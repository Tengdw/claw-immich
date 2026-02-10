#!/bin/bash
# 搜索操作示例脚本
# 演示如何使用 Claw-Immich 的各种搜索功能

# 加载 API 函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$SCRIPT_DIR")/scripts/immich-api.sh"
source "$(dirname "$SCRIPT_DIR")/scripts/utils.sh"

# 设置错误处理
set -e

echo "=========================================="
echo "  Claw-Immich 搜索功能示例"
echo "=========================================="
echo ""

# ============================================================================
# 1. 按日期范围搜索
# ============================================================================

print_info "1. 按日期范围搜索照片"
echo ""

echo "示例：搜索最近 30 天内拍摄的所有照片"
echo ""

# 计算日期范围
thirty_days_ago=$(date -u -v-30d +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u -d "30 days ago" +"%Y-%m-%dT%H:%M:%S.000Z")
today=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

search_query=$(build_date_filter "$thirty_days_ago" "$today")
search_query=$(echo "$search_query" | jq '. + {type: "IMAGE"}')

echo "搜索条件:"
echo "$search_query" | jq .
echo ""

print_info "执行搜索..."
search_results=$(search_assets "$search_query")

if is_success_response "$search_results"; then
    result_count=$(echo "$search_results" | jq '.assets.items | length // 0')
    print_success "找到 $result_count 张照片"

    if [[ "$result_count" -gt 0 ]]; then
        echo ""
        echo "前 10 个结果:"
        echo ""
        format_asset_list "$search_results" | head -50
    fi
else
    print_error "搜索失败"
    extract_error_message "$search_results"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 2. 按文件类型搜索
# ============================================================================

print_info "2. 按文件类型搜索"
echo ""

echo "可用的文件类型："
echo "  - IMAGE: 图片（JPEG, PNG, GIF, HEIC 等）"
echo "  - VIDEO: 视频（MP4, MOV, AVI 等）"
echo ""

read -p "选择文件类型 (IMAGE/VIDEO) [IMAGE]: " file_type
file_type=${file_type:-IMAGE}

search_query=$(jq -n --arg type "$file_type" '{type: $type}')

echo ""
echo "搜索条件:"
echo "$search_query" | jq .
echo ""

print_info "执行搜索..."
search_results=$(search_assets "$search_query")

if is_success_response "$search_results"; then
    result_count=$(echo "$search_results" | jq '.assets.items | length // 0')
    print_success "找到 $result_count 个 $file_type 文件"

    if [[ "$result_count" -gt 0 ]]; then
        echo ""
        echo "文件统计:"

        # 统计不同的文件扩展名
        echo "$search_results" | jq -r '.assets.items[] | .originalFileName' | \
            sed 's/.*\.//' | sort | uniq -c | sort -rn | \
            awk '{printf "  %s: %d 个\n", $2, $1}'
    fi
else
    print_error "搜索失败"
    extract_error_message "$search_results"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 3. 按位置搜索
# ============================================================================

print_info "3. 按位置信息搜索"
echo ""

echo "示例：搜索在特定城市拍摄的照片"
echo ""

read -p "输入城市名称（例如：Beijing, Shanghai, Tokyo）[跳过]: " city_name

if [[ -n "$city_name" ]]; then
    search_query=$(jq -n \
        --arg city "$city_name" \
        '{city: $city, type: "IMAGE"}')

    echo ""
    echo "搜索条件:"
    echo "$search_query" | jq .
    echo ""

    print_info "执行搜索..."
    search_results=$(search_assets "$search_query")

    if is_success_response "$search_results"; then
        result_count=$(echo "$search_results" | jq '.assets.items | length // 0')
        print_success "在 $city_name 找到 $result_count 张照片"

        if [[ "$result_count" -gt 0 ]]; then
            echo ""
            echo "照片详情:"
            echo ""
            echo "$search_results" | jq -r '.assets.items[:5][] |
                "📍 \(.originalFileName)\n" +
                "   位置: \(.exifInfo.city // "未知"), \(.exifInfo.state // ""), \(.exifInfo.country // "")\n" +
                "   拍摄时间: \(.fileCreatedAt)\n" +
                "   ---"'
        fi
    else
        print_error "搜索失败"
        extract_error_message "$search_results"
    fi
else
    print_warning "跳过位置搜索"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 4. 按相机设备搜索
# ============================================================================

print_info "4. 按相机设备搜索"
echo ""

echo "示例：搜索使用特定相机拍摄的照片"
echo ""

read -p "输入相机品牌（例如：Canon, Nikon, Sony）[跳过]: " camera_make

if [[ -n "$camera_make" ]]; then
    read -p "输入相机型号（可选，直接回车跳过）: " camera_model

    if [[ -n "$camera_model" ]]; then
        search_query=$(jq -n \
            --arg make "$camera_make" \
            --arg model "$camera_model" \
            '{make: $make, model: $model, type: "IMAGE"}')
    else
        search_query=$(jq -n \
            --arg make "$camera_make" \
            '{make: $make, type: "IMAGE"}')
    fi

    echo ""
    echo "搜索条件:"
    echo "$search_query" | jq .
    echo ""

    print_info "执行搜索..."
    search_results=$(search_assets "$search_query")

    if is_success_response "$search_results"; then
        result_count=$(echo "$search_results" | jq '.assets.items | length // 0')
        print_success "找到 $result_count 张照片"

        if [[ "$result_count" -gt 0 ]]; then
            echo ""
            echo "设备统计:"

            # 统计不同的相机型号
            echo "$search_results" | jq -r '.assets.items[] |
                "\(.exifInfo.make // "未知") \(.exifInfo.model // "")"' | \
                sort | uniq -c | sort -rn | \
                awk '{printf "  %s: %d 张\n", substr($0, index($0,$2)), $1}'
        fi
    else
        print_error "搜索失败"
        extract_error_message "$search_results"
    fi
