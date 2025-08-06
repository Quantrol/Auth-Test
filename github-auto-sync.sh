#!/bin/bash

# Stack Auth GitHub 자동 연동 스크립트
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

# 환경 변수 확인
check_environment() {
    log_info "환경 변수 확인 중..."
    
    local missing_vars=()
    
    if [ -z "$GITHUB_USERNAME" ]; then
        missing_vars+=("GITHUB_USERNAME")
    fi
    
    if [ -z "$GITHUB_REPO" ]; then
        missing_vars+=("GITHUB_REPO")
    fi
    
    if [ -z "$GITHUB_TOKEN" ]; then
        missing_vars+=("GITHUB_TOKEN")
    fi
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "다음 환경 변수가 설정되지 않았습니다:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo ""
        echo "설정 방법:"
        echo "1. .envrc 파일에 다음 내용 추가:"
        echo "   export GITHUB_USERNAME=\"your-username\""
        echo "   export GITHUB_REPO=\"your-repo-name\""
        echo "   export GITHUB_TOKEN=\"ghp_your_token\""
        echo "2. direnv allow 실행"
        return 1
    fi
    
    log_success "환경 변수 확인 완료"
    echo "  GitHub 사용자: $GITHUB_USERNAME"
    echo "  레포지토리: $GITHUB_REPO"
    echo "  토큰: ${GITHUB_TOKEN:0:10}..."
}

# Git 원격 저장소 설정
setup_remote_repository() {
    log_info "Git 원격 저장소 설정 중..."
    
    # 현재 원격 저장소 확인
    if git remote get-url personal &>/dev/null; then
        log_info "기존 'personal' 원격 저장소 발견"
        local current_url=$(git remote get-url personal)
        echo "  현재 URL: $current_url"
        
        # URL 업데이트
        local new_url="https://${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git"
        git remote set-url personal "$new_url"
        log_success "원격 저장소 URL 업데이트 완료"
    else
        log_info "새 'personal' 원격 저장소 추가 중..."
        local remote_url="https://${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git"
        git remote add personal "$remote_url"
        log_success "원격 저장소 추가 완료"
    fi
    
    # 원격 저장소 목록 표시
    echo ""
    echo "현재 원격 저장소 목록:"
    git remote -v | sed 's/^/  /'
}

# GitHub 레포지토리 존재 확인
check_github_repository() {
    log_info "GitHub 레포지토리 존재 확인 중..."
    
    local api_url="https://api.github.com/repos/${GITHUB_USERNAME}/${GITHUB_REPO}"
    local response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "$api_url")
    
    if echo "$response" | grep -q '"message": "Not Found"'; then
        log_error "GitHub 레포지토리를 찾을 수 없습니다: ${GITHUB_USERNAME}/${GITHUB_REPO}"
        echo ""
        echo "해결 방법:"
        echo "1. GitHub에서 레포지토리를 생성하세요"
        echo "2. 레포지토리 이름이 GITHUB_REPO 환경 변수와 일치하는지 확인하세요"
        return 1
    fi
    
    log_success "GitHub 레포지토리 확인 완료"
    
    # 레포지토리 정보 표시
    local repo_name=$(echo "$response" | grep '"name"' | head -1 | cut -d'"' -f4)
    local repo_private=$(echo "$response" | grep '"private"' | head -1 | cut -d':' -f2 | tr -d ' ,')
    echo "  레포지토리: $repo_name"
    echo "  비공개: $repo_private"
}

# 초기 푸시 (빈 레포지토리인 경우)
initial_push() {
    log_info "초기 푸시 확인 중..."
    
    # 원격 브랜치 확인
    if git ls-remote --heads personal main &>/dev/null; then
        log_info "원격 레포지토리에 main 브랜치가 이미 존재합니다"
        return 0
    fi
    
    log_info "초기 푸시 실행 중..."
    
    # 현재 브랜치 확인
    local current_branch=$(git branch --show-current)
    
    # main 브랜치로 전환 (없으면 생성)
    if [ "$current_branch" != "main" ]; then
        if git show-ref --verify --quiet refs/heads/main; then
            git checkout main
        else
            git checkout -b main
        fi
    fi
    
    # 초기 커밋이 없는 경우 생성
    if ! git rev-parse --verify HEAD &>/dev/null; then
        echo "# Stack Auth Personal Development Environment" > README.md
        git add README.md
        git commit -m "Initial commit: Stack Auth personal development setup"
    fi
    
    # 초기 푸시
    git push -u personal main
    log_success "초기 푸시 완료"
}

# 자동 커밋 및 푸시
auto_commit_push() {
    local commit_message="$1"
    
    if [ -z "$commit_message" ]; then
        commit_message="Auto sync: $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    log_info "자동 커밋 및 푸시 실행 중..."
    
    # 변경사항 확인
    if git diff --quiet && git diff --cached --quiet; then
        log_info "커밋할 변경사항이 없습니다"
        return 0
    fi
    
    # 스테이징
    git add .
    
    # 커밋
    git commit -m "$commit_message"
    
    # 푸시
    git push personal main
    
    log_success "자동 커밋 및 푸시 완료"
    echo "  커밋 메시지: $commit_message"
}

