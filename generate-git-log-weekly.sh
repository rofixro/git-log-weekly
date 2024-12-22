#!/bin/bash

# 设置默认用户名为 Rofix
author="${1:-Rofix}"

# 检测操作系统类型和对应的打开命令
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    end_date=$(date +%Y-%m-%d)
    start_date=$(date -v-7d +%Y-%m-%d)
    OPEN_CMD="open"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Windows
    end_date=$(date +%Y-%m-%d)
    start_date=$(date --date="7 days ago" +%Y-%m-%d)
    OPEN_CMD="start"
else
    # Linux
    end_date=$(date +%Y-%m-%d)
    start_date=$(date --date="7 days ago" +%Y-%m-%d)
    OPEN_CMD="xdg-open"
fi

# 输出文件名（包含用户名）
output_file="git_log_${author}_${start_date}_to_${end_date}.txt"

# 删除上次生成的文件
rm -f git_log_*.txt

echo "正在获取用户 ${author} 从 ${start_date} 到 ${end_date} 的提交记录..."

# 检查是否在git仓库中
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "错误：当前目录不是 Git 仓库！"
    exit 1
fi

# 临时文件用于存储编号
temp_file=$(mktemp)

# 获取提交记录，过滤掉包含"更新"的提交，并添加编号
git log --author="${author}" --since="${start_date} 00:00:00" --until="${end_date} 23:59:59" \
    --pretty=format:"%s" | grep -v "更新" | \
    awk 'NF' | \
    awk '{printf "%d.%s\n", NR, $0}' > "${temp_file}"

# 检查是否有提交记录
if [ ! -s "${temp_file}" ]; then
    echo "在指定时间范围内没有找到符合条件的提交记录"
    echo "时间范围: ${start_date} 到 ${end_date}"
    echo "用户: ${author}"
    echo "请确认："
    echo "1. 用户名是否正确"
    echo "2. 该时间范围内是否有提交"
    echo "3. 可以通过以下命令查看所有提交者："
    echo "   git log --format='%an' | sort -u"
    rm -f "${temp_file}"
    exit 1
fi

# 移动临时文件到最终输出文件
mv "${temp_file}" "${output_file}"

# 统计提交数量
commit_count=$(wc -l < "${output_file}")

echo -e "\n提交记录已导出到 ${output_file}"
echo "共计 ${commit_count} 条提交"

# 显示文件内容预览
echo -e "\n前5条提交记录预览："
head -n 5 "${output_file}"

# 尝试打开文件
echo -e "\n正在打开文件..."
if ! ${OPEN_CMD} "${output_file}" 2>/dev/null; then
    echo "无法自动打开文件，请手动打开：${output_file}"
fi
