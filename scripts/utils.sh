#!/bin/bash
# Immich API 辅助工具函数
# 提供格式化输出、错误处理等实用功能

# ============================================================================
# JSON 处理
# ============================================================================

# 格式化 JSON 响应
# 参数: json_data
format_json_response() {
    local json_data="$1"

    if [[ -z "$json_data" ]]; then
        echo "{}"
        return 0
    fi

    # 使用 jq 格式化（如果 JSON 有效）
    if echo "$json_data" | jq . > /dev/null 2>&1; then
        echo "$json_data" | jq .
    else
        # 如果不是有效的 JSON，直接输出
        echo "$json_data"
    fi
}

# 从 API 响应中提取错误信息
# 参数: response
extract_error_message() {
    local response="$1"

    if [[ -z "$response" ]]; then
        echo "未知错误"
        return 0
    fi

    # 尝试从 JSON 中提取错误消息
    local error_msg=$(echo "$response" | jq -r '.message // .error // empty' 2>/dev/null)

    if [[ -n "$error_msg" ]]; then
        echo "$error_msg"
    else
        # 如果没有标准错误字段，返回原始响应
        echo "$response"
    fi
}

# 检查响应是否成功
# 参数: response
# 返回: 0 表示成功，1 表示失败
is_success_response() {
    local response="$1"

    if [[ -z "$response" ]]; then
        return 1
    fi

    # 检查是否包含错误标识
    if echo "$response" | grep -qi "错误\|error"; then
        return 1
    fi

    # 检查是否为有效的 JSON
    if echo "$response" | jq . > /dev/null 2>&1; then
        # 检查是否有 error 字段
        local has_error=$(echo "$response" | jq 'has("error")' 2>/dev/null)
        if [[ "$has_error" == "true" ]]; then
            return 1
        fi
        return 0
    fi

    # 默认认为失败
    return 1
}

# ============================================================================
# 格式化输出
# ============================================================================

# 格式化相册列表
# 参数: albums_json
format_album_list() {
    local albums_json="$1"

    if [[ -z "$albums_json" ]]; then
        echo "没有相册"
        return 0
    fi

    # 检查是否为有效的 JSON 数组
    if ! echo "$albums_json" | jq -e '. | type == "array"' > /dev/null 2>&1; then
        echo "无效的相册数据"
        return 1
    fi

    local count=$(echo "$albums_json" | jq 'length')

    if [[ "$count" -eq 0 ]]; then
        echo "没有相册"
        return 0
    fi

    echo "共找到 $count 个相册："
    echo ""

    # 格式化输出每个相册
    echo "$albums_json" | jq -r '.[] |
        "ID: \(.id)\n" +
        "名称: \(.albumName)\n" +
        "描述: \(.description // "无")\n" +
        "资源数量: \(.assetCount)\n" +
        "创建时间: \(.createdAt)\n" +
        "---"'
}

# 格式化资源列表
# 参数: assets_json
format_asset_list() {
    local assets_json="$1"

    if [[ -z "$assets_json" ]]; then
        echo "没有资源"
        return 0
    fi

    # 处理搜索结果格式（assets.items）
    local items=$(echo "$assets_json" | jq -e '.assets.items // .items // .' 2>/dev/null)

    if [[ -z "$items" || "$items" == "null" ]]; then
        echo "没有资源"
        return 0
    fi

    # 检查是否为有效的 JSON 数组
    if ! echo "$items" | jq -e '. | type == "array"' > /dev/null 2>&1; then
        echo "无效的资源数据"
        return 1
    fi

    local count=$(echo "$items" | jq 'length')

    if [[ "$count" -eq 0 ]]; then
        echo "没有资源"
        return 0
    fi

    echo "共找到 $count 个资源："
    echo ""

    # 格式化输出每个资源
    echo "$items" | jq -r '.[] |
        "ID: \(.id)\n" +
        "类型: \(.type)\n" +
        "文件名: \(.originalFileName // "未知")\n" +
        "拍摄时间: \(.fileCreatedAt // "未知")\n" +
        "尺寸: \(.exifInfo.exifImageWidth // "?")x\(.exifInfo.exifImageHeight // "?")\n" +
        if .exifInfo.make then "相机: \(.exifInfo.make) \(.exifInfo.model // "")\n" else "" end +
        if .exifInfo.city then "位置: \(.exifInfo.city), \(.exifInfo.state // ""), \(.exifInfo.country // "")\n" else "" end +
        "---"'
}

