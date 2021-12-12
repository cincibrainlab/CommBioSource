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
source(file = "SourceBackup/_Common.R")
pacman::p_load(R.matlab, tidyverse, here, weights, flextable,reshape2, raveio, rstatix, hdf5r, DescTools)
pacman::p_load(nlme,emmeans)
pacman::p_load(ggthemes, broom.mixed, dotwhisker)
#devtools::install_github("fsolt/dotwhisker")
#==============================================================================#
# Step 2: Customize basename for script                                        #
#==============================================================================#
basename    <- "peakFreqElec" # Edit
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

if(is.na(data_file)) {} else load(data_file)  # external data (optional)

import.peakfreq.elec <- read_csv("Source/datasets/P1_peakFreq.csv") %>% mutate(chan = paste0("E",Electrode))

import.peakfreq.src <- read_csv("Source/datasets/P1_source_peakFreq.csv")

elecinfo <- read_csv("Source/model_elecDetailsEGI128.csv")
nodeinfo <- read_csv("Source/atlas_dk_networks_mni.csv")  # atlas assignments
clininfo <- read_csv("Source/fxs_group_list.csv")         # group assignments

# Check electrode regions
elecinfo %>% filter(!is.na(side)) %>% mutate(mapping = factor(paste(side, zone))) %>% 
  group_by(mapping) %>% dplyr::summarize(n = n())

#==============================================================================#
# Step 2: Data Modeling                                                        #
#==============================================================================#

# electrode level peak frequency
df.elec <- import.peakfreq.elec %>% left_join(elecinfo, by=c("chan"="chan")) %>% 
  left_join(clininfo, by=c("eegid"="eegid")) %>% filter(!is.na(side)) %>% drop_na() %>% 
  rename(value = peakFreq) %>% mutate(mapping = factor(paste(side, zone)),
                                      mosaic = factor(paste0(sex,"_",mosaic)))

# Base LME model includes group, sex, lower band, and resting state network (RSN)
fit.1 <- nlme::lme(value~group*sex*zone, random = ~1|eegid, method="ML",
                   correlation=corCompSymm(form=~1|eegid), data=df.elec)
anova(fit.1)  # laterality did not matter

model_results <- 
  tidy(fit.1, effects = "fixed")

dwplot(fit.1)

sprintf("We found a significant interaction effect (F2,12618=18.1,p<.0001) of group, sex, and electrode region (anterior, central, posterior).") 


# selected model
fit.final <- fit.1

# least-squared means
emc <- emmeans(fit.final, ~ group*sex*zone)
estimates <- broom::tidy(emc, conf.int = TRUE, conf.level = .95)

# get paired significant contrasts
pairs_by_group<- broom::tidy(pairs(emc, by = c("zone","sex"), adjust='none')) %>% 
  group_by(contrast) %>% mutate(adj.p = p.adjust(p.value,method = "fdr", n = n())) %>% 
  select(-term,-null.value) %>% ungroup() %>% select(-contrast,-p.value) %>% 
  mutate(estimate = weights::rd(estimate,2),
         std.error = weights::rd(std.error,2),
         statistic = weights::rd(statistic,1),
         adj.p = scales::pvalue(adj.p))

# get mean values
peakmeans <- estimates %>% 
  mutate(mean = paste0(rd(estimate,1)," \u00B1 ",rd(std.error,2))) %>% 
  select(group, sex, zone, mean) %>% 
  pivot_wider(names_from = group,values_from = c(mean)) 

ft.elecpeak <- pairs_by_group %>% left_join(peakmeans, by=c("sex","zone")) %>%
  relocate(c(FXS,TDC),.before = estimate) %>% flextable() %>% 
  set_header_labels(sex = "Sex",
                    zone = "Region",
                    estimate = "FXS-TDC",
                    std.error = "SE",
                    df = "DF",
                    statistic = "F",
                    adj.p = "% FDR p") %>% 
  flextable::merge_v(j=1) %>% 
  flextable::valign(j = 1,valign = "top") %>% 
  autofit() %>% fix_border_issues()



pairs_by_group_alphaslowing<- broom::tidy(pairs(emc, by = c("group","sex"), adjust='none')) %>% 
  group_by(contrast) %>% mutate(adj.p = p.adjust(p.value,method = "fdr", n = n()))

  select(-term,-null.value) %>% ungroup() %>% select(-p.value) %>% 
  mutate(estimate = weights::rd(estimate,2),
         std.error = weights::rd(std.error,2),
         statistic = weights::rd(statistic,1),
         adj.p = scales::pvalue(adj.p))
  unique(estimates$zone)
  estimates %>% mutate(zone = factor(zone,levels = c("Posterior","Central","Anterior"))) %>% 
    mutate(subgroup = paste0(group,"_",sex)) %>%
  ggplot() + geom_pointrange(aes(x=zone,y=estimate, color=subgroup, ymin=conf.low, ymax=conf.high)) +
    scale_color_manual(values = colors_subgroup2) + ylab("Alpha Peak Frequency (Hz)") + 
    xlab("Electrode Region") +
    theme_Publication()

# ---------------------------------------------------------------------------- #
# EXPORT TABLE
# Description: Summary pairwise comparisons of AAC (with significance stars)

target_file.table1 <- str_replace(target_file, ".RData", "table_peaks.docx")
save_as_docx(ft.elecpeak, path = target_file.table1)

#==============================================================================#
# Step 3:          Assign model to output/export variable model.output         #
# =============================================================================#
model.output <- dat.pow.rel.long

#==============================================================================#
# Step 4: Export data                                                          #
# =============================================================================#

save(model.output, file = target_file)

