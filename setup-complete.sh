#!/bin/bash

# Stack Auth 완전 자동화 설정 스크립트
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

echo "Stack Auth 완전 자동화 설정"
echo "=========================="
echo ""

# 1. 자동 시작 설정
log_info "1단계: 자동 시작 설정 실행 중..."
./setup-autostart.sh

echo ""

# 2. 별칭 설정
log_info "2단계: 개발 별칭 설정 중..."
STACK_PATH=$(pwd)
ALIAS_LINE="source $STACK_PATH/.zshrc_stack_aliases"

if ! grep -q ".zshrc_stack_aliases" ~/.zshrc; then
    echo "" >> ~/.zshrc
    echo "# Stack Auth 개발 별칭" >> ~/.zshrc
    echo "$ALIAS_LINE" >> ~/.zshrc
    log_success "개발 별칭이 ~/.zshrc에 추가되었습니다."
else
    log_success "개발 별칭이 이미 설정되어 있습니다."
fi

# 3. 개발환경 체크 및 초기화
log_info "3단계: 개발환경 초기 체크 및 설정 중..."
./dev.sh quick

echo ""
echo "🎉 완전 자동화 설정이 완료되었습니다!"
echo ""
echo "📋 설정된 내용:"
echo "  ✅ PostgreSQL/Redis 자동 시작"
echo "  ✅ asdf/direnv 자동 로드"
echo "  ✅ 개발 별칭 설정"
echo "  ✅ 의존성 자동 체크"
echo "  ✅ 데이터베이스 자동 초기화"
echo "  ✅ 패키지 자동 빌드"
echo ""
echo "🚀 이제 다음과 같이 사용하세요:"
echo ""
echo "  터미널 재시작 후:"
echo "  $ cdstack        # Stack Auth 디렉토리로 이동"
echo "  $ sdev           # 개발 서버 빠른 시작"
echo "  $ sstatus        # 상태 확인"
echo "  $ smonitor       # 실시간 모니터링"
echo "  $ slaunch        # 런치패드 브라우저에서 열기"
echo ""
echo "  또는 기존 방식:"
echo "  $ ./dev.sh quick # 빠른 시작"
echo "  $ ./dev.sh status # 상태 확인"
echo ""
echo "변경사항을 적용하려면 터미널을 재시작하거나:"
echo "$ source ~/.zshrc"
echo ""
log_success "설정이 완료되었습니다! 이제 매번 복잡한 설정 없이 개발을 시작할 수 있습니다."