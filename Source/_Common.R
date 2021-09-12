# =============================================================================#
# RepMake           Reproducible Manuscript Toolkit with GNU Make              #
# =============================================================================#
# COMMON           ============================================================#
#                  This script should be included in each independent script   #
#                  as source('_Common.R'). The '_' ensures it can be sorted    #
#                  first in a directory. Common should include:                #
#                  * fixed study constants or parameters (i.e. subject number) #
#                  * common libraries or packages to load                      #
#                  * data sets that should be loaded before every script       #
#                  * command line parser code (for GNU Make compatability)     #
#                  * custom functions or routines                              #
#                  We recommend that first-time configuration (package install)#
#                  in a separate file called _setup_first_run.R                #
# =============================================================================#
# =============================================================================#
# CONFIGURATION    ============================================================#
#                  Define naming for output. File names in REPMAKE stay        #
#                  consistent between the script name and any output files.    #
#                  The prefix specifies the type of output (i.e., figure_).    #
#                  This code also automatically switches between a specific    #
#                  command line output file and if the script is run from      #
#                  RStudio. Note: Sensitive to capitalization and no spaces.   #
# =============================================================================#
# Step 1: Study Constants or Parameters                                        #
# =============================================================================#
 
  
  myCaptionFile <- "Source/_Captions.md"  # editable caption file
  
  
# =============================================================================#
# Step 2: Load Common Packages install.packages('pacman')                      #
# =============================================================================#

  # required packages for repmake
  install.packages(c('argparser','this.path','here'))
  
  # highly recommended packages
  install.packages(c('argparser','this.path','here'))
  
# =============================================================================#
# Step 3: Command line parser (Do not edit)                                    #
# =============================================================================#
if (!interactive()) {
  p <- arg_parser("R Script")
  p <- add_argument(p, "--o", help = "specific output file", default = NA)
  argv <- parse_args(p)
  target_file <- here::here(argv$o)
  print(paste0("CLI Target: ", target_file))
} else {
  target_file <- NA
  print("Interactive Mode")
}

# =============================================================================#
# Step 4: Define Datasets                                                      #
# =============================================================================#
fx.addDataSetPath <- function(filename) {  # set correct path
  dataPath <- here::here("Source/datasets")
  addPath <- file.path(dataPath, filename)
}

# =============================================================================#
# Step 5: Set included versus excluded                                         #
# =============================================================================#

# Helper function for filenames
outFile <- function(prefix, typeOfOutput) {
  fn <- switch(typeOfOutput,
    "SCRIPT" = ".R",
    "PNG" = ".png",
    "RDATA" = ".RData",
    "TABLE" = ".docx",
    "FIGURE" = ".png",
    "PDF" = ".pdf",
    "REPORT" = "_report.docx",
    "DOCX" = ".docx"
  )
  fn <- paste0("Build/", tools::file_path_sans_ext(basename(prefix)), fn)
  return(fn)
}

# Shared functions ----
`%notin%` <- Negate(`%in%`)
validateTotalNumberOfSubjects <- function(test_n, valid_n) {
  assertthat::assert_that(test_n == valid_n,
    msg = "Total Number of Subjects Incorrect"
  )
}

### CAPTION FUNCTIONS ####

loadCaptions <- function(captionFile) {
  tryCatch(
    {
      all_Captions <- captionFile %>%
        readr::read_lines(skip_empty_rows = TRUE) %>%
        as_tibble()
    },
    error = function(e) {
      all_Captions <<- NA
    }
  )
  return(all_Captions)
}

searchCaptions <- function(all_Captions, search_Term) {
  selected_Caption <- all_Captions %>%
    filter(stringr::str_detect(value, search_Term)) %>%
    as.character()
  stopifnot(nrow(selected_Caption) == 1)
  return(selected_Caption)
}

getCaptionDoc <- function(selected_Caption) {
  tmpmd <- tempfile(pattern = "file", tmpdir = tempdir(), fileext = ".md")
  caption_docx <- tempfile(pattern = "file", tmpdir = tempdir(), fileext = ".docx")
  write(selected_Caption, tmpmd)
  rmarkdown::pandoc_convert(input = tmpmd, output = caption_docx)
  return(caption_docx)
}

png_dimensions <- function(external_figure) {
  require(png)
  dim_pixels <- readPNG(external_figure) %>% dim() # height x width (pixels)
  dim_width <- 6.5
  dim_height <- dim_width * (dim_pixels[1] / dim_pixels[2])
  return(c(dim_height, dim_width))
}

saveFigureWithCaption_old <- function(caption_file_docx, original_target_file, height = 6.5, width = 6.5) {
  read_docx(caption_file_docx) %>%
    body_add_img(original_target_file, width = width, height = height) %>%
    print(target = paste0(tools::file_path_sans_ext(original_target_file), ".docx"))
}

# saveFigureWithCaption: combine a docx with a caption, insert a figure (png, pdf)
# file (which can be scaled), and output to a combined target docx.

saveFigureWithCaption <- function(caption_file_docx, figure_filename,
                                  target_document_file, height = 6.5, width = 6.5) {
  read_docx(caption_file_docx) %>%
    body_add_img(figure_filename, width = width, height = height) %>%
    print(target = target_document_file)
}

saveIllustrationWithCaption <- function(caption_file_docx, original_illustration_file,
                                        target_document_file, height = 6.5, width = 6.5) {
  read_docx(caption_file_docx) %>%
    body_add_img(original_illustration_file, width = width, height = height) %>%
    print(target = target_document_file)
}

# save word document with caption and table
saveTableWithCaption <- function(caption_file_docx, table_file_docx, original_target_file) {
  # merge to single documents
  read_docx(caption_file_docx) %>%
    body_add_docx(table_file_docx) %>%
    print(target = original_target_file)
}

#==============================================================================#
# RepMake          Reproducible Manuscript Toolkit with GNU Make               #
#                  Version 8/2021                                              #
#                  cincibrainlab.com                                           #
# =============================================================================#