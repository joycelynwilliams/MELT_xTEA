# Load Required Libraries
library(circlize)
library(dplyr)
library(readr)
library(stringr)

# Load Data
data <- read_tsv("/Volumes/data/624_LINE1.tsv")

# Extract Source Chromosome from MESOURCE
data$Source_Chromosome <- str_extract(data$MESOURCE, "^chr[0-9XY]+")

# Classify Interactions: If MESOURCE is missing or invalid, it's an insertion-only event
data$Interaction_Type <- ifelse(is.na(data$Source_Chromosome) | data$Source_Chromosome == "",
                                "Insertion Only", "Chromosome Interaction")

# If MESOURCE is missing, use the same chromosome as insertion (self-link)
data$Source_Chromosome[is.na(data$Source_Chromosome) | data$Source_Chromosome == ""] <- data$CHROM[is.na(data$Source_Chromosome) | data$Source_Chromosome == ""]

# Ensure Insertion Chromosome is properly formatted
data$Insertion_Chromosome <- as.character(data$CHROM)

# Ensure POS column is numeric (fix non-numeric values)
data <- data %>% mutate(POS = as.numeric(POS)) %>% filter(!is.na(POS))

# Aggregate duplicate rows by averaging AF
data <- data %>%
  group_by(Source_Chromosome, Insertion_Chromosome, POS, REF, ALT, Interaction_Type) %>%
  summarise(Avg_AF = mean(AF, na.rm = TRUE), .groups = "drop")

# Define AF bins
bins <- c(0, 0.2, 0.4, 0.6, 0.8, 1.0)
labels <- c("Low (>20%)", "Moderate (>40%)", "High (>60%)", "Very High (>80%)", "Extreme (100%)")

# Assign AF values to categories
data$AF_Category <- cut(data$Avg_AF, breaks = bins, labels = labels, include.lowest = TRUE)

# Define color palette for AF intensity
af_colors <- colorRampPalette(c("#DAF7A6", "#FA8072", "#CCCCFF", "#9FE2BF", "#900C3F"))(length(labels))
names(af_colors) <- labels

# Get available chromosomes from Circos' default ideogram
available_chromosomes <- paste0("chr", c(1:22, "X", "Y"))

# Filter out invalid chromosomes
chromosomes <- unique(c(data$Source_Chromosome, data$Insertion_Chromosome))
chromosomes <- chromosomes[chromosomes %in% available_chromosomes]

# Debugging: Print count of interaction vs. insertion-only
interaction_count <- sum(data$Interaction_Type == "Chromosome Interaction")
insertion_count <- sum(data$Interaction_Type == "Insertion Only")
print(paste("Chromosome Interactions:", interaction_count, "Insertion-Only Events:", insertion_count))

# Ensure all Chromosomes in the dataset are present in the Circos plot
if (length(chromosomes) == 0) {
  stop("Error: No valid chromosomes found for Circos plot. Check chromosome formatting.")
}

# Initialize Circos Plot
circos.clear()
circos.par("gap.degree" = 1.5, start.degree = 90, track.margin = c(0.02, 0.02))

# Initialize with Ideogram
circos.initializeWithIdeogram(
  plotType = c("axis", "labels", "ideogram"),
  ideogram.height = 0.04, track.height = 0.002,
  chromosome.index = chromosomes
)

# Add Plot Title
mtext("LINE1 Chromosome Interactions and Insertions", side = 3, line = 1, cex = .75, font = 2)

# Add Axis Labels
circos.axis(
  h = "bottom",
  major.at = seq(0, 20000000, by = 5000000),
  labels = seq(0, 20, by = 5),
  labels.cex = 0.7,
  lwd = 0.7,
  col = "black"
)

# Ensure all interactions are plotted
set.seed(123)
for (i in seq_len(nrow(data))) {
  af_label <- as.character(data$AF_Category[i])
  link_color <- af_colors[af_label]
  
  pos1 <- max(1, data$POS[i])  # Ensure no zero or negative values
  pos2 <- min(pos1 + 500000, 2.5e8)  # Ensure we don’t exceed chromosome length
  
  # Only plot if chromosome names are valid
  if (!is.na(pos1) & !is.na(pos2) & data$Source_Chromosome[i] %in% chromosomes & data$Insertion_Chromosome[i] %in% chromosomes) {
    if (data$Interaction_Type[i] == "Chromosome Interaction") {
      circos.link(
        sector.index1 = data$Source_Chromosome[i], point1 = pos1,
        sector.index2 = data$Insertion_Chromosome[i], point2 = pos2,
        col = link_color, border = NA, lwd = max(1, data$Avg_AF[i] * 3),
        directional = 1, arr.length = 0.3, arr.width = 0.25
      )
    } else if (data$Interaction_Type[i] == "Insertion Only") {
      circos.link(
        sector.index1 = data$Insertion_Chromosome[i], point1 = pos1,
        sector.index2 = data$Insertion_Chromosome[i], point2 = pos1 + 2000,  # **Shortened insertion marker**
        col = link_color, border = NA, lwd = 0,  # **Make arrow size more visible**
        directional = 1 , arr.length = 0.25, arr.width = 0.005  # **Turn into an arrow**
      )
    }
  }
}


# Add Color Legend for AF Categories
par(xpd = TRUE)
legend(
  "bottomright",
  legend = names(af_colors),
  fill = af_colors,
  border = "black",
  title = "AF Intensity",
  cex = 1.0,
  bty = "n",
  inset = c(-0.05, 0)
)



# Save Circos Plot
png("/data/williamsjoh/DCEG/Blood/HERVKinsertions.png", width = 1800, height = 1400, res = 300)
dev.off()
