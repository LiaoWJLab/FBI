#!/bin/bash

# The-FBI-Pipeline: Automated End-to-End RNA-Seq Analysis Pipeline
# Step 3: Gene Fusion Detection with STAR-Fusion
# Author: Dongqiang Zeng
# Email: interlaken@smu.edu.cn
# Affiliation: Southern Medical University
# Last Modified: 2025-11-15

# Description:
# This script detects gene fusion events using STAR-Fusion via Docker container.
# It performs fusion discovery, validation with FusionInspector, and examines coding effects.

# Prerequisites:
# - Docker installed and running
# - STAR-Fusion Docker image: docker pull trinityctat/starfusion
# - CTAT genome library downloaded and placed in /home/data3/TIMES001/ctat_db_dir

# Configuration
path_base="/home/data3/TIMES001"
path_input="/home/data3/TIMES001/03-rribo"
path_out="/home/data3/TIMES001/13-starfusion"

# Navigate to base directory
cd $path_base

# Get all _1.fastq.gz files and randomize processing order
for fq1 in $(ls "${path_input}"/*_1.fastq.gz | shuf); do
    # Extract base sample name
    sample_name=$(basename "${fq1}" _1.fastq.gz)

    # Skip if already processed
    if [ -e "${path_out}/${sample_name}/task.complete" ]; then
        echo "Skipping ${sample_name} - already processed."
        continue
    fi
    
    # Create output directory
    mkdir -p "${path_out}/${sample_name}"

    echo "Processing: ${sample_name}"
    
    # Run STAR-Fusion in Docker container
    docker run -v /home/data3/TIMES001:/TIMES001 --rm trinityctat/starfusion \
        STAR-Fusion \
        --left_fq "/TIMES001/03-rribo/${sample_name}_1.fastq.gz" \
        --right_fq "/TIMES001/03-rribo/${sample_name}_2.fastq.gz" \
        --genome_lib_dir /TIMES001/ctat_db_dir \
        -O "/TIMES001/13-starfusion/${sample_name}/" \
        --FusionInspector validate \
        --examine_coding_effect \
        --CPU 32 \
        --denovo_reconstruct

    # Check exit status
    docker_exit_status=$?
    
    # Create completion marker if successful
    if [ ${docker_exit_status} -eq 0 ]; then
        touch "${path_out}/${sample_name}/task.complete"
        echo "✓ Successfully completed: ${sample_name}"
    else
        echo "✗ Processing failed: ${sample_name}"
    fi
done

echo "All samples processed successfully!"
