# 共享链接 API

本文档详细介绍 Immich 共享链接相关的所有 API 端点。

## 概述

共享链接允许你与他人分享照片和相册，无需对方拥有 Immich 账户。支持设置过期时间、访问密码、下载权限等。

**基础 URL**: `{server_url}/api/shared-links`

## API 端点

### 获取所有共享链接

```
GET /api/shared-links
```

**所需权限**: 需要认证

**响应示例**:
```json
[
  {
    "id": "link-uuid",
    "type": "ALBUM",
    "description": "分享的相册",
    "key": "shared-key-string",
    "expiresAt": "2024-12-31T23:59:59.999Z",
    "allowDownload": true,
    "showMetadata": true,
    "album": {
      "id": "album-uuid",
      "albumName": "家庭照片"
    },
    "assets": [],
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
]
```

**Shell 函数**:
```bash
get_all_shared_links
```

---

### 创建共享链接

```
POST /api/shared-links
```

**所需权限**: 需要认证

**请求体（相册类型）**:
```json
{
  "type": "ALBUM",
  "albumId": "album-uuid",
  "description": "描述",
  "expiresAt": "2024-12-31T23:59:59.999Z",
  "allowDownload": true,
  "showMetadata": true,
  "password": "可选密码"
}
```

**请求体（资源类型）**:
```json
{
  "type": "INDIVIDUAL",
  "assetIds": ["asset-id-1", "asset-id-2"],
  "description": "描述",
  "expiresAt": "2024-12-31T23:59:59.999Z",
  "allowDownload": true,
  "showMetadata": true,
  "password": "可选密码"
}
```

**参数说明**:
- `type` (string, 必需): 链接类型，`ALBUM` 或 `INDIVIDUAL`
- `albumId` (string): 相册 ID（type=ALBUM 时必需）
- `assetIds` (array): 资源 ID 数组（type=INDIVIDUAL 时必需）
- `description` (string, 可选): 描述信息
- `expiresAt` (string, 可选): 过期时间（ISO 8601 格式）
- `allowDownload` (boolean, 可选): 允许下载，默认 true
- `showMetadata` (boolean, 可选): 显示元数据，默认 true
- `password` (string, 可选): 访问密码

**响应**: 返回创建的共享链接对象，包含 `key` 字段（访问密钥）。

**Shell 函数**:
```bash
# 高级方式
create_shared_link '{"type": "ALBUM", "albumId": "...", ...}'

# 简单方式
create_simple_shared_link "album|assets" "id" ["描述"] ["过期时间"] ["允许下载"] ["显示元数据"]
```

**示例**:

```bash
# 分享相册（简单方式）
link=$(create_simple_shared_link "album" "$album_id" "家庭相册分享")
link_key=$(echo "$link" | jq -r '.key')
echo "分享链接: $IMMICH_SERVER_URL/share/$link_key"

# 分享资源（高级方式，带密码和过期时间）
expires=$(date -u -v+7d +"%Y-%m-%dT%H:%M:%S.000Z")
data='{
  "type": "INDIVIDUAL",
  "assetIds": ["asset-1", "asset-2"],
  "description": "精选照片",
  "expiresAt": "'$expires'",
  "allowDownload": true,
  "password": "secret123"
}'
link=$(create_shared_link "$data")
```

---

### 获取当前共享链接

```
GET /api/shared-links/me
```

**所需权限**: 需要认证

**查询参数**:
- `key`: 共享密钥

**用途**: 通过 key 获取共享链接信息（通常用于访客访问）。

**Shell 函数**:
```bash
get_my_shared_link
```

---

### 获取指定共享链接

```
GET /api/shared-links/{id}
```

**所需权限**: 需要认证

**URL 参数**:
- `id`: 共享链接 ID

**响应**: 返回共享链接详情。

**Shell 函数**:
```bash
get_shared_link_by_id "link_id"
```

---

### 更新共享链接

```
PATCH /api/shared-links/{id}
```

**所需权限**: 需要认证

**URL 参数**:
- `id`: 共享链接 ID

**请求体**:
```json
{
  "description": "新描述",
  "expiresAt": "2024-12-31T23:59:59.999Z",
  "allowDownload": false,
  "showMetadata": false,
  "password": "新密码"
}
```

**Shell 函数**:
```bash
update_shared_link "link_id" '{"description": "新描述", ...}'
```

**示例**:
```bash
# 延长过期时间
new_expires=$(date -u -v+30d +"%Y-%m-%dT%H:%M:%S.000Z")
update_shared_link "$link_id" "{\"expiresAt\": \"$new_expires\"}"

# 禁止下载
update_shared_link "$link_id" '{"allowDownload": false}'

# 设置密码
update_shared_link "$link_id" '{"password": "newpass123"}'
```

---

### 删除共享链接

```
DELETE /api/shared-links/{id}
```

