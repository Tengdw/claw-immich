#!/bin/bash
# 标签操作示例脚本
# 演示如何使用 Immich API 进行标签管理和资源标记

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 加载 API 函数
source "$SKILL_DIR/scripts/immich-api.sh"

# 加载配置
load_config || exit 1

echo "================================================"
echo "Immich 标签操作示例"
echo "================================================"
echo ""

# ============================================================================
# 1. 获取所有标签
# ============================================================================

echo "1. 获取所有现有标签..."
all_tags=$(get_all_tags)

if [[ $? -eq 0 ]]; then
    tag_count=$(echo "$all_tags" | jq '. | length')
    echo "✓ 找到 $tag_count 个标签"

    if [[ $tag_count -gt 0 ]]; then
        echo ""
        echo "现有标签列表："
        echo "$all_tags" | jq -r '.[] | "  - \(.name) (颜色: \(.color // "未设置"), ID: \(.id))"'
    fi
else
    echo "✗ 获取标签失败"
fi

echo ""

# ============================================================================
# 2. 创建新标签
# ============================================================================

echo "2. 创建新标签..."

# 创建带颜色的标签
tag1=$(create_tag "旅行" "#FF5733")
if [[ $? -eq 0 ]]; then
    tag1_id=$(echo "$tag1" | jq -r '.id')
    echo "✓ 创建标签 '旅行' 成功 (ID: $tag1_id)"
else
    echo "✗ 创建标签 '旅行' 失败"
    tag1_id=""
fi

# 创建不带颜色的标签
tag2=$(create_tag "家庭")
if [[ $? -eq 0 ]]; then
    tag2_id=$(echo "$tag2" | jq -r '.id')
    echo "✓ 创建标签 '家庭' 成功 (ID: $tag2_id)"
else
    echo "✗ 创建标签 '家庭' 失败"
    tag2_id=""
fi

# 创建更多标签
tag3=$(create_tag "美食" "#FFC300")
if [[ $? -eq 0 ]]; then
    tag3_id=$(echo "$tag3" | jq -r '.id')
    echo "✓ 创建标签 '美食' 成功 (ID: $tag3_id)"
else
    echo "✗ 创建标签 '美食' 失败"
    tag3_id=""
fi

echo ""

# ============================================================================
# 3. 批量创建或更新标签
# ============================================================================

echo "3. 批量创建或更新标签..."

upsert_data=$(jq -n \
    '{
        tags: [
            {name: "风景", color: "#00FF00"},
            {name: "人物", color: "#0000FF"},
            {name: "活动", color: "#FF00FF"}
        ]
    }')

upsert_result=$(upsert_tags "$upsert_data")
if [[ $? -eq 0 ]]; then
    echo "✓ 批量创建/更新标签成功"
    echo "$upsert_result" | jq -r '.[] | "  - \(.name) (ID: \(.id))"'
else
    echo "✗ 批量创建/更新标签失败"
fi

echo ""

# ============================================================================
# 4. 查询指定标签
# ============================================================================

if [[ -n "$tag1_id" ]]; then
    echo "4. 查询标签详情..."
    tag_detail=$(get_tag_by_id "$tag1_id")

    if [[ $? -eq 0 ]]; then
        echo "✓ 获取标签 '旅行' 详情成功"
        echo "$tag_detail" | jq '{id, name, color, createdAt, updatedAt}'
    else
        echo "✗ 获取标签详情失败"
    fi
    echo ""
fi

# ============================================================================
# 5. 更新标签
# ============================================================================

if [[ -n "$tag1_id" ]]; then
    echo "5. 更新标签..."

    update_data=$(jq -n '{name: "旅行摄影", color: "#FF6B6B"}')
    update_result=$(update_tag "$tag1_id" "$update_data")

    if [[ $? -eq 0 ]]; then
        echo "✓ 更新标签成功"
        echo "$update_result" | jq '{id, name, color}'
    else
        echo "✗ 更新标签失败"
    fi
    echo ""
fi

# ============================================================================
# 6. 为资源添加标签
# ============================================================================

