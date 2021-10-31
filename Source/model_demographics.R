#==============================================================================#
# RepMake           Reproducible Manuscript Toolkit with GNU Make              #
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
basename    <- "demographics" # Edit
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
target_file <- if(!is.na(target_file)) {target_file=target_file} else here::here(outFile(prefix, "RDATA")) # RSTUDIO default output file                 #
#==============================================================================#
#==============================================================================#
# DATA PREPERATION ============================================================#
#                  All inclusive data to generate figure below. We recommend   #
#                  loading data from reusable .RData from a model file rather  #
#                  than performing extensive data import and manpulation here. #
#==============================================================================#
# Step 1: Load, Import, or Prepare Data set(s) for plotting. If NA no loading. #
# =============================================================================#
if(is.na(data_file)) {} else load(target_file)

#==============================================================================#
# Step 2: Wrangle data as needed.                                              #
# =============================================================================#

demographics <- c("eegid", "group", "sex","mosaic","visitage")

selectvars <- c("iq_dev",
                "sbs_nvz", "sbs_vz", "adams_anxiety",
                "adams_ocd", "scq_total", "abc_irritable",
                "abc_hyperactivity", "abc_speech",
                "abc_lethargy", "abc_stereotypy", "wj3", "visitage"
)

# exclude subjects with benzodiazapines 794, 1806, 2464
model.demo  <- 
  read_csv(source_filename.clinical) %>%
  dplyr::filter(eegid %notin% c("D0794_rest","D1806_rest","D2464_rest")) %>%
  dplyr::select(all_of(c(demographics, selectvars))) %>%
  mutate( NVIQ = (sbs_nvz * 15) + 100,
          VIQ  = (sbs_vz * 15) + 100) %>% 
  mutate(subgroup = paste0(group,'_',sex),
         mgroup = paste0(subgroup,'_',mosaic)) %>%
  mutate(subgroup = factor(subgroup,
                           levels=c("TDC_M","FXS_M","TDC_F","FXS_F"),
                           labels=c("Control(M)","FXS(M)","Control(F)","FXS(F)")),
         mgroup=factor(mgroup, 
                       levels=c("TDC_M_4","FXS_F_3", "TDC_F_4", "FXS_M_1", "FXS_M_2"), 
                       labels=c("CM","FF","CF","FM","MM")),
         sex=factor(sex,
                    levels=c("M","F"), 
                    labels=c("Male","Female"))) 

# Model for short demographic table.
dat.demo_short <- model.demo %>%
  select(group, 
         visitage,
         iq_dev,
         VIQ,
         NVIQ,
         scq_total,
         adams_anxiety, 
         wj3) %>%
  set_variable_labels(visitage = "Age (y)", 
                      iq_dev = "FSIQ",
                      VIQ = "VIQ",
                      NVIQ = "NVIQ",
                      scq_total = "Social Score",
                      adams_anxiety = "Anxiety Score",
                      wj3="WJ-III")

# Model for long demographic table.
dat.demo_long <- model.demo %>%
  select(subgroup,
         visitage,
         iq_dev,
         VIQ,
         NVIQ,
         scq_total,
         abc_irritable,
         abc_hyperactivity, 
         abc_speech,
         abc_lethargy,
         abc_stereotypy,
         adams_ocd,
         adams_anxiety, 
         wj3) %>%
  set_variable_labels(visitage = "Age (Years)", subgroup="Group", iq_dev = "FSIQ",
                      scq_total = "SCQ", wj3 = "WJ-III", abc_irritable = "ABC-Irritability",
                      abc_lethargy = "ABC-Lethargy", abc_stereotypy = "ABC-Stereotypy",
                      abc_hyperactivity = "ABC-Hyperactivity", abc_speech = "ABC-Abnormal Speech",
                      adams_anxiety = "ADAMS-Anxiety", adams_ocd = "ADAMS-OCD")


# Model for NVIQ figure
dat.demo_iq <- model.demo %>% select(eegid, NVIQ, sbs_nvz, group, sex, subgroup) 



#==============================================================================#
# Step 3:          Assign model to output/export variable model.output         #
# =============================================================================#
model.output <- model.demo

#==============================================================================#
# Step 4: Export data                                                          #
# =============================================================================#

save(model.output, dat.demo_short, dat.demo_long, dat.demo_iq, file = target_file)
