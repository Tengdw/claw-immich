#!/bin/bash
# Immich API 核心封装脚本
# 提供所有 Immich API 操作的 Bash 函数

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$SKILL_DIR/config/config.json"

# 全局变量
IMMICH_SERVER_URL=""
IMMICH_API_KEY=""
IMMICH_DEVICE_ID=""

# ============================================================================
# 配置管理
# ============================================================================

# 加载配置文件
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "错误: 配置文件不存在: $CONFIG_FILE" >&2
        echo "请运行配置向导: bash $SKILL_DIR/scripts/setup.sh" >&2
        return 1
    fi

    # 检查 jq 是否安装
    if ! command -v jq &> /dev/null; then
        echo "错误: 需要安装 jq 工具" >&2
        echo "macOS: brew install jq" >&2
        echo "Linux: sudo apt-get install jq 或 sudo yum install jq" >&2
        return 1
    fi

    # 读取配置
    IMMICH_SERVER_URL=$(jq -r '.server_url' "$CONFIG_FILE")
    IMMICH_API_KEY=$(jq -r '.api_key' "$CONFIG_FILE")
    IMMICH_DEVICE_ID=$(jq -r '.default_device_id // "claude-code"' "$CONFIG_FILE")

    # 验证必需字段
    if [[ -z "$IMMICH_SERVER_URL" || "$IMMICH_SERVER_URL" == "null" ]]; then
        echo "错误: 配置文件缺少 'server_url'" >&2
        return 1
    fi

    if [[ -z "$IMMICH_API_KEY" || "$IMMICH_API_KEY" == "null" ]]; then
        echo "错误: 配置文件缺少 'api_key'" >&2
        return 1
    fi

    # 移除 server_url 末尾的斜杠
    IMMICH_SERVER_URL="${IMMICH_SERVER_URL%/}"

    return 0
}

# ============================================================================
# 通用 API 请求封装
# ============================================================================

# 通用 API 请求函数
# 参数: method endpoint [data] [content_type]
immich_api_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local content_type="${4:-application/json}"

    # 确保配置已加载
    if [[ -z "$IMMICH_SERVER_URL" || -z "$IMMICH_API_KEY" ]]; then
        load_config || return 1
    fi

    local url="${IMMICH_SERVER_URL}${endpoint}"
    local response
    local http_code
    local temp_file=$(mktemp)

    # 构建 curl 命令
    local curl_args=(
        -sL
        -w "\n%{http_code}"
        -H "x-api-key: $IMMICH_API_KEY"
        -H "Accept: application/json"
        -X "$method"
    )

    # 添加 Content-Type（如果有数据）
    if [[ -n "$data" ]]; then
        curl_args+=(-H "Content-Type: $content_type")
        curl_args+=(-d "$data")
    fi

    # 执行请求
    response=$(curl "${curl_args[@]}" "$url" 2>"$temp_file")
    local curl_exit_code=$?

    # 检查 curl 是否成功
    if [[ $curl_exit_code -ne 0 ]]; then
        echo "错误: 请求失败" >&2
        cat "$temp_file" >&2
        rm -f "$temp_file"
        return 1
    fi

    # 提取 HTTP 状态码和响应体
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')

    rm -f "$temp_file"

    # 检查 HTTP 状态码
    if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
        echo "$response"
        return 0
    else
        echo "错误: HTTP $http_code" >&2
        echo "$response" >&2
        return 1
    fi
}

# ============================================================================
# 相册操作
# ============================================================================

# 列出所有相册
# GET /api/albums
list_albums() {
    immich_api_request "GET" "/api/albums"
}

# 创建新相册
# POST /api/albums
# 参数: album_name [description]
create_album() {
    local album_name="$1"
    local description="${2:-}"

    if [[ -z "$album_name" ]]; then
        echo "错误: 相册名称不能为空" >&2
        return 1
    fi

    local data=$(jq -n \
        --arg name "$album_name" \
        --arg desc "$description" \
        '{albumName: $name, description: $desc}')

    immich_api_request "POST" "/api/albums" "$data"
}

# 获取相册详情
# GET /api/albums/{id}
# 参数: album_id
get_album() {
    local album_id="$1"

    if [[ -z "$album_id" ]]; then
        echo "错误: 相册 ID 不能为空" >&2
        return 1
    fi

    immich_api_request "GET" "/api/albums/$album_id"
}