echo "6. 为资源添加标签..."
echo "注意: 此步骤需要有实际的资源 ID"
echo "可以先搜索资源，然后为搜索结果添加标签"
echo ""

# 搜索一些资源（例如：最近的照片）
echo "搜索最近的照片..."
search_query='{"type": "IMAGE"}'
search_result=$(search_assets "$search_query")

if [[ $? -eq 0 ]]; then
    asset_count=$(echo "$search_result" | jq '.assets.items | length')
    echo "✓ 找到 $asset_count 张照片"

    if [[ $asset_count -gt 0 && -n "$tag1_id" ]]; then
        # 获取前 3 个资源的 ID
        asset_ids=($(echo "$search_result" | jq -r '.assets.items[0:3] | .[] | .id'))

        if [[ ${#asset_ids[@]} -gt 0 ]]; then
            echo ""
            echo "为前 ${#asset_ids[@]} 张照片添加标签 '旅行摄影'..."

            tag_result=$(tag_assets "$tag1_id" "${asset_ids[@]}")
            if [[ $? -eq 0 ]]; then
                echo "✓ 成功为 ${#asset_ids[@]} 张照片添加标签"
            else
                echo "✗ 添加标签失败"
            fi
        fi
    fi
else
    echo "✗ 搜索资源失败"
fi

echo ""

# ============================================================================
# 7. 批量为资源添加多个标签
# ============================================================================

if [[ ${#asset_ids[@]} -gt 0 && -n "$tag1_id" && -n "$tag2_id" ]]; then
    echo "7. 批量为资源添加多个标签..."

    # 构建批量标记数据
    asset_ids_json=$(printf '%s\n' "${asset_ids[@]}" | jq -R . | jq -s .)
    tag_ids_json=$(jq -n --arg t1 "$tag1_id" --arg t2 "$tag2_id" '[$t1, $t2]')

    bulk_tag_data=$(jq -n \
        --argjson aids "$asset_ids_json" \
        --argjson tids "$tag_ids_json" \
        '{assetIds: $aids, tagIds: $tids}')

    bulk_result=$(bulk_tag_assets "$bulk_tag_data")
    if [[ $? -eq 0 ]]; then
        echo "✓ 批量标记成功"
    else
        echo "✗ 批量标记失败"
    fi
    echo ""
fi

# ============================================================================
# 8. 移除资源标签
# ============================================================================

if [[ ${#asset_ids[@]} -gt 0 && -n "$tag2_id" ]]; then
    echo "8. 移除资源标签..."

    # 移除 '家庭' 标签
    untag_result=$(untag_assets "$tag2_id" "${asset_ids[@]}")
    if [[ $? -eq 0 ]]; then
        echo "✓ 成功移除 ${#asset_ids[@]} 张照片的 '家庭' 标签"
    else
        echo "✗ 移除标签失败"
    fi
    echo ""
fi

# ============================================================================
# 9. 查看所有标签（最终状态）
# ============================================================================

echo "9. 查看所有标签（最终状态）..."
final_tags=$(get_all_tags)

if [[ $? -eq 0 ]]; then
    final_count=$(echo "$final_tags" | jq '. | length')
    echo "✓ 当前共有 $final_count 个标签"
    echo ""
    echo "标签列表："
    echo "$final_tags" | jq -r '.[] | "  - \(.name) (颜色: \(.color // "未设置"))"'
else
    echo "✗ 获取标签失败"
fi

echo ""

# ============================================================================
# 10. 清理（可选）
# ============================================================================

echo "10. 清理测试数据..."
echo "注意: 以下操作将删除创建的测试标签"
read -p "是否删除测试标签？(y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 删除创建的标签
    for tag_id in "$tag1_id" "$tag2_id" "$tag3_id"; do
        if [[ -n "$tag_id" ]]; then
            delete_tag "$tag_id" >/dev/null 2>&1
            echo "  已删除标签 ID: $tag_id"
        fi
    done
    echo "✓ 清理完成"
else
    echo "跳过清理"
fi

echo ""
echo "================================================"
echo "标签操作示例完成"
echo "================================================"
