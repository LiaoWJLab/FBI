#!/bin/bash




# 原始数据质控
#####################################
bash
conda activate rrna

input_dir="/home/data3/TIMES001/01-raw"
output_dir="/home/data3/TIMES001/02-fastp"

# 获取所有 _1.fastq.gz 文件的列表
files=(${input_dir}/*_1.fastq.gz)
# 随机排序文件列表
shuf_files=($(shuf -e "${files[@]}"))


# 使用for循环处理每个文件
for forward_file in "${shuf_files[@]}"; do
    # 获取文件名（不包含路径和扩展名）
    base_name=$(basename "$forward_file" "_1.fastq.gz")
    
    # 构建反向文件路径
    reverse_file="${input_dir}/${base_name}_2.fastq.gz"
    
    # 检查反向文件是否存在
    if [[ ! -f "$reverse_file" ]]; then
        echo "错误: 找不到对应的反向文件: $reverse_file"
        continue
    fi
    
    # 设置输出文件路径
    output_forward="${output_dir}/${base_name}_1.fastq.gz"
    output_reverse="${output_dir}/${base_name}_2.fastq.gz"
    json_report="${output_dir}/${base_name}_fastp.json"
    html_report="${output_dir}/${base_name}_fastp.html"
    
    echo "正在处理: $base_name"
    echo "输入文件: $forward_file 和 $reverse_file"
    echo "输出文件: $output_forward 和 $output_reverse"
    
    # 运行fastp进行质控
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
    
    # 检查fastp是否成功执行
    if [[ $? -eq 0 ]]; then
        echo "✓ 成功完成: $base_name"
        # 创建完成标记文件
        touch "${output_dir}/${base_name}.task.complete"
    else
        echo "✗ 处理失败: $base_name"
        # 创建失败标记文件
        touch "${output_dir}/${base_name}.task.failed"
    fi
    
    echo "----------------------------------------"
done

echo "所有文件处理完成！"

#######################################




# 移除核糖体RNA
#########################################
bash
# 激活 Conda 环境
conda activate ribodetector

# 设置输入和输出的基本路径
input_dir="/home/data3/TIMES001/02-fastp"
output_dir="/home/data3/TIMES001/03-rribo"

# 获取所有 _1.fastq.gz 文件的列表
files=(${input_dir}/*_1.fastq.gz)
# 随机排序文件列表
shuf_files=($(shuf -e "${files[@]}"))

# 遍历所有随机排序后的 _1.fastq.gz 文件
for file1 in "${shuf_files[@]}"; do
    # 根据文件名找到配对的 _2.fastq.gz 文件
    file2="${file1/_1.fastq.gz/_2.fastq.gz}"
    
    # 创建输出文件名
    output_file1="${file1/$input_dir/$output_dir}"
    output_file2="${file2/$input_dir/$output_dir}"
    
    # 从文件名中提取样本ID
    sample_id=$(basename "$file1" | sed 's/_1.fastq.gz//')
    complete_file="${output_dir}/${sample_id}.task.complete"
    
    # 检查是否存在完成文件
    if [ -f "$complete_file" ]; then
        echo "Sample ${sample_id} already processed, skipping."
        continue
    fi
    
    # 运行 ribodetector_cpu
    ribodetector_cpu -t 36 -l 100 \
                     -i "$file1" "$file2" \
                     -o "$output_file1" "$output_file2" \
                     -e rrna \
                     --chunk_size 6400
    
    # 运行成功后创建完成标记文件
    touch "$complete_file"
done




##########################################
path_base="/home/data3/TIMES001"
path_input="/home/data3/TIMES001/03-rribo"
path_out="/home/data3/TIMES001/13-starfusion"
# Navigate to the directory
cd $path_base

# Loop through each fastq.gz file in /IMpower133/02-fastp
for fq1 in $(ls "${path_input}"/*_1.fastq.gz | shuf); do
    # Get the base filename without extension
    sample_name=$(basename "${fq1}" _1.fastq.gz)

    # Check if task.complete file already exists
    if [ -e "${path_out}/${sample_name}/task.complete" ]; then
        echo "Skipping ${sample_name} as task.complete already exists."
        continue
    fi
    
    # Create the output directory if it doesn't exist
    mkdir -p "${path_out}/${sample_name}"

    # Run Docker command
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


    # Check the exit status of Docker command
    docker_exit_status=$?
    
    # If Docker command executed successfully (exit status 0), create task.complete file
    if [ ${docker_exit_status} -eq 0 ]; then
        touch "${path_out}/${sample_name}/task.complete"
    else
        echo "Error: Docker command failed for ${sample_name}."
    fi
    
    # Create task.complete file to indicate completion
    # touch "${path_out}/${sample_name}/task.complete"
done



# 合并结果文件
###############################################
cd /home/data3/TIMES001/13-starfusion

#!/bin/bash

# 输出文件的路径
output_file="1-merged_fusion_predictions.tsv"
# 创建一个带有完整标题行的输出文件
echo -e "Folder_ID\t#FusionName\tJunctionReadCount\tSpanningFragCount\test_J\test_S\tSpliceType\tLeftGene\tLeftBreakpoint\tRightGene\tRightBreakpoint\tJunctionReads\tSpanningFrags\tLargeAnchorSupport\tFFPM\tLeftBreakDinuc\tLeftBreakEntropy\tRightBreakDinuc\tRightBreakEntropy\tannots" > "$output_file"

# 遍历当前目录下的所有子文件夹
for dir in */; do
    # 检查每个子文件夹中的目标文件路径
    file_path="${dir}star-fusion.fusion_predictions.tsv"

    # 如果文件存在，则处理
    if [ -f "$file_path" ]; then
        # 获取文件夹名称，作为ID使用
        folder_id="${dir%/}"  # 移除路径末尾的斜线
        
        # 使用awk处理每个文件：为每行添加文件夹ID，跳过第一行标题
        awk -v id="$folder_id" 'NR>1 {print id "\t" $0}' "$file_path" >> "$output_file"
    fi
done

echo "Data merge completed. Output file: $output_file"


###################################################



#!/bin/bash

# Output file where merged results will be saved
output_file="2-merged_fusion_predictions_abridged.tsv"
# Write the header line to the output file
echo -e "Folder_ID\t#FusionName\tJunctionReadCount\tSpanningFragCount\test_J\test_S\tSpliceType\tLeftGene\tLeftBreakpoint\tRightGene\tRightBreakpoint\tLargeAnchorSupport\tFFPM\tLeftBreakDinuc\tLeftBreakEntropy\tRightBreakDinuc\tRightBreakEntropy\tannots" > "$output_file"

# Loop through all directories in the current directory
for dir in */; do
    # Path to the specific fusion file
    file_path="${dir}star-fusion.fusion_predictions.abridged.tsv"

    # Check if the fusion file exists in the directory
    if [ -f "$file_path" ]; then
        # Get the directory name, remove the trailing slash for use as ID
        folder_id="${dir%/}"

        # Append data from file to the output, prepending the folder name
        awk -v id="$folder_id" 'NR>1 {print id "\t" $0}' "$file_path" >> "$output_file"
    fi
done

echo "Data merge completed. Output file: $output_file"

#####################################################




# Output file where merged results will be saved
output_file="3-merged_fusion_predictions_abridged_coding_effect.tsv"
# Write the header line to the output file
echo -e "Folder_ID\t#FusionName\tJunctionReadCount\tSpanningFragCount\test_J\test_S\tSpliceType\tLeftGene\tLeftBreakpoint\tRightGene\tRightBreakpoint\tLargeAnchorSupport\tFFPM\tLeftBreakDinuc\tLeftBreakEntropy\tRightBreakDinuc\tRightBreakEntropy\tannots" > "$output_file"

# Loop through all directories in the current directory
for dir in */; do
    # Path to the specific fusion file
    file_path="${dir}star-fusion.fusion_predictions.abridged.coding_effect.tsv"

    # Check if the fusion file exists in the directory
    if [ -f "$file_path" ]; then
        # Get the directory name, remove the trailing slash for use as ID
        folder_id="${dir%/}"

        # Append data from file to the output, prepending the folder name
        awk -v id="$folder_id" 'NR>1 {print id "\t" $0}' "$file_path" >> "$output_file"
    fi
done

echo "Data merge completed. Output file: $output_file"

########################################################




# 使用MixCR 进行TCR/BCR序列组装和识别
########################################################

bash
input_folder="/home/data3/TIMES001/03-rribo/"
output_folder="/home/data3/TIMES001/07-mixcr/"

# Create an array to hold the files
files=(${input_folder}*_1.fastq.gz)

# Shuffle the array using a random sort
shuffled_files=($(shuf -e "${files[@]}"))

# Iterate over the shuffled array
for file in "${shuffled_files[@]}"; do
  sample=$(basename $file _1.fastq.gz)
  if [ -f "${output_folder}${sample}.vdjca" ]; then
    echo "Skipping sample $sample - Output folder ${output_folder}${sample}.vdjca already exists."
    continue
  fi
  java -jar /home/data/project/biosoft/mixcr/mixcr.jar analyze rna-seq \
  -t 32 --species hsa ${input_folder}${sample}_1.fastq.gz ${input_folder}${sample}_2.fastq.gz ${output_folder}${sample}
done

######################################################
