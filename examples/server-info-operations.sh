#!/bin/bash
# 服务器信息查询示例脚本
# 演示如何使用 Immich API 查询服务器状态和信息

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 加载 API 函数
source "$SKILL_DIR/scripts/immich-api.sh"

# 加载配置
load_config || exit 1

echo "================================================"
echo "Immich 服务器信息查询示例"
echo "================================================"
echo ""

# ============================================================================
# 1. Ping 服务器
# ============================================================================

echo "1. Ping 服务器..."
ping_result=$(ping_server)

if [[ $? -eq 0 ]]; then
    echo "✓ 服务器在线"
    echo "  响应: $ping_result"
else
    echo "✗ 服务器离线或无响应"
fi

echo ""

# ============================================================================
# 2. 获取服务器版本
# ============================================================================

echo "2. 获取服务器版本..."
version=$(get_server_version)

if [[ $? -eq 0 ]]; then
    major=$(echo "$version" | jq -r '.major')
    minor=$(echo "$version" | jq -r '.minor')
    patch=$(echo "$version" | jq -r '.patch')
    echo "✓ 服务器版本: v$major.$minor.$patch"
else
    echo "✗ 获取服务器版本失败"
fi

echo ""

# ============================================================================
# 3. 获取服务器基本信息
# ============================================================================

echo "3. 获取服务器基本信息..."
about_info=$(get_about_info)

if [[ $? -eq 0 ]]; then
    echo "✓ 服务器信息:"
    echo "$about_info" | jq -r '
        "  版本: \(.version)",
        "  机器类型: \(.machineType // "未知")",
        "  CPU 核心数: \(.numCores // "未知")",
        "  总内存: \(.totalMemory // "未知")",
        "  磁盘大小: \(.diskSize // "未知")",
        "  可用空间: \(.diskAvailable // "未知")",
        "  磁盘使用率: \(.diskUsagePercentage // 0)%"
    '
else
    echo "✗ 获取服务器信息失败"
fi

echo ""

# ============================================================================
# 4. 获取服务器功能
# ============================================================================

echo "4. 获取服务器功能..."
features=$(get_server_features)

if [[ $? -eq 0 ]]; then
    echo "✓ 服务器功能:"
    echo "$features" | jq -r 'to_entries | .[] | "  \(.key): \(if .value then "✓" else "✗" end)"'
else
    echo "✗ 获取服务器功能失败"
fi

echo ""

# ============================================================================
# 5. 获取服务器配置
# ============================================================================

echo "5. 获取服务器配置..."
config=$(get_server_config)

if [[ $? -eq 0 ]]; then
    echo "✓ 服务器配置:"
    echo "$config" | jq -r '
        if .loginPageMessage and .loginPageMessage != "" then
            "  登录页消息: \(.loginPageMessage)"
        else
            "  登录页消息: 未设置"
        end,
        if .oauthButtonText then
            "  OAuth 按钮文本: \(.oauthButtonText)"
        else
            empty
        end,
        if .mapTileUrl then
            "  地图服务: \(.mapTileUrl)"
        else
            empty
        end
    '
else
    echo "✗ 获取服务器配置失败"
fi

echo ""

# ============================================================================
# 6. 获取服务器统计信息
# ============================================================================

echo "6. 获取服务器统计信息..."
stats=$(get_server_statistics)

if [[ $? -eq 0 ]]; then
    photos=$(echo "$stats" | jq -r '.photos // 0')
    videos=$(echo "$stats" | jq -r '.videos // 0')
    usage=$(echo "$stats" | jq -r '.usage // 0')

    # 转换字节为可读格式
    if command -v numfmt &> /dev/null; then
        usage_readable=$(numfmt --to=iec-i --suffix=B $usage)
    else
        usage_readable="$usage bytes"
    fi

    echo "✓ 服务器统计:"
    echo "  照片数量: $photos"
    echo "  视频数量: $videos"
    echo "  总使用量: $usage_readable"

    # 显示用户统计
    user_count=$(echo "$stats" | jq '.usageByUser | length')
    if [[ $user_count -gt 0 ]]; then
        echo ""
        echo "  用户统计:"
        echo "$stats" | jq -r '.usageByUser[] | "    - \(.userName): \(.photos) 张照片, \(.videos) 个视频"'
    fi
else
    echo "✗ 获取服务器统计失败"
fi

echo ""

# ============================================================================
# 7. 获取存储信息
# ============================================================================

echo "7. 获取存储信息..."
storage=$(get_storage)

if [[ $? -eq 0 ]]; then
    echo "✓ 存储信息:"
    echo "$storage" | jq '.'
else
    echo "✗ 获取存储信息失败"
fi

echo ""

# ============================================================================
# 8. 获取支持的媒体类型
# ============================================================================

echo "8. 获取支持的媒体类型..."
media_types=$(get_supported_media_types)

