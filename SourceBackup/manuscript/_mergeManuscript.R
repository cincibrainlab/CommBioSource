# HEADER ----
args = commandArgs(trailingOnly=TRUE)
outfile <- here::here(args[1]) # output file
print(paste0('R target:', outfile))
RProjPath<-this.path::this.dir()
setwd(RProjPath)

protect <- function(p) if (file.exists(p)) stop("File exsits!") else p
unlink("tmpmerge.docx")

# merge main document
pacman::p_load(officer, magrittr) # may need xml2

main_doc <- read_docx()

args <- args[-1]

for(arg in args){
  print(arg)
  main_doc <- body_add_docx(main_doc, src = here::here(arg))
  main_doc <- body_add_break(main_doc,pos = "after")
}
print(main_doc, target = outfile)
