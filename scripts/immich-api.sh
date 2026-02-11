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
# 共享链接操作
# ============================================================================

# 获取所有共享链接
# GET /api/shared-links
get_all_shared_links() {
    immich_api_request "GET" "/api/shared-links"
}

# 创建共享链接
# POST /api/shared-links
# 参数: json_data
create_shared_link() {
    local json_data="$1"

    if [[ -z "$json_data" ]]; then
        echo "错误: 共享链接数据不能为空" >&2
        return 1
    fi

    immich_api_request "POST" "/api/shared-links" "$json_data"
}

# 创建简单共享链接（便捷函数）
# 参数: type (album|assets) id [description] [expires_at] [allow_download] [show_metadata]
create_simple_shared_link() {
    local type="$1"
    local id="$2"
    local description="${3:-}"
    local expires_at="${4:-}"
    local allow_download="${5:-true}"
    local show_metadata="${6:-true}"

    if [[ -z "$type" ]] || [[ -z "$id" ]]; then
        echo "错误: 类型和 ID 不能为空" >&2
        return 1
    fi

    local data
    if [[ "$type" == "album" ]]; then
        data=$(jq -n \
            --arg aid "$id" \
            --arg desc "$description" \
            --arg exp "$expires_at" \
            --argjson dl "$allow_download" \
            --argjson meta "$show_metadata" \
            '{type: "ALBUM", albumId: $aid, description: $desc, expiresAt: $exp, allowDownload: $dl, showMetadata: $meta} | with_entries(select(.value != ""))')
    else
        # assets type
        local asset_ids_json=$(echo "$id" | jq -R . | jq -s .)
        data=$(jq -n \
            --argjson aids "$asset_ids_json" \
            --arg desc "$description" \
            --arg exp "$expires_at" \
            --argjson dl "$allow_download" \
            --argjson meta "$show_metadata" \
            '{type: "INDIVIDUAL", assetIds: $aids, description: $desc, expiresAt: $exp, allowDownload: $dl, showMetadata: $meta} | with_entries(select(.value != ""))')
    fi

    immich_api_request "POST" "/api/shared-links" "$data"
}

# 获取当前共享链接
# GET /api/shared-links/me
get_my_shared_link() {
    immich_api_request "GET" "/api/shared-links/me"
}

# 获取指定共享链接
# GET /api/shared-links/{id}
# 参数: link_id
get_shared_link_by_id() {
    local link_id="$1"

    if [[ -z "$link_id" ]]; then
        echo "错误: 共享链接 ID 不能为空" >&2
        return 1
    fi

    immich_api_request "GET" "/api/shared-links/$link_id"
}

# 更新共享链接
# PATCH /api/shared-links/{id}
# 参数: link_id json_data
update_shared_link() {
    local link_id="$1"
    local json_data="$2"

    if [[ -z "$link_id" ]]; then
        echo "错误: 共享链接 ID 不能为空" >&2
        return 1
    fi

    if [[ -z "$json_data" ]]; then
        echo "错误: 更新数据不能为空" >&2
        return 1
    fi

    immich_api_request "PATCH" "/api/shared-links/$link_id" "$json_data"
}

# 删除共享链接
# DELETE /api/shared-links/{id}
# 参数: link_id
remove_shared_link() {
    local link_id="$1"

    if [[ -z "$link_id" ]]; then
        echo "错误: 共享链接 ID 不能为空" >&2
        return 1
    fi

    immich_api_request "DELETE" "/api/shared-links/$link_id"
}

# 添加资源到共享链接
# PUT /api/shared-links/{id}/assets
# 参数: link_id asset_id1 [asset_id2 ...]
add_shared_link_assets() {
    local link_id="$1"
    shift

    if [[ -z "$link_id" ]]; then
        echo "错误: 共享链接 ID 不能为空" >&2
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        echo "错误: 至少需要一个资源 ID" >&2
        return 1
    fi

    # 构建资源 ID 数组
    local asset_ids_json=$(printf '%s\n' "$@" | jq -R . | jq -s .)
    local data=$(jq -n --argjson ids "$asset_ids_json" '{assetIds: $ids}')

    immich_api_request "PUT" "/api/shared-links/$link_id/assets" "$data"
}

