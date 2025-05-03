#!/bin/bash

# Pulse 프로젝트 GitHub Actions 시크릿 설정 스크립트
# 이 스크립트는 GitHub CLI가 설치되어 있어야 합니다.

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Pulse GitHub Actions 시크릿 설정 스크립트${NC}"
echo -e "${YELLOW}=======================================${NC}\n"

# GitHub CLI가 설치되어 있는지 확인
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI(gh)가 설치되어 있지 않습니다.${NC}"
    echo -e "${YELLOW}설치 방법: https://cli.github.com/manual/installation${NC}"
    exit 1
fi

# GitHub 로그인 상태 확인
if ! gh auth status &> /dev/null; then
    echo -e "${RED}GitHub에 로그인되어 있지 않습니다. 먼저 로그인해주세요.${NC}"
    echo -e "${YELLOW}다음 명령어로 로그인: gh auth login${NC}"
    exit 1
fi

echo -e "${GREEN}GitHub에 로그인되어 있습니다. 시크릿 설정을 진행합니다.${NC}\n"

# 저장소 정보 확인
REPO=$(git config --get remote.origin.url | sed -e 's|^.*github.com[:/]\(.*\)\.git$|\1|')
if [ -z "$REPO" ]; then
    echo -e "${RED}GitHub 저장소 정보를 찾을 수 없습니다.${NC}"
    echo -e "${YELLOW}이 스크립트는 GitHub 저장소 내에서 실행해야 합니다.${NC}"
    exit 1
fi

echo -e "${GREEN}저장소: $REPO${NC}\n"

# .env 파일 확인
if [ ! -f ".env" ]; then
    echo -e "${RED}.env 파일을 찾을 수 없습니다.${NC}"
    echo -e "${YELLOW}.env.example 파일을 .env로 복사하고 값을 입력한 후 다시 시도해주세요.${NC}"
    exit 1
fi

echo -e "${YELLOW}CI/CD에 필요한 시크릿을 GitHub Actions에 설정합니다.${NC}"
echo -e "${YELLOW}이 작업은 기존 시크릿을 덮어쓸 수 있습니다.${NC}"
read -p "계속하시겠습니까? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}스크립트를 종료합니다.${NC}"
    exit 0
fi

# .env 파일에서 시크릿 추출 및 설정
echo -e "\n${YELLOW}환경 변수 파일에서 시크릿을 추출하여 GitHub에 설정 중...${NC}"

# Supabase 관련 시크릿
SUPABASE_URL=$(grep -E "^SUPABASE_URL=" .env | cut -d '=' -f2-)
SUPABASE_ANON_KEY=$(grep -E "^SUPABASE_ANON_KEY=" .env | cut -d '=' -f2-)
SUPABASE_SERVICE_KEY=$(grep -E "^SUPABASE_SERVICE_KEY=" .env | cut -d '=' -f2-)

# Firebase 관련 시크릿
FIREBASE_PROJECT_ID=$(grep -E "^FIREBASE_PROJECT_ID=" .env | cut -d '=' -f2-)
FIREBASE_API_KEY=$(grep -E "^FIREBASE_API_KEY=" .env | cut -d '=' -f2-)
FIREBASE_APP_ID=$(grep -E "^FIREBASE_APP_ID=" .env | cut -d '=' -f2-)

# 시크릿 설정
echo -e "\n${YELLOW}GitHub Actions 시크릿 설정 중...${NC}"

# Supabase 시크릿 설정
gh secret set SUPABASE_URL --body "$SUPABASE_URL" -R "$REPO"
gh secret set SUPABASE_ANON_KEY --body "$SUPABASE_ANON_KEY" -R "$REPO"
gh secret set SUPABASE_SERVICE_KEY --body "$SUPABASE_SERVICE_KEY" -R "$REPO"

# Firebase 시크릿 설정
gh secret set FIREBASE_PROJECT_ID --body "$FIREBASE_PROJECT_ID" -R "$REPO"
gh secret set FIREBASE_API_KEY --body "$FIREBASE_API_KEY" -R "$REPO"
gh secret set FIREBASE_APP_ID --body "$FIREBASE_APP_ID" -R "$REPO"

# Codemagic 관련 시크릿 입력 요청
echo -e "\n${YELLOW}Codemagic 통합을 위한 시크릿을 입력해주세요.${NC}"
read -p "Codemagic API 토큰: " CODEMAGIC_API_TOKEN
read -p "Codemagic 앱 ID: " CODEMAGIC_APP_ID
read -p "Codemagic 워크플로우 ID: " CODEMAGIC_WORKFLOW_ID

# Codemagic 시크릿 설정
gh secret set CODEMAGIC_API_TOKEN --body "$CODEMAGIC_API_TOKEN" -R "$REPO"
gh secret set CODEMAGIC_APP_ID --body "$CODEMAGIC_APP_ID" -R "$REPO"
gh secret set CODEMAGIC_WORKFLOW_ID --body "$CODEMAGIC_WORKFLOW_ID" -R "$REPO"

echo -e "\n${GREEN}✅ GitHub Actions 시크릿 설정이 완료되었습니다!${NC}"
echo -e "${YELLOW}CI/CD 파이프라인이 이제 구성된 시크릿을 사용할 수 있습니다.${NC}"
exit 0 