**所需权限**: 需要认证

**URL 参数**:
- `id`: 共享链接 ID

**Shell 函数**:
```bash
remove_shared_link "link_id"
```

---

### 添加资源到共享链接

```
PUT /api/shared-links/{id}/assets
```

**所需权限**: 需要认证

**URL 参数**:
- `id`: 共享链接 ID

**请求体**:
```json
{
  "assetIds": ["asset-id-1", "asset-id-2"]
}
```

**注意**: 仅适用于 `INDIVIDUAL` 类型的共享链接。

**Shell 函数**:
```bash
add_shared_link_assets "link_id" "asset_id_1" "asset_id_2"
```

---

### 从共享链接移除资源

```
DELETE /api/shared-links/{id}/assets
```

**所需权限**: 需要认证

**URL 参数**:
- `id`: 共享链接 ID

**请求体**:
```json
{
  "assetIds": ["asset-id-1", "asset-id-2"]
}
```

**Shell 函数**:
```bash
remove_shared_link_assets "link_id" "asset_id_1" "asset_id_2"
```

---

## 使用场景

### 场景 1: 分享旅行相册

```bash
#!/bin/bash
source ~/.claude/skills/claw-immich/scripts/immich-api.sh

# 创建旅行相册
album=$(create_album "2024 日本之旅" "东京、京都、大阪")
album_id=$(echo "$album" | jq -r '.id')

# 搜索旅行照片并添加到相册
japan_photos=$(search_assets '{
  "takenAfter": "2024-06-01T00:00:00.000Z",
  "takenBefore": "2024-06-15T23:59:59.999Z",
  "city": "Tokyo"
}')

asset_ids=($(echo "$japan_photos" | jq -r '.assets.items[] | .id'))
add_assets_to_album "$album_id" "${asset_ids[@]}"

# 创建共享链接（30 天有效期）
expires=$(date -u -v+30d +"%Y-%m-%dT%H:%M:%S.000Z")
link=$(create_simple_shared_link "album" "$album_id" "日本之旅照片分享" "$expires")
link_key=$(echo "$link" | jq -r '.key')

echo "========================================="
echo "分享链接已创建"
echo "URL: $IMMICH_SERVER_URL/share/$link_key"
echo "有效期至: $expires"
echo "========================================="
```

### 场景 2: 分享精选照片（带密码）

```bash
# 搜索最佳照片
best_photos=$(search_assets '{"isFavorite": true}' | \
    jq '.assets.items | sort_by(.exifInfo.rating) | reverse | .[0:10]')

asset_ids=($(echo "$best_photos" | jq -r '.[].id'))

# 创建带密码的分享
expires=$(date -u -v+7d +"%Y-%m-%dT%H:%M:%S.000Z")
data=$(jq -n \
    --argjson aids "$(printf '%s\n' "${asset_ids[@]}" | jq -R . | jq -s .)" \
    --arg exp "$expires" \
    '{
        type: "INDIVIDUAL",
        assetIds: $aids,
        description: "精选摄影作品",
        expiresAt: $exp,
        allowDownload: false,
        showMetadata: true,
        password: "photo2024"
    }')

link=$(create_shared_link "$data")
link_key=$(echo "$link" | jq -r '.key')

echo "分享链接: $IMMICH_SERVER_URL/share/$link_key"
echo "访问密码: photo2024"
echo "注意: 已禁止下载原图"
```

### 场景 3: 临时分享（24小时有效）

```bash
# 创建临时分享链接
create_temp_share() {
    local asset_ids=("$@")

    # 24 小时后过期
    local expires=$(date -u -v+1d +"%Y-%m-%dT%H:%M:%S.000Z")

    local link=$(create_simple_shared_link "assets" "${asset_ids[0]}" \
        "临时分享 - 24小时有效" "$expires" "true" "false")

    local link_key=$(echo "$link" | jq -r '.key')
    local link_id=$(echo "$link" | jq -r '.id')

    # 如果有多个资源，添加剩余资源
    if [[ ${#asset_ids[@]} -gt 1 ]]; then
        add_shared_link_assets "$link_id" "${asset_ids[@]:1}"
    fi

    echo "$IMMICH_SERVER_URL/share/$link_key"
}

# 使用示例
asset_ids=("asset-1" "asset-2" "asset-3")
temp_url=$(create_temp_share "${asset_ids[@]}")
echo "临时链接: $temp_url（24小时后失效）"
```

### 场景 4: 管理过期链接

```bash
#!/bin/bash
# 查找和清理过期的共享链接

all_links=$(get_all_shared_links)
current_time=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

echo "检查过期链接..."
echo "$all_links" | jq -c '.[]' | while read link; do
    link_id=$(echo "$link" | jq -r '.id')
    description=$(echo "$link" | jq -r '.description // "无描述"')
    expires_at=$(echo "$link" | jq -r '.expiresAt // empty')

    if [[ -n "$expires_at" && "$expires_at" < "$current_time" ]]; then
        echo "过期链接: $description (过期于 $expires_at)"

        read -p "删除此链接？(y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            remove_shared_link "$link_id"
            echo "  已删除"
        fi
    fi
done
```

