#==============================================================================#
# REPMAKE          Reproducible Manuscript Toolkit with GNU Make               #
#==============================================================================#
# MODEL SCRIPT     ============================================================#
                   basename <- "peakFreqSource" # TITLE
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
       clininfo <- read_csv("Source/datasets/fxs_group_list.csv")
       
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

         target_file.between_table <- str_replace(target_file, ".RData", "_between_table.docx")
         target_file.within_table <- str_replace(target_file, ".RData", "_within_table.docx")
         target_file.atlas_figure <- str_replace(target_file, ".RData", "_atlas_figure.pdf")
         target_file.intraregion_figure <- str_replace(target_file, ".RData", "_intraregion_figure.pdf")
         target_file.group_table <- str_replace(target_file, ".RData", "_group_table.docx")
         target_file.group_figure <- str_replace(target_file, ".RData", "_group_figure.pdf")
         target_file.nodetable <- str_replace(target_file, ".RData", "_node_table.docx")
         target_file.node_figure <- str_replace(target_file, ".RData", "_node_figure.pdf")
         target_file.PafCorrelations <- str_replace(target_file, ".RData", "forCorr.RData")
                   
# START R SCRIPT   ============================================================#

# Load data set
import.peakfreq.source <- read_csv("Source/datasets/P1_source_peakFreq.csv")

# electrode level peak frequency
df.source <- import.peakfreq.source %>% 
  left_join(nodeinfo, by=c("Electrode"="labelclean")) %>% 
  left_join(clininfo, by=c("eegid"="eegid")) %>% 
  rename(value = peakFreq) %>% 
  drop_na() %>% 
  mutate(side = ifelse(nchar(region) < 3, 
                       substring(region,1, nchar(region)-1), 
                       substring(region,1, nchar(region)-2)),
         zone = substring(region,2, nchar(region))) %>% 
  mutate(zone = factor(zone, levels=c("PF","F","L","T","P","C","O"),
                       labels=c("Prefrontal", "Frontal", "Lingula", "Temporal", 
                                "Parietal","Central","Occipital")),
         side = factor(side, levels=c("L","R"), labels = c("Left","Right"))) %>% 
  filter(zone %in% c("Occipital","Parietal","Frontal"))  



#==============================================================================#
# ANALYSIS #1      ============================================================#
#                  Between group analysis
#==============================================================================#

#==============================================================================#
# LME: Group, sex, and zone
#==============================================================================#

# Base LME model includes group, sex, lower band, and resting state network (RSN)
fit.1 <- nlme::lme(value~group*sex*zone, random = ~1|eegid, method="ML",
                   correlation=corCompSymm(form=~1|eegid), data=df.source)
anova(fit.1)  # laterality did not matter

# numDF denDF  F-value p-value
# (Intercept)        1  4452 9761.976  <.0001
# group              1   140   22.539  <.0001
# sex                1   140    0.017  0.8967
# zone               3  4452   57.585  <.0001
# group:sex          1   140    0.018  0.8949
# group:zone         3  4452    7.246  0.0001
# sex:zone           3  4452    2.537  0.0549
# group:sex:zone     3  4452    3.481  0.0152

# selected model
fit.final <- fit.1

# least-squared means
emc <- emmeans(fit.final, ~ group*sex*zone)
estimates <- broom::tidy(emc, conf.int = TRUE, conf.level = .95) %>% 
  mutate(zone = factor(zone, levels = c("Occipital","Parietal","Central","Frontal")))

# get paired significant contrasts
pairs_by_group<- broom::tidy(pairs(emc, by = c("zone","sex"), adjust='none')) %>% 
  group_by(contrast) %>% mutate(adj.p = p.adjust(p.value,method = "fdr", n = n())) %>% 
  select(-term,-null.value) %>% ungroup() %>% select(-p.value) %>% 
  mutate(estimate = weights::rd(estimate,2),
         std.error = weights::rd(std.error,2),
         statistic = weights::rd(statistic,1),
         adj.p = scales::pvalue(adj.p))

