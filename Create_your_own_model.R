######## CREATE NEW 1D CNN MODEL BASED ON SMRT METLIN 
######## The longest SMILES character in METLIN SMRT data set IS 93
######## FOR the NEW DATASET length of the longest SMILES character may be changed
######## USE TRANSFER LEARNING ON THE NEW MODEL



library(text2vec)
library(stringi)
library(rcdk)
############CREATE SMILES##############################
smrt<- load.molecules("SMRT_excludeHydrogens_only.sdf")
smiles <-lapply(smrt, function(x) get.smiles(x, smiles.flavors(c("Canonical", "UseAromaticSymbols"))))

smiles_character <- as.vector(unlist(smiles_character))
#### Split into elements
smiles_split <- strsplit(smiles_character, "")
smiles_elements <- as.vector(unlist(smiles_split))
####Create vocabulary
vocab = create_vocabulary(smiles_elements)
vocab <- vocab$term
### Finding the longest smile character
x <- which.max(lapply(smiles_split, function(x) length(x)))
x
length <- length(smiles_split[[x]])
length 
#### the length of the longest SMILEs vector
####Creating matrix in which rows are vocabulary and number of columns
### are the longest SMILES
matrixsmi <- matrix(0, nrow = as.numeric(length(vocab)), ncol = length)
###CREATING LIST OF MATRICES

### Finding elements using vocabulary which present in the molecule
### Should be a list containing number of elemets equal to number of molecules
list_of_elements <-  lapply(1:length(smiles_character), function(x) sapply(1:length(vocab), function(y) stri_locate_all_coll(smiles_character[x], vocab[y], max_count=-1)[[1]][,1]))

###Creating list of matrices
list_matrices <- lapply(1:length(smiles_character), function(x) sapply(1:length(vocab), function(t) 
  replace(matrixsmi[t,], list_of_elements[[x]][[t]], 1)))
library(abind)
library(caret)
library(Metrics)
retention_time <- as.data.frame(fread("SMRT_excluded.csv")$rt)
names(retention_time)[1]<- "rt"
###### Combine multi-dimensional arrays
matrix <- abind(list_matrices, along=0.5)
### check the dimension. 
#Should be: number of molecules, length of the longest SMILES, number of elements in vocabulary
dim(matrix) 
#### data splitting
trainIndex<-sample(createDataPartition(retention_time$rt, p=0.8, list=FALSE))
ytrain = as.matrix(retention_time[trainIndex,])
ytest <- as.matrix(retention_time[-trainIndex,])
xtrain <- matrix[trainIndex,,]
dim(xtrain)
xtest <- matrix[-trainIndex,,]
dim(xtest)

library(keras)

#### BUILD 1D CNN model#######
in_dim = c(dim(xtrain)[2:3])
print(in_dim)
model = keras_model_sequential() %>%
  layer_conv_1d(filters = 200, kernel_size = 11,strides = 1, input_shape = in_dim, activation = "relu")%>%
  layer_conv_1d(filters = 200, kernel_size = 9,strides = 1, activation = "relu") %>% 
  layer_global_average_pooling_1d()%>%
  layer_dense(units = 200,activation = "relu")%>%
  layer_dense(units = 1, activation = "linear")
model %>% compile(
  loss = "mae",
  optimizer <- "adam")

model%>% summary()
#####TRAIN MODEL
model %>% fit(xtrain, ytrain, epochs = 20, batch_size=32, validation_split=0.1)
model %>% fit(xtrain, ytrain, epochs = 5, batch_size=128, validation_split=0.1)
###########TESTING
test_y_pred = model %>% predict(xtest)
plot(test_y_pred,ytest)

RMSE<- RMSE(ytest, test_y_pred)
RMSE
MAE <- mae(ytest, test_y_pred)
MAE
MAE
MAD<- mdae(ytest, test_y_pred)
MAD
model %>% save_model_hdf5("new_model.h5")
