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

models: $(B)model_preprocessing.RData $(B)model_demographics.RData \
				$(B)model_gedbounds.RData $(B)model_pairs.RData \
        $(B)model_topo_compare.RData $(B)model_topo.RData \
        $(B)model_corCoef.RData
        
tables: $(B)Table1.docx $(B)Table2.docx \
        $(B)Sup_Table1.docx $(B)Sup_Table2.docx $(B)Sup_Table3.docx \
        $(B)Sup_Table4.docx $(B)Sup_Table5.docx $(B)Sup_Table6.docx \
        $(B)Sup_Table7.docx $(B)Sup_Table8.docx 
  
figures: $(B)Figure1A.docx $(B)Figure1B.docx $(B)Figure1C.docx $(B)Figure2A.docx \
         $(B)Figure2B.docx $(B)Figure2C.docx $(B)Figure2DE.docx $(B)Figure3.docx \
         $(B)Sup_Figure1.docx $(B)Sup_Figure2.docx  
  
manuscript: $(B)manuscript_coverletter.docx $(B)manuscript_main.docx \
            $(B)manuscript_supplement.docx

matlab: $(B)gedbounds_01_config.mat $(B)gedbounds_02_import.mat

#==============================================================================#
# RECIPES: DATA MODELS AND STATISTICS                                          #
#==============================================================================#
$(B)model_preprocessing.RData: $(S)model_preprocessing.R
	$(R) $< -o $@

$(B)model_demographics.RData: $(S)model_demographics.R
	$(R) $< -o $@
	
$(B)model_corCoef.RData: $(S)model_corCoef.R
	$(R) $< -o $@

$(B)model_gedbounds.RData: $(S)model_gedbounds.R
	$(R) $< -o $@

$(B)model_pairs.RData: $(S)model_pairs.R
	$(R) $< -o $@

$(B)model_topo.RData: $(S)model_topo.R
	$(R) $< -o $@

$(B)model_topo_compare.RData: $(S)model_topo_compare.R $(B)model_topo.RData
	$(R) $< -o $@

#==============================================================================#
# RECIPES: TABLES                                                              #
#==============================================================================#
# TABLE 1: Demographics (results)
$(B)Table1.docx: $(S)table_demographics.R $(B)model_demographics.RData
	$(R) $< -o $@

# TABLE 2: Boundaries (results)
$(B)Table2.docx: $(S)table_nbounds.R $(B)model_gedbounds.RData
	$(R) $< -o $@

# SUPPLEMENTAL TABLE 1: PREPROCESSING 
$(B)Sup_Table1.docx: $(S)table_preprocessing.R $(B)model_preprocessing.RData
	$(R) $< -o $@
  
# SUPPLEMENTAL TABLE 2: GEDBOUNDS comparisions 
$(B)Sup_Table2.docx: $(S)table_gedbounds.R $(B)model_gedbounds.RData
	$(R) $< -o $@
  
# SUPPLEMENTAL TABLE 3: alpha pairs 
$(B)Sup_Table3.docx: $(S)table_pairs.R $(B)model_pairs.RData
	$(R) $< -o $@
  
# SUPPLEMENTAL TABLE 4
$(B)Sup_Table4.docx: $(S)table_topo_compare_means.R $(B)model_topo_compare.RData $(B)model_topo.RData
	$(R) $< -o $@

# SUPPLEMENTAL TABLE 5
$(B)Sup_Table5.docx: $(S)table_topo_compare_topo.R $(B)model_topo_compare.RData $(B)model_topo.RData
	$(R) $< -o $@  
  
# SUPPLEMENTAL TABLE 6
$(B)Sup_Table6.docx: $(S)table_topo_compare_group.R $(B)model_topo_compare.RData $(B)model_topo.RData
	$(R) $< -o $@  
  
# SUPPLEMENTAL TABLE 7 corr (results)
$(B)Sup_Table7.docx: $(S)table_topo_corr.R $(B)model_topo.RData
	$(R) $< -o $@
  
# SUPPLEMENTAL TABLE 8 corr males (results)
$(B)Sup_Table8.docx: $(S)table_topo_corr_maleonly.R $(B)model_topo.RData
	$(R) $< -o $@