### 场景 5: 批量创建事件分享

```bash
#!/bin/bash
# 为每个事件创建独立的分享链接

create_event_shares() {
    # 定义事件列表
    events=(
        "2024-01-15:春节聚会"
        "2024-04-05:清明踏青"
        "2024-06-01:儿童节活动"
        "2024-09-15:中秋团圆"
    )

    for event in "${events[@]}"; do
        IFS=':' read -r date name <<< "$event"

        # 搜索该日期的照片
        photos=$(search_assets "{
            \"takenAfter\": \"${date}T00:00:00.000Z\",
            \"takenBefore\": \"${date}T23:59:59.999Z\",
            \"type\": \"IMAGE\"
        }")

        asset_count=$(echo "$photos" | jq '.assets.items | length')

        if [[ $asset_count -gt 0 ]]; then
            # 创建相册
            album=$(create_album "$name" "拍摄于 $date")
            album_id=$(echo "$album" | jq -r '.id')

            # 添加照片到相册
            asset_ids=($(echo "$photos" | jq -r '.assets.items[] | .id'))
            add_assets_to_album "$album_id" "${asset_ids[@]}"

            # 创建分享链接
            link=$(create_simple_shared_link "album" "$album_id" "$name 照片分享")
            link_key=$(echo "$link" | jq -r '.key')

            echo "$name: $IMMICH_SERVER_URL/share/$link_key ($asset_count 张照片)"
        else
            echo "$name: 没有找到照片"
        fi
    done
}

create_event_shares
```

### 场景 6: 分享链接统计

```bash
# 生成分享链接报告
echo "共享链接统计报告"
echo "=================="
echo ""

all_links=$(get_all_shared_links)
total_count=$(echo "$all_links" | jq '. | length')

echo "总共享链接数: $total_count"
echo ""

# 按类型统计
album_count=$(echo "$all_links" | jq '[.[] | select(.type == "ALBUM")] | length')
asset_count=$(echo "$all_links" | jq '[.[] | select(.type == "INDIVIDUAL")] | length')

echo "相册分享: $album_count"
echo "资源分享: $asset_count"
echo ""

# 列出所有链接
echo "链接列表:"
echo "$all_links" | jq -r '.[] |
    "  - \(.description // "无描述") [\(.type)]" +
    if .expiresAt then " (过期: \(.expiresAt))" else " (永久)" end'
```

## 分享策略

### 安全分享

1. **设置过期时间**: 避免永久链接，建议 7-30 天
2. **使用密码**: 对敏感内容添加密码保护
3. **禁止下载**: 只允许在线查看，不允许下载
4. **隐藏元数据**: 保护位置等隐私信息

```bash
# 安全分享示例
create_secure_share() {
    local album_id="$1"
    local expires=$(date -u -v+7d +"%Y-%m-%dT%H:%M:%S.000Z")

    local data='{
        "type": "ALBUM",
        "albumId": "'$album_id'",
        "description": "私密分享",
        "expiresAt": "'$expires'",
        "allowDownload": false,
        "showMetadata": false,
        "password": "secure'$(date +%s)'"
    }'

    create_shared_link "$data"
}
```

### 公开分享

适用于非敏感内容的广泛分享：

```bash
# 公开分享示例
create_public_share() {
    local album_id="$1"

    local data='{
        "type": "ALBUM",
        "albumId": "'$album_id'",
        "description": "公开相册",
        "allowDownload": true,
        "showMetadata": true
    }'

    create_shared_link "$data"
}
```

## 最佳实践

1. **清晰的描述**: 为分享链接添加清晰的描述信息
2. **合理的有效期**: 根据分享目的设置合适的有效期
3. **定期清理**: 删除过期和不再需要的分享链接
4. **权限控制**: 根据分享对象设置合适的下载和元数据权限
5. **密码保护**: 对私密内容使用密码保护
6. **监控使用**: 定期检查分享链接的使用情况

## 注意事项

- 共享链接的 key 是访问凭证，请妥善保管
- 删除共享链接不会删除原始资源或相册
- `ALBUM` 类型的链接会随相册内容自动更新
- `INDIVIDUAL` 类型的链接需要手动管理资源列表
- 设置密码后，无法通过 API 查看密码内容
- 过期的链接会自动失效，但不会自动删除

## 相关文档

- [相册管理 API](./albums.md) - 创建和管理相册
- [资源管理 API](./assets.md) - 管理要分享的资源
- [搜索功能 API](./search.md) - 查找要分享的内容
