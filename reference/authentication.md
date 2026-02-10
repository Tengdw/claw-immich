# Immich API 认证设置指南

本文档详细说明如何为 Claw-Immich skill 配置认证。

## 认证方式

Immich API 使用 API 密钥进行认证。每个请求都需要在 HTTP 头部包含：

```
x-api-key: YOUR_API_KEY
```

## 生成 API 密钥

### 步骤 1: 登录 Immich Web 界面

在浏览器中打开你的 Immich 服务器地址，使用你的账号登录。

例如：
- `http://localhost:2283`（本地部署）
- `https://immich.example.com`（远程服务器）

### 步骤 2: 进入 API 密钥管理

1. 点击右上角的用户头像
2. 选择 **设置**（Settings）
3. 在左侧菜单中选择 **API 密钥**（API Keys）

或直接访问：`{server_url}/user-settings?isOpen=api-keys`

### 步骤 3: 创建新的 API 密钥

1. 点击 **创建 API 密钥**（New API Key）按钮
2. 为密钥输入一个有意义的名称，例如：
   - `claude-code`
   - `claw-immich-skill`
   - `automation-bot`

### 步骤 4: 选择权限

根据你的需求选择权限。建议的权限配置：

#### 完整权限（推荐用于个人使用）
- ✓ `album.read` - 读取相册信息
- ✓ `album.write` - 创建和修改相册
- ✓ `asset.read` - 读取资源信息
- ✓ `asset.upload` - 上传新资源
- ✓ `asset.write` - 修改资源信息
- ✓ `asset.delete` - 删除资源

#### 只读权限（用于查看和搜索）
- ✓ `album.read` - 读取相册信息
- ✓ `asset.read` - 读取资源信息

#### 上传专用权限
- ✓ `album.read` - 读取相册信息
- ✓ `album.write` - 创建相册
- ✓ `asset.upload` - 上传新资源

### 步骤 5: 复制 API 密钥

1. 点击 **创建**（Create）按钮
2. **重要**: API 密钥只会显示一次，请立即复制并保存
3. 点击 **复制**（Copy）按钮或手动选择并复制密钥

示例密钥格式：
```
immich_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## 配置 Claw-Immich

### 方法 1: 使用配置向导（推荐）

运行配置向导脚本：

```bash
bash ~/.claude/skills/claw-immich/scripts/setup.sh
```

按照提示输入：
1. **服务器地址**: 例如 `https://immich.example.com`
2. **API 密钥**: 粘贴你刚才复制的密钥

配置向导会自动：
- 验证服务器连接
- 测试 API 密钥有效性
- 创建配置文件
- 设置安全权限

### 方法 2: 手动创建配置文件

如果需要手动配置，创建文件：`~/.claude/skills/claw-immich/config/config.json`

```json
{
  "server_url": "https://immich.example.com",
  "api_key": "immich_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "default_device_id": "claude-code",
  "preferences": {
    "max_upload_size_mb": 100,
    "default_output_format": "json",
    "pagination_limit": 50
  }
}
```

设置文件权限（仅所有者可读写）：

```bash
chmod 600 ~/.claude/skills/claw-immich/config/config.json
```

## 验证配置

### 测试连接

使用以下命令测试配置是否正确：

```bash
source ~/.claude/skills/claw-immich/scripts/immich-api.sh
test_connection
```

成功输出示例：
```
正在测试连接到 https://immich.example.com ...
✓ 连接成功
服务器版本: 1.90.0
```

### 使用 curl 直接测试

你也可以使用 curl 命令直接测试 API 连接：

```bash
curl -H "x-api-key: YOUR_API_KEY" \
     https://immich.example.com/api/server-info/version
```

成功响应：
```json
{
  "major": 1,
  "minor": 90,
  "patch": 0
}
```

失败响应（401 未授权）：
```json
{
  "statusCode": 401,
  "message": "Unauthorized",
  "error": "Unauthorized"
}
```

## 安全最佳实践

### 1. 使用独立的 API 密钥

为不同的应用或用途创建独立的 API 密钥：
- 便于追踪使用情况
- 可以单独撤销而不影响其他应用
- 减少密钥泄露的影响范围

### 2. 最小权限原则

