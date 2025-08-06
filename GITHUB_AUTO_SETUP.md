# 🚀 Stack Auth GitHub 자동 연동 완전 가이드

## 🎯 목표
Stack Auth 프로젝트를 개인 GitHub 레포지토리에 자동으로 연동하여, 모든 변경사항이 자동으로 커밋되고 푸시되도록 설정합니다.

## 📋 준비사항 체크리스트

### ✅ 1. GitHub 계정 및 레포지토리
- [ ] GitHub 계정 보유
- [ ] 새 레포지토리 생성 (예: `stack-auth-personal`)
- [ ] 레포지토리를 **빈 상태**로 생성 (README, .gitignore 추가 안 함)

### ✅ 2. Personal Access Token (PAT) 생성
- [ ] GitHub → Settings → Developer settings → Personal access tokens
- [ ] "Generate new token (classic)" 클릭
- [ ] 권한 선택: `repo`, `workflow`, `write:packages`, `delete:packages`
- [ ] 토큰 안전하게 저장

### ✅ 3. SSH 키 설정 (선택사항, 하지만 권장)
- [ ] SSH 키 생성: `ssh-keygen -t ed25519 -C "your-email@example.com"`
- [ ] SSH 에이전트에 추가: `ssh-add ~/.ssh/id_ed25519`
- [ ] GitHub에 공개 키 등록

## 🚀 자동 설정 실행 (원클릭 설정)

### 1단계: GitHub 통합 기능 설치
```bash
# GitHub 통합 기능을 기존 자동화 스크립트들에 추가
./github-integration.sh
```

### 2단계: 환경 변수 설정
```bash
# .envrc 파일 편집
nano .envrc

# 다음 내용을 실제 정보로 수정:
export GITHUB_USERNAME="your-actual-username"
export GITHUB_REPO="stack-auth-personal"
export GITHUB_TOKEN="ghp_your_actual_token_here"
export AUTO_COMMIT=true

# 환경 변수 적용
direnv allow
```

### 3단계: GitHub 자동 연동 설정
```bash
# 완전 자동 설정 실행
./github-auto-sync.sh setup
```

### 4단계: 별칭 적용
```bash
# 새로운 별칭들 적용
source ~/.zshrc
```

## 🎮 사용법

### 📱 새로운 GitHub 연동 별칭들

```bash
# GitHub 연동 관리
sgit-setup     # GitHub 연동 초기 설정
sgit-sync      # 수동 동기화 (변경사항 커밋 후 푸시)
sgit-status    # 동기화 상태 확인
sgit-push      # 메시지와 함께 커밋 후 푸시

# 통합 자동화 (백업/업데이트 + GitHub 동기화)
sbackup-sync   # 백업 생성 후 GitHub에 자동 푸시
supdate-sync   # 의존성 업데이트 후 GitHub에 자동 푸시
```

### 🔄 자동 동기화 방식

#### 1. **실시간 자동 동기화** (Git Hooks)
- 모든 `git commit` 후 자동으로 GitHub에 푸시
- 백그라운드에서 실행되어 개발 흐름 방해 안 함

#### 2. **정기 자동 동기화** (Cron)
- 30분마다 자동으로 변경사항 확인 및 동기화
- 커밋을 깜빡한 변경사항도 자동으로 처리

#### 3. **통합 자동화 동기화**
- 백업 생성 시 자동으로 GitHub에 백업 히스토리 동기화
- 의존성 업데이트 시 자동으로 변경사항 커밋 및 푸시

## 🛠 고급 설정

### GitHub Actions 자동 설정
프로젝트에 다음 워크플로우가 자동으로 생성됩니다:

#### 1. **자동 테스트** (`.github/workflows/auto-test.yml`)
- 푸시할 때마다 자동으로 타입 체크, 빌드, 테스트 실행
- Node.js 18, 20 버전에서 테스트

#### 2. **주간 의존성 업데이트** (`.github/workflows/dependency-update.yml`)
- 매주 월요일 오전 2시에 자동으로 의존성 업데이트
- Pull Request 자동 생성

