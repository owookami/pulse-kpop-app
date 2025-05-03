#!/bin/bash

# Pulse 개발 환경 설정 스크립트
# 의존성 관리 및 개발 환경 초기화를 수행합니다.

# 색상 정의
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}Pulse 개발 환경 설정을 시작합니다...${NC}"
echo -e "${CYAN}===================================${NC}\n"

# 실행 환경 확인
echo -e "${YELLOW}환경 확인 중...${NC}"

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter가 설치되어 있지 않습니다. 설치 후 다시 시도해주세요.${NC}"
    exit 1
fi

if ! command -v melos &> /dev/null; then
    echo -e "${YELLOW}Melos가 설치되어 있지 않습니다. 설치합니다...${NC}"
    dart pub global activate melos
fi

# Flutter 버전 확인
FLUTTER_VERSION=$(flutter --version | grep -o "Flutter [0-9.]*" | cut -d' ' -f2)
echo -e "${GREEN}Flutter 버전: $FLUTTER_VERSION${NC}"

# 환경 클린업 및 초기화
echo -e "\n${YELLOW}환경 클린업 및 초기화 중...${NC}"
flutter clean
melos clean

# 의존성 설치
echo -e "\n${YELLOW}의존성 설치 중...${NC}"
melos bootstrap

# 코드 생성
echo -e "\n${YELLOW}코드 생성 중...${NC}"
melos generate

# 의존성 일관성 확인
echo -e "\n${YELLOW}의존성 일관성 확인 중...${NC}"
melos deps:check

echo -e "\n${GREEN}Pulse 개발 환경 설정이 완료되었습니다!${NC}"
echo -e "${CYAN}개발을 시작하려면 다음 명령어를 사용하세요:${NC}"
echo -e "${YELLOW}  - 앱 실행하기: cd apps/mobile && flutter run${NC}"
echo -e "${YELLOW}  - 패키지 테스트: melos test${NC}"
echo -e "${YELLOW}  - 코드 분석: melos analyze${NC}"
echo -e "${YELLOW}  - 코드 포맷팅: melos format${NC}" 