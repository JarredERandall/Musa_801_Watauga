# install tidygeocoder package and read into environment (+dplyr)
install.packages("tidygeocoder")

library(tidygeocoder)
library(dplyr)

# read in data, ensure it has address columns
dat <- read.csv("E:\\UPenn\\24Spring\\MUSA_Practicum\\Data\\septic_permit\\new_permits_2017.csv")

# Combine 'Street.Address' and 'City' and 'State' columns to create a single address column called 'FullAddress'
dat$FullAddress <- paste(dat$Street.Address, dat$City, dat$State, sep = ", ")

# geocode data
# adjust input columns based on available data
dat_geocoded <- geocode(
  dat,
  method = "census", 
  address = FullAddress
      )

# Save the dataframe to a CSV file
write.csv(dat, "E:\\UPenn\\24Spring\\MUSA_Practicum\\Data\\septic_permit\\new_permits_2017_geocoded_census.csv", row.names = FALSE)