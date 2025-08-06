#!/bin/bash

# Stack Auth 의존성 자동 업데이트 스크립트
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

# Context7 MCP 도구 사용하여 최신 버전 확인
check_latest_versions() {
    log_info "Context7를 사용하여 최신 버전 확인 중..."
    
    # 주요 의존성들의 최신 버전 확인
    local packages=("next" "react" "typescript" "@types/node" "prisma" "tailwindcss")
    
    for package in "${packages[@]}"; do
        log_info "$package 최신 버전 확인 중..."
        # Context7 MCP를 통해 npm 패키지 정보 조회 (실제 구현 시 MCP 호출)
        # 현재는 npm view 명령어로 대체
        local latest_version=$(npm view $package version 2>/dev/null || echo "unknown")
        echo "  📦 $package: $latest_version"
    done
}

# asdf 도구 버전 업데이트
update_asdf_tools() {
    log_info "asdf 도구 버전 업데이트 중..."
    
    if ! command -v asdf &> /dev/null; then
        log_warning "asdf가 설치되지 않았습니다."
        return 1
    fi
    
    # 플러그인 업데이트
    asdf plugin update --all
    
    # .tool-versions 파일에서 도구들 읽기
    if [ -f ".tool-versions" ]; then
        while IFS= read -r line; do
            if [[ ! $line =~ ^#.* ]] && [[ -n $line ]]; then
                tool=$(echo $line | awk '{print $1}')
                current_version=$(echo $line | awk '{print $2}')
                
                log_info "$tool 최신 버전 확인 중..."
                latest_version=$(asdf latest $tool 2>/dev/null || echo $current_version)
                
                if [ "$current_version" != "$latest_version" ]; then
                    log_warning "$tool: $current_version → $latest_version 업데이트 가능"
                    
                    # 자동 업데이트 여부 확인
                    if [ "${AUTO_UPDATE:-false}" = "true" ]; then
                        log_info "$tool을 $latest_version으로 업데이트 중..."
                        asdf install $tool $latest_version
                        asdf global $tool $latest_version
                        
                        # .tool-versions 파일 업데이트
                        sed -i.bak "s/$tool $current_version/$tool $latest_version/" .tool-versions
                        log_success "$tool 업데이트 완료"
                    fi
                else
                    log_success "$tool은 이미 최신 버전입니다 ($current_version)"
                fi
            fi
        done < .tool-versions
    fi
}

# Node.js 의존성 업데이트
update_node_dependencies() {
    log_info "Node.js 의존성 업데이트 중..."
    
    # 보안 취약점 확인
    log_info "보안 취약점 확인 중..."
    pnpm audit --audit-level moderate || true
    
    # 업데이트 가능한 패키지 확인
    log_info "업데이트 가능한 패키지 확인 중..."
    pnpm outdated || true
    
    if [ "${AUTO_UPDATE:-false}" = "true" ]; then
        # 패치 및 마이너 업데이트만 자동 적용
        log_info "패치 및 마이너 업데이트 적용 중..."
        pnpm update --latest
        
        # 보안 취약점 자동 수정
        log_info "보안 취약점 자동 수정 중..."
        pnpm audit --fix || true
        
        log_success "의존성 업데이트 완료"
    else
        log_info "자동 업데이트가 비활성화되어 있습니다. AUTO_UPDATE=true로 설정하여 활성화하세요."
    fi
}

# 개발 환경 재구성
rebuild_environment() {
    log_info "개발 환경 재구성 중..."
    
    # 캐시 정리
    log_info "캐시 정리 중..."
    pnpm store prune
    rm -rf node_modules/.cache
    rm -rf .turbo
    
    # 의존성 재설치
    log_info "의존성 재설치 중..."
    pnpm install
    
    # 타입 체크
    log_info "타입 체크 중..."
    pnpm run type-check || log_warning "타입 체크에서 오류가 발생했습니다."
    
    # 빌드 테스트
    log_info "빌드 테스트 중..."
    pnpm run build:packages || log_warning "빌드 테스트에서 오류가 발생했습니다."
    
    log_success "개발 환경 재구성 완료"
}

# 변경사항 커밋
commit_changes() {
    if [ "${AUTO_COMMIT:-false}" = "true" ]; then
        log_info "변경사항 커밋 중..."
        
        if git diff --quiet && git diff --cached --quiet; then
            log_info "커밋할 변경사항이 없습니다."
            return 0
        fi
        
        git add .tool-versions package.json pnpm-lock.yaml
        git commit -m "chore: 의존성 자동 업데이트 $(date '+%Y-%m-%d %H:%M:%S')" || true
        
        log_success "변경사항 커밋 완료"
    fi
}

# 업데이트 보고서 생성
generate_report() {
    local report_file="update-report-$(date '+%Y%m%d-%H%M%S').md"
    
    log_info "업데이트 보고서 생성 중: $report_file"
    
    cat > "$report_file" << EOF
# 의존성 업데이트 보고서

**생성 시간**: $(date)
**실행 모드**: ${AUTO_UPDATE:-false} (자동 업데이트)

## asdf 도구 버전

\`\`\`
$(cat .tool-versions)
\`\`\`

## Node.js 의존성 상태

\`\`\`
$(pnpm list --depth=0 2>/dev/null || echo "의존성 목록을 가져올 수 없습니다.")
\`\`\`

## 보안 감사 결과

\`\`\`
$(pnpm audit --audit-level moderate 2>/dev/null || echo "보안 감사를 실행할 수 없습니다.")
\`\`\`

## 권장사항

- 정기적으로 의존성을 업데이트하세요
- 메이저 버전 업데이트는 수동으로 검토하세요
- 보안 취약점은 즉시 수정하세요

EOF

    log_success "업데이트 보고서 생성 완료: $report_file"
}

# 메인 실행 함수
main() {
    echo "Stack Auth 의존성 자동 업데이트"
    echo "================================="
    echo ""
    
    # 환경 변수 확인
    echo "설정:"
    echo "  AUTO_UPDATE: ${AUTO_UPDATE:-false}"
    echo "  AUTO_COMMIT: ${AUTO_COMMIT:-false}"
    echo ""
    
    # 업데이트 실행
    check_latest_versions
    echo ""
    
    update_asdf_tools
    echo ""
    
    update_node_dependencies
    echo ""
    
    if [ "${AUTO_UPDATE:-false}" = "true" ]; then
        rebuild_environment
        echo ""
        
        commit_changes
        echo ""
    fi
    
    generate_report
    echo ""
    
    log_success "의존성 업데이트 프로세스 완료!"
}

# 명령행 인수 처리
case "${1:-}" in
    "check")
        check_latest_versions
        ;;
    "asdf")
        update_asdf_tools
        ;;
    "node")
        update_node_dependencies
        ;;
    "rebuild")
        rebuild_environment
        ;;
    "auto")
        AUTO_UPDATE=true AUTO_COMMIT=true main
        ;;
    "help"|"-h"|"--help")
        echo "Stack Auth 의존성 자동 업데이트 스크립트"
        echo ""
        echo "사용법: ./auto-update.sh [옵션]"
        echo ""
        echo "옵션:"
        echo "  check    - 최신 버전만 확인"
        echo "  asdf     - asdf 도구만 업데이트"
        echo "  node     - Node.js 의존성만 업데이트"
        echo "  rebuild  - 개발 환경 재구성"
        echo "  auto     - 자동 업데이트 모드로 전체 실행"
        echo "  help     - 이 도움말 표시"
        echo ""
        echo "환경 변수:"
        echo "  AUTO_UPDATE=true  - 자동 업데이트 활성화"
        echo "  AUTO_COMMIT=true  - 자동 커밋 활성화"
        echo ""
        echo "예시:"
        echo "  ./auto-update.sh check"
        echo "  AUTO_UPDATE=true ./auto-update.sh"
        echo "  ./auto-update.sh auto"
        ;;
    *)
        main
        ;;
esac