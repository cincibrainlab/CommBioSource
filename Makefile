#==============================================================================#
# REPMAN           Reproducible Manuscript Toolkit with GNU Make               #
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
Matlab = matlab -nogui -nosplash -batch
B = Build/
S = Source/
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

all: models tables figures manuscript

demographics: $(B)model_demographics.RData \
							$(B)table_demographics_short.docx \
							$(B)table_demographics_long.docx \
							$(B)figure_demographics_iq.pdf


  
#figures: $(B)Figure1A.docx 
  
#manuscript: $(B)manuscript_coverletter.docx 

#matlab: $(B)gedbounds_01_config.mat 

#==============================================================================#
# RECIPES: RESULTS                                                             #
#==============================================================================#
# Demographics
$(B)model_demographics.RData: $(S)model_demographics.R
	$(R) $< -o $@
	
$(B)table_demographics_long.docx: $(S)table_demographics_long.R
	$(R) $< -o $@
	cp $(B)table_demographics_long.docx $(B)Drafts/STable1.docx
	
$(B)table_demographics_short.docx: $(S)table_demographics_short.R
	$(R) $< -o $@
	cp $(B)table_demographics_short.docx $(B)Drafts/Table1.docx
	
$(B)figure_demographics_iq.pdf: $(S)figure_demographics_iq.R
	$(R) $< -o $@
	cp $@ $(B)Drafts/Figure1A.pdf




#==============================================================================#
# MANUSCRIPT                                                                   #
#==============================================================================#

#==============================================================================#
# MATLAB                                                                       #
#==============================================================================#
#$(B)matlab_01_loadData.mat: $(S)MATLAB/matlab_01_loadData.m
#	matlab /minimize /nosplash /nodesktop /batch 'run $^'
# $(B)gedbounds_02_import.mat: $(S)MATLAB/gedbounds_02_import.m
#	matlab /minimize /nosplash /nodesktop /batch 'run $^'   
#==============================================================================#
# CLEAN         commands erase files in Build folder                           #
#==============================================================================#
clean:
	rm -rf Build/*.docx Build/*.Rmd Build/*.png Build/*.docx Build/*.pdf
  
clean_models:
	rm -rf Build/*.RData
  
clean_figures:
	rm -rf Build/*.docx Build/*.png
	
clean_manuscript:
	rm -rf $(B)manuscript_main.docx \
         $(B)manuscript_supplement.docx \
         $(B)manuscript_tables.docx \
         $(B)manuscript_figures.docx

clean_matlab:
	rm -rf $(B)*.mat
#==============================================================================#
# REPMAN           Reproducible Manuscript Toolkit with GNU Make               #
#                  Version 8/2021                                              #
#                  cincibrainlab.com                                           #
# =============================================================================#