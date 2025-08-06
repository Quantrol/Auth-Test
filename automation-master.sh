#!/bin/bash

# Stack Auth 마스터 자동화 스크립트
# 모든 자동화 도구들을 통합 관리하는 중앙 허브

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 로고 표시
show_logo() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║    ███████╗████████╗ █████╗  ██████╗██╗  ██╗             ║
║    ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝             ║
║    ███████╗   ██║   ███████║██║     █████╔╝              ║
║    ╚════██║   ██║   ██╔══██║██║     ██╔═██╗              ║
║    ███████║   ██║   ██║  ██║╚██████╗██║  ██╗             ║
║    ╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝             ║
║                                                           ║
║              자동화 마스터 컨트롤 센터                      ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

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

# 사용 가능한 자동화 도구들
declare -A AUTOMATION_TOOLS=(
    ["dashboard"]="통합 개발 대시보드"
    ["heal"]="자동 헬스체크 및 복구"
    ["update"]="의존성 자동 업데이트"
    ["backup"]="환경 백업 및 복원"
    ["monitor"]="실시간 모니터링"
    ["setup"]="완전 자동화 설정"
)

# 도구 상태 확인
check_tool_status() {
    local tool=$1
    local script_name=""
    
    case $tool in
        "dashboard") script_name="dev-dashboard.sh" ;;
        "heal") script_name="auto-heal.sh" ;;
        "update") script_name="auto-update.sh" ;;
        "backup") script_name="backup-restore.sh" ;;
        "monitor") script_name="monitor.sh" ;;
        "setup") script_name="setup-complete.sh" ;;
    esac
    
    if [ -f "$script_name" ] && [ -x "$script_name" ]; then
        echo -e "  ✅ ${AUTOMATION_TOOLS[$tool]}"
    else
        echo -e "  ❌ ${AUTOMATION_TOOLS[$tool]} (스크립트 없음: $script_name)"
    fi
}

# 전체 상태 확인
show_status() {
    echo -e "${PURPLE}🔧 자동화 도구 상태${NC}"
    echo "===================="
    
    for tool in "${!AUTOMATION_TOOLS[@]}"; do
        check_tool_status "$tool"
    done
    
    echo ""
    
    # 시스템 상태 요약
    echo -e "${CYAN}📊 시스템 상태 요약${NC}"
    echo "===================="
    
    # 서비스 상태
    local services_running=0
    local total_services=5
    local ports=(8100 8101 8102 8103 8104)
    
    for port in "${ports[@]}"; do
        if lsof -i :$port &>/dev/null; then
            services_running=$((services_running + 1))
        fi
    done
    
    echo "개발 서비스: $services_running/$total_services 실행 중"
    
    # 의존성 상태
    if [ -d "node_modules" ]; then
        echo "의존성: ✅ 설치됨"
    else
        echo "의존성: ❌ 설치 필요"
    fi
    
    # Git 상태
    if [ -d ".git" ]; then
        local uncommitted=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        if [ "$uncommitted" -eq 0 ]; then
            echo "Git 상태: ✅ 깨끗함"
        else
            echo "Git 상태: ⚠️ ${uncommitted}개 변경사항"
        fi
    fi
    
    echo ""
}

# 메인 메뉴 표시
show_main_menu() {
    echo -e "${GREEN}🚀 자동화 도구 메뉴${NC}"
    echo "===================="
    echo ""
    echo "1. 📊 통합 개발 대시보드"
    echo "2. 🔧 자동 헬스체크 및 복구"
    echo "3. 📦 의존성 자동 업데이트"
    echo "4. 💾 환경 백업 및 복원"
    echo "5. 📈 실시간 모니터링"
    echo "6. ⚙️  완전 자동화 설정"
    echo ""
    echo "7. 🔍 전체 상태 확인"
    echo "8. 📚 도움말"
    echo "9. 🧹 정리 및 최적화"
    echo "0. 종료"
    echo ""
}

# 정리 및 최적화
cleanup_and_optimize() {
    log_info "시스템 정리 및 최적화 시작..."
    
    # 캐시 정리
    log_info "캐시 정리 중..."
    if command -v pnpm &> /dev/null; then
        pnpm store prune > /dev/null 2>&1 || true
    fi
    
    rm -rf .turbo > /dev/null 2>&1 || true
    rm -rf node_modules/.cache > /dev/null 2>&1 || true
    
    # 로그 파일 정리
    log_info "로그 파일 정리 중..."
    find . -name "*.log" -type f -mtime +7 -delete > /dev/null 2>&1 || true
    
    # 임시 파일 정리
    log_info "임시 파일 정리 중..."
    rm -rf /tmp/stack-auth-* > /dev/null 2>&1 || true
    
    # 오래된 백업 정리
    if [ -d "$HOME/.stack-auth-backups" ]; then
        log_info "오래된 백업 정리 중..."
        find "$HOME/.stack-auth-backups" -name "*.tar.gz" -type f -mtime +30 -delete > /dev/null 2>&1 || true
    fi
    
    # 권한 수정
    log_info "스크립트 권한 확인 중..."
    chmod +x *.sh > /dev/null 2>&1 || true
    
    log_success "정리 및 최적화 완료!"
}

