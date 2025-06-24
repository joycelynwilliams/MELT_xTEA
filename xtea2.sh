#!/bin/bash

SAMPLE_LIST="/data/williamsjoh/xTEA_MELTAnalysis/TCGA-STAD/ids.txt"
BASE_DIR="/data/williamsjoh/xTEA_MELTAnalysis/TCGA_xTEAAnalysis/TCGA-STAD/Case_Control/"
LOG_DIR="${BASE_DIR}/logs"
SCRIPT_DIR="${BASE_DIR}/slurm_scripts"

mkdir -p "$LOG_DIR" "$SCRIPT_DIR"

while read -r SAMPLE; do
  SCRIPT_PATH="${SCRIPT_DIR}/${SAMPLE}_xtea_job.sh"

  cat > "$SCRIPT_PATH" <<EOF
#!/bin/bash
#SBATCH --job-name=xtea_mosaiccase_${SAMPLE}
#SBATCH --output=${LOG_DIR}/${SAMPLE}_xtea.out
#SBATCH --error=${LOG_DIR}/${SAMPLE}_xtea.err
#SBATCH --mem=20G
#SBATCH --cpus-per-task=4
#SBATCH --time=7-00:00:00

source /data/williamsjoh/conda/etc/profile.d/conda.sh
conda activate py2_env

echo "🚀 Running xTEA for sample: ${SAMPLE}"
bash "$BASE_DIR/$SAMPLE/L1/run_xTEA_pipeline.sh"
EOF

  # Make script executable and submit
  chmod +x "$SCRIPT_PATH"
  JOB_ID=$(sbatch "$SCRIPT_PATH" | awk '{print $4}')
  echo "✅ Submitted job for sample: $SAMPLE (Job ID: $JOB_ID)"
done < "$SAMPLE_LIST"
