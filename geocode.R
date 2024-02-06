# install tidygeocoder package and read into environment (+dplyr)
install.packages("tidygeocoder")
library(tidygeocoder)
library(dplyr)

# read in data, ensure it has address columns
dat <- read.csv("INSERT DATA HERE")

# geocode data
# adjust input columns based on available data
dat_geocoded <- geocode(
  dat,
  method = "census", 
  address = FullAddress
      )