---
name: claw-immich
description: |
  与 Immich 照片管理 API 交互，执行相册和资源操作。
  当用户提到以下关键词时使用：Immich、照片相册、上传照片、上传视频、
  照片库管理、搜索照片、Immich 服务器、管理照片集合、
  创建相册、列出相册、更新相册、查看资源、删除资源、更新资源、搜索媒体元数据、
  标签管理、照片标签、为照片打标签、共享链接、分享照片、分享相册、
  服务器信息、服务器状态、服务器统计、存储信息。
allowed-tools: Bash, Read, Write, Grep
---

# Claw-Immich Skill

## 概述

Claw-Immich 是一个 Claude Code skill，用于与 Immich 照片管理系统的 API 集成。它提供了完整的相册管理、资源操作、搜索功能、标签管理、共享链接和服务器信息查询能力。

### 主要功能

- 📁 **相册管理** - 创建、列出、更新和删除相册，管理相册中的照片
- 📷 **资源管理** - 上传照片和视频，查看资源信息，更新元数据
- 🔍 **智能搜索** - 使用元数据搜索照片，支持日期范围、文件类型等过滤条件
- 🏷️ **标签管理** - 创建、管理标签，为照片和视频打标签，批量标签操作
- 🔗 **共享链接** - 创建和管理共享链接，分享相册或单个资源，设置访问权限和过期时间
- 🖥️ **服务器信息** - 查询服务器状态、版本、统计信息、存储使用情况

## 快速开始

### 1. 配置 Immich 连接

首次使用前，运行配置向导：

```bash
bash ~/.claude/skills/claw-immich/scripts/setup.sh
```

配置向导会提示你输入：
- **服务器地址**（server_url）：你的 Immich 服务器 URL，例如 `https://immich.example.com`
- **API 密钥**（api_key）：从 Immich Web 界面生成的 API 密钥

### 2. 生成 API 密钥

1. 登录 Immich Web 界面
2. 进入 **设置** → **API 密钥**
3. 点击 **创建 API 密钥**
4. 为密钥命名（例如：claude-code）
5. 复制生成的密钥

详细说明：[reference/authentication.md](./reference/authentication.md)

### 3. 基本使用

```bash
# 加载 API 函数
source ~/.claude/skills/claw-immich/scripts/immich-api.sh

# 测试连接
test_connection

# 列出所有相册
list_albums

# 上传照片
upload_asset "/path/to/photo.jpg"

# 搜索照片
search_assets '{"type": "IMAGE", "takenAfter": "2024-01-01T00:00:00.000Z"}'
```

## 功能文档

### 按类别查看详细文档

每个功能类别都有独立的详细文档，包含完整的 API 参考、使用示例和最佳实践：

| 功能模块 | 文档链接 | 说明 |
|---------|---------|------|
| 📁 相册管理 | [reference/albums.md](./reference/albums.md) | 创建、管理相册，添加和移除照片 |
| 📷 资源管理 | [reference/assets.md](./reference/assets.md) | 上传、下载、更新和删除照片视频 |
| 🔍 搜索功能 | [reference/search.md](./reference/search.md) | 元数据搜索和 AI 智能搜索 |
| 🏷️ 标签管理 | [reference/tags.md](./reference/tags.md) | 创建标签、为资源打标签 |
| 🔗 共享链接 | [reference/shared-links.md](./reference/shared-links.md) | 创建分享链接、管理权限和过期时间 |
| 🖥️ 服务器信息 | [reference/server.md](./reference/server.md) | 查询服务器状态、版本和统计信息 |

### 其他文档

- 📖 [API 端点快速参考](./reference/api-endpoints.md) - 所有 API 端点速查表
- 🛠️ [使用指南](./reference/usage-guide.md) - 常见使用场景和最佳实践
- 🔐 [认证指南](./reference/authentication.md) - API 密钥管理和安全建议

## 示例脚本

`examples/` 目录包含可执行的示例脚本：

```bash
# 相册操作示例
bash ~/.claude/skills/claw-immich/examples/album-operations.sh

# 资源操作示例
bash ~/.claude/skills/claw-immich/examples/asset-operations.sh

# 搜索功能示例
bash ~/.claude/skills/claw-immich/examples/search-operations.sh

# 标签操作示例
bash ~/.claude/skills/claw-immich/examples/tag-operations.sh

# 共享链接示例
bash ~/.claude/skills/claw-immich/examples/shared-link-operations.sh

# 服务器信息示例
bash ~/.claude/skills/claw-immich/examples/server-info-operations.sh
```

