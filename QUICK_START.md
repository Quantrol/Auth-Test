# Stack Auth 빠른 시작 가이드

## 🚀 5분 만에 시작하기

### 1. 필수 도구 설치 (한 번만)

```bash
# Homebrew 설치 (없는 경우)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 필수 도구들 설치
brew install asdf direnv postgresql redis

# Shell 설정 (zsh 사용 시)
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc
echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
source ~/.zshrc
```

### 2. 개발환경 설정

```bash
# 저장소 클론
git clone https://github.com/stack-auth/stack-auth.git
cd stack-auth

# 개발환경 자동 설정
./dev.sh setup
```

### 3. 개발 서버 시작

```bash
# 의존성 서비스 시작 (PostgreSQL, Redis)
./dev.sh deps

# 개발 서버 시작
./dev.sh dev
```

### 4. 접속 확인

- 개발 런치패드: http://localhost:8100
- 대시보드: http://localhost:8101
- API: http://localhost:8102

## 🛠 주요 명령어

```bash
./dev.sh help          # 도움말
./dev.sh setup         # 초기 설정
./dev.sh deps          # 서비스 시작
./dev.sh dev           # 개발 서버 시작
./dev.sh dev:basic     # 기본 서버만 시작
./dev.sh test          # 테스트 실행
./dev.sh clean         # 정리
```

## 🔧 문제 해결

설정 확인:
```bash
./check-setup.sh
```

서비스 재시작:
```bash
./dev.sh stop-deps
./dev.sh deps
```

## 📚 더 자세한 정보

- [개발환경 설정 가이드](DEVELOPMENT_SETUP.md)
- [기여 가이드](CONTRIBUTING.md)
- [공식 문서](https://docs.stack-auth.com)