# 도움말 표시
show_help() {
    echo -e "${CYAN}📚 Stack Auth 자동화 도구 가이드${NC}"
    echo "=================================="
    echo ""
    echo "이 마스터 스크립트는 모든 자동화 도구들을 통합 관리합니다."
    echo ""
    echo -e "${YELLOW}주요 기능:${NC}"
    echo "• 통합 개발 대시보드: 실시간 상태 모니터링 및 빠른 액션"
    echo "• 자동 헬스체크: 서비스 상태 확인 및 자동 복구"
    echo "• 의존성 업데이트: Context7 MCP 통합 최신 버전 관리"
    echo "• 백업 및 복원: 개발 환경 안전 보관"
    echo "• 실시간 모니터링: 지속적인 시스템 감시"
    echo ""
    echo -e "${YELLOW}빠른 시작:${NC}"
    echo "1. ./automation-master.sh 6  # 완전 자동화 설정"
    echo "2. ./automation-master.sh 1  # 대시보드 실행"
    echo "3. ./automation-master.sh 7  # 상태 확인"
    echo ""
    echo -e "${YELLOW}일반적인 워크플로우:${NC}"
    echo "• 매일: 대시보드로 상태 확인 → 개발 시작"
    echo "• 주간: 의존성 업데이트 → 백업 생성"
    echo "• 문제 시: 헬스체크 → 자동 복구"
    echo ""
    echo -e "${YELLOW}개별 스크립트 직접 실행:${NC}"
    echo "• ./dev-dashboard.sh      # 대시보드"
    echo "• ./auto-heal.sh         # 헬스체크"
    echo "• ./auto-update.sh       # 업데이트"
    echo "• ./backup-restore.sh    # 백업"
    echo "• ./monitor.sh           # 모니터링"
    echo ""
}

# 액션 실행
execute_action() {
    local action="$1"
    
    case "$action" in
        "1")
            log_info "통합 개발 대시보드 실행 중..."
            if [ -f "dev-dashboard.sh" ]; then
                ./dev-dashboard.sh
            else
                log_error "dev-dashboard.sh 파일이 없습니다."
            fi
            ;;
        "2")
            log_info "자동 헬스체크 및 복구 실행 중..."
            if [ -f "auto-heal.sh" ]; then
                ./auto-heal.sh
            else
                log_error "auto-heal.sh 파일이 없습니다."
            fi
            ;;
        "3")
            log_info "의존성 자동 업데이트 실행 중..."
            if [ -f "auto-update.sh" ]; then
                ./auto-update.sh
            else
                log_error "auto-update.sh 파일이 없습니다."
            fi
            ;;
        "4")
            log_info "환경 백업 및 복원 도구 실행 중..."
            if [ -f "backup-restore.sh" ]; then
                ./backup-restore.sh
            else
                log_error "backup-restore.sh 파일이 없습니다."
            fi
            ;;
        "5")
            log_info "실시간 모니터링 실행 중..."
            if [ -f "monitor.sh" ]; then
                ./monitor.sh monitor
            else
                log_error "monitor.sh 파일이 없습니다."
            fi
            ;;
        "6")
            log_info "완전 자동화 설정 실행 중..."
            if [ -f "setup-complete.sh" ]; then
                ./setup-complete.sh
            else
                log_error "setup-complete.sh 파일이 없습니다."
            fi
            ;;
        "7")
            show_status
            ;;
        "8")
            show_help
            ;;
        "9")
            cleanup_and_optimize
            ;;
        "0")
            log_info "자동화 마스터를 종료합니다."
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
        show_logo
        show_status
        show_main_menu
        
        echo -n "원하는 작업을 선택하세요 (0-9): "
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

# 메인 로직
case "${1:-interactive}" in
    "status"|"s")
        show_status
        ;;
    "interactive"|"i")
        interactive_mode
        ;;
    "help"|"h")
        show_help
        ;;
    "cleanup"|"clean")
        cleanup_and_optimize
        ;;
    [1-9])
        execute_action "$1"
        ;;
    *)
        if [ -n "$1" ]; then
            log_error "알 수 없는 옵션: $1"
            echo ""
        fi
        echo "Stack Auth 자동화 마스터"
        echo "======================="
        echo ""
        echo "사용법: ./automation-master.sh [옵션|번호]"
        echo ""
        echo "옵션:"
        echo "  status, s      - 전체 상태 확인"
        echo "  interactive, i - 대화형 모드 (기본값)"
        echo "  cleanup, clean - 정리 및 최적화"
        echo "  help, h        - 도움말"
        echo ""
        echo "번호:"
        echo "  1-9           - 해당 메뉴 항목 직접 실행"
        echo ""
        echo "예시:"
        echo "  ./automation-master.sh 1      # 대시보드 실행"
        echo "  ./automation-master.sh status # 상태 확인"
        ;;
esac