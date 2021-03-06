library(data.table)
library(text2vec)
library(stringi)
library(rcdk)
###### FOR SDF FILE##############
## MASS BANK EXAMPLE
massbank <- load.molecules("MassBank1.sdf")
retention_time <- as.data.frame(fread("smiles_retention_MassBank1.csv")$retention_time) 
retention_time <- apply(retention_time,2,function(x)as.numeric(as.character(x)))
retention_time<- as.data.frame(retention_time)
names(retention_time)[1]<- "rt"
### FOR CSV DATA If SMILES ARE NOT IN THE REQUIRED FORM
smiles <- fread("smiles_retention_MassBank1.csv")$smiles 
massbank <- parse.smiles(smiles)
write.molecules(massbank, "massbank1.sdf")
massbank <- load.molecules("massbank1.sdf")
## Create SMILES
smiles <-lapply(massbank, function(x) get.smiles(x, smiles.flavors(c("Canonical","UseAromaticSymbols")))) 
smiles_character<- unlist(smiles)
smiles_split <- strsplit(smiles_character, "")
smiles_elements <- as.vector(unlist(smiles_split))

###### CREATE VOCABULARY
#To train model from scratch use data set's vocabulary
vocab = create_vocabulary(smiles_elements)
vocab <- vocab$term
# For transfer learning use METLIN's Vocabulary
vocab_metlin <- unlist(fread("vocab_canonical_aroma.txt"))
vocab <-unique(c(vocab,vocab_metlin))
#### Define the longest SMILES
#### To build model from scratch use the longest SMILES of the data set
#### For transfer learning define the longest SMILES between two data sets
x <- which.max(lapply(smiles_split, function(x) length(x)))
x
length <- length(smiles_split[[x]])
length 
####Creating matrix in which rows are vocabulary and number of columns
### are the longest SMILEs
matrixsmi <- matrix(0, nrow = as.numeric(length(vocab)), ncol = length)
### Finding elements using vocabulary which present in the molecule
### Should be a list containing number of elemets equal to number of molecules
list_of_elements <-  lapply(1:length(smiles_character), function(x) sapply(1:length(vocab), function(y) stri_locate_all_coll(smiles_character[x], vocab[y], max_count=-1)[[1]][,1]))
###Creating list of matrices
list_matrices <- lapply(1:length(smiles_character), function(x) sapply(1:length(vocab), function(t) 
  replace(matrixsmi[t,], list_of_elements[[x]][[t]], 1)))

########## processing list of matrices to the  array######

library(abind)
library(caret)
library(Metrics)
library(keras)

matrix <- abind(list_matrices, along=0.5)
dim(matrix)

#### data splitting

trainIndex<-sample(createDataPartition(retention_time$rt, p=0.8, list=FALSE))
ytrain = as.matrix(retention_time[trainIndex,])
ytest <- as.matrix(retention_time[-trainIndex,])
xtrain <- matrix[trainIndex,,]
xtest<- matrix[-trainIndex,,]
rm(list_matrices)

###BUILD THE MODEL
in_dim = c(dim(xtrain)[2:3])
print(in_dim)
model = keras_model_sequential() %>%
  layer_conv_1d(filters = 200, kernel_size = 11,strides =1, input_shape = in_dim, activation = "relu")%>%#, padding = "valid"
  layer_conv_1d(filters = 200, kernel_size = 9,strides = 1, activation = "relu") %>% 
  layer_global_average_pooling_1d()%>%
  layer_dense(units = 200, activation = "relu")%>%
  layer_dense(units = 1, activation = "linear")

model %>% compile(
  loss = "mae",
  optimizer <- "adam")

model %>% summary()

num_epochs = 35
size = 8
early_stop <- callback_early_stopping(monitor = "val_loss", patience =7,mode = "min",min_delta= 0.01,restore_best_weights = T)

model %>% fit(xtrain, 
              ytrain, 
              epochs = num_epochs,
              batch_size=size,
              validation_split=0.05,
              callbacks = list(early_stop))
##### TEST
test_y_pred = model %>% predict(xtest)
mdape <- function(x,z) median(abs(x-z)/x)
test_y_pred = model %>% predict(xtest)
RMSE<- RMSE(ytest, test_y_pred)
MAE <- MAE(ytest, test_y_pred)
MdAE<- mdae(ytest, test_y_pred)
MedRE<- mdape(ytest, test_y_pred)
MRE <- mape(ytest, test_y_pred)
test_metrics <- as.data.frame(cbind(RMSE,MAE,MdAE,MRE,MedRE))
plot(ytest,test_y_pred)

model %>% save_model_hdf5("model.h5")
