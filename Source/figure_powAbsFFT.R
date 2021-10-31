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
#==============================================================================#
# Step 2: Customize basename for script                                        #
#==============================================================================#
basename    <- "powAbsFFT" # Edit
prefix      <- paste0("figure_", basename)
print(paste0("Current Asset: ", prefix))
#==============================================================================#
# Step 3: Specify any RData to load into environment when script is run. We    #
#         recommend creating a model script (with the same base name) to load  #
#         and wrangle dataset and save to a single RData file. This will allow #
#         multiple figures and tables without having to re-import data. Use    #
#         NA if no data is necessary.                                          #
#==============================================================================#
data_file   <- "Build/model_powAbsFFT.RData" # any RData inputs (or NA)
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
target_file <- if(!is.na(target_file)) {target_file=target_file} else          #
  here(outFile(prefix, "DOCX")) # RSTUDIO default output file                  #
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
# from model file
df.plot <- model.output %>% group_by(subgroup, freq) %>% 
  summarize(across(where(is.numeric), 
                   list(mean = function(x) {mean(x, na.rm = T)},
                        se = function(x) {sd(x, na.rm = T) / sqrt(sum(!is.na(x)))},
                        lower = function(x) {mean(x, na.rm = T) + 
                            qt(0.05, sum(!is.na(x)) - 1) * sd(x, na.rm = T) / sqrt(sum(!is.na(x)))},
                        upper = function(x) {mean(x, na.rm = T) + 
                            qt(0.95, sum(!is.na(x)) - 1) * sd(x, na.rm = T) / sqrt(sum(!is.na(x)))}))) %>% 
  rename(GroupMean = value_mean,
         GroupCI1 = value_lower,
         GroupCI2 = value_upper)


df.plot$freq


p.pow <- df.plot %>%
  ggplot(aes(x=freq, color=subgroup)) +
  geom_line(aes(y=GroupMean), size=1.2) +
  geom_line(aes(y=GroupCI1), size=0.25,linetype="dashed")+
  geom_line(aes(y=GroupCI2), size=0.25,linetype="dashed") + theme_bw()+
  theme(plot.margin = unit(c(0,0,0,0), "cm")) +
  scale_color_manual(values  = colors_subgroup) +
  geom_vline(xintercept = c(2))+
  scale_x_continuous(expand = c(0,0),limits = c(2,32), breaks = scales::pretty_breaks(n = 10))+
  scale_y_continuous(breaks = scales::pretty_breaks(n = 5)) +
  theme( text = element_text(size=20),
         axis.text.x = element_text(colour = "black", size=20),
         axis.text.y = element_text(colour = "black", size=20), legend.position = "bottom")+
  theme(panel.grid.major.x = element_blank(), panel.grid.minor.x = element_blank(),
        legend.position = "none") +
  labs(y = expression(Absolute~Power~(mV^2)), x = "Frequency (Hz)")

p.pow

p.gamma <- df.plot %>%
  ggplot(aes(x=freq, color=subgroup)) +
  geom_line(aes(y=GroupMean*freq, alpha=ifelse(freq > 55 & freq < 65, .2,1)), size=1.2) +
  geom_line(aes(y=GroupCI1*freq), size=0.25,linetype="dashed")+
  geom_line(aes(y=GroupCI2*freq), size=0.25,linetype="dashed") + theme_bw() +
  theme_Publication() +
  #geom_rect(aes(NULL, NULL, xmin=55, xmax=65), ymin=-Inf, ymax=Inf,fill="white", color="white", alpha=.2)+
  #annotate("text", y=0,x=60,  color="black", label=expression(notch), angle = 0,size=6) +
  scale_color_manual(values  = colors_subgroup) +
  theme( text = element_text(size=16),
         axis.text.x = element_text(colour = "black", size=10),
         axis.text.y = element_text(colour = "black", size=10))+
  theme(aspect.ratio = 1/1.3, panel.grid.major.x = element_blank(), panel.grid.minor.x = element_blank(), 
        panel.border = element_rect(),
        plot.background = element_rect(fill = "transparent", colour = NA),
        legend.position = "none")+
  geom_segment(aes(x=55,xend=65,y=.7e-12,yend=.7e-12), lineend="butt", color="black", size=1) + 
  scale_x_continuous(limits = c(30,90), breaks = scales::pretty_breaks(n = 5)) +
  scale_y_continuous(limits = c(.7e-12,1.4e-11), breaks = scales::pretty_breaks(n = 5)) +
  labs(y = expression(Absolute~Power~(mV^2)~x~Hz), x = "Frequency (Hz)")

p.gamma

pacman::p_load(egg)
p.output <- p.pow + 
  annotation_custom(
    ggplotGrob(p.gamma), 
    xmin = 12, xmax = 30, ymin=2e-12)

# =============================================================================#

#==============================================================================#
# Step 2:          Assign plot to output/export variable p.output              #
#                  This plot will be exported.                                 #
#                  *Use NA if using an external image.                         #
# =============================================================================#
p.output <- p.pow
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
caption_Search_Term <- "TBD"  # edit. use '\' to escape special chars
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
  ggsave(p.output, filename = figure_pdf_filename, dpi=300, colormodel = "cmyk",width = 7, height = 6)
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
#==============================================================================#
# RepMake          Reproducible Manuscript Toolkit with GNU Make               #
#                  Version 8/2021                                              #
#                  cincibrainlab.com                                           #
# =============================================================================#