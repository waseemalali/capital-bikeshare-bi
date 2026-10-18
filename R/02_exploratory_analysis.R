# Capital Bikeshare: exploratory analysis of the cleaned trip sample (with weather)
# Input: data/bikeshare_trips_sample_clean.csv (unzip data/bikeshare_trips_sample_clean.zip)

# Load required libraries
library(ggplot2)
library(dplyr)
library(lubridate)
library(gridExtra)  # For arranging multiple plots

# Read the dataset
df <- read.csv("data/bikeshare_trips_sample_clean.csv", stringsAsFactors = FALSE)

# Convert time columns to datetime format
df$started_at <- ymd_hms(df$started_at)
df$ended_at <- ymd_hms(df$ended_at)

# Extract additional time features
df$hour <- hour(df$started_at)
df$day_of_week <- wday(df$started_at, label = TRUE)
df$month <- month(df$started_at, label = TRUE)

# 1. Ride Duration by User Type
p1 <- ggplot(df, aes(x = member_casual, y = duration, fill = member_casual)) +
  geom_boxplot() +
  labs(title = "Ride Duration by User Type", x = "User Type", y = "Duration (seconds)") +
  theme_minimal()

# 2. Impact of Temperature on Ride Duration
p2 <- ggplot(df, aes(x = avg_temp, y = duration, color = member_casual)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm") +
  labs(title = "Impact of Temperature on Ride Duration", x = "Average Temperature (°C)", y = "Duration (seconds)") +
  theme_minimal()

# 3. Ride Distribution by Hour of Day
p3 <- df %>%
  group_by(hour) %>%
  summarise(count = n()) %>%
  ggplot(aes(x = hour, y = count)) +
  geom_line(color = "blue", linewidth = 1) +
  labs(title = "Ride Distribution Throughout the Day", x = "Hour of the Day", y = "Number of Rides") +
  theme_minimal()

# 4. Ride Distribution by Day of the Week
p4 <- df %>%
  group_by(day_of_week) %>%
  summarise(count = n()) %>%
  ggplot(aes(x = day_of_week, y = count, fill = day_of_week)) +
  geom_bar(stat = "identity") +
  labs(title = "Ride Distribution by Day of the Week", x = "Day of the Week", y = "Number of Rides") +
  theme_minimal()

# 5. Ride Duration vs. Distance (Calculated from Coordinates)
df$distance <- geosphere::distVincentySphere(
  matrix(c(df$start_lng, df$start_lat), ncol = 2),
  matrix(c(df$end_lng, df$end_lat), ncol = 2)
) / 1000  # Convert to kilometers

p5 <- ggplot(df, aes(x = distance, y = duration, color = member_casual)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm") +
  labs(title = "Ride Duration vs. Distance", x = "Distance (km)", y = "Duration (seconds)") +
  theme_minimal()

# 6. Average Ride Duration by Month
p6 <- df %>%
  group_by(month) %>%
  summarise(avg_duration = mean(duration)) %>%
  ggplot(aes(x = month, y = avg_duration, fill = month)) +
  geom_bar(stat = "identity") +
  labs(title = "Average Ride Duration by Month", x = "Month", y = "Average Duration (seconds)") +
  theme_minimal()

# Arrange all plots together
grid.arrange(p1, p2, p3, p4, p5, p6, ncol = 2)
correlation_matrix <- cor(df %>% select_if(is.numeric), use = "pairwise.complete.obs")
print(correlation_matrix)
library(ggcorrplot)
ggcorrplot(correlation_matrix, method = "circle", type = "upper", lab = TRUE)