# get paired significant contrasts - across zones
pairs_by_group.zone<- broom::tidy(pairs(emc, by = c("group","sex"), adjust='none')) %>% 
  group_by(contrast) %>% mutate(adj.p = p.adjust(p.value,method = "fdr", n = n())) %>% 
  select(-term,-null.value) %>% ungroup() %>% select(-p.value)

#==============================================================================#
# LME 1: Group, sex, and zone
#==============================================================================#

# get mean values for summary table
peakmeans <- estimates %>% 
  mutate(mean = paste0(rd(estimate,1)," \u00B1 ",rd(std.error,2)),
         ploty = estimate) %>% 
  select(group, sex, zone, mean, ploty) %>% 
  pivot_wider(names_from = group,values_from = c(mean,ploty)) %>% 
  left_join(pairs_by_group, by=c("zone","sex")) %>%
  relocate(c(starts_with("FXS"),starts_with("TDC")),.before = estimate)

# Create significance stars for between group plots
peakmean.plot <- peakmeans %>% mutate(ploty = (ploty_FXS+ploty_TDC)/2,
                                      stars = add_sig_stars(adj.p)) %>% 
  select(sex,zone, statistic, ploty,  stars, adj.p) %>% 
  mutate(stars = ifelse(stars == "","",stars))

#==============================================================================#
# LME 1: Group Table
#==============================================================================#
peakmeans <- estimates %>% 
  mutate(mean = paste0(rd(estimate,1),"\u00B1", rd(std.error,2))) %>% 
  select(group, sex, zone, mean) %>% 
  pivot_wider(names_from = group,values_from = c(mean)) %>% 
  left_join(pairs_by_group, by=c("zone","sex")) %>% select(-contrast) %>% 
  relocate(c(starts_with("FXS"),starts_with("TDC")),.before = estimate) %>% 
  relocate(zone, .before=sex) %>% 
  flextable() %>% 
  set_header_labels(label = "Node",
                    region = "Region",
                    TDC = "Control",
                    sex = "Sex",
                    zone = "Region",
                    estimate = "FXS-Control",
                    std.error = "SE",
                    df = "DF",
                    statistic = "F",
                    adj.p = "5% FDR") %>% 
  flextable::merge_v(j=1) %>% 
  flextable::valign(j = 1,valign = "top") %>% 
  autofit() %>% fix_border_issues() %>% 
  save_as_docx(path = target_file.group_table) 

peakmeans

#==============================================================================#
# LME 1: Plot
#==============================================================================#

# New facet label names for dose variable
sex.labs <- c(M = "Male", F = "Female")
subgroup.labs <- c(FXS_F = "FXS(F)",FXS_M = "FXS(M)")

estimates %>% 
  mutate(subgroup = paste0(group,"_",sex)) %>%
  ggplot() + 
  geom_line(aes(group = subgroup,  color=subgroup, y=estimate, x=zone), size=1) +
  geom_pointrange(aes(x=zone, fill=subgroup, 
                      y=estimate, ymin=estimate-std.error, ymax=estimate+std.error), size=.8, shape=21) + 
  scale_fill_manual(values = colors_subgroup2) + 
  scale_color_manual(values = colors_subgroup2) + 
  geom_text(aes(x=zone, y=9.5, label=stars), nudge_x=0, angle=0, size=6, data=peakmean.plot) +
  facet_grid(cols=vars(sex), labeller = labeller(sex = sex.labs)) + 
  theme_Publication() + theme(strip.background = element_blank()) +
  xlab("Cortical Region") + ylab("PAF (Hz)") + ylim(7.5,10)
ggsave(filename=target_file.group_figure, width = 6,height = 4)

#==============================================================================#
# ANALYSIS #2      ============================================================#
#                  Intra-regional, within-group analysis
#==============================================================================#

