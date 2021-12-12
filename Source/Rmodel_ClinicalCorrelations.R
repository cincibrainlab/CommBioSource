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
pacman::p_load(R.matlab, reshape2, tidyverse, emmeans, flextable, purrr)

#==============================================================================#
# Step 2: Customize basename for script                                        #
#==============================================================================#
basename    <- "ClinicalCorrelations" # Edit
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

load(file = "Build/model_sourcePowFromMat_forCorr.RData")
load(file = "Build/peakFreqSourceforCorr.RData") 
load(file = "Build/model_MneJunAAC_forCorr.RData")


#remotes::install_github("conig/corx@devel")

library(corx)

region_vars <-paste0("_", unique(dat.pow$region),"_")
label_vars <-paste0("_", gsub(" ","", unique(dat.pow$label)),"_")
label_vars2 <-paste0("_",  unique(dat.pow$label),"_")
rsn_vars <-paste0("_", unique(dat.pow$RSN),"_")


#==============================================================================#
# Step 2: Wrangle data as needed.                                              #
# =============================================================================#
source.clin <- read_csv("SourceBackup/datasets/fxssource_table_01_demographics_data.csv")

dat.clin <- source.clin %>% 
  mutate(subgroup = paste0(group,"(",sex,")"),
         mgroup = paste0(sex,mosaic)) %>% relocate(subgroup, mgroup, .after=group)

selectvars <- c(
  "sbs_nvz", "sbs_vz", "adams_anxiety",
  "adams_ocd", "scq_total", "abc_irritable",
  "abc_hyperactivity", "abc_speech",
  "abc_lethargy", "abc_stereotypy", "wj3", "visitage"
)


selectvars_noage <- selectvars[selectvars != "visitage"]

# inclusion IDs
includedEegIds <-  unique(dat.pow$eegid)

#==============================================================================#
# CUSTOM FUNCTIONS
#==============================================================================#

# create wide-table function
cleanPivotJoin <- function( dataset ){
  dataset %>% ungroup() %>% 
    select(eegid,bandname_label,value) %>% 
    pivot_wider(names_from = bandname_label, values_from = value) %>% 
    filter(eegid %in% includedEegIds)

}

getEegVars <- function( data_for_correlation, search_string ){
  list_bandnames <- as.character(search_string)
  eegvariables <- names(data_for_correlation %>% select(contains(list_bandnames)))
}

#==============================================================================#
# CLINICAL VARIABLES INTO WIDE FORMAT FOR JOINING
#==============================================================================#

forCorr.clin <- dat.clin %>% select(eegid, mgroup, group, subgroup, selectvars) %>% filter(eegid %in% includedEegIds)

#==============================================================================#
# SPECTRAL POWER : READY FOR CORRELATION TABLES
#==============================================================================#

forCorr.pow <- dat.pow %>% ungroup() %>% select(eegid,bandname,label,region,RSN,value) %>% 
  filter(bandname %in% c("theta","alpha1","alpha2","gamma1") )

forCorr.pow.node <- forCorr.pow %>% mutate(bandname_label = paste0(bandname,"_",label,"_label")) %>% 
  cleanPivotJoin()

forCorr.pow.region  <- forCorr.pow %>%  group_by(eegid, bandname,region) %>% 
  dplyr::summarize(value = mean(value)) %>% ungroup() %>% mutate(bandname_label = paste0(bandname,"_",region,"_region")) %>% 
  cleanPivotJoin()
  
forCorr.pow.rsn     <- forCorr.pow %>% filter(RSN != "other") %>% group_by(eegid, bandname,RSN) %>% 
  dplyr::summarize(value = mean(value)) %>% ungroup %>% mutate(bandname_label = paste0(bandname,"_",RSN,"_RSN")) %>% 
  cleanPivotJoin()

forCorr.all.pow <- forCorr.pow.node %>% 
  left_join(forCorr.pow.region, by=c("eegid")) %>% 
  left_join(forCorr.pow.rsn, by=c("eegid")) %>% 
  left_join(forCorr.clin, by=c("eegid")) %>% 
  relocate(eegid, group, subgroup, mgroup)

eegvariables.pow <- getEegVars(forCorr.all.pow, unique(dat.pow$bandname))

#==============================================================================#
# CREATE PEAK FREQUENCY TABLE                                                       #
#==============================================================================#

# create master dataset
forCorr.paf <- df.paf %>% select(eegid,label,RSN,region,value) %>% ungroup() %>% mutate(bandname = "PAF")

