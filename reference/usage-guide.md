# Claw-Immich 使用指南

本文档提供常见使用场景、工作流程和最佳实践。

## 目录

- [常见使用场景](#常见使用场景)
- [工作流程](#工作流程)
- [最佳实践](#最佳实践)
- [故障排除](#故障排除)
- [性能优化](#性能优化)

## 常见使用场景

### 1. 导入和组织照片

**场景描述**: 将本地照片导入 Immich 并自动组织到相册。

**详细指南**: [资源管理 API - 场景 1: 智能导入照片](./assets.md#场景-1-智能导入照片)

**快速示例**:
```bash
# 批量上传并自动按日期创建相册
for photo in ~/Photos/Import/*.jpg; do
    result=$(upload_asset "$photo")
    asset_id=$(echo "$result" | jq -r '.id')

    # 根据日期归类
    date=$(get_asset "$asset_id" | jq -r '.fileCreatedAt' | cut -d'T' -f1)
    # ... 创建或添加到相册
done
```

### 2. 创建和分享旅行相册

**场景描述**: 为旅行照片创建相册并生成分享链接。

**详细指南**: [共享链接 API - 场景 1: 分享旅行相册](./shared-links.md#场景-1-分享旅行相册)

**快速示例**:
```bash
# 1. 创建相册
album=$(create_album "日本之旅 2024" "东京、京都、大阪")
album_id=$(echo "$album" | jq -r '.id')

# 2. 搜索并添加照片
photos=$(search_assets '{"city": "Tokyo", "takenAfter": "2024-06-01T00:00:00.000Z"}')
asset_ids=($(echo "$photos" | jq -r '.assets.items[] | .id'))
add_assets_to_album "$album_id" "${asset_ids[@]}"

# 3. 创建分享链接
link=$(create_simple_shared_link "album" "$album_id" "日本之旅分享")
echo "分享链接: $(echo "$link" | jq -r '.key')"
```

### 3. 智能照片分类

**场景描述**: 使用标签和AI搜索自动分类照片。

**详细指南**:
- [标签管理 API - 场景 2: 智能自动标记](./tags.md#场景-2-智能自动标记)
- [搜索功能 API - 场景 4: 智能搜索应用](./search.md#场景-4-智能搜索应用)

**快速示例**:
```bash
# 创建标签
beach_tag=$(create_tag "海滩" "#00BFFF")
beach_tag_id=$(echo "$beach_tag" | jq -r '.id')

# 使用 AI 搜索海滩照片
beach_photos=$(smart_search "beach ocean" 100)

# 自动打标签
asset_ids=($(echo "$beach_photos" | jq -r '.items[] | .id'))
tag_assets "$beach_tag_id" "${asset_ids[@]}"
```

### 4. 定期备份收藏照片

**场景描述**: 定期下载收藏照片到本地备份。

**详细指南**: [资源管理 API - 场景 3: 备份收藏的照片](./assets.md#场景-3-备份收藏的照片)

**快速示例**:
```bash
# 搜索收藏照片
favorites=$(search_assets '{"isFavorite": true}')

# 下载到本地
mkdir -p ~/Backups/Favorites
echo "$favorites" | jq -r '.assets.items[] | .id' | while read asset_id; do
    filename=$(get_asset "$asset_id" | jq -r '.originalFileName')
    download_asset "$asset_id" "~/Backups/Favorites/$filename"
done
```

### 5. 服务器健康监控

**场景描述**: 监控 Immich 服务器的健康状态和资源使用。

**详细指南**: [服务器信息 API - 场景 1: 服务器健康检查](./server.md#场景-1-服务器健康检查)

**快速示例**:
```bash
# 健康检查脚本
ping_server && echo "✓ 服务器在线" || echo "✗ 服务器离线"

# 检查存储
about=$(get_about_info)
usage=$(echo "$about" | jq -r '.diskUsagePercentage')
echo "存储使用率: $usage%"

# 检查更新
check=$(get_version_check)
is_available=$(echo "$check" | jq -r '.isAvailable')
[[ "$is_available" == "true" ]] && echo "⚠ 有新版本可用"
```

## 工作流程

### 照片导入工作流

```
1. 准备导入
   ↓
2. 验证文件格式 (get_supported_media_types)
   ↓
3. 批量上传 (upload_asset)
   ↓
4. 提取 EXIF 信息 (get_asset)
   ↓
5. 自动分类
   - 按日期创建相册
   - 按位置添加标签
   - AI 识别内容
   ↓
6. 验证和清理
```

**实施脚本**: 参考 `examples/asset-operations.sh`

### 相册整理工作流

```
1. 创建相册结构
   ↓
2. 搜索相关照片 (search_assets / smart_search)
   ↓
3. 添加到相册 (add_assets_to_album)
   ↓
4. 添加标签 (tag_assets)
   ↓
5. 创建分享链接 (create_shared_link)
   ↓
6. 设置权限和过期时间
```

**实施脚本**: 参考 `examples/album-operations.sh`

### 定期维护工作流

```
1. 健康检查
   - ping_server
   - get_server_statistics
   - get_storage
   ↓
2. 内容整理
   - 清理重复照片
   - 归档旧照片
   - 删除未使用的标签
   ↓
3. 备份
   - 下载重要照片
   - 导出相册列表
   ↓
4. 更新检查
   - get_version_check
   - 查看更新日志
```

**实施脚本**: 参考 `examples/server-info-operations.sh`

## 最佳实践

### 1. 相册组织

**命名规范**:
- 使用统一格式：`年份-事件-地点`
- 示例：`2024-春节-北京`, `2024-日本之旅-东京`

**描述信息**:
- 添加详细描述便于搜索
- 包含关键信息：时间、地点、人物、事件

**相册大小**:
- 每个相册建议不超过 500 张照片
- 大型活动可分多个相册

详见: [相册管理 API - 最佳实践](./albums.md#最佳实践)

### 2. 标签系统

**分类体系**:
- 主题类：风景、人物、美食、建筑
- 事件类：旅行、聚会、工作
- 时间类：2024、春季、夏季
- 地点类：东京、北京、纽约
- 情感类：快乐、怀旧、浪漫

**颜色编码**:
- 使用颜色区分标签类别
- 相关标签使用相似颜色

**定期维护**:
- 合并相似标签
- 删除未使用的标签
- 更新标签命名

详见: [标签管理 API - 标签组织策略](./tags.md#标签组织策略)

### 3. 搜索优化

**元数据搜索技巧**:
- 组合多个条件缩小范围
- 使用日期范围过滤
- 利用 EXIF 位置信息

**智能搜索技巧**:
- 使用描述性语言
- 组合多个概念
- 避免过于抽象

**性能考虑**:
- 限制结果数量
- 先用元数据搜索缩小范围
- 缓存常用搜索结果

详见: [搜索功能 API - 搜索技巧](./search.md#搜索技巧)

### 4. 共享安全

**安全分享**:
- 设置合理的过期时间（7-30天）
- 使用密码保护敏感内容
- 禁止下载原图
- 隐藏位置等隐私信息

**公开分享**:
- 允许下载和查看元数据
- 不设过期时间或设置较长期限
- 清晰的描述信息

**定期维护**:
- 删除过期链接
- 检查分享统计
- 更新权限设置

详见: [共享链接 API - 分享策略](./shared-links.md#分享策略)

### 5. 服务器维护

**定期检查**:
- 每日：在线状态、存储使用率
- 每周：版本更新、系统资源
- 每月：功能状态、性能指标

**监控自动化**:
- 使用 cron 定时任务
- 设置告警阈值
- 记录历史数据

**备份策略**:
- 定期备份配置
- 导出重要数据
- 测试恢复流程

详见: [服务器信息 API - 监控建议](./server.md#监控建议)

## 故障排除

### 连接问题

**问题**: 无法连接到服务器

**检查清单**:
1. ✓ 服务器地址是否正确（包括 http/https）
2. ✓ 服务器是否正在运行
3. ✓ API 密钥是否有效
4. ✓ 网络连接是否正常
5. ✓ 防火墙设置是否阻止连接

**解决方案**:
```bash
# 测试连接
ping_server

# 检查服务器版本
get_server_version

# 查看错误详情
get_about_info 2>&1 | tee /tmp/immich-debug.log
```

### 上传失败

**问题**: 照片上传失败

**可能原因**:
- 文件格式不支持
- 文件过大
- 服务器存储空间不足
- API 密钥权限不足

**解决方案**:
```bash
# 检查支持的格式
media_types=$(get_supported_media_types)
echo "$media_types" | jq '.image'

# 检查存储空间
about=$(get_about_info)
echo "$about" | jq '{diskAvailable, diskUsagePercentage}'

# 检查文件大小
ls -lh /path/to/photo.jpg
```

### 搜索无结果

**问题**: 搜索不到预期的照片

**可能原因**:
- EXIF 数据不完整
- 搜索条件过于严格
- 智能搜索功能未启用
- 照片尚未索引

**解决方案**:
```bash
# 检查照片 EXIF 信息
asset=$(get_asset "asset_id")
echo "$asset" | jq '.exifInfo'

# 检查智能搜索是否可用
features=$(get_server_features)
echo "$features" | jq '.smartSearch'

# 放宽搜索条件
search_assets '{"type": "IMAGE"}'  # 只按类型搜索
```

### 性能问题

**问题**: API 响应缓慢

**检查项目**:
- 服务器负载
- 网络延迟
- 请求频率
- 数据库性能

**优化方案**:
```bash
# 检查服务器状态
stats=$(get_server_statistics)
echo "$stats" | jq '{photos, videos, usage}'

# 批量操作添加延迟
for id in "${asset_ids[@]}"; do
    update_asset "$id" '{"isFavorite": true}'
    sleep 0.1  # 添加 100ms 延迟
done
```

更多问题请查看各功能模块的详细文档。

## 性能优化

### 批量操作优化

**问题**: 大量操作导致性能下降

**优化策略**:
```bash
# 使用批量 API
bulk_tag_assets '{"assetIds": [...], "tagIds": [...]}'

# 而不是循环调用
for asset_id in "${asset_ids[@]}"; do
    tag_assets "$tag_id" "$asset_id"  # 不推荐
done
```

### 搜索性能优化

**策略 1**: 逐步缩小范围
```bash
# 先用元数据搜索
photos=$(search_assets '{"type": "IMAGE", "city": "Tokyo"}')

# 再从结果中用智能搜索
# 提取 ID 后再进行 CLIP 搜索
```

**策略 2**: 限制结果数量
```bash
# 设置合理的 limit
smart_search "beach" 20  # 而不是 1000
```

**策略 3**: 缓存常用结果
```bash
# 缓存搜索结果
if [[ ! -f /tmp/tokyo_photos.json ]]; then
    search_assets '{"city": "Tokyo"}' > /tmp/tokyo_photos.json
fi
```

### 网络优化

**并发控制**:
```bash
# 使用后台任务但控制并发数
max_concurrent=3
count=0

for photo in *.jpg; do
    upload_asset "$photo" &
    ((count++))

    if [[ $count -ge $max_concurrent ]]; then
        wait -n  # 等待任意一个完成
        ((count--))
    fi
done

wait  # 等待所有任务完成
```

**请求合并**:
```bash
# 一次请求获取多个资源信息
# 而不是多次单独请求
album=$(get_album "$album_id")  # 包含所有资源信息
```

## 自动化脚本示例

### 每日自动备份脚本

```bash
#!/bin/bash
# 自动备份收藏照片

BACKUP_DIR="$HOME/Backups/Immich/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

source ~/.claude/skills/claw-immich/scripts/immich-api.sh

# 搜索收藏
favorites=$(search_assets '{"isFavorite": true}')

# 下载
echo "$favorites" | jq -r '.assets.items[] | .id' | while read id; do
    filename=$(get_asset "$id" | jq -r '.originalFileName')
    download_asset "$id" "$BACKUP_DIR/$filename"
done

echo "备份完成: $BACKUP_DIR"
```

### 自动整理脚本

```bash
#!/bin/bash
# 按月份自动创建相册

source ~/.claude/skills/claw-immich/scripts/immich-api.sh

# 获取当前年月
year=$(date +%Y)
month=$(date +%m)
month_name=$(date +%B)

# 搜索本月照片
start="${year}-${month}-01T00:00:00.000Z"
end="${year}-${month}-$(date -d "${year}-${month}-01 +1 month -1 day" +%d)T23:59:59.999Z"

photos=$(search_assets "{
    \"takenAfter\": \"$start\",
    \"takenBefore\": \"$end\",
    \"type\": \"IMAGE\"
}")

count=$(echo "$photos" | jq '.assets.items | length')

if [[ $count -gt 0 ]]; then
    # 创建相册
    album=$(create_album "$year年$month_name" "自动创建")
    album_id=$(echo "$album" | jq -r '.id')

    # 添加照片
    asset_ids=($(echo "$photos" | jq -r '.assets.items[] | .id'))
    add_assets_to_album "$album_id" "${asset_ids[@]}"

    echo "已创建相册: $year年$month_name ($count 张照片)"
fi
```

## 相关文档

- [相册管理 API](./albums.md)
- [资源管理 API](./assets.md)
- [搜索功能 API](./search.md)
- [标签管理 API](./tags.md)
- [共享链接 API](./shared-links.md)
- [服务器信息 API](./server.md)
- [API 端点快速参考](./api-endpoints.md)
- [认证指南](./authentication.md)
