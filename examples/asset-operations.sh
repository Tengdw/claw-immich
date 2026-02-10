#!/bin/bash
# 资源操作示例脚本
# 演示如何使用 Claw-Immich 管理照片和视频资源

# 加载 API 函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$SCRIPT_DIR")/scripts/immich-api.sh"
source "$(dirname "$SCRIPT_DIR")/scripts/utils.sh"

# 设置错误处理
set -e

echo "=========================================="
echo "  Claw-Immich 资源操作示例"
echo "=========================================="
echo ""

# ============================================================================
# 1. 上传单个资源
# ============================================================================

print_info "1. 上传单个照片或视频"
echo ""

echo "请输入要上传的文件路径（例如: ~/Pictures/photo.jpg）"
echo "如果没有文件可以跳过此步骤，直接按回车"
read -p "文件路径: " file_path

uploaded_asset_id=""

if [[ -n "$file_path" ]]; then
    # 展开路径（处理 ~）
    file_path=$(eval echo "$file_path")

    if [[ ! -f "$file_path" ]]; then
        print_error "文件不存在: $file_path"
    else
        echo ""
        print_info "文件信息:"
        echo "  路径: $file_path"
        echo "  名称: $(basename "$file_path")"
        echo "  大小: $(human_readable_size $(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path"))"
        echo "  类型: $(get_mime_type "$file_path")"
        echo ""

        print_info "开始上传..."

        upload_response=$(upload_asset "$file_path")
        if is_success_response "$upload_response"; then
            uploaded_asset_id=$(echo "$upload_response" | jq -r '.id')
            print_success "上传成功！"
            echo "资源 ID: $uploaded_asset_id"

            # 保存资源 ID 供后续步骤使用
            echo "$uploaded_asset_id" > /tmp/claw_immich_example_asset_id.txt
        else
            print_error "上传失败"
            extract_error_message "$upload_response"
        fi
    fi
else
    print_warning "跳过上传步骤"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 2. 批量上传多个文件
# ============================================================================

print_info "2. 批量上传多个文件"
echo ""

echo "请输入要批量上传的文件路径模式（例如: ~/Pictures/vacation/*.jpg）"
echo "如果不需要批量上传，直接按回车跳过"
read -p "路径模式: " batch_pattern

uploaded_asset_ids=()

