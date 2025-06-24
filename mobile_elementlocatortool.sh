#!/bin/bash
#SBATCH --job-name=newrunexp    # Job name
#SBATCH --output=/data/williamsjoh/logs/newrun.log
#SBATCH --error=/data/williamsjoh/logs/newrun.err
#SBATCH --time=5-00:00:00
#SBATCH --partition=norm
#SBATCH --cpus-per-task=10
#SBATCH --mem=20
# Exit immediately if a command exits with a non-zero status
set -e

# Define paths and resources
MELT_DIR="/data/williamsjoh/DCEG/MELTv2.2.2"                       # Path to the MELT tool directory
ME_REFS="/data/williamsjoh/DCEG/MELTv2.2.2/me_refs/Hg38/ALU_MELT.zip" # Path to Mobile Element references
REF_FASTA="/data/Zhang_Group/Sharing/Reference/Homo_sapiens_assembly38.fasta" # Reference human genome
GENES_BED="/data/williamsjoh/DCEG/MELTv2.2.2/add_bed_files/Hg38/Hg38.genes.bed" # BED file with gene annotations

# Define directories for input BAM files, intermediate discovery results, and final output
BAM_DIR="/data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/CRAM_Norm/"                        # Directory for CRAM files
DISCOVERY_DIR="/data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/MeltNormDiscovey/ALU"        # Directory for discovery outputs
OUTPUT_DIR="/data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/MeltNormDiscovey/ALU"           # Final output directory for results
LOGDIR="/data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/MeltNormDiscovey/logs/ALU"                                              # Directory for log files

