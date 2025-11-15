#!/bin/bash

# The-FBI-Pipeline: Automated End-to-End RNA-Seq Analysis Pipeline
# Step 2: Ribosomal RNA Removal with RiboDetector
# Author: Dongqiang Zeng
# Email: interlaken@smu.edu.cn
# Affiliation: Southern Medical University
# Last Modified: 2025-11-15

# Description:
# This script removes ribosomal RNA (rRNA) sequences from quality-controlled RNA-seq data
# using RiboDetector, which uses deep learning to efficiently identify and filter rRNA reads.

# Environment Setup
# Create conda environment (if not exists):
# conda create -n ribodetector -c bioconda ribodetector -y
conda activate ribodetector

# Configuration
input_dir="/home/data3/TIMES001/02-fastp"
output_dir="/home/data3/TIMES001/03-rribo"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Get all _1.fastq.gz files and randomize processing order
files=(${input_dir}/*_1.fastq.gz)
shuf_files=($(shuf -e "${files[@]}"))

# Process each paired-end sample
for file1 in "${shuf_files[@]}"; do
    # Build path for corresponding reverse read file
    file2="${file1/_1.fastq.gz/_2.fastq.gz}"
    
    # Create output file paths
    output_file1="${file1/$input_dir/$output_dir}"
    output_file2="${file2/$input_dir/$output_dir}"
    
    # Extract sample ID from filename
    sample_id=$(basename "$file1" | sed 's/_1.fastq.gz//')
    complete_file="${output_dir}/${sample_id}.task.complete"
    
    # Skip if already processed
    if [ -f "$complete_file" ]; then
        echo "Sample ${sample_id} already processed, skipping."
        continue
    fi
    
    echo "Processing: ${sample_id}"
    
    # Run ribodetector_cpu to remove rRNA sequences
    ribodetector_cpu -t 36 -l 100 \
                     -i "$file1" "$file2" \
                     -o "$output_file1" "$output_file2" \
                     -e rrna \
                     --chunk_size 6400
    
    # Create completion marker file upon success
    if [[ $? -eq 0 ]]; then
        touch "$complete_file"
        echo "✓ Successfully completed: ${sample_id}"
    else
        echo "✗ Processing failed: ${sample_id}"
    fi
done

echo "All files processed successfully!"