## 常用操作速查

### 相册操作

```bash
# 创建相册
create_album "相册名称" "描述"

# 添加照片到相册
add_assets_to_album "album_id" "asset_id_1" "asset_id_2"
```

### 资源操作

```bash
# 上传照片
upload_asset "/path/to/photo.jpg"

# 批量上传
for photo in ~/Photos/*.jpg; do
    upload_asset "$photo"
done
```

### 搜索操作

```bash
# 按日期搜索
search_assets '{"takenAfter": "2024-01-01T00:00:00.000Z", "type": "IMAGE"}'

# 智能搜索
smart_search "beach sunset" 20
```

### 标签操作

```bash
# 创建标签
create_tag "旅行" "#FF5733"

# 为资源添加标签
tag_assets "tag_id" "asset_id_1" "asset_id_2"
```

### 共享链接

```bash
# 创建相册分享
create_simple_shared_link "album" "album_id" "分享描述"
```

### 服务器信息

```bash
# 查看服务器状态
ping_server

# 获取统计信息
get_server_statistics
```

## 核心函数

所有 API 函数都在 `scripts/immich-api.sh` 中定义。使用前需要先加载：

```bash
source ~/.claude/skills/claw-immich/scripts/immich-api.sh
```

**主要函数**:
- `load_config()` - 加载配置文件
- `test_connection()` - 测试 API 连接
- `immich_api_request()` - 通用 API 请求封装

**相册函数**: `list_albums`, `create_album`, `get_album`, `update_album`, `delete_album`, `add_assets_to_album`, `remove_assets_from_album`

**资源函数**: `upload_asset`, `get_asset`, `update_asset`, `delete_asset`, `download_asset`, `search_assets`, `smart_search`

**标签函数**: `get_all_tags`, `create_tag`, `get_tag_by_id`, `update_tag`, `delete_tag`, `tag_assets`, `untag_assets`, `bulk_tag_assets`, `upsert_tags`

**共享函数**: `get_all_shared_links`, `create_shared_link`, `create_simple_shared_link`, `get_shared_link_by_id`, `update_shared_link`, `remove_shared_link`, `add_shared_link_assets`, `remove_shared_link_assets`

**服务器函数**: `ping_server`, `get_server_version`, `get_about_info`, `get_server_config`, `get_server_features`, `get_server_statistics`, `get_storage`, `get_supported_media_types`, `get_theme`, `get_version_check`, `get_version_history`, `get_apk_links`

完整函数列表和详细说明请查看对应的功能文档。

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

**Q: 提示 "配置文件不存在"**
A: 运行配置向导：`bash ~/.claude/skills/claw-immich/scripts/setup.sh`

**Q: 提示 "连接失败"**
A: 检查：
1. 服务器地址是否正确（包括 http/https）
2. 服务器是否正在运行
3. API 密钥是否有效
4. 网络连接是否正常

**Q: 上传大文件失败**
A: 检查 Immich 服务器的上传大小限制，可能需要调整服务器配置。

更多问题请查看 [使用指南](./reference/usage-guide.md)。

## 安全建议

1. **保护配置文件** - 配置文件包含 API 密钥，权限已设为 600（仅所有者可读写）
2. **API 密钥管理** - 为不同用途创建独立的 API 密钥，定期轮换
3. **使用 HTTPS** - 生产环境务必使用 HTTPS 连接
4. **权限最小化** - 仅授予所需的最小权限

详细安全指南：[reference/authentication.md](./reference/authentication.md)

## 相关资源

- **Immich 官网**: https://immich.app/
- **Immich GitHub**: https://github.com/immich-app/immich
- **API 文档**: https://api.immich.app/
- **Claude Code**: https://github.com/anthropics/claude-code

## 更新日志

### v1.1.0 (2026-02-11)
- ✨ 新增标签管理功能（9个 API 函数）
- ✨ 新增共享链接功能（8个 API 函数）
- ✨ 新增完整的服务器信息查询（14个 API 函数）
- 📚 文档重构为模块化结构
- 📝 新增示例脚本：tag-operations.sh, shared-link-operations.sh, server-info-operations.sh

### v1.0.0 (2026-02-10)
- 🎉 初始版本
- ✅ 完整的相册管理功能
- ✅ 资源上传和搜索
- ✅ 中文文档和示例
- ✅ 配置向导

## 许可证

MIT License - 详见 LICENSE 文件