plot.zone <- pairs_by_group.zone  %>% 
  mutate(region1 = strsplit(contrast," - ") %>% map_chr(., 1),
         region2 = strsplit(contrast," - ") %>% map_chr(., 2)) %>% 
  mutate(subgroup = paste0(group,"_",sex)) %>%
  select(group,sex,subgroup, region1,region2,estimate,df, statistic,std.error,adj.p) 

plot.zone.within <- plot.zone %>% 
  filter(region1 %in% c("Parietal","Occipital") & region2 %in% c("Parietal","Occipital") |
           region1 %in% c("Parietal","Frontal") & region2 %in% c("Parietal","Frontal") |
           region1 %in% c("Occipital","Frontal") & region2 %in% c("Occipital","Frontal")) %>% 
  mutate(reverse = ifelse(region1 %in% c("Parietal","Frontal"), TRUE, FALSE),
         reverse = ifelse(region1 %in% c("Parietal") & region2 %in% c("Occiptal"), TRUE, reverse),
         reverse = ifelse(region1 %in% c("Frontal") & region2 %in% c("Occiptal"), TRUE, reverse),
         regionA = ifelse(reverse==TRUE, region2, region1),
         regionB = ifelse(reverse==TRUE, region1, region2),
         contrast = paste0(regionA,"-",regionB),
         estimate = ifelse(reverse==TRUE, estimate * -1, estimate),
         contrast = factor(contrast, 
                           levels=c("Occipital-Frontal","Occipital-Parietal", "Parietal-Frontal")),
         stars = add_sig_stars(adj.p),
         offx = ifelse(contrast == "Occipital-Parietal",0,+.45) ) 
  # select(subgroup, reverse, region1, region2, offx, contrast, estimate,  std.error, adj.p)

#==============================================================================#
# LME 2: Plot
#==============================================================================#

plot.zone.within %>% 
  mutate(nonsig = ifelse(stars == "", "n.s.", "")) %>% 
  ggplot() +
  geom_line(aes(group=subgroup, color=subgroup,  x=contrast, y=estimate), linetype="dotted") +
    geom_pointrange(aes(x=contrast, y=estimate, ymin=estimate-std.error, 
                      ymax=estimate+std.error, group=subgroup, fill=subgroup), shape=21,size=1) +
  geom_hline(aes(yintercept=0), size = .2) +
  geom_text(aes(x=contrast, y=estimate, label=stars), nudge_y=-.05, nudge_x=-.2+plot.zone.within$offx, angle=0, size=6) +
  geom_text(aes(x=contrast, y=estimate, label=nonsig), nudge_y=0, nudge_x=-.2+plot.zone.within$offx, angle=0, size=4) +
  scale_fill_manual(values = colors_subgroup2) + 
  scale_color_manual(values = colors_subgroup2) + 
  ylim(-1,1) + ylab("Change in PAF (Hz)") + xlab("Region1 - Region2 Contrast") +
  theme_Publication()
ggsave(filename=target_file.intraregion_figure, width = 4,height = 4)

#==============================================================================#
# LME 1: Table
#==============================================================================#

plot.zone.within %>% select(group, sex, contrast,estimate, 
                            std.error, statistic, adj.p,stars) %>% 
  mutate(estimate = weights::rd(estimate,2),
         std.error = weights::rd(std.error,2),
         statistic = weights::rd(statistic,1),
         adj.p = scales::pvalue(adj.p),
         mean = paste0(estimate, "\u00B1", std.error, stars)) %>% 
  select(contrast, sex, group, mean) %>% 
  pivot_wider(names_from = contrast, values_from = c(mean)) %>%
  relocate('Occipital-Parietal', .after = group) %>% 
  flextable() %>% merge_v(j=1) %>% set_header_labels(values = c("sex"="Sex","group" ="Group")) %>% 
  autofit() %>% fix_border_issues() %>% 
  save_as_docx(path = target_file.within_table) 


#==============================================================================#
# ANALYSIS #3      ============================================================#
#                  Node level view of Alpha Peak Frequency
#==============================================================================#

