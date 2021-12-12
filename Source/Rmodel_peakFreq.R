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
pacman::p_load(R.matlab, tidyverse, here, weights, flextable,reshape2, raveio, rstatix, hdf5r, DescTools)
pacman::p_load(nlme,emmeans)
pacman::p_load(ggthemes)
#==============================================================================#
# Step 2: Customize basename for script                                        #
#==============================================================================#
basename    <- "peakFreq" # Edit
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

#==============================================================================#
# Step 2: Data Modeling                                                        #
#==============================================================================#

# electrode level peak frequency
df.elec <- import.peakfreq.elec %>% left_join(elecinfo, by=c("chan"="chan")) %>% 
  fx.add.group_assignments(dat.clin) %>% filter(position == "SCALP") %>% drop_na() %>% 
  rename(value = peakFreq) 

#%>% group_by(eegid, position, group,sex) %>% 
#  dplyr::summarize(value = mean(value))

# Base LME model includes group, sex, lower band, and resting state network (RSN)
fit.1 <- nlme::lme(value~group*sex, random = ~1|eegid, method="ML",
                   correlation=corCompSymm(form=~1|eegid), data=df.elec)
anova(fit.1)

fit.2 <- nlme::lme(value~group*sex*region, random = ~1|eegid, method="ML",
                   correlation=corCompSymm(form=~1|eegid), data=df.elec)


anova(fit.1,fit.2)
anova(fit.2)

# selected model
fit.final <- fit.2

# least-squared means
emc <- emmeans(fit.final, ~ group*sex*region)
estimates <- broom::tidy(emc, conf.int = TRUE, conf.level = .95)
emc <- emmeans(fit.final, ~ sex)
estimates <- broom::tidy(emc, conf.int = TRUE, conf.level = .95)

estimates %>% ggplot() + 
  geom_jitter(aes(x=group, color=sex, y = estimate), shape=21,
              position = position_dodge2(width = .3)) + 
  facet_wrap(~vars(region)) +
  theme_minimal()


# get paired significant contrasts
pairs_by_group<- broom::tidy(pairs(emc, by = c("group","sex"), adjust='none')) %>% 
  group_by(contrast) %>% mutate(adj.p = p.adjust(p.value,method = "fdr", n = n())) %>% 
  select(-term,-null.value)

# ---------------------------------------------------------------------------- #
# EXPORT TABLE
# Description: Summary pairwise comparisons of AAC (with significance stars)

target_file.table1 <- str_replace(target_file, ".RData", "table_pairwise.docx")

ft.pairs.tmp <- pairs_by_group %>% ungroup() %>%  select(lowerband, RSN, estimate, adj.p) %>% 
  mutate(estimate = weights::rd(estimate,2),
         estimate = paste0(estimate, add_sig_stars(adj.p, cutoffs = c(0.01, 0.001, 0.0001)))) %>% 
  select(-adj.p) %>% 
  pivot_wider(names_from = RSN, values_from = estimate)

ft.pairs <- ft.pairs.tmp %>% flextable()
ft.pairs <- set_header_labels(ft.pairs, 
                              values = list(lowerband, "AAC"))




pairs_by_group %>% filter(RSN != "other") %>% 
  ggplot() + 
  geom_pointrange(aes(x=RSN, y=estimate, fill=lowerband,ymin=estimate-std.error,
                      ymax=estimate+std.error),
                  shape=21,size=1) + theme_Publication() +
  ylab("AAC Contrast (FXS-TDC)")
ggsave(filename = str_replace(target_file, ".RData", "pairs.pdf"))




# =========================== GGSEG GROUP PLOTS OF AAC =========================
# Create group dataset for plotting with ggseg
df.ggseg <- df.aac  %>% group_by(powertype, group, sex, lowerband, label) %>% 
  select(-value) %>% 
  summarize(value = mean(z)) %>% 
  left_join(nodeinfo %>% select(Name, labelclean), 
            by=c("label"="labelclean")) %>% ungroup() %>% 
  mutate(ggseglabel = paste0(str_split(Name, " ",simplify=TRUE)[,2],"h_",
                             str_split(Name, " ",simplify=TRUE)[,1]) %>% str_to_lower()) %>% select(-label,-Name) %>% 
  rename(label = ggseglabel) 

