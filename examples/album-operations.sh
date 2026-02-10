#!/bin/bash
# 相册操作示例脚本
# 演示如何使用 Claw-Immich 进行相册管理

# 加载 API 函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$SCRIPT_DIR")/scripts/immich-api.sh"
source "$(dirname "$SCRIPT_DIR")/scripts/utils.sh"

# 设置错误处理
set -e

echo "=========================================="
echo "  Claw-Immich 相册操作示例"
echo "=========================================="
echo ""

# ============================================================================
# 1. 列出所有相册
# ============================================================================

print_info "1. 列出所有现有相册"
echo ""

albums=$(list_albums)
if is_success_response "$albums"; then
    format_album_list "$albums"
else
    print_error "获取相册列表失败"
    extract_error_message "$albums"
    exit 1
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 2. 创建新相册
# ============================================================================

print_info "2. 创建新相册"
echo ""

# 使用时间戳确保相册名称唯一
timestamp=$(date +%Y%m%d_%H%M%S)
album_name="示例相册_${timestamp}"
album_description="这是一个通过 Claw-Immich 创建的示例相册"

echo "相册名称: $album_name"
echo "相册描述: $album_description"
echo ""

album_response=$(create_album "$album_name" "$album_description")
if is_success_response "$album_response"; then
    print_success "相册创建成功！"

    # 提取相册 ID
    album_id=$(echo "$album_response" | jq -r '.id')
    echo "相册 ID: $album_id"

    # 保存相册 ID 供后续步骤使用
    echo "$album_id" > /tmp/claw_immich_example_album_id.txt
else
    print_error "创建相册失败"
    extract_error_message "$album_response"
    exit 1
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 3. 上传照片到相册
# ============================================================================

print_info "3. 上传照片并添加到相册"
echo ""

# 注意：这里需要用户提供实际的照片文件路径
# 作为示例，我们假设用户有一些照片文件

echo "请输入要上传的照片路径（支持通配符，例如: ~/Pictures/*.jpg）"
echo "如果没有照片可以跳过此步骤，直接按回车"
read -p "照片路径: " photo_pattern

if [[ -n "$photo_pattern" ]]; then
    # 展开通配符
    photo_files=($(eval echo "$photo_pattern"))

    if [[ ${#photo_files[@]} -eq 0 ]]; then
        print_warning "没有找到匹配的照片文件"
    else
        print_info "找到 ${#photo_files[@]} 个文件，开始上传..."
        echo ""

        # 存储上传成功的资源 ID
        asset_ids=()

        for photo in "${photo_files[@]}"; do
            if [[ ! -f "$photo" ]]; then
                print_warning "文件不存在: $photo"
                continue
            fi

            echo "正在上传: $(basename "$photo")"

            asset_response=$(upload_asset "$photo")
            if is_success_response "$asset_response"; then
                asset_id=$(echo "$asset_response" | jq -r '.id')
                asset_ids+=("$asset_id")
                print_success "上传成功: $asset_id"
            else
                print_error "上传失败: $photo"
                extract_error_message "$asset_response"
            fi
        done

        echo ""
        print_success "共上传 ${#asset_ids[@]} 个文件"

        # 如果有上传成功的资源，添加到相册
        if [[ ${#asset_ids[@]} -gt 0 ]]; then
            echo ""
            print_info "将上传的资源添加到相册..."

            add_response=$(add_assets_to_album "$album_id" "${asset_ids[@]}")
            if is_success_response "$add_response"; then
                print_success "资源已添加到相册！"
            else
                print_error "添加资源到相册失败"
                extract_error_message "$add_response"
            fi
        fi
    fi
else
    print_warning "跳过上传步骤"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 4. 查看相册详情
# ============================================================================

print_info "4. 查看相册详情"
echo ""

album_detail=$(get_album "$album_id")
if is_success_response "$album_detail"; then
    format_album_detail "$album_detail"
else
    print_error "获取相册详情失败"
    extract_error_message "$album_detail"
    exit 1
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 5. 更新相册信息
# ============================================================================

print_info "5. 更新相册信息"
echo ""

new_description="相册描述已通过 Claw-Immich 更新于 $(date '+%Y-%m-%d %H:%M:%S')"
update_data=$(jq -n --arg desc "$new_description" '{description: $desc}')

echo "新描述: $new_description"
echo ""

update_response=$(update_album "$album_id" "$update_data")
if is_success_response "$update_response"; then
    print_success "相册信息更新成功！"
else
    print_error "更新相册信息失败"
    extract_error_message "$update_response"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 6. 从相册移除资源（如果有）
# ============================================================================

print_info "6. 管理相册中的资源"
echo ""

# 获取相册中的资源
album_detail=$(get_album "$album_id")
asset_count=$(echo "$album_detail" | jq '.assets | length // 0')

if [[ "$asset_count" -gt 0 ]]; then
    echo "相册中有 $asset_count 个资源"
    echo ""

    # 显示资源列表
    echo "$album_detail" | jq -r '.assets[] | "  - \(.originalFileName // .id) (\(.type))"'
    echo ""

    read -p "是否要从相册中移除第一个资源？(y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # 获取第一个资源的 ID
        first_asset_id=$(echo "$album_detail" | jq -r '.assets[0].id')

        echo "正在移除资源: $first_asset_id"

        remove_response=$(remove_assets_from_album "$album_id" "$first_asset_id")
        if is_success_response "$remove_response"; then
            print_success "资源已从相册中移除"
        else
            print_error "移除资源失败"
            extract_error_message "$remove_response"
        fi
    else
        print_info "跳过移除操作"
    fi
else
    print_info "相册中没有资源"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 7. 删除相册（可选）
# ============================================================================

print_info "7. 删除示例相册"
echo ""

read -p "是否要删除刚才创建的示例相册？(y/N): " confirm_delete
if [[ "$confirm_delete" =~ ^[Yy]$ ]]; then
    delete_response=$(delete_album "$album_id")
    if is_success_response "$delete_response"; then
        print_success "相册已删除"
        rm -f /tmp/claw_immich_example_album_id.txt
    else
        print_error "删除相册失败"
        extract_error_message "$delete_response"
    fi
else
    print_info "保留示例相册"
    echo "相册 ID 已保存到: /tmp/claw_immich_example_album_id.txt"
fi

echo ""
echo "=========================================="
echo "  示例脚本执行完成"
echo "=========================================="
echo ""
echo "你已经学会了："
echo "  ✓ 列出所有相册"
echo "  ✓ 创建新相册"
echo "  ✓ 上传照片"
echo "  ✓ 将照片添加到相册"
echo "  ✓ 查看相册详情"
echo "  ✓ 更新相册信息"
echo "  ✓ 从相册移除资源"
echo "  ✓ 删除相册"
echo ""
echo "更多示例请参阅："
echo "  - asset-operations.sh（资源操作）"
echo "  - search-operations.sh（搜索功能）"
echo ""
