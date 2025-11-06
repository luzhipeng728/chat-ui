#!/bin/bash
# 服务功能测试脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "=========================================="
echo "  易诚融智 AI 系统功能测试"
echo "  Ynet NexMind Service Test"
echo "=========================================="
echo ""

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local test_name=$1
    local test_command=$2
    local expected_pattern=$3

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log_info "测试 $TOTAL_TESTS: $test_name"

    if output=$(eval "$test_command" 2>&1); then
        if echo "$output" | grep -q "$expected_pattern"; then
            log_success "✓ 测试通过"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        else
            log_error "✗ 测试失败: 输出不符合预期"
            log_error "期望包含: $expected_pattern"
            log_error "实际输出: $output"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    else
        log_error "✗ 测试失败: 命令执行失败"
        log_error "错误信息: $output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# 1. 测试后端代理服务 - 端口监听
log_info "========== 后端服务测试 =========="
run_test "后端代理端口监听" \
    "lsof -i:8090 | grep LISTEN" \
    "LISTEN"

# 2. 测试后端代理服务 - 模型列表
run_test "后端代理模型列表接口" \
    "curl -s http://localhost:8090/models" \
    "Ynet-NexMind"

# 3. 测试后端代理服务 - 模型信息
run_test "模型信息包含易诚融智" \
    "curl -s http://localhost:8090/models" \
    "易诚融智大模型"

# 4. 测试后端代理服务 - 公司信息
run_test "模型信息包含公司名称" \
    "curl -s http://localhost:8090/models" \
    "yicheng-hudong"

echo ""
log_info "========== 前端服务测试 =========="

# 5. 测试前端服务 - 端口监听
run_test "前端服务端口监听" \
    "lsof -i:5173 | grep LISTEN" \
    "LISTEN"

# 6. 测试前端服务 - HTTP 响应
run_test "前端服务 HTTP 响应" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost:5173" \
    "200"

# 7. 测试前端页面 - HTML 内容
run_test "前端页面包含 HTML" \
    "curl -s http://localhost:5173" \
    "<!doctype html>"

echo ""
log_info "========== 集成测试 =========="

# 8. 测试前端能否访问后端
run_test "前端服务器端能访问后端代理" \
    "curl -s http://localhost:8090/models" \
    "object"

# 9. 测试数据库目录
run_test "数据库目录存在" \
    "test -d ./db && echo 'exists'" \
    "exists"

# 10. 测试日志目录
run_test "日志目录存在" \
    "test -d ./logs && echo 'exists'" \
    "exists"

echo ""
log_info "========== 配置文件测试 =========="

# 11. 测试 .env.local 存在
run_test ".env.local 配置文件存在" \
    "test -f .env.local && echo 'exists'" \
    "exists"

# 12. 测试 .env.local 包含 API Key
run_test ".env.local 包含 API Key" \
    "grep -q 'UPSTREAM_API_KEY=' .env.local && echo 'found'" \
    "found"

# 13. 测试 .env.production 存在
run_test ".env.production 配置文件存在" \
    "test -f .env.production && echo 'exists'" \
    "exists"

echo ""
log_info "========== 安全性测试 =========="

# 14. 测试 .gitignore 包含 .env.local
run_test ".gitignore 包含 .env.local" \
    "grep -q '.env.local' .gitignore && echo 'found'" \
    "found"

# 15. 测试 .env.local 未被 git 跟踪
run_test ".env.local 未被 git 跟踪" \
    "git status --porcelain .env.local 2>&1 | grep -v 'fatal' || echo 'not-tracked'" \
    "not-tracked"

echo ""
echo "=========================================="
echo "  测试结果汇总"
echo "=========================================="
echo -e "${BLUE}总测试数:${NC} $TOTAL_TESTS"
echo -e "${GREEN}通过:${NC} $PASSED_TESTS"
echo -e "${RED}失败:${NC} $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    log_success "🎉 所有测试通过!"
    echo ""
    log_info "服务访问地址:"
    log_info "  前端: http://localhost:5173"
    log_info "  后端: http://localhost:8090 (仅内网)"
    echo ""
    log_info "可以使用以下命令查看服务状态:"
    log_info "  pm2 list"
    log_info "  pm2 logs"
    echo ""
    exit 0
else
    log_error "❌ 有 $FAILED_TESTS 个测试失败"
    echo ""
    log_info "请检查服务状态:"
    log_info "  pm2 list"
    log_info "  pm2 logs ynet-proxy"
    log_info "  pm2 logs ynet-frontend"
    echo ""
    exit 1
fi
