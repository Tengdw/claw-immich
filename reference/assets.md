# 资源管理 API

本文档详细介绍 Immich 资源（照片和视频）管理相关的所有 API 端点。

## 概述

资源（Asset）是 Immich 中照片和视频的统称。每个资源包含文件数据、EXIF 元数据、缩略图等信息。

**基础 URL**: `{server_url}/api/assets`

## API 端点

### 上传资源

```
POST /api/assets
Content-Type: multipart/form-data
```

**所需权限**: `asset.upload`

**表单字段**:
- `deviceAssetId` (string, 必需): 设备上的资源 ID（唯一标识）
- `deviceId` (string, 必需): 设备 ID
- `fileCreatedAt` (string, 必需): 文件创建时间（ISO 8601 格式）
- `fileModifiedAt` (string, 必需): 文件修改时间（ISO 8601 格式）
- `assetData` (file, 必需): 文件数据
- `isFavorite` (boolean, 可选): 是否收藏
- `isArchived` (boolean, 可选): 是否归档

**响应**: 返回上传的资源对象，包含 `id` 字段。

**Shell 函数**:
```bash
upload_asset "/path/to/photo.jpg" ["device_id"]
```

**示例**:
```bash
# 上传单个文件
result=$(upload_asset "/Users/me/Photos/IMG_0001.jpg")
asset_id=$(echo "$result" | jq -r '.id')
echo "上传成功，资源 ID: $asset_id"

# 批量上传目录中的所有照片
for photo in ~/Photos/Japan2024/*.jpg; do
    echo "上传: $photo"
    upload_asset "$photo"
done
```

---

### 获取资源信息

```
GET /api/assets/{id}
```

**所需权限**: `asset.read`

**URL 参数**:
- `id`: 资源 ID

**响应**: 返回资源详细信息，包含 EXIF 数据。

```json
{
  "id": "asset-uuid",
  "type": "IMAGE",
  "originalPath": "/path/to/file.jpg",
  "originalFileName": "IMG_0001.jpg",
  "fileCreatedAt": "2024-01-01T12:00:00.000Z",
  "fileModifiedAt": "2024-01-01T12:00:00.000Z",
  "isFavorite": false,
  "isArchived": false,
  "duration": "0:00:00.000000",
  "exifInfo": {
    "make": "Canon",
    "model": "EOS R5",
    "exposureTime": "1/500",
    "fNumber": 2.8,
    "iso": 100,
    "focalLength": 50,
    "latitude": 35.6762,
    "longitude": 139.6503,
    "city": "Tokyo",
    "state": "Tokyo",
    "country": "Japan"
  },
  "tags": []
}
```

**Shell 函数**:
```bash
get_asset "asset_id"
```

---

### 更新资源信息

```
PATCH /api/assets/{id}
```

**所需权限**: `asset.write`

**URL 参数**:
- `id`: 资源 ID

**请求体**:
```json
{
  "isFavorite": true,
  "isArchived": false,
  "description": "新描述",
  "dateTimeOriginal": "2024-01-01T12:00:00.000Z"
}
```

**Shell 函数**:
```bash
update_asset "asset_id" '{"isFavorite": true, "description": "美丽的日落"}'
```

**示例**:
```bash
# 标记为收藏
update_asset "$asset_id" '{"isFavorite": true}'

# 归档旧照片
update_asset "$asset_id" '{"isArchived": true}'

# 批量设置描述
for id in "${asset_ids[@]}"; do
    update_asset "$id" '{"description": "2024春节聚会"}'
done
```

---

### 删除资源

```
DELETE /api/assets/{id}
```

**所需权限**: `asset.delete`

**URL 参数**:
- `id`: 资源 ID

**注意**: 此操作会永久删除资源文件，无法恢复。

**Shell 函数**:
```bash
delete_asset "asset_id"
```

**示例**:
```bash
# 删除前确认
asset=$(get_asset "$asset_id")
filename=$(echo "$asset" | jq -r '.originalFileName')
echo "确定要删除 $filename 吗？"
read -p "(y/N) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    delete_asset "$asset_id"
    echo "已删除"
fi
```

---

### 下载资源原图

```
GET /api/assets/{id}/original
```

**所需权限**: `asset.read`

**URL 参数**:
- `id`: 资源 ID

**响应**: 返回文件二进制数据。

**Shell 函数**:
```bash
download_asset "asset_id" "/path/to/save/file.jpg"
```