# create table for node, region, and RSN levels 
forCorr.paf.node    <- forCorr.paf %>% mutate(bandname_label = paste0(bandname,"_",label,"_paf")) %>% cleanPivotJoin()
forCorr.paf.region  <- forCorr.paf %>% group_by(eegid, bandname, region) %>% dplyr::summarize(value=mean(value)) %>% 
  ungroup() %>% mutate(bandname_label = paste0(bandname,"_",region,"_paf")) %>% cleanPivotJoin()
forCorr.paf.rsn <- forCorr.paf  %>% filter(RSN != "other") %>% group_by(eegid, bandname, RSN) %>% dplyr::summarize(value=mean(value)) %>% 
  ungroup() %>%  mutate(bandname_label = paste0(bandname,"_",RSN,"_paf")) %>% cleanPivotJoin()

forCorr.all.paf <- forCorr.paf.node %>% 
  left_join(forCorr.paf.region, by=c("eegid")) %>% 
  left_join(forCorr.paf.rsn, by=c("eegid")) %>% 
  left_join(forCorr.clin, by=c("eegid")) %>% 
  relocate(eegid, group, subgroup, mgroup)

eegvariables.paf <- getEegVars(forCorr.all.paf, "PAF")

#==============================================================================#
# CREATE AAC TABLES
#==============================================================================#

forCorr.aac <- df.aac %>% select(eegid, region, RSN,powertype, lowerband, upperband, label, z) %>% 
  rename(value = z) %>% mutate(bandname = paste0(powertype,"-",lowerband,"-",upperband))

forCorr.aac.node    <- forCorr.aac %>% 
  mutate(bandname_label = paste0(bandname,"_", label,"_aac")) %>% cleanPivotJoin()
forCorr.aac.region  <- forCorr.aac %>% group_by(eegid, bandname, region) %>% dplyr::summarize(value=mean(value)) %>% 
  ungroup()  %>% mutate(bandname_label = paste0(bandname,"_", region,"_aac"))  %>% cleanPivotJoin()
forCorr.aac.rsn     <- forCorr.aac %>% filter(RSN != "other")  %>% group_by(eegid, bandname, RSN) %>% dplyr::summarize(value=mean(value)) %>% 
  ungroup()  %>% mutate(bandname_label = paste0(bandname,"_", RSN,"_aac"))  %>% cleanPivotJoin()

forCorr.all.aac <- forCorr.aac.node %>% 
  left_join(forCorr.aac.region, by=c("eegid")) %>% 
  left_join(forCorr.aac.rsn, by=c("eegid")) %>% 
  left_join(forCorr.clin, by=c("eegid")) %>% 
  relocate(eegid, group, subgroup, mgroup, sex, visitage)

eegvariables.aac <- getEegVars(forCorr.all.aac, "aac")

#==============================================================================#
# CUSTOM CORRELATION FUNCTION
#==============================================================================#
runCorxAgeCorrect <- function(data_for_correlation, group_var, group_filter, clinical_variables, eeg_variables){
  
  data_prep <- data_for_correlation %>% filter(eval(parse(text = group_var))==group_filter) %>% 
    select(eegid,clinical_variables, eeg_variables, visitage)
  corx(data_prep, x=eeg_variables,y=clinical_variables, z=visitage, method="spearman")
  
}

runCorx <- function(data_for_correlation, group_var, group_filter, clinical_variables, eeg_variables){
  
  data_prep <- data_for_correlation %>% filter(eval(parse(text = group_var))==group_filter) %>% 
    select(eegid,clinical_variables, eeg_variables, visitage)
  corx(data_prep, x=eeg_variables,y=clinical_variables, method="spearman")
  
}

#==============================================================================#
# RUN CORRELATION AND ORGANIZE RESULTS
#==============================================================================#

eegvariables.pow.node <- getEegVars(forCorr.all.pow, label_vars2)
eegvariables.pow.region <- getEegVars(forCorr.all.pow, region_vars)
eegvariables.pow.rsn <- getEegVars(forCorr.all.pow, rsn_vars)

#==============================================================================#
# pow CORRELATION RESULTS
#==============================================================================#

res.pow.m1.node <- runCorx(forCorr.all.pow, "mgroup",'M1', selectvars, eegvariables.pow.node)
res.pow.m1.region <- runCorx(forCorr.all.pow, "mgroup",'M1', selectvars, eegvariables.pow.region)
res.pow.m1.rsn <- runCorx(forCorr.all.pow, "mgroup",'M1', selectvars, eegvariables.pow.rsn)