# 从共享链接移除资源
# DELETE /api/shared-links/{id}/assets
# 参数: link_id asset_id1 [asset_id2 ...]
remove_shared_link_assets() {
    local link_id="$1"
    shift

    if [[ -z "$link_id" ]]; then
        echo "错误: 共享链接 ID 不能为空" >&2
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        echo "错误: 至少需要一个资源 ID" >&2
        return 1
    fi

    # 构建资源 ID 数组
    local asset_ids_json=$(printf '%s\n' "$@" | jq -R . | jq -s .)
    local data=$(jq -n --argjson ids "$asset_ids_json" '{assetIds: $ids}')

    immich_api_request "DELETE" "/api/shared-links/$link_id/assets" "$data"
}

# ============================================================================
# 标签操作
# ============================================================================

# 获取所有标签
# GET /api/tags
get_all_tags() {
    immich_api_request "GET" "/api/tags"
}

# 创建新标签
# POST /api/tags
# 参数: tag_name [color]
create_tag() {
    local tag_name="$1"
    local color="${2:-}"

    if [[ -z "$tag_name" ]]; then
        echo "错误: 标签名称不能为空" >&2
        return 1
    fi

    local data
    if [[ -n "$color" ]]; then
        data=$(jq -n \
            --arg name "$tag_name" \
            --arg c "$color" \
            '{name: $name, color: $c}')
    else
        data=$(jq -n \
            --arg name "$tag_name" \
            '{name: $name}')
    fi

    immich_api_request "POST" "/api/tags" "$data"
}

# 批量创建或更新标签
# PUT /api/tags
# 参数: json_data (包含标签数组的 JSON)
upsert_tags() {
    local json_data="$1"

    if [[ -z "$json_data" ]]; then
        echo "错误: 标签数据不能为空" >&2
        return 1
    fi

    immich_api_request "PUT" "/api/tags" "$json_data"
}

# 获取指定标签
# GET /api/tags/{id}
# 参数: tag_id
get_tag_by_id() {
    local tag_id="$1"

    if [[ -z "$tag_id" ]]; then
        echo "错误: 标签 ID 不能为空" >&2
        return 1
    fi

    immich_api_request "GET" "/api/tags/$tag_id"
}

# 更新标签
# PUT /api/tags/{id}
# 参数: tag_id json_data
update_tag() {
    local tag_id="$1"
    local json_data="$2"

    if [[ -z "$tag_id" ]]; then
        echo "错误: 标签 ID 不能为空" >&2
        return 1
    fi

    if [[ -z "$json_data" ]]; then
        echo "错误: 更新数据不能为空" >&2
        return 1
    fi

    immich_api_request "PUT" "/api/tags/$tag_id" "$json_data"
}

# 删除标签
# DELETE /api/tags/{id}
# 参数: tag_id
delete_tag() {
    local tag_id="$1"

    if [[ -z "$tag_id" ]]; then
        echo "错误: 标签 ID 不能为空" >&2
        return 1
    fi

    immich_api_request "DELETE" "/api/tags/$tag_id"
}

# 为资源添加标签
# PUT /api/tags/{id}/assets
# 参数: tag_id asset_id1 [asset_id2 ...]
tag_assets() {
    local tag_id="$1"
    shift

    if [[ -z "$tag_id" ]]; then
        echo "错误: 标签 ID 不能为空" >&2
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        echo "错误: 至少需要一个资源 ID" >&2
        return 1
    fi

    # 构建资源 ID 数组
    local asset_ids_json=$(printf '%s\n' "$@" | jq -R . | jq -s .)
    local data=$(jq -n --argjson ids "$asset_ids_json" '{assetIds: $ids}')

    immich_api_request "PUT" "/api/tags/$tag_id/assets" "$data"
}

