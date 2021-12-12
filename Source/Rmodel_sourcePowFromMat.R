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
pacman::p_load(R.matlab, reshape2, tidyverse, emmeans, flextable)
#==============================================================================#
# Step 2: Customize basename for script                                        #
#==============================================================================#
basename    <- "sourcePowFromMat" # Edit
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

# df.old <- read_csv("C:/Users/ernie/Dropbox/NN_RestingSource/Results/data-raw/sas_import_cortex_all_no_epsilion.csv")
dat.matlab <- R.matlab::readMat("Build/model_bstSourcePow_sourceRelPow865.mat")

values <- dat.matlab$timefreq

dimnames(values)[1] <- dat.matlab$channels %>%  unlist() %>%unname() %>% list()
dimnames(values)[2] <- dat.matlab$subnames %>% unlist() %>% unname() %>% list()

freqbands <- dat.matlab$freqbands %>% unlist() %>% unname()
freqbandlabels <- matrix(freqbands %>% t(), ncol = 3,byrow = TRUE)
dimnames(values)[3] <-  as.vector(freqbandlabels[,1] ) %>% list()

dat.pow.relative <- reshape2::melt(values, 
                          value.name = "value", 
                          varnames=c("chan","eegid","freq"))

atlas.vertices <- read_csv("Source/createVertexFromBstAtlas_Desikan0x2DKilliany.csv")
atlas.networks <- read_csv(file = "Source/atlas_dk_networks_mni.csv") %>%
  select(label, RSN, region)

dat.pow.rel <- dat.pow.relative %>%  left_join(atlas.vertices, by=c("chan"="Vertex"))

dat.pow <- dat.pow.rel %>% group_by(eegid, freq, Label) %>% 
  summarize(value=mean(value)) %>% 
  fx.add.group_assignments(dat.clin) %>%
  left_join(atlas.networks, by=c("Label"="label")) %>% 
  rename(label = Label, bandname = freq) %>% 
  mutate(label = factor(label)) %>% filter(!is.na(label))

unique(dat.pow$label)

library(nlme)
#fit.region <- lme(log(value)~group*sex*bandname*region, random = ~1|eegid,
#              correlation=corCompSymm(form=~1|eegid), data=dat.pow)
# save(fit.region, file = "Source/upload/fit_region.rdata")
load("Source/upload/fit_region.rdata")

#fit.rsn <- lme(log(value)~group*sex*bandname*RSN, random = ~1|eegid,
#               correlation=corCompSymm(form=~1|eegid), data=dat.pow)
#save(fit.rsn, file = "Source/upload/fit_RSN.rdata")
load("Source/upload/fit_RSN.rdata")


# Create Tables
fit.final <- fit.region
anova(fit.final)
emc <- emmeans(fit.final, ~ group*sex*bandname*region)
estimates <- broom::tidy(emc, conf.int = TRUE, conf.level = .95)
pairs_by_group<- broom::tidy(pairs(emc, by = c("bandname","region","sex"), adjust='none')) %>% 
  group_by(contrast) %>% mutate(adj.p = p.adjust(p.value,method = "fdr", n = n())) %>% 
  select(-term,-null.value)

pairs_by_group <- pairs_by_group %>% mutate(adj.p = p.value)
pairs_by_group %>% filter(adj.p <= .05)


target_file.table1 <- str_replace(target_file, ".RData", "region_table_pairwise.docx")

ft.pairs.tmp <- pairs_by_group %>% ungroup() %>%  select(sex, bandname,region, estimate, std.error, adj.p) %>% 
  mutate(side = substr(region,1,1),
         region = substr(region,2,nchar(region))) %>% 
  mutate(estimate = weights::rd(estimate,2),
         estimate = paste0(estimate, "\u00B1", weights::rd(std.error,2), add_sig_stars(adj.p, cutoffs = c(0.01, 0.001, 0.0001)))) %>% 
  select(-adj.p,-std.error) %>% relocate(side, region, sex ) %>% 
  pivot_wider(names_from = bandname, values_from = estimate) %>% 
  mutate(side = factor(side, levels=c("L","R"), labels = c("Left", "Right")),
         sex= factor(sex),
         region = factor(region, levels=c("C",  "F",  "L",  "O",  "P",  "PF", "T" ),
                         labels = c("Central","Frontal","Lingula","Occipital", "Parietal", "Prefrontal", "Temporal")))

ft.pairs <- ft.pairs.tmp %>% flextable()
ft.pairs <- set_header_labels(ft.pairs, 
                              side = "L/R",
                              region = "Region",
                              sex = "Sex") %>% merge_v(j=c(1,2,3)) %>% valign(j=c(1,2,3),valign = "top") %>% 
  fix_border_issues()%>% 
  autofit()
