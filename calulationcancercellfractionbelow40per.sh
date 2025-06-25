# Step 1: Extract sample names from VCF
bcftools query -l \
  /data/williamsjoh/xTEA_MELTAnalysis/TCGA_LUSC/MeltNormDiscovey/LINE1/LINE1.final_comp.trans.vcf \
  > /data/williamsjoh/normsample_list.txt

# Step 2: Sort extracted sample names
bcftools query -l \
  /data/williamsjoh/xTEA_MELTAnalysis/TCGA_LUSC/MeltNormDiscovey/LINE1/LINE1.final_comp.trans.vcf \
  | sort \
  > /data/williamsjoh/samples.list

# Step 3: Count variants per sample (GT=0/1, AF<0.4)
bcftools query -f '[%SAMPLE\t%GT\t%AD\t%DP\n]' \
  /data/williamsjoh/xTEA_MELTAnalysis/TCGA_LUSC/MeltNormDiscovey/LINE1/LINE1.final_comp.trans.vcf \
| awk -F'\t' '
  {
    sample=$1; gt=$2; ad=$3+0; dp=$4+0;
    if (gt == "0/1" && dp > 0 && (ad/dp) < 0.4) {
      count[sample]++;
    }
  }
  END {
    for (s in count)
      print s "\t" count[s];
  }' \
| sort \
  > /data/williamsjoh/variant_counts.txt

# Step 4: Merge sample list with variant counts
join -a1 -e 0 -t $'\t' -o '1.1 2.2' \
  /data/williamsjoh/samples.list \
  /data/williamsjoh/variant_counts.txt \
> /data/williamsjoh/xTEA_MELTAnalysis/TCGA_LUSC/1final_sample_variant_counts.tsv

# Optional Step: Extract details for a single sample (e.g., TCGA-77-A5G3)
bcftools query -f '[%SAMPLE\t%GT\t%AD\t%DP\n]' \
  /data/williamsjoh/xTEA_MELTAnalysis/TCGA_LUSC/MeltNormDiscovey/LINE1/LINE1.final_comp.trans.vcf \
| grep "TCGA-77-A5G3-10A-01D-A92U-36.WholeGenome.RP-1657" \
| awk -F'\t' '
  {
    sample=$1; gt=$2; ad=$3+0; dp=$4+0;
    af = (dp > 0) ? (ad/dp) : "NA";
    print "GT=" gt, "AD=" ad, "DP=" dp, "AF=" af
  }'

# R script to summarize and count samples with zero insertions
Rscript -e "
samples <- read.table('/Volumes/data/tumorsample_list.txt', header=FALSE, stringsAsFactors=FALSE)
colnames(samples) <- 'Sample'

counts <- read.table('/Volumes/data/sample_TumorTE_counts_raw.txt', header=FALSE, stringsAsFactors=FALSE, sep='\t')
colnames(counts) <- c('Sample', 'Total_TE')

merged <- merge(samples, counts, by='Sample', all.x=TRUE)
merged$Total_TE[is.na(merged$Total_TE)] <- 0

cat('✅ Number of samples with 0 insertions (AF < 0.4):', sum(merged$Total_TE == 0), '\n')

write.table(merged, file='/Volumes/data/Tumor_TE_AFbelow0.4_full.txt', sep='\t', row.names=FALSE, quote=FALSE)
"
