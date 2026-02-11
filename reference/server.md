# 服务器信息 API

本文档详细介绍 Immich 服务器信息查询相关的所有 API 端点。

## 概述

服务器信息 API 提供了查询 Immich 服务器状态、配置、统计和版本等信息的功能。这些端点主要用于监控、管理和了解服务器状态。

**基础 URL**: `{server_url}/api/server`

## API 端点

### Ping 服务器

```
GET /api/server/ping
```

**所需权限**: 无（公开端点）

**用途**: 快速检测服务器是否在线。

**响应**:
```json
{
  "res": "pong"
}
```

**Shell 函数**:
```bash
ping_server
```

**示例**:
```bash
# 健康检查
if ping_server >/dev/null 2>&1; then
    echo "✓ 服务器在线"
else
    echo "✗ 服务器离线"
fi
```

---

### 获取服务器版本

```
GET /api/server/version
```

**所需权限**: 无（公开端点）

**响应**:
```json
{
  "major": 1,
  "minor": 137,
  "patch": 0
}
```

**Shell 函数**:
```bash
get_server_version
```

**示例**:
```bash
version=$(get_server_version)
ver_string=$(echo "$version" | jq -r '"\(.major).\(.minor).\(.patch)"')
echo "服务器版本: v$ver_string"
```

---

### 获取服务器基本信息

```
GET /api/server/about
```

**所需权限**: 需要认证

**响应**:
```json
{
  "version": "v1.137.0",
  "versionUrl": "https://github.com/immich-app/immich/releases/tag/v1.137.0",
  "diskAvailable": "500 GB",
  "diskSize": "1 TB",
  "diskUsagePercentage": 50.0,
  "diskAvailableRaw": 500000000000,
  "diskSizeRaw": 1000000000000,
  "diskUsagePercentageRaw": 50.0,
  "installed": true,
  "machineType": "x86_64",
  "numCores": 8,
  "totalMemory": "16 GB"
}
```

**Shell 函数**:
```bash
get_about_info
```

---

### 获取服务器配置

```
GET /api/server/config
```

**所需权限**: 需要认证

**响应**: 返回服务器公开配置信息。

```json
{
  "loginPageMessage": "",
  "oauthButtonText": "Login with OAuth",
  "mapTileUrl": "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
  "trashDays": 30,
  "userDeleteDelay": 7
}
```

**Shell 函数**:
```bash
get_server_config
```

---

### 获取服务器功能

```
GET /api/server/features
```

**所需权限**: 需要认证

**响应**: 返回服务器支持的功能列表。

```json
{
  "smartSearch": true,
  "facialRecognition": true,
  "map": true,
  "reverseGeocoding": true,
  "sidecar": true,
  "search": true,
  "trash": true,
  "oauth": false,
  "oauthAutoLaunch": false,
  "passwordLogin": true,
  "configFile": false,
  "email": false
}
```

**Shell 函数**:
```bash
get_server_features
```

**示例**:
```bash
features=$(get_server_features)

# 检查智能搜索是否可用
if [[ $(echo "$features" | jq -r '.smartSearch') == "true" ]]; then
    echo "✓ 智能搜索可用"
else
    echo "✗ 智能搜索不可用"
fi
```

---

### 获取服务器统计信息

```
GET /api/server/statistics
```

**所需权限**: 需要认证

**响应**:
```json
{
  "photos": 1234,
  "videos": 567,
  "usage": 107374182400,
  "usageByUser": [
    {
      "userId": "user-uuid",
      "userName": "用户名",
      "photos": 100,
      "videos": 50,
      "usage": 10737418240
    }
  ]
}
```

**Shell 函数**:
```bash
get_server_statistics
```

**示例**:
```bash
stats=$(get_server_statistics)
photos=$(echo "$stats" | jq -r '.photos')
videos=$(echo "$stats" | jq -r '.videos')
total=$((photos + videos))

echo "服务器统计:"
echo "  照片: $photos"
echo "  视频: $videos"
echo "  总计: $total"
```

---

### 获取存储信息

```
GET /api/server/storage
```

**所需权限**: 需要认证（管理员）

**响应**: 返回详细的存储使用情况。

**Shell 函数**:
```bash
get_storage
```

---

### 获取支持的媒体类型

```
GET /api/server/media-types
```

**所需权限**: 无（公开端点）

