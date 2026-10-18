# Capital Bikeshare: 5-year ARIMA forecast of monthly rentals, evaluated with MAPE
# Adapted from Code 32 in the project report (report/Bike_Sharing_Jordan_Graduation_Project.pdf)
# Input: data/bikeshare_trips_sample_clean.csv (unzip data/bikeshare_trips_sample_clean.zip)

library(forecast)

general_sample <- read.csv("data/bikeshare_trips_sample_clean.csv", stringsAsFactors = FALSE)
general_sample$started_at_date <- as.Date(substr(general_sample$started_at, 1, 10))

# daily rentals to monthly rentals
daily_rentals <- as.data.frame(table(general_sample$started_at_date))
colnames(daily_rentals) <- c("date", "total_rentals")
daily_rentals$date <- as.Date(daily_rentals$date)
daily_rentals$year_month <- format(daily_rentals$date, "%Y-%m")

monthly_rentals <- aggregate(total_rentals ~ year_month, data = daily_rentals, sum)
colnames(monthly_rentals) <- c("month", "total_rentals")
monthly_rentals$month <- as.Date(paste0(monthly_rentals$month, "-01"))

# time series object
months.ts <- ts(monthly_rentals$total_rentals,
                start = c(as.numeric(format(min(monthly_rentals$month), "%Y")),
                          as.numeric(format(min(monthly_rentals$month), "%m"))),
                frequency = 12)

decomp <- decompose(months.ts)

# fit ARIMA on all data and forecast 5 years
forecast_horizon <- 12 * 5
fit <- auto.arima(months.ts)
forecast_values <- forecast(fit, h = forecast_horizon)

# hold out the last 12 months to measure accuracy
train_size <- length(months.ts) - 12
train_ts <- window(months.ts, end = time(months.ts)[train_size])
test_ts  <- window(months.ts, start = time(months.ts)[train_size + 1])

fit_train <- auto.arima(train_ts)
test_forecast <- forecast(fit_train, h = length(test_ts))

mape <- mean(abs((test_ts - test_forecast$mean) / test_ts)) * 100
cat("MAPE:", round(mape, 2), "%\n")

# plot the 5-year forecast (actual data in red)
plot(forecast_values, main = "5-year Forecast of Bike Rentals")
lines(months.ts, col = 2, lwd = 2)
