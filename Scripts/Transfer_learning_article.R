#################TRANSFER LEARNING################

set.seed(1234)
library(keras)
library(data.table)
library(Metrics)
library(caret)
library(abind)
########################## LOAD DATA ##############

##########RIKEN_RETIP#########################
retention_time <- as.data.frame(fread("smiles_retention_riken_retip.csv")$rt)
load("C:/MY_WORKING_directory/list_matrices_riken_157_35.RData")
##############METABOBASE################
retention_time <- as.data.frame(fread("smiles_retention_metabobase.csv")$retention_time)
load("C:/MY_WORKING_directory/list_matrices_metabobase_223_35.RData")

##############HILIC RETIP ####################
retention_time <- as.data.frame(fread("smiles_retention_hilic_retip.csv")$`Experimental Retention Time`)
load("C:/MY_WORKING_directory/list_matrices_hilic_178_35.RData")
##############MASSBANK1##################
retention_time<- as.data.frame(fread("smiles_retention_MassBank1.csv")$retention_time)
load("C:/MY_WORKING_directory/list_matrices_MassBank1_9735.RData")

####### PRE-PROCESSING###########
retention_time <- apply(retention_time, 2, function(x) as.numeric(as.character(x)))
retention_time <- as.data.frame(retention_time)
names(retention_time)[1]<- "rt"
##CREATE AN ARRAY with dimension : number of observations, longest SMILES, Length of vocabulary
matrix<- abind(list_matrices, along=0.5)
dim(matrix)

##########CREATE FOLDS FOR CROSS-VALIDATION########

kfold <- createFolds(retention_time$rt, k = 10, list = T, returnTrain = FALSE)
kfold

MedAE_all <-NULL
MAE_all <- NULL
RMSE_all<- NULL
MRE_all<- NULL
MedRE_all<- NULL
##### Median Relative Error
mdape <- function(x,z) median(abs(x-z)/x)
#########BUID MODEL HILIC######
#REMOVING THE LAST LAYER
#ADDING NEW DENSE LAYER
#FREEZING THE FIRST CONVOLUTIONAL LAYER
#COMPILE
build_model_hilic <- function(){
  model <- load_model_hdf5("model_hilic_178_35.h5")
  pop_layer(model)
   predictions <- model$output %>% layer_dense(units = 1, activation = "linear")
   summary(model)
   model_2 <- keras_model(inputs = model$input, outputs = predictions)
  layers <- model_2$layers
  for (i in 1:length(layers)){
    cat(i, layers[[i]]$name, "\n")}
  for (i in 1){
    layers[[i]]$trainable <- F}
  for (i in 2:length(layers)){
    layers[[i]]$trainable <-T}
  summary(model_2)
  model_2 %>% compile(
    optimizer = "adam", 
    loss="mae")
}

########## CROSS-VALIDATION#############
for(f in 1:10){
  ind <- kfold[[f]]
  x_train <- matrix[-ind,,]
  y_train <- retention_time[-ind,]
  x_test <- matrix[ind,,]
  y_test <- retention_time[ind,]
  model_hilic<- build_model_hilic() 
  early_stop <- callback_early_stopping(monitor = "loss", patience =5,mode = "min",min_delta= 0.01,restore_best_weights =F)
  model_hilic %>% fit(
    x = x_train, y = y_train,
    batch_size = 8,
    epochs = 35,
    callbacks = list(early_stop))
  
  test_y_pred <- model_hilic %>% predict(x_test)
  RMSE<- RMSE(y_test, test_y_pred)
  MAE <- MAE(y_test, test_y_pred)
  MedAE<- mdae(y_test, test_y_pred)
  MedRE<- mdape(y_test, test_y_pred)
  MRE <- mape(y_test, test_y_pred)
  
  RMSE_all <- c(RMSE_all, RMSE)
  MAE_all <- c(MAE_all, MAE)
  MedAE_all <- c(MedAE_all, MedAE)
  MRE_all <- c(MRE_all, MRE)
  MedRE_all<- c(MedRE_all, MedRE)
  
} 
#########RESULTS ####################
#### METRICS FOR EACH FOLD
test_metrics<- as.data.frame(cbind(RMSE_all,MAE_all,MedAE_all, MRE_all, MedRE_all ))
####MEAN VALUE  across folds
mean <- as.data.frame(t(apply(test_metrics,2, function(x) mean(x))),row.names = "Mean")
#### STANDARD DEVIATION
standard_dev <- as.data.frame(t(apply(test_metrics,2,function(z) sd(z))))

test_metrics_mean <- rbind(test_metrics,mean)
######################

MedAE_all <-NULL
MAE_all <- NULL
RMSE_all<- NULL
MRE_all<- NULL
MedRE_all<- NULL

