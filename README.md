# Claw-Immich Skill

一个用于 Claude Code 的 Immich 照片管理 API 集成 skill。

## 快速开始

### 1. 配置

首次使用前，运行配置向导：

```bash
bash ~/.claude/skills/claw-immich/scripts/setup.sh
```

你需要提供：
- **Immich 服务器地址**（例如：`https://immich.example.com`）
- **API 密钥**（从 Immich Web 界面生成）

### 2. 使用方式

#### 在 Claude Code 中使用

直接与 Claude 对话：

```
"列出我的 Immich 相册"
"上传照片到 Immich"
"搜索最近一个月的照片"
```

#### 在脚本中使用

```bash
# 加载 API 函数
source ~/.claude/skills/claw-immich/scripts/immich-api.sh
source ~/.claude/skills/claw-immich/scripts/utils.sh

# 列出所有相册
albums=$(list_albums)
format_album_list "$albums"

# 创建新相册
album_response=$(create_album "我的相册" "相册描述")
album_id=$(echo "$album_response" | jq -r '.id')

# 上传照片
upload_asset "/path/to/photo.jpg"

# 搜索照片
query='{"type":"IMAGE","takenAfter":"2024-01-01T00:00:00.000Z"}'
search_assets "$query"
```

## 主要功能

### 相册管理
- ✓ 列出所有相册
- ✓ 创建新相册
- ✓ 查看相册详情
- ✓ 更新相册信息
- ✓ 删除相册
- ✓ 添加/移除相册中的照片

### 资源管理
- ✓ 上传照片和视频
- ✓ 查看资源详情（包含 EXIF 信息）
- ✓ 更新资源元数据
- ✓ 下载资源
- ✓ 删除资源

### 搜索功能
- ✓ 按日期范围搜索
- ✓ 按文件类型搜索
- ✓ 按位置搜索（城市、国家）
- ✓ 按相机设备搜索
- ✓ 按收藏状态搜索
- ✓ 智能搜索（CLIP AI）
- ✓ 多条件组合搜索

## 目录结构

```
~/.claude/skills/claw-immich/
├── SKILL.md                          # Skill 定义和完整文档
├── README.md                         # 本文件
├── config/
│   ├── config.json                   # 用户配置（首次运行 setup.sh 后生成）
│   └── config.template.json          # 配置模板
├── scripts/
│   ├── immich-api.sh                 # 核心 API 函数库
│   ├── setup.sh                      # 配置向导
│   └── utils.sh                      # 辅助工具函数
├── reference/
│   ├── api-endpoints.md              # API 端点完整参考
│   └── authentication.md             # 认证设置详细指南
└── examples/
    ├── album-operations.sh           # 相册操作示例
    ├── asset-operations.sh           # 资源操作示例
    └── search-operations.sh          # 搜索功能示例
```

## 运行示例

学习如何使用各种功能：

```bash
# 相册管理示例
bash ~/.claude/skills/claw-immich/examples/album-operations.sh

# 资源操作示例
bash ~/.claude/skills/claw-immich/examples/asset-operations.sh

# 搜索功能示例
bash ~/.claude/skills/claw-immich/examples/search-operations.sh
```

## 文档

- **SKILL.md** - 完整的 skill 文档和使用说明
- **reference/api-endpoints.md** - API 端点参考
- **reference/authentication.md** - 认证设置指南

## 常见问题

### Q: 如何生成 API 密钥？

1. 登录 Immich Web 界面
2. 进入 **设置** → **API 密钥**
3. 点击 **创建 API 密钥**
4. 复制生成的密钥

详细说明请查看 `reference/authentication.md`

### Q: 需要什么权限？

建议授予以下权限：
- `album.read` - 读取相册
- `album.write` - 创建和修改相册
- `asset.read` - 读取资源
- `asset.upload` - 上传资源
- `asset.write` - 修改资源
- `asset.delete` - 删除资源（可选）

### Q: 配置文件在哪里？

配置文件位于：`~/.claude/skills/claw-immich/config/config.json`

如需重新配置，运行：
```bash
bash ~/.claude/skills/claw-immich/scripts/setup.sh
```

### Q: 支持哪些文件格式？

支持 Immich 支持的所有格式：
- **图片**: JPEG, PNG, GIF, WEBP, HEIC, TIFF, DNG, RAW 等
- **视频**: MP4, MOV, AVI, MKV, WEBM 等

### Q: 如何测试连接？

```bash
source ~/.claude/skills/claw-immich/scripts/immich-api.sh
test_connection
```

## 故障排除

### 连接错误

检查：
1. 服务器地址是否正确
2. 服务器是否正在运行
3. 网络连接是否正常
4. 防火墙设置

### 认证失败

检查：
1. API 密钥是否正确
2. API 密钥是否已过期或被撤销
3. API 密钥是否有所需权限

### 需要安装 jq

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq
```

## 安全建议

1. **保护配置文件** - 配置文件包含 API 密钥，权限已设置为 600
2. **使用 HTTPS** - 生产环境务必使用 HTTPS 连接
3. **定期轮换密钥** - 建议每 3-6 个月更换 API 密钥
4. **最小权限原则** - 只授予所需的最小权限
5. **独立密钥** - 为不同用途创建独立的 API 密钥

## 技术实现

- **语言**: Pure Bash
- **依赖**: curl, jq
- **API**: Immich REST API
- **认证**: API Key (x-api-key 头部)
- **格式**: JSON

## 版本信息

- **版本**: 1.0.0
- **发布日期**: 2026-02-10
- **兼容性**: Immich v1.90.0+

## 相关资源

- [Immich 官方网站](https://immich.app/)
- [Immich API 文档](https://api.immich.app/)
- [Immich GitHub](https://github.com/immich-app/immich)
- [Claude Code 文档](https://github.com/anthropics/claude-code)

## 许可证

MIT License

---

**需要帮助？** 查看 `SKILL.md` 获取完整文档，或运行示例脚本学习具体用法。
