#!/bin/bash

# Stack Auth 통합 개발 대시보드
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 시스템 상태 확인
check_system_status() {
    echo -e "${CYAN}🖥️  시스템 상태${NC}"
    echo "===================="
    
    # 운영체제 정보
    echo "OS: $(uname -s) $(uname -r)"
    
    # 메모리 사용량
    if command -v free &> /dev/null; then
        echo "메모리: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    elif command -v vm_stat &> /dev/null; then
        # macOS
        local pages_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\\.//')
        local pages_total=$(vm_stat | grep -E "(Pages free|Pages active|Pages inactive|Pages speculative|Pages wired down)" | awk '{sum += $3} END {print sum}')
        local mem_used=$((($pages_total - $pages_free) * 4096 / 1024 / 1024))
        local mem_total=$(($pages_total * 4096 / 1024 / 1024))
        echo "메모리: ${mem_used}MB / ${mem_total}MB"
    fi
    
    # 디스크 사용량
    echo "디스크: $(df -h . | awk 'NR==2 {print $3 "/" $2 " (" $5 " 사용)"}')"
    
    echo ""
}

# 개발 도구 상태 확인
check_dev_tools() {
    echo -e "${PURPLE}🔧 개발 도구 상태${NC}"
    echo "===================="
    
    local tools=(
        "node:Node.js"
        "pnpm:pnpm"
        "asdf:asdf"
        "direnv:direnv"
        "git:Git"
        "docker:Docker"
    )
    
    for tool_info in "${tools[@]}"; do
        IFS=':' read -r cmd name <<< "$tool_info"
        
        if command -v "$cmd" &> /dev/null; then
            local version=$($cmd --version 2>/dev/null | head -n1 | grep -o '[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+' | head -n1 || echo "unknown")
            echo -e "  ✅ $name: $version"
        else
            echo -e "  ❌ $name: 설치되지 않음"
        fi
    done
    
    echo ""
}

# 프로젝트 상태 확인
check_project_status() {
    echo -e "${GREEN}📦 프로젝트 상태${NC}"
    echo "===================="
    
    # Git 상태
    if [ -d ".git" ]; then
        local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        local commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        local status=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        
        echo "Git 브랜치: $branch ($commit)"
        if [ "$status" -eq 0 ]; then
            echo "Git 상태: 깨끗함"
        else
            echo "Git 상태: ${status}개 변경사항"
        fi
    else
        echo "Git: 저장소가 아님"
    fi
    
    # 의존성 상태
    if [ -f "package.json" ]; then
        if [ -d "node_modules" ]; then
            echo "의존성: 설치됨"
        else
            echo "의존성: 설치되지 않음"
        fi
        
        # 보안 취약점 확인
        local audit_result=$(pnpm audit --audit-level moderate 2>/dev/null | grep -c "vulnerabilities" || echo "0")
        if [ "$audit_result" -eq 0 ]; then
            echo "보안: 취약점 없음"
        else
            echo "보안: 취약점 발견됨"
        fi
    fi
    
    echo ""
}

# 서비스 상태 확인
check_services_status() {
    echo -e "${YELLOW}🚀 서비스 상태${NC}"
    echo "===================="
    
    local services=(
        "8100:런치패드"
        "8101:대시보드"
        "8102:백엔드"
        "8103:데모앱"
        "8104:문서"
        "5432:PostgreSQL"
        "6379:Redis"
    )
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r port name <<< "$service_info"
        
        if lsof -i :$port &>/dev/null; then
            local pid=$(lsof -ti :$port)
            echo -e "  ✅ $name (포트 $port, PID: $pid)"
        else
            echo -e "  ❌ $name (포트 $port)"
        fi
    done
    
    echo ""
}

# 최근 로그 확인
check_recent_logs() {
    echo -e "${CYAN}📋 최근 로그${NC}"
    echo "===================="
    
    # 개발 서버 로그 확인
    local log_files=(
        ".turbo/daemon.log"
        "apps/dev-launchpad/.next/trace"
        "apps/dashboard/.next/trace"
    )
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            echo "📄 $log_file (최근 5줄):"
            tail -n 5 "$log_file" 2>/dev/null | sed 's/^/  /'
            echo ""
        fi
    done
    
    # Git 로그
    if [ -d ".git" ]; then
        echo "📄 Git 로그 (최근 3개 커밋):"
        git log --oneline -3 2>/dev/null | sed 's/^/  /' || echo "  로그를 가져올 수 없습니다."
        echo ""
    fi
}

# 성능 메트릭
check_performance() {
    echo -e "${PURPLE}⚡ 성능 메트릭${NC}"
    echo "===================="
    
    # Node.js 프로세스 확인
    local node_processes=$(pgrep -f "node" | wc -l | tr -d ' ')
    echo "Node.js 프로세스: $node_processes개"
    
    # 포트 사용량
    local used_ports=$(lsof -i -P -n | grep LISTEN | wc -l | tr -d ' ')
    echo "사용 중인 포트: $used_ports개"
    
    # 빌드 캐시 크기
    if [ -d ".turbo" ]; then
        local cache_size=$(du -sh .turbo 2>/dev/null | cut -f1)
        echo "Turbo 캐시: $cache_size"
    fi
    
    if [ -d "node_modules/.cache" ]; then
        local nm_cache_size=$(du -sh node_modules/.cache 2>/dev/null | cut -f1)
        echo "Node 모듈 캐시: $nm_cache_size"
    fi
    
    echo ""
}