ft.pairs

target_file_region_table <- str_replace(target_file, ".RData", "_region.docx") 

ft.pairs %>% save_as_docx(path = target_file_region_table)

# labels for significance lines
dat_text <- data.frame(
  label = c("adj.p<.05", "adj.p<.001","adj.p<.05", "adj.p<.001"),
  sex   = c("Female: FXS-Control","Female: FXS-Control","Female: FXS-Control","Female: FXS-Control"),
  x     = c(4, 4, 1.5,1.5),
  y     = c(.18, .27,-.18, -.27)
)


p.region <- pairs_by_group %>%   mutate(side = substr(region,1,1),
                            region = substr(region,2,nchar(region))) %>% 
  mutate(bandname = factor(bandname, levels=c("delta","theta","alpha1","alpha2","beta","gamma1","gamma2")),
           side = factor(side, levels=c("L","R"), labels = c("Left", "Right")),
         sex= factor(sex, levels=c("F","M"), labels=c("Female: FXS-Control", "Males: FXS-Control")),
         region = factor(region, levels=c("O","L","P", "T", "C",  "F",  "PF" ),
                         labels = c("Occipital","Lingula", "Parietal","Temporal","Central","Frontal","Prefrontal"))) %>% 
  arrange(side) %>% 
  ggplot() + geom_col(aes(x=bandname, y=estimate, fill=region), color='black', size=0.05, position = position_dodge2()) +
  geom_hline(yintercept = c(-.155,.155), linetype="dotted") +
  geom_hline(yintercept = c(-.247,.247), linetype="dotted") +
  ylab("Difference in Log Spectral Power") +
  xlab("Frequency Band") +
  geom_text( data    = dat_text,
             mapping = aes(x = x, y = y, label = label)) +
  facet_wrap(~sex) + theme_minimal()  +  theme(legend.position = c(.2,.1), legend.direction = "horizontal")
    
target_file_region_plot <- str_replace(target_file, ".RData", "_region.pdf") 
ggsave(plot = p.region, filename = target_file_region_plot)
ft.pairs %>% save_as_docx(path = target_file_region_)


# Compare old and new data
df.old %>% filter(eegid == "D0079_rest" & bandname == "gamma1") %>% select(eegid, label, value) %>% 
  left_join(dat.pow %>% ungroup() %>% rename(valuenew = value) %>% 
              filter(eegid == "D0079_rest" & bandname == "gamma1") %>% select(label, valuenew))

library(ggsegDefaultExtra)
library(ggsegExtra)
# Create group dataset for plotting with ggseg
df.ggseg <- dat.pow  %>% 
  mutate(ggseglabel = paste0(str_split(Label, " ",simplify=TRUE)[,2],"h_",
                             str_split(Label, " ",simplify=TRUE)[,1]) %>% str_to_lower()) %>% 
  select(-Label) %>% 
  rename(label = ggseglabel) 

df.ggseg

dkcustom <- dkextra
dkcustom$data <- dkextra$data %>% filter(side %in% c('superior','lateral'))
dkcustom$data
df.ggseg %>% 
  group_by(group,label,freq) %>% summarise(value =mean(value)) %>% filter(label != "h_na") %>% 
  ungroup() %>% 
  ggplot() +
  geom_brain(atlas = dkcustom, 
             position = position_brain(hemi ~ side),
             aes(fill = value)) +
  facet_grid(cols = vars(group), rows=vars(freq))+theme(legend.position = "bottom") + 
  scale_fill_gradientn(colours = c("blue", "white","firebrick"),na.value="white") +
  labs(title="AAC") + theme_Publication() +
  theme(strip.background = element_blank(), panel.grid.major = element_blank())
  ggsave(filename = str_replace(target_file, ".RData", "ggseg.pdf"))
  
  
dat.pow.rel.long <- dat.pow.relative %>% 
  fx.add.group_assignments(dat.clin) %>% 
  mutate(freq = factor(freq),
         mgroup = factor(mgroup, levels=c("M4","M2","M1","F4","F3"),
                         labels=c("Control(M)","Mosaic(M)","FXS(M)","Control(F)","FXS(F)")))
library(ggseg)
dat.pow %>% filter(freq == "theta") %>% 
  
  
  ggplot() + geom_boxplot(aes(x=subgroup, y=value, fill=freq)) 

## =============================================================================
## SAVE FOR CORRELATIONS
target_file_region_corr <- str_replace(target_file, ".RData", "_forCorr.RData") 