# 移除资源标签
# DELETE /api/tags/{id}/assets
# 参数: tag_id asset_id1 [asset_id2 ...]
untag_assets() {
    local tag_id="$1"
    shift

    if [[ -z "$tag_id" ]]; then
        echo "错误: 标签 ID 不能为空" >&2
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        echo "错误: 至少需要一个资源 ID" >&2
        return 1
    fi

    # 构建资源 ID 数组
    local asset_ids_json=$(printf '%s\n' "$@" | jq -R . | jq -s .)
    local data=$(jq -n --argjson ids "$asset_ids_json" '{assetIds: $ids}')

    immich_api_request "DELETE" "/api/tags/$tag_id/assets" "$data"
}

# 批量为资源添加标签
# PUT /api/tags/assets
# 参数: json_data (包含 assetIds 和 tagIds 的 JSON)
bulk_tag_assets() {
    local json_data="$1"

    if [[ -z "$json_data" ]]; then
        echo "错误: 标签数据不能为空" >&2
        return 1
    fi

    immich_api_request "PUT" "/api/tags/assets" "$json_data"
}

# ============================================================================
# 服务器信息
# ============================================================================

# 获取服务器信息
# GET /api/server/about
get_about_info() {
    immich_api_request "GET" "/api/server/about"
}

# 获取 APK 下载链接
# GET /api/server/apk-links
get_apk_links() {
    immich_api_request "GET" "/api/server/apk-links"
}

# 获取服务器配置
# GET /api/server/config
get_server_config() {
    immich_api_request "GET" "/api/server/config"
}

# 获取服务器功能
# GET /api/server/features
get_server_features() {
    immich_api_request "GET" "/api/server/features"
}

# 获取服务器许可证
# GET /api/server/license
get_server_license() {
    immich_api_request "GET" "/api/server/license"
}

# 设置服务器许可证
# PUT /api/server/license
# 参数: license_key activation_key
set_server_license() {
    local license_key="$1"
    local activation_key="$2"

    if [[ -z "$license_key" ]]; then
        echo "错误: 许可证密钥不能为空" >&2
        return 1
    fi

    if [[ -z "$activation_key" ]]; then
        echo "错误: 激活密钥不能为空" >&2
        return 1
    fi

    local data=$(jq -n \
        --arg lk "$license_key" \
        --arg ak "$activation_key" \
        '{licenseKey: $lk, activationKey: $ak}')

    immich_api_request "PUT" "/api/server/license" "$data"
}

# 删除服务器许可证
# DELETE /api/server/license
delete_server_license() {
    immich_api_request "DELETE" "/api/server/license"
}

# 获取支持的媒体类型
# GET /api/server/media-types
get_supported_media_types() {
    immich_api_request "GET" "/api/server/media-types"
}

# Ping 服务器
# GET /api/server/ping
ping_server() {
    immich_api_request "GET" "/api/server/ping"
}

# 获取服务器统计信息
# GET /api/server/statistics
get_server_statistics() {
    immich_api_request "GET" "/api/server/statistics"
}

# 获取存储信息
# GET /api/server/storage
get_storage() {
    immich_api_request "GET" "/api/server/storage"
}

# 获取服务器主题
# GET /api/server/theme
get_theme() {
    immich_api_request "GET" "/api/server/theme"
}

# 获取服务器版本
# GET /api/server/version
get_server_version() {
    immich_api_request "GET" "/api/server/version"
}

# 获取版本检查状态
# GET /api/server/version-check
get_version_check() {
    immich_api_request "GET" "/api/server/version-check"
}

# 获取版本历史
# GET /api/server/version-history
get_version_history() {
    immich_api_request "GET" "/api/server/version-history"
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
