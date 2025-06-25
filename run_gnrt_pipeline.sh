#!/bin/bash
##based on the xTEA formatting instructions
# ===== Set user-defined variables =====
SAMPLE_ID="/data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/ids.txt"
BAMS="/data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/casecontrolbams.txt"
X10_BAM="null"
WFOLDER="/data/williamsjoh/xTEA_MELTAnalysis/TCGA_xTEAAnalysis/TCGA-STAD/Case_Control"
OUT_SCRTP="submit_jobs.sh"
TIME="10-00:00:00"

# Repeat library folder
REP_LIB="/data/williamsjoh/resources/xtea/rep_lib_annotation/"
# Reference FASTA file
REF="/data/Zhang_Group/Sharing/Reference/Homo_sapiens_assembly38.fasta"
# Gene annotation GFF3
GENE="/data/williamsjoh/xTEA_MELTAnalysis/TCGA_xTEAAnalysis/xteafiles/gencode.v33.primary_assembly.annotation.gff3"
# xTEA executable directory
XTEA="/data/williamsjoh/tools/xtea_mosaic_2/xtea/"
# Blacklist (optional, not used in your current command but included for completeness)
BLK_LIST="/data/williamsjoh/resources/xtea/rep_lib_annotation/blacklist/hg38/centromere.bed"


#
python ${XTEA}"gnrt_pipeline_local.py" -i ${SAMPLE_ID} -b ${BAMS} -x ${X10_BAM} -p ${WFOLDER} -o ${OUT_SCRTP} -q short -n 8 -m 16 -t ${TIME} \
-l ${REP_LIB} -r ${REF} -g ${GENE} --xtea ${XTEA}  --nclip 4 --cr 2 --nd 5 --nfclip 4 --nfdisc 5 --flklen 3000 -f 5907  -y 7  --blacklist ${BLK_LIST}