df.ggseg

dkcustom <- dkextra
dkcustom$data <- dkextra$data %>% filter(side %in% c('superior','lateral'))
dkcustom$data
df.ggseg %>% filter(powertype == "relative") %>% 
  group_by(group, lowerband) %>%
  ggplot() +
  geom_brain(atlas = dkcustom, 
             position = position_brain(hemi ~ side),
             aes(fill = value)) +
  facet_grid(cols = vars(lowerband), rows=vars(group))+theme(legend.position = "bottom") + 
  scale_fill_gradientn(colours = c("blue", "white","firebrick"),na.value="white", limits=c(-.2,.2)) +
  labs(title="AAC") + theme_Publication() +
  theme(strip.background = element_blank(), panel.grid.major = element_blank()) +
  ggsave(filename = str_replace(target_file, ".RData", "ggseg.pdf"))

# Is there a difference between group by band*sex (FXS-TDC)
pairs_by_group<- broom::tidy(pairs(emc, by = c("lowerband","RSN"), adjust='none')) %>% 
  group_by(contrast) %>% mutate(adj.p = p.adjust(p.value,method = "fdr", n = n())) %>% 
  select(-term,-null.value)

ft.pairs <- pairs_by_group %>% ungroup() %>%  select(lowerband, RSN, estimate) %>% 
  pivot_wider(names_from = RSN, values_from = estimate)

pairs_by_group %>% filter(RSN != "other") %>% 
  ggplot() + 
  geom_pointrange(aes(x=RSN, y=estimate, fill=lowerband,ymin=estimate-std.error,
                      ymax=estimate+std.error),
                  shape=21,size=1) + theme_Publication() +
  ylab("AAC Contrast (FXS-TDC)")
ggsave(filename = str_replace(target_file, ".RData", "pairs.pdf"))

sig.table <- pairs_by_group %>% select(lowerband, RSN, adj.p) %>% 
  mutate(stars = add_sig_stars(adj.p, cutoffs = c(0.05, 0.01, 0.001))) %>% 
  filter(RSN != "other") %>% mutate(lowerband = factor(lowerband, levels=c("theta","alpha1","alpha2")))

ggplot(aes(), data = df.aac %>% filter(powertype == "relative") %>% filter(RSN !="other") %>% 
         group_by(eegid, group, RSN,lowerband) %>% 
         dplyr::summarize(value = mean(z))) + 
  geom_hline(yintercept = 0) +
  geom_boxplot(aes(x=RSN, y=value, fill=group), color="black", position = "dodge2",
               width=.7, alpha=.8,outlier.shape = NA) +
  geom_jitter(aes(x=RSN, y=value, fill=group), alpha = .3,
              pch = 21, color = "black", position = position_jitterdodge(jitter.width = .1)) +
  geom_text(aes(x = RSN, y=.5, label=stars), size=6, data=sig.table) +
  scale_color_manual(values = colors_group) + 
  scale_fill_manual(values = colors_group) +
  ylim(c(-.7,.7)) +
  facet_grid(cols = vars(lowerband)) +
  theme_Publication() +
  theme(strip.background = element_blank(), panel.grid.major = element_blank()) +
  xlab("Resting State Network") + ylab("gamma1 CFC (Fisher Z)")
ggsave(filename = str_replace(target_file, ".RData", "means.pdf"))

#==============================================================================#
# Step 3:          Assign model to output/export variable model.output         #
# =============================================================================#
model.output <- dat.pow.rel.long

#==============================================================================#
# Step 4: Export data                                                          #
# =============================================================================#

save(model.output, file = target_file)

