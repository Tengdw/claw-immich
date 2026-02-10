# Claw-Immich Skill - 项目说明

这是一个 Claude Code skill，用于与 Immich 照片管理 API 集成。

## 项目概述

**类型**: Claude Code Skill
**语言**: Bash
**依赖**: curl, jq
**用途**: Immich API 集成，提供相册管理、资源上传和搜索功能

## 项目结构

```
claw-immich/
├── SKILL.md                    # Skill 定义（Claude 读取）
├── README.md                   # 用户文档
├── CLAUDE.md                   # 本文件（开发指南）
├── config/
│   ├── config.json            # 用户配置（不纳入版本控制）
│   └── config.template.json   # 配置模板
├── scripts/
│   ├── immich-api.sh          # 核心 API 封装
│   ├── setup.sh               # 配置向导
│   └── utils.sh               # 工具函数
├── reference/
│   ├── api-endpoints.md       # API 参考
│   └── authentication.md      # 认证指南
└── examples/
    ├── album-operations.sh    # 相册操作示例
    ├── asset-operations.sh    # 资源操作示例
    └── search-operations.sh   # 搜索功能示例
```

## 开发原则

### 代码规范

1. **Shell 脚本**
   - 使用 `#!/bin/bash` shebang
   - 启用错误检查（根据需要使用 `set -e`）
   - 函数名使用 snake_case
   - 变量名使用小写，常量使用大写
   - 使用中文注释

2. **API 封装**
   - 所有 API 调用通过 `immich_api_request()` 统一处理
   - 返回原始 JSON，由调用者处理
   - 错误信息输出到 stderr
   - 成功返回 0，失败返回 1

3. **文档**
   - SKILL.md: 中文，面向 Claude
   - README.md: 中文，面向用户
   - reference/: 中文，详细技术文档
   - 代码注释: 中文

### 安全考虑

1. **配置文件保护**
   - config.json 设置为 600 权限
   - config.json 已在 .gitignore 中排除
   - 从不在日志中输出 API 密钥

2. **API 密钥管理**
   - 通过 setup.sh 向导配置
   - 存储在用户家目录
   - 建议为每个用途创建独立密钥

3. **HTTPS 优先**
   - 远程服务器必须使用 HTTPS
   - 仅允许本地环境使用 HTTP

## 修改指南

### 添加新的 API 端点

1. 在 `scripts/immich-api.sh` 中添加函数：
```bash
# 功能描述
# API 端点: METHOD /api/path
# 参数: param1 [param2]
function_name() {
    local param1="$1"
    local param2="${2:-default}"

    # 参数验证
    if [[ -z "$param1" ]]; then
        echo "错误: 参数不能为空" >&2
        return 1
    fi

    # 构建请求数据
    local data=$(jq -n --arg p1 "$param1" '{field: $p1}')

    # 调用 API
    immich_api_request "METHOD" "/api/path" "$data"
}
```

2. 在 `SKILL.md` 中添加文档
3. 在 `reference/api-endpoints.md` 中添加端点说明
4. 在 `examples/` 中添加使用示例

### 添加工具函数

在 `scripts/utils.sh` 中添加通用工具函数：
```bash
# 功能描述
# 参数: param1
function_name() {
    local param1="$1"
    # 实现
}
```

### 更新文档

- **SKILL.md**: Claude 读取，需要包含完整的使用说明
- **README.md**: 用户快速入门指南
- **reference/**: 详细的技术参考文档

## 测试

### 语法检查

```bash
# 检查所有脚本语法
for script in scripts/*.sh examples/*.sh; do
    bash -n "$script" && echo "✓ $script" || echo "✗ $script"
done
```

### 功能测试

```bash
# 运行示例脚本
bash examples/album-operations.sh
bash examples/asset-operations.sh
bash examples/search-operations.sh
```

### 单元测试（未来）

考虑添加单元测试框架（如 bats）：
```bash
# 安装 bats
brew install bats-core

# 运行测试
bats tests/
```

## API 参考

### Immich API

- **官方文档**: https://api.immich.app/
- **认证方式**: x-api-key 头部
- **基础 URL**: {server_url}/api
- **格式**: JSON

### 核心函数

#### immich_api_request(method, endpoint, data, content_type)
通用 API 请求封装

#### load_config()
加载配置文件，设置全局变量

#### list_albums()
列出所有相册

#### create_album(name, description)
创建新相册

#### upload_asset(file_path, device_id)
上传照片或视频

#### search_assets(query_json)
搜索资源

更多函数请参阅 `scripts/immich-api.sh`

## 发布流程

### 版本号规范

使用语义化版本：`MAJOR.MINOR.PATCH`

- MAJOR: 不兼容的 API 修改
- MINOR: 向下兼容的功能新增
- PATCH: 向下兼容的问题修正

### 发布检查清单

- [ ] 所有脚本通过语法检查
- [ ] 示例脚本可以正常运行
- [ ] 文档已更新
- [ ] SKILL.md 中的版本号已更新
- [ ] README.md 中的版本号已更新
- [ ] 创建 Git 标签
- [ ] 推送到 GitHub
- [ ] 创建 GitHub Release

### 发布命令

```bash
# 1. 更新版本号（在 SKILL.md 和 README.md 中）

# 2. 提交更改
git add .
git commit -m "chore: bump version to v1.1.0"

# 3. 创建标签
git tag -a v1.1.0 -m "Release v1.1.0"

# 4. 推送
git push origin main --tags
```

## 常见问题

### Q: 如何调试 API 调用？

设置 DEBUG 环境变量：
```bash
DEBUG=1 bash examples/album-operations.sh
```

### Q: 如何测试不同的 Immich 版本？

修改 config.json 中的 server_url 指向不同的测试服务器。

### Q: 如何贡献代码？

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/new-feature`
3. 提交更改：`git commit -m "feat: add new feature"`
4. 推送分支：`git push origin feature/new-feature`
5. 创建 Pull Request

## 技术债务和改进计划

### 短期（v1.1）

- [ ] 添加批量上传进度显示
- [ ] 支持从相册下载所有照片
- [ ] 添加资源标签管理功能
- [ ] 改进错误处理和重试机制

### 中期（v1.2）

- [ ] 添加配置文件验证
- [ ] 支持多个 Immich 服务器配置
- [ ] 添加本地缓存机制
- [ ] 实现增量同步功能

### 长期（v2.0）

- [ ] 支持人脸识别 API
- [ ] 集成机器学习标签
- [ ] 添加自动化工作流
- [ ] Web UI 配置界面

## 相关资源

- **Immich**: https://immich.app/
- **Immich GitHub**: https://github.com/immich-app/immich
- **Claude Code**: https://github.com/anthropics/claude-code
- **Bash 最佳实践**: https://google.github.io/styleguide/shellguide.html

## 许可证

MIT License - 详见 LICENSE 文件

## 维护者

- 主要开发: @Tengdw
- AI 协助: Claude Sonnet 4.5

## 更新日志

### v1.0.0 (2026-02-10)

- 初始发布
- 完整的相册管理功能
- 资源上传和搜索
- 中文文档和示例
- 配置向导

---

**注意**: 本文件是为 Claude Code 准备的开发指南。用户文档请参阅 README.md。
