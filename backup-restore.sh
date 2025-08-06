#!/bin/bash

# Stack Auth 개발 환경 백업 및 복원 스크립트
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

# 백업 디렉토리 설정
BACKUP_DIR="${HOME}/.stack-auth-backups"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
BACKUP_NAME="stack-auth-backup-${TIMESTAMP}"

# 백업 디렉토리 생성
ensure_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log_info "백업 디렉토리 생성: $BACKUP_DIR"
    fi
}

# 개발 환경 백업
backup_environment() {
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    
    log_info "개발 환경 백업 시작: $backup_path"
    
    ensure_backup_dir
    mkdir -p "$backup_path"
    
    # 설정 파일들 백업
    log_info "설정 파일 백업 중..."
    
    local config_files=(
        ".env.local"
        ".envrc"
        ".tool-versions"
        ".zshrc_stack_aliases"
        "package.json"
        "pnpm-lock.yaml"
        "pnpm-workspace.yaml"
        "turbo.json"
        ".vscode/settings.json"
        ".vscode/tasks.json"
        ".vscode/launch.json"
    )
    
    for file in "${config_files[@]}"; do
        if [ -f "$file" ]; then
            mkdir -p "$backup_path/$(dirname "$file")"
            cp "$file" "$backup_path/$file"
            log_info "  ✅ $file"
        else
            log_warning "  ⚠️  $file (파일 없음)"
        fi
    done
    
    # 데이터베이스 백업 (SQLite인 경우)
    log_info "데이터베이스 백업 중..."
    if [ -f "prisma/dev.db" ]; then
        mkdir -p "$backup_path/prisma"
        cp "prisma/dev.db" "$backup_path/prisma/"
        log_info "  ✅ SQLite 데이터베이스"
    fi
    
    # 커스텀 스크립트들 백업
    log_info "커스텀 스크립트 백업 중..."
    local scripts=(
        "dev.sh"
        "auto-heal.sh"
        "auto-update.sh"
        "backup-restore.sh"
        "check-setup.sh"
        "monitor.sh"
        "setup-autostart.sh"
        "setup-complete.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            cp "$script" "$backup_path/"
            log_info "  ✅ $script"
        fi
    done
    
    # Git 설정 백업
    log_info "Git 설정 백업 중..."
    if [ -d ".git" ]; then
        mkdir -p "$backup_path/.git"
        cp ".git/config" "$backup_path/.git/" 2>/dev/null || true
        git branch > "$backup_path/git-branches.txt" 2>/dev/null || true
        git status --porcelain > "$backup_path/git-status.txt" 2>/dev/null || true
        log_info "  ✅ Git 설정 및 상태"
    fi
    
    # 환경 정보 저장
    log_info "환경 정보 저장 중..."
    cat > "$backup_path/environment-info.txt" << EOF
백업 생성 시간: $(date)
운영체제: $(uname -a)
Node.js 버전: $(node --version 2>/dev/null || echo "설치되지 않음")
pnpm 버전: $(pnpm --version 2>/dev/null || echo "설치되지 않음")
asdf 버전: $(asdf --version 2>/dev/null || echo "설치되지 않음")
direnv 버전: $(direnv --version 2>/dev/null || echo "설치되지 않음")

설치된 asdf 플러그인:
$(asdf plugin list 2>/dev/null || echo "asdf가 설치되지 않음")

현재 디렉토리: $(pwd)
백업 경로: $backup_path
EOF
    
    # 백업 메타데이터 생성
    cat > "$backup_path/backup-metadata.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "backup_name": "$BACKUP_NAME",
  "backup_path": "$backup_path",
  "project_path": "$(pwd)",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "git_branch": "$(git branch --show-current 2>/dev/null || echo 'unknown')"
}
EOF
    
    # 백업 압축
    log_info "백업 압축 중..."
    cd "$BACKUP_DIR"
    tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
    rm -rf "$BACKUP_NAME"
    
    log_success "백업 완료: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    
    # 백업 목록 업데이트
    update_backup_list
}

# 백업 목록 업데이트
update_backup_list() {
    local list_file="$BACKUP_DIR/backup-list.txt"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $BACKUP_NAME" >> "$list_file"
    
    # 오래된 백업 정리 (30개 이상인 경우)
    local backup_count=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
    if [ "$backup_count" -gt 30 ]; then
        log_info "오래된 백업 정리 중..."
        cd "$BACKUP_DIR"
        ls -1t *.tar.gz | tail -n +31 | xargs rm -f
        log_info "$(($backup_count - 30))개의 오래된 백업을 삭제했습니다."
    fi
}

