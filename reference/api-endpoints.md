# Immich API 端点快速参考

本文档提供 Immich API 所有端点的快速索引。每个类别都有详细的文档，包含完整的 API 参考、使用示例和最佳实践。

## 基础信息

- **基础 URL**: `{server_url}/api`
- **认证方式**: HTTP 头部 `x-api-key: YOUR_API_KEY`
- **请求格式**: JSON（资源上传使用 multipart/form-data）
- **响应格式**: JSON

## API 端点索引

### 📁 相册管理 API

完整文档: [reference/albums.md](./albums.md)

| 方法 | 端点 | 说明 | Shell 函数 |
|------|------|------|-----------|
| GET | `/api/albums` | 列出所有相册 | `list_albums` |
| POST | `/api/albums` | 创建新相册 | `create_album` |
| GET | `/api/albums/{id}` | 获取相册详情 | `get_album` |
| PATCH | `/api/albums/{id}` | 更新相册信息 | `update_album` |
| DELETE | `/api/albums/{id}` | 删除相册 | `delete_album` |
| PUT | `/api/albums/{id}/assets` | 添加资源到相册 | `add_assets_to_album` |
| DELETE | `/api/albums/{id}/assets` | 从相册移除资源 | `remove_assets_from_album` |

### 📷 资源管理 API

完整文档: [reference/assets.md](./assets.md)

| 方法 | 端点 | 说明 | Shell 函数 |
|------|------|------|-----------|
| POST | `/api/assets` | 上传资源 | `upload_asset` |
| GET | `/api/assets/{id}` | 获取资源信息 | `get_asset` |
| PATCH | `/api/assets/{id}` | 更新资源信息 | `update_asset` |
| DELETE | `/api/assets/{id}` | 删除资源 | `delete_asset` |
| GET | `/api/assets/{id}/original` | 下载资源原图 | `download_asset` |
| GET | `/api/assets/{id}/thumbnail` | 获取资源缩略图 | - |

### 🔍 搜索功能 API

完整文档: [reference/search.md](./search.md)

| 方法 | 端点 | 说明 | Shell 函数 |
|------|------|------|-----------|
| POST | `/api/search/metadata` | 元数据搜索 | `search_assets` |
| POST | `/api/search/smart` | 智能搜索（CLIP） | `smart_search` |

### 🏷️ 标签管理 API

完整文档: [reference/tags.md](./tags.md)

| 方法 | 端点 | 说明 | Shell 函数 |
|------|------|------|-----------|
| GET | `/api/tags` | 获取所有标签 | `get_all_tags` |
| POST | `/api/tags` | 创建新标签 | `create_tag` |
| PUT | `/api/tags` | 批量创建或更新标签 | `upsert_tags` |
| GET | `/api/tags/{id}` | 获取指定标签 | `get_tag_by_id` |
| PUT | `/api/tags/{id}` | 更新标签 | `update_tag` |
| DELETE | `/api/tags/{id}` | 删除标签 | `delete_tag` |
| PUT | `/api/tags/{id}/assets` | 为资源添加标签 | `tag_assets` |
| DELETE | `/api/tags/{id}/assets` | 移除资源标签 | `untag_assets` |
| PUT | `/api/tags/assets` | 批量为资源添加标签 | `bulk_tag_assets` |

### 🔗 共享链接 API

完整文档: [reference/shared-links.md](./shared-links.md)

| 方法 | 端点 | 说明 | Shell 函数 |
|------|------|------|-----------|
| GET | `/api/shared-links` | 获取所有共享链接 | `get_all_shared_links` |
| POST | `/api/shared-links` | 创建共享链接 | `create_shared_link` |
| GET | `/api/shared-links/me` | 获取当前共享链接 | `get_my_shared_link` |
| GET | `/api/shared-links/{id}` | 获取指定共享链接 | `get_shared_link_by_id` |
| PATCH | `/api/shared-links/{id}` | 更新共享链接 | `update_shared_link` |
| DELETE | `/api/shared-links/{id}` | 删除共享链接 | `remove_shared_link` |
| PUT | `/api/shared-links/{id}/assets` | 添加资源到共享链接 | `add_shared_link_assets` |
| DELETE | `/api/shared-links/{id}/assets` | 从共享链接移除资源 | `remove_shared_link_assets` |

