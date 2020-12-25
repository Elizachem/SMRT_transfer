library(Metrics)
library(abind)
library(caret)
library(keras)

in_dim = c(dim(xtrain)[2:3])
print(in_dim)
########### 10-fold Cross-validation
retention_time <- apply(retention_time, 2, function(x) as.numeric(as.character(x)))
kfold <- createFolds(retention_time, k = 10, list = T, returnTrain = FALSE)
kfold
all_scores <- c()
all_mae_histories <- NULL
mdae_all <-NULL
MAE_all <- NULL
RMSE_all<- NULL

###### FINGERPRINT NN with fully connected layers
#### BUILD MODEL
build_model <- function(){
  input_prop <- layer_input(shape = dim(test)[2])
  tower_1 <- input_prop %>%
    layer_dense(units =256,activation = "relu")%>%
    layer_dense(units =256,activation = "relu")%>%
    layer_dense(units =256,activation = 'relu')
  
  tower_2 <- input_prop %>%
    layer_dense(units =256,activation = "relu")%>%
    layer_dense(units =256,activation = "relu")%>%
    layer_dense(units =256,activation = 'relu')
  output <- layer_concatenate(c(tower_1,tower_2))%>%
    layer_dense(units = 1, activation = 'linear')
  model <- keras_model(inputs =input_prop, outputs = output)
  model %>% compile(
    loss = "mae",
    optimizer <-"adam" )
}
####TRAINING AND TESTING ####
for(f in 1:10){
  ind <- kfold[[f]]
  x_train <- test[-ind,]
  y_train <- rt[-ind,]
  y_test <- rt[ind,]
  x_test <- test[ind,]
  model <- build_model()
  history <-  model %>% fit(
    x = x_train, y = y_train,
    batch_size = 32,
    epochs = 12)
   model %>% fit(
    x = x_train, y = y_train,
    batch_size = 128,
    epochs = 3)
  test_y_pred <-  model %>% predict(x_test)
  RMSE<- RMSE(y_test, test_y_pred)
  MAE <- MAE(y_test, test_y_pred)
  mdae<- mdae(y_test, test_y_pred)
  RMSE_all <- c(RMSE_all, RMSE)
  MAE_all <- c(MAE_all, MAE)
  mdae_all <- c(mdae_all, mdae)
}

#####  1-D CNN
build_model <- function(){
  model = keras_model_sequential() %>%
    layer_conv_1d(filters = 200, kernel_size = 11,strides = 1, input_shape = in_dim, activation = "relu")%>%
    layer_conv_1d(filters = 200, kernel_size = 9,strides = 1, activation = "relu") %>% 
    layer_global_average_pooling_1d()%>%
    layer_dense(units = 200, activation = "relu")%>%
    layer_dense(units = 1, activation = "linear")
  
    model %>% compile(
    loss = "mae",
    optimizer <- "adam")
}
####TRAINING AND TESTING ####
for(f in 1:10){
  ind <- kfold[[f]]
  x_train <- matrix[-ind,,]
  y_train <- retention_time[-ind,]
  x_test <- matrix[ind,,]
  y_test <- retention_time[ind,]
  model<- build_model()
  model %>% fit(
    x = x_train, y = y_train,
    batch_size = 32,
    epochs = 20)
  model%>% fit(
    x = x_train, y = y_train,
    batch_size = 128,
    epochs = 5)
  test_y_pred <- model %>% predict(x_test)
  RMSE<- RMSE(y_test, test_y_pred)
  MAE <- MAE(y_test, test_y_pred)
  mdae<- mdae(y_test, test_y_pred)
  RMSE_all <- c(RMSE_all, RMSE)
  MAE_all <- c(MAE_all, MAE)
  mdae_all <- c(mdae_all, mdae)
} 

#### Transfer Learning
#########MODEL FOR HILIC
build_model_hilic <- function(){
  model_hilic <- load_model_hdf5("model_metlin_93_35.h5")
    model_hilic %>% compile(
    optimizer = "adam", 
    loss="mae")
}
############MODEL FOR RP HPLC

build_model_RP <- function(){
  model_rp <- load_model_hdf5("model_metlin_93_35.h5")
  
  layers <- model_rp$layers
  for (i in 1:length(layers)){
    cat(i, layers[[i]]$name, "\n")}
  for (i in 1){
    layers[[i]]$trainable <- F}
  for (i in 2:length(layers)){
    layers[[i]]$trainable <- T}
  
  model_rp %>% compile(
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
  model_hilic<- build_model_hilic() #or build_model_RP
  model_hilic %>% fit(
    x = x_train, y = y_train,
    batch_size = 8,
    epochs = 20)
  model_hilic%>% fit(
    x = x_train, y = y_train,
    batch_size = 64,
    epochs = 5)
  test_y_pred <- model_hilic %>% predict(x_test)
  RMSE<- RMSE(y_test, test_y_pred)
  MAE <- MAE(y_test, test_y_pred)
  mdae<- mdae(y_test, test_y_pred)
  RMSE_all <- c(RMSE_all, RMSE)
  MAE_all <- c(MAE_all, MAE)
  mdae_all <- c(mdae_all, mdae)
} 

######### RESULTS######
test_metrics<- cbind(RMSE_all,MAE_all,mdae_all )
test_metrics <- as.data.frame(test_metrics)
RMSE_mean <- mean(errors_test_extend$RMSE_all)
MAE_mean <- mean(errors_test_extend$MAE_all)
MDAE_mean <- mean(errors_test_extend$mdae_all)
mean<- cbind(RMSE_mean, MAE_mean, MDAE_mean)
fwrite(test_metrics, "test_metrics_METLIN.csv")
test_metrics<- fread("test_metrics_METLIN.csv")
sd(test_metrics$MAE_all)
sd(test_metrics$mdae_all)
sd(test_metrics$RMSE_all)














































  

