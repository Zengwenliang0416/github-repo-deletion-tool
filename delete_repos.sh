#!/bin/bash

# 检查是否提供了GitHub个人访问令牌
if [ -z "$1" ]; then
    echo "请提供GitHub个人访问令牌"
    echo "使用方法: ./delete_repos.sh <github_token>"
    exit 1
fi

TOKEN=$1

# 获取所有仓库列表
echo "正在获取你的仓库列表..."
curl -s -H "Authorization: token $TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/user/repos?per_page=100" > repos_data.json

if [ ! -s repos_data.json ]; then
    echo "获取仓库列表失败或没有找到仓库"
    exit 1
fi

# 创建一个格式化的仓库列表
echo "你的仓库列表："
echo "--------------------------------------------------------------------------------------------------------"
printf "%-4s %-50s %-10s %-15s %-20s\n" "序号" "仓库名称" "类型" "语言" "最后更新时间"
echo "--------------------------------------------------------------------------------------------------------"

jq -r '.[] | "\(.full_name) \(.private) \(.language // "未知") \(.updated_at)"' repos_data.json | \
while IFS=' ' read -r name private lang updated; do
    index=$((index+1))
    repo_type=$([ "$private" = "true" ] && echo "私有" || echo "公开")
    formatted_date=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$updated" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$updated")
    printf "%-4s %-50s %-10s %-15s %-20s\n" "$index" "$name" "$repo_type" "${lang:-未知}" "$formatted_date"
    echo "$name" >> all_repos.txt
done

echo "--------------------------------------------------------------------------------------------------------"

while true; do
    echo ""
    echo "请输入要删除的仓库编号（多个编号用空格分隔，输入 'q' 退出）："
    read -e input  # 使用 -e 启用readline功能，支持编辑和光标移动
    
    # 清理输入中的特殊字符
    input=$(echo "$input" | tr -cd '0-9q \n')
    
    if [ "$input" = "q" ]; then
        echo "操作已取消"
        rm -f all_repos.txt repos_data.json
        exit 0
    fi
    
    # 验证输入是否为有效的数字
    valid=true
    for num in $input; do
        if ! [[ "$num" =~ ^[0-9]+$ ]]; then
            valid=false
            break
        fi
        
        # 检查数字是否在有效范围内
        if [ "$num" -lt 1 ] || [ "$num" -gt $(wc -l < all_repos.txt) ]; then
            valid=false
            break
        fi
    done
    
    if [ "$valid" = true ]; then
        break
    else
        echo "无效的输入，请输入有效的仓库编号"
    fi
done

# 创建临时文件存储要删除的仓库
> repos_to_delete.txt
for num in $input; do
    sed -n "${num}p" all_repos.txt >> repos_to_delete.txt
done

echo ""
echo "将要删除以下仓库："
echo "--------------------------------------------------------------------------------------------------------"
while IFS= read -r repo; do
    repo_info=$(jq -r --arg repo "$repo" '.[] | select(.full_name == $repo) | "\(.full_name) \(.private) \(.language // "未知") \(.updated_at)"' repos_data.json)
    if [ ! -z "$repo_info" ]; then
        name=$(echo "$repo_info" | cut -d' ' -f1)
        private=$(echo "$repo_info" | cut -d' ' -f2)
        lang=$(echo "$repo_info" | cut -d' ' -f3)
        updated=$(echo "$repo_info" | cut -d' ' -f4)
        
        repo_type=$([ "$private" = "true" ] && echo "私有" || echo "公开")
        formatted_date=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$updated" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$updated")
        printf "%-50s %-10s %-15s %-20s\n" "$name" "$repo_type" "${lang:-未知}" "$formatted_date"
    fi
done < repos_to_delete.txt
echo "--------------------------------------------------------------------------------------------------------"

echo ""
echo "确认删除这些仓库吗？(y/n)"
read -e confirm

if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    while IFS= read -r repo; do
        if [ ! -z "$repo" ]; then
            echo "正在删除仓库: $repo"
            curl -X DELETE \
                 -H "Authorization: token $TOKEN" \
                 -H "Accept: application/vnd.github.v3+json" \
                 "https://api.github.com/repos/$repo"
            
            if [ $? -eq 0 ]; then
                echo "成功删除仓库: $repo"
            else
                echo "删除仓库失败: $repo"
            fi
        fi
    done < repos_to_delete.txt
    echo "删除操作完成！"
else
    echo "操作已取消"
fi

# 清理临时文件
rm -f all_repos.txt repos_to_delete.txt repos_data.json
