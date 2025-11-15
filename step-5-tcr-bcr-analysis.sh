#!/bin/bash

# The-FBI-Pipeline: Automated End-to-End RNA-Seq Analysis Pipeline
# Step 5: TCR/BCR Repertoire Analysis with MixCR
# Author: Dongqiang Zeng
# Email: interlaken@smu.edu.cn
# Affiliation: Southern Medical University
# Last Modified: 2025-11-15

# Description:
# This script performs T-cell receptor (TCR) and B-cell receptor (BCR) repertoire analysis
# using MixCR, which assembles and identifies immune receptor sequences from RNA-seq data.

# Prerequisites:
# - MixCR installed at /home/data/project/biosoft/mixcr/mixcr.jar
# - Or install via: conda create -n mixcr -c bioconda mixcr -y
# Note: This script uses the standalone JAR version

# Configuration
input_folder="/home/data3/TIMES001/03-rribo/"
output_folder="/home/data3/TIMES001/07-mixcr/"

# Create output directory if it doesn't exist
mkdir -p "$output_folder"

# Get all _1.fastq.gz files
files=(${input_folder}*_1.fastq.gz)

# Randomize processing order
shuffled_files=($(shuf -e "${files[@]}"))

# Process each paired-end sample
for file in "${shuffled_files[@]}"; do
    # Extract sample name
    sample=$(basename $file _1.fastq.gz)
    
    # Skip if already processed
    if [ -f "${output_folder}${sample}.vdjca" ]; then
        echo "Skipping sample $sample - Output ${output_folder}${sample}.vdjca already exists."
        continue
    fi
    
    echo "Processing: ${sample}"
    
    # Run MixCR RNA-seq analysis pipeline
    # This performs: alignment, assembly, and export of TCR/BCR repertoires
    java -jar /home/data/project/biosoft/mixcr/mixcr.jar analyze rna-seq \
        -t 32 \
        --species hsa \
        ${input_folder}${sample}_1.fastq.gz \
        ${input_folder}${sample}_2.fastq.gz \
        ${output_folder}${sample}
    
    # Check if analysis completed successfully
    if [[ $? -eq 0 ]]; then
        echo "✓ Successfully completed: ${sample}"
    else
        echo "✗ Processing failed: ${sample}"
    fi
done

echo "All samples processed successfully!"
