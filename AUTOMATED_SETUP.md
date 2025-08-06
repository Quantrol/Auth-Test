# Stack Auth 자동화된 개발환경 가이드

## 🎯 문제 해결: 매번 서버 켜고 의존성 확인하는 번거로움

이제 **한 번 설정하면 끝**입니다! 더 이상 매번 복잡한 설정을 반복할 필요가 없습니다.

## 🚀 완전 자동화 설정 (한 번만 실행)

```bash
# 모든 자동화 설정을 한 번에 완료
./setup-complete.sh
```

이 명령어 하나로 다음이 모두 자동 설정됩니다:
- ✅ PostgreSQL/Redis 시스템 시작 시 자동 실행
- ✅ asdf/direnv 터미널 시작 시 자동 로드
- ✅ 개발 별칭 설정 (sdev, sstatus 등)
- ✅ 의존성 자동 체크 및 설치
- ✅ 데이터베이스 자동 초기화
- ✅ 패키지 자동 빌드

## 📱 이제 이렇게 간단하게 사용하세요

### 터미널 재시작 후 (또는 `source ~/.zshrc`)

```bash
# Stack Auth 디렉토리로 이동
cdstack

# 개발 서버 빠른 시작 (모든 체크 자동화)
sdev

# 상태 확인
sstatus

# 실시간 모니터링
smonitor
```

## 🛠 스마트 개발 명령어들

### 기본 개발 명령어
```bash
sdev           # 빠른 개발 서버 시작 (모든 체크 자동)
sstatus        # 전체 시스템 상태 확인
smonitor       # 실시간 모니터링
slogs          # 로그 모니터링
sperf          # 성능 분석
```

### 서비스 관리
```bash
sstart         # 의존성 서비스 시작
sstop          # 의존성 서비스 중지
srestart       # 의존성 서비스 재시작
```

### 데이터베이스 관리
```bash
sdb            # 데이터베이스 초기화
sdbreset       # 데이터베이스 리셋
sdbseed        # 시드 데이터 삽입
```

### 빠른 접속 (브라우저에서 자동 열기)
```bash
slaunch        # 런치패드 열기
sdash          # 대시보드 열기
sapi           # API 문서 열기
sdemo          # 데모 앱 열기
```

## 🔍 스마트 체크 기능

`./dev.sh quick` 또는 `sdev` 명령어는 다음을 자동으로 체크하고 처리합니다:

### 1. 서비스 상태 체크
- PostgreSQL이 실행 중인지 확인, 없으면 자동 시작
- Redis가 실행 중인지 확인, 없으면 자동 시작
- 데이터베이스 연결 테스트

### 2. 의존성 체크
- node_modules가 있는지 확인, 없으면 자동 설치
- pnpm-lock.yaml 존재 여부 확인

### 3. 빌드 상태 체크
- 패키지가 빌드되었는지 확인, 없으면 자동 빌드
- 필요한 경우에만 codegen 실행

### 4. 데이터베이스 상태 체크
- 데이터베이스 존재 여부 확인
- 스키마 테이블 존재 여부 확인
- 필요한 경우에만 초기화 실행

## 📊 실시간 모니터링

```bash
# 실시간 상태 모니터링 (5초마다 업데이트)
./monitor.sh monitor

# 또는 별칭 사용
smonitor
```

모니터링 화면에서 확인할 수 있는 정보:
- 🔧 시스템 서비스 상태 (PostgreSQL, Redis)
- 🌐 개발 서버 상태 (런치패드, 대시보드, 백엔드, 데모)
- 💾 리소스 사용량 (CPU, 메모리)
- 📊 데이터베이스 연결 상태

## 🎯 일반적인 사용 시나리오

### 매일 개발 시작할 때
```bash
cdstack    # 프로젝트로 이동
sdev       # 개발 서버 시작 (모든 체크 자동)
slaunch    # 런치패드 브라우저에서 열기
```

### 문제가 생겼을 때
```bash
sstatus    # 상태 확인
smonitor   # 실시간 모니터링으로 문제 파악
```

### 데이터베이스 문제가 있을 때
```bash
sdbreset   # 데이터베이스 리셋
sdbseed    # 시드 데이터 다시 삽입
```

### 빌드 문제가 있을 때
```bash
sclean     # 빌드 파일 정리
sbuild     # 다시 빌드
```

## 🔧 고급 사용법

### 기존 방식도 여전히 사용 가능
```bash
./dev.sh quick      # 빠른 시작
./dev.sh status     # 상태 확인
./dev.sh dev        # 전체 개발 서버
./dev.sh dev:basic  # 기본 서버만
```

### 모니터링 옵션
```bash
./monitor.sh monitor  # 실시간 상태
./monitor.sh logs     # 로그 모니터링
./monitor.sh perf     # 성능 분석
```

## 💡 팁과 요령

