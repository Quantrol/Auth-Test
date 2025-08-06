#!/bin/bash

# Stack Auth 개발환경 스크립트
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

# 도움말 함수
show_help() {
    echo "Stack Auth 개발환경 관리 스크립트"
    echo ""
    echo "사용법: ./dev.sh [명령어]"
    echo ""
    echo "명령어:"
    echo "  setup     - 개발환경 초기 설정"
    echo "  deps      - 의존성 서비스 시작 (PostgreSQL, Redis 등)"
    echo "  stop-deps - 의존성 서비스 중지"
    echo "  dev       - 개발 서버 시작"
    echo "  dev:basic - 기본 개발 서버 시작 (백엔드 + 대시보드만)"
    echo "  dev:docs  - 문서 서버 시작"
    echo "  dev:full  - 전체 서버 시작 (백엔드 + 대시보드 + 문서)"
    echo "  build     - 프로젝트 빌드"
    echo "  test      - 테스트 실행"
    echo "  clean     - 빌드 파일 정리"
    echo "  db:init   - 데이터베이스 초기화"
    echo "  db:reset  - 데이터베이스 리셋"
    echo "  db:seed   - 데이터베이스 시드 데이터 삽입"
    echo "  quick     - 빠른 시작 (모든 체크 자동화)"
    echo "  start     - quick와 동일"
    echo "  status    - 전체 시스템 상태 확인"
    echo "  help      - 이 도움말 표시"
}

# 필수 도구 확인
check_requirements() {
    log_info "필수 도구 확인 중..."
    
    # asdf 확인
    if ! command -v asdf &> /dev/null; then
        log_error "asdf가 설치되지 않았습니다. 설치 후 다시 시도하세요."
        echo "설치 방법: https://asdf-vm.com/guide/getting-started.html"
        exit 1
    fi
    
    # direnv 확인
    if ! command -v direnv &> /dev/null; then
        log_error "direnv가 설치되지 않았습니다. 설치 후 다시 시도하세요."
        echo "설치 방법: brew install direnv"
        exit 1
    fi
    
    # PostgreSQL 확인
    if ! command -v psql &> /dev/null; then
        log_warning "PostgreSQL이 설치되지 않았습니다."
        echo "설치 방법: brew install postgresql"
    fi
    
    # Redis 확인
    if ! command -v redis-server &> /dev/null; then
        log_warning "Redis가 설치되지 않았습니다."
        echo "설치 방법: brew install redis"
    fi
    
    log_success "필수 도구 확인 완료"
}

# 개발환경 초기 설정
setup_environment() {
    log_info "개발환경 초기 설정 시작..."
    
    # asdf 플러그인 설치
    log_info "asdf 플러그인 설치 중..."
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git 2>/dev/null || true
    asdf plugin add pnpm https://github.com/jonathanmorley/asdf-pnpm.git 2>/dev/null || true
    
    # 버전 설치
    log_info "Node.js 및 pnpm 설치 중..."
    asdf install
    
    # direnv 허용
    log_info "direnv 환경 허용 중..."
    direnv allow
    
    # 의존성 설치
    log_info "프로젝트 의존성 설치 중..."
    pnpm install
    
    log_success "개발환경 초기 설정 완료"
}

# 의존성 서비스 시작
start_dependencies() {
    log_info "의존성 서비스 시작 중..."
    
    # PostgreSQL 시작
    if command -v brew &> /dev/null; then
        log_info "PostgreSQL 시작 중..."
        brew services start postgresql 2>/dev/null || true
        
        # 데이터베이스 생성
        createdb stackframe 2>/dev/null || log_warning "데이터베이스 'stackframe'이 이미 존재합니다."
    fi
    
    # Redis 시작
    if command -v brew &> /dev/null; then
        log_info "Redis 시작 중..."
        brew services start redis 2>/dev/null || true
    fi
    
    # 잠시 대기 (서비스 시작 시간)
    sleep 3
    
    log_success "의존성 서비스 시작 완료"
}

# 의존성 서비스 중지
stop_dependencies() {
    log_info "의존성 서비스 중지 중..."
    
    if command -v brew &> /dev/null; then
        brew services stop postgresql 2>/dev/null || true
        brew services stop redis 2>/dev/null || true
    fi
    
    log_success "의존성 서비스 중지 완료"
}

# 개발 서버 시작 (스마트 체크 포함)
start_dev_server() {
    log_info "개발 서버 시작 중..."
    
    # 의존성 서비스 자동 체크 및 시작
    check_and_start_services
    
    # 의존성 설치 체크
    check_dependencies
    
    # 빌드 상태 체크
    check_and_build_if_needed
    
    # 데이터베이스 상태 체크
    check_and_init_database
    
    # 개발 서버 시작
    log_info "개발 서버 시작 중..."
    pnpm run dev
}

