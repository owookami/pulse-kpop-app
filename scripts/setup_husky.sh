#!/bin/bash

# Pulse 프로젝트 Husky Git Hooks 설정 스크립트

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Pulse Git Hooks 설정 시작...${NC}"
echo -e "${YELLOW}=========================${NC}\n"

# npm이 설치되었는지 확인
if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm이 설치되어 있지 않습니다. Node.js와 npm을 설치한 후 다시 시도해주세요.${NC}"
    exit 1
fi

# 프로젝트 루트로 이동
cd $(git rev-parse --show-toplevel) || { echo -e "${RED}Git 저장소를 찾을 수 없습니다.${NC}"; exit 1; }
echo -e "${GREEN}프로젝트 디렉토리: $(pwd)${NC}\n"

# package.json이 있는지 확인
if [ ! -f package.json ]; then
    echo -e "${YELLOW}package.json을 생성합니다...${NC}"
    npm init -y
fi

# husky 설치
echo -e "${YELLOW}husky 패키지를 설치하는 중...${NC}"
npm install --save-dev husky

# husky 초기화
echo -e "${YELLOW}husky를 초기화하는 중...${NC}"
npx husky install

# Git hooks 경로 생성
mkdir -p .husky

# pre-commit 스크립트 실행 권한 설정
chmod +x .husky/pre-commit

echo -e "\n${GREEN}✅ Git Hooks 설정이 완료되었습니다!${NC}"
echo -e "${YELLOW}앞으로 모든 커밋 전에 린트 검사가 자동으로 실행됩니다.${NC}" 