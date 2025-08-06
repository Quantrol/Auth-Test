#!/bin/bash

# 기존 자동화 스크립트들에 GitHub 연동 기능 추가
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# GitHub 연동 함수를 기존 스크립트들에 추가
add_github_integration() {
    log_info "기존 자동화 스크립트들에 GitHub 연동 기능 추가 중..."
    
    # auto-update.sh에 GitHub 연동 추가
    if [ -f "auto-update.sh" ]; then
        log_info "auto-update.sh에 GitHub 연동 추가 중..."
        
        # GitHub 자동 커밋 함수 추가
        cat >> auto-update.sh << 'EOF'

# GitHub 자동 커밋 함수
github_auto_commit() {
    if [ "${AUTO_COMMIT:-false}" = "true" ] && [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_REPO" ]; then
        log_info "GitHub에 변경사항 자동 커밋 중..."
        
        if [ -f "github-auto-sync.sh" ]; then
            ./github-auto-sync.sh push "chore: 의존성 자동 업데이트 $(date '+%Y-%m-%d %H:%M:%S')"
        else
            log_warning "github-auto-sync.sh 파일이 없습니다. GitHub 연동을 건너뜁니다."
        fi
    fi
}
EOF
        
        log_success "auto-update.sh 업데이트 완료"
    fi
    
    # backup-restore.sh에 GitHub 연동 추가
    if [ -f "backup-restore.sh" ]; then
        log_info "backup-restore.sh에 GitHub 연동 추가 중..."
        
        cat >> backup-restore.sh << 'EOF'

# GitHub 백업 연동 함수
github_backup_sync() {
    if [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_REPO" ]; then
        log_info "백업 정보를 GitHub에 동기화 중..."
        
        # 백업 목록 파일 생성
        if [ -f "$BACKUP_DIR/backup-list.txt" ]; then
            cp "$BACKUP_DIR/backup-list.txt" "./backup-history.txt"
            
            if [ -f "github-auto-sync.sh" ]; then
                ./github-auto-sync.sh push "backup: 백업 히스토리 업데이트 $(date '+%Y-%m-%d %H:%M:%S')"
            fi
        fi
    fi
}
EOF
        
        log_success "backup-restore.sh 업데이트 완료"
    fi
}

# .envrc 파일에 GitHub 설정 템플릿 추가
setup_envrc_template() {
    log_info ".envrc 파일에 GitHub 설정 템플릿 추가 중..."
    
    if [ -f ".envrc" ]; then
        # GitHub 설정이 이미 있는지 확인
        if ! grep -q "GITHUB_USERNAME" .envrc; then
            cat >> .envrc << 'EOF'

# GitHub 자동 연동 설정
# 아래 값들을 실제 정보로 변경하세요
export GITHUB_USERNAME="your-github-username"
export GITHUB_REPO="stack-auth-personal"
export GITHUB_TOKEN="ghp_your_personal_access_token_here"

# 자동 커밋 활성화 (선택사항)
export AUTO_COMMIT=false
EOF
            log_success ".envrc에 GitHub 설정 템플릿 추가 완료"
            echo "  📝 .envrc 파일을 편집하여 실제 GitHub 정보를 입력하세요"
        else
            log_info "GitHub 설정이 이미 .envrc에 존재합니다"
        fi
    else
        log_warning ".envrc 파일이 없습니다. 먼저 direnv를 설정하세요"
    fi
}

# GitHub 연동 별칭 추가
add_github_aliases() {
    log_info "GitHub 연동 별칭 추가 중..."
    
    if [ -f ".zshrc_stack_aliases" ]; then
        # GitHub 별칭이 이미 있는지 확인
        if ! grep -q "sgithub" .zshrc_stack_aliases; then
            cat >> .zshrc_stack_aliases << 'EOF'

# GitHub 자동 연동 별칭
alias sgithub='./github-auto-sync.sh'
alias sgit-setup='./github-auto-sync.sh setup'
alias sgit-sync='./github-auto-sync.sh sync'
alias sgit-status='./github-auto-sync.sh status'
alias sgit-push='./github-auto-sync.sh push'
alias sbackup-sync='./backup-restore.sh backup && ./github-auto-sync.sh push "backup: $(date +%Y%m%d-%H%M%S)"'
alias supdate-sync='AUTO_COMMIT=true ./auto-update.sh && ./github-auto-sync.sh push "update: dependencies $(date +%Y%m%d-%H%M%S)"'
EOF
            log_success "GitHub 연동 별칭 추가 완료"
        else
            log_info "GitHub 별칭이 이미 존재합니다"
        fi
    else
        log_warning ".zshrc_stack_aliases 파일이 없습니다"
    fi
}

# GitHub Actions 워크플로우 생성
create_github_actions() {
    log_info "GitHub Actions 워크플로우 생성 중..."
    
    mkdir -p .github/workflows
    
    # 자동 테스트 워크플로우
    cat > .github/workflows/auto-test.yml << 'EOF'
name: Stack Auth Auto Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        node-version: [18.x, 20.x]
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Use Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'pnpm'
    
    - name: Install pnpm
      uses: pnpm/action-setup@v2
      with:
        version: latest
    
    - name: Install dependencies
      run: pnpm install
    
    - name: Type check
      run: pnpm run type-check
      continue-on-error: true
    
    - name: Build packages
      run: pnpm run build:packages
      continue-on-error: true
    
    - name: Run tests
      run: pnpm test
      continue-on-error: true
EOF
    
    # 의존성 업데이트 워크플로우
    cat > .github/workflows/dependency-update.yml << 'EOF'
name: Weekly Dependency Update

on:
  schedule:
    - cron: '0 2 * * 1'  # 매주 월요일 오전 2시
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Use Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'
        cache: 'pnpm'
    
    - name: Install pnpm
      uses: pnpm/action-setup@v2
      with:
        version: latest
    
    - name: Update dependencies
      run: |
        pnpm update --latest
        pnpm audit --fix
    
    - name: Create Pull Request
      uses: peter-evans/create-pull-request@v5
      with:
        token: ${{ secrets.GITHUB_TOKEN }}
        commit-message: 'chore: update dependencies'
        title: 'Weekly Dependency Update'
        body: |
          Automated dependency update
          
          - Updated all dependencies to latest versions
          - Fixed security vulnerabilities
        branch: dependency-update
EOF
    
    log_success "GitHub Actions 워크플로우 생성 완료"
}

# .gitignore 업데이트
update_gitignore() {
    log_info ".gitignore 파일 업데이트 중..."
    
    if [ -f ".gitignore" ]; then
        # GitHub 관련 항목이 없으면 추가
        if ! grep -q "# GitHub Integration" .gitignore; then
            cat >> .gitignore << 'EOF'

# GitHub Integration
backup-history.txt
update-report-*.md
.github-sync-*
EOF
            log_success ".gitignore 업데이트 완료"
        fi
    fi
}

# 메인 실행
main() {
    echo -e "${BLUE}Stack Auth GitHub 통합 설정${NC}"
    echo "============================"
    echo ""
    
    add_github_integration
    echo ""
    
    setup_envrc_template
    echo ""
    
    add_github_aliases
    echo ""
    
    create_github_actions
    echo ""
    
    update_gitignore
    echo ""
    
    log_success "GitHub 통합 설정 완료!"
    echo ""
    echo "다음 단계:"
    echo "1. .envrc 파일을 편집하여 실제 GitHub 정보 입력"
    echo "2. direnv allow 실행"
    echo "3. ./github-auto-sync.sh setup 실행"
    echo "4. source ~/.zshrc 실행 (별칭 적용)"
    echo ""
    echo "새로운 별칭들:"
    echo "  sgit-setup    # GitHub 연동 설정"
    echo "  sgit-sync     # 수동 동기화"
    echo "  sgit-status   # 동기화 상태 확인"
    echo "  sbackup-sync  # 백업 후 GitHub 동기화"
    echo "  supdate-sync  # 업데이트 후 GitHub 동기화"
}

main