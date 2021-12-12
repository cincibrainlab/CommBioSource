#==============================================================================#
# RepMake           Reproducible Manuscript Toolkit with GNU Make               #
#==============================================================================#
# FIGURE SCRIPT    ============================================================#
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

pacman::p_load(lsmeans)
#==============================================================================#
# Step 2: Customize basename for script                                        #
#==============================================================================#
basename    <- "demographics_iq" # Edit
prefix      <- paste0("figure_", basename)
print(paste0("Current Asset: ", prefix))
#==============================================================================#
# Step 3: Specify any RData to load into environment when script is run. We    #
#         recommend creating a model script (with the same base name) to load  #
#         and wrangle dataset and save to a single RData file. This will allow #
#         multiple figures and tables without having to re-import data. Use    #
#         NA if no data is necessary.                                          #
#==============================================================================#
data_file   <- "Build/model_demographics.RData" # any RData inputs (or NA)
print(paste0("Input Data: ", data_file))
#==============================================================================#
# Step 4: Specify External Image File (use NA if not needed)                   #
#         An external image will be combined with a caption and directly saved #
#         to a word document.                                                  #
#==============================================================================#
external_figure = NA                                                           #  
print(paste0("External Figure: ", data_file))                                  #
#==============================================================================#
# Step 5: Specify target file for interactive RStudio (no modification needed) #                                                           #
#==============================================================================#
target_file <- if(!is.na(target_file)) {target_file=target_file} else here(outFile(prefix, "PDF")) # RSTUDIO default output file                  #
print(paste0("Output File: ", target_file))
#==============================================================================#

#==============================================================================#
#                                 FIGURE                                       #
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
# FIGURE CREATION  ============================================================#
#                  Generate single plot below. May combine multiple plots into #
#                  single figure. Figure output should be assigned to variable #
#                  p.output below.                                             #
#==============================================================================#
# Step 1: Create plot                                                          #
#==============================================================================#

# Operation: ANOVA of NIQ by group
# Compute the analysis of variance for IQ

fit.nviq <- aov(NVIQ ~ group * sex, data=dat.demo_iq)
#dat.table_nviq_stats <- apa_print(fit.nviq)$table %>% assign_in(list(1, 3), "Group*Sex")
dat.table_nviq_estimates <- lsmeans::lsmeans(fit.nviq, ~ group:sex) %>% as_data_frame()%>% 
  dplyr::select(-df) %>% mutate(across(where(is.numeric), round,2))

# Figure: Boxplot of NVIQ
p.demo_iq <- dat.demo_iq %>% ggplot(aes(x = subgroup, y = sbs_nvz, fill = subgroup)) +
  geom_boxplot(outlier.size = 0, alpha = .2) +
  scale_y_continuous(breaks = seq(-10, 2, 2)) +
  geom_point(aes(fill = subgroup, shape = sex),
             color = "black", size = 8,
             position = position_jitterdodge(jitter.width = 0.75), alpha = 0.8
  ) +
  scale_shape_manual(values = c(24, 21)) +
  scale_fill_manual(values = colors_subgroup) +
  scale_color_manual(values = colors_subgroup) +
  theme_bw(base_size = 30) +
  theme(
    axis.text.x = element_text(colour = "black"),
    axis.text.y = element_text(colour = "black"), legend.position = "none"
  ) +
  xlab("Group") +
  ylab("Non-verbal IQ z-score")

#==============================================================================#
# Step 1B: Optional add multiple plots to save file to create panels                                                          #
#==============================================================================#

# resave(p.demo_iq, file=panel_data_file)

# =============================================================================#

#==============================================================================#
# Step 2:          Assign plot to output/export variable p.output              #
#                  This plot will be exported.                                 #
#                  *Use NA if using an external image.                         #
# =============================================================================#
p.output <- p.demo_iq
# =============================================================================#
# FIGURE CAPTION   ============================================================#
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
caption_Search_Term <- "\\*Figure 1"  # edit. use '\' to escape special chars
selected_Caption <- searchCaptions(all_Captions, caption_Search_Term)
#==============================================================================#
# Step 3: Create word document with caption text for merging                   #
# =============================================================================#
caption_file_docx <- getCaptionDoc( selected_Caption )
# =============================================================================#

# =============================================================================#
# EXPORT FIGURES  ============================================================#
#                 By default code creates a high quality PNG and a vector PDF 
#                 (for Illustrator or inkscape). The target_file is required as 
#                 file names automatically generated from the stem. By default
#                 ggsave is used but any system that can export to PNG or PDF
#                 can be used with the same file name specifiers. 
#==============================================================================#
# Step 1          generate PNG, PDF, and DOCX file names (PNG is temporary)    #
#                 OR                                                           #
#                 if external figure will save PNG.                            #
#                 * external_figure must be set to NA to avoid if statement    #
# =============================================================================#
if(is.na(external_figure)){
  figure_pdf_filename <- outFile(target_file, "PDF")
  figure_png_filename <- paste0(tempfile(),'.png')
} else {
  figure_png_filename <- external_figure
}  
doc_filename <- outFile(target_file, "DOCX")

#==============================================================================#
# Step 2          save plot in both PNG and PDF formats                        #
#                 will only run if external_figure is NA                       #
# =============================================================================#
if(is.na(external_figure)){
  ggsave(p.output, filename = figure_pdf_filename, dpi=300, colormodel = "cmyk")
  ggsave(p.output, filename = figure_png_filename, dpi=300)
}
#==============================================================================#
# Step 3 scale PNG image for word document                                     #
# =============================================================================#
scaling_factor = 1 # proportion of 1
pngdim <- png_dimensions(figure_png_filename) * scaling_factor
#==============================================================================#
# Step 4 combine caption file and PNG into single word file (target_file)      #
# =============================================================================#
saveFigureWithCaption( caption_file_docx, 
                       figure_png_filename, 
                       doc_filename,  height = pngdim[1], width = pngdim[2])

print(target_file)
#==============================================================================#
# RepMake          Reproducible Manuscript Toolkit with GNU Make               #
#                  Version 8/2021                                              #
#                  cincibrainlab.com                                           #
# =============================================================================#