**示例**:
```bash
# 下载单个资源
download_asset "$asset_id" "~/Downloads/photo.jpg"

# 批量下载相册中的所有照片
album=$(get_album "$album_id")
echo "$album" | jq -r '.assets[] | .id' | while read asset_id; do
    filename=$(get_asset "$asset_id" | jq -r '.originalFileName')
    download_asset "$asset_id" "~/Downloads/$filename"
done
```

---

### 获取资源缩略图

```
GET /api/assets/{id}/thumbnail
```

**所需权限**: `asset.read`

**URL 参数**:
- `id`: 资源 ID

**查询参数**:
- `size`: 缩略图尺寸（`preview` 或 `thumbnail`）

**响应**: 返回缩略图二进制数据。

---

## 使用场景

### 场景 1: 智能导入照片

```bash
#!/bin/bash
source ~/.claude/skills/claw-immich/scripts/immich-api.sh

PHOTO_DIR="$HOME/Pictures/Import"
LOG_FILE="$HOME/immich_upload.log"

# 上传目录中的所有照片
for file in "$PHOTO_DIR"/*.{jpg,jpeg,png,heic,mp4,mov}; do
    # 检查文件是否存在
    [[ -f "$file" ]] || continue

    echo "$(date): 上传 $file" >> "$LOG_FILE"

    # 上传文件
    result=$(upload_asset "$file" 2>&1)
    if [[ $? -eq 0 ]]; then
        asset_id=$(echo "$result" | jq -r '.id')
        echo "  成功: $asset_id" >> "$LOG_FILE"

        # 上传成功后移动到已处理目录
        mkdir -p "$PHOTO_DIR/processed"
        mv "$file" "$PHOTO_DIR/processed/"
    else
        echo "  失败: $result" >> "$LOG_FILE"
    fi
done
```

### 场景 2: 批量添加标签

```bash
# 查找海滩照片并添加标签
beach_photos=$(search_assets '{
  "query": "beach",
  "type": "IMAGE"
}')

# 创建"海滩"标签
tag=$(create_tag "海滩" "#00BFFF")
tag_id=$(echo "$tag" | jq -r '.id')

# 为所有海滩照片添加标签
asset_ids=($(echo "$beach_photos" | jq -r '.assets.items[] | .id'))
tag_assets "$tag_id" "${asset_ids[@]}"
```

### 场景 3: 备份收藏的照片

```bash
# 搜索所有收藏的照片
favorites=$(search_assets '{"isFavorite": true}')

# 下载到本地
mkdir -p ~/Backups/Favorites
echo "$favorites" | jq -r '.assets.items[] | .id' | while read asset_id; do
    asset=$(get_asset "$asset_id")
    filename=$(echo "$asset" | jq -r '.originalFileName')

    echo "下载: $filename"
    download_asset "$asset_id" "~/Backups/Favorites/$filename"
done
```

### 场景 4: 清理重复照片

```bash
# 这个示例需要额外的去重逻辑
# 可以基于文件哈希或 EXIF 时间戳

# 获取所有照片
all_photos=$(search_assets '{"type": "IMAGE"}')

# 按文件修改时间分组
echo "$all_photos" | jq -r '.assets.items[] | "\(.fileModifiedAt)|\(.id)|\(.originalFileName)"' | \
    sort | \
    awk -F'|' '{
        if ($1 == prev_time) {
            print "可能重复: " $3 " (ID: " $2 ")"
        }
        prev_time = $1
    }'
```

## 最佳实践

### 上传

1. **保持原始文件名**: 有助于日后识别和管理
2. **正确的时间戳**: 使用文件的实际拍摄/创建时间
3. **批量操作**: 使用循环批量上传，添加错误处理和日志
4. **检查重复**: 上传前可以通过 `deviceAssetId` 检查是否已存在

### 管理

1. **使用收藏**: 标记重要照片便于快速访问
2. **归档功能**: 归档不常用但需保留的照片
3. **定期整理**: 定期检查和清理不需要的照片
4. **善用标签**: 使用标签系统组织照片

### 下载备份

1. **定期备份**: 定期下载重要照片到本地
2. **保持结构**: 下载时保持合理的目录结构
3. **验证完整性**: 下载后验证文件完整性

## 注意事项

- 上传大文件时可能需要较长时间，建议添加超时处理
- 删除操作不可逆，删除前务必确认
- 修改 EXIF 数据时要格外小心，可能影响照片的排序和组织
- 批量操作时建议添加延迟，避免服务器压力过大

## 相关文档

- [搜索功能 API](./search.md) - 查找和过滤资源
- [标签管理 API](./tags.md) - 为资源添加标签
- [相册管理 API](./albums.md) - 将资源组织到相册
- [共享链接 API](./shared-links.md) - 分享资源
