## Deep convolutional neural network for retention time prediction in Reversed-Phase Liquid Chromatography
### Repository contains pre-trained models, data on retention times, one-hot matrices for five data sets (METLIN SMRT, MassBank1, MetaboBASE, Hilic_Retip and Riken_Retip)
### Scripts can be used to train 1D CNN model from scratch or for transfer learning approach
### To reproduce results of predicition retention times for METLIN SMRT data set with 1D CNN check Report 

* To train 1D CNN on METLIN SMRT data set load zip file "Train initial model for SMRT"
* To train 1D CNN from scratch on MassBank1, MetaboBASE, Hilic_Retip and Riken_Retip data sets load zip files "List of matrices transfer data sets" and "SMILES and RTs"
* For transfer learning with MassBank1, MetaboBASE, Hilic_Retip and Riken_Retip data sets load zip files "List of matrices transfer data sets", "SMILES and RTs", "models for transfer learning" 
* DATA also contains SDF files for MassBank1, MetaboBASE, Hilic_Retip and Riken_Retip data sets "SDF_DATA_SETS.zip". These files can be used to build your own model and to compare results with 1D CNN