res.pow.m1.node_age <- runCorxAgeCorrect(forCorr.all.pow, "mgroup",'M1', selectvars, eegvariables.pow.node)
res.pow.m1.region_age <- runCorxAgeCorrect(forCorr.all.pow, "mgroup",'M1', selectvars, eegvariables.pow.region)
res.pow.m1.rsn_age <- runCorxAgeCorrect(forCorr.all.pow, "mgroup",'M1', selectvars,eegvariables.pow.rsn)

res.pow.m2.node <- runCorx(forCorr.all.pow, "mgroup",'M2', selectvars, eegvariables.pow.node)
res.pow.m2.region <- runCorx(forCorr.all.pow, "mgroup",'M2', selectvars, eegvariables.pow.region)
res.pow.m2.rsn <- runCorx(forCorr.all.pow, "mgroup",'M2', selectvars, eegvariables.pow.rsn)

res.pow.m2.node_age <- runCorxAgeCorrect(forCorr.all.pow, "mgroup",'M2', selectvars, eegvariables.pow.node)
res.pow.m2.region_age <- runCorxAgeCorrect(forCorr.all.pow, "mgroup",'M2', selectvars, eegvariables.pow.region)
res.pow.m2.rsn_age <- runCorxAgeCorrect(forCorr.all.pow, "mgroup",'M2', selectvars,eegvariables.pow.rsn)

res.pow.f3.node <- runCorx(forCorr.all.pow, "mgroup",'F3', selectvars, eegvariables.pow.node)
res.pow.f3.region <- runCorx(forCorr.all.pow, "mgroup",'F3', selectvars, eegvariables.pow.region)
res.pow.f3.rsn <- runCorx(forCorr.all.pow, "mgroup",'F3', selectvars, eegvariables.pow.rsn)

res.pow.f3.node_age <- runCorxAgeCorrect(forCorr.all.pow, "mgroup",'F3', selectvars, eegvariables.pow.node)
res.pow.f3.region_age <- runCorxAgeCorrect(forCorr.all.pow, "mgroup",'F3', selectvars, eegvariables.pow.region)
res.pow.f3.rsn_age <- runCorxAgeCorrect(forCorr.all.pow, "mgroup",'F3', selectvars,eegvariables.pow.rsn)

res.pow.fx.node <- runCorx(forCorr.all.pow, "group",'FXS', selectvars, eegvariables.pow.node)
res.pow.fx.region <- runCorx(forCorr.all.pow, "group",'FXS', selectvars, eegvariables.pow.region)
res.pow.fx.rsn <- runCorx(forCorr.all.pow, "group",'FXS', selectvars, eegvariables.pow.rsn)

res.pow.fx.node_age <- runCorxAgeCorrect(forCorr.all.pow, "group",'FXS', selectvars, eegvariables.pow.node)
res.pow.fx.region_age <- runCorxAgeCorrect(forCorr.all.pow, "group",'FXS', selectvars, eegvariables.pow.region)
res.pow.fx.rsn_age <- runCorxAgeCorrect(forCorr.all.pow, "group",'FXS', selectvars,eegvariables.pow.rsn)

# alpha1_frontalpole L_label -66 abc_stereotypy

#==============================================================================#
# POW RSN PLOT
#==============================================================================#

plot.pow.fx.stereo <- forCorr.all.pow %>% filter(mgroup %in% c("M1","M4")) %>% 
  select(subgroup, abc_stereotypy, `alpha1_frontalpole L_label`)

corlabel.rho <- round(cor(plot.pow.fx.stereo$abc_stereotypy, plot.pow.fx.stereo$`alpha1_frontalpole L_label`,
                          method = "spearman", use = "complete.obs"), 2)
corlabel.rho <- paste0("VIS: All FXS, rho=", corlabel.rho, ", p<.001*, n=64")
plotlabel <- paste0("VIS")

plot.pow.fx.stereo %>% 
  ggpubr::ggscatter(x ="alpha1_frontalpole L_label" , y="abc_stereotypy", 
                    fill = "subgroup", color = "black", size = 2.5, shape = "subgroup",
                    add = "reg.line",
                    conf.int = TRUE, 
                    add.params = list(
                      level = 0.95, color = "black",
                      fill = "azure2", alpha = .3
                    ),
                    legend.title = "Sex", legend = "",
                    xlab = "Alpha1-Gamma1 AAC", ylab = "ADAMS Anxiety (Higher is Worse)", title = ""
  ) +
  scale_shape_manual(values = c(24, 21)) +
  scale_fill_manual(values = c("darkorange2", "red")) +
  annotate("text", x = -.2, y = 8.5, label = corlabel.rho, hjust = 0, size = 5)+
  theme(aspect.ratio = 1)