save(dat.pow, file = target_file_region_corr)

## =============================================================================



# Examine region by region contrasts
pairs_by_group<- broom::tidy(pairs(emc, by = c("bandname","group","sex"), adjust='none')) %>% 
  group_by(contrast) %>% mutate(adj.p = p.adjust(p.value,method = "fdr", n = n())) %>% 
  select(-term,-null.value)

df.brainplot <- pairs_by_group %>% ungroup() %>% rowwise() %>% 
  mutate(region1 = str_split(contrast, " - ", simplify=TRUE)[[1]],
         region2 = str_split(contrast, " - ", simplify=TRUE)[[2]]) %>%  
  mutate(side1 = substr(region1,1,1),
         region1 = substr(region1,2,nchar(region1)),
         side2 = substr(region2,1,1),
         region2 = substr(region2,2,nchar(region2))) %>% 
  mutate(bandname = factor(bandname, 
                           levels=c("delta","theta","alpha1","alpha2","beta","gamma1","gamma2")),
         side1 = factor(side1, levels=c("L","R"), labels = c("Left", "Right")),
         side2 = factor(side2, levels=c("L","R"), labels = c("Left", "Right")),
         sex= factor(sex, levels=c("F","M"), 
                     labels=c("Female", "Males")),
         region1 = factor(region1, levels=c("O","L","P", "T", "C",  "F",  "PF" ),
                         labels = c("Occipital","Lingula", "Parietal","Temporal","Central","Frontal","Prefrontal")),
         region2 = factor(region2, levels=c("O","L","P", "T", "C",  "F",  "PF" ),
                         labels = c("Occipital","Lingula", "Parietal","Temporal","Central","Frontal","Prefrontal"))) %>% 
  relocate(side1, region1,side2, region2, .before =estimate) %>% select(-contrast) 
  
df.brainplot %>% filter(region2 == "Temporal") %>% 
  mutate(regiontemp = as.character(region1), 
                        sidetemp = as.character(side1),
                        region1 = as.character(ifelse(region2 == "Temporal", region2, region1)),
                        side1 = as.character(ifelse(region2 == "Temporal", side2, side1)),
                        side2 = as.character(ifelse(region2 == "Temporal", sidetemp, side2)),
                        region2 = as.character(ifelse(region2 == "Temporal", regiontemp, region2)))
                        
                        
                        
                        
                        
  
  
  filter(region1 == "Temporal" & region2 == "Temporal")
unique(df.brainplot$region2)

estimates %>% filter(bandname == "gamma1") %>% arrange(-estimate) %>% select(group, sex, region, estimate)

pairs_by_group %>% filter(adj.p <= .05) %>% filter(bandname == "gamma1")


target_file.table1 <- str_replace(target_file, ".RData", "region_table_pairwise.docx")

ft.pairs.tmp <- pairs_by_group %>% ungroup() %>%  select(sex, bandname,region, estimate, std.error, adj.p) %>% 
  mutate(side = substr(region,1,1),
         region = substr(region,2,nchar(region))) %>% 
  mutate(estimate = weights::rd(estimate,2),
         estimate = paste0(estimate, "\u00B1", weights::rd(std.error,2), add_sig_stars(adj.p, cutoffs = c(0.01, 0.001, 0.0001)))) %>% 
  select(-adj.p,-std.error) %>% relocate(side, region, sex ) %>% 
  pivot_wider(names_from = bandname, values_from = estimate) %>% 
  mutate(side = factor(side, levels=c("L","R"), labels = c("Left", "Right")),
         sex= factor(sex),
         region = factor(region, levels=c("C",  "F",  "L",  "O",  "P",  "PF", "T" ),
                         labels = c("Central","Frontal","Lingula","Occipital", "Parietal", "Prefrontal", "Temporal")))

ft.pairs <- ft.pairs.tmp %>% flextable()
ft.pairs <- set_header_labels(ft.pairs, 
                              side = "L/R",
                              region = "Region",
                              sex = "Sex") %>% merge_v(j=c(1,2,3)) %>% valign(j=c(1,2,3),valign = "top") %>% 
  fix_border_issues()%>% 
  autofit()
ft.pairs

target_file_region_table <- str_replace(target_file, ".RData", "_region.docx") 

ft.pairs %>% save_as_docx(path = target_file_region_table)

#==============================================================================#
# Step 3:          Assign model to output/export variable model.output         #
# =============================================================================#
model.output <- dat.pow.rel.long

#==============================================================================#
# Step 4: Export data                                                          #
# =============================================================================#

save(model.output, file = target_file)