# Create an array of sample CRAM files
SAMPLE_LIST=(${BAM_DIR}/*.cram)

# Create the log directory if it doesn't exist
mkdir -p $LOGDIR
mkdir -p $DISCOVERY_DIR

# Arrays to store job IDs for Step 2 and Step 4, used for dependency management
JOB_IDS_STEP2=()
JOB_IDS_STEP4=()

# Step 1: Preprocess - prepare samples by converting CRAM to BAM and preparing for MELT analysis
for BAM in "${SAMPLE_LIST[@]}"; do
    SAMPLE_NAME=$(basename $BAM .cram) # Extract sample name from CRAM file name

    # Submit job for Preprocess step
    JOB_ID_STEP1=$(sbatch --job-name=Preprocess_${SAMPLE_NAME} --partition=norm --ntasks=1 --mem=20G --cpus-per-task=4 --time=10-00:00:00 \
        --error=$LOGDIR/Preprocess_${SAMPLE_NAME}.err --output=$LOGDIR/Preprocess_${SAMPLE_NAME}.out --wrap="\
    module load bowtie2; module load samtools; \
    java -Xmx2G -jar $MELT_DIR/MELT.jar Preprocess \
    -h $REF_FASTA -bamfile $BAM" | awk '{print $1}') # Capture job ID for dependency tracking
    
    echo "Step 1 Job ID for ${SAMPLE_NAME}: ${JOB_ID_STEP1}"
    
    # Step 2: IndivAnalysis - Perform transposon analysis (MELTv2.2.2). This is STEP 1 of the analysis pipeline.
    # This step analyzes individual pre-processed genomes and identifies initial putative transposable element hits.

    # Command structure:
    # -bamfile <arg>    Path to the BAM file for MEI analysis.
    # -h <arg>          Path to the reference genome sequence used for read alignment.
    # -w <arg>          Path to the working root directory for analysis outputs.
    # -t <arg>          Path to the transposon ZIP file(s) to be used for this analysis.
    # (additional MELT options can be included if needed)

    JOB_ID_STEP2=$(sbatch --dependency=afterok:${JOB_ID_STEP1} --job-name=IndivAnalysis_${SAMPLE_NAME} --partition=norm --ntasks=1 --mem=20G --cpus-per-task=4 --time=10-00:00:00 \
        --error=$LOGDIR/IndivAnalysis_${SAMPLE_NAME}.err --output=$LOGDIR/IndivAnalysis_${SAMPLE_NAME}.out --wrap="\
    module load bowtie2; module load samtools; \
    java -Xmx6G -jar $MELT_DIR/MELT.jar IndivAnalysis \
    -h $REF_FASTA -bamfile $BAM -w $DISCOVERY_DIR \
    -t $ME_REFS" | awk '{print $1}')

    # Store job ID for Step 2 for dependency handling in Step 3
    JOB_IDS_STEP2+=($JOB_ID_STEP2)
    
    echo "Step 2 Job ID for ${SAMPLE_NAME}: ${JOB_ID_STEP2}"
done

# Step 3: GroupAnalysis - Perform transposon analysis (MELTv2.2.2). This is STEP 2 of the analysis pipeline.
# This step merges and analyzes all data compiled from STEP 1. The final output is a *.pre_geno.tsv file, which can
# be used to genotype individual genomes.

# Command structure:
# -discoverydir <arg>   Full path to the working directory from STEP 1.
# -w <arg>              Path to the working root directory.
# -h <arg>              Path to the reference genome sequence used for alignment.
# -t <arg>              Path to the transposon ZIP file(s) to be used for this analysis.
# -n <arg>              Path to the genome annotation file.

DEPENDENCY_IDS=$(echo "${JOB_IDS_STEP2[@]}" | sed 's/  */,/g') # Join Step 2 job IDs as dependency
echo "For Step 3 Job IDs need to complete: $DEPENDENCY_IDS"

JOB_ID_STEP3=$(sbatch --dependency=afterok:${DEPENDENCY_IDS} --job-name=GroupAnalysis --partition=norm --ntasks=1 --mem=20G --cpus-per-task=4 --time=10-00:00:00 \
    --error=$LOGDIR/GroupAnalysis.err --output=$LOGDIR/GroupAnalysis.out --wrap="\
module load bowtie2; module load samtools; \
java -Xmx4G -jar $MELT_DIR/MELT.jar GroupAnalysis \
-discoverydir $DISCOVERY_DIR -w $DISCOVERY_DIR \
-h $REF_FASTA -t $ME_REFS -n $GENES_BED" | awk '{print $1}')

# Step 4: Genotype - Perform transposon analysis (MELTv2.2.2). This is STEP 3 of the analysis pipeline.
# This step takes individual genomes and genotypes them with putative hits identified in STEP 2.

# Command structure:
# -bamfile <arg>    Path to the BAM file for MEI analysis.
# -h <arg>          Path to the reference genome sequence used for read alignment.
# -w <arg>          Path to the working root directory for analysis outputs.
# -t <arg>          Path to the transposon ZIP file(s) to be used for this analysis.
# -p <arg>          Full path to working directory from STEP 2.

for BAM in "${SAMPLE_LIST[@]}"; do
    SAMPLE_NAME=$(basename $BAM .cram)
    JOB_ID_STEP4=$(sbatch --dependency=afterok:${JOB_ID_STEP3} --job-name=Genotype_${SAMPLE_NAME} --partition=norm --ntasks=1 --mem=20G --cpus-per-task=4 --time=10-00:00:00 \
        --error=$LOGDIR/Genotype_${SAMPLE_NAME}.err --output=$LOGDIR/Genotype_${SAMPLE_NAME}.out --wrap="\
    module load bowtie2; module load samtools; \
    java -Xmx2G -jar $MELT_DIR/MELT.jar Genotype \
    -h $REF_FASTA -bamfile $BAM -w $DISCOVERY_DIR \
    -t $ME_REFS -p $DISCOVERY_DIR" | awk '{print $1}')

    echo "Step 4 Job ID for ${SAMPLE_NAME}: ${JOB_ID_STEP4}"

    # Store the Step 4 job ID for dependency management in Step 5
    JOB_IDS_STEP4+=($JOB_ID_STEP4)
done

# Step 5: MakeVCF - Perform transposon analysis (MELTv2.2.2). This is STEP 4 of the analysis pipeline.
# This step takes genotyped hits, filters them, and merges the results into a final VCF (Variant Call Format) output file.

# Command structure:
# -genotypingdir <arg>   Full path to the working directory from STEP 3.
# -w <arg>               Path to the working root directory.
# -h <arg>               Path to the reference genome sequence used for alignment.
# -t <arg>               Path to the transposon ZIP file(s) to be used for this analysis.
# -p <arg>               Full path to the working directory from STEP 2.

DEPENDENCY_IDS_STEP4=$(echo "${JOB_IDS_STEP4[@]}" | sed 's/  */,/g') # Join Step 4 job IDs
echo "For Step 5 Job IDs need to complete: ${DEPENDENCY_IDS_STEP4}"
JOB_ID_STEP5=$(sbatch --dependency=afterok:${DEPENDENCY_IDS_STEP4} --job-name=MakeVCF  --partition=norm --ntasks=1 --mem=20g --cpus-per-task=4 --time=10-00:00:00 \
    --error=$LOGDIR/MakeVCF.err --output=$LOGDIR/MakeVCF.out --wrap="\
    
module load bowtie2; module load samtools; \
java -Xmx2G -jar $MELT_DIR/MELT.jar MakeVCF \
-genotypingdir $OUTPUT_DIR -w $DISCOVERY_DIR \
-h $REF_FASTA -t $ME_REFS -p $OUTPUT_DIR" | awk '{print $1}')

echo "Step 5 Job submitted"