#==============================================================================#
# PAF CORRELATION AND ORGANIZE RESULTS
#==============================================================================#

eegvariables.paf.node <- getEegVars(forCorr.all.paf, label_vars2)
eegvariables.paf.region <- getEegVars(forCorr.all.paf, region_vars)
eegvariables.paf.rsn <- getEegVars(forCorr.all.paf, rsn_vars)

#==============================================================================#
# PAF CORRELATION RESULTS
#==============================================================================#

res.paf.m1.node <- runCorx(forCorr.all.paf, "mgroup",'M1', selectvars, eegvariables.paf.node)
res.paf.m1.region <- runCorx(forCorr.all.paf, "mgroup",'M1', selectvars, eegvariables.paf.region)
res.paf.m1.rsn <- runCorx(forCorr.all.paf, "mgroup",'M1', selectvars, eegvariables.paf.rsn)

res.paf.m1.node_age <- runCorxAgeCorrect(forCorr.all.paf, "mgroup",'M1', selectvars, eegvariables.paf.node)
res.paf.m1.region_age <- runCorxAgeCorrect(forCorr.all.paf, "mgroup",'M1', selectvars, eegvariables.paf.region)
res.paf.m1.rsn_age <- runCorxAgeCorrect(forCorr.all.paf, "mgroup",'M1', selectvars,eegvariables.paf.rsn)

res.paf.m2.node <- runCorx(forCorr.all.paf, "mgroup",'M2', selectvars, eegvariables.paf.node)
res.paf.m2.region <- runCorx(forCorr.all.paf, "mgroup",'M2', selectvars, eegvariables.paf.region)
res.paf.m2.rsn <- runCorx(forCorr.all.paf, "mgroup",'M2', selectvars, eegvariables.paf.rsn)

res.paf.m2.node_age <- runCorxAgeCorrect(forCorr.all.paf, "mgroup",'M2', selectvars, eegvariables.paf.node)
res.paf.m2.region_age <- runCorxAgeCorrect(forCorr.all.paf, "mgroup",'M2', selectvars, eegvariables.paf.region)
res.paf.m2.rsn_age <- runCorxAgeCorrect(forCorr.all.paf, "mgroup",'M2', selectvars,eegvariables.paf.rsn)

res.paf.f3.node <- runCorx(forCorr.all.paf, "mgroup",'F3', selectvars, eegvariables.paf.node)
res.paf.f3.region <- runCorx(forCorr.all.paf, "mgroup",'F3', selectvars, eegvariables.paf.region)
res.paf.f3.rsn <- runCorx(forCorr.all.paf, "mgroup",'F3', selectvars, eegvariables.paf.rsn)

res.paf.f3.node_age <- runCorxAgeCorrect(forCorr.all.paf, "mgroup",'F3', selectvars, eegvariables.paf.node)
res.paf.f3.region_age <- runCorxAgeCorrect(forCorr.all.paf, "mgroup",'F3', selectvars, eegvariables.paf.region)
res.paf.f3.rsn_age <- runCorxAgeCorrect(forCorr.all.paf, "mgroup",'F3', selectvars,eegvariables.paf.rsn)

res.paf.fx.node <- runCorx(forCorr.all.paf, "group",'FXS', selectvars, eegvariables.paf.node)
res.paf.fx.region <- runCorx(forCorr.all.paf, "group",'FXS', selectvars, eegvariables.paf.region)
res.paf.fx.rsn <- runCorx(forCorr.all.paf, "group",'FXS', selectvars, eegvariables.paf.rsn)

res.paf.fx.node_age <- runCorxAgeCorrect(forCorr.all.paf, "group",'FXS', selectvars, eegvariables.paf.node)
res.paf.fx.region_age <- runCorxAgeCorrect(forCorr.all.paf, "group",'FXS', selectvars, eegvariables.paf.region)
res.paf.fx.rsn_age <- runCorxAgeCorrect(forCorr.all.paf, "group",'FXS', selectvars,eegvariables.paf.rsn)



#==============================================================================#
# AAC Examine Group Level Results First by Region and Network
#==============================================================================#

