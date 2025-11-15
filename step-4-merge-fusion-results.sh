#!/bin/bash

# The-FBI-Pipeline: Automated End-to-End RNA-Seq Analysis Pipeline
# Step 4: Merge STAR-Fusion Results
# Author: Dongqiang Zeng
# Email: interlaken@smu.edu.cn
# Affiliation: Southern Medical University
# Last Modified: 2025-11-15

# Description:
# This script consolidates STAR-Fusion output files from multiple samples into unified datasets.
# It creates three merged files: full predictions, abridged predictions, and coding effect predictions.

# Navigate to STAR-Fusion output directory
cd /home/data3/TIMES001/13-starfusion

echo "========================================="
echo "Merging STAR-Fusion Results"
echo "========================================="

# ============================================================================
# 1. Merge Full Fusion Predictions
# ============================================================================
echo "Step 1: Merging full fusion predictions..."

output_file="1-merged_fusion_predictions.tsv"

# Create header for output file
echo -e "Folder_ID\t#FusionName\tJunctionReadCount\tSpanningFragCount\test_J\test_S\tSpliceType\tLeftGene\tLeftBreakpoint\tRightGene\tRightBreakpoint\tJunctionReads\tSpanningFrags\tLargeAnchorSupport\tFFPM\tLeftBreakDinuc\tLeftBreakEntropy\tRightBreakDinuc\tRightBreakEntropy\tannots" > "$output_file"

# Process each sample directory
for dir in */; do
    file_path="${dir}star-fusion.fusion_predictions.tsv"

    if [ -f "$file_path" ]; then
        folder_id="${dir%/}"  # Remove trailing slash
        
        # Append data with folder ID, skip header line
        awk -v id="$folder_id" 'NR>1 {print id "\t" $0}' "$file_path" >> "$output_file"
    fi
done

echo "✓ Full predictions merged: $output_file"

# ============================================================================
# 2. Merge Abridged Fusion Predictions
# ============================================================================
echo "Step 2: Merging abridged fusion predictions..."

output_file="2-merged_fusion_predictions_abridged.tsv"

# Create header for output file
echo -e "Folder_ID\t#FusionName\tJunctionReadCount\tSpanningFragCount\test_J\test_S\tSpliceType\tLeftGene\tLeftBreakpoint\tRightGene\tRightBreakpoint\tLargeAnchorSupport\tFFPM\tLeftBreakDinuc\tLeftBreakEntropy\tRightBreakDinuc\tRightBreakEntropy\tannots" > "$output_file"

# Process each sample directory
for dir in */; do
    file_path="${dir}star-fusion.fusion_predictions.abridged.tsv"

    if [ -f "$file_path" ]; then
        folder_id="${dir%/}"
        
        # Append data with folder ID, skip header line
        awk -v id="$folder_id" 'NR>1 {print id "\t" $0}' "$file_path" >> "$output_file"
    fi
done

echo "✓ Abridged predictions merged: $output_file"

# ============================================================================
# 3. Merge Abridged Fusion Predictions with Coding Effects
# ============================================================================
echo "Step 3: Merging abridged predictions with coding effects..."

output_file="3-merged_fusion_predictions_abridged_coding_effect.tsv"

# Create header for output file
echo -e "Folder_ID\t#FusionName\tJunctionReadCount\tSpanningFragCount\test_J\test_S\tSpliceType\tLeftGene\tLeftBreakpoint\tRightGene\tRightBreakpoint\tLargeAnchorSupport\tFFPM\tLeftBreakDinuc\tLeftBreakEntropy\tRightBreakDinuc\tRightBreakEntropy\tannots" > "$output_file"

# Process each sample directory
for dir in */; do
    file_path="${dir}star-fusion.fusion_predictions.abridged.coding_effect.tsv"

    if [ -f "$file_path" ]; then
        folder_id="${dir%/}"
        
        # Append data with folder ID, skip header line
        awk -v id="$folder_id" 'NR>1 {print id "\t" $0}' "$file_path" >> "$output_file"
    fi
done

echo "✓ Coding effect predictions merged: $output_file"

echo "========================================="
echo "All STAR-Fusion results successfully merged!"
echo "========================================="
