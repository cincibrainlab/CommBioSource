#==============================================================================#
# REPMAKE          Reproducible Manuscript Toolkit with GNU Make               #
#==============================================================================#
# MODEL SCRIPT     ============================================================#
                   basename <- "peakFreqElec" # TITLE
#                  comparison of pre-processing results between groups
#==============================================================================#
# STARTUP              
                   source(file = "SourceBackup/_Common.R")  # COMMON FUNCTIONS
                   
                   pacman::p_load(R.matlab, tidyverse, here, weights, flextable,
                                  reshape2, raveio, rstatix, hdf5r, DescTools, 
                                  nlme,emmeans, ggthemes, broom.mixed, 
                                  dotwhisker)
# LOAD OTHER RDATA ============================================================#
       # Group Assigments
       clininfo <- read_csv("Source/fxs_group_list.csv")
       
       # Electrode and Scalp Atlases
       # elecinfo <- read_csv("https://bit.ly/3CSUB4k") # Egi 128 electrode atlas
       # nodeinfo <- read_csv("https://bit.ly/32J64qV") # DK atlas + MNI
       elecinfo <- read_csv("Source/resource/resource_elecDetailsEGI128_v2.csv")
       nodeinfo <- read_csv("Source/resource/resource_atlas_dk_networks_mni.csv") 
                   
       data_file   <- NA # any R Data inputs (or NA)   
       if(is.na(data_file)) {} else 
         load(data_file)  # external data (optional)
                   
# DEFAULT OUTPUT   i.e. modify with str_replace(target_file, ".RData", ".docx")
                   prefix      <- paste0(basename)
                   target_file <- if(!is.na(target_file)) 
                     {target_file=target_file} else 
                     here(outFile(prefix, "RDATA"))
                   
# CUSTOM OUTPUTS   ============================================================#                 

         target_file.table <- str_replace(target_file, ".RData", "_table.docx")
                   
# START R SCRIPT   ============================================================#

# Load data set
import.peakfreq.elec <- read_csv("Source/datasets/P1_peakFreq.csv") %>% 
  mutate(chan = paste0("E",Electrode))

# Check electrode regions
elecinfo %>% filter(!is.na(side)) %>% 
  mutate(mapping = factor(paste(side, zone))) %>% 
  group_by(mapping) %>% dplyr::summarize(n = n())     

import.peakfreq.src <- read_csv("Source/datasets/P1_source_peakFreq.csv")

# electrode level peak frequency
df.elec <- import.peakfreq.elec %>% left_join(elecinfo, by=c("chan"="chan")) %>% 
  left_join(clininfo, by=c("eegid"="eegid")) %>% filter(!is.na(side)) %>% drop_na() %>% 
  rename(value = peakFreq) %>% mutate(mapping = factor(paste(side, zone)),
                                      mosaic = factor(paste0(sex,"_",mosaic)))

# Base LME model includes group, sex, lower band, and resting state network (RSN)
fit.1 <- nlme::lme(value~group*sex*zone, random = ~1|eegid, method="ML",
                   correlation=corCompSymm(form=~1|eegid), data=df.elec)
anova(fit.1)  # laterality did not matter

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

#==============================================================================#
# EXPORT TABLE
  save_as_docx(ft.elecpeak, path = target_file.table)
#==============================================================================#
  
