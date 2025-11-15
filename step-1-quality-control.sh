#!/bin/bash

# The-FBI-Pipeline: Automated End-to-End RNA-Seq Analysis Pipeline
# Step 1: Quality Control with Fastp
# Author: Dongqiang Zeng
# Email: interlaken@smu.edu.cn
# Affiliation: Southern Medical University
# Last Modified: 2025-11-15

# Description:
# This script performs quality control on raw paired-end RNA-seq FASTQ files using fastp.
# It removes adapters, trims low-quality bases, and filters reads based on quality metrics.

# Environment Setup
# Create conda environment (if not exists):
# conda create -n rrna -c bioconda fastp -y
conda activate rrna

# Configuration
input_dir="/home/data3/TIMES001/01-raw"
output_dir="/home/data3/TIMES001/02-fastp"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Get all _1.fastq.gz files and randomize processing order
files=(${input_dir}/*_1.fastq.gz)
shuf_files=($(shuf -e "${files[@]}"))

# Process each paired-end sample
for forward_file in "${shuf_files[@]}"; do
    # Extract base sample name
    base_name=$(basename "$forward_file" "_1.fastq.gz")
    
    # Build path for reverse read file
    reverse_file="${input_dir}/${base_name}_2.fastq.gz"
    
    # Check if reverse file exists
    if [[ ! -f "$reverse_file" ]]; then
        echo "Error: Reverse file not found: $reverse_file"
        continue
    fi
    
    # Define output file paths
    output_forward="${output_dir}/${base_name}_1.fastq.gz"
    output_reverse="${output_dir}/${base_name}_2.fastq.gz"
    json_report="${output_dir}/${base_name}_fastp.json"
    html_report="${output_dir}/${base_name}_fastp.html"
    
    echo "Processing: $base_name"
    echo "Input files: $forward_file and $reverse_file"
    echo "Output files: $output_forward and $output_reverse"
    
    # Run fastp quality control
    fastp \
        -i "$forward_file" \
        -I "$reverse_file" \
        -o "$output_forward" \
        -O "$output_reverse" \
        -j "$json_report" \
        -h "$html_report" \
        --detect_adapter_for_pe \
        --cut_front \
        --cut_tail \
        --cut_window_size 4 \
        --cut_mean_quality 20 \
        --length_required 36 \
        --qualified_quality_phred 15 \
        --unqualified_percent_limit 40 \
        --n_base_limit 5 \
        --correction \
        --thread 8 \
        --compression 6
    
    # Check if fastp completed successfully
    if [[ $? -eq 0 ]]; then
        echo "✓ Successfully completed: $base_name"
        # Create completion marker file
        touch "${output_dir}/${base_name}.task.complete"
    else
        echo "✗ Processing failed: $base_name"
        # Create failure marker file
        touch "${output_dir}/${base_name}.task.failed"
    fi
    
    echo "----------------------------------------"
done

echo "All files processed successfully!"