### 1. 터미널 시작 시 자동 실행
`~/.zshrc`에 다음을 추가하면 터미널 시작 시 자동으로 Stack Auth로 이동:
```bash
# 터미널 시작 시 Stack Auth로 자동 이동 (선택사항)
# cdstack
```

### 2. 개발 서버가 느릴 때
```bash
sperf      # 성능 분석으로 문제 파악
sclean     # 빌드 파일 정리
sdev       # 다시 시작
```

### 3. 포트 충돌이 있을 때
```bash
sstatus    # 어떤 포트가 사용 중인지 확인
# 필요시 다른 프로세스 종료 후 재시작
```

## 🎉 결론

이제 **매번 복잡한 설정을 반복할 필요가 없습니다!**

1. **한 번만 설정**: `./setup-complete.sh`
2. **매일 사용**: `cdstack && sdev`
3. **문제 해결**: `sstatus` 또는 `smonitor`

간단하고 효율적인 개발 환경을 즐기세요! 🚀
##
 🔧 추가 자동화 도구들

### 4. **의존성 자동 업데이트** ✅
```bash
# 최신 버전 확인 (Context7 MCP 사용)
./auto-update.sh check

# 자동 업데이트 실행
./auto-update.sh auto

# asdf 도구만 업데이트
./auto-update.sh asdf

# Node.js 의존성만 업데이트
./auto-update.sh node
```

**기능:**
- Context7 MCP 통합으로 최신 버전 확인
- asdf 도구 자동 업데이트
- Node.js 의존성 관리
- 보안 취약점 자동 수정
- 업데이트 보고서 자동 생성

### 5. **개발 환경 백업 및 복원** ✅
```bash
# 현재 환경 백업
./backup-restore.sh backup

# 백업 목록 확인
./backup-restore.sh list

# 백업 복원
./backup-restore.sh restore [백업이름]

# 자동 백업 설정 (매일 오전 2시)
./backup-restore.sh auto-setup
```

**백업 대상:**
- 설정 파일 (.env.local, .envrc, .tool-versions 등)
- VSCode 설정
- 데이터베이스 (SQLite)
- 커스텀 스크립트들
- Git 설정 및 상태

### 6. **통합 개발 대시보드** ✅
```bash
# 대화형 대시보드 실행
./dev-dashboard.sh

# 상태만 확인
./dev-dashboard.sh status

# 성능 메트릭 확인
./dev-dashboard.sh perf

# 최근 로그 확인
./dev-dashboard.sh logs
```

**대시보드 기능:**
- 실시간 시스템 상태 모니터링
- 개발 도구 버전 확인
- 서비스 상태 확인
- 성능 메트릭 표시
- 빠른 액션 메뉴 (서버 시작, 빌드, 테스트 등)
- 권장사항 표시

### 7. **자동 헬스체크 및 복구** ✅
```bash
# 전체 헬스체크 및 자동 복구
./auto-heal.sh

# 특정 서비스만 체크
./auto-heal.sh postgres
./auto-heal.sh redis
./auto-heal.sh node

# 모니터링 모드 (지속적 감시)
./auto-heal.sh monitor
```

**자동 복구 기능:**
- 서비스 자동 재시작
- 의존성 자동 재설치
- 데이터베이스 자동 복구
- 포트 충돌 해결
- 권한 문제 자동 수정

## 🎯 완전 자동화된 워크플로우

### 매일 개발 시작
```bash
cdstack                    # 프로젝트로 이동
./dev-dashboard.sh status  # 전체 상태 확인
sdev                      # 개발 서버 시작
```

### 주간 유지보수
```bash
./auto-update.sh check    # 업데이트 확인
./backup-restore.sh backup # 백업 생성
./auto-heal.sh           # 헬스체크
```

### 문제 발생 시
```bash
./dev-dashboard.sh       # 대화형 대시보드로 문제 파악
./auto-heal.sh          # 자동 복구 시도
```

## 🚀 Context7 MCP 통합

의존성 업데이트 스크립트는 Context7 MCP를 사용하여 최신 패키지 정보를 실시간으로 확인합니다:

```bash
# Context7를 통한 최신 버전 확인
./auto-update.sh check
```

이를 통해 다음 패키지들의 최신 버전을 자동으로 확인할 수 있습니다:
- Next.js
- React
- TypeScript
- Prisma
- Tailwind CSS
- 기타 주요 의존성들

## 💡 자동화 팁

### 1. 정기적인 백업
```bash
# cron을 통한 자동 백업 설정
./backup-restore.sh auto-setup
```

### 2. 의존성 자동 업데이트
```bash
# 환경 변수로 자동 업데이트 활성화
AUTO_UPDATE=true AUTO_COMMIT=true ./auto-update.sh
```

### 3. 지속적인 모니터링
```bash
# 백그라운드에서 지속적 헬스체크
nohup ./auto-heal.sh monitor &
```

이제 Stack Auth 개발 환경이 완전히 자동화되었습니다! 🎉