### 환경별 설정

#### 개발 환경 (로컬)
```bash
# 자동 커밋 활성화
export AUTO_COMMIT=true

# 매번 변경사항 자동 푸시
# (Git hooks를 통해 자동 실행됨)
```

#### 프로덕션 환경
```bash
# 수동 커밋 모드
export AUTO_COMMIT=false

# 필요할 때만 수동 동기화
sgit-sync
```

## 📊 실제 사용 시나리오

### 🌅 매일 개발 시작
```bash
cdstack           # 프로젝트로 이동
sgit-status       # GitHub 동기화 상태 확인
sdev              # 개발 서버 시작
# 이후 모든 커밋이 자동으로 GitHub에 푸시됨
```

### 🔄 주간 유지보수
```bash
supdate-sync      # 의존성 업데이트 + GitHub 동기화
sbackup-sync      # 백업 생성 + GitHub 동기화
```

### 🚨 긴급 백업
```bash
# 현재 상태를 즉시 GitHub에 백업
sgit-push "긴급 백업: $(date)"
```

### 📈 프로젝트 상태 확인
```bash
sgit-status       # GitHub 동기화 상태
./automation-master.sh status  # 전체 시스템 상태
```

## 🔒 보안 고려사항

### 1. **토큰 보안**
- Personal Access Token을 `.envrc`에 저장 (Git에 커밋되지 않음)
- 토큰 만료 시 자동 알림 설정 권장

### 2. **민감한 파일 제외**
- `.env.local`, `.envrc` 등은 자동으로 `.gitignore`에 포함
- 데이터베이스 파일은 백업에만 포함, GitHub에는 푸시 안 됨

### 3. **브랜치 보호**
- GitHub에서 main 브랜치 보호 규칙 설정 권장
- Force push 방지

## 🎯 문제 해결

### ❌ "GitHub 레포지토리를 찾을 수 없습니다"
```bash
# 해결 방법:
1. GitHub에서 레포지토리가 실제로 생성되었는지 확인
2. GITHUB_USERNAME과 GITHUB_REPO 환경 변수 확인
3. Personal Access Token 권한 확인
```

### ❌ "Authentication failed"
```bash
# 해결 방법:
1. Personal Access Token이 올바른지 확인
2. 토큰 만료 여부 확인
3. 토큰 권한에 'repo' 포함되어 있는지 확인
```

### ❌ "Push rejected"
```bash
# 해결 방법:
sgit-status        # 상태 확인
git pull personal main  # 원격 변경사항 가져오기
sgit-sync          # 다시 동기화
```

## 🎉 완료 확인

설정이 완료되면 다음을 확인하세요:

### ✅ 자동 동기화 테스트
```bash
# 테스트 파일 생성
echo "# GitHub 연동 테스트" > github-test.md
git add github-test.md
git commit -m "test: GitHub 자동 연동 테스트"

# 몇 초 후 GitHub 레포지토리에서 확인
# 자동으로 푸시되었는지 확인
```

### ✅ 별칭 작동 확인
```bash
sgit-status       # 동기화 상태 확인
sbackup-sync      # 백업 + 동기화 테스트
```

### ✅ GitHub Actions 확인
- GitHub 레포지토리의 "Actions" 탭에서 워크플로우 실행 확인

## 🚀 이제 완전 자동화!

설정 완료 후:
- ✅ 모든 커밋이 자동으로 GitHub에 푸시
- ✅ 백업 생성 시 자동으로 GitHub 동기화
- ✅ 의존성 업데이트 시 자동으로 GitHub 동기화
- ✅ 30분마다 자동으로 변경사항 확인 및 동기화
- ✅ GitHub Actions를 통한 자동 테스트 및 의존성 업데이트

**이제 개발에만 집중하세요! GitHub 연동은 모두 자동으로 처리됩니다.** 🎉

---

*Stack Auth GitHub 자동 연동 시스템 - 완전 자동화 달성! 🏆*