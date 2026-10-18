# Capital Bikeshare: relationship between temperature, rentals, and trip duration
# Adapted from Code 31 in the project report (report/Bike_Sharing_Jordan_Graduation_Project.pdf)
# Input: data/bikeshare_trips_sample_clean.csv (unzip data/bikeshare_trips_sample_clean.zip)

library(dplyr)
library(lubridate)
library(ggplot2)

general_sample <- read.csv("data/bikeshare_trips_sample_clean.csv", stringsAsFactors = FALSE) %>%
  mutate(
    started_at = ymd_hms(started_at),
    quarter_label = paste0(year(started_at), " Q", quarter(started_at))
  )

# combine data by quarters
quarterly_data <- general_sample %>%
  group_by(quarter_label) %>%
  summarise(
    total_rentals = n(),
    avg_duration = mean(duration, na.rm = TRUE),
    avg_temp = mean(avg_temp, na.rm = TRUE)
  )

# correlations
cor_temp_rentals <- cor(quarterly_data$avg_temp, quarterly_data$total_rentals, use = "complete.obs")
cor_temp_duration <- cor(quarterly_data$avg_temp, quarterly_data$avg_duration, use = "complete.obs")
cat("Correlation between temperature and total rentals:", cor_temp_rentals, "\n")
cat("Correlation between temperature and average duration:", cor_temp_duration, "\n")

# linear models
model_rentals <- lm(total_rentals ~ avg_temp, data = quarterly_data)
model_duration <- lm(avg_duration ~ avg_temp, data = quarterly_data)
summary(model_rentals)
summary(model_duration)

# temperature vs. total rentals
ggplot(quarterly_data, aes(x = avg_temp, y = total_rentals)) +
  geom_point() +
  geom_smooth(method = "lm", color = "red") +
  labs(title = "Temperature vs. Total Rentals", x = "Average Temperature (°C)", y = "Total Rentals")

# temperature vs. average duration
ggplot(quarterly_data, aes(x = avg_temp, y = avg_duration)) +
  geom_point() +
  geom_smooth(method = "lm", color = "red") +
  labs(title = "Temperature vs. Average Duration", x = "Average Temperature (°C)", y = "Average Duration (s)")