**响应**:
```json
{
  "video": [".mp4", ".mov", ".avi", ".webm", ".flv", ".mkv"],
  "image": [".jpg", ".jpeg", ".png", ".gif", ".webp", ".heic", ".heif", ".tiff", ".dng"],
  "sidecar": [".xmp"]
}
```

**Shell 函数**:
```bash
get_supported_media_types
```

**示例**:
```bash
# 检查文件是否支持
media_types=$(get_supported_media_types)

check_file_supported() {
    local filename="$1"
    local ext="${filename##*.}"
    ext=".$ext"

    if echo "$media_types" | jq -e ".image | index(\"$ext\")" >/dev/null; then
        echo "✓ 支持的图片格式"
        return 0
    elif echo "$media_types" | jq -e ".video | index(\"$ext\")" >/dev/null; then
        echo "✓ 支持的视频格式"
        return 0
    else
        echo "✗ 不支持的格式"
        return 1
    fi
}

check_file_supported "photo.heic"  # ✓ 支持的图片格式
check_file_supported "video.mp4"   # ✓ 支持的视频格式
```

---

### 获取服务器主题

```
GET /api/server/theme
```

**所需权限**: 无（公开端点）

**响应**: 返回服务器主题配置。

**Shell 函数**:
```bash
get_theme
```

---

### 检查版本更新

```
GET /api/server/version-check
```

**所需权限**: 需要认证

**响应**:
```json
{
  "checkedAt": "2024-01-01T00:00:00.000Z",
  "serverVersion": {
    "major": 1,
    "minor": 137,
    "patch": 0
  },
  "releaseVersion": {
    "major": 1,
    "minor": 140,
    "patch": 0
  },
  "isAvailable": true
}
```

**Shell 函数**:
```bash
get_version_check
```

**示例**:
```bash
check=$(get_version_check)
is_available=$(echo "$check" | jq -r '.isAvailable')

if [[ "$is_available" == "true" ]]; then
    current=$(echo "$check" | jq -r '.serverVersion | "\(.major).\(.minor).\(.patch)"')
    latest=$(echo "$check" | jq -r '.releaseVersion | "\(.major).\(.minor).\(.patch)"')

    echo "⚠ 有新版本可用"
    echo "  当前版本: v$current"
    echo "  最新版本: v$latest"
else
    echo "✓ 当前已是最新版本"
fi
```

---

### 获取版本历史

```
GET /api/server/version-history
```

**所需权限**: 需要认证

**响应**: 返回版本更新历史记录。

**Shell 函数**:
```bash
get_version_history
```

---

### 获取 APK 下载链接

```
GET /api/server/apk-links
```

**所需权限**: 无（公开端点）

**响应**:
```json
{
  "apkLinks": [
    {
      "version": "v1.137.0",
      "url": "https://github.com/immich-app/immich/releases/download/v1.137.0/immich.apk"
    }
  ]
}
```

**Shell 函数**:
```bash
get_apk_links
```

---

### 许可证管理

#### 获取许可证信息

```
GET /api/server/license
```

**所需权限**: 需要认证（管理员）

**Shell 函数**:
```bash
get_server_license
```

---

#### 设置许可证

```
PUT /api/server/license
```

**所需权限**: 需要认证（管理员）

**请求体**:
```json
{
  "licenseKey": "YOUR-LICENSE-KEY",
  "activationKey": "YOUR-ACTIVATION-KEY"
}
```

**Shell 函数**:
```bash
set_server_license "license_key" "activation_key"
```

---

#### 删除许可证

```
DELETE /api/server/license
```

**所需权限**: 需要认证（管理员）

**Shell 函数**:
```bash
delete_server_license
```

---

## 使用场景

### 场景 1: 服务器健康检查