if [[ $? -eq 0 ]]; then
    echo "✓ 支持的媒体类型:"

    # 显示图片格式
    image_formats=$(echo "$media_types" | jq -r '.image // [] | join(", ")')
    if [[ -n "$image_formats" && "$image_formats" != "null" ]]; then
        echo "  图片格式: $image_formats"
    fi

    # 显示视频格式
    video_formats=$(echo "$media_types" | jq -r '.video // [] | join(", ")')
    if [[ -n "$video_formats" && "$video_formats" != "null" ]]; then
        echo "  视频格式: $video_formats"
    fi

    # 显示 sidecar 格式
    sidecar_formats=$(echo "$media_types" | jq -r '.sidecar // [] | join(", ")')
    if [[ -n "$sidecar_formats" && "$sidecar_formats" != "null" ]]; then
        echo "  Sidecar 格式: $sidecar_formats"
    fi
else
    echo "✗ 获取支持的媒体类型失败"
fi

echo ""

# ============================================================================
# 9. 获取服务器主题
# ============================================================================

echo "9. 获取服务器主题..."
theme=$(get_theme)

if [[ $? -eq 0 ]]; then
    echo "✓ 服务器主题:"
    echo "$theme" | jq '.'
else
    echo "✗ 获取服务器主题失败"
fi

echo ""

# ============================================================================
# 10. 检查版本更新
# ============================================================================

echo "10. 检查版本更新..."
version_check=$(get_version_check)

if [[ $? -eq 0 ]]; then
    is_available=$(echo "$version_check" | jq -r '.isAvailable // false')

    if [[ "$is_available" == "true" ]]; then
        server_ver=$(echo "$version_check" | jq -r '.serverVersion | "\(.major).\(.minor).\(.patch)"')
        release_ver=$(echo "$version_check" | jq -r '.releaseVersion | "\(.major).\(.minor).\(.patch)"')
        echo "✓ 有新版本可用"
        echo "  当前版本: v$server_ver"
        echo "  最新版本: v$release_ver"
    else
        echo "✓ 当前已是最新版本"
    fi
else
    echo "✗ 检查版本更新失败"
fi

echo ""

# ============================================================================
# 11. 获取版本历史
# ============================================================================

echo "11. 获取版本历史..."
version_history=$(get_version_history)

if [[ $? -eq 0 ]]; then
    echo "✓ 版本历史:"
    echo "$version_history" | jq '.'
else
    echo "✗ 获取版本历史失败"
fi

echo ""

# ============================================================================
# 12. 获取 APK 下载链接（如果可用）
# ============================================================================

echo "12. 获取 Android APK 下载链接..."
apk_links=$(get_apk_links)

if [[ $? -eq 0 ]]; then
    link_count=$(echo "$apk_links" | jq '.apkLinks // [] | length')

    if [[ $link_count -gt 0 ]]; then
        echo "✓ 找到 $link_count 个 APK 下载链接:"
        echo "$apk_links" | jq -r '.apkLinks[] | "  版本 \(.version): \(.url)"'
    else
        echo "✓ 当前没有可用的 APK 下载链接"
    fi
else
    echo "✗ 获取 APK 下载链接失败"
fi

echo ""

# ============================================================================
# 13. 许可证信息（需要管理员权限）
# ============================================================================

echo "13. 获取许可证信息（需要管理员权限）..."
license=$(get_server_license 2>/dev/null)

if [[ $? -eq 0 ]]; then
    echo "✓ 许可证信息:"
    echo "$license" | jq '.'
else
    echo "ℹ 无法获取许可证信息（可能需要管理员权限或服务器未配置许可证）"
fi

echo ""

# ============================================================================
# 总结
# ============================================================================

echo "================================================"
echo "服务器信息总结"
echo "================================================"

# 重新获取关键信息以生成总结
summary_version=$(get_server_version 2>/dev/null | jq -r '"\(.major).\(.minor).\(.patch)"')
summary_stats=$(get_server_statistics 2>/dev/null)
summary_features=$(get_server_features 2>/dev/null)

if [[ -n "$summary_version" && "$summary_version" != "null" ]]; then
    echo "服务器版本: v$summary_version"
fi

if [[ -n "$summary_stats" ]]; then
    total_photos=$(echo "$summary_stats" | jq -r '.photos // 0')
    total_videos=$(echo "$summary_stats" | jq -r '.videos // 0')
    total_assets=$((total_photos + total_videos))
    echo "资源总数: $total_assets ($total_photos 张照片, $total_videos 个视频)"
fi

if [[ -n "$summary_features" ]]; then
    smart_search=$(echo "$summary_features" | jq -r '.smartSearch // false')
    facial_recognition=$(echo "$summary_features" | jq -r '.facialRecognition // false')

    echo ""
    echo "主要功能:"
    if [[ "$smart_search" == "true" ]]; then
        echo "  ✓ 智能搜索已启用"
    else
        echo "  ✗ 智能搜索未启用"
    fi

    if [[ "$facial_recognition" == "true" ]]; then
        echo "  ✓ 人脸识别已启用"
    else
        echo "  ✗ 人脸识别未启用"
    fi
fi

echo ""
echo "================================================"
echo "服务器信息查询示例完成"
echo "================================================"