# 格式化单个相册详情
# 参数: album_json
format_album_detail() {
    local album_json="$1"

    if [[ -z "$album_json" ]]; then
        echo "没有相册信息"
        return 0
    fi

    echo "相册详情："
    echo ""
    echo "$album_json" | jq -r '
        "ID: \(.id)\n" +
        "名称: \(.albumName)\n" +
        "描述: \(.description // "无")\n" +
        "所有者: \(.owner.name)\n" +
        "资源数量: \(.assetCount)\n" +
        "创建时间: \(.createdAt)\n" +
        "更新时间: \(.updatedAt)\n" +
        if .startDate then "起始日期: \(.startDate)\n" else "" end +
        if .endDate then "结束日期: \(.endDate)\n" else "" end'

    # 显示相册中的资源（如果有）
    local asset_count=$(echo "$album_json" | jq '.assets | length // 0')
    if [[ "$asset_count" -gt 0 ]]; then
        echo ""
        echo "相册中的资源 ($asset_count 个)："
        echo ""
        echo "$album_json" | jq -r '.assets[] |
            "  - \(.originalFileName // .id) (\(.type))"'
    fi
}

# 格式化单个资源详情
# 参数: asset_json
format_asset_detail() {
    local asset_json="$1"

    if [[ -z "$asset_json" ]]; then
        echo "没有资源信息"
        return 0
    fi

    echo "资源详情："
    echo ""
    echo "$asset_json" | jq -r '
        "ID: \(.id)\n" +
        "类型: \(.type)\n" +
        "文件名: \(.originalFileName // "未知")\n" +
        "原始路径: \(.originalPath)\n" +
        "文件大小: \((.exifInfo.fileSizeInByte // 0) / 1024 / 1024 | floor)MB\n" +
        "拍摄时间: \(.fileCreatedAt // "未知")\n" +
        "上传时间: \(.createdAt)\n" +
        if .isFavorite then "★ 已收藏\n" else "" end +
        if .isArchived then "已归档\n" else "" end +
        "\n=== EXIF 信息 ===\n" +
        if .exifInfo.make then "相机品牌: \(.exifInfo.make)\n" else "" end +
        if .exifInfo.model then "相机型号: \(.exifInfo.model)\n" else "" end +
        if .exifInfo.exifImageWidth then "尺寸: \(.exifInfo.exifImageWidth)x\(.exifInfo.exifImageHeight)\n" else "" end +
        if .exifInfo.fNumber then "光圈: f/\(.exifInfo.fNumber)\n" else "" end +
        if .exifInfo.exposureTime then "快门: \(.exifInfo.exposureTime)s\n" else "" end +
        if .exifInfo.iso then "ISO: \(.exifInfo.iso)\n" else "" end +
        if .exifInfo.focalLength then "焦距: \(.exifInfo.focalLength)mm\n" else "" end +
        if .exifInfo.lensModel then "镜头: \(.exifInfo.lensModel)\n" else "" end +
        "\n=== 位置信息 ===\n" +
        if .exifInfo.city then "城市: \(.exifInfo.city)\n" else "" end +
        if .exifInfo.state then "省/州: \(.exifInfo.state)\n" else "" end +
        if .exifInfo.country then "国家: \(.exifInfo.country)\n" else "" end +
        if .exifInfo.latitude then "坐标: \(.exifInfo.latitude), \(.exifInfo.longitude)\n" else "" end'
}

# ============================================================================
# 数据构建
# ============================================================================

# 构建日期范围过滤器
# 参数: start_date end_date
# 日期格式: YYYY-MM-DD 或 ISO 8601
build_date_filter() {
    local start_date="$1"
    local end_date="$2"
    local filter="{}"

    # 转换日期为 ISO 8601 格式（如果需要）
    if [[ -n "$start_date" ]]; then
        # 检查是否已经是 ISO 8601 格式
        if [[ ! "$start_date" =~ T.*Z$ ]]; then
            start_date="${start_date}T00:00:00.000Z"
        fi
        filter=$(echo "$filter" | jq --arg date "$start_date" '. + {takenAfter: $date}')
    fi

    if [[ -n "$end_date" ]]; then
        # 检查是否已经是 ISO 8601 格式
        if [[ ! "$end_date" =~ T.*Z$ ]]; then
            end_date="${end_date}T23:59:59.999Z"
        fi
        filter=$(echo "$filter" | jq --arg date "$end_date" '. + {takenBefore: $date}')
    fi

    echo "$filter"
}