```bash
#!/bin/bash
source ~/.claude/skills/claw-immich/scripts/immich-api.sh

echo "Immich 服务器健康检查"
echo "======================"
echo ""

# 1. Ping 测试
echo "1. 连接测试..."
if ping_server >/dev/null 2>&1; then
    echo "   ✓ 服务器在线"
else
    echo "   ✗ 服务器离线"
    exit 1
fi

# 2. 版本信息
echo ""
echo "2. 版本信息..."
version=$(get_server_version)
if [[ $? -eq 0 ]]; then
    ver=$(echo "$version" | jq -r '"\(.major).\(.minor).\(.patch)"')
    echo "   服务器版本: v$ver"
fi

# 3. 系统资源
echo ""
echo "3. 系统资源..."
about=$(get_about_info)
if [[ $? -eq 0 ]]; then
    echo "$about" | jq -r '
        "   CPU 核心: \(.numCores)",
        "   总内存: \(.totalMemory)",
        "   磁盘总量: \(.diskSize)",
        "   可用空间: \(.diskAvailable)",
        "   使用率: \(.diskUsagePercentage)%"
    '
fi

# 4. 服务状态
echo ""
echo "4. 服务状态..."
stats=$(get_server_statistics)
if [[ $? -eq 0 ]]; then
    echo "$stats" | jq -r '
        "   照片总数: \(.photos)",
        "   视频总数: \(.videos)",
        "   存储使用: \(.usage / 1073741824 | floor) GB"
    '
fi

# 5. 功能状态
echo ""
echo "5. 功能状态..."
features=$(get_server_features)
if [[ $? -eq 0 ]]; then
    echo "$features" | jq -r '
        "   智能搜索: \(if .smartSearch then "✓" else "✗" end)",
        "   人脸识别: \(if .facialRecognition then "✓" else "✗" end)",
        "   地图功能: \(if .map then "✓" else "✗" end)"
    '
fi

echo ""
echo "健康检查完成"
```

### 场景 2: 自动更新检查

```bash
#!/bin/bash
# 定期检查并通知新版本

check_for_updates() {
    local check=$(get_version_check)

    if [[ $? -ne 0 ]]; then
        echo "无法检查更新"
        return 1
    fi

    local is_available=$(echo "$check" | jq -r '.isAvailable')

    if [[ "$is_available" == "true" ]]; then
        local current=$(echo "$check" | jq -r '.serverVersion | "\(.major).\(.minor).\(.patch)"')
        local latest=$(echo "$check" | jq -r '.releaseVersion | "\(.major).\(.minor).\(.patch)"')

        # 发送通知（示例使用 echo，实际可以使用邮件或其他通知方式）
        echo "========================================="
        echo "Immich 新版本可用！"
        echo "========================================="
        echo "当前版本: v$current"
        echo "最新版本: v$latest"
        echo ""
        echo "更新说明: $(echo "$check" | jq -r '.releaseUrl // "无"')"
        echo "========================================="

        return 0
    else
        echo "当前已是最新版本"
        return 1
    fi
}

# 运行检查
check_for_updates
```

### 场景 3: 存储监控

```bash
#!/bin/bash
# 监控存储使用情况并发出警告

THRESHOLD=80  # 使用率阈值（百分比）

monitor_storage() {
    local about=$(get_about_info)

    if [[ $? -ne 0 ]]; then
        echo "无法获取存储信息"
        return 1
    fi

    local usage=$(echo "$about" | jq -r '.diskUsagePercentage')
    local available=$(echo "$about" | jq -r '.diskAvailable')
    local total=$(echo "$about" | jq -r '.diskSize')

    echo "存储监控报告"
    echo "============"
    echo "磁盘总量: $total"
    echo "可用空间: $available"
    echo "使用率: $usage%"

    if (( $(echo "$usage >= $THRESHOLD" | bc -l) )); then
        echo ""
        echo "⚠ 警告: 存储使用率超过 ${THRESHOLD}%！"
        echo "建议清理不需要的文件或扩展存储空间。"
        return 1
    else
        echo ""
        echo "✓ 存储空间充足"
        return 0
    fi
}

monitor_storage
```

### 场景 4: 服务器信息仪表板

