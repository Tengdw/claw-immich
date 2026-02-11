#!/bin/bash
# 共享链接操作示例脚本
# 演示如何使用 Immich API 创建和管理共享链接

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 加载 API 函数
source "$SKILL_DIR/scripts/immich-api.sh"

# 加载配置
load_config || exit 1

echo "================================================"
echo "Immich 共享链接操作示例"
echo "================================================"
echo ""

# ============================================================================
# 1. 获取所有共享链接
# ============================================================================

echo "1. 获取所有现有共享链接..."
all_links=$(get_all_shared_links)

if [[ $? -eq 0 ]]; then
    link_count=$(echo "$all_links" | jq '. | length')
    echo "✓ 找到 $link_count 个共享链接"

    if [[ $link_count -gt 0 ]]; then
        echo ""
        echo "现有共享链接："
        echo "$all_links" | jq -r '.[] | "  - \(.description // "无描述") (\(.type), key: \(.key))"'
    fi
else
    echo "✗ 获取共享链接失败"
fi

echo ""

# ============================================================================
# 2. 准备测试数据
# ============================================================================

echo "2. 准备测试数据..."

# 获取一些相册
albums=$(list_albums)
if [[ $? -eq 0 ]]; then
    album_count=$(echo "$albums" | jq '. | length')
    echo "✓ 找到 $album_count 个相册"

    if [[ $album_count -gt 0 ]]; then
        # 使用第一个相册
        test_album_id=$(echo "$albums" | jq -r '.[0].id')
        test_album_name=$(echo "$albums" | jq -r '.[0].albumName')
        echo "  将使用相册: $test_album_name (ID: $test_album_id)"
    else
        echo "  没有可用的相册，将创建一个测试相册"
        new_album=$(create_album "共享测试相册" "用于测试共享链接功能")
        if [[ $? -eq 0 ]]; then
            test_album_id=$(echo "$new_album" | jq -r '.id')
            echo "  ✓ 创建测试相册成功 (ID: $test_album_id)"
        else
            echo "  ✗ 创建测试相册失败"
            test_album_id=""
        fi
    fi
else
    echo "✗ 获取相册列表失败"
    test_album_id=""
fi

# 获取一些资源
search_result=$(search_assets '{"type": "IMAGE"}')
if [[ $? -eq 0 ]]; then
    asset_count=$(echo "$search_result" | jq '.assets.items | length')
    echo "✓ 找到 $asset_count 张照片"

    if [[ $asset_count -gt 0 ]]; then
        # 获取前 3 个资源
        test_asset_ids=($(echo "$search_result" | jq -r '.assets.items[0:3] | .[] | .id'))
        echo "  将使用 ${#test_asset_ids[@]} 张照片进行测试"
    fi
else
    echo "✗ 搜索资源失败"
    test_asset_ids=()
fi

echo ""

# ============================================================================
# 3. 创建相册共享链接
# ============================================================================

if [[ -n "$test_album_id" ]]; then
    echo "3. 创建相册共享链接..."

    # 计算 7 天后的过期时间
    expires_at=$(date -u -v+7d +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u -d "+7 days" +"%Y-%m-%dT%H:%M:%S.000Z")

    # 使用简单方式创建
    album_link=$(create_simple_shared_link "album" "$test_album_id" "分享的相册" "$expires_at" "true" "true")

    if [[ $? -eq 0 ]]; then
        album_link_id=$(echo "$album_link" | jq -r '.id')
        album_link_key=$(echo "$album_link" | jq -r '.key')
        echo "✓ 创建相册共享链接成功"
        echo "  链接 ID: $album_link_id"
        echo "  访问密钥: $album_link_key"
        echo "  访问 URL: $IMMICH_SERVER_URL/share/$album_link_key"
        echo "  过期时间: $expires_at"
    else
        echo "✗ 创建相册共享链接失败"
        album_link_id=""
    fi
    echo ""
fi

# ============================================================================
# 4. 创建资源共享链接（高级方式）
# ============================================================================