# 构建搜索查询
# 参数: 键值对 (key1 value1 key2 value2 ...)
build_search_query() {
    local query="{}"

    while [[ $# -gt 0 ]]; do
        local key="$1"
        local value="$2"
        shift 2

        if [[ -n "$key" && -n "$value" ]]; then
            # 根据值类型决定如何添加
            if [[ "$value" =~ ^[0-9]+$ ]]; then
                # 数字
                query=$(echo "$query" | jq --arg k "$key" --argjson v "$value" '. + {($k): $v}')
            elif [[ "$value" == "true" || "$value" == "false" ]]; then
                # 布尔值
                query=$(echo "$query" | jq --arg k "$key" --argjson v "$value" '. + {($k): $v}')
            else
                # 字符串
                query=$(echo "$query" | jq --arg k "$key" --arg v "$value" '. + {($k): $v}')
            fi
        fi
    done

    echo "$query"
}

# ============================================================================
# 颜色输出（可选）
# ============================================================================

# 定义颜色代码
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_MAGENTA='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_NC='\033[0m' # No Color

# 打印彩色消息
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${COLOR_NC}"
}

print_success() {
    print_color "$COLOR_GREEN" "✓ $1"
}

print_error() {
    print_color "$COLOR_RED" "✗ $1" >&2
}

print_info() {
    print_color "$COLOR_BLUE" "ℹ $1"
}

print_warning() {
    print_color "$COLOR_YELLOW" "⚠ $1"
}

# ============================================================================
# 文件处理
# ============================================================================

# 获取文件的 MIME 类型
get_mime_type() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        echo "application/octet-stream"
        return 0
    fi

    # 使用 file 命令获取 MIME 类型
    if command -v file &> /dev/null; then
        file --mime-type -b "$file_path"
    else
        # 根据文件扩展名猜测
        local ext="${file_path##*.}"
        case "${ext,,}" in
            jpg|jpeg) echo "image/jpeg" ;;
            png) echo "image/png" ;;
            gif) echo "image/gif" ;;
            webp) echo "image/webp" ;;
            heic) echo "image/heic" ;;
            mp4) echo "video/mp4" ;;
            mov) echo "video/quicktime" ;;
            avi) echo "video/x-msvideo" ;;
            *) echo "application/octet-stream" ;;
        esac
    fi
}

# 人类可读的文件大小
human_readable_size() {
    local bytes="$1"

    if [[ "$bytes" -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ "$bytes" -lt 1048576 ]]; then
        echo "$((bytes / 1024))KB"
    elif [[ "$bytes" -lt 1073741824 ]]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# ============================================================================
# 批量操作辅助
# ============================================================================

# 进度条
show_progress() {
    local current="$1"
    local total="$2"
    local width=50

    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "\r["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "] %d%% (%d/%d)" "$percent" "$current" "$total"

    if [[ "$current" -eq "$total" ]]; then
        echo ""
    fi
}

# 批量操作包装器
batch_operation() {
    local operation="$1"
    shift
    local items=("$@")
    local total=${#items[@]}
    local success=0
    local failed=0

    echo "开始批量操作，共 $total 项..."
    echo ""

    for i in "${!items[@]}"; do
        local item="${items[$i]}"
        local index=$((i + 1))

        if $operation "$item"; then
            ((success++))
        else
            ((failed++))
        fi

        show_progress "$index" "$total"
    done

    echo ""
    echo "完成: 成功 $success 项，失败 $failed 项"
    return $failed
}

# ============================================================================
# 输出重定向（用于调试）
# ============================================================================

# 调试输出
debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# 详细输出
verbose() {
    if [[ "${VERBOSE:-0}" == "1" ]]; then
        echo "[VERBOSE] $*" >&2
    fi
}