convertCorResultsToLongPow <- function( corrresults_matrix ){
  
  review.aac.fx.rsn.r <- corrresults_matrix  %>% as_tibble(rownames = "measure") %>%  
    rowwise() %>% 
    mutate(bandname = str_split(measure, pattern = "_", simplify = TRUE)[1],
           label = str_split(measure, pattern = "_", simplify = TRUE)[2],
           type = str_split(measure, pattern = "_", simplify = TRUE)[3]) %>% 
    relocate(bandname, label,type) %>% 
    select(-measure) %>%  
    pivot_longer(cols = sbs_nvz:visitage, names_to = "measure" )
}

convertCorResultsToLongPowNoAge <- function( corrresults_matrix ){
  
  review.aac.fx.rsn.r <- corrresults_matrix  %>% as_tibble(rownames = "measure") %>%  
    rowwise() %>% 
    mutate(bandname = str_split(measure, pattern = "_", simplify = TRUE)[1],
           label = str_split(measure, pattern = "_", simplify = TRUE)[2],
           type = str_split(measure, pattern = "_", simplify = TRUE)[3]) %>% 
    relocate(bandname, label,type) %>% 
    select(-measure) %>%  
    pivot_longer(cols = sbs_nvz:wj3, names_to = "measure" )
}

bind_r_p_n <- function( df_r, df_p, df_n ){
  final.df <- df_r %>% rename(r = value) %>% 
    bind_cols( df_p %>% 
                 rename(p = value) %>% 
                 select(p,adjp)) %>% 
    bind_cols(df_n %>% 
                rename(n=value) %>%  
                select(n)) %>% 
    arrange(adjp)
}


#==============================================================================#
# POW RSN Results
#==============================================================================#
review.pow.fx.rsn.r <- convertCorResultsToLongPow( res.pow.fx.rsn$r ) 
review.pow.fx.rsn.p <- convertCorResultsToLongPow( res.pow.fx.rsn$p ) %>%
  group_by(type) %>% mutate(adjp = p.adjust(value, method="fdr")) %>% ungroup()
review.pow.fx.rsn.n <- convertCorResultsToLongPow( res.pow.fx.rsn$n )

final.pow.fx.rsn <- bind_r_p_n(review.pow.fx.rsn.r, 
                               review.pow.fx.rsn.p, review.pow.fx.rsn.n)
final.pow.fx.rsn %>% filter(adjp < .05 & bandname != "delta")

#==============================================================================#
# POW RSN Results: AGE CORRECTED
#==============================================================================#
review.pow.fx.rsn_age.r <- convertCorResultsToLongPowNoAge( res.pow.fx.rsn_age$r ) 
review.pow.fx.rsn_age.p <- convertCorResultsToLongPowNoAge( res.pow.fx.rsn_age$p ) %>%
  group_by(type) %>% mutate(adjp = p.adjust(value, method="fdr")) %>% ungroup()
review.pow.fx.rsn_age.n <- convertCorResultsToLongPowNoAge( res.pow.fx.rsn_age$n )

final.pow.fx.rsn_age <- bind_r_p_n(review.pow.fx.rsn_age.r, 
                               review.pow.fx.rsn_age.p, review.pow.fx.rsn_age.n)
final.pow.fx.rsn_age %>% filter(adjp < .05 & bandname != "delta")

#==============================================================================#
# POW RSN Results: AGE CORRECTED  FULL MUTATION ONLY
#==============================================================================#
review.pow.m1.rsn_age.r <- convertCorResultsToLongPowNoAge( res.pow.m1.rsn_age$r ) 
review.pow.m1.rsn_age.p <- convertCorResultsToLongPowNoAge( res.pow.m1.rsn_age$p ) %>%
  group_by(type) %>% mutate(adjp = p.adjust(value, method="fdr")) %>% ungroup()
review.pow.m1.rsn_age.n <- convertCorResultsToLongPowNoAge( res.pow.m1.rsn_age$n )

final.pow.m1.rsn_age <- bind_r_p_n(review.pow.m1.rsn_age.r, 
                                   review.pow.m1.rsn_age.p, review.pow.m1.rsn_age.n)
final.pow.m1.rsn_age %>% filter(p < .05 & bandname != "delta")

final.pow.m1.rsn_age %>% arrange(p)

#==============================================================================#
# POW REGIONAL Results
#==============================================================================#

review.pow.m1.region.r <- convertCorResultsToLongPow( res.pow.m1.region$r ) 
review.pow.m1.region.p <- convertCorResultsToLongPow( res.pow.m1.region$p ) %>%
  group_by(type) %>% mutate(adjp = p.adjust(value, method="fdr")) %>% ungroup()
review.pow.m1.region.n <- convertCorResultsToLongPow( res.pow.m1.region$n )