# 기본 개발 서버 시작
start_basic_dev_server() {
    log_info "기본 개발 서버 시작 중..."
    
    # 의존성 서비스 자동 체크 및 시작
    check_and_start_services
    
    # 의존성 설치 체크
    check_dependencies
    
    # 빌드 상태 체크
    check_and_build_if_needed
    
    # 데이터베이스 상태 체크
    check_and_init_database
    
    # 기본 개발 서버 시작
    log_info "기본 개발 서버 시작 중..."
    pnpm run dev:basic
}

# 문서 서버 시작
start_docs_server() {
    log_info "문서 서버 시작 중..."
    
    # 의존성 서비스 자동 체크 및 시작
    check_and_start_services
    
    # 의존성 설치 체크
    check_dependencies
    
    # 빌드 상태 체크
    check_and_build_if_needed
    
    # 문서 서버 시작
    log_info "문서 서버 시작 중..."
    pnpm run dev:docs
}

# 전체 개발 서버 시작
start_full_dev_server() {
    log_info "전체 개발 서버 시작 중..."
    
    # 의존성 서비스 자동 체크 및 시작
    check_and_start_services
    
    # 의존성 설치 체크
    check_dependencies
    
    # 빌드 상태 체크
    check_and_build_if_needed
    
    # 데이터베이스 상태 체크
    check_and_init_database
    
    # 전체 개발 서버 시작
    log_info "전체 개발 서버 시작 중..."
    pnpm run dev:full
}

# 프로젝트 빌드
build_project() {
    log_info "프로젝트 빌드 중..."
    pnpm run build
    log_success "프로젝트 빌드 완료"
}

# 테스트 실행
run_tests() {
    log_info "테스트 실행 중..."
    pnpm run test
    log_success "테스트 실행 완료"
}

# 빌드 파일 정리
clean_project() {
    log_info "빌드 파일 정리 중..."
    pnpm run clean
    log_success "빌드 파일 정리 완료"
}

# 데이터베이스 초기화
init_database() {
    log_info "데이터베이스 초기화 중..."
    pnpm run db:init
    log_success "데이터베이스 초기화 완료"
}

# 데이터베이스 리셋
reset_database() {
    log_info "데이터베이스 리셋 중..."
    pnpm run db:reset
    log_success "데이터베이스 리셋 완료"
}

# 데이터베이스 시드
seed_database() {
    log_info "데이터베이스 시드 데이터 삽입 중..."
    pnpm run db:seed
    log_success "데이터베이스 시드 데이터 삽입 완료"
}

# 스마트 체크 함수들
check_and_start_services() {
    log_info "의존성 서비스 상태 확인 중..."
    
    # PostgreSQL 체크
    if ! brew services list | grep -q "postgresql@14.*started"; then
        log_warning "PostgreSQL이 실행되지 않고 있습니다. 시작 중..."
        brew services start postgresql@14
        sleep 3
    else
        log_success "PostgreSQL이 이미 실행 중입니다."
    fi
    
    # Redis 체크
    if ! brew services list | grep -q "redis.*started"; then
        log_warning "Redis가 실행되지 않고 있습니다. 시작 중..."
        brew services start redis
        sleep 2
    else
        log_success "Redis가 이미 실행 중입니다."
    fi
    
    # 데이터베이스 연결 테스트
    if ! /opt/homebrew/opt/postgresql@14/bin/pg_isready -h localhost -p 5432 -U postgres &>/dev/null; then
        log_warning "PostgreSQL 연결 대기 중..."
        sleep 5
    fi
}

check_dependencies() {
    log_info "프로젝트 의존성 확인 중..."
    
    if [ ! -d "node_modules" ] || [ ! -f "pnpm-lock.yaml" ]; then
        log_warning "의존성이 설치되지 않았습니다. 설치 중..."
        pnpm install
    else
        log_success "의존성이 이미 설치되어 있습니다."
    fi
}

