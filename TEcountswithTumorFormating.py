import pandas as pd

# Step 1: Load bam_paired file and extract Tumor UUID → Subject mapping
bam_df = pd.read_csv("/data/williamsjoh/xTEA_MELTAnalysis/TCGA_LUSC/bam_paired.txt", sep="\t")

# Extract full Tumor CRAM filename without .cram extension
bam_df["Tumor_Basename"] = bam_df["Tumor_File"].str.extract(r'/([^/]+)\.cram')

# Build a dictionary: Tumor_Basename → Subject
tumor_map = dict(zip(bam_df["Tumor_Basename"], bam_df["Subject"]))

# Step 2: Load Tumor TE file (should have Barcode and Total_TE)
tumor_df = pd.read_csv("/data/williamsjoh/sample_TumorTE_counts_raw.txt", sep="\t")
tumor_df.columns = tumor_df.columns.str.strip()

# Step 3: Extract CRAM basename from Barcode (e.g., UUID_wgs_gdc_realn)
tumor_df["Cram_Name"] = tumor_df["Barcode"].str.extract(r'([^/]+)$')

# Step 4: Map to Subject ID (TCGA-XX-XXXX)
tumor_df["Subject"] = tumor_df["Cram_Name"].map(tumor_map)

# Step 5: Drop unmatched and summarize per subject
tumor_df = tumor_df.dropna(subset=["Subject"])
tumor_summary = tumor_df.groupby("Subject", as_index=False).agg({"Total_TE": "sum"})

# Step 6: Rename for clarity
tumor_summary = tumor_summary.rename(columns={"Subject": "Barcode", "Total_TE": "Total_TE_Tumor"})

# Step 7: Save the mapped file
tumor_summary.to_csv("/data/williamsjoh/Tumorall_TE_by_subject.tsv", sep="\t", index=False)

print(f"✅ Saved {len(tumor_summary)} tumor subjects to Tumorall_TE_by_subject.tsv")
