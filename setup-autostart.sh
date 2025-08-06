#!/bin/bash

# Stack Auth 자동 시작 설정 스크립트
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

echo "Stack Auth 자동 시작 설정"
echo "=========================="

# PostgreSQL 자동 시작 설정
log_info "PostgreSQL 자동 시작 설정 중..."
if brew services list | grep -q "postgresql@14.*started"; then
    log_success "PostgreSQL이 이미 실행 중입니다."
else
    brew services start postgresql@14
    log_success "PostgreSQL 자동 시작이 설정되었습니다."
fi

# Redis 자동 시작 설정
log_info "Redis 자동 시작 설정 중..."
if brew services list | grep -q "redis.*started"; then
    log_success "Redis가 이미 실행 중입니다."
else
    brew services start redis
    log_success "Redis 자동 시작이 설정되었습니다."
fi

# direnv 자동 로드 설정
log_info "direnv 자동 로드 설정 확인 중..."
if ! grep -q "direnv hook" ~/.zshrc; then
    echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
    log_success "direnv hook이 ~/.zshrc에 추가되었습니다."
else
    log_success "direnv hook이 이미 설정되어 있습니다."
fi

# asdf 자동 로드 설정
log_info "asdf 자동 로드 설정 확인 중..."
if ! grep -q "asdf.sh" ~/.zshrc; then
    echo '. $(brew --prefix asdf)/libexec/asdf.sh' >> ~/.zshrc
    log_success "asdf가 ~/.zshrc에 추가되었습니다."
else
    log_success "asdf가 이미 설정되어 있습니다."
fi

echo ""
log_success "자동 시작 설정이 완료되었습니다!"
echo ""
echo "이제 다음과 같이 동작합니다:"
echo "- PostgreSQL과 Redis가 시스템 시작 시 자동으로 실행됩니다"
echo "- 터미널을 열 때 asdf와 direnv가 자동으로 로드됩니다"
echo "- 프로젝트 디렉토리에 들어가면 환경변수가 자동으로 설정됩니다"
echo ""
echo "변경사항을 적용하려면 터미널을 재시작하거나 다음 명령을 실행하세요:"
echo "source ~/.zshrc"