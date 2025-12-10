# ==============================================================================
# MATH 452 PROJECT: NETFLIX VIEWING HABITS ANALYSIS
# Ellie Burton
# Description:
# The script first imports and cleans raw Netflix data. It then generates
# exploratory visualizations to illustrate viewing patterns. Finally, 
# the code checks assumptions and performs a Kruskal-Wallis rank sum test
# to determine if viewing intensity varies significantly by day of the week.
# ==============================================================================

# --- STEP 1: LOAD LIBRARIES ---
if(!require(tidyverse)) install.packages("tidyverse")
if(!require(lubridate)) install.packages("lubridate")
if(!require(ggpubr)) install.packages("ggpubr") # For nice QQ plots

library(tidyverse)
library(lubridate)
library(ggpubr)

theme_set(theme_minimal(base_family = "serif"))


# --- STEP 2: LOAD AND CLEAN DATA ---
# Ensure 'ViewingActivity.csv' is in your working directory
df <- read_csv("ViewingActivity.csv")

# Clean column names (spaces become dots, e.g., "Start Time" -> "Start.Time")
colnames(df) <- make.names(colnames(df))

# Initial Filter & Transformation (Session Level)
session_df <- df %>%
  # 1. Remove non-content rows (Hooks, Trailers, etc.)
  filter(!Supplemental.Video.Type %in% c("HOOK","TRAILER","BONUS_VIDEO","TEASER_TRAILER","TUTORIAL","RECAP")) %>%
  
  # 2. Time Conversions
  mutate(
    Start_DateTime = ymd_hms(Start.Time),
    Date = as_date(Start_DateTime),
    Duration_Minutes = period_to_seconds(hms(Duration)) / 60
  ) %>%
  
  # 3. Filter invalid rows
  filter(!is.na(Start_DateTime)) %>%
  
  # 4. PARSE TITLES
  # Logic: Movies usually have 0 or 1 colon. TV shows usually have 2+ (Show: Season: Episode)
  mutate(
    Type = ifelse(str_count(Title, ":") >= 2, "TV Show", "Movie"),
    # Extract just the Show Name (everything before the first colon)
    Show_Name = str_split_fixed(Title, ":", 3)[,1]
  )

# --- STEP 2.5: CURIOSITY QUESTIONS (Exploratory Analysis) ---

print("--- CURIOSITY CHECK 1: TOTAL WATCH TIME ---")
total_hours <- sum(session_df$Duration_Minutes, na.rm = TRUE) / 60
total_days <- total_hours / 24
cat(sprintf("Total Hours Watched: %.2f\n", total_hours))
cat(sprintf("Total Days of Life Spent on Netflix: %.2f\n", total_days))

print("--- CURIOSITY CHECK 2: TOP 5 BINGED SHOWS ---")
top_shows <- session_df %>%
  filter(Type == "TV Show") %>%
  group_by(Show_Name) %>%
  summarise(Hours_Watched = sum(Duration_Minutes) / 60) %>%
  arrange(desc(Hours_Watched)) %>%
  slice(1:5)
print(top_shows)

print("--- CURIOSITY CHECK 3: MOVIES VS TV SHOWS RATIO ---")
content_ratio <- session_df %>%
  group_by(Type) %>%
  summarise(Total_Minutes = sum(Duration_Minutes)) %>%
  mutate(Percentage = round(Total_Minutes / sum(Total_Minutes) * 100, 1))
print(content_ratio)


# --- STEP 3: AGGREGATION (ACTIVE DAYS ONLY) ---
# Goal: Calculate TOTAL minutes watched per active day.

daily_df <- session_df %>%
  group_by(Date) %>%
  summarise(Total_Minutes = sum(Duration_Minutes)) %>%
  mutate(
    # Re-derive Weekday and Month from the Date
    Day_of_Week = wday(Date, label = TRUE, abbr = FALSE),
    Month = month(Date, label = TRUE, abbr = FALSE),
    # Ensure factor order is correct
    Day_of_Week = factor(Day_of_Week, levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))
  )

# --- STEP 3.5: DATE RANGE CHECK ---
min_date <- min(daily_df$Date)
max_date <- max(daily_df$Date)

print("--- DATA TIMELINE ---")
cat(sprintf("Start Date: %s\n", min_date))
cat(sprintf("End Date:   %s\n", max_date))
cat(sprintf("Total Days Spanned: %s\n", max_date - min_date))

# --- STEP 3.6: MONTHLY ACTIVITY TABLE ---
# Counts how many individual things (rows) were watched per month
print("--- ROW COUNT PER MONTH ---")
monthly_counts <- session_df %>%
  mutate(Month_Year = format(Date, "%Y-%m")) %>%
  group_by(Month_Year) %>%
  summarise(
    Items_Watched = n(),
    Total_Hours = sum(Duration_Minutes) / 60
  ) %>%
  arrange(Month_Year)

print(monthly_counts)

# --- STEP 3.7: RECORD BREAKING DAY ---
# Finds the single day with the absolute highest viewing time
print("--- MOST ACTIVE DAY EVER ---")
record_day <- daily_df %>%
  arrange(desc(Total_Minutes)) %>%
  slice(1) %>%
  mutate(Total_Hours = Total_Minutes / 60)

