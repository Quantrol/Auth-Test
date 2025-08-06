#!/bin/bash

# Stack Auth 개발환경 모니터링 스크립트
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 실시간 상태 모니터링
monitor_services() {
    while true; do
        clear
        echo "Stack Auth 개발환경 실시간 모니터링"
        echo "=================================="
        echo "$(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        
        # 서비스 상태
        echo "🔧 시스템 서비스:"
        if brew services list | grep -q "postgresql@14.*started"; then
            echo -e "  ✅ PostgreSQL: ${GREEN}실행 중${NC}"
        else
            echo -e "  ❌ PostgreSQL: ${RED}중지됨${NC}"
        fi
        
        if brew services list | grep -q "redis.*started"; then
            echo -e "  ✅ Redis: ${GREEN}실행 중${NC}"
        else
            echo -e "  ❌ Redis: ${RED}중지됨${NC}"
        fi
        
        echo ""
        echo "🌐 개발 서버:"
        
        # 포트 체크 함수
        check_port() {
            local port=$1
            local name=$2
            if lsof -i :$port &>/dev/null; then
                local response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port 2>/dev/null || echo "000")
                if [ "$response" = "200" ]; then
                    echo -e "  ✅ $name ($port): ${GREEN}실행 중 (HTTP $response)${NC}"
                else
                    echo -e "  ⚠️  $name ($port): ${YELLOW}포트 열림, HTTP 응답 없음${NC}"
                fi
            else
                echo -e "  ❌ $name ($port): ${RED}중지됨${NC}"
            fi
        }
        
        check_port 8100 "런치패드"
        check_port 8101 "대시보드"
        check_port 8102 "백엔드 API"
        check_port 8103 "데모 앱"
        check_port 8104 "문서"
        
        echo ""
        echo "💾 리소스 사용량:"
        
        # CPU 사용량 (Node.js 프로세스)
        local node_cpu=$(ps aux | grep node | grep -v grep | awk '{sum += $3} END {printf "%.1f", sum}')
        echo "  🖥️  Node.js CPU: ${node_cpu:-0.0}%"
        
        # 메모리 사용량
        local node_mem=$(ps aux | grep node | grep -v grep | awk '{sum += $4} END {printf "%.1f", sum}')
        echo "  🧠 Node.js 메모리: ${node_mem:-0.0}%"
        
        echo ""
        echo "📊 데이터베이스 연결:"
        if /opt/homebrew/opt/postgresql@14/bin/pg_isready -h localhost -p 5432 -U postgres &>/dev/null; then
            echo -e "  ✅ PostgreSQL: ${GREEN}연결 가능${NC}"
        else
            echo -e "  ❌ PostgreSQL: ${RED}연결 불가${NC}"
        fi
        
        if redis-cli ping &>/dev/null | grep -q "PONG"; then
            echo -e "  ✅ Redis: ${GREEN}연결 가능${NC}"
        else
            echo -e "  ❌ Redis: ${RED}연결 불가${NC}"
        fi
        
        echo ""
        echo "Press Ctrl+C to exit"
        sleep 5
    done
}

# 로그 모니터링
monitor_logs() {
    echo "개발 서버 로그 모니터링 시작..."
    echo "Ctrl+C로 종료"
    echo ""
    
    # 백그라운드에서 실행 중인 개발 서버의 로그를 실시간으로 표시
    tail -f dev-server.log.untracked.txt 2>/dev/null || echo "로그 파일을 찾을 수 없습니다."
}

# 성능 분석
performance_analysis() {
    echo "Stack Auth 성능 분석"
    echo "==================="
    echo ""
    
    echo "🔍 프로세스 분석:"
    ps aux | grep -E "(node|pnpm)" | grep -v grep | head -10
    
    echo ""
    echo "🌐 포트 사용 현황:"
    lsof -i :8100-8110 2>/dev/null || echo "개발 서버가 실행되지 않고 있습니다."
    
    echo ""
    echo "💾 디스크 사용량:"
    du -sh node_modules 2>/dev/null || echo "node_modules 없음"
    du -sh packages/*/dist 2>/dev/null || echo "빌드 파일 없음"
    
    echo ""
    echo "🗄️ 데이터베이스 상태:"
    if /opt/homebrew/opt/postgresql@14/bin/psql -h localhost -p 5432 -U postgres -d stackframe -c "SELECT COUNT(*) as user_count FROM \"User\";" 2>/dev/null; then
        echo "데이터베이스 연결 성공"
    else
        echo "데이터베이스 연결 실패"
    fi
}

# 메인 메뉴
case "${1:-menu}" in
    "monitor"|"m")
        monitor_services
        ;;
    "logs"|"l")
        monitor_logs
        ;;
    "perf"|"p")
        performance_analysis
        ;;
    "menu"|*)
        echo "Stack Auth 모니터링 도구"
        echo "======================="
        echo ""
        echo "사용법: ./monitor.sh [옵션]"
        echo ""
        echo "옵션:"
        echo "  monitor, m  - 실시간 서비스 상태 모니터링"
        echo "  logs, l     - 개발 서버 로그 모니터링"
        echo "  perf, p     - 성능 분석"
        echo "  menu        - 이 메뉴 표시 (기본값)"
        ;;
esac