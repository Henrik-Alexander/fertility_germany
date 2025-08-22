####
# Project: Fertility in Germany
# Purpose: Meta-file
# Author: Henrik-Alexander Schubert
# Date: 2025/08/22
##

# Do you have internet connection?
internet_connection <- FALSE

### Create the folders =============================

folders <- c("code", "data", "raw", "figures")
lapply(folders, function(folder) if(!dir.exists(folder)) dir.create(folder))


### Load the raw data ===============================

# This function loads the German short-term fertility data
load_stfd <- function() {

  # Load the short-term fertility data
  path_stfd <- "https://www.humanfertility.org/File/GetDocumentFree/STFF/countries/DEUTNPstffout.csv"
  fert_stfd <- read.csv(path_stfd)
  write.csv(fert_stfd, file="raw/deutnp_stfd.csv")
  
  
  # Load the seasonally adjusted short term fertility data
  path_sa_stfd <- "https://www.humanfertility.org/File/GetDocumentFree/STFF/countries/adj/DEUTNPstffadjout.csv"
  fert_sa_stfd <- read.csv(path_sa_stfd)
  write.csv(fert_sa_stfd, file="raw/deu_stfd_sa.csv")

}

# Apply the function
if (internet_connection) load_stfd()


###

### END #############################################