final.pow.m1.region <- bind_r_p_n(review.pow.m1.region.r, 
                                  review.pow.m1.region.p, 
                                  review.pow.m1.region.n)
final.pow.m1.region

# Examine age related correlations (no effect of age on AAC)
final.pow.m1.region %>% filter(measure=="visitage") %>% arrange(p)

# identify significant correlations
final.pow.m1.region %>% filter(adjp <= .05)

review.pow.m1.region.r <- convertCorResultsToLongPowNoAge( res.pow.m1.region_age$r ) 
review.pow.m1.region.p <- convertCorResultsToLongPowNoAge( res.pow.m1.region_age$p ) %>%
  group_by(type) %>% mutate(adjp = p.adjust(value, method="fdr")) %>% ungroup()
review.pow.m1.region.n <- convertCorResultsToLongPowNoAge( res.pow.m1.region_age$n )

final.pow.m1.region <- bind_r_p_n(review.pow.m1.region.r, review.pow.m1.region.p, review.pow.m1.region.n)
final.pow.m1.region %>% arrange(adjp)

#==============================================================================#
# AAC RUN CORRELATION AND ORGANIZE RESULTS
#==============================================================================#

eegvariables.aac.label <- getEegVars(forCorr.all.aac, label_vars)
eegvariables.aac.region <- getEegVars(forCorr.all.aac, region_vars)
eegvariables.aac.rsn <- getEegVars(forCorr.all.aac, rsn_vars)


#==============================================================================#
# AAC CORRELATION RESULTS
#==============================================================================#

res.aac.m1.node <- runCorx(forCorr.all.aac, "mgroup",'M1', selectvars, eegvariables.aac.node)
res.aac.m1.region <- runCorx(forCorr.all.aac, "mgroup",'M1', selectvars, eegvariables.aac.region)
res.aac.m1.rsn <- runCorx(forCorr.all.aac, "mgroup",'M1', selectvars, eegvariables.aac.rsn)

res.aac.m1.node_age <- runCorxAgeCorrect(forCorr.all.aac, "mgroup",'M1', selectvars, eegvariables.aac.node)
res.aac.m1.region_age <- runCorxAgeCorrect(forCorr.all.aac, "mgroup",'M1', selectvars, eegvariables.aac.region)
res.aac.m1.rsn_age <- runCorxAgeCorrect(forCorr.all.aac, "mgroup",'M1', selectvars,eegvariables.aac.rsn)

res.aac.m2.node <- runCorx(forCorr.all.aac, "mgroup",'M2', selectvars, eegvariables.aac.node)
res.aac.m2.region <- runCorx(forCorr.all.aac, "mgroup",'M2', selectvars, eegvariables.aac.region)
res.aac.m2.rsn <- runCorx(forCorr.all.aac, "mgroup",'M2', selectvars, eegvariables.aac.rsn)

res.aac.m2.node_age <- runCorxAgeCorrect(forCorr.all.aac, "mgroup",'M2', selectvars, eegvariables.aac.node)
res.aac.m2.region_age <- runCorxAgeCorrect(forCorr.all.aac, "mgroup",'M2', selectvars, eegvariables.aac.region)
res.aac.m2.rsn_age <- runCorxAgeCorrect(forCorr.all.aac, "mgroup",'M2', selectvars,eegvariables.aac.rsn)

res.aac.f3.node <- runCorx(forCorr.all.aac, "mgroup",'F3', selectvars, eegvariables.aac.node)
res.aac.f3.region <- runCorx(forCorr.all.aac, "mgroup",'F3', selectvars, eegvariables.aac.region)
res.aac.f3.rsn <- runCorx(forCorr.all.aac, "mgroup",'F3', selectvars, eegvariables.aac.rsn)

res.aac.f3.node_age <- runCorxAgeCorrect(forCorr.all.aac, "mgroup",'F3', selectvars, eegvariables.aac.node)
res.aac.f3.region_age <- runCorxAgeCorrect(forCorr.all.aac, "mgroup",'F3', selectvars, eegvariables.aac.region)
res.aac.f3.rsn_age <- runCorxAgeCorrect(forCorr.all.aac, "mgroup",'F3', selectvars,eegvariables.aac.rsn)

res.aac.fx.node <- runCorx(forCorr.all.aac, "group",'FXS', selectvars, eegvariables.aac.node)
res.aac.fx.region <- runCorx(forCorr.all.aac, "group",'FXS', selectvars, eegvariables.aac.region)
res.aac.fx.rsn <- runCorx(forCorr.all.aac, "group",'FXS', selectvars, eegvariables.aac.rsn)

