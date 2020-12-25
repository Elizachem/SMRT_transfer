#################TRANSFER LEARNING################
################ Transfer Learning###############
#########MODEL FOR HILIC
####LOAD DATA
######HILIC Fiehn
retention_time<- as.data.frame(fread("HILIC_SMILES_rt.csv")$V1)
names(retention_time)[1]<- "rt"
retention_time <- apply(retention_time, 2, function(x) as.numeric(as.character(x)))
list_matrices<- readRDS("list_matrices_HILIC_FIEHN_93_35.rda")
matrix<- abind(list_matrices, along=0.5)
dim(matrix)
##########RP-LC RIKEN PLASMA
retention_time<- as.data.frame(fread("riken_smiles_rt.csv")$rt)
retention_time <- apply(retention_time, 2, function(x) as.numeric(as.character(x)))
list_matrices<- readRDS("list_matrices_PLASMA_RIKEN_POS.rda")
matrix<- abind(list_matrices, along=0.5)
dim(matrix)
#####CREATE FOLDS FOR CROSS-VALIDATION
kfold <- createFolds(retention_time, k = 10, list = T, returnTrain = FALSE)
kfold
all_scores <- c()
all_mae_histories <- NULL
mdae_all <-NULL
MAE_all <- NULL
RMSE_all<- NULL
#########BUID MODEL HILIC
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
  model_hilic<- build_model_hilic() # or build_model_RP FOR RIKEN PLASMA DATA SET
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

sd(test_metrics$MAE_all)
sd(test_metrics$mdae_all)
sd(test_metrics$RMSE_all)