#==============================================================================#
# GGSEG ATLAS FOR SUPPLEMENT
#==============================================================================#
ggseg(atlas = dkextra, mapping = aes(fill = region)) +
  scale_fill_brain("dk")
ggsave(filename = target_file.atlas_figure)


# Higher resolution view
df.source2 <- import.peakfreq.source %>% 
  left_join(nodeinfo, by=c("Electrode"="labelclean")) %>% 
  left_join(clininfo, by=c("eegid"="eegid")) %>% 
  rename(value = peakFreq) %>% 
  drop_na()

df.paf <- df.source2 %>% select(eegid, label, value, region, RSN)
save(df.paf, file = target_file.PafCorrelations)

#==============================================================================#
# LME 2: Group X Sex X Label
#==============================================================================#
# Base LME model includes group, sex, lower band, and resting state network (RSN)
fit.2 <- nlme::lme(value~group*sex*label, random = ~1|eegid, method="ML",
                   correlation=corCompSymm(form=~1|eegid), data=df.source2)
anova(fit.2)  # laterality did not matter

# least-squared means
emc.2 <- emmeans(fit.2, ~ group*label)
estimates.2 <- broom::tidy(emc.2, conf.int = TRUE, conf.level = .95) 

# get paired significant contrasts
pairs_by_group.2 <- broom::tidy(pairs(emc.2, by = c("label"), adjust='none')) %>% 
  group_by(contrast) %>% mutate(adj.p = p.adjust(p.value,method = "fdr", n = n())) %>% 
  select(-term,-null.value) %>% ungroup() %>% select(-p.value) 

df.ggseg <- pairs_by_group.2 %>% rename(Name = label) %>% 
  mutate(ggseglabel = paste0(str_split(Name, " ",simplify=TRUE)[,2],"h_",
                             str_split(Name, " ",simplify=TRUE)[,1]) %>% str_to_lower()) %>% 
  rename(label = ggseglabel,
         value = statistic)
df.ggseg

#==============================================================================#
# LME 3: Node-level Plot
#==============================================================================#
# T-values
p.tvals <- df.ggseg %>% 
ggseg(atlas = dkextra, view="lateral", mapping = aes(fill = value)) + 
  scale_fill_gradientn(colours = c("blue", "white","firebrick"),na.value="gray", limits=c(-5,5)) +
  theme(legend.position = "bottom" , legend.text = element_text(size = 7))  
ggsave(filename = target_file.node_figure)

#==============================================================================#
# LME 3: Node-Level Table
#==============================================================================#

est_for_merge <- estimates.2 %>% select(group, label, estimate, std.error) %>%  
  mutate(meanse = paste0(rd(estimate,2), "\u00B1", rd(std.error,2))) %>% 
  select(-estimate, -std.error) %>% pivot_wider(names_from = group, values_from = meanse)


ft.elecpeak <- pairs_by_group.2 %>% left_join(est_for_merge,
                                            by=c("label")) %>%
  left_join(nodeinfo %>% select(label,region), by=c("label")) %>% 
  relocate(c(region, FXS,TDC),.before = estimate) %>% filter(adj.p <=  .05) %>% 
  arrange(statistic) %>% select(-contrast) %>% 
  mutate(estimate = weights::rd(estimate,2),
         std.error = weights::rd(std.error,2),
         statistic = weights::rd(statistic,1),
         adj.p = scales::pvalue(adj.p)) %>%  
  flextable() %>% 
  set_header_labels(label = "Node",
                    region = "Region",
                    sex = "Sex",
                    zone = "Region",
                    estimate = "FXS-TDC",
                    std.error = "SE",
                    df = "DF",
                    statistic = "F",
                    adj.p = "5% FDR") %>% 
  flextable::merge_v(j=1) %>% 
  flextable::valign(j = 1,valign = "top") %>% 
  autofit() %>% fix_border_issues() %>% 
  save_as_docx(path = target_file.nodetable) 


#==============================================================================#
# EXPORT TABLE
 # see above
#==============================================================================#
  
