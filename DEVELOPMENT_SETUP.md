# Stack Auth 개발환경 설정 가이드

이 가이드는 Docker 대신 asdf + direnv + dev.sh 조합을 사용하여 Stack Auth 로컬 개발환경을 설정하는 방법을 설명합니다.

## 📋 필수 요구사항

- macOS (Homebrew 사용)
- Node.js 20+
- pnpm 9+
- PostgreSQL 14+
- Redis 6+
- asdf (버전 관리 도구)
- direnv (환경변수 관리 도구)

## 🚀 빠른 시작

### 1단계: 저장소 클론

```bash
git clone https://github.com/stack-auth/stack-auth.git
cd stack-auth
```

### 2단계: 필수 도구 설치

```bash
# Homebrew가 없다면 먼저 설치
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 필수 도구들 설치
brew install asdf direnv postgresql redis

# Shell 설정에 asdf와 direnv 추가 (zsh 사용 시)
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc

# 설정 적용
source ~/.zshrc
```

### 3단계: 개발환경 자동 설정

```bash
# 모든 개발환경을 자동으로 설정
./dev.sh setup
```

이 명령은 다음을 수행합니다:
- asdf 플러그인 설치 (nodejs, pnpm)
- Node.js 20.17.0 및 pnpm 9.1.2 설치
- direnv 환경 허용
- 프로젝트 의존성 설치

### 4단계: 의존성 서비스 시작

```bash
# PostgreSQL과 Redis 서비스 시작
./dev.sh deps
```

### 5단계: 개발 서버 시작

```bash
# 전체 개발 서버 시작
./dev.sh dev

# 또는 기본 서버만 (백엔드 + 대시보드)
./dev.sh dev:basic
```

## 🛠 개발 스크립트 상세 설명

### 기본 명령어

| 명령어 | 설명 |
|--------|------|
| `./dev.sh help` | 도움말 표시 |
| `./dev.sh setup` | 개발환경 초기 설정 |
| `./dev.sh deps` | 의존성 서비스 시작 |
| `./dev.sh stop-deps` | 의존성 서비스 중지 |

### 개발 서버 명령어

| 명령어 | 설명 |
|--------|------|
| `./dev.sh dev` | 전체 개발 서버 시작 |
| `./dev.sh dev:basic` | 기본 개발 서버 시작 (백엔드 + 대시보드만) |

### 빌드 및 테스트 명령어

| 명령어 | 설명 |
|--------|------|
| `./dev.sh build` | 프로젝트 빌드 |
| `./dev.sh test` | 테스트 실행 |
| `./dev.sh clean` | 빌드 파일 정리 |

### 데이터베이스 명령어

| 명령어 | 설명 |
|--------|------|
| `./dev.sh db:init` | 데이터베이스 초기화 |
| `./dev.sh db:reset` | 데이터베이스 리셋 |
| `./dev.sh db:seed` | 시드 데이터 삽입 |

## 🌐 서비스 포트

개발 서버가 시작되면 다음 포트에서 서비스에 접근할 수 있습니다:

| 서비스 | 포트 | URL |
|--------|------|-----|
| 개발 런치패드 | 8100 | http://localhost:8100 |
| 대시보드 | 8101 | http://localhost:8101 |
| API 백엔드 | 8102 | http://localhost:8102 |
| 데모 앱 | 8103 | http://localhost:8103 |
| 문서 | 8104 | http://localhost:8104 |

## 🔧 환경변수 설정

환경변수는 `.envrc` 파일에서 자동으로 관리됩니다. 필요에 따라 수정할 수 있습니다:

```bash
# .envrc 파일 편집
vim .envrc

# 변경사항 적용
direnv reload
```

주요 환경변수:

- `DATABASE_URL`: PostgreSQL 연결 문자열
- `REDIS_URL`: Redis 연결 문자열
- `NEXT_PUBLIC_STACK_API_URL`: API 서버 URL
- `STACK_SECRET_SERVER_KEY`: 서버 시크릿 키

## 🐛 문제 해결

### 1. PostgreSQL 연결 오류

```bash
# PostgreSQL 서비스 상태 확인
brew services list | grep postgresql

# PostgreSQL 재시작
brew services restart postgresql

# 데이터베이스 생성 (필요시)
createdb stackframe
```

### 2. Redis 연결 오류

```bash
# Redis 서비스 상태 확인
brew services list | grep redis

# Redis 재시작
brew services restart redis
```

### 3. Node.js 버전 문제

```bash
# 현재 Node.js 버전 확인
node --version

# asdf로 올바른 버전 설치
asdf install nodejs 20.17.0
asdf global nodejs 20.17.0
```

### 4. pnpm 설치 문제

```bash
# pnpm 재설치
asdf uninstall pnpm 9.1.2
asdf install pnpm 9.1.2
```

### 5. 의존성 설치 오류

```bash
# 캐시 정리 후 재설치
pnpm store prune
pnpm install
```

### 6. TypeScript 오류

IDE에서 `@stackframe/XYZ` 임포트 오류가 표시되는 경우:

- VSCode: `Ctrl+Shift+P` → `TypeScript: Restart TS Server`
- 또는 `Developer: Reload Window`

## 📚 추가 정보

### 데이터베이스 관리

Prisma Studio를 사용하여 데이터베이스를 시각적으로 관리할 수 있습니다:

```bash
pnpm run prisma studio
```

### 로그 확인

개발 서버 로그는 터미널에서 실시간으로 확인할 수 있습니다. 로그 레벨은 `.envrc`에서 `LOG_LEVEL` 변수로 조정할 수 있습니다.

### 코드 변경사항 반영

- 대부분의 변경사항은 핫 리로드로 자동 반영됩니다
- 패키지 변경 시에는 `./dev.sh build` 실행 후 서버 재시작이 필요할 수 있습니다

## 🤝 기여하기

개발환경 설정이 완료되면 [CONTRIBUTING.md](CONTRIBUTING.md)를 참고하여 프로젝트에 기여할 수 있습니다.

문제가 발생하거나 질문이 있으면 [Discord](https://discord.stack-auth.com)에서 도움을 요청하세요.