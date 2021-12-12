#==============================================================================#
# RepMake           Reproducible Manuscript Toolkit with GNU Make              #
#==============================================================================#
# TABLE SCRIPT     ============================================================#
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
#                  RStudio. Note: Sensitive to capitalization and no spaces.   #                                                             #
#==============================================================================#
# Step 1: Load common packages, data, and functions.                           #
# =============================================================================#
rm(list = ls()) # clear current environment
source(file = "Source/_Common.R")
pacman::p_load(compareGroups)

#==============================================================================#
# Step 2: Customize "basename" for script                                        #
#==============================================================================#
basename    <- "demographics_short" # Edit
prefix      <- paste0("table_", basename)
#==============================================================================#
# Step 3: Specify any RData to load into environment when script is run. We    #
#         recommend creating a model script (with the same base name) to load  #
#         and wrangle dataset and save to a single RData file. This will allow #
#         multiple figures and tables without having to re-import data. Use    #
#         NA if no data is necessary.                                          #
#==============================================================================#
data_file   <- "Build/model_demographics.RData" # any RData inputs (or NA)
#==============================================================================#
# Step 4: Specify target file for interactive RStudio (no modification needed) #                                                           #
#==============================================================================#
target_file <- if(!is.na(target_file)) {target_file=target_file} else          #
  here(outFile(prefix, "DOCX")) # RSTUDIO default output file                  #
#==============================================================================#

#==============================================================================#
#                                  TABLE                                       #
#==============================================================================#
# DATA PREPARATION ============================================================#
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

# =============================================================================#
# TABLE CREATION   ============================================================#
#                  Generate tables below. May combine multiple tables into     #
#                  single document. First table output should be assigned to   #
#                  t.output below. Consider using flextable, descrTable, gt.   #
#==============================================================================#
# Step 1: Create table                                                         #
#==============================================================================#

# Caption: Short demographic table (Table)
result_table.demo_short <- descrTable(group ~ ., dat.demo_short, 
                                      hide.no = "no", 
                                      simplify = TRUE)

#==============================================================================#
# Step 2: Format table                                                         #
#==============================================================================#  



#==============================================================================#
# Step 2: Assign plot to output/export variable t.output
# =============================================================================#
t.output <- result_table.demo_short

# =============================================================================#
# TABLE CAPTION    ============================================================#
#                  All captions should be entered into markdown/text format    #
#                  in Source/S07_Manuscript_Sections/captions.md. Captions     #
#                  will be loaded, reviewed, and a search term can be used to  #
#                                                                              #
#==============================================================================#
# Step 1: Load captions from captions.md                                       #
# =============================================================================#
all_Captions <- loadCaptions(myCaptionFile)  # run all_Captions to list
#==============================================================================#
# Step 2: Specify search term                                                  #
# =============================================================================#
caption_Search_Term <-  "\\*Table 1"  # edit. use '\\' to escape special chars
selected_Caption <- searchCaptions(all_Captions, caption_Search_Term)
#==============================================================================#
# Step 3: Create word document with caption text for merging                   #
# =============================================================================#
caption_file_docx <- getCaptionDoc( selected_Caption ) # temporary document
# =============================================================================#


# =============================================================================#
# EXPORT TABLE   ==============================================================#
#                 By default, code combines caption and table and exports to a #
#                 Word document.                                               #
#==============================================================================#
# Step 1 Prepare table export   (intermediate form prior to docx)              #
# =============================================================================#
NA
#==============================================================================#
# Step 2         Depending on table package, several options are available. If #
#                the package allows for adding a caption and saving to document#
#                use the selected_caption variable. Some packages it may be    #
#                easier to merge two separate documents (caption and table).In #
#                this case, use the temporary word file (caption_file_docx).   #
# =============================================================================#

t.output  %>% export2word(target_file, caption=selected_Caption)
print(target_file)

# =============================================================================#

#==============================================================================#
# RepMake           Reproducible Manuscript Toolkit with GNU Make               #
#                  Version 8/2021                                              #
#                  cincibrainlab.com                                           #
# =============================================================================#