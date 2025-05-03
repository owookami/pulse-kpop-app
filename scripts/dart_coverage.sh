#!/bin/bash

# Pulse 프로젝트의 Dart 코드 커버리지 스크립트

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 필요한 도구 체크
if ! command -v lcov &> /dev/null; then
    echo -e "${RED}lcov이 설치되어 있지 않습니다. 설치해주세요:${NC}"
    echo -e "${YELLOW}macOS: brew install lcov${NC}"
    echo -e "${YELLOW}Ubuntu: sudo apt-get install lcov${NC}"
    exit 1
fi

echo -e "${YELLOW}Dart 코드 커버리지 검사 시작...${NC}"
echo -e "${YELLOW}=============================${NC}\n"

# 프로젝트 루트로 이동
cd $(git rev-parse --show-toplevel) || { echo -e "${RED}Git 저장소를 찾을 수 없습니다.${NC}"; exit 1; }

# 모든 패키지에 대한 테스트 및 커버리지 수집
for pkg in apps/* packages/*; do
  if [ -d "$pkg" ]; then
    echo -e "${YELLOW}패키지 $pkg 테스트 실행 및 커버리지 수집 중...${NC}"
    
    # 디렉토리 변경
    cd $pkg
    
    # coverage 디렉토리 생성
    mkdir -p coverage
    
    # 테스트 실행 및 커버리지 파일 생성
    if flutter test --coverage; then
      echo -e "${GREEN}✓ 패키지 $pkg 테스트 성공${NC}"
      
      # lcov.info 파일 위치 확인
      if [ -f "coverage/lcov.info" ]; then
        echo -e "${GREEN}✓ 커버리지 정보 생성됨${NC}"
        
        # lcov를 사용하여 커버리지 보고서 생성
        genhtml coverage/lcov.info -o coverage/html
        
        echo -e "${GREEN}✓ 커버리지 HTML 보고서 생성됨: $pkg/coverage/html/index.html${NC}"
      else
        echo -e "${RED}✗ 커버리지 정보 파일을 찾을 수 없습니다.${NC}"
      fi
    else
      echo -e "${RED}✗ 패키지 $pkg 테스트 실패${NC}"
    fi
    
    # 루트 디렉토리로 돌아가기
    cd $(git rev-parse --show-toplevel)
  fi
done

echo -e "\n${GREEN}✓ 모든 패키지의 커버리지 검사 완료!${NC}"
echo -e "${YELLOW}각 패키지의 coverage/html 디렉토리에서 커버리지 보고서를 확인할 수 있습니다.${NC}"
exit 0 