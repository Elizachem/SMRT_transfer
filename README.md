## Deep convolutional neural network for retention time prediction in Reversed-Phase Liquid Chromatography
<img src="graphical abstract.png" align="center" height="354" width="680"/>

# Brief Description
Repository contains pre-trained models, data on retention times, one-hot matrices for five data sets (*METLIN SMRT*, *MassBank1*, *MetaboBASE*, *Hilic_Retip* and *Riken_Retip*).
Scripts can be used to train 1D CNN model from scratch or for transfer learning approach.
**To reproduce results of predicition retention times for *METLIN SMRT* data set with 1D CNN check [Report](https://github.com/Elizachem/SMRT_transfer/tree/main/Report).**

* To train 1D CNN on *METLIN SMRT* data set load zip file ["Train initial model for SMRT"](https://github.com/Elizachem/SMRT_transfer/blob/main/DATA/Train%20initial%20model%20for%20SMRT.zip)
* To train 1D CNN from scratch on *MassBank1*, *MetaboBASE*, *Hilic_Retip* and *Riken_Retip* data sets load zip files ["List of matrices transfer data sets"](https://github.com/Elizachem/SMRT_transfer/blob/main/DATA/List%20of%20matrices%20transfer%20data%20sets.zip) and ["SMILES and RTs"](https://github.com/Elizachem/SMRT_transfer/blob/main/DATA/SMILES%20and%20RTs.zip)
* For transfer learning with *MassBank1*, *MetaboBASE*, *Hilic_Retip* and *Riken_Retip* data sets load zip files ["List of matrices transfer data sets"](https://github.com/Elizachem/SMRT_transfer/blob/main/DATA/List%20of%20matrices%20transfer%20data%20sets.zip), ["SMILES and RTs"](https://github.com/Elizachem/SMRT_transfer/blob/main/DATA/SMILES%20and%20RTs.zip), ["models for transfer learning"](https://github.com/Elizachem/SMRT_transfer/blob/main/DATA/models%20for%20transfer%20learning.zip) 
* [DATA](https://github.com/Elizachem/SMRT_transfer/tree/main/DATA) also contains SDF files for *MassBank1*, *MetaboBASE*, *Hilic_Retip* and *Riken_Retip* data sets ["SDF_DATA_SETS.zip"](https://github.com/Elizachem/SMRT_transfer/blob/main/DATA/SDF_DATA_SETS.zip). These files can be used to build your own model and to compare results with 1D CNN

# Requirements
The only requirements are to be familiar with the basic syntax of the *R* language, PC with Internet connection and Windows OS (desirable), [*RStudio*](https://www.rstudio.com/products/rstudio/download/) and [*R*](https://cloud.r-project.org/) (≥ 4.0.0).

# Contact
Please send any comments or questions you may have to the author (*Ms. Elizaveta Fedorova*), email: elizaveta.chemi@gmail.com, ORCID: 0000-0002-5774-7901.
