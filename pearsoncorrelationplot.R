# Load required libraries
library(ggplot2)

# Load both files
blood_df <- read.table("/Volumes/data/xTEA_MELTAnalysis/TCGA_LUSC/Complete_TE_Counts_By_Barcode.tsv", header = TRUE, sep = "\t", stringsAsFactors = FALSE)
tumor_df <- read.table("/Volumes/data/tumor_TE_by_subject.tsv", header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# Confirm column names
colnames(blood_df) <- c("Barcode", "Total_TE_Normal")
colnames(tumor_df) <- c("Barcode", "Total_TE_Tumor")

# Merge by Barcode (Subject ID)
merged_df <- merge(blood_df, tumor_df, by = "Barcode")

# Ensure numeric
merged_df$Total_TE_Normal <- as.numeric(merged_df$Total_TE_Normal)
merged_df$Total_TE_Tumor <- as.numeric(merged_df$Total_TE_Tumor)

# Filter finite rows
merged_df <- merged_df[is.finite(merged_df$Total_TE_Normal) & is.finite(merged_df$Total_TE_Tumor), ]

# Pearson correlation
cor_result <- cor.test(merged_df$Total_TE_Normal, merged_df$Total_TE_Tumor, method = "pearson")
print(cor_result)

# Plot

ggplot(merged_df, aes(x = Total_TE_Normal, y = Total_TE_Tumor)) +
  geom_point(color = "steelblue", size = 3) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed", color = "lavender") +
  labs(
    title = paste0("Blood L1 Events and Tumor TEs\nPearson r = ", round(cor_result$estimate, 2),
                   ", p = ", formatC(cor_result$p.value, format = "e", digits = 2)),
    x = "Blood Somatic L1 Count",
    y = "Tumor TE Count"
  ) +
  theme_minimal()


# Step 1: Apply log2 transformation with +1 to avoid log(0)
merged_df$log2_Total_TE_Normal <- log2(merged_df$Total_TE_Normal + 1)
merged_df$log2_Total_TE_Tumor  <- log2(merged_df$Total_TE_Tumor + 1)

# Step 2: Compute Pearson correlation and p-value
cor_result <- cor.test(
  merged_df$log2_Total_TE_Normal,
  merged_df$log2_Total_TE_Tumor,
  method = "pearson"
)

# Step 3: Create the plot
library(ggplot2)

ggplot(merged_df, aes(x = neg_log2_Total_TE_Normal, y = neg_log2_Total_TE_Tumor)) +
  geom_point(color = "midnightblue", size = 3) +
  geom_smooth(method = "lm", se = FALSE, linetype = "twodash", color = "lavender") +
  labs(
    title = paste0(
      "Blood L1 vs Tumor TEs\nPearson Correlation r = ", round(cor_result$estimate, 2),
      ", p = ", formatC(cor_result$p.value, format = "e", digits = 2)
    ),
    x = "log2(Blood Somatic L1 Count + 1)",
    y = "log2(Tumor TE Count + 1)"
  ) +
  theme_minimal()



