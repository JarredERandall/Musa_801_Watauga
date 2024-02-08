install.packages("ggmap")
library(ggmap)
library(dplyr)

# google geocoding api AIzaSyBz4P2Efdk7lb1AgWlLgnjvue6kHSibIlA
register_google(key = "AIzaSyBz4P2Efdk7lb1AgWlLgnjvue6kHSibIlA")

# read in data, ensure it has address columns
dat <- read.csv("E:\\UPenn\\24Spring\\MUSA_Practicum\\Data\\septic_permit\\new_permits_2022.csv")

# Combine 'Street.Address' and 'City' and 'State' columns to create a single address column called 'FullAddress'
dat$FullAddress <- paste(dat$Street.Address, dat$City, dat$State, sep = ", ")

# Assuming 'Street.Address' is the column containing addresses in your dataframe 'dat'
addresses <- dat$FullAddress

# Geocode addresses
locations <- geocode(addresses)

# Add latitude and longitude to the original dataframe
dat$lat <- locations$lat
dat$lon <- locations$lon

# Save the dataframe to a CSV file
write.csv(dat, "E:\\UPenn\\24Spring\\MUSA_Practicum\\Data\\septic_permit\\new_permits_2022_geocoded_google.csv", row.names = FALSE)






