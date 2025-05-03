#!/bin/bash

# Pulse 프로젝트의 린트 검사 스크립트
# 커밋이나 PR 전 코드 품질을 검사합니다.

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Pulse 린트 검사 시작...${NC}"
echo -e "${YELLOW}====================${NC}\n"

# Dart 분석
echo -e "${YELLOW}Dart 정적 분석 실행 중...${NC}"
cd $(git rev-parse --show-toplevel) # 프로젝트 루트로 이동

# Melos를 통한 정적 분석 실행
if melos analyze; then
  echo -e "${GREEN}✓ 정적 분석 통과${NC}"
else
  echo -e "${RED}✗ 정적 분석 실패${NC}"
  echo -e "${YELLOW}문제를 해결한 후 다시 시도해주세요.${NC}"
  exit 1
fi

# 코드 포맷팅 검사
echo -e "\n${YELLOW}코드 포맷팅 검사 중...${NC}"
if melos format; then
  echo -e "${GREEN}✓ 코드 포맷팅 통과${NC}"
else
  echo -e "${RED}✗ 코드 포맷팅 실패${NC}"
  echo -e "${YELLOW}아래 명령어로 코드 포맷을 수정할 수 있습니다:${NC}"
  echo -e "  melos format"
  exit 1
fi

# 의존성 일관성 검사
echo -e "\n${YELLOW}의존성 일관성 검사 중...${NC}"
if melos deps:check; then
  echo -e "${GREEN}✓ 의존성 일관성 검사 통과${NC}"
else
  echo -e "${RED}✗ 의존성 일관성 검사 실패${NC}"
  echo -e "${YELLOW}패키지 간 일관되지 않은 의존성이 있습니다.${NC}"
  echo -e "${YELLOW}아래 명령어로 의존성 문제를 해결할 수 있습니다:${NC}"
  echo -e "  melos deps:fix"
  exit 1
fi

# 모든 검사 통과
echo -e "\n${GREEN}✓ 모든 린트 검사 통과!${NC}"
exit 0 