check_and_build_if_needed() {
    log_info "빌드 상태 확인 중..."
    
    # 패키지 빌드 상태 체크
    BUILT_PACKAGES=0
    for package_dir in packages/*/; do
        if [ -d "${package_dir}dist" ]; then
            ((BUILT_PACKAGES++))
        fi
    done
    
    if [ $BUILT_PACKAGES -lt 3 ]; then
        log_warning "패키지가 빌드되지 않았습니다. 빌드 중..."
        pnpm run build:packages
        pnpm run codegen
    else
        log_success "패키지가 이미 빌드되어 있습니다."
    fi
}

check_and_init_database() {
    log_info "데이터베이스 상태 확인 중..."
    
    # 데이터베이스 존재 여부 확인
    if ! /opt/homebrew/opt/postgresql@14/bin/psql -h localhost -p 5432 -U postgres -d stackframe -c "SELECT 1;" &>/dev/null; then
        log_warning "데이터베이스가 초기화되지 않았습니다. 초기화 중..."
        pnpm run db:init
    else
        # 테이블 존재 여부 확인
        if ! /opt/homebrew/opt/postgresql@14/bin/psql -h localhost -p 5432 -U postgres -d stackframe -c "SELECT 1 FROM \"Project\" LIMIT 1;" &>/dev/null; then
            log_warning "데이터베이스 스키마가 없습니다. 초기화 중..."
            pnpm run db:init
        else
            log_success "데이터베이스가 이미 초기화되어 있습니다."
        fi
    fi
}

# 빠른 시작 함수
quick_start() {
    log_info "빠른 시작 모드..."
    
    # 모든 체크를 한 번에 수행
    check_and_start_services
    check_dependencies
    check_and_build_if_needed
    check_and_init_database
    
    log_success "모든 준비가 완료되었습니다!"
    
    # 개발 서버 시작
    log_info "개발 서버 시작 중..."
    pnpm run dev:basic
}

# 상태 확인 함수
status_check() {
    log_info "전체 시스템 상태 확인 중..."
    
    echo ""
    echo "=== 서비스 상태 ==="
    
    # PostgreSQL 상태
    if brew services list | grep -q "postgresql@14.*started"; then
        echo "✅ PostgreSQL: 실행 중"
    else
        echo "❌ PostgreSQL: 중지됨"
    fi
    
    # Redis 상태
    if brew services list | grep -q "redis.*started"; then
        echo "✅ Redis: 실행 중"
    else
        echo "❌ Redis: 중지됨"
    fi
    
    # 개발 서버 상태
    echo ""
    echo "=== 개발 서버 상태 ==="
    
    if lsof -i :8100 &>/dev/null; then
        echo "✅ 런치패드 (8100): 실행 중"
    else
        echo "❌ 런치패드 (8100): 중지됨"
    fi
    
    if lsof -i :8101 &>/dev/null; then
        echo "✅ 대시보드 (8101): 실행 중"
    else
        echo "❌ 대시보드 (8101): 중지됨"
    fi
    
    if lsof -i :8102 &>/dev/null; then
        echo "✅ 백엔드 (8102): 실행 중"
    else
        echo "❌ 백엔드 (8102): 중지됨"
    fi
    
    if lsof -i :8103 &>/dev/null; then
        echo "✅ 데모 앱 (8103): 실행 중"
    else
        echo "❌ 데모 앱 (8103): 중지됨"
    fi
    
    if lsof -i :8104 &>/dev/null; then
        echo "✅ 문서 (8104): 실행 중"
    else
        echo "❌ 문서 (8104): 중지됨"
    fi
    
    echo ""
    echo "=== 의존성 상태 ==="
    
    if [ -d "node_modules" ]; then
        echo "✅ Node 모듈: 설치됨"
    else
        echo "❌ Node 모듈: 설치 필요"
    fi
    
    BUILT_PACKAGES=0
    for package_dir in packages/*/; do
        if [ -d "${package_dir}dist" ]; then
            ((BUILT_PACKAGES++))
        fi
    done
    
    if [ $BUILT_PACKAGES -gt 0 ]; then
        echo "✅ 패키지 빌드: $BUILT_PACKAGES 개 완료"
    else
        echo "❌ 패키지 빌드: 필요"
    fi
}

# 메인 로직
case "${1:-help}" in
    "setup")
        check_requirements
        setup_environment
        ;;
    "deps")
        start_dependencies
        ;;
    "stop-deps")
        stop_dependencies
        ;;
    "dev")
        start_dev_server
        ;;
    "dev:basic")
        start_basic_dev_server
        ;;
    "dev:docs")
        start_docs_server
        ;;
    "dev:full")
        start_full_dev_server
        ;;
    "build")
        build_project
        ;;
    "test")
        run_tests
        ;;
    "clean")
        clean_project
        ;;
    "db:init")
        init_database
        ;;
    "db:reset")
        reset_database
        ;;
    "db:seed")
        seed_database
        ;;
    "quick"|"start")
        quick_start
        ;;
    "status")
        status_check
        ;;
    "help"|*)
        show_help
        ;;
esac