else
    print_warning "跳过相机搜索"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 5. 组合条件搜索
# ============================================================================

print_info "5. 多条件组合搜索"
echo ""

echo "示例：搜索特定时间范围、特定类型的收藏照片"
echo ""

# 过去一年
one_year_ago=$(date -u -v-1y +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u -d "1 year ago" +"%Y-%m-%dT%H:%M:%S.000Z")
today=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

search_query=$(jq -n \
    --arg after "$one_year_ago" \
    --arg before "$today" \
    '{
        takenAfter: $after,
        takenBefore: $before,
        type: "IMAGE",
        isFavorite: true
    }')

echo "搜索条件:"
echo "$search_query" | jq .
echo ""

print_info "执行搜索..."
search_results=$(search_assets "$search_query")

if is_success_response "$search_results"; then
    result_count=$(echo "$search_results" | jq '.assets.items | length // 0')
    print_success "找到 $result_count 张收藏照片（过去一年）"

    if [[ "$result_count" -gt 0 ]]; then
        echo ""
        format_asset_list "$search_results" | head -50
    fi
else
    print_error "搜索失败"
    extract_error_message "$search_results"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 6. 智能搜索（CLIP）
# ============================================================================

print_info "6. 智能搜索（AI 语义搜索）"
echo ""

echo "智能搜索使用 AI 模型理解图片内容，可以搜索："
echo "  - 场景：beach, mountain, city, forest"
echo "  - 物体：cat, dog, car, building"
echo "  - 活动：swimming, running, eating"
echo "  - 情绪：happy, sad, excited"
echo ""

read -p "输入搜索查询（英文，例如：beach sunset）[跳过]: " smart_query

if [[ -n "$smart_query" ]]; then
    read -p "返回结果数量 [20]: " result_limit
    result_limit=${result_limit:-20}

    echo ""
    print_info "执行智能搜索..."

    smart_results=$(smart_search "$smart_query" "$result_limit")

    if is_success_response "$smart_results"; then
        result_count=$(echo "$smart_results" | jq '.assets.items | length // 0')
        print_success "找到 $result_count 个匹配结果"

        if [[ "$result_count" -gt 0 ]]; then
            echo ""
            echo "智能搜索结果（按相关度排序）:"
            echo ""

            echo "$smart_results" | jq -r '.assets.items[:10][] |
                "🔍 \(.originalFileName)\n" +
                "   类型: \(.type)\n" +
                "   拍摄时间: \(.fileCreatedAt)\n" +
                if .exifInfo.city then "   位置: \(.exifInfo.city)\n" else "" end +
                "   ---"'
        fi
    else
        print_error "智能搜索失败"
        extract_error_message "$smart_results"
        echo ""
        print_info "注意：智能搜索需要服务器启用 CLIP 机器学习模型"
    fi
else
    print_warning "跳过智能搜索"
fi

echo ""
read -p "按回车键继续..."
echo ""

# ============================================================================
# 7. 自定义高级搜索
# ============================================================================

print_info "7. 自定义高级搜索"
echo ""

echo "你可以构建自己的搜索查询 JSON"
echo ""
echo "示例查询:"
echo '{
  "takenAfter": "2024-01-01T00:00:00.000Z",
  "takenBefore": "2024-12-31T23:59:59.999Z",
  "type": "IMAGE",
  "city": "Beijing",
  "make": "Apple"
}'
echo ""

read -p "是否要尝试自定义搜索？(y/N): " custom_confirm

if [[ "$custom_confirm" =~ ^[Yy]$ ]]; then
    echo ""
    echo "请输入 JSON 搜索条件（多行输入，输入 EOF 结束）:"
    echo ""

    custom_query=""
    while IFS= read -r line; do
        if [[ "$line" == "EOF" ]]; then
            break
        fi
        custom_query+="$line"$'\n'
    done

    # 验证 JSON 格式
    if echo "$custom_query" | jq . > /dev/null 2>&1; then
        echo ""
        print_info "执行自定义搜索..."

        search_results=$(search_assets "$custom_query")

        if is_success_response "$search_results"; then
            result_count=$(echo "$search_results" | jq '.assets.items | length // 0')
            print_success "找到 $result_count 个结果"

            if [[ "$result_count" -gt 0 ]]; then
                echo ""
                format_asset_list "$search_results" | head -30
            fi
        else
            print_error "搜索失败"
            extract_error_message "$search_results"
        fi
    else
        print_error "无效的 JSON 格式"
    fi
else
    print_info "跳过自定义搜索"
fi

echo ""
echo "=========================================="
echo "  示例脚本执行完成"
echo "=========================================="
echo ""
echo "你已经学会了："
echo "  ✓ 按日期范围搜索"
echo "  ✓ 按文件类型搜索"
echo "  ✓ 按位置信息搜索"
echo "  ✓ 按相机设备搜索"
echo "  ✓ 多条件组合搜索"
echo "  ✓ 智能搜索（CLIP AI）"
echo "  ✓ 自定义高级搜索"
echo ""
echo "搜索技巧："
echo "  - 使用精确的日期范围缩小结果"
echo "  - 组合多个条件获得更精确的结果"
echo "  - 智能搜索支持自然语言描述"
echo "  - 可以搜索 EXIF 元数据中的任何字段"
echo ""
echo "更多示例请参阅："
echo "  - album-operations.sh（相册管理）"
echo "  - asset-operations.sh（资源操作）"
echo ""
