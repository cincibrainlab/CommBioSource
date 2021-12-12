#==============================================================================#
# RepMake           Reproducible Manuscript Toolkit with GNU Make               #
#==============================================================================#
# MAKEFILE         ============================================================#
#                  This makefile generates all manuscript assets from source   #
#                  files and illustrations. Prior to using, user should check  #
#                  that GNU make, R, and matlab are all accessible via command #
#                  line.                                                       #
#==============================================================================#

#==============================================================================#
#                               CONFIGURATION                                  #
#==============================================================================#
# SHORTCUTS        ============================================================#
#                  definition: shortcut [commands or paths]                    #
#                  usage: $(shortcut)                                          #
#==============================================================================#
SHELL=/bin/bash
R = RScript --verbose
# Matlab = matlab -nodesktop -nosplash -batch
Matlab = docker exec -it matlab matlab -nodesktop -nosplash -batch
MB = /srv/rawdata/MatlabBuild/CommBioEEGRev/
B = Build/
S = /srv/cbl/CommBioEEGRev/Source/MATLAB/

#==============================================================================#

#==============================================================================#
#                                  RECIPES                                     #
#==============================================================================#
# COMBINED         ============================================================#
# "RECIPES"        combination recipes create groups of assets such as all     #
#                  tables or figures.                                          #
#                  definition: recipe_name: asset1 asset2                      #
#                  usage: make recipe_name                                     #
#==============================================================================#

all: source_model

source_model: $(MB)model_loadDataset.mat


#==============================================================================#
# MATLAB RECIPIES                                                              #
#==============================================================================#

# Create MNE Model from Preprocessed Data
# MODEL: Complete EEG Dataset Object
$(MB)model_loadDataset.mat: $(S)model_loadDataset.m
	$(Matlab) "target_file='$@';, run $^"

# # MODEL: Electrode power metrics for R analysis
# $(MB)model_electrodePower.mat: model_electrodePower.m
# 	matlab /minimize /nosplash /nodesktop /batch "target_file='$@';, run $^" 

# # TABLE: Preprocessing metrics for R analysis
# $(B)table_preprocessing.csv: table_preprocessing.m
# 	matlab /minimize /nosplash /nodesktop /batch "target_file='$@';, run $^" 

# # TABLE: Preprocessing metrics for R analysis
# $(B)table_electrodePowerContinuous.parquet: table_electrodePowerContinuous.m $(MB)model_electrodePower.mat
# 	matlab /minimize /nosplash /nodesktop /batch "target_file='$@';, run $<" 

#==============================================================================#
# CLEAN         commands erase files in Build folder                           #
#==============================================================================#
clean:
	rm -rf $(MB)model_loadDataset.mat
#	del /q /s "$(MB)model_loadDataset.mat $(B)table_preprocessing.csv"

#==============================================================================#
# RepMake           Reproducible Manuscript Toolkit with GNU Make               #
#                  Version 8/2021                                              #
#                  cincibrainlab.com                                           #
# =============================================================================#
