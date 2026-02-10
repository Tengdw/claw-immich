---
name: claw-immich
description: |
  与 Immich 照片管理 API 交互，执行相册和资源操作。
  当用户提到以下关键词时使用：Immich、照片相册、上传照片、上传视频、
  照片库管理、搜索照片、Immich 服务器、管理照片集合、
  创建相册、列出相册、更新相册、查看资源、删除资源、更新资源、搜索媒体元数据。
allowed-tools: Bash, Read, Write, Grep
---

# Claw-Immich Skill

## 概述

Claw-Immich 是一个 Claude Code skill，用于与 Immich 照片管理系统的 API 集成。它提供了完整的相册管理、资源操作和搜索功能，使 Claude 能够帮助用户管理他们的照片和视频库。

### 主要功能

- **相册管理**：创建、列出、更新和删除相册，管理相册中的照片
- **资源管理**：上传照片和视频，查看资源信息，更新元数据
- **智能搜索**：使用元数据搜索照片，支持日期范围、文件类型等过滤条件

## 配置说明

### 首次设置

在首次使用前，需要配置 Immich 服务器连接信息：

```bash
bash ~/.claude/skills/claw-immich/scripts/setup.sh
```

设置向导会提示你输入：
- **服务器地址**（server_url）：你的 Immich 服务器 URL，例如 `https://immich.example.com`
- **API 密钥**（api_key）：从 Immich Web 界面生成的 API 密钥

### 配置文件位置

配置文件存储在：`~/.claude/skills/claw-immich/config/config.json`

配置文件结构：
```json
{
  "server_url": "https://immich.example.com",
  "api_key": "你的API密钥",
  "default_device_id": "claude-code"
}
```

### 生成 API 密钥

1. 登录 Immich Web 界面
2. 进入 **设置** → **API 密钥**
3. 点击 **创建 API 密钥**
4. 为密钥命名（例如：claude-code）
5. 选择所需权限（建议全部选择）
6. 复制生成的密钥

详细说明请参阅：`reference/authentication.md`

## 核心操作

### 相册操作

#### 列出所有相册
```bash
source ~/.claude/skills/claw-immich/scripts/immich-api.sh
list_albums
```

API 端点：`GET /api/albums`

#### 创建新相册
```bash
create_album "相册名称" "相册描述"
```

API 端点：`POST /api/albums`

#### 获取相册详情
```bash
get_album "album_id"
```

API 端点：`GET /api/albums/{id}`

#### 更新相册
```bash
update_album "album_id" '{"albumName": "新名称"}'
```

API 端点：`PATCH /api/albums/{id}`

#### 添加资源到相册
```bash
add_assets_to_album "album_id" "asset_id_1" "asset_id_2" "asset_id_3"
```

API 端点：`PUT /api/albums/{id}/assets`

#### 从相册移除资源
```bash
remove_assets_from_album "album_id" "asset_id_1" "asset_id_2"
```

API 端点：`DELETE /api/albums/{id}/assets`

#### 删除相册
```bash
delete_album "album_id"
```

API 端点：`DELETE /api/albums/{id}`

### 资源操作

#### 上传照片或视频
```bash
upload_asset "/path/to/photo.jpg"
```

API 端点：`POST /api/assets`

上传使用 multipart/form-data 格式，包含以下字段：
- `deviceId`：设备标识（默认：claude-code）
- `deviceAssetId`：设备上的资源 ID
- `fileCreatedAt`：文件创建时间
- `fileModifiedAt`：文件修改时间
- `assetData`：文件数据

#### 搜索资源
```bash
query='{"takenAfter":"2024-01-01T00:00:00.000Z","type":"IMAGE"}'
search_assets "$query"
```

API 端点：`POST /api/search/metadata`

支持的搜索条件：
- `takenAfter` / `takenBefore`：拍摄日期范围
- `type`：文件类型（IMAGE、VIDEO）
- `city`、`state`、`country`：位置信息
- `make`、`model`：相机品牌和型号
- `tags`：标签列表

#### 获取资源信息
```bash
get_asset "asset_id"
```

API 端点：`GET /api/assets/{id}`

#### 更新资源信息
```bash
update_asset "asset_id" '{"description": "新描述", "isFavorite": true}'
```

API 端点：`PATCH /api/assets/{id}`