print(record_day)


# --- STEP 4: VISUALIZATION ---

# Visualization 1: Time Series (Line Plot)
p_timeline <- ggplot(daily_df, aes(x = Date, y = Total_Minutes)) +
  geom_line(color = "steelblue", alpha = 0.6) +
  geom_smooth(method = "loess", color = "darkred", se = FALSE) + # Adds a trend line
  theme_minimal(base_family = "serif") + # Explicitly ensuring Serif
  labs(
    title = "Timeline of My Netflix Addiction",
    subtitle = paste("Daily Watch Time from", min_date, "to", max_date),
    x = "Date",
    y = "Minutes Watched per Day"
  )
print(p_timeline)

# Visualization 2: Boxplot of Daily Consumption
p1 <- ggplot(daily_df, aes(x = Day_of_Week, y = Total_Minutes, fill = Day_of_Week)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(color="black", alpha=0.1, width=0.2) + # Shows individual active days
  theme_minimal(base_family = "serif") +
  labs(
    title = "Netflix Binge Intensity by Day of Week",
    subtitle = "Total Minutes Watched (Active Days Only)",
    x = "Day of Week",
    y = "Total Minutes Watched"
  ) +
  theme(legend.position = "none")
print(p1)

# Visualization 3: Density Plot (Shows the shape of the data)
p2 <- ggplot(daily_df, aes(x = Total_Minutes, fill = Day_of_Week)) +
  geom_density(alpha = 0.5) +
  facet_wrap(~Day_of_Week, ncol = 4) +
  theme_minimal(base_family = "serif") +
  labs(
    title = "Distribution of Viewing Minutes by Day",
    x = "Minutes Watched",
    y = "Density"
  ) +
  theme(legend.position = "none")
print(p2)

# Visualization 5: Heatmap (Hour vs Day) - FIXED METHODOLOGY
# NEW LOGIC: Normalize by "Active Days" to be consistent with ANOVA

# 1. Count how many ACTIVE days exist for each weekday (and convert to character for join)
active_day_counts <- daily_df %>%
  group_by(Day_of_Week) %>%
  summarise(n_active_days = n()) %>%
  mutate(Day_of_Week = as.character(Day_of_Week)) # FORCE TO CHARACTER

print("--- Active Days per Weekday ---")
print(active_day_counts)

# 2. Prep Heatmap Data
heatmap_data <- session_df %>%
  mutate(
    Day_of_Week = wday(Start_DateTime, label = TRUE, abbr = FALSE),
    Hour = hour(Start_DateTime)
  ) %>%
  # Force to character immediately to avoid factor mismatch during join
  mutate(Day_of_Week = as.character(Day_of_Week)) %>%
  
  group_by(Day_of_Week, Hour) %>%
  summarise(Total_Minutes = sum(Duration_Minutes), .groups = 'drop') %>%
  
  # 3. Join the counts (Now both are characters, so it will work!)
  left_join(active_day_counts, by = "Day_of_Week") %>%
  
  # 4. Calculate Average
  mutate(Average_Minutes = Total_Minutes / n_active_days) %>%
  
  # 5. NOW we convert back to Factor with REVERSED levels for plotting
  mutate(Day_of_Week = factor(Day_of_Week, 
                              levels = rev(c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))))

# Heatmap of AVERAGE INTENSITY (Active Days Normalized)
p_heatmap_avg <- ggplot(heatmap_data, aes(x = Hour, y = Day_of_Week, fill = Average_Minutes)) +
  geom_tile(color = "white") +
  scale_fill_viridis_c(option = "plasma") + 
  scale_x_continuous(breaks = 0:23) +
  theme_minimal(base_family = "serif") +
  labs(
    title = "Heatmap: Average Active Intensity",
    subtitle = "Minutes watched per hour slot (On days when I actually watch)",
    x = "Hour of Day",
    y = "Day of Week",
    fill = "Avg Min"
  )
print(p_heatmap_avg)

# --- STEP 5: ASSUMPTION CHECKING (DIAGNOSTICS) ---

# A. Normality Check (Shapiro-Wilk Test)
if(nrow(daily_df) < 5000) {
  shapiro_res <- shapiro.test(daily_df$Total_Minutes)
  print(paste("Shapiro-Wilk Normality Test p-value:", shapiro_res$p.value))
} else {
  print("Sample too large for Shapiro-Wilk. check Q-Q plot.")
}

# Visualization 4: Q-Q Plot
# ggpubr requires specifying the theme argument differently or adding it as a layer
p3 <- ggqqplot(daily_df$Total_Minutes, 
               title = "Q-Q Plot of Viewing Minutes",
               ylab = "Observed Minutes",
               xlab = "Theoretical Quantiles (Normal)",
               ggtheme = theme_minimal(base_family = "serif")) # Ensuring Serif here too
print(p3)


# --- STEP 6: STATISTICAL TEST (HYPOTHESIS TESTING) ---

# --- Kruskal-Wallis Test (Non-Parametric) ---
kruskal_res <- kruskal.test(Total_Minutes ~ Day_of_Week, data = daily_df)
print("--- Kruskal-Wallis Results (Non-Parametric) ---")
print(kruskal_res)

# --- END OF SCRIPT ---