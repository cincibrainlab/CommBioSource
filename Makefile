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
R = RScript --
Matlab = matlab -nodesktop -nosplash -batch
#Matlab = matlab -nosplash -r
# Matlab = docker exec -it matlab matlab -nosplash -desktop -nosoftwareopengl -r
MB = /srv/build/CommBioEEGRev/
B = Build/
S = /srv/cbl/CommBioEEGRev/Source/

all: $(MB)model_loadDataset.mat $(MB)model_makeMne.mat

# Create MNE Model from Preprocessed Data

# Load scalp EEGs
$(MB)model_loadDataset.mat: $(S)model_loadDataset.m
	$(Matlab) "target_file='$@';, run $^"

# Construct MNE Source model in Brainstorm
$(MB)model_makeMne.mat: $(S)model_makeMne.m
	$(Matlab) "target_file='$@';, run $^"

# Calculate Electrode Power in Brainstorm
$(MB)model_bstElecPow.mat: $(S)model_bstElecPow.m
	$(Matlab) "target_file='$@';, run $^"

# Calculate Source Power in Brainstorm
$(MB)model_bstSourcePow.mat: $(S)model_bstSourcePow.m
	$(Matlab) "target_file='$@';, run $^"

# Calculate Electrode Group Comparisions Statistics
$(MB)model_bstElecPowStats.mat: $(S)model_bstElecPowStats.m
	$(Matlab) "target_file='$@';, run $^"


    
# Output File : Input Files
# Recipe (Commands)

# # Generate source model and power from cleaned EEG data
# Model_SourceEEGs.mat : Model_PostProcessEEGs.mat\
#       MATLAB CreateSourceFromPostProcessEEGs.m

# Model_PowerFromSourceEEGS.mat : Model_SourceEEGs.mat\
#        Rscript CreatePowerFromSourceEEGs.m

# # Spectral Power Statistical Comparison
# Model_PowerComparison.RData : Model_PowerFromSourceEEGS.mat\
#        Rscript ComparePowerFromSourceEEGs.m

# Table_PowerComparision : Model_PowerComparison.RData
#        Rscript Table_PowerComparision.R

# Figure_PowerComparision : Model_PowerComparison.RData
#        Rscript Figure_PowerComparision.R

# # Spectral Power Clinical Correlations
# Model_CorrelationPowerWithClinical.RData : Model_PowerFromSourceEEGS.mat Model_SubjectClinicalMeasures.csv\
#        Rscript CorrelationPowerWithClinical.R

# Figure_CorrelationPower.RData : Model_CorrelationPower.RData
#        Rscript Figure_CorrelationPowerWithClinical.R

# Table_CorrelationPower.RData : Model_CorrelationPower.RData
#        Rscript Figure_CorrelationPowerWithClinical.R


#==============================================================================#
# CLEAN         commands erase files in Build folder                           #
#==============================================================================#
clean:
	rm -rf $(MB)model_loadDataset.mat $(MB)model_makeMne.mat
#	del /q /s "$(MB)model_loadDataset.mat $(B)table_preprocessing.csv"

#==============================================================================#
# RepMake           Reproducible Manuscript Toolkit with GNU Make               #
#                  Version 8/2021                                              #
#                  cincibrainlab.com                                           #
# =============================================================================#