#### 删除资源
```bash
delete_asset "asset_id"
```

API 端点：`DELETE /api/assets/{id}`

#### 下载资源
```bash
download_asset "asset_id" "/path/to/save/file.jpg"
```

API 端点：`GET /api/assets/{id}/original`

### 搜索功能

#### 元数据搜索
按照元数据条件搜索资源：

```bash
# 按日期范围搜索
query='{"takenAfter":"2024-01-01T00:00:00.000Z","takenBefore":"2024-12-31T23:59:59.999Z"}'
search_assets "$query"

# 按文件类型搜索
query='{"type":"VIDEO"}'
search_assets "$query"

# 组合条件搜索
query='{"type":"IMAGE","city":"Beijing","takenAfter":"2024-06-01T00:00:00.000Z"}'
search_assets "$query"
```

#### 智能搜索（CLIP）
使用 AI 语义搜索照片：

```bash
smart_search "beach sunset" 20
```

API 端点：`POST /api/search/smart`

## 认证方式

所有 API 请求都需要在 HTTP 头部包含 API 密钥：

```
x-api-key: YOUR_API_KEY
```

认证流程：
1. 用户通过 `setup.sh` 配置服务器地址和 API 密钥
2. 密钥存储在 `config/config.json`（权限设置为 600）
3. 所有 API 函数通过 `load_config()` 加载配置
4. 每个请求自动添加 `x-api-key` 头部

### API 密钥权限

建议为 Claude Code 创建独立的 API 密钥，并授予以下权限：
- `album.read`：读取相册信息
- `album.write`：创建和修改相册
- `asset.read`：读取资源信息
- `asset.upload`：上传新资源
- `asset.write`：修改资源信息
- `asset.delete`：删除资源

## 辅助脚本

### immich-api.sh
核心 API 封装脚本，提供所有 API 操作函数。

使用方式：
```bash
source ~/.claude/skills/claw-immich/scripts/immich-api.sh
```

### utils.sh
辅助工具函数，用于格式化输出和错误处理。

主要函数：
- `format_json_response`：格式化 JSON 输出
- `extract_error_message`：提取错误信息
- `is_success_response`：检查响应是否成功
- `format_album_list`：格式化相册列表
- `format_asset_list`：格式化资源列表
- `build_date_filter`：构建日期范围过滤器

使用方式：
```bash
source ~/.claude/skills/claw-immich/scripts/utils.sh
```

### setup.sh
交互式配置向导，用于首次设置。

运行方式：
```bash
bash ~/.claude/skills/claw-immich/scripts/setup.sh
```

## 错误处理

### 配置错误

**配置文件不存在**：
```
错误: 配置文件不存在。请运行配置向导：
bash ~/.claude/skills/claw-immich/scripts/setup.sh
```

**配置无效**：
```
错误: 配置文件缺少必需字段 'server_url' 或 'api_key'
请重新运行配置向导。
```

### 连接错误

**服务器不可达**：
```
错误: 无法连接到 Immich 服务器
请检查：
1. 服务器地址是否正确
2. 服务器是否正在运行
3. 网络连接是否正常
```

**SSL/TLS 错误**：
```
错误: SSL 证书验证失败
如果使用自签名证书，请在 curl 命令中添加 -k 参数（不推荐用于生产环境）
```

### API 错误

**认证失败**：
```
错误: API 密钥无效或已过期
请在 Immich Web 界面检查 API 密钥状态，或重新生成新密钥。
```

**权限不足**：
```
错误: API 密钥权限不足
此操作需要以下权限：album.write
请在 Immich 设置中为 API 密钥添加所需权限。
```

**资源不存在**：
```
错误: 找不到指定的资源或相册
请检查 ID 是否正确。
```

### 文件错误

**文件不存在**：
```
错误: 找不到要上传的文件: /path/to/file.jpg
请检查文件路径是否正确。
```

**文件过大**：
```
错误: 文件大小超过限制
当前文件: 150 MB，最大允许: 100 MB
```

## 示例参考

### 完整工作流示例

详细的可执行示例脚本位于 `examples/` 目录：

- **album-operations.sh**：相册操作完整工作流
  - 列出现有相册
  - 创建新相册
  - 上传照片并添加到相册
  - 查看相册详情

