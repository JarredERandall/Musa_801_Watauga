library(tidyverse)
library(rvest)
library(httr)
library(sf)
library(RecordLinkage)
library(fuzzyjoin)

# Link Watauga permits from HTML web page to property data

# I can link about 2000 of 2500 permits. Some permits are just not linkable because of bad data
# There are 47K properties, so roughly 4% of our properties are "1", which is not great put not horrible.
# I haven't been able to scrape the dates

# OK so I selected all new permit applications and showed all 2570 on one page
# Let's read them in and try to join them to the parcels

# Set the URL
file_path <- "C:/Users/Michael/Downloads/watauga_props.htm"

# Read the HTML file
html_data <- read_html(file_path)

# Extract using CSS selectors
data <- html_data %>% html_table()

permits <- data[37] %>% as.data.frame()

df_clean <- permits %>%
  # Separate the File ID, PIN, and Permit columns
  separate(col = File.IDPINPermit.., 
           into = c("File_ID", "PIN", "Permit"), 
           sep = "\r\n\r\n|\r\n", 
           extra = "merge") %>%
  # Separate the Street Address, City, State, and ZIP Code columns
  separate(col = Street.Address..City..State..ZIP.Code, 
           into = c("Street_Address", "City", "State", "ZIP_Code"), 
           sep = "\r\n", 
           extra = "merge") %>%
  mutate(names = str_split(Owner.Name.Applicant.Name, "\r\n") %>% map_chr(1)) %>%
  # Split names separated by "/"
  separate(names, into = c("name1", "name2"), sep = " / ", extra = "merge", fill = "right") %>%
  # Clean up any leading/trailing whitespace
  mutate(across(everything(), ~trimws(.x, which = "both"))) %>%
  mutate(PIN = if_else(str_detect(PIN, "^\\d{4}-\\d{2}-\\d{4}$"), 
                       paste0(PIN, "-000"), 
                       PIN)) %>%
  separate(PIN, into = c("PIN", "rest"), sep = "[^0-9-]+", extra = "drop", fill = "right") %>%
  # Select only the first part
  select(-rest) %>%
  # Remove all non-numeric and non-hyphen characters
  mutate(PIN = str_replace_all(PIN, "[^0-9-]", "")) %>% 
  mutate(PIN = if_else(nchar(PIN) == 13, 
                                                     paste0(str_sub(PIN, 1, 4), "-", 
                                                     str_sub(PIN, 5, 6), "-", 
                                                     str_sub(PIN, 7, 10), "-", 
                                                     str_sub(PIN, 11, 13)), 
                              PIN)) %>%
  mutate(PIN = if_else(str_detect(PIN, "^\\d{4}-\\d{2}-\\d{4}$"), 
                       paste0(PIN, "-000"), 
                       PIN)) %>%
  mutate(name1 = toupper(name1),
         name2 = toupper(name2),
         Street_Address = toupper(Street_Address),
         City = toupper(City),
         State = toupper(State))

# Now load the parcels

values <- st_read("C:/Users/Michael/Documents/Clients/MUSA_Teaching_and_Admin/SPRING_STUDIO_2024/Boone/Data/Data/Housing Council/County Data/Property Values/PropertyValues.shp")

values <- values %>%
  mutate(year = year(mdy(DATERECORD))) %>%
  st_transform(2264)

# This nets 1946

test_join <- df_clean %>%
  left_join(., values, by = c("PIN" = "PARCELID")) %>%
  filter(is.na(OBJECTID) == FALSE, is.na(PIN) == FALSE)

# What to do about these?

# Join just on address

# This nets 68

test_join_addr <- df_clean %>%
  left_join(., values, by = c("Street_Address" = "PROPADDRES")) %>%
  filter(is.na(PIN.y) == FALSE, PARCELID != PIN.x)

# Might have to do some probability-based join using owner names.

fail_join <- df_clean %>%
  left_join(., values, by = c("PIN" = "PARCELID")) %>%
  filter(is.na(OBJECTID) == TRUE)

# Try a fuzzy join on multiple criteria

# This nets 21

result_name_addr <- stringdist_left_join(fail_join %>%
                                 select(PIN, Street_Address, name1) %>%
                                 rename(TXACCTNAME = name1,
                                        PROPADDRES = Street_Address,
                                        PARCELID = PIN) %>%
                                 na.omit(), 
                               values %>% 
                                 as.data.frame() %>%
                                 select(PARCELID, TXACCTNAME, PROPADDRES) %>%
                                 na.omit(), 
                               by = c("TXACCTNAME", "PROPADDRES"), max_dist = 4)

result_name_addr %>% filter(is.na(PARCELID.y) == FALSE) %>% nrow()

# This nets 48 (not sure what the overlap is with previous)

result_name_PIN <- stringdist_left_join(fail_join %>%
                                           select(PIN, Street_Address, name1) %>%
                                           rename(TXACCTNAME = name1,
                                                  PROPADDRES = Street_Address,
                                                  PARCELID = PIN) %>%
                                           na.omit(), 
                                         values %>% 
                                           as.data.frame() %>%
                                           select(PARCELID, TXACCTNAME, PROPADDRES) %>%
                                           na.omit(), 
                                         by = c("PARCELID", "TXACCTNAME"), max_dist = 4)

result_name_PIN %>% filter(is.na(PARCELID.y) == FALSE) %>% nrow()

# Don't do this -

# Try a prob match using ID, Address, Taxpayer name
# This takes forever and freezes shit up

rpairs <- compare.linkage(df_clean %>%
                            select(PIN, Street_Address, Owner.Name.Applicant.Name, File_ID) %>%
                            rename(TXACCTNAME = Owner.Name.Applicant.Name,
                                   PROPADDRES = Street_Address,
                                   PARCELID = PIN),
                          values %>% 
                            as.data.frame() %>%
                            select(PARCELID, TXACCTNAME, PROPADDRES, OBJECTID),
                          strcmp = TRUE,
                          exclude = c("File_ID", "OBJECTID"))
