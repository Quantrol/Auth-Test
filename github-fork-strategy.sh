#!/bin/bash

# Stack Auth 하드포크를 위한 GitHub 연동 전략
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 방법 1: 개발 브랜치 사용 (현재 dev 브랜치 활용)
setup_dev_branch_sync() {
    log_info "방법 1: 개발 브랜치(dev)를 개인 레포지토리 main으로 동기화"
    
    # 현재 브랜치 확인
    local current_branch=$(git branch --show-current)
    echo "현재 브랜치: $current_branch"
    
    # dev 브랜치로 전환 (이미 dev 브랜치인 경우 스킵)
    if [ "$current_branch" != "dev" ]; then
        git checkout dev || git checkout -b dev
    fi
    
    # 개인 레포지토리의 main 브랜치로 푸시
    log_info "dev 브랜치를 personal/main으로 푸시 중..."
    git push personal dev:main -f
    
    log_success "dev 브랜치가 개인 레포지토리 main으로 동기화되었습니다"
}

# 방법 2: 독립 브랜치 생성
setup_independent_branch() {
    log_info "방법 2: 완전 독립 브랜치 생성"
    
    # 새로운 독립 브랜치 생성
    local branch_name="personal-main"
    
    if git show-ref --verify --quiet refs/heads/$branch_name; then
        git checkout $branch_name
    else
        git checkout -b $branch_name
        log_success "새로운 독립 브랜치 '$branch_name' 생성"
    fi
    
    # 개인화 작업을 위한 초기 커밋
    echo "# Stack Auth Personal Fork" > PERSONAL_README.md
    echo "" >> PERSONAL_README.md
    echo "이 프로젝트는 Stack Auth의 개인 포크입니다." >> PERSONAL_README.md
    echo "원본: https://github.com/stack-auth/stack-auth" >> PERSONAL_README.md
    echo "포크 시작일: $(date)" >> PERSONAL_README.md
    
    git add PERSONAL_README.md
    git commit -m "feat: 개인 포크 초기화 - $(date)"
    
    # 개인 레포지토리로 푸시
    git push personal $branch_name:main -f
    
    log_success "독립 브랜치가 개인 레포지토리로 동기화되었습니다"
}

# 방법 3: 원본 히스토리 제거 후 새 시작
setup_clean_start() {
    log_info "방법 3: 원본 히스토리 제거 후 깔끔한 시작"
    
    log_warning "이 방법은 모든 Git 히스토리를 제거합니다. 신중하게 선택하세요."
    echo "계속하시겠습니까? (y/N)"
    read -r confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        log_info "취소되었습니다."
        return 0
    fi
    
    # 백업 생성
    local backup_branch="backup-$(date +%Y%m%d-%H%M%S)"
    git checkout -b $backup_branch
    git push personal $backup_branch
    log_info "백업 브랜치 '$backup_branch' 생성 완료"
    
    # 새로운 orphan 브랜치 생성 (히스토리 없음)
    git checkout --orphan personal-clean
    
    # 모든 파일 스테이징
    git add .
    
    # 초기 커밋
    git commit -m "🚀 Initial commit: Stack Auth Personal Fork

이 프로젝트는 Stack Auth를 기반으로 한 개인 포크입니다.

원본 프로젝트: https://github.com/stack-auth/stack-auth
포크 시작일: $(date)
개발자: $GITHUB_USERNAME

주요 변경사항:
- 완전 자동화된 개발 환경 구축
- 개인 맞춤형 설정 추가
- GitHub 자동 연동 시스템 구현"
    
    # 개인 레포지토리로 푸시
    git push personal personal-clean:main -f
    
    log_success "깔끔한 새 시작으로 개인 레포지토리 설정 완료"
}