# 백업 목록 표시
list_backups() {
    ensure_backup_dir
    
    echo "사용 가능한 백업:"
    echo "=================="
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/*.tar.gz 2>/dev/null)" ]; then
        echo "백업이 없습니다."
        return 0
    fi
    
    cd "$BACKUP_DIR"
    local count=1
    for backup in $(ls -1t *.tar.gz 2>/dev/null); do
        local backup_name=$(basename "$backup" .tar.gz)
        local backup_date=$(echo "$backup_name" | grep -o '[0-9]\\{8\\}-[0-9]\\{6\\}')
        local formatted_date=$(echo "$backup_date" | sed 's/\\([0-9]\\{4\\}\\)\\([0-9]\\{2\\}\\)\\([0-9]\\{2\\}\\)-\\([0-9]\\{2\\}\\)\\([0-9]\\{2\\}\\)\\([0-9]\\{2\\}\\)/\\1-\\2-\\3 \\4:\\5:\\6/')\n        local size=$(du -h \"$backup\" | cut -f1)\n        \n        echo \"$count. $backup_name\"\n        echo \"   날짜: $formatted_date\"\n        echo \"   크기: $size\"\n        echo \"\"\n        \n        count=$((count + 1))\n    done\n}\n\n# 백업 복원\nrestore_environment() {\n    local backup_name=\"$1\"\n    \n    if [ -z \"$backup_name\" ]; then\n        echo \"복원할 백업을 선택하세요:\"\n        echo \"\"\n        list_backups\n        echo \"\"\n        echo \"백업 이름을 입력하세요 (예: stack-auth-backup-20240101-120000):\"\n        read -r backup_name\n    fi\n    \n    local backup_file=\"$BACKUP_DIR/${backup_name}.tar.gz\"\n    \n    if [ ! -f \"$backup_file\" ]; then\n        log_error \"백업 파일을 찾을 수 없습니다: $backup_file\"\n        return 1\n    fi\n    \n    log_info \"백업 복원 시작: $backup_name\"\n    \n    # 현재 환경 백업 (복원 전 안전장치)\n    log_info \"현재 환경을 안전 백업 중...\"\n    local safety_backup=\"stack-auth-safety-$(date '+%Y%m%d-%H%M%S')\"\n    BACKUP_NAME=\"$safety_backup\" backup_environment > /dev/null\n    \n    # 백업 압축 해제\n    log_info \"백업 압축 해제 중...\"\n    cd \"$BACKUP_DIR\"\n    tar -xzf \"${backup_name}.tar.gz\"\n    \n    # 파일 복원\n    log_info \"파일 복원 중...\"\n    local restore_path=\"$BACKUP_DIR/$backup_name\"\n    \n    # 설정 파일 복원\n    if [ -f \"$restore_path/.env.local\" ]; then\n        cp \"$restore_path/.env.local\" \"$(pwd)/.env.local\"\n        log_info \"  ✅ .env.local\"\n    fi\n    \n    if [ -f \"$restore_path/.envrc\" ]; then\n        cp \"$restore_path/.envrc\" \"$(pwd)/.envrc\"\n        log_info \"  ✅ .envrc\"\n    fi\n    \n    if [ -f \"$restore_path/.tool-versions\" ]; then\n        cp \"$restore_path/.tool-versions\" \"$(pwd)/.tool-versions\"\n        log_info \"  ✅ .tool-versions\"\n    fi\n    \n    # VSCode 설정 복원\n    if [ -d \"$restore_path/.vscode\" ]; then\n        mkdir -p \".vscode\"\n        cp -r \"$restore_path/.vscode/\"* \".vscode/\"\n        log_info \"  ✅ VSCode 설정\"\n    fi\n    \n    # 데이터베이스 복원\n    if [ -f \"$restore_path/prisma/dev.db\" ]; then\n        mkdir -p \"prisma\"\n        cp \"$restore_path/prisma/dev.db\" \"prisma/dev.db\"\n        log_info \"  ✅ SQLite 데이터베이스\"\n    fi\n    \n    # 스크립트 복원\n    local scripts=(\"dev.sh\" \"auto-heal.sh\" \"auto-update.sh\" \"backup-restore.sh\")\n    for script in \"${scripts[@]}\"; do\n        if [ -f \"$restore_path/$script\" ]; then\n            cp \"$restore_path/$script\" \"$(pwd)/$script\"\n            chmod +x \"$script\"\n            log_info \"  ✅ $script\"\n        fi\n    done\n    \n    # 임시 디렉토리 정리\n    rm -rf \"$restore_path\"\n    \n    log_success \"백업 복원 완료!\"\n    log_info \"안전 백업이 생성되었습니다: $safety_backup\"\n    \n    # 환경 재설정 권장\n    echo \"\"\n    log_warning \"복원 후 다음 명령어를 실행하는 것을 권장합니다:\"\n    echo \"  direnv allow\"\n    echo \"  asdf install\"\n    echo \"  pnpm install\"\n    echo \"  ./dev.sh setup\"\n}\n\n# 백업 삭제\ndelete_backup() {\n    local backup_name=\"$1\"\n    \n    if [ -z \"$backup_name\" ]; then\n        echo \"삭제할 백업을 선택하세요:\"\n        echo \"\"\n        list_backups\n        echo \"\"\n        echo \"백업 이름을 입력하세요:\"\n        read -r backup_name\n    fi\n    \n    local backup_file=\"$BACKUP_DIR/${backup_name}.tar.gz\"\n    \n    if [ ! -f \"$backup_file\" ]; then\n        log_error \"백업 파일을 찾을 수 없습니다: $backup_file\"\n        return 1\n    fi\n    \n    echo \"정말로 '$backup_name' 백업을 삭제하시겠습니까? (y/N)\"\n    read -r confirm\n    \n    if [ \"$confirm\" = \"y\" ] || [ \"$confirm\" = \"Y\" ]; then\n        rm -f \"$backup_file\"\n        log_success \"백업 삭제 완료: $backup_name\"\n    else\n        log_info \"삭제가 취소되었습니다.\"\n    fi\n}\n\n# 자동 백업 설정\nsetup_auto_backup() {\n    log_info \"자동 백업 설정 중...\"\n    \n    # crontab 항목 생성\n    local cron_entry=\"0 2 * * * cd $(pwd) && ./backup-restore.sh backup > /dev/null 2>&1\"\n    \n    # 기존 crontab 확인\n    if crontab -l 2>/dev/null | grep -q \"backup-restore.sh\"; then\n        log_warning \"자동 백업이 이미 설정되어 있습니다.\"\n        return 0\n    fi\n    \n    # crontab에 추가\n    (crontab -l 2>/dev/null; echo \"$cron_entry\") | crontab -\n    \n    log_success \"자동 백업이 설정되었습니다 (매일 오전 2시)\"\n    log_info \"현재 crontab 설정:\"\n    crontab -l | grep \"backup-restore.sh\"\n}\n\n# 메인 로직\ncase \"${1:-}\" in\n    \"backup\"|\"b\")\n        backup_environment\n        ;;\n    \"restore\"|\"r\")\n        restore_environment \"$2\"\n        ;;\n    \"list\"|\"l\")\n        list_backups\n        ;;\n    \"delete\"|\"d\")\n        delete_backup \"$2\"\n        ;;\n    \"auto-setup\")\n        setup_auto_backup\n        ;;\n    \"help\"|\"h\")\n        echo \"Stack Auth 백업 및 복원 스크립트\"\n        echo \"================================\"\n        echo \"\"\n        echo \"사용법: ./backup-restore.sh [명령어] [옵션]\"\n        echo \"\"\n        echo \"명령어:\"\n        echo \"  backup, b           - 현재 환경 백업\"\n        echo \"  restore, r [이름]   - 백업 복원\"\n        echo \"  list, l             - 백업 목록 표시\"\n        echo \"  delete, d [이름]    - 백업 삭제\"\n        echo \"  auto-setup          - 자동 백업 설정 (cron)\"\n        echo \"  help, h             - 이 도움말 표시\"\n        echo \"\"\n        echo \"예시:\"\n        echo \"  ./backup-restore.sh backup\"\n        echo \"  ./backup-restore.sh restore stack-auth-backup-20240101-120000\"\n        echo \"  ./backup-restore.sh list\"\n        echo \"  ./backup-restore.sh delete stack-auth-backup-20240101-120000\"\n        echo \"\"\n        echo \"백업 위치: $BACKUP_DIR\"\n        ;;\n    *)\n        log_error \"알 수 없는 명령어: ${1:-}\"\n        echo \"사용법: ./backup-restore.sh help\"\n        exit 1\n        ;;\nesac