res.aac.fx.node_age <- runCorxAgeCorrect(forCorr.all.aac, "group",'FXS', selectvars, eegvariables.aac.node)
res.aac.fx.region_age <- runCorxAgeCorrect(forCorr.all.aac, "group",'FXS', selectvars, eegvariables.aac.region)
res.aac.fx.rsn_age <- runCorxAgeCorrect(forCorr.all.aac, "group",'FXS', selectvars,eegvariables.aac.rsn)


#==============================================================================#
# AAC Examine Group Level Results First by Region and Network
#==============================================================================#

convertCorResultsToLong <- function( corrresults_matrix ){

  review.aac.fx.rsn.r <- corrresults_matrix  %>% as_tibble(rownames = "measure") %>%  rowwise() %>% 
    mutate(powertype = str_split(measure, pattern = "-", simplify = TRUE)[1],
           lowband = str_split(measure, pattern = "-", simplify = TRUE)[2],
           highband = str_split( str_split(measure, "-", simplify = TRUE)[3], "_", simplify=TRUE)[1],
           label = str_split( str_split(measure, "-", simplify = TRUE)[3], "_", simplify=TRUE)[2],
           type = str_split( str_split(measure, "-", simplify = TRUE)[3], "_", simplify=TRUE)[3]) %>% 
    relocate(powertype, lowband, highband,label,type) %>% 
    select(-measure) %>%  
    pivot_longer(cols = sbs_nvz:visitage, names_to = "measure" )
}

bind_r_p_n <- function( df_r, df_p, df_n ){
  final.df <- df_r %>% rename(r = value) %>% 
    bind_cols( df_p %>% 
                 rename(p = value) %>% 
                 select(p,adjp)) %>% 
    bind_cols(df_n %>% 
                rename(n=value) %>%  
                select(n)) %>% 
    arrange(adjp)
}


#==============================================================================#
# AAC RSN Results
#==============================================================================#

review.aac.fx.rsn.r <- convertCorResultsToLong( res.aac.fx.rsn$r ) 
review.aac.fx.rsn.p <- convertCorResultsToLong( res.aac.fx.rsn$p ) %>%
  group_by(powertype) %>% mutate(adjp = p.adjust(value, method="fdr")) %>% ungroup()
review.aac.fx.rsn.n <- convertCorResultsToLong( res.aac.fx.rsn$n )

final.aac.fx.rsn <- bind_r_p_n(review.aac.fx.rsn.r, review.aac.fx.rsn.p, review.aac.fx.rsn.n)
final.aac.fx.rsn

#==============================================================================#
# AAC RSN PLOT
#==============================================================================#

plot.aac.fx.ocd <- forCorr.all.aac %>% filter(group == "FXS") %>% 
  select(subgroup, adams_ocd, `relative-alpha1-gamma1_VIS_aac`)

corlabel.rho <- round(cor(plot.aac.fx.ocd$adams_ocd, plot.aac.fx.ocd$`relative-alpha1-gamma1_VIS_aac`,
                          method = "spearman", use = "complete.obs"), 2)
corlabel.rho <- paste0("VIS: All FXS, rho=", corlabel.rho, ", p<.001*, n=64")
plotlabel <- paste0("VIS")

plot.aac.fx.ocd %>% 
  ggpubr::ggscatter(x ="relative-alpha1-gamma1_VIS_aac" , y="adams_ocd", 
                    fill = "subgroup", color = "black", size = 2.5, shape = "subgroup",
                    add = "reg.line",
                    conf.int = TRUE, 
                    add.params = list(
                      level = 0.95, color = "black",
                      fill = "azure2", alpha = .3
                    ),
                    legend.title = "Sex", legend = "",
                    xlab = "Alpha1-Gamma1 AAC", ylab = "ADAMS Anxiety (Higher is Worse)", title = ""
  ) +
  scale_shape_manual(values = c(24, 21)) +
  scale_fill_manual(values = c("darkorange2", "red")) +
  annotate("text", x = -.2, y = 8.5, label = corlabel.rho, hjust = 0, size = 5)+
  theme(aspect.ratio = 1)

#==============================================================================#
# AAC REGIONAL Results
#==============================================================================#

review.aac.m1.region.r <- convertCorResultsToLong( res.aac.m1.region$r ) 
review.aac.m1.region.p <- convertCorResultsToLong( res.aac.m1.region$p ) %>%
  group_by(powertype) %>% mutate(adjp = p.adjust(value, method="fdr")) %>% ungroup()
