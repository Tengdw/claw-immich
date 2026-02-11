# 标签管理 API

本文档详细介绍 Immich 标签管理相关的所有 API 端点。

## 概述

标签是组织和分类照片的灵活方式。与相册不同，一个资源可以有多个标签，标签支持层级结构和颜色标记。

**基础 URL**: `{server_url}/api/tags`

## API 端点

### 获取所有标签

```
GET /api/tags
```

**所需权限**: `tag.read`

**响应示例**:
```json
[
  {
    "id": "tag-uuid",
    "name": "家庭",
    "color": "#FF5733",
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
]
```

**Shell 函数**:
```bash
get_all_tags
```

---

### 创建新标签

```
POST /api/tags
```

**所需权限**: `tag.create`

**请求体**:
```json
{
  "name": "标签名称",
  "color": "#FF5733"
}
```

**参数说明**:
- `name` (string, 必需): 标签名称
- `color` (string, 可选): 标签颜色，十六进制格式

**Shell 函数**:
```bash
create_tag "标签名称" ["#颜色代码"]
```

**示例**:
```bash
# 创建带颜色的标签
tag=$(create_tag "旅行" "#FF5733")
tag_id=$(echo "$tag" | jq -r '.id')

# 创建不带颜色的标签
create_tag "家庭"
```

---

### 批量创建或更新标签

```
PUT /api/tags
```

**所需权限**: `tag.create`

**请求体**:
```json
{
  "tags": [
    {
      "id": "existing-tag-id",
      "name": "更新的标签名",
      "color": "#00FF00"
    },
    {
      "name": "新标签",
      "color": "#0000FF"
    }
  ]
}
```

**Shell 函数**:
```bash
upsert_tags '{"tags": [...]}'
```

**示例**:
```bash
# 批量创建多个标签
data='{
  "tags": [
    {"name": "风景", "color": "#00FF00"},
    {"name": "人物", "color": "#0000FF"},
    {"name": "美食", "color": "#FFC300"}
  ]
}'
upsert_tags "$data"
```

---

### 获取指定标签

```
GET /api/tags/{id}
```

**所需权限**: `tag.read`

**URL 参数**:
- `id`: 标签 ID

**响应**: 返回标签详情，包含使用该标签的资源列表。

**Shell 函数**:
```bash
get_tag_by_id "tag_id"
```

---

### 更新标签

```
PUT /api/tags/{id}
```

**所需权限**: `tag.create`

**URL 参数**:
- `id`: 标签 ID

**请求体**:
```json
{
  "name": "新名称",
  "color": "#00FF00"
}
```

**Shell 函数**:
```bash
update_tag "tag_id" '{"name": "新名称", "color": "#颜色"}'
```

---

### 删除标签

```
DELETE /api/tags/{id}
```

**所需权限**: `tag.delete`

**URL 参数**:
- `id`: 标签 ID

**注意**: 删除标签会从所有资源中移除该标签。

**Shell 函数**:
```bash
delete_tag "tag_id"
```

---

### 为资源添加标签

```
PUT /api/tags/{id}/assets
```

**所需权限**: `tag.create`

**URL 参数**:
- `id`: 标签 ID

**请求体**:
```json
{
  "assetIds": ["asset-id-1", "asset-id-2", "asset-id-3"]
}
```

**Shell 函数**:
```bash
tag_assets "tag_id" "asset_id_1" "asset_id_2" "asset_id_3"
```

**示例**:
```bash
# 为搜索结果添加标签
search_result=$(search_assets '{"city": "Tokyo"}')
asset_ids=($(echo "$search_result" | jq -r '.assets.items[] | .id'))

tag_id="your-tag-id"
tag_assets "$tag_id" "${asset_ids[@]}"
```

---

### 移除资源标签

```
DELETE /api/tags/{id}/assets
```

**所需权限**: `tag.delete`

**URL 参数**:
- `id`: 标签 ID

**请求体**:
```json
{
  "assetIds": ["asset-id-1", "asset-id-2"]
}
```

**Shell 函数**:
```bash
untag_assets "tag_id" "asset_id_1" "asset_id_2"
```

---

### 批量为资源添加标签

```
PUT /api/tags/assets
```

**所需权限**: `tag.create`

**请求体**:
```json
{
  "assetIds": ["asset-id-1", "asset-id-2"],
  "tagIds": ["tag-id-1", "tag-id-2"]
}
```

**Shell 函数**:
```bash
bulk_tag_assets '{"assetIds": [...], "tagIds": [...]}'
```

**示例**:
```bash
# 为多个资源添加多个标签
data='{
  "assetIds": ["asset-1", "asset-2", "asset-3"],
  "tagIds": ["tag-1", "tag-2"]
}'
bulk_tag_assets "$data"
```

---

## 使用场景

### 场景 1: 创建标签体系

```bash
#!/bin/bash
source ~/.claude/skills/claw-immich/scripts/immich-api.sh

# 创建分类标签体系
echo "创建标签体系..."

# 主题类标签
create_tag "风景" "#00FF00"
create_tag "人物" "#0000FF"
create_tag "美食" "#FFC300"
create_tag "建筑" "#C70039"
create_tag "动物" "#FF5733"

# 事件类标签
create_tag "旅行" "#900C3F"
create_tag "聚会" "#581845"
create_tag "工作" "#6C3483"

# 情感类标签
create_tag "快乐" "#F39C12"
create_tag "怀旧" "#5DADE2"

echo "标签体系创建完成"
```

### 场景 2: 智能自动标记

