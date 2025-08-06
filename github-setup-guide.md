# GitHub 자동 연동 설정 가이드

## 1. GitHub Personal Access Token (PAT) 생성

### 1-1. GitHub 웹사이트 접속
1. https://github.com 접속
2. 우측 상단 프로필 클릭 → Settings
3. 좌측 메뉴에서 "Developer settings" 클릭
4. "Personal access tokens" → "Tokens (classic)" 클릭
5. "Generate new token" → "Generate new token (classic)" 클릭

### 1-2. 토큰 설정
- **Note**: `Stack Auth Auto Sync` (토큰 이름)
- **Expiration**: `No expiration` (또는 원하는 기간)
- **Select scopes** (권한 선택):
  - ✅ `repo` (전체 저장소 접근)
  - ✅ `workflow` (GitHub Actions)
  - ✅ `write:packages` (패키지 업로드)
  - ✅ `delete:packages` (패키지 삭제)

### 1-3. 토큰 저장
- "Generate token" 클릭
- **중요**: 생성된 토큰을 안전한 곳에 복사 저장 (다시 볼 수 없음)
- 형태: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## 2. SSH 키 설정 (권장)

### 2-1. SSH 키 생성
```bash
# SSH 키 생성 (이메일은 GitHub 계정 이메일로 변경)
ssh-keygen -t ed25519 -C "your-email@example.com"

# 기본 경로에 저장 (Enter 누르기)
# 패스프레이즈 설정 (선택사항)
```

### 2-2. SSH 키를 SSH 에이전트에 추가
```bash
# SSH 에이전트 시작
eval "$(ssh-agent -s)"

# SSH 키 추가
ssh-add ~/.ssh/id_ed25519
```

### 2-3. 공개 키를 GitHub에 추가
```bash
# 공개 키 내용 복사
cat ~/.ssh/id_ed25519.pub
```

1. GitHub → Settings → SSH and GPG keys
2. "New SSH key" 클릭
3. Title: `Stack Auth Development`
4. Key: 복사한 공개 키 내용 붙여넣기
5. "Add SSH key" 클릭

## 3. 새 GitHub 레포지토리 생성

### 3-1. 레포지토리 생성
1. GitHub 메인 페이지에서 "New" 클릭
2. Repository name: `stack-auth-personal` (또는 원하는 이름)
3. Description: `Personal Stack Auth Development Environment`
4. Private/Public 선택
5. **중요**: README, .gitignore, license 추가하지 않기 (빈 레포지토리로 생성)
6. "Create repository" 클릭

### 3-2. 레포지토리 URL 확인
- HTTPS: `https://github.com/USERNAME/stack-auth-personal.git`
- SSH: `git@github.com:USERNAME/stack-auth-personal.git`

## 4. 환경 변수 설정

### 4-1. GitHub 정보를 환경 변수로 저장
```bash
# .envrc 파일에 추가 (direnv 사용)
echo 'export GITHUB_USERNAME="your-username"' >> .envrc
echo 'export GITHUB_REPO="stack-auth-personal"' >> .envrc
echo 'export GITHUB_TOKEN="ghp_your_token_here"' >> .envrc

# direnv 적용
direnv allow
```

### 4-2. Git 전역 설정
```bash
# Git 사용자 정보 설정
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"

# 기본 브랜치 이름 설정
git config --global init.defaultBranch main
```