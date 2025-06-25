# Set the input file
INPUT_FILE="/data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/bam_paired.txt"


# Custom base path replacements
TUMOR_DIR="/data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/CRAM_Tum"
NORM_DIR="/data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/CRAM_Norm"


# 1. Column 1 only
echo "Header: $(head -1 "$INPUT_FILE" | cut -f1)"
tail -n +2 "$INPUT_FILE" | cut -f1 > /data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/sample_ids.txt > col1.txt

# 2. Column 1 and 3 (Tumor CRAM with updated directory)
echo -e "Subject_ID\tTumor_CRAM" > col1_3.txt
tail -n +2 "$INPUT_FILE" | awk -v dir="$TUMOR_DIR" 'BEGIN{OFS="\t"} {
    split($3, parts, "/");
    cram=parts[length(parts)];
    print $1, dir "/" cram;
}' >> /data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/tumornewbams.txt

# 3. Column 1 and 6 (Normal CRAM with updated directory)
echo -e "Subject_ID\tNormal_CRAM" > col1_6.txt
tail -n +2 "$INPUT_FILE" | awk -v dir="$NORM_DIR" 'BEGIN{OFS="\t"} {
    split($6, parts, "/");
    cram=parts[length(parts)];
    print $1, dir "/" cram;
}' >> /data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/normanewlbams.txt

# 4. Column 1, 3, and 6 (Both CRAMs with updated directories)
echo -e "Subject_ID\tTumor_CRAM\tNormal_CRAM" > col1_3_6.txt
tail -n +2 "$INPUT_FILE" | awk -v tdir="$TUMOR_DIR" -v ndir="$NORM_DIR" 'BEGIN{OFS="\t"} {
    split($3, tparts, "/");
    split($6, nparts, "/");
    tcram = tparts[length(tparts)];
    ncram = nparts[length(nparts)];
    print $1, tdir "/" tcram, ndir "/" ncram;
}' >> /data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/casecontrolnewbams.txt