# 동기화 상태 확인
check_sync_status() {
    log_info "동기화 상태 확인 중..."
    
    # 원격 정보 가져오기
    git fetch personal &>/dev/null || true
    
    # 로컬과 원격 비교
    local local_commit=$(git rev-parse HEAD 2>/dev/null || echo "none")
    local remote_commit=$(git rev-parse personal/main 2>/dev/null || echo "none")
    
    echo "  로컬 커밋:  ${local_commit:0:8}"
    echo "  원격 커밋:  ${remote_commit:0:8}"
    
    if [ "$local_commit" = "$remote_commit" ]; then
        log_success "로컬과 원격이 동기화되어 있습니다"
    elif [ "$remote_commit" = "none" ]; then
        log_warning "원격 브랜치가 존재하지 않습니다"
    else
        log_warning "로컬과 원격이 다릅니다"
        
        # 커밋 차이 확인
        local ahead=$(git rev-list --count personal/main..HEAD 2>/dev/null || echo "0")
        local behind=$(git rev-list --count HEAD..personal/main 2>/dev/null || echo "0")
        
        if [ "$ahead" -gt 0 ]; then
            echo "  로컬이 $ahead 커밋 앞서 있음"
        fi
        
        if [ "$behind" -gt 0 ]; then
            echo "  로컬이 $behind 커밋 뒤처져 있음"
        fi
    fi
}

# 자동 동기화 설정
setup_auto_sync() {
    log_info "자동 동기화 설정 중..."
    
    # Git hooks 디렉토리 생성
    mkdir -p .git/hooks
    
    # post-commit hook 생성
    cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
# Stack Auth 자동 GitHub 동기화

# 환경 변수 로드
if [ -f ".envrc" ]; then
    source .envrc
fi

# 자동 푸시 (백그라운드에서 실행)
if [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_REPO" ] && [ -n "$GITHUB_TOKEN" ]; then
    (
        sleep 2  # 약간의 지연
        git push personal main 2>/dev/null || true
    ) &
fi
EOF
    
    chmod +x .git/hooks/post-commit
    log_success "post-commit hook 설정 완료"
    
    # cron 작업 설정 (선택사항)
    local cron_entry="*/30 * * * * cd $(pwd) && ./github-auto-sync.sh sync > /dev/null 2>&1"
    
    if ! crontab -l 2>/dev/null | grep -q "github-auto-sync.sh"; then
        echo "자동 동기화 cron 작업을 설정하시겠습니까? (30분마다 실행) [y/N]"
        read -r setup_cron
        
        if [ "$setup_cron" = "y" ] || [ "$setup_cron" = "Y" ]; then
            (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
            log_success "cron 작업 설정 완료 (30분마다 자동 동기화)"
        fi
    fi
}

# 전체 설정 실행
full_setup() {
    echo -e "${CYAN}Stack Auth GitHub 자동 연동 설정${NC}"
    echo "=================================="
    echo ""
    
    check_environment || return 1
    echo ""
    
    setup_remote_repository
    echo ""
    
    check_github_repository || return 1
    echo ""
    
    initial_push
    echo ""
    
    setup_auto_sync
    echo ""
    
    check_sync_status
    echo ""
    
    log_success "GitHub 자동 연동 설정 완료!"
    echo ""
    echo "이제 다음과 같이 사용할 수 있습니다:"
    echo "  ./github-auto-sync.sh sync           # 수동 동기화"
    echo "  ./github-auto-sync.sh status         # 동기화 상태 확인"
    echo "  ./github-auto-sync.sh push \"메시지\"   # 커밋 후 푸시"
    echo ""
    echo "자동 동기화:"
    echo "  - 커밋할 때마다 자동으로 GitHub에 푸시됩니다"
    echo "  - cron 작업이 설정된 경우 30분마다 자동 동기화됩니다"
}

# 메인 로직
case "${1:-setup}" in
    "setup"|"s")
        full_setup
        ;;
    "sync")
        check_environment || exit 1
        auto_commit_push "$2"
        ;;
    "status"|"st")
        check_environment || exit 1
        check_sync_status
        ;;
    "push"|"p")
        check_environment || exit 1
        auto_commit_push "$2"
        ;;
    "check")
        check_environment || exit 1
        check_github_repository
        ;;
    "help"|"h")
        echo "Stack Auth GitHub 자동 연동 스크립트"
        echo "=================================="
        echo ""
        echo "사용법: ./github-auto-sync.sh [명령어] [옵션]"
        echo ""
        echo "명령어:"
        echo "  setup, s              - 전체 설정 실행 (기본값)"
        echo "  sync                  - 수동 동기화 (변경사항 커밋 후 푸시)"
        echo "  status, st            - 동기화 상태 확인"
        echo "  push, p [메시지]      - 커밋 후 푸시"
        echo "  check                 - GitHub 레포지토리 확인"
        echo "  help, h               - 이 도움말 표시"
        echo ""
        echo "예시:"
        echo "  ./github-auto-sync.sh setup"
        echo "  ./github-auto-sync.sh sync"
        echo "  ./github-auto-sync.sh push \"새 기능 추가\""
        echo ""
        echo "필요한 환경 변수:"
        echo "  GITHUB_USERNAME       - GitHub 사용자명"
        echo "  GITHUB_REPO          - 레포지토리 이름"
        echo "  GITHUB_TOKEN         - Personal Access Token"
        ;;
    *)
        log_error "알 수 없는 명령어: $1"
        echo "사용법: ./github-auto-sync.sh help"
        exit 1
        ;;
esac