#==============================================================================#
# RECIPES: FIGURES                                                             #
#==============================================================================#

# FIGURE 1A (introduction)
$(B)Figure1A.docx: $(S)figure_schematic.R $(S)illustrations/figure_schematic.png
	$(R) $< -o $@
  
# FIGURE 1B Example (results)
$(B)Figure1B.docx: $(S)figure_exemplar.R $(S)illustrations/figure_exemplar.png
	$(R) $< -o $@

# FIGURE 1C KDE (results)
$(B)Figure1C.docx: $(S)figure_overviewBounds.R $(B)model_gedbounds.RData
	$(R) $< -o $@

# FIGURE 2A paired alpha plot (results)
$(B)Figure2A.docx: $(S)figure_alphaBoundaryPairs.R $(B)model_pairs.RData
	$(R) $< -o $@
  
# FIGURE 2B Topo template (results)
$(B)Figure2B.docx: $(S)figure_topo_template.R $(S)illustrations/figure_topo_template.png
	$(R) $< -o $@

# FIGURE 2C within topo (results)
$(B)Figure2C.docx: $(S)figure_topoCompare_within.R $(B)model_topo.RData
	$(R) $< -o $@

# FIGURE 2DE groups (results)
$(B)Figure2DE.docx: $(S)figure_topoCompare.R $(B)model_topo.RData
	$(R) $< -o $@

# FIGURE 3 groups (results)
$(B)Figure3.docx: $(S)figure_topo_corr.R $(B)model_topo.RData
	$(R) $< -o $@
  
# SUPPLEMENTAL FIGURE 1 corcoef (results)
$(B)Sup_Figure1.docx: $(S)figure_corCoef.R
	$(R) $< -o $@
  
# SUPPLEMENTAL FIGURE 2 tracings (results)
$(B)Sup_Figure2.docx: $(S)figure_tracings.R
	$(R) $< -o $@
  
#==============================================================================#
# MANUSCRIPT                                                                   #
#==============================================================================#
$(B)manuscript_main.docx: \
$(S)manuscript/titlepage.docx \
$(S)manuscript/acknowledgements.docx \
$(S)manuscript/abstract.docx \
$(S)manuscript/introduction.docx \
$(S)manuscript/results.docx \
$(S)manuscript/discussion.docx \
$(S)manuscript/methods.docx \
$(B)Figure1A.docx    \
$(B)Figure1B.docx    \
$(B)Figure1C.docx    \
$(B)Figure2A.docx    \
$(B)Figure2B.docx    \
$(B)Figure2C.docx    \
$(B)Figure2DE.docx   \
$(B)Figure3.docx   \
$(B)Table1.docx      \
$(B)Table2.docx
	$(R) $(S)manuscript/_mergeManuscript.R $@ $^

$(B)manuscript_supplement.docx: \
$(B)Sup_Table1.docx \
$(B)Sup_Table2.docx \
$(B)Sup_Table3.docx \
$(B)Sup_Table4.docx \
$(B)Sup_Table5.docx \
$(B)Sup_Table6.docx \
$(B)Sup_Table7.docx \
$(B)Sup_Table8.docx \
$(B)Sup_Figure1.docx \
$(B)Sup_Figure2.docx
	$(R) $(S)manuscript/_mergeManuscript.R $@ $^

$(B)manuscript_coverletter.docx:$(S)manuscript/coverletter.docx
	$(R) $(S)manuscript/_mergeManuscript.R $@ $^

#==============================================================================#
# MATLAB                                                                       #
#==============================================================================#
$(B)matlab_01_loadData.mat: $(S)MATLAB/matlab_01_loadData.m
	matlab /minimize /nosplash /nodesktop /batch 'run $^'
# $(B)gedbounds_02_import.mat: $(S)MATLAB/gedbounds_02_import.m
#	matlab /minimize /nosplash /nodesktop /batch 'run $^'   
#==============================================================================#
# CLEAN         commands erase files in Build folder                           #
#==============================================================================#
clean:
	rm -rf Build/*.docx Build/*.Rmd Build/*.png Build/*.docx
  
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