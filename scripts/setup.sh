#!/bin/bash
# Immich API 配置向导
# 用于首次设置 Immich 服务器连接信息

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$SKILL_DIR/config"
CONFIG_FILE="$CONFIG_DIR/config.json"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 打印标题
print_header() {
    echo ""
    echo "============================================"
    echo "  Claw-Immich 配置向导"
    echo "============================================"
    echo ""
}

# 检查依赖
check_dependencies() {
    local missing_deps=()

    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "缺少必需的工具: ${missing_deps[*]}"
        echo ""
        echo "安装说明:"
        echo "  macOS:  brew install ${missing_deps[*]}"
        echo "  Ubuntu: sudo apt-get install ${missing_deps[*]}"
        echo "  CentOS: sudo yum install ${missing_deps[*]}"
        echo ""
        exit 1
    fi
}

# 读取用户输入
read_input() {
    local prompt="$1"
    local default="$2"
    local is_secret="${3:-false}"
    local user_input

    if [[ -n "$default" ]]; then
        prompt="$prompt [$default]"
    fi

    if [[ "$is_secret" == "true" ]]; then
        # 隐藏输入（用于密钥）
        read -s -p "$prompt: " user_input
        echo ""
    else
        read -p "$prompt: " user_input
    fi

    # 如果用户未输入，使用默认值
    if [[ -z "$user_input" && -n "$default" ]]; then
        echo "$default"
        return
    fi

    echo "$user_input"
}

# 验证 URL 格式
validate_url() {
    local url="$1"

    # 去除前后空白字符
    url=$(echo "$url" | xargs)

    if [[ -z "$url" ]]; then
        print_error "服务器地址不能为空"
        return 1
    fi

    if [[ "$url" != http://* && "$url" != https://* ]]; then
        print_error "服务器地址必须以 http:// 或 https:// 开头"
        return 1
    fi

    # 警告使用 HTTP
    if [[ "$url" =~ ^http:// ]] && [[ ! "$url" =~ ^http://localhost ]] && [[ ! "$url" =~ ^http://127\.0\.0\.1 ]]; then
        print_warning "使用 HTTP 连接不安全，建议使用 HTTPS"
        echo -n "是否继续？(y/N): "
        read confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi

    return 0
}

# 测试 API 连接
test_api_connection() {
    local server_url="$1"
    local api_key="$2"

    print_info "正在测试连接..."

    # 移除 URL 末尾的斜杠
    server_url="${server_url%/}"

    local response
    local http_code

    response=$(curl -sL -w "\n%{http_code}" \
        -H "Accept: application/json" \
        "${server_url}/api/server/ping" 2>/dev/null)

    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')

    if [[ "$http_code" -eq 200 ]]; then
        print_success "连接成功！"
        return 0
    elif [[ "$http_code" -eq 401 ]]; then
        print_error "认证失败：API 密钥无效"
        return 1
    elif [[ "$http_code" -eq 000 ]]; then
        print_error "无法连接到服务器：请检查服务器地址和网络连接"
        return 1
    else
        print_error "连接失败：HTTP $http_code"
        echo "$response" >&2
        return 1
    fi
}

# 保存配置
save_config() {
    local server_url="$1"
    local api_key="$2"
    local device_id="${3:-claude-code}"

    # 去除可能的换行符
    api_key=$(echo "$api_key" | tr -d '\n')
    server_url=$(echo "$server_url" | tr -d '\n')

    # 创建配置目录
    mkdir -p "$CONFIG_DIR"

    # 生成配置 JSON
    local config_json=$(jq -n \
        --arg url "$server_url" \
        --arg key "$api_key" \
        --arg device "$device_id" \
        '{
            server_url: $url,
            api_key: $key,
            default_device_id: $device,
            preferences: {
                max_upload_size_mb: 100,
                default_output_format: "json",
                pagination_limit: 50
            }
        }')

    # 写入配置文件
    echo "$config_json" > "$CONFIG_FILE"

    # 设置严格权限（仅所有者可读写）
    chmod 600 "$CONFIG_FILE"

    print_success "配置已保存到: $CONFIG_FILE"
    print_info "配置文件权限已设置为 600（仅所有者可读写）"
}

# 主配置流程
main() {
    print_header

    # 检查依赖
    check_dependencies

    # 检查是否已有配置
    if [[ -f "$CONFIG_FILE" ]]; then
        print_warning "检测到已有配置文件"
        echo -n "是否要重新配置？(y/N): "
        read confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "配置已取消"
            exit 0
        fi
        echo ""
    fi

    # 读取配置信息
    echo "请输入 Immich 服务器信息："
    echo ""

    # 读取服务器 URL
    while true; do
        server_url=$(read_input "服务器地址" "http://localhost:2283")
        if validate_url "$server_url"; then
            break
        fi
        echo ""
    done

    echo ""
    print_info "如何获取 API 密钥："
    print_info "  1. 登录 Immich Web 界面"
    print_info "  2. 进入 设置 → API 密钥"
    print_info "  3. 点击 创建 API 密钥"
    print_info "  4. 为密钥命名（例如：claude-code）"
    print_info "  5. 选择所需权限（建议全部选择）"
    print_info "  6. 复制生成的密钥"
    echo ""

    # 读取 API 密钥
    while true; do
        api_key=$(read_input "API 密钥" "" "true")
        if [[ -n "$api_key" ]]; then
            break
        fi
        print_error "API 密钥不能为空"
        echo ""
    done

    echo ""

    # 读取设备 ID（可选）
    device_id=$(read_input "设备 ID（可选）" "claude-code")

    echo ""

    # 测试连接
    if ! test_api_connection "$server_url" "$api_key"; then
        echo ""
        print_error "配置失败：无法连接到 Immich 服务器"
        echo ""
        echo "故障排除建议："
        echo "  1. 检查服务器地址是否正确"
        echo "  2. 确认 Immich 服务器正在运行"
        echo "  3. 验证 API 密钥是否有效"
        echo "  4. 检查网络连接和防火墙设置"
        echo ""
        exit 1
    fi

    echo ""

    # 保存配置
    save_config "$server_url" "$api_key" "$device_id"

    echo ""
    print_success "配置完成！"
    echo ""
    echo "现在你可以使用 Claw-Immich skill 了："
    echo ""
    echo "  # 在 Claude Code 中使用"
    echo "  \"列出我的 Immich 相册\""
    echo "  \"上传照片到 Immich\""
    echo ""
    echo "  # 或者在脚本中使用"
    echo "  source ~/.claude/skills/claw-immich/scripts/immich-api.sh"
    echo "  list_albums"
    echo ""
    echo "详细文档: ~/.claude/skills/claw-immich/SKILL.md"
    echo ""
}

# 运行主程序
main