if [[ -n "$batch_pattern" ]]; then
    # 展开通配符
    batch_files=($(eval echo "$batch_pattern"))

    if [[ ${#batch_files[@]} -eq 0 ]]; then
        print_warning "没有找到匹配的文件"
    else
        print_info "找到 ${#batch_files[@]} 个文件"
        echo ""

        read -p "是否继续上传这些文件？(y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo ""

            for i in "${!batch_files[@]}"; do
                file="${batch_files[$i]}"
                index=$((i + 1))

                if [[ ! -f "$file" ]]; then
                    print_warning "[$index/${#batch_files[@]}] 文件不存在: $file"
                    continue
                fi

                echo "[$index/${#batch_files[@]}] 上传: $(basename "$file")"

                upload_response=$(upload_asset "$file")
                if is_success_response "$upload_response"; then
                    asset_id=$(echo "$upload_response" | jq -r '.id')
                    uploaded_asset_ids+=("$asset_id")
                    print_success "  ✓ 成功: $asset_id"
                else
                    print_error "  ✗ 失败"
                    extract_error_message "$upload_response" | sed 's/^/    /'
                fi

                # 添加小延迟避免过载服务器
                sleep 0.5
            done

            echo ""
            print_success "批量上传完成: 成功 ${#uploaded_asset_ids[@]} 个，失败 $((${#batch_files[@]} - ${#uploaded_asset_ids[@]})) 个"

            # 如果之前没有单个上传，使用第一个批量上传的 ID
            if [[ -z "$uploaded_asset_id" && ${#uploaded_asset_ids[@]} -gt 0 ]]; then
                uploaded_asset_id="${uploaded_asset_ids[0]}"
                echo "$uploaded_asset_id" > /tmp/claw_immich_example_asset_id.txt
            fi
        else
            print_info "取消批量上传"
        fi
    fi
else
    print_warning "跳过批量上传"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 3. 获取资源详细信息
# ============================================================================

print_info "3. 获取资源详细信息"
echo ""

if [[ -z "$uploaded_asset_id" ]]; then
    print_warning "没有可用的资源 ID，跳过此步骤"
    echo "你可以手动输入一个资源 ID："
    read -p "资源 ID (直接回车跳过): " manual_asset_id

    if [[ -n "$manual_asset_id" ]]; then
        uploaded_asset_id="$manual_asset_id"
    fi
fi

if [[ -n "$uploaded_asset_id" ]]; then
    asset_detail=$(get_asset "$uploaded_asset_id")
    if is_success_response "$asset_detail"; then
        format_asset_detail "$asset_detail"
    else
        print_error "获取资源信息失败"
        extract_error_message "$asset_detail"
    fi
else
    print_warning "没有资源 ID，跳过"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 4. 更新资源信息
# ============================================================================

print_info "4. 更新资源信息"
echo ""

if [[ -n "$uploaded_asset_id" ]]; then
    echo "可以更新的信息："
    echo "  - 描述（description）"
    echo "  - 收藏状态（isFavorite）"
    echo "  - 归档状态（isArchived）"
    echo ""

    # 设置为收藏
    read -p "是否将此资源标记为收藏？(y/N): " mark_favorite
    if [[ "$mark_favorite" =~ ^[Yy]$ ]]; then
        update_data='{"isFavorite": true, "description": "通过 Claw-Immich 标记为收藏"}'

        update_response=$(update_asset "$uploaded_asset_id" "$update_data")
        if is_success_response "$update_response"; then
            print_success "资源已标记为收藏 ★"
        else
            print_error "更新失败"
            extract_error_message "$update_response"
        fi
    else
        print_info "跳过更新"
    fi
else
    print_warning "没有资源 ID，跳过此步骤"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 5. 搜索类似资源
# ============================================================================

print_info "5. 搜索最近上传的资源"
echo ""

# 搜索最近 7 天上传的所有照片
seven_days_ago=$(date -u -v-7d +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%S.000Z")
today=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

search_query=$(build_date_filter "$seven_days_ago" "$today")
search_query=$(echo "$search_query" | jq '. + {type: "IMAGE"}')

echo "搜索条件:"
echo "$search_query" | jq .
echo ""

search_results=$(search_assets "$search_query")
if is_success_response "$search_results"; then
    result_count=$(echo "$search_results" | jq '.assets.items | length // 0')

    if [[ "$result_count" -gt 0 ]]; then
        print_success "找到 $result_count 个资源"
        echo ""

        # 显示前 5 个结果
        echo "前 5 个结果:"
        echo ""
        echo "$search_results" | jq -r '.assets.items[:5][] |
            "ID: \(.id)\n" +
            "文件名: \(.originalFileName)\n" +
            "类型: \(.type)\n" +
            "上传时间: \(.createdAt)\n" +
            "---"'
    else
        print_info "没有找到匹配的资源"
    fi
else
    print_error "搜索失败"
    extract_error_message "$search_results"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 6. 下载资源
# ============================================================================

print_info "6. 下载资源"
echo ""

if [[ -n "$uploaded_asset_id" ]]; then
    read -p "是否下载之前上传的资源？(y/N): " download_confirm

    if [[ "$download_confirm" =~ ^[Yy]$ ]]; then
        # 获取原始文件名
        asset_info=$(get_asset "$uploaded_asset_id")
        original_name=$(echo "$asset_info" | jq -r '.originalFileName // "download"')

        # 下载到临时目录
        download_path="/tmp/immich_download_${original_name}"

        echo "下载到: $download_path"
        echo ""

        download_asset "$uploaded_asset_id" "$download_path"

        if [[ -f "$download_path" ]]; then
            print_success "下载成功！"
            echo "文件大小: $(human_readable_size $(stat -f%z "$download_path" 2>/dev/null || stat -c%s "$download_path"))"
        else
            print_error "下载失败"
        fi
    else
        print_info "跳过下载"
    fi
else
    print_warning "没有资源 ID，跳过此步骤"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 7. 删除资源（可选）
# ============================================================================

print_info "7. 删除资源"
echo ""

if [[ -n "$uploaded_asset_id" ]]; then
    print_warning "警告: 删除操作不可恢复！"
    read -p "是否要删除之前上传的示例资源？(y/N): " delete_confirm

    if [[ "$delete_confirm" =~ ^[Yy]$ ]]; then
        delete_response=$(delete_asset "$uploaded_asset_id")
        if is_success_response "$delete_response"; then
            print_success "资源已删除"
            rm -f /tmp/claw_immich_example_asset_id.txt
        else
            print_error "删除失败"
            extract_error_message "$delete_response"
        fi
    else
        print_info "保留资源"
        echo "资源 ID 已保存到: /tmp/claw_immich_example_asset_id.txt"
    fi
else
    print_warning "没有资源 ID，跳过此步骤"
fi

echo ""
echo "=========================================="
echo "  示例脚本执行完成"
echo "=========================================="
echo ""
echo "你已经学会了："
echo "  ✓ 上传单个文件"
echo "  ✓ 批量上传多个文件"
echo "  ✓ 获取资源详细信息"
echo "  ✓ 更新资源元数据"
echo "  ✓ 搜索资源"
echo "  ✓ 下载资源"
echo "  ✓ 删除资源"
echo ""
echo "更多示例请参阅："
echo "  - album-operations.sh（相册管理）"
echo "  - search-operations.sh（搜索功能）"
echo ""
