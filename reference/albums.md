# 相册管理 API

本文档详细介绍 Immich 相册管理相关的所有 API 端点。

## 概述

相册是 Immich 中组织照片和视频的基本方式。相册可以包含多个资源，支持共享和协作。

**基础 URL**: `{server_url}/api/albums`

## API 端点

### 列出所有相册

```
GET /api/albums
```

**所需权限**: `album.read`

**响应示例**:
```json
[
  {
    "id": "album-uuid",
    "albumName": "家庭照片",
    "description": "家庭聚会照片",
    "assetCount": 42,
    "owner": {
      "id": "user-uuid",
      "email": "user@example.com",
      "name": "用户名"
    },
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
]
```

**Shell 函数**:
```bash
list_albums
```

---

### 创建新相册

```
POST /api/albums
```

**所需权限**: `album.write`

**请求体**:
```json
{
  "albumName": "相册名称",
  "description": "相册描述（可选）"
}
```

**响应**: 返回创建的相册对象，包含 `id` 字段。

**Shell 函数**:
```bash
create_album "相册名称" "相册描述"
```

**示例**:
```bash
# 创建相册
album=$(create_album "2024 旅行" "日本之旅照片")
album_id=$(echo "$album" | jq -r '.id')
echo "相册 ID: $album_id"
```

---

### 获取相册详情

```
GET /api/albums/{id}
```

**所需权限**: `album.read`

**URL 参数**:
- `id`: 相册 ID

**响应**: 返回相册详情，包含 `assets` 数组（相册中的所有资源）。

```json
{
  "id": "album-uuid",
  "albumName": "家庭照片",
  "description": "家庭聚会照片",
  "assetCount": 42,
  "assets": [
    {
      "id": "asset-uuid",
      "type": "IMAGE",
      "originalPath": "/path/to/file.jpg",
      "fileCreatedAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "owner": {...},
  "sharedUsers": [],
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

**Shell 函数**:
```bash
get_album "album_id"
```

---

### 更新相册信息

```
PATCH /api/albums/{id}
```

**所需权限**: `album.write`

**URL 参数**:
- `id`: 相册 ID

**请求体**:
```json
{
  "albumName": "新名称（可选）",
  "description": "新描述（可选）"
}
```

**Shell 函数**:
```bash
update_album "album_id" '{"albumName": "新名称", "description": "新描述"}'
```

---

### 删除相册

```
DELETE /api/albums/{id}
```

**所需权限**: `album.write`

**URL 参数**:
- `id`: 相册 ID

**注意**: 删除相册不会删除其中的资源，只是移除相册本身。

**Shell 函数**:
```bash
delete_album "album_id"
```

---

### 添加资源到相册

```
PUT /api/albums/{id}/assets
```

**所需权限**: `album.write`

**URL 参数**:
- `id`: 相册 ID

**请求体**:
```json
{
  "ids": ["asset-id-1", "asset-id-2", "asset-id-3"]
}
```

**Shell 函数**:
```bash
add_assets_to_album "album_id" "asset_id_1" "asset_id_2" "asset_id_3"
```

**示例**:
```bash
# 将搜索结果添加到相册
search_result=$(search_assets '{"type": "IMAGE", "takenAfter": "2024-01-01T00:00:00.000Z"}')
asset_ids=($(echo "$search_result" | jq -r '.assets.items[] | .id'))

if [[ ${#asset_ids[@]} -gt 0 ]]; then
    add_assets_to_album "$album_id" "${asset_ids[@]}"
    echo "已添加 ${#asset_ids[@]} 个资源到相册"
fi
```

---

### 从相册移除资源

```
DELETE /api/albums/{id}/assets
```

**所需权限**: `album.write`

**URL 参数**:
- `id`: 相册 ID

**请求体**:
```json
{
  "ids": ["asset-id-1", "asset-id-2"]
}
```

**Shell 函数**:
```bash
remove_assets_from_album "album_id" "asset_id_1" "asset_id_2"
```

---

## 使用场景

### 场景 1: 创建相册并添加照片

```bash
#!/bin/bash
source ~/.claude/skills/claw-immich/scripts/immich-api.sh

# 1. 创建相册
album=$(create_album "2024 春节" "春节家庭聚会")
album_id=$(echo "$album" | jq -r '.id')

# 2. 搜索特定日期的照片
search_result=$(search_assets '{
  "takenAfter": "2024-02-10T00:00:00.000Z",
  "takenBefore": "2024-02-17T23:59:59.999Z",
  "type": "IMAGE"
}')

# 3. 添加到相册
asset_ids=($(echo "$search_result" | jq -r '.assets.items[] | .id'))
add_assets_to_album "$album_id" "${asset_ids[@]}"

echo "相册创建完成，包含 ${#asset_ids[@]} 张照片"
```

### 场景 2: 批量整理相册

```bash
# 列出所有相册
albums=$(list_albums)

# 找出空相册
echo "$albums" | jq -r '.[] | select(.assetCount == 0) | "\(.id) - \(.albumName)"' | while read id name; do
    echo "发现空相册: $name"
    # 可以选择删除或保留
done
```

### 场景 3: 相册去重

```bash
# 获取相册详情
album=$(get_album "$album_id")

# 提取所有资源 ID
asset_ids=($(echo "$album" | jq -r '.assets[].id' | sort -u))

# 如果发现重复，可以重建相册
# 先清空
original_ids=($(echo "$album" | jq -r '.assets[].id'))
remove_assets_from_album "$album_id" "${original_ids[@]}"

# 重新添加去重后的资源
add_assets_to_album "$album_id" "${asset_ids[@]}"
```

## 最佳实践

1. **命名规范**: 使用清晰的命名规则，如 "年份-事件-地点"
2. **描述信息**: 为相册添加详细描述，便于日后查找
3. **定期整理**: 定期检查并清理空相册或未使用的相册
4. **批量操作**: 使用搜索功能批量添加相关照片，而不是逐个添加

## 注意事项

- 相册名称不能为空
- 删除相册不会删除其中的资源
- 相册可以包含来自不同时间和地点的资源
- 同一资源可以属于多个相册

## 相关文档

- [资源管理 API](./assets.md) - 了解如何管理照片和视频
- [搜索功能 API](./search.md) - 使用搜索功能查找要添加的资源
- [共享链接 API](./shared-links.md) - 创建相册共享链接