# 방법 4: 하이브리드 접근법 (권장)
setup_hybrid_approach() {
    log_info "방법 4: 하이브리드 접근법 (원본 추적 + 개인 개발)"
    
    # 원본을 upstream으로 설정
    if ! git remote get-url upstream &>/dev/null; then
        git remote add upstream https://github.com/stack-auth/stack-auth.git
        log_success "원본 레포지토리를 upstream으로 추가"
    fi
    
    # 개인 개발 브랜치 생성
    local dev_branch="personal-dev"
    
    if git show-ref --verify --quiet refs/heads/$dev_branch; then
        git checkout $dev_branch
    else
        git checkout -b $dev_branch
        log_success "개인 개발 브랜치 '$dev_branch' 생성"
    fi
    
    # 개인화 마커 파일 생성
    cat > FORK_INFO.md << EOF
# Stack Auth Personal Fork

## 프로젝트 정보
- **원본**: https://github.com/stack-auth/stack-auth
- **개인 포크**: https://github.com/$GITHUB_USERNAME/$GITHUB_REPO
- **포크 시작일**: $(date)
- **개발자**: $GITHUB_USERNAME

## 주요 개선사항
- ✅ 완전 자동화된 개발 환경
- ✅ GitHub 자동 연동 시스템
- ✅ 실시간 모니터링 대시보드
- ✅ 자동 백업 및 복원 시스템
- ✅ 의존성 자동 업데이트

## 원본과의 동기화
\`\`\`bash
# 원본 최신 변경사항 가져오기
git fetch upstream
git merge upstream/main

# 또는 리베이스
git rebase upstream/main
\`\`\`

## 개발 워크플로우
1. 개인 개발: \`personal-dev\` 브랜치
2. 자동 동기화: GitHub Actions
3. 원본 추적: \`upstream\` 원격 저장소
EOF
    
    git add FORK_INFO.md
    git commit -m "docs: 개인 포크 정보 추가"
    
    # 개인 레포지토리로 푸시
    git push personal $dev_branch:main
    
    log_success "하이브리드 접근법으로 설정 완료"
    
    echo ""
    echo "이제 다음과 같이 사용할 수 있습니다:"
    echo "  git fetch upstream          # 원본 최신 변경사항 가져오기"
    echo "  git merge upstream/main     # 원본 변경사항 병합"
    echo "  git push personal $dev_branch:main  # 개인 레포지토리 업데이트"
}

# GitHub Auto-sync 스크립트 수정
update_github_sync_for_fork() {
    log_info "GitHub 자동 동기화 스크립트를 포크용으로 수정 중..."
    
    # 현재 브랜치를 기본으로 사용하도록 수정
    local current_branch=$(git branch --show-current)
    
    # github-auto-sync.sh 수정
    if [ -f "github-auto-sync.sh" ]; then
        # 백업 생성
        cp github-auto-sync.sh github-auto-sync.sh.backup
        
        # main 대신 현재 브랜치 사용하도록 수정
        sed -i.tmp "s/personal main/personal $current_branch:main/g" github-auto-sync.sh
        sed -i.tmp "s/git push personal main/git push personal $current_branch:main/g" github-auto-sync.sh
        
        rm -f github-auto-sync.sh.tmp
        
        log_success "GitHub 자동 동기화 스크립트가 포크용으로 수정되었습니다"
        echo "  현재 브랜치 '$current_branch'를 개인 레포지토리 main으로 푸시합니다"
    fi
}

# 메뉴 표시
show_menu() {
    echo -e "${CYAN}Stack Auth 하드포크를 위한 GitHub 연동 전략${NC}"
    echo "=============================================="
    echo ""
    echo "현재 상황:"
    echo "  - 브랜치: $(git branch --show-current)"
    echo "  - 원본: stack-auth/stack-auth"
    echo "  - 개인: $GITHUB_USERNAME/$GITHUB_REPO"
    echo ""
    echo "선택 가능한 방법들:"
    echo ""
    echo "1. 🔄 개발 브랜치 동기화 (현재 브랜치 → 개인 main)"
    echo "   - 현재 dev 브랜치를 개인 레포지토리 main으로 푸시"
    echo "   - 가장 간단하고 빠른 방법"
    echo ""
    echo "2. 🌿 독립 브랜치 생성"
    echo "   - 새로운 독립 브랜치 생성 후 개인화"
    echo "   - 원본과 구분되는 명확한 시작점"
    echo ""
    echo "3. 🧹 깔끔한 새 시작 (히스토리 제거)"
    echo "   - 모든 Git 히스토리 제거 후 새로 시작"
    echo "   - 완전히 독립적인 프로젝트로 전환"
    echo ""
    echo "4. 🔀 하이브리드 접근법 (권장)"
    echo "   - 원본 추적 + 개인 개발 브랜치"
    echo "   - 원본 업데이트 추적 가능"
    echo ""
    echo "5. ⚙️  현재 설정 수정만"
    echo "   - GitHub 자동 동기화 스크립트만 포크용으로 수정"
    echo ""
    echo "0. 종료"
    echo ""
}

# 메인 로직
main() {
    show_menu
    
    echo -n "원하는 방법을 선택하세요 (1-5, 0=종료): "
    read -r choice
    
    case $choice in
        1)
            setup_dev_branch_sync
            update_github_sync_for_fork
            ;;
        2)
            setup_independent_branch
            update_github_sync_for_fork
            ;;
        3)
            setup_clean_start
            update_github_sync_for_fork
            ;;
        4)
            setup_hybrid_approach
            update_github_sync_for_fork
            ;;
        5)
            update_github_sync_for_fork
            ;;
        0)
            log_info "종료합니다."
            exit 0
            ;;
        *)
            log_warning "잘못된 선택입니다."
            main
            ;;
    esac
    
    echo ""
    log_success "설정이 완료되었습니다!"
    echo ""
    echo "이제 다음 명령어로 동기화할 수 있습니다:"
    echo "  ./github-auto-sync.sh sync"
    echo "  ./github-auto-sync.sh push \"커밋 메시지\""
}

# 환경 변수 확인
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_REPO" ]; then
    echo "환경 변수를 먼저 설정하세요:"
    echo "  export GITHUB_USERNAME=\"Quantrol\""
    echo "  export GITHUB_REPO=\"Auth-Test\""
    echo "  export GITHUB_TOKEN=\"your_token\""
    exit 1
fi

main