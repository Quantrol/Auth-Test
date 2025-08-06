#!/bin/bash

# Stack Auth 개발환경 설정 확인 스크립트
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

echo "Stack Auth 개발환경 설정 확인 중..."
echo "=================================="

# 1. 필수 도구 확인
log_info "필수 도구 확인 중..."

# asdf 확인
if command -v asdf &> /dev/null; then
    log_success "asdf 설치됨: $(asdf --version)"
else
    log_error "asdf가 설치되지 않았습니다."
    echo "설치 방법: brew install asdf"
    exit 1
fi

# direnv 확인
if command -v direnv &> /dev/null; then
    log_success "direnv 설치됨: $(direnv --version)"
else
    log_error "direnv가 설치되지 않았습니다."
    echo "설치 방법: brew install direnv"
    exit 1
fi

# PostgreSQL 확인
if command -v psql &> /dev/null; then
    log_success "PostgreSQL 설치됨: $(psql --version)"
else
    log_warning "PostgreSQL이 설치되지 않았습니다."
    echo "설치 방법: brew install postgresql"
fi

# Redis 확인
if command -v redis-server &> /dev/null; then
    log_success "Redis 설치됨: $(redis-server --version)"
else
    log_warning "Redis가 설치되지 않았습니다."
    echo "설치 방법: brew install redis"
fi

# 2. Node.js 및 pnpm 버전 확인
log_info "Node.js 및 pnpm 버전 확인 중..."

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    log_success "Node.js 설치됨: $NODE_VERSION"
    
    # Node.js 20 이상인지 확인
    if [[ $NODE_VERSION == v20* ]] || [[ $NODE_VERSION == v21* ]] || [[ $NODE_VERSION == v22* ]]; then
        log_success "Node.js 버전이 요구사항을 만족합니다."
    else
        log_warning "Node.js 20 이상이 권장됩니다. 현재: $NODE_VERSION"
    fi
else
    log_error "Node.js가 설치되지 않았습니다."
fi

if command -v pnpm &> /dev/null; then
    PNPM_VERSION=$(pnpm --version)
    log_success "pnpm 설치됨: $PNPM_VERSION"
else
    log_error "pnpm이 설치되지 않았습니다."
fi

# 3. 환경변수 확인
log_info "환경변수 확인 중..."

if [ -f ".envrc" ]; then
    log_success ".envrc 파일이 존재합니다."
    
    # direnv가 허용되었는지 확인
    if direnv status | grep -q "Found RC allowed true"; then
        log_success "direnv가 허용되었습니다."
    else
        log_warning "direnv가 허용되지 않았습니다. 'direnv allow' 명령을 실행하세요."
    fi
else
    log_error ".envrc 파일이 존재하지 않습니다."
fi

# 4. 서비스 상태 확인
log_info "서비스 상태 확인 중..."

# PostgreSQL 서비스 확인
if brew services list | grep -q "postgresql.*started"; then
    log_success "PostgreSQL 서비스가 실행 중입니다."
    
    # 데이터베이스 연결 테스트
    if psql -h localhost -p 5432 -U postgres -d stackframe -c "SELECT 1;" &> /dev/null; then
        log_success "PostgreSQL 데이터베이스 연결 성공"
    else
        log_warning "PostgreSQL 데이터베이스 'stackframe'에 연결할 수 없습니다."
        echo "데이터베이스 생성: createdb stackframe"
    fi
else
    log_warning "PostgreSQL 서비스가 실행되지 않고 있습니다."
    echo "서비스 시작: brew services start postgresql"
fi

# Redis 서비스 확인
if brew services list | grep -q "redis.*started"; then
    log_success "Redis 서비스가 실행 중입니다."
    
    # Redis 연결 테스트
    if redis-cli ping | grep -q "PONG"; then
        log_success "Redis 연결 성공"
    else
        log_warning "Redis에 연결할 수 없습니다."
    fi
else
    log_warning "Redis 서비스가 실행되지 않고 있습니다."
    echo "서비스 시작: brew services start redis"
fi

# 5. 프로젝트 의존성 확인
log_info "프로젝트 의존성 확인 중..."

if [ -d "node_modules" ]; then
    log_success "node_modules 디렉토리가 존재합니다."
else
    log_warning "node_modules 디렉토리가 존재하지 않습니다."
    echo "의존성 설치: pnpm install"
fi

if [ -f "pnpm-lock.yaml" ]; then
    log_success "pnpm-lock.yaml 파일이 존재합니다."
else
    log_warning "pnpm-lock.yaml 파일이 존재하지 않습니다."
fi

# 6. 빌드 파일 확인
log_info "빌드 상태 확인 중..."

BUILT_PACKAGES=0
for package_dir in packages/*/; do
    if [ -d "${package_dir}dist" ] || [ -d "${package_dir}.next" ]; then
        ((BUILT_PACKAGES++))
    fi
done

if [ $BUILT_PACKAGES -gt 0 ]; then
    log_success "$BUILT_PACKAGES 개의 패키지가 빌드되었습니다."
else
    log_warning "빌드된 패키지가 없습니다."
    echo "빌드 실행: ./dev.sh build 또는 pnpm run build:packages"
fi

echo ""
echo "=================================="
log_info "설정 확인 완료!"

# 권장사항 출력
echo ""
echo "다음 단계:"
echo "1. 누락된 도구가 있다면 설치하세요"
echo "2. 서비스가 실행되지 않고 있다면 './dev.sh deps' 명령을 실행하세요"
echo "3. 의존성이 설치되지 않았다면 './dev.sh setup' 명령을 실행하세요"
echo "4. 개발 서버를 시작하려면 './dev.sh dev' 명령을 실행하세요"