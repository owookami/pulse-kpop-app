FROM python:3.11-slim

WORKDIR /app

# 캐싱을 위해 요구사항 먼저 복사
COPY requirements.txt .

# 종속성 설치
RUN pip install --no-cache-dir --upgrade -r requirements.txt

# 애플리케이션 코드 복사
COPY . .

# 환경 변수 설정
ENV PYTHONPATH=/app
ENV PORT=8000

# 포트 노출
EXPOSE 8000

# 애플리케이션 실행
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"] 