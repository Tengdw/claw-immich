# 搜索功能 API

本文档详细介绍 Immich 搜索功能相关的所有 API 端点。

## 概述

Immich 提供两种主要的搜索方式：
1. **元数据搜索** - 基于 EXIF 数据、日期、位置等结构化信息搜索
2. **智能搜索（CLIP）** - 使用 AI 进行语义搜索，理解自然语言描述

**基础 URL**: `{server_url}/api/search`

## API 端点

### 元数据搜索

```
POST /api/search/metadata
```

**所需权限**: `asset.read`

**请求体**:
```json
{
  "takenAfter": "2024-01-01T00:00:00.000Z",
  "takenBefore": "2024-12-31T23:59:59.999Z",
  "type": "IMAGE",
  "city": "Beijing",
  "state": "Beijing",
  "country": "China",
  "make": "Canon",
  "model": "EOS R5",
  "tags": ["vacation", "beach"],
  "isFavorite": true,
  "isArchived": false
}
```

**支持的搜索字段**:

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `takenAfter` | string | 拍摄时间起始（ISO 8601） | `"2024-01-01T00:00:00.000Z"` |
| `takenBefore` | string | 拍摄时间结束（ISO 8601） | `"2024-12-31T23:59:59.999Z"` |
| `type` | string | 文件类型 | `"IMAGE"` 或 `"VIDEO"` |
| `isFavorite` | boolean | 是否收藏 | `true` |
| `isArchived` | boolean | 是否归档 | `false` |
| `city` | string | 城市 | `"Beijing"` |
| `state` | string | 省/州 | `"Beijing"` |
| `country` | string | 国家 | `"China"` |
| `make` | string | 相机品牌 | `"Canon"` |
| `model` | string | 相机型号 | `"EOS R5"` |
| `lensModel` | string | 镜头型号 | `"RF 50mm F1.2 L USM"` |
| `tags` | array | 标签列表 | `["vacation", "beach"]` |

**响应**:
```json
{
  "assets": {
    "count": 100,
    "total": 500,
    "items": [
      {
        "id": "asset-uuid",
        "type": "IMAGE",
        "originalFileName": "IMG_0001.jpg",
        "fileCreatedAt": "2024-01-01T12:00:00.000Z",
        "exifInfo": {...}
      }
    ]
  }
}
```

**Shell 函数**:
```bash
search_assets '{"query": "json_string"}'
```

**示例**:

```bash
# 搜索 2024 年所有照片
search_assets '{"takenAfter": "2024-01-01T00:00:00.000Z", "type": "IMAGE"}'

# 搜索特定相机拍摄的照片
search_assets '{"make": "Canon", "model": "EOS R5"}'

# 搜索北京的照片
search_assets '{"city": "Beijing", "country": "China"}'

# 组合条件：搜索 2024 年夏季的收藏照片
search_assets '{
  "takenAfter": "2024-06-01T00:00:00.000Z",
  "takenBefore": "2024-08-31T23:59:59.999Z",
  "type": "IMAGE",
  "isFavorite": true
}'
```

---

### 智能搜索（CLIP）

```
POST /api/search/smart
```

**所需权限**: `asset.read`

**前置条件**: 服务器必须启用智能搜索功能（machine learning）。

**请求体**:
```json
{
  "query": "beach sunset with people",
  "limit": 20
}
```

**参数说明**:
- `query` (string, 必需): 自然语言搜索查询
- `limit` (number, 可选): 返回结果数量，默认 20

**响应**: 返回匹配的资源列表，按相似度排序。

```json
{
  "items": [
    {
      "id": "asset-uuid",
      "type": "IMAGE",
      "originalFileName": "sunset.jpg",
      "score": 0.95
    }
  ]
}
```

**Shell 函数**:
```bash
smart_search "搜索查询" [limit]
```

**示例**:

```bash
# 搜索海滩日落
smart_search "beach sunset" 10

# 搜索食物照片
smart_search "delicious food" 20

# 搜索人物照片
smart_search "people smiling" 15

# 搜索宠物
smart_search "cat or dog" 30
```

---

## 使用场景

### 场景 1: 按日期范围查找照片

```bash
#!/bin/bash
source ~/.claude/skills/claw-immich/scripts/immich-api.sh

# 搜索 2024 年 6 月的所有照片
query='{
  "takenAfter": "2024-06-01T00:00:00.000Z",
  "takenBefore": "2024-06-30T23:59:59.999Z",
  "type": "IMAGE"
}'

result=$(search_assets "$query")
count=$(echo "$result" | jq '.assets.items | length')

echo "找到 $count 张 2024 年 6 月的照片"

# 列出文件名
echo "$result" | jq -r '.assets.items[] | .originalFileName'
```

### 场景 2: 查找特定地点的照片

```bash
# 搜索东京的所有照片
tokyo_photos=$(search_assets '{
  "city": "Tokyo",
  "type": "IMAGE"
}')

# 统计数量
total=$(echo "$tokyo_photos" | jq '.assets.total')
echo "东京照片总数: $total"

# 按年份分组
echo "$tokyo_photos" | jq -r '.assets.items[] | .fileCreatedAt' | \
    cut -d'-' -f1 | sort | uniq -c
```

