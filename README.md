# The-FBI-Pipeline
**Automated End-to-End RNA-Seq Analysis for Fusion Detection and Immune Profiling**
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-green.svg)](https://www.gnu.org/software/bash/)

---

## 📋 Overview

The-FBI-Pipeline (Fusion, BCR/TCR, Immunogenomics) streamlines paired-end RNA-seq data from raw reads to validated fusion calls and immune repertoire profiles. The modular Bash scripts cover fastp QC, RiboDetector rRNA depletion, STAR-Fusion analysis, merged reporting, and MixCR-based TCR/BCR profiling.

---

## 🚀 Highlights

- Modular steps that run independently or end-to-end
- Reproducible environments via Conda and Docker
- Checkpoint markers (`.task.complete`) to resume safely
- Consolidated TSV outputs ready for downstream review

---

## 📂 Pipeline Steps

- **Step 1 · Quality Control (`step-1-quality-control.sh`)** – fastp trimming, filtering, and interactive QC reports.
- **Step 2 · rRNA Removal (`step-2-rrna-removal.sh`)** – RiboDetector deep-learning filter for ribosomal reads.
- **Step 3 · Fusion Detection (`step-3-fusion-detection.sh`)** – STAR-Fusion in Docker with FusionInspector validation and coding-effect assessment.
- **Step 4 · Merge Results (`step-4-merge-fusion-results.sh`)** – aggregates STAR-Fusion outputs into three master TSV files.
- **Step 5 · TCR/BCR Profiling (`step-5-tcr-bcr-analysis.sh`)** – MixCR V(D)J assembly and clonotype summarization.

---

## 🛠️ Quick Start

```bash
# Clone repository
git clone https://github.com/LiaoWJLab/FBI.git
cd FBI/code

# Prepare environments (run once)
conda create -n rrna -c bioconda fastp -y
conda create -n ribodetector -c bioconda ribodetector -y
conda create -n mixcr -c bioconda mixcr -y
docker pull trinityctat/starfusion

# Execute steps (edit paths inside scripts beforehand)
bash step-1-quality-control.sh
bash step-2-rrna-removal.sh
bash step-3-fusion-detection.sh
bash step-4-merge-fusion-results.sh
bash step-5-tcr-bcr-analysis.sh
```

Each script logs progress and writes `.task.complete` markers so interrupted runs can resume safely.

---

## 📊 Outputs

- `02-fastp/` – cleaned FASTQ files plus fastp HTML/JSON reports
- `03-rribo/` – rRNA-depleted paired reads
- `13-starfusion/` – per-sample STAR-Fusion folders and merged TSV summaries
- `07-mixcr/` – MixCR `.vdjca` alignments and clonotype tables

---

## 📚 Citations

- Chen *et al.* 2018 — fastp
- Kang *et al.* 2022 — RiboDetector
- Haas *et al.* 2019 — STAR-Fusion
- Bolotin *et al.* 2015 — MixCR

---

## 👤 Author & Support

**Dongqiang Zeng**  
Southern Medical University  
📧 interlaken@smu.edu.cn  
🌐 https://github.com/LiaoWJLab/FBI

Report issues or request features at [github.com/LiaoWJLab/FBI/issues](https://github.com/LiaoWJLab/FBI/issues).

---

**License**: MIT — see `LICENSE`.  
**Last Updated**: November 15, 2025