if [[ ${#test_asset_ids[@]} -gt 0 ]]; then
    echo "4. 创建资源共享链接（使用高级方式）..."

    # 构建资源 ID 数组
    asset_ids_json=$(printf '%s\n' "${test_asset_ids[@]}" | jq -R . | jq -s .)

    # 计算 3 天后的过期时间
    expires_at=$(date -u -v+3d +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u -d "+3 days" +"%Y-%m-%dT%H:%M:%S.000Z")

    # 创建带密码的共享链接
    link_data=$(jq -n \
        --argjson aids "$asset_ids_json" \
        --arg desc "精选照片分享" \
        --arg exp "$expires_at" \
        '{
            type: "INDIVIDUAL",
            assetIds: $aids,
            description: $desc,
            expiresAt: $exp,
            allowDownload: true,
            showMetadata: false,
            password: "test123"
        }')

    asset_link=$(create_shared_link "$link_data")

    if [[ $? -eq 0 ]]; then
        asset_link_id=$(echo "$asset_link" | jq -r '.id')
        asset_link_key=$(echo "$asset_link" | jq -r '.key')
        echo "✓ 创建资源共享链接成功"
        echo "  链接 ID: $asset_link_id"
        echo "  访问密钥: $asset_link_key"
        echo "  访问 URL: $IMMICH_SERVER_URL/share/$asset_link_key"
        echo "  访问密码: test123"
        echo "  过期时间: $expires_at"
        echo "  资源数量: ${#test_asset_ids[@]}"
    else
        echo "✗ 创建资源共享链接失败"
        asset_link_id=""
    fi
    echo ""
fi

# ============================================================================
# 5. 查询共享链接详情
# ============================================================================

if [[ -n "$album_link_id" ]]; then
    echo "5. 查询共享链接详情..."

    link_detail=$(get_shared_link_by_id "$album_link_id")
    if [[ $? -eq 0 ]]; then
        echo "✓ 获取共享链接详情成功"
        echo "$link_detail" | jq '{id, type, description, key, expiresAt, allowDownload, showMetadata}'
    else
        echo "✗ 获取共享链接详情失败"
    fi
    echo ""
fi

# ============================================================================
# 6. 更新共享链接
# ============================================================================

if [[ -n "$album_link_id" ]]; then
    echo "6. 更新共享链接..."

    # 延长过期时间到 14 天后
    new_expires_at=$(date -u -v+14d +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date -u -d "+14 days" +"%Y-%m-%dT%H:%M:%S.000Z")

    update_data=$(jq -n \
        --arg exp "$new_expires_at" \
        '{
            description: "更新的相册分享",
            expiresAt: $exp,
            allowDownload: false
        }')

    update_result=$(update_shared_link "$album_link_id" "$update_data")
    if [[ $? -eq 0 ]]; then
        echo "✓ 更新共享链接成功"
        echo "  新描述: 更新的相册分享"
        echo "  新过期时间: $new_expires_at"
        echo "  禁止下载: 是"
    else
        echo "✗ 更新共享链接失败"
    fi
    echo ""
fi

# ============================================================================
# 7. 管理共享链接中的资源
# ============================================================================

if [[ -n "$asset_link_id" && ${#test_asset_ids[@]} -gt 1 ]]; then
    echo "7. 管理共享链接中的资源..."

    # 移除第一个资源
    echo "  移除一个资源..."
    remove_result=$(remove_shared_link_assets "$asset_link_id" "${test_asset_ids[0]}")
    if [[ $? -eq 0 ]]; then
        echo "  ✓ 移除资源成功"
    else
        echo "  ✗ 移除资源失败"
    fi

    # 重新添加资源
    echo "  重新添加资源..."
    add_result=$(add_shared_link_assets "$asset_link_id" "${test_asset_ids[0]}")
    if [[ $? -eq 0 ]]; then
        echo "  ✓ 添加资源成功"
    else
        echo "  ✗ 添加资源失败"
    fi
    echo ""
fi

# ============================================================================
# 8. 查看所有共享链接（最终状态）
# ============================================================================

echo "8. 查看所有共享链接（最终状态）..."
final_links=$(get_all_shared_links)

if [[ $? -eq 0 ]]; then
    final_count=$(echo "$final_links" | jq '. | length')
    echo "✓ 当前共有 $final_count 个共享链接"
    echo ""
    echo "共享链接列表："
    echo "$final_links" | jq -r '.[] | "  - \(.description // "无描述")"'
    echo "    类型: \(.type)"
    echo "    URL: '$IMMICH_SERVER_URL'/share/\(.key)"
    if [[ -n "$(echo "$final_links" | jq -r '.expiresAt // empty')" ]]; then
        echo "    过期时间: \(.expiresAt)"
    fi
else
    echo "✗ 获取共享链接失败"
fi

echo ""

# ============================================================================
# 9. 清理（可选）
# ============================================================================

echo "9. 清理测试数据..."
echo "注意: 以下操作将删除创建的测试共享链接"
read -p "是否删除测试共享链接？(y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 删除创建的共享链接
    for link_id in "$album_link_id" "$asset_link_id"; do
        if [[ -n "$link_id" ]]; then
            remove_shared_link "$link_id" >/dev/null 2>&1
            echo "  已删除共享链接 ID: $link_id"
        fi
    done
    echo "✓ 清理完成"
else
    echo "跳过清理"
fi

echo ""
echo "================================================"
echo "共享链接操作示例完成"
echo "================================================"