### 场景 3: 查找特定相机的照片

```bash
# 搜索用 iPhone 拍摄的照片
iphone_photos=$(search_assets '{
  "make": "Apple",
  "type": "IMAGE"
}')

# 按型号分组统计
echo "$iphone_photos" | jq -r '.assets.items[] | .exifInfo.model' | \
    sort | uniq -c | sort -rn
```

### 场景 4: 智能搜索应用

```bash
# 搜索自然风景
landscapes=$(smart_search "beautiful landscape mountains" 50)

# 创建风景相册
album=$(create_album "自然风景" "AI 智能搜索找到的风景照")
album_id=$(echo "$album" | jq -r '.id')

# 添加搜索结果到相册
asset_ids=($(echo "$landscapes" | jq -r '.items[] | .id'))
add_assets_to_album "$album_id" "${asset_ids[@]}"

echo "已创建包含 ${#asset_ids[@]} 张照片的风景相册"
```

### 场景 5: 组合搜索和批量操作

```bash
# 搜索旧照片并归档
old_photos=$(search_assets '{
  "takenBefore": "2020-01-01T00:00:00.000Z",
  "isArchived": false
}')

# 批量归档
echo "$old_photos" | jq -r '.assets.items[] | .id' | while read asset_id; do
    update_asset "$asset_id" '{"isArchived": true}'
    echo "已归档: $asset_id"
done
```

### 场景 6: 创建智能相册

```bash
#!/bin/bash
# 根据搜索条件自动创建相册

create_smart_album() {
    local album_name="$1"
    local search_query="$2"

    # 搜索照片
    result=$(search_assets "$search_query")
    count=$(echo "$result" | jq '.assets.items | length')

    if [[ $count -eq 0 ]]; then
        echo "没有找到匹配的照片"
        return 1
    fi

    # 创建相册
    album=$(create_album "$album_name" "自动创建于 $(date)")
    album_id=$(echo "$album" | jq -r '.id')

    # 添加照片
    asset_ids=($(echo "$result" | jq -r '.assets.items[] | .id'))
    add_assets_to_album "$album_id" "${asset_ids[@]}"

    echo "已创建相册 '$album_name'，包含 $count 张照片"
}

# 使用示例
create_smart_album "2024 夏季旅行" '{
  "takenAfter": "2024-06-01T00:00:00.000Z",
  "takenBefore": "2024-08-31T23:59:59.999Z",
  "tags": ["travel"]
}'
```

## 搜索技巧

### 元数据搜索技巧

1. **日期范围**: 使用 ISO 8601 格式，确保包含完整的时间
   ```json
   {
     "takenAfter": "2024-01-01T00:00:00.000Z",
     "takenBefore": "2024-12-31T23:59:59.999Z"
   }
   ```

2. **组合条件**: 所有字段都是 AND 关系
   ```json
   {
     "type": "IMAGE",
     "city": "Tokyo",
     "make": "Canon"
   }
   ```

3. **模糊匹配**: 某些字段支持部分匹配（取决于服务器配置）

### 智能搜索技巧

1. **使用描述性语言**: "sunset on the beach" 比 "beach" 更精确
2. **组合多个概念**: "family gathering indoors"
3. **避免过于抽象**: 具体的描述会得到更好的结果
4. **多语言支持**: 根据模型训练数据，可能支持多种语言

### 性能优化

1. **限制结果数量**: 使用合理的 `limit` 值
2. **缩小搜索范围**: 先用元数据搜索缩小范围，再用智能搜索
3. **批量处理**: 一次搜索处理多个结果，而不是多次搜索
4. **缓存结果**: 对于不变的搜索条件，可以缓存结果

## 日期格式参考

所有日期时间字段使用 ISO 8601 格式：`YYYY-MM-DDTHH:mm:ss.SSSZ`

**常用日期生成**:

```bash
# 当前时间
date -u +"%Y-%m-%dT%H:%M:%S.000Z"

# 7 天前（macOS）
date -u -v-7d +"%Y-%m-%dT%H:%M:%S.000Z"

# 7 天前（Linux）
date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%S.000Z"

# 特定日期的开始
echo "2024-01-01T00:00:00.000Z"

# 特定日期的结束
echo "2024-01-31T23:59:59.999Z"
```

## 注意事项

- 智能搜索需要服务器启用机器学习功能
- 大量结果可能需要分页处理
- 搜索性能取决于资源库大小和服务器性能
- EXIF 数据不完整的照片可能搜索不到（如缺少位置信息）
- 标签搜索需要先为照片添加标签

## 相关文档

- [资源管理 API](./assets.md) - 了解资源的完整信息结构
- [标签管理 API](./tags.md) - 使用标签组织和搜索照片
- [相册管理 API](./albums.md) - 将搜索结果添加到相册
