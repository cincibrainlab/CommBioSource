#==============================================================================#
# RepMake           Reproducible Manuscript Toolkit with GNU Make               #
#==============================================================================#
# MODEL SCRIPT     ============================================================#
#                  This script generates a single figure from a dataset and    #
#                  exports the file into a high-resolution vector (PDF) and    #
#                  a single page word document with a caption. This script can #
#                  run from the command line or run directly from the GUI.     #
#                  When run from the command line use -o to specify an output  #
#                  file (i.e. Table1.docx).                                    #
#==============================================================================#
#==============================================================================#
# CONFIGURATION    ============================================================#
#                  Define naming for output. File names in REPMAKE stay        #
#                  consistent between the script name and any output files.    #
#                  The prefix specifies the type of output (i.e., figure_).    #
#                  This code also automatically switches between a specific    #
#                  command line output file and if the script is run from      #
#                  RStudio. Note: Sensitive to capitalization and no spaces.   # 
#==============================================================================#
# Step 1: Load common packages, data, and functions.                           #
# =============================================================================#
source(file = "Source/_Common.R")
#==============================================================================#
# Step 2: Customize basename for script                                        #
#==============================================================================#
basename    <- "powAbsFFT" # Edit
prefix      <- paste0("model_", basename)
#==============================================================================#
# Step 3: Specify any RData to load into environment when script is run. We    #
#         recommend creating a model script (with the same base name) to load  #
#         and wrangle dataset and save to a single RData file. This will allow #
#         multiple figures and tables without having to re-import data. Use    #
#         NA if no data is necessary.                                          #
#==============================================================================#
data_file   <- NA # any RData inputs (or NA)
#==============================================================================#
# Step 4: Specify target file for interactive RStudio (no modification needed) # 
#==============================================================================#
target_file <- if(!is.na(target_file)) {target_file=target_file} else          #
  here(outFile(prefix, "RDATA")) # RSTUDIO default output file                 #
#==============================================================================#
#==============================================================================#
# DATA PREPERATION ============================================================#
#                  All inclusive data to generate figure below. We recommend   #
#                  loading data from reusable .RData from a model file rather  #
#                  than performing extensive data import and manpulation here. #
#==============================================================================#
# Step 1: Load, Import, or Prepare Data set(s) for plotting. If NA no loading. #
# =============================================================================#
if(is.na(data_file)) {} else load(data_file)

#==============================================================================#
# Step 2: Wrangle data as needed.                                              #
# =============================================================================#

#==============================================================================#
# Step 1: Load MAT file with CFC results                                       #
#==============================================================================#

dat.matlab <- R.matlab::readMat("Build/model_bstElecAbsPowFFT.mat")

values <- dat.matlab$timefreq

dimnames(values)[1] <- dat.matlab$channels %>%  unlist() %>%unname() %>% list()
dimnames(values)[2] <- dat.matlab$subnames %>% unlist() %>% unname() %>% list()
dimnames(values)[3] <- paste0("", round(dat.matlab$freqbands,2) %>% unlist()) %>% list() %>% as.numeric()

dat.pow.absolute <- reshape2::melt(values, 
                          value.name = "value", 
                          varnames=c("chan","eegid","freq"))
dat.pow.absolute %>%  head()

dat.pow.abs.long <- dat.pow.absolute %>% 
  fx.add.group_assignments(dat.clin) %>% 
  mutate(freq = factor(freq),
         mgroup = factor(mgroup, levels=c("M4","M2","M1","F4","F3"),
                         labels=c("Control(M)","Mosaic(M)","FXS(M)","Control(F)","FXS(F)")))


#==============================================================================#
# Step 3:          Assign model to output/export variable model.output         #
# =============================================================================#
model.output <- dat.pow.abs.long

#==============================================================================#
# Step 4: Export data                                                          #
# =============================================================================#

save(model.output, file = target_file)