# 更新相册信息
# PATCH /api/albums/{id}
# 参数: album_id json_data
update_album() {
    local album_id="$1"
    local json_data="$2"

    if [[ -z "$album_id" ]]; then
        echo "错误: 相册 ID 不能为空" >&2
        return 1
    fi

    if [[ -z "$json_data" ]]; then
        echo "错误: 更新数据不能为空" >&2
        return 1
    fi

    immich_api_request "PATCH" "/api/albums/$album_id" "$json_data"
}

# 删除相册
# DELETE /api/albums/{id}
# 参数: album_id
delete_album() {
    local album_id="$1"

    if [[ -z "$album_id" ]]; then
        echo "错误: 相册 ID 不能为空" >&2
        return 1
    fi

    immich_api_request "DELETE" "/api/albums/$album_id"
}

# 添加资源到相册
# PUT /api/albums/{id}/assets
# 参数: album_id asset_id1 [asset_id2 ...]
add_assets_to_album() {
    local album_id="$1"
    shift

    if [[ -z "$album_id" ]]; then
        echo "错误: 相册 ID 不能为空" >&2
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        echo "错误: 至少需要一个资源 ID" >&2
        return 1
    fi

    # 构建资源 ID 数组
    local asset_ids_json=$(printf '%s\n' "$@" | jq -R . | jq -s .)
    local data=$(jq -n --argjson ids "$asset_ids_json" '{ids: $ids}')

    immich_api_request "PUT" "/api/albums/$album_id/assets" "$data"
}

# 从相册移除资源
# DELETE /api/albums/{id}/assets
# 参数: album_id asset_id1 [asset_id2 ...]
remove_assets_from_album() {
    local album_id="$1"
    shift

    if [[ -z "$album_id" ]]; then
        echo "错误: 相册 ID 不能为空" >&2
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        echo "错误: 至少需要一个资源 ID" >&2
        return 1
    fi

    # 构建资源 ID 数组
    local asset_ids_json=$(printf '%s\n' "$@" | jq -R . | jq -s .)
    local data=$(jq -n --argjson ids "$asset_ids_json" '{ids: $ids}')

    # DELETE 请求使用请求体
    immich_api_request "DELETE" "/api/albums/$album_id/assets" "$data"
}

# ============================================================================
# 资源操作
# ============================================================================

# 搜索资源（元数据搜索）
# POST /api/search/metadata
# 参数: query_json
search_assets() {
    local query_json="$1"

    if [[ -z "$query_json" ]]; then
        echo "错误: 搜索条件不能为空" >&2
        return 1
    fi

    immich_api_request "POST" "/api/search/metadata" "$query_json"
}

# 智能搜索（CLIP）
# POST /api/search/smart
# 参数: query [limit]
smart_search() {
    local query="$1"
    local limit="${2:-20}"

    if [[ -z "$query" ]]; then
        echo "错误: 搜索查询不能为空" >&2
        return 1
    fi

    local data=$(jq -n \
        --arg q "$query" \
        --argjson l "$limit" \
        '{query: $q, limit: $l}')

    immich_api_request "POST" "/api/search/smart" "$data"
}

# 获取资源信息
# GET /api/assets/{id}
# 参数: asset_id
get_asset() {
    local asset_id="$1"

    if [[ -z "$asset_id" ]]; then
        echo "错误: 资源 ID 不能为空" >&2
        return 1
    fi

    immich_api_request "GET" "/api/assets/$asset_id"
}

# 更新资源信息
# PATCH /api/assets/{id}
# 参数: asset_id json_data
update_asset() {
    local asset_id="$1"
    local json_data="$2"

    if [[ -z "$asset_id" ]]; then
        echo "错误: 资源 ID 不能为空" >&2
        return 1
    fi

    if [[ -z "$json_data" ]]; then
        echo "错误: 更新数据不能为空" >&2
        return 1
    fi

    immich_api_request "PATCH" "/api/assets/$asset_id" "$json_data"
}

# 删除资源
# DELETE /api/assets/{id}
# 参数: asset_id
delete_asset() {
    local asset_id="$1"

    if [[ -z "$asset_id" ]]; then
        echo "错误: 资源 ID 不能为空" >&2
        return 1
    fi

    immich_api_request "DELETE" "/api/assets/$asset_id"
}

