#==============================================================================#
# RepMake           Reproducible Manuscript Toolkit with GNU Make               #
#==============================================================================#
# _SETUP_FIRST     ============================================================#
#                  This script should be run when configuring the project for  #
#                  first time on a new install or a new project.               #
#                  * include installation steps or notes for a new install     #
#                  * have code on how to authenticate github                   #
#==============================================================================#
#==============================================================================#
# SECTION 1: Installation of Required Libraries or Packages                             #              #
# =============================================================================#
  # required packages for repmake
  install.packages('pacman')
  pacman::p_load(argparser, here, this.path)

#==============================================================================#
# SECTION 2: Platform Specific Notes                                           #
# =============================================================================#
# on debian-linux install for pandoc: 
#  sudo apt-get install r-base-dev libcairo2-dev libgsl-dev

#==============================================================================#
# SECTION 3: Optional Libraries or Packages                                    #     #
# =============================================================================#
# install.packages("pacman") % efficient package manager for R
# devtools::install_github("aphanotus/borealis")
# remotes::install_github("conig/corx@devel", force=TRUE)
# remotes::install_github("HenrikBengtsson/R.matlab@develop")
# install.packages('kableExtra')
# devtools::install_github("davidgohel/officer")
# install.packages("devtools")
# install.packages('BiocManager')
# install.packages('tinytex')
# devtools::install_github("crsh/papaja@devel")
# devtools::install_github("jfrancoiscollin/ClinReport")
# devtools::install_github("crsh/papaja@devel")
# pacman::p_delete(corx)
# Install development 
# devtools::install_github("conig/corx@devel")