```bash
#!/bin/bash
# 生成服务器信息仪表板

generate_dashboard() {
    clear

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           Immich 服务器信息仪表板                         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # 版本信息
    version=$(get_server_version 2>/dev/null | jq -r '"\(.major).\(.minor).\(.patch)"')
    echo "服务器版本: v$version"
    echo ""

    # 系统信息
    about=$(get_about_info 2>/dev/null)
    if [[ -n "$about" ]]; then
        echo "系统信息:"
        echo "$about" | jq -r '
            "  机器类型: \(.machineType)",
            "  CPU 核心: \(.numCores)",
            "  总内存: \(.totalMemory)"
        '
        echo ""
    fi

    # 存储信息
    if [[ -n "$about" ]]; then
        echo "存储信息:"
        echo "$about" | jq -r '
            "  磁盘总量: \(.diskSize)",
            "  已用空间: \(.diskSize) - \(.diskAvailable)",
            "  可用空间: \(.diskAvailable)",
            "  使用率: \(.diskUsagePercentage)%"
        '
        echo ""

        # 绘制简单的进度条
        usage=$(echo "$about" | jq -r '.diskUsagePercentage | floor')
        bar_length=50
        filled=$((usage * bar_length / 100))
        empty=$((bar_length - filled))

        printf "  ["
        printf "%${filled}s" | tr ' ' '█'
        printf "%${empty}s" | tr ' ' '░'
        printf "] %d%%\n" "$usage"
        echo ""
    fi

    # 内容统计
    stats=$(get_server_statistics 2>/dev/null)
    if [[ -n "$stats" ]]; then
        echo "内容统计:"
        photos=$(echo "$stats" | jq -r '.photos')
        videos=$(echo "$stats" | jq -r '.videos')
        usage_gb=$(echo "$stats" | jq -r '(.usage / 1073741824) | floor')

        echo "  照片: $photos"
        echo "  视频: $videos"
        echo "  总计: $((photos + videos))"
        echo "  存储使用: ${usage_gb} GB"
        echo ""
    fi

    # 功能状态
    features=$(get_server_features 2>/dev/null)
    if [[ -n "$features" ]]; then
        echo "功能状态:"
        echo "$features" | jq -r '
            "  智能搜索: \(if .smartSearch then "✓ 已启用" else "✗ 未启用" end)",
            "  人脸识别: \(if .facialRecognition then "✓ 已启用" else "✗ 未启用" end)",
            "  地图功能: \(if .map then "✓ 已启用" else "✗ 未启用" end)",
            "  OAuth: \(if .oauth then "✓ 已启用" else "✗ 未启用" end)"
        '
        echo ""
    fi

    # 检查更新
    check=$(get_version_check 2>/dev/null)
    if [[ -n "$check" ]]; then
        is_available=$(echo "$check" | jq -r '.isAvailable')
        if [[ "$is_available" == "true" ]]; then
            latest=$(echo "$check" | jq -r '.releaseVersion | "v\(.major).\(.minor).\(.patch)"')
            echo "更新提示: ⚠ 新版本 $latest 可用"
        else
            echo "更新状态: ✓ 当前已是最新版本"
        fi
    fi

    echo ""
    echo "────────────────────────────────────────────────────────────"
    echo "刷新时间: $(date '+%Y-%m-%d %H:%M:%S')"
}

# 持续刷新仪表板（可选）
while true; do
    generate_dashboard
    read -t 60 -p "按回车刷新，或等待60秒自动刷新..." && continue
done
```

### 场景 5: 文件格式验证

```bash
# 批量验证文件是否支持上传
validate_files() {
    local dir="$1"
    local media_types=$(get_supported_media_types)

    echo "验证目录: $dir"
    echo ""

    local supported=0
    local unsupported=0

    for file in "$dir"/*; do
        [[ -f "$file" ]] || continue

        local filename=$(basename "$file")
        local ext=".${filename##*.}"

        if echo "$media_types" | jq -e ".image | index(\"$ext\")" >/dev/null 2>&1 || \
           echo "$media_types" | jq -e ".video | index(\"$ext\")" >/dev/null 2>&1; then
            echo "✓ $filename"
            ((supported++))
        else
            echo "✗ $filename (不支持的格式: $ext)"
            ((unsupported++))
        fi
    done

    echo ""
    echo "总计: $((supported + unsupported)) 个文件"
    echo "支持: $supported"
    echo "不支持: $unsupported"
}

# 使用示例
validate_files "$HOME/Pictures/Import"
```

## 监控建议

### 定期检查项

1. **每日检查**:
   - 服务器在线状态（ping）
   - 存储使用率
   - 备份状态

2. **每周检查**:
   - 版本更新
   - 系统资源使用
   - 内容统计变化

3. **每月检查**:
   - 功能状态
   - 许可证状态
   - 性能指标

### 自动化监控

```bash
# 添加到 crontab
# 每天 8:00 检查服务器状态
0 8 * * * /path/to/health-check.sh

# 每周一 9:00 检查更新
0 9 * * 1 /path/to/check-updates.sh

# 每小时检查存储
0 * * * * /path/to/monitor-storage.sh
```

## 注意事项

- 某些端点需要管理员权限（如许可证管理、存储信息）
- 频繁调用可能影响服务器性能，建议合理设置检查间隔
- 版本检查依赖于外部网络连接
- 统计信息可能有缓存，不是实时数据

## 相关文档

- [资源管理 API](./assets.md) - 了解如何管理上传的资源
- [搜索功能 API](./search.md) - 利用服务器功能进行搜索