review.aac.m1.region.n <- convertCorResultsToLong( res.aac.m1.region$n )

final.aac.m1.region <- bind_r_p_n(review.aac.m1.region.r, review.aac.m1.region.p, review.aac.m1.region.n)
final.aac.m1.region

# Examine age related correlations (no effect of age on AAC)
final.aac.m1.region %>% filter(measure=="visitage") %>% arrange(p)

# identify significant correlations
final.aac.m1.region %>% filter(p <= .05)


#==============================================================================#
# AAC2 Region Results
#==============================================================================#

review.aac.fx.region.r <- convertCorResultsToLong( res.aac.fx.region$r ) 
review.aac.fx.region.p <- convertCorResultsToLong( res.aac.fx.region$p ) %>%
  group_by(powertype) %>% mutate(adjp = p.adjust(value, method="fdr")) %>% ungroup()
review.aac.fx.region.n <- convertCorResultsToLong( res.aac.fx.region$n )

final.aac.fx.region <- bind_r_p_n(review.aac.fx.region.r, review.aac.fx.region.p, review.aac.fx.region.n)
final.aac.fx.region

review.aac.m1.region.r <- convertCorResultsToLong( res.aac.m1.region$r ) 
review.aac.m1.region.p <- convertCorResultsToLong( res.aac.m1.region$p ) %>%
  group_by(powertype) %>% mutate(adjp = p.adjust(value, method="fdr")) %>% ungroup()
review.aac.m1.region.n <- convertCorResultsToLong( res.aac.m1.region$n )

final.aac.m1.region <- bind_r_p_n(review.aac.m1.region.r, review.aac.m1.region.p, review.aac.m1.region.n)
final.aac.m1.region

plot.aac.m1 <- forCorr.all.aac %>% filter(mgroup == "M1") 





# =========================== GGSEG GROUP PLOTS OF POW =========================
# Create group dataset for plotting with ggseg
df.ggseg <- df.gamma1.nvz  %>%  ungroup() %>% 
  mutate(ggseglabel = paste0(str_split(label, " ",simplify=TRUE)[,2],"h_",
                             str_split(label, " ",simplify=TRUE)[,1]) %>% tolower()) %>% 
  select(-label) %>% rename(value = sbs_nvz) %>% rename(label = ggseglabel)

df.ggseg <- df.alpha2.anxiety  %>%  ungroup() %>% 
  mutate(ggseglabel = paste0(str_split(label, " ",simplify=TRUE)[,2],"h_",
                             str_split(label, " ",simplify=TRUE)[,1]) %>% tolower()) %>% 
  select(-label) %>% rename(value = adams_anxiety) %>% rename(label = ggseglabel)


df.ggseg %>%
  ggplot() +
  geom_brain(atlas = dk, 
             position = position_brain(hemi ~ side),
             aes(fill = value)) +
  scale_fill_gradientn(colours = c("blue", "white","firebrick"),na.value="white", limits=c(-.7,.7)) 
  theme_Publication()
  


#> merging atlas and data by 'region'
dkcustom <- dkextra
dkcustom$data <- dkextra$data %>% filter(side %in% c('superior','lateral'))
dkcustom$data
df.ggseg %>% 
  ggplot() +
  geom_brain(atlas = dkcustom, 
             position = position_brain(hemi ~ side),
             aes(fill = value)) +
  theme(legend.position = "bottom") + 
  scale_fill_gradientn(colours = c("blue", "white","firebrick"),na.value="white", limits=c(-1,1)) +
  labs(title="AAC") + theme_Publication() +
  theme(strip.background = element_blank(), panel.grid.major = element_blank())
  ggsave(filename = str_replace(target_file, ".RData", "ggseg.pdf"))

facet_grid(cols = vars(lowerband), rows=vars(group))

 
paste0(str_split("lateraloccipital R", " ",simplify=TRUE)[,2],"h_",
       str_split("lateraloccipital R", " ",simplify=TRUE)[,1]) %>% stringr::str_to_lower()

  select(-label,-Name) %>% 
  rename(label = ggseglabel) 

df.ggseg



#==============================================================================#
# Step 1: Load MAT file with CFC results                                       #
#==============================================================================#



#==============================================================================#
# Step 3:          Assign model to output/export variable model.output         #
# =============================================================================#
model.output <- dat.pow.rel.long

#==============================================================================#
# Step 4: Export data                                                          #
# =============================================================================#

save(model.output, file = target_file)