### 🖥️ 服务器信息 API

完整文档: [reference/server.md](./server.md)

| 方法 | 端点 | 说明 | Shell 函数 |
|------|------|------|-----------|
| GET | `/api/server/ping` | Ping 服务器 | `ping_server` |
| GET | `/api/server/version` | 获取服务器版本 | `get_server_version` |
| GET | `/api/server/about` | 获取服务器基本信息 | `get_about_info` |
| GET | `/api/server/config` | 获取服务器配置 | `get_server_config` |
| GET | `/api/server/features` | 获取服务器功能 | `get_server_features` |
| GET | `/api/server/statistics` | 获取服务器统计信息 | `get_server_statistics` |
| GET | `/api/server/storage` | 获取存储信息 | `get_storage` |
| GET | `/api/server/media-types` | 获取支持的媒体类型 | `get_supported_media_types` |
| GET | `/api/server/theme` | 获取服务器主题 | `get_theme` |
| GET | `/api/server/version-check` | 检查版本更新 | `get_version_check` |
| GET | `/api/server/version-history` | 获取版本历史 | `get_version_history` |
| GET | `/api/server/apk-links` | 获取 APK 下载链接 | `get_apk_links` |
| GET | `/api/server/license` | 获取许可证信息 | `get_server_license` |
| PUT | `/api/server/license` | 设置许可证 | `set_server_license` |
| DELETE | `/api/server/license` | 删除许可证 | `delete_server_license` |

## 通用信息

### HTTP 状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 201 | 资源创建成功 |
| 204 | 请求成功，无返回内容 |
| 400 | 请求参数错误 |
| 401 | 认证失败（API 密钥无效） |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 409 | 资源冲突（例如：重复上传） |
| 500 | 服务器内部错误 |

### 错误响应格式

```json
{
  "statusCode": 400,
  "message": "错误描述",
  "error": "Bad Request"
}
```

### 日期格式

所有日期时间字段使用 ISO 8601 格式：`YYYY-MM-DDTHH:mm:ss.SSSZ`

**示例**:
- `2024-01-01T00:00:00.000Z` - 2024年1月1日 00:00:00 UTC
- `2024-12-31T23:59:59.999Z` - 2024年12月31日 23:59:59 UTC

### 分页

某些端点支持分页参数：

- `page`: 页码（从 1 开始）
- `size`: 每页数量

示例: `GET /api/assets?page=1&size=50`

## 认证

所有需要认证的端点都需要在 HTTP 头部包含 API 密钥：

```
x-api-key: YOUR_API_KEY
```

**生成 API 密钥**:
1. 登录 Immich Web 界面
2. 进入 **设置** → **API 密钥**
3. 点击 **创建 API 密钥**
4. 为密钥命名并复制

详细说明：[authentication.md](./authentication.md)

## 使用示例

### 加载 API 函数

```bash
source ~/.claude/skills/claw-immich/scripts/immich-api.sh
```

### 基本操作

```bash
# 测试连接
test_connection

# 列出相册
list_albums

# 上传照片
upload_asset "/path/to/photo.jpg"

# 搜索照片
search_assets '{"type": "IMAGE", "takenAfter": "2024-01-01T00:00:00.000Z"}'

# 创建标签
create_tag "旅行" "#FF5733"

# 创建共享链接
create_simple_shared_link "album" "album_id" "分享描述"

# 查看服务器状态
ping_server
```

## 相关文档

- 📖 [使用指南](./usage-guide.md) - 常见使用场景和最佳实践
- 🔐 [认证指南](./authentication.md) - API 密钥管理和安全建议
- 📚 [主文档](../SKILL.md) - Skill 概述和快速开始

## 官方文档

完整的 API 文档请访问：
- https://api.immich.app/
- 或在你的 Immich 服务器上访问：`{server_url}/api/docs`
