# Capital Bikeshare: combine the monthly trip files, clean them, and take a 1% sample
# Input: monthly trip CSVs from https://s3.amazonaws.com/capitalbikeshare-data/index.html in data/raw/

library(dplyr)
library(readr)
library(janitor)

# List all CSV files
file_list <- list.files(path = "data/raw", pattern = "*.csv", full.names = TRUE)

# Define column mapping
column_mapping <- c(
  "start_date" = "started_at",
  "end_date" = "ended_at",
  "start_station_number" = "start_station_id",
  "start_station" = "start_station_name",
  "end_station_number" = "end_station_id",
  "end_station" = "end_station_name",
  "member_type" = "member_casual"
)

# Read and clean files
all_data <- lapply(file_list, function(file) {
  df <- read_csv(file)  # Read CSV file
  df <- clean_names(df)  # Standardize column names
  df <- df %>%
    rename_with(~ column_mapping[.x], .cols = intersect(names(df), names(column_mapping)))
  
  # Ensure consistency of IDs
  if ("start_station_id" %in% colnames(df)) {
    df$start_station_id <- as.character(df$start_station_id)
  }
  if ("end_station_id" %in% colnames(df)) {
    df$end_station_id <- as.character(df$end_station_id)
  }
  
  return(df)
})

# Combine all dataframes into a single dataframe
combined_df <- bind_rows(all_data)

# Manually set column types for combined data
combined_df <- combined_df %>%
  mutate(
    ride_id = as.character(ride_id),                 # Convert to character
    rideable_type = as.character(rideable_type),     # Convert to character
    started_at = as.POSIXct(started_at),             # Convert to datetime
    ended_at = as.POSIXct(ended_at),                 # Convert to datetime
    start_station_name = as.character(start_station_name),
    start_station_id = as.character(start_station_id),
    end_station_name = as.character(end_station_name),
    end_station_id = as.character(end_station_id),
    start_lat = as.numeric(start_lat),
    start_lng = as.numeric(start_lng),
    end_lat = as.numeric(end_lat),
    end_lng = as.numeric(end_lng),
    member_casual = as.character(member_casual)
  )

# ---- Data cleaning ----

# 1. Fill missing values (median for numeric, "unknown" for text)
combined_df <- combined_df %>%
  mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .))) %>%
  mutate(across(where(is.character), ~ ifelse(is.na(.), "unknown", .)))

# 2. Remove impossible values
combined_df <- combined_df %>%
  filter(
    started_at < ended_at,                    # start time must be before end time
    start_lat > -90 & start_lat < 90,         # valid latitude
    start_lng > -180 & start_lng < 180,       # valid longitude
    end_lat > -90 & end_lat < 90,
    end_lng > -180 & end_lng < 180
  )

# 3. Remove outliers with the IQR rule
numeric_columns <- c("start_lat", "start_lng", "end_lat", "end_lng")
for (col in numeric_columns) {
  Q1 <- quantile(combined_df[[col]], 0.25, na.rm = TRUE)
  Q3 <- quantile(combined_df[[col]], 0.75, na.rm = TRUE)
  IQR <- Q3 - Q1
  lower_bound <- Q1 - 1.5 * IQR
  upper_bound <- Q3 + 1.5 * IQR
  
  # keep values inside the bounds
  combined_df <- combined_df %>%
    filter(combined_df[[col]] >= lower_bound & combined_df[[col]] <= upper_bound)
}

# ---- Drop rows with an unknown rideable_type ----
combined_df <- combined_df %>%
  filter(rideable_type != "unknown")

# ---- Take a 1% random sample of all trips ----
sample_size <- max(floor(0.01 * nrow(combined_df)), 1)  # at least one row
sampled_df <- combined_df %>%
  sample_n(size = sample_size)

# Save the sample
write_csv(sampled_df, "data/sampled_data.csv")

# ---- Save the full cleaned data ----
write_csv(combined_df, "data/cleaned_combined_data.csv")

# Reload data for verification
cleaned_df <- read_csv("data/sampled_data.csv", show_col_types = FALSE)

# Display summary of the cleaned data
summary(cleaned_df)