# 上传资源
# POST /api/assets
# 参数: file_path [device_id]
upload_asset() {
    local file_path="$1"
    local device_id="${2:-$IMMICH_DEVICE_ID}"

    if [[ -z "$file_path" ]]; then
        echo "错误: 文件路径不能为空" >&2
        return 1
    fi

    if [[ ! -f "$file_path" ]]; then
        echo "错误: 文件不存在: $file_path" >&2
        return 1
    fi

    # 确保配置已加载
    if [[ -z "$IMMICH_SERVER_URL" || -z "$IMMICH_API_KEY" ]]; then
        load_config || return 1
    fi

    # 获取文件信息
    local filename=$(basename "$file_path")
    local file_stat

    # macOS 和 Linux 的 stat 命令不同
    if [[ "$(uname)" == "Darwin" ]]; then
        local created_at=$(stat -f "%B" "$file_path")
        local modified_at=$(stat -f "%m" "$file_path")
    else
        local created_at=$(stat -c "%W" "$file_path")
        local modified_at=$(stat -c "%Y" "$file_path")
        # 如果创建时间不可用，使用修改时间
        if [[ "$created_at" == "0" ]]; then
            created_at="$modified_at"
        fi
    fi

    # 转换为 ISO 8601 格式
    local created_iso=$(date -u -r "$created_at" +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    local modified_iso=$(date -u -r "$modified_at" +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%S.000Z")

    # 生成设备资源 ID（使用文件名和时间戳）
    local device_asset_id="${filename}-${modified_at}"

    local url="${IMMICH_SERVER_URL}/api/assets"
    local response
    local http_code
    local temp_file=$(mktemp)

    # 执行 multipart 上传
    response=$(curl -sL \
        -w "\n%{http_code}" \
        -H "x-api-key: $IMMICH_API_KEY" \
        -H "Accept: application/json" \
        -F "deviceAssetId=$device_asset_id" \
        -F "deviceId=$device_id" \
        -F "fileCreatedAt=$created_iso" \
        -F "fileModifiedAt=$modified_iso" \
        -F "assetData=@$file_path" \
        "$url" 2>"$temp_file")

    local curl_exit_code=$?

    # 检查 curl 是否成功
    if [[ $curl_exit_code -ne 0 ]]; then
        echo "错误: 上传失败" >&2
        cat "$temp_file" >&2
        rm -f "$temp_file"
        return 1
    fi

    # 提取 HTTP 状态码和响应体
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')

    rm -f "$temp_file"

    # 检查 HTTP 状态码
    if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
        echo "$response"
        return 0
    else
        echo "错误: HTTP $http_code" >&2
        echo "$response" >&2
        return 1
    fi
}

# 下载资源原图
# GET /api/assets/{id}/original
# 参数: asset_id output_path
download_asset() {
    local asset_id="$1"
    local output_path="$2"

    if [[ -z "$asset_id" ]]; then
        echo "错误: 资源 ID 不能为空" >&2
        return 1
    fi

    if [[ -z "$output_path" ]]; then
        echo "错误: 输出路径不能为空" >&2
        return 1
    fi

    # 确保配置已加载
    if [[ -z "$IMMICH_SERVER_URL" || -z "$IMMICH_API_KEY" ]]; then
        load_config || return 1
    fi

    local url="${IMMICH_SERVER_URL}/api/assets/$asset_id/original"

    curl -sL \
        -H "x-api-key: $IMMICH_API_KEY" \
        -o "$output_path" \
        "$url"

    if [[ $? -eq 0 ]]; then
        echo "已下载到: $output_path"
        return 0
    else
        echo "错误: 下载失败" >&2
        return 1
    fi
}

# ============================================================================
# 服务器信息
# ============================================================================

# 获取服务器版本（用于测试连接）
# GET /api/server-info/version
get_server_version() {
    immich_api_request "GET" "/api/server-info/version"
}

# 测试 API 连接
test_connection() {
    echo "正在测试连接到 $IMMICH_SERVER_URL ..."

    local version=$(get_server_version 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        echo "✓ 连接成功"
        echo "服务器版本: $(echo "$version" | jq -r '.major + "." + .minor + "." + .patch')"
        return 0
    else
        echo "✗ 连接失败" >&2
        return 1
    fi
}

# ============================================================================
# 初始化
# ============================================================================

# 如果直接运行此脚本（而不是 source），加载配置
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    load_config
fi