# 권장사항 표시
show_recommendations() {
    echo -e "${YELLOW}💡 권장사항${NC}"
    echo "===================="
    
    local recommendations=()
    
    # 의존성 체크
    if [ ! -d "node_modules" ]; then
        recommendations+=("pnpm install을 실행하여 의존성을 설치하세요")
    fi
    
    # Git 상태 체크
    if [ -d ".git" ]; then
        local uncommitted=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        if [ "$uncommitted" -gt 0 ]; then
            recommendations+=("${uncommitted}개의 변경사항이 커밋되지 않았습니다")
        fi
    fi
    
    # 서비스 상태 체크
    if ! lsof -i :8102 &>/dev/null; then
        recommendations+=("백엔드 서비스가 실행되지 않고 있습니다")
    fi
    
    # 보안 체크
    if [ -f "package.json" ]; then
        local audit_issues=$(pnpm audit --audit-level moderate 2>/dev/null | grep -c "vulnerabilities" || echo "0")
        if [ "$audit_issues" -gt 0 ]; then
            recommendations+=("보안 취약점이 발견되었습니다. pnpm audit --fix를 실행하세요")
        fi
    fi
    
    # 권장사항 출력
    if [ ${#recommendations[@]} -eq 0 ]; then
        echo "  ✅ 모든 것이 정상입니다!"
    else
        for rec in "${recommendations[@]}"; do
            echo "  ⚠️  $rec"
        done
    fi
    
    echo ""
}

# 빠른 액션 메뉴
show_quick_actions() {
    echo -e "${GREEN}⚡ 빠른 액션${NC}"
    echo "===================="
    echo "1. 개발 서버 시작 (./dev.sh quick)"
    echo "2. 의존성 설치 (pnpm install)"
    echo "3. 타입 체크 (pnpm run type-check)"
    echo "4. 테스트 실행 (pnpm test)"
    echo "5. 빌드 (pnpm run build:packages)"
    echo "6. 보안 감사 (pnpm audit)"
    echo "7. 캐시 정리 (pnpm store prune)"
    echo "8. 백업 생성 (./backup-restore.sh backup)"
    echo "9. 자동 복구 (./auto-heal.sh)"
    echo "0. 종료"
    echo ""
}

# 액션 실행
execute_action() {
    local action="$1"
    
    case "$action" in
        "1")
            log_info "개발 서버 시작 중..."
            ./dev.sh quick
            ;;
        "2")
            log_info "의존성 설치 중..."
            pnpm install
            ;;
        "3")
            log_info "타입 체크 중..."
            pnpm run type-check
            ;;
        "4")
            log_info "테스트 실행 중..."
            pnpm test
            ;;
        "5")
            log_info "빌드 중..."
            pnpm run build:packages
            ;;
        "6")
            log_info "보안 감사 중..."
            pnpm audit
            ;;
        "7")
            log_info "캐시 정리 중..."
            pnpm store prune
            rm -rf .turbo
            ;;
        "8")
            log_info "백업 생성 중..."
            ./backup-restore.sh backup
            ;;
        "9")
            log_info "자동 복구 실행 중..."
            ./auto-heal.sh
            ;;
        "0")
            log_info "대시보드를 종료합니다."
            exit 0
            ;;
        *)
            log_warning "잘못된 선택입니다."
            ;;
    esac
}

# 대화형 모드
interactive_mode() {
    while true; do
        clear
        echo -e "${CYAN}Stack Auth 개발 대시보드${NC}"
        echo "=========================="
        echo ""
        
        check_system_status
        check_dev_tools
        check_project_status
        check_services_status
        show_recommendations
        show_quick_actions
        
        echo -n "액션을 선택하세요 (1-9, 0=종료): "
        read -r choice
        
        if [ "$choice" = "0" ]; then
            break
        fi
        
        echo ""
        execute_action "$choice"
        
        echo ""
        echo "계속하려면 Enter를 누르세요..."
        read -r
    done
}

# 상태만 표시하는 모드
status_only_mode() {
    echo -e "${CYAN}Stack Auth 개발 환경 상태${NC}"
    echo "=========================="
    echo ""
    
    check_system_status
    check_dev_tools
    check_project_status
    check_services_status
    check_performance
    show_recommendations
}

# 메인 로직
case "${1:-interactive}" in
    "status"|"s")
        status_only_mode
        ;;
    "interactive"|"i")
        interactive_mode
        ;;
    "logs"|"l")
        check_recent_logs
        ;;
    "perf"|"p")
        check_performance
        ;;
    "help"|"h")
        echo "Stack Auth 통합 개발 대시보드"
        echo "============================"
        echo ""
        echo "사용법: ./dev-dashboard.sh [옵션]"
        echo ""
        echo "옵션:"
        echo "  status, s      - 상태만 표시"
        echo "  interactive, i - 대화형 모드 (기본값)"
        echo "  logs, l        - 최근 로그 표시"
        echo "  perf, p        - 성능 메트릭 표시"
        echo "  help, h        - 이 도움말 표시"
        echo ""
        echo "예시:"
        echo "  ./dev-dashboard.sh status"
        echo "  ./dev-dashboard.sh interactive"
        ;;
    *)
        log_error "알 수 없는 옵션: $1"
        echo "사용법: ./dev-dashboard.sh help"
        exit 1
        ;;
esac