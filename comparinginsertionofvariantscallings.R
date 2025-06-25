# Load required libraries
library(tidyverse) # includes ggplot2, dplyr, readr, and %>%

# Read the TSV file
df <- read_tsv("/Volumes/data/523_LINE1.tsv")

# Convert AF column to numeric (ensure no character issues)
df <- df %>% mutate(AF = as.numeric(AF))

# Plot AF density distribution
df %>% 
  ggplot(aes(AF)) +
  geom_density(col = "pink3", alpha = 0.5) +
  labs(title = "LINE-1 Density Distribution of Allele Frequency (AF)",
       x = "Allele Frequency (AF)",
       y = "Density") +
  theme_minimal()

# Scatter plot of DP vs AF
df %>%
  ggplot(aes(DP, AF)) +
  geom_point(alpha = 0.5, color = "darkorange") +
  labs(title = "Scatter Plot of DP vs. AF",
       x = "Depth (DP)",
       y = "Allele Frequency (AF)") +
  theme_minimal()

ggplot(df, aes(x = AF)) +
  geom_density(aes(y = after_stat(count)), color = "salmon",  alpha = 0.5) +
  scale_x_continuous(breaks = c(0, 0.5, 1)) +
  labs(
    title = "LINE1 AF Value Density Distribution",
    x = "Allele Frequency (AF)",
    y = "Density (Scaled by Sample Count)"
  ) +
  theme_minimal(base_size = 18) +  # Increase base font size for visibility
  theme(
    panel.background = element_rect(fill = "transparent", color = NA),
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.grid = element_line(color = "grey80")
  )

library(tidyverse)

# Read first dataset and coerce DP and AF to numeric
df1 <- read_tsv("/Volumes/data/DCEG/Blood/HERVK_filtered.tsv", show_col_types = FALSE) %>%
  mutate(
    AF = as.numeric(AF),
    DP = as.numeric(DP),
    dataset = "HERVK"
  )

# Read second dataset and coerce DP and AF to numeric
df2 <- read_tsv("/Volumes/data/523_LINE1.tsv", show_col_types = FALSE) %>%
  mutate(
    AF = as.numeric(AF),
    DP = as.numeric(DP),
    dataset = "LINE1"
  )

# Read second dataset and coerce DP and AF to numeric
df3 <- read_tsv("/Volumes/data/DCEG/Blood/SVA_filtered.tsv", show_col_types = FALSE) %>%
  mutate(
    AF = as.numeric(AF),
    DP = as.numeric(DP),
    dataset = "SVA"
  )
# Read second dataset and coerce DP and AF to numeric
df4 <- read_tsv("/Volumes/data/DCEG/Blood/ALU_filtered.tsv", show_col_types = FALSE) %>%
  mutate(
    AF = as.numeric(AF),
    DP = as.numeric(DP),
    dataset = "ALU"
  )

df1 <- df1[!grepl("2:|3:|4:|5:", df1$SAMPLE), ]
df2 <- df2[!grepl("2:|3:|4:|5:", df2$SAMPLE), ]
df3 <- df3[!grepl("2:|3:|4:|5:", df3$SAMPLE), ]
df4 <- df4[!grepl("2:|3:|4:|5:", df4$SAMPLE), ]

# Combine datasets
combined_df <- bind_rows(df1, df2, df3, df4)

# Plot comparative density
ggplot(combined_df, aes(x = AF, color = dataset)) +
  geom_density(alpha = 0.5) +
  labs(
    title = "Comparative Density of Blood Tissue Transopable Genes Allele Frequency (AF)",
    x = "Allele Frequency (AF)",
    y = "Density",
    color = "Dataset"
  ) +
  scale_x_continuous(breaks = c(0, 0.5, 1)) +
  theme_minimal()



# Read first dataset and coerce DP and AF to numeric
df_1 <- read_tsv("/Volumes/data-1/DCEG/Blood/523_LINE1.tsv", show_col_types = FALSE) %>%
  mutate(
    AF = as.numeric(AF),
    DP = as.numeric(DP),
    dataset = "Blood"
  )

# Read second dataset and coerce DP and AF to numeric
df_2 <- read_tsv("/Volumes/data-1/DCEG/Blood/LINE1trans.tsv", show_col_types = FALSE) %>%
  mutate(
    AF = as.numeric(AF),
    DP = as.numeric(DP),
    dataset = "Normal"
  )

# Read second dataset and coerce DP and AF to numeric
df_3 <- read_tsv("/Volumes/data-1/xTEA_MELTAnalysis/TCGA_LUSC/MeltTumorDiscovey/LINE1/LINE1_new.tsv", show_col_types = FALSE) %>%
  mutate(
    AF = as.numeric(AF),
    DP = as.numeric(DP),
    dataset = "Tumor"
  )

# Read second dataset and coerce DP and AF to numeric
df_4 <- read_tsv("/Volumes/data-1/xTEA_MELTAnalysis/TCGA_LUSC/MeltTumorDiscovey/LINE1/LINE1_new.tsv", show_col_types = FALSE) %>%
  mutate(
    AF = as.numeric(AF),
    DP = as.numeric(DP),
    dataset = "Tumor"
  )



# Combine datasets
combined_dfNB <- bind_rows(df_1, df_2, df_3, df_4)

# Plot comparative density
ggplot(combined_dfNB, aes(x = AF, fill = dataset)) +
  geom_density(alpha = 0.5) +
  labs(
    title = "Comparative Density of Blood vs. Normal vs. Tumor Tissue LINE1 Allele Frequency (AF)",
    x = "Allele Frequency (AF)",
    y = "Density",
    fill = "Dataset"
  ) +
  scale_x_continuous(breaks = c(0, 0.5, 1)) +
  theme_minimal()