###############MODEL FOR RP HPLC#############
###choose the model for the certain data set
build_model_RP <- function(){
  model_basic <- load_model_hdf5(".h5")
  pop_layer(model_basic)
  predictions <- model_basic$output %>% layer_dense(units = 1, activation = "linear")
  summary(model_basic)
  model <- keras_model(inputs = model_basic$input, outputs = predictions)
  
  layers <- model$layers
  for (i in 1:length(layers)){
    cat(i, layers[[i]]$name, "\n")}
  for (i in 1){
    layers[[i]]$trainable <- F}
  for (i in 2:length(layers)){
    layers[[i]]$trainable <- T}
  model %>% compile(
    optimizer = "adam", 
    loss="mae")
}
####TRAINING AND TESTING ####
for(f in 1:10){
  ind <- kfold[[f]]
  x_train <- matrix[-ind,,]
  y_train <- retention_time[-ind,]
  x_test <- matrix[ind,,]
  y_test <- retention_time[ind,]
  
  model_rp<- build_model_RP() 
  early_stop <- callback_early_stopping(monitor = "loss", patience =7,mode = "min",min_delta= 0.01,restore_best_weights = F)
     model_rp %>% fit(
    x = x_train, y = y_train,
    batch_size = 8,
    epochs = 35,
    callbacks = list(early_stop)
    )
     model_rp %>% fit(
       x = x_train, y = y_train,
       batch_size = 16,
       epochs = 10,
       callbacks = list(early_stop))
  test_y_pred <- model_rp %>% predict(x_test)
  
  RMSE<- RMSE(y_test, test_y_pred)
  MAE <- MAE(y_test, test_y_pred)
  MedAE<- mdae(y_test, test_y_pred)
  MedRE<- mdape(y_test, test_y_pred)
  MRE <- mape(y_test, test_y_pred)
  
  RMSE_all <- c(RMSE_all, RMSE)
  MAE_all <- c(MAE_all, MAE)
  MedAE_all <- c(MedAE_all, MedAE)
  MRE_all <- c(MRE_all, MRE)
  MedRE_all<- c(MedRE_all, MedRE)
  
} 
#########RESULTS ####################
#### METRICS FOR EACH FOLD
test_metrics<- as.data.frame(cbind(RMSE_all,MAE_all,MedAE_all, MRE_all, MedRE_all ))
####MEAN VALUE  across folds
mean <- as.data.frame(t(apply(test_metrics,2, function(x) mean(x))),row.names = "Mean")
#### STANDARD DEVIATION
standard_dev <- as.data.frame(t(apply(test_metrics,2,function(z) sd(z))))

test_metrics_mean <- rbind(test_metrics,mean)

##############BUILD MODEL FROM SCRATCH##############
MedAE_all <-NULL
MAE_all <- NULL
RMSE_all<- NULL
MRE_all<- NULL
MedRE_all<- NULL

in_dim<- dim(matrix)[-1]
in_dim
build_model_scratch <- function(){
  model = keras_model_sequential() %>%
    layer_conv_1d(filters = 200, kernel_size = 11,strides =1, input_shape = in_dim, activation = "relu")%>%
    layer_conv_1d(filters = 200, kernel_size = 9,strides = 1, activation = "relu") %>% 
    layer_global_average_pooling_1d()%>%
    layer_dense(units = 200, activation = "relu")%>%
    layer_dense(units = 1, activation = "linear")
  model %>% compile(
    optimizer = "adam", 
    loss="mae")
}
####TRAINING AND TESTING ####
for(f in 1:10){
  ind <- kfold[[f]]
  x_train <- matrix[-ind,,]
  y_train <- retention_time[-ind,]
  x_test <- matrix[ind,,]
  y_test <- retention_time[ind,]
  
  model_scratch<- build_model_scratch()
  early_stop <- callback_early_stopping(monitor = "val_loss", patience =5,mode = "min",min_delta= 0.01,restore_best_weights = T)
  model_scratch%>% fit(
    x_train,
    y_train,
    batch_size =8,
    epochs = 35,
    validation_split = 0.05,
    callbacks = list(early_stop))
  model_scratch%>% fit(
    x_train,
    y_train,
    batch_size =32,
    epochs = 10,
    validation_split = 0.05,
    callbacks = list(early_stop))

  test_y_pred <- model_scratch %>% predict(x_test)
  RMSE<- RMSE(y_test, test_y_pred)
  MAE <- MAE(y_test, test_y_pred)
  MedAE<- mdae(y_test, test_y_pred)
  MedRE<- mdape(y_test, test_y_pred)
  MRE <- mape(y_test, test_y_pred)
  
  RMSE_all <- c(RMSE_all, RMSE)
  MAE_all <- c(MAE_all, MAE)
  MedAE_all <- c(MedAE_all, MedAE)
  MRE_all <- c(MRE_all, MRE)
  MedRE_all<- c(MedRE_all, MedRE)
  
} 

#########RESULTS ####################
test_metrics<- as.data.frame(cbind(RMSE_all,MAE_all,MedAE_all, MRE_all, MedRE_all ))
mean <- as.data.frame(t(apply(test_metrics,2, function(x) mean(x))),row.names = "Mean")
standard_dev <- as.data.frame(t(apply(test_metrics,2,function(z) sd(z))))
test_metrics_mean <- rbind(test_metrics,mean)
