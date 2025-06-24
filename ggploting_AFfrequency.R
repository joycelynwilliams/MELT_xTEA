# Load required libraries
library(ggplot2)
library(readr)
library(dplyr)

# Read the TSV file
df <- read_tsv("path/to/file")

# Convert AF column to numeric (ensure no character issues)
df$AF <- as.numeric(df$AF)
df %>% ggplot(aes(AF))+geom_density()

df %>% ggplot(aes(DP,AF))+geom_point()

ggplot(df, aes(x = AF)) +
  geom_density(aes(y = ..count..), fill = "salmon", alpha = 0.5, bw = 0.05) +
  scale_x_continuous(breaks = c(0, 0.5, 1)) +
  labs(
    title = "LINE-1 AF Value Density Distribution in Blood",
    x = "Allele Frequency (AF)",
    y = "Density (Scaled by Sample Count)"
    
  ) +
  theme_minimal()

