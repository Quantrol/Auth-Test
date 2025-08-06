#!/bin/bash

# Stack Auth 자동 헬스체크 및 복구 스크립트
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 헬스체크 함수
health_check() {
    local service_name=$1
    local port=$2
    local max_retries=${3:-3}
    local retry_delay=${4:-5}
    
    for i in $(seq 1 $max_retries); do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:$port | grep -q "200"; then
            log_success "$service_name ($port): 정상"
            return 0
        else
            log_warning "$service_name ($port): 응답 없음 (시도 $i/$max_retries)"
            if [ $i -lt $max_retries ]; then
                sleep $retry_delay
            fi
        fi
    done
    
    log_error "$service_name ($port): 복구 필요"
    return 1
}

# 서비스 복구 함수
recover_service() {
    local service_name=$1
    local port=$2
    
    log_info "$service_name 복구 시도 중..."
    
    case $port in
        8100)
            # 런치패드 복구
            (cd apps/dev-launchpad && pnpm run dev &)
            ;;
        8101)
            # 대시보드 복구 - 기존 프로세스 종료 후 재시작
            pkill -f "next dev.*8101" || true
            sleep 2
            pnpm run --filter=@stackframe/stack-dashboard dev &
            ;;
        8102)
            # 백엔드 복구
            pkill -f "next dev.*8102" || true
            sleep 2
            pnpm run --filter=@stackframe/stack-backend dev &
            ;;
        8103)
            # 데모 앱 복구
            pkill -f "next dev.*8103" || true
            sleep 2
            (cd examples/demo && pnpm run dev &)
            ;;
        8104)
            # 문서 복구
            pkill -f "next dev.*8104" || true
            sleep 2
            pnpm run dev:docs &
            ;;
    esac
    
    # 복구 후 대기
    sleep 10
    
    # 복구 확인
    if health_check "$service_name" $port 1 0; then
        log_success "$service_name 복구 완료"
        return 0
    else
        log_error "$service_name 복구 실패"
        return 1
    fi
}

# 메인 헬스체크 루프
main_health_check() {
    log_info "Stack Auth 헬스체크 시작..."
    
    declare -A services=(
        ["런치패드"]="8100"
        ["대시보드"]="8101"
        ["백엔드"]="8102"
        ["데모앱"]="8103"
        ["문서"]="8104"
    )
    
    local failed_services=()
    
    # 모든 서비스 체크
    for service_name in "${!services[@]}"; do
        port=${services[$service_name]}
        if ! health_check "$service_name" $port 2 3; then
            failed_services+=("$service_name:$port")
        fi
    done
    
    # 실패한 서비스 복구
    if [ ${#failed_services[@]} -gt 0 ]; then
        log_warning "${#failed_services[@]}개 서비스에 문제가 발견되었습니다."
        
        for service_info in "${failed_services[@]}"; do
            IFS=':' read -r service_name port <<< "$service_info"
            recover_service "$service_name" $port
        done
        
        # 전체 재체크
        log_info "복구 후 전체 재체크..."
        sleep 5
        
        local still_failed=0
        for service_info in "${failed_services[@]}"; do
            IFS=':' read -r service_name port <<< "$service_info"
            if ! health_check "$service_name" $port 1 0; then
                still_failed=$((still_failed + 1))
            fi
        done
        
        if [ $still_failed -eq 0 ]; then
            log_success "모든 서비스가 정상적으로 복구되었습니다!"
        else
            log_error "$still_failed 개 서비스가 여전히 문제가 있습니다."
            log_info "수동 확인이 필요합니다: ./dev.sh status"
        fi
    else
        log_success "모든 서비스가 정상 작동 중입니다!"
    fi
}

# 지속적 모니터링 모드
continuous_monitoring() {
    log_info "지속적 헬스체크 모드 시작 (30초 간격)"
    log_info "Ctrl+C로 종료"
    
    while true; do
        echo ""
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 헬스체크 실행"
        main_health_check
        sleep 30
    done
}

# 사용법
case "${1:-check}" in
    "check"|"c")
        main_health_check
        ;;
    "monitor"|"m")
        continuous_monitoring
        ;;
    "help"|*)
        echo "Stack Auth 자동 헬스체크 및 복구 도구"
        echo "====================================="
        echo ""
        echo "사용법: ./auto-heal.sh [옵션]"
        echo ""
        echo "옵션:"
        echo "  check, c    - 한 번 헬스체크 및 복구 (기본값)"
        echo "  monitor, m  - 지속적 모니터링 (30초 간격)"
        echo "  help        - 이 도움말 표시"
        ;;
esac