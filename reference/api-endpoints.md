# Immich API 端点参考

本文档提供 Immich API 关键端点的快速参考。

## 基础信息

- **基础 URL**: `{server_url}/api`
- **认证方式**: HTTP 头部 `x-api-key: YOUR_API_KEY`
- **请求格式**: JSON（资源上传使用 multipart/form-data）
- **响应格式**: JSON

## 相册操作端点

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
    "owner": {...},
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
]
```

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

### 获取相册详情

```
GET /api/albums/{id}
```

**所需权限**: `album.read`

**URL 参数**:
- `id`: 相册 ID

**响应**: 返回相册详情，包含 `assets` 数组（相册中的所有资源）。

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

### 删除相册

```
DELETE /api/albums/{id}
```

**所需权限**: `album.write`

**URL 参数**:
- `id`: 相册 ID

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

## 资源操作端点

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

### 搜索资源（元数据）

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
  "tags": ["vacation", "beach"]
}
```

**响应**:
```json
{
  "assets": {
    "count": 100,
    "items": [...]
  }
}
```

### 智能搜索（CLIP）

```
POST /api/search/smart
```

**所需权限**: `asset.read`

**请求体**:
```json
{
  "query": "beach sunset with people",
  "limit": 20
}
```

**响应**: 返回匹配的资源列表。

### 获取资源信息

```
GET /api/assets/{id}
```

**所需权限**: `asset.read`

**URL 参数**:
- `id`: 资源 ID

**响应**: 返回资源详细信息，包含 EXIF 数据。

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

### 删除资源

```
DELETE /api/assets/{id}
```

**所需权限**: `asset.delete`

**URL 参数**:
- `id`: 资源 ID

### 下载资源原图

```
GET /api/assets/{id}/original
```

**所需权限**: `asset.read`

**URL 参数**:
- `id`: 资源 ID

**响应**: 返回文件二进制数据。

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

## 服务器信息端点

### 获取服务器版本

```
GET /api/server-info/version
```

**所需权限**: 无（公开端点）

**响应**:
```json
{
  "major": 1,
  "minor": 90,
  "patch": 0
}
```

### 获取服务器配置

```
GET /api/server-info/config
```

**所需权限**: 需要认证

**响应**: 返回服务器配置信息。

## 用户端点

### 获取当前用户信息

```
GET /api/users/me
```

**所需权限**: 需要认证

**响应**: 返回当前用户信息。

## 搜索查询参数

### 元数据搜索支持的字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `takenAfter` | string | 拍摄时间起始（ISO 8601） |
| `takenBefore` | string | 拍摄时间结束（ISO 8601） |
| `type` | string | 文件类型（IMAGE, VIDEO） |
| `isFavorite` | boolean | 是否收藏 |
| `isArchived` | boolean | 是否归档 |
| `city` | string | 城市 |
| `state` | string | 省/州 |
| `country` | string | 国家 |
| `make` | string | 相机品牌 |
| `model` | string | 相机型号 |
| `lensModel` | string | 镜头型号 |
| `tags` | array | 标签列表 |

### 日期格式

所有日期时间字段使用 ISO 8601 格式：

```
YYYY-MM-DDTHH:mm:ss.SSSZ
```

示例：
- `2024-01-01T00:00:00.000Z` - 2024年1月1日 00:00:00 UTC
- `2024-12-31T23:59:59.999Z` - 2024年12月31日 23:59:59 UTC

## HTTP 状态码

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

## 错误响应格式

```json
{
  "statusCode": 400,
  "message": "错误描述",
  "error": "Bad Request"
}
```

## 分页

某些端点支持分页参数：

- `page`: 页码（从 1 开始）
- `size`: 每页数量

示例：
```
GET /api/assets?page=1&size=50
```

## 速率限制

Immich API 可能有速率限制，具体限制取决于服务器配置。建议：

- 批量操作时添加适当延迟
- 使用批量端点而不是循环调用单个端点
- 监控响应头中的速率限制信息

## 官方文档

完整的 API 文档请访问：https://api.immich.app/

或在你的 Immich 服务器上访问：`{server_url}/api/docs`