- **asset-operations.sh**：资源操作完整工作流
  - 单个文件上传
  - 批量上传多个文件
  - 搜索和查询资源
  - 更新资源元数据

- **search-operations.sh**：搜索功能示例
  - 按日期范围搜索
  - 按文件类型搜索
  - 多条件组合搜索
  - 格式化搜索结果

运行示例：
```bash
bash ~/.claude/skills/claw-immich/examples/album-operations.sh
```

## 使用场景

### 场景 1：创建旅行相册并上传照片

```bash
# 1. 创建相册
album_id=$(create_album "2024年日本之旅" "东京、京都和大阪的照片" | jq -r '.id')

# 2. 上传照片
for photo in ~/Pictures/Japan2024/*.jpg; do
    asset_id=$(upload_asset "$photo" | jq -r '.id')
    echo "已上传: $photo -> $asset_id"
    asset_ids+=("$asset_id")
done

# 3. 添加照片到相册
add_assets_to_album "$album_id" "${asset_ids[@]}"

echo "相册创建完成，共添加 ${#asset_ids[@]} 张照片"
```

### 场景 2：搜索特定日期的照片

```bash
# 搜索 2024 年 6 月的所有照片
query='{
  "takenAfter": "2024-06-01T00:00:00.000Z",
  "takenBefore": "2024-06-30T23:59:59.999Z",
  "type": "IMAGE"
}'

results=$(search_assets "$query")
count=$(echo "$results" | jq '.assets.items | length')
echo "找到 $count 张照片"

# 格式化并显示结果
source ~/.claude/skills/claw-immich/scripts/utils.sh
format_asset_list "$results"
```

### 场景 3：批量更新照片标签

```bash
# 为所有海滩照片添加标签
query='{"tags": ["beach"]}'
beach_photos=$(search_assets "$query")

# 为每张照片添加新标签
echo "$beach_photos" | jq -r '.assets.items[].id' | while read asset_id; do
    update_asset "$asset_id" '{"tags": ["beach", "summer", "vacation"]}'
    echo "已更新: $asset_id"
done
```

## API 参考

完整的 API 端点参考请查看：`reference/api-endpoints.md`

官方 Immich API 文档：https://api.immich.app/

## 安全建议

1. **保护配置文件**
   - 配置文件包含敏感的 API 密钥
   - 默认权限设置为 600（仅所有者可读写）
   - 不要将配置文件提交到版本控制系统

2. **API 密钥管理**
   - 为不同用途创建独立的 API 密钥
   - 定期轮换 API 密钥
   - 如果密钥泄露，立即在 Immich 中撤销

3. **网络安全**
   - 生产环境务必使用 HTTPS
   - 仅在本地测试环境使用 HTTP
   - 避免在不安全的网络上传输 API 密钥

4. **权限最小化**
   - 仅授予所需的最小权限
   - 如果只需要读取，不要授予写入权限
   - 定期审查 API 密钥的权限设置

## 故障排除

### 常见问题

**Q: 提示 "command not found: jq"**
A: 需要安装 `jq` 工具：
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq
```

**Q: 上传大文件失败**
A: 检查 Immich 服务器的上传大小限制，可能需要调整服务器配置。

**Q: API 响应很慢**
A: 可能是网络延迟或服务器负载高，可以尝试：
- 检查网络连接
- 减少并发请求
- 联系 Immich 服务器管理员

**Q: 无法连接到服务器**
A: 排查步骤：
1. 检查服务器地址是否正确（包括协议 http/https）
2. 使用 `curl` 测试连接：`curl -v https://your-server.com/api/server-info/version`
3. 检查防火墙设置
4. 确认 API 密钥是否有效

## 更新日志

### v1.0.0 (2026-02-10)
- 初始版本
- 支持相册管理（创建、列出、更新、删除）
- 支持资源管理（上传、搜索、更新、删除）
- 支持元数据搜索和智能搜索
- 提供配置向导和完整文档

## 未来计划

- 支持目录批量上传
- 与人脸识别功能集成
- 本地文件夹同步
- 自动 EXIF 元数据提取
- 上传前重复检测
- 多文件操作进度跟踪
- 导出功能（ZIP、外部服务）

## 贡献与反馈

如有问题或建议，欢迎提交 Issue 或 Pull Request。

## 许可证

本 skill 采用 MIT 许可证。