只授予所需的最小权限：
- 如果只需要查看照片，不要授予 `write` 或 `delete` 权限
- 自动化脚本应该使用受限的权限
- 定期审查和调整权限

### 3. 定期轮换密钥

建议定期更换 API 密钥（例如每 3-6 个月）：
1. 创建新的 API 密钥
2. 更新配置文件
3. 测试新密钥是否工作
4. 撤销旧密钥

### 4. 保护配置文件

- 配置文件权限应设置为 `600`（仅所有者可读写）
- 不要将配置文件提交到版本控制系统
- 不要在公共场合分享配置文件
- 使用加密磁盘存储敏感配置

### 5. 使用 HTTPS

- 生产环境**必须**使用 HTTPS
- 仅在本地测试环境使用 HTTP
- 避免在公共 Wi-Fi 上使用 HTTP 连接

### 6. 监控 API 使用

定期检查 API 密钥的使用情况：
1. 在 Immich 设置中查看 API 密钥列表
2. 检查最后使用时间
3. 撤销长期未使用或可疑的密钥

## 常见问题

### Q: API 密钥丢失了怎么办？

A: API 密钥只在创建时显示一次，无法找回。你需要：
1. 撤销旧密钥
2. 创建新密钥
3. 更新配置文件

### Q: 如何撤销 API 密钥？

A: 在 Immich Web 界面中：
1. 进入 **设置** → **API 密钥**
2. 找到要撤销的密钥
3. 点击 **删除**（Delete）按钮

### Q: 一个账号可以创建多少个 API 密钥？

A: Immich 没有硬性限制，但建议保持在合理数量（5-10 个以内），便于管理。

### Q: API 密钥会过期吗？

A: 默认情况下 API 密钥不会过期，除非你手动撤销。某些 Immich 配置可能设置了过期时间。

### Q: 忘记配置了哪个服务器地址怎么办？

A: 查看配置文件：

```bash
cat ~/.claude/skills/claw-immich/config/config.json | jq -r .server_url
```

### Q: 如何更换 API 密钥？

A: 重新运行配置向导：

```bash
bash ~/.claude/skills/claw-immich/scripts/setup.sh
```

或直接编辑配置文件：

```bash
# 使用你喜欢的编辑器
nano ~/.claude/skills/claw-immich/config/config.json
# 或
code ~/.claude/skills/claw-immich/config/config.json
```

### Q: 多个设备可以共享同一个 API 密钥吗？

A: 可以，但不推荐。建议为每个设备创建独立的 API 密钥，便于管理和追踪。

## SSL/TLS 证书问题

### 自签名证书

如果你的 Immich 服务器使用自签名 SSL 证书，可能会遇到证书验证错误。

**不推荐的解决方案**（仅用于测试）：

修改 `immich-api.sh` 中的 curl 命令，添加 `-k` 参数：

```bash
curl -k -H "x-api-key: $api_key" ...
```

**推荐的解决方案**：

1. 使用 Let's Encrypt 等服务获取有效的 SSL 证书
2. 或将自签名证书添加到系统信任存储

### 证书过期

如果遇到证书过期错误：
1. 更新服务器的 SSL 证书
2. 或临时使用 HTTP（仅限本地网络）

## 故障排除

### 连接被拒绝

```
错误: 无法连接到 Immich 服务器
```

检查：
1. 服务器地址是否正确（包括 http:// 或 https://）
2. 服务器是否正在运行
3. 防火墙是否阻止了连接
4. 网络连接是否正常

### 认证失败

```
错误: HTTP 401
```

检查：
1. API 密钥是否正确
2. API 密钥是否已被撤销
3. API 密钥是否有所需权限

### 权限不足

```
错误: HTTP 403
```

检查：
1. API 密钥是否有执行此操作的权限
2. 在 Immich 中为 API 密钥添加所需权限

## 获取帮助

如果遇到问题：

1. 查看 SKILL.md 中的故障排除章节
2. 检查 Immich 服务器日志
3. 访问 Immich 官方文档：https://immich.app/docs
4. 访问 Immich GitHub：https://github.com/immich-app/immich

## 相关资源

- [Immich 官方文档](https://immich.app/docs)
- [Immich API 文档](https://api.immich.app/)
- [API 端点参考](./api-endpoints.md)
- [Claw-Immich Skill 文档](../SKILL.md)