```bash
#!/bin/bash
# 基于搜索结果自动添加标签

# 创建"海滩"标签
beach_tag=$(create_tag "海滩" "#00BFFF")
beach_tag_id=$(echo "$beach_tag" | jq -r '.id')

# 使用智能搜索找到海滩照片
beach_photos=$(smart_search "beach ocean" 100)

# 为所有结果添加标签
asset_ids=($(echo "$beach_photos" | jq -r '.items[] | .id'))
if [[ ${#asset_ids[@]} -gt 0 ]]; then
    tag_assets "$beach_tag_id" "${asset_ids[@]}"
    echo "已为 ${#asset_ids[@]} 张照片添加'海滩'标签"
fi
```

### 场景 3: 按时间段批量标记

```bash
# 为 2024 夏季照片添加"夏季"标签
summer_tag=$(create_tag "夏季" "#FFD700")
summer_tag_id=$(echo "$summer_tag" | jq -r '.id')

# 搜索夏季照片
summer_photos=$(search_assets '{
  "takenAfter": "2024-06-01T00:00:00.000Z",
  "takenBefore": "2024-08-31T23:59:59.999Z",
  "type": "IMAGE"
}')

# 添加标签
asset_ids=($(echo "$summer_photos" | jq -r '.assets.items[] | .id'))
tag_assets "$summer_tag_id" "${asset_ids[@]}"
```

### 场景 4: 标签管理和清理

```bash
#!/bin/bash
# 查找和清理未使用的标签

all_tags=$(get_all_tags)

echo "$all_tags" | jq -c '.[]' | while read tag; do
    tag_id=$(echo "$tag" | jq -r '.id')
    tag_name=$(echo "$tag" | jq -r '.name')

    # 获取标签详情
    tag_detail=$(get_tag_by_id "$tag_id")

    # 检查是否有资源使用此标签
    asset_count=$(echo "$tag_detail" | jq '.assets | length // 0')

    if [[ $asset_count -eq 0 ]]; then
        echo "未使用的标签: $tag_name"
        read -p "是否删除？(y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            delete_tag "$tag_id"
            echo "已删除: $tag_name"
        fi
    fi
done
```

### 场景 5: 标签统计报告

```bash
#!/bin bash
# 生成标签使用统计报告

echo "标签使用统计报告"
echo "=================="
echo ""

all_tags=$(get_all_tags)

echo "$all_tags" | jq -c '.[]' | while read tag; do
    tag_id=$(echo "$tag" | jq -r '.id')
    tag_name=$(echo "$tag" | jq -r '.name')
    tag_color=$(echo "$tag" | jq -r '.color // "无"')

    # 搜索使用此标签的资源
    tagged_assets=$(search_assets "{\"tags\": [\"$tag_name\"]}")
    count=$(echo "$tagged_assets" | jq '.assets.total // 0')

    printf "%-20s %-10s %d 张照片\n" "$tag_name" "$tag_color" "$count"
done | sort -k3 -rn
```

### 场景 6: 多标签组合搜索

```bash
# 搜索同时带有"旅行"和"海滩"标签的照片
result=$(search_assets '{
  "tags": ["旅行", "海滩"],
  "type": "IMAGE"
}')

count=$(echo "$result" | jq '.assets.total')
echo "找到 $count 张旅行+海滩照片"

# 为这些照片添加新标签"度假"
if [[ $count -gt 0 ]]; then
    vacation_tag=$(create_tag "度假" "#FF6B9D")
    vacation_tag_id=$(echo "$vacation_tag" | jq -r '.id')

    asset_ids=($(echo "$result" | jq -r '.assets.items[] | .id'))
    tag_assets "$vacation_tag_id" "${asset_ids[@]}"
fi
```

## 标签组织策略

### 1. 分类标签

按主题分类：
- 🌄 风景、🏛️ 建筑、🍔 美食、👨‍👩‍👧 人物、🐕 动物

### 2. 事件标签

按事件分类：
- 🎉 聚会、✈️ 旅行、💼 工作、🎓 教育

### 3. 时间标签

按时间分类：
- 📅 2024、🌸 春季、☀️ 夏季、🍂 秋季、❄️ 冬季

### 4. 地点标签

按地点分类：
- 🗼 东京、🗽 纽约、🗼 巴黎、🏛️ 北京

### 5. 情感标签

按情感分类：
- 😊 快乐、😢 怀旧、❤️ 浪漫、🎊 激动

## 颜色编码建议

使用颜色帮助快速识别标签类别：

```bash
# 主题类 - 绿色系
create_tag "风景" "#00FF00"
create_tag "自然" "#90EE90"

# 人物类 - 蓝色系
create_tag "家庭" "#0000FF"
create_tag "朋友" "#6495ED"

# 事件类 - 紫色系
create_tag "旅行" "#800080"
create_tag "聚会" "#9370DB"

# 情感类 - 黄橙色系
create_tag "快乐" "#FFD700"
create_tag "怀旧" "#FFA500"

# 重要标记 - 红色系
create_tag "精选" "#FF0000"
create_tag "待编辑" "#FF6347"
```

## 最佳实践

1. **标签命名**: 使用简短、清晰的名称，避免过于复杂
2. **颜色分组**: 相关标签使用相似颜色，便于视觉识别
3. **避免重复**: 创建前检查是否已存在类似标签
4. **定期整理**: 合并相似标签，删除未使用的标签
5. **组合使用**: 一个照片可以有多个标签，充分利用标签的灵活性

## 注意事项

- 标签名称区分大小写
- 颜色使用十六进制格式，如 `#FF5733`
- 删除标签会影响所有使用该标签的资源
- 批量操作时注意性能，建议分批处理大量资源

## 相关文档

- [搜索功能 API](./search.md) - 使用标签搜索照片
- [资源管理 API](./assets.md) - 了解资源的标签属性
- [相册管理 API](./albums.md) - 标签和相册的配合使用
