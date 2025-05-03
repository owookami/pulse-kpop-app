# Pulse Supabase 프로젝트 설정 가이드

이 문서는 Pulse 앱을 위한 Supabase 백엔드 설정 방법을 안내합니다.

## 목차

1. [프로젝트 생성](#1-프로젝트-생성)
2. [인증 시스템 설정](#2-인증-시스템-설정)
3. [데이터베이스 스키마 설정](#3-데이터베이스-스키마-설정)
4. [Row-Level Security 정책](#4-row-level-security-정책)
5. [API 키 및 URL 설정](#5-api-키-및-url-설정)
6. [스토리지 버킷 설정](#6-스토리지-버킷-설정)

## 1. 프로젝트 생성

1. [Supabase 대시보드](https://app.supabase.io/)에서 새 프로젝트를 생성합니다.
2. 프로젝트 이름: `pulse`
3. 데이터베이스 비밀번호를 생성하고 안전하게 저장합니다.
4. 리전 선택: 앱 사용자의 주요 위치에 가까운 리전을 선택합니다(예: `Asia Northeast 1 (Tokyo)`).
5. 요금제: 처음에는 무료 티어로 시작하고, 필요에 따라 업그레이드합니다.

## 2. 인증 시스템 설정

### 이메일/비밀번호 인증

1. `Authentication` > `Providers` 메뉴로 이동합니다.
2. `Email` 제공자가 기본적으로 활성화되어 있습니다.
3. `Confirm email` 옵션을 활성화하여 사용자 이메일 인증을 요구합니다.
4. 비밀번호 정책 설정:
   - 최소 8자 이상
   - 대문자, 소문자, 숫자 포함 필요

### 소셜 로그인 (선택사항)

1. `Authentication` > `Providers` 메뉴로 이동합니다.
2. 원하는 소셜 로그인 제공자(Google, Apple)를 활성화합니다.
3. 각 제공자의 설정에 따라 필요한 API 키와 시크릿을 구성합니다.

### 이메일 템플릿 설정

1. `Authentication` > `Email Templates` 메뉴로 이동합니다.
2. 다음 이메일 템플릿을 Pulse 브랜딩에 맞게 커스터마이징합니다:
   - 확인 메일
   - 비밀번호 초기화 메일
   - 이메일 변경 메일
   - SMS OTP 메시지

## 3. 데이터베이스 스키마 설정

### 기본 테이블

아래 SQL 쿼리를 `SQL Editor`에서 실행하여 기본 테이블을 생성합니다:

```sql
-- 타임스탬프 트리거 함수 생성
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 아티스트 테이블
CREATE TABLE artists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    image_url TEXT,
    group_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 비디오 테이블
CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    thumbnail_url TEXT,
    video_url TEXT NOT NULL,
    platform TEXT NOT NULL,
    platform_id TEXT NOT NULL,
    artist_id UUID REFERENCES artists(id) ON DELETE CASCADE,
    view_count BIGINT DEFAULT 0,
    like_count BIGINT DEFAULT 0,
    event_name TEXT,
    recorded_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(platform, platform_id)
);

-- 리뷰 테이블
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    rating SMALLINT CHECK (rating >= 1 AND rating <= 5),
    liked BOOLEAN DEFAULT NULL,
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, video_id)
);

-- 북마크 테이블
CREATE TABLE bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    collection_name TEXT DEFAULT 'default',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, video_id)
);

-- 팔로우 테이블
CREATE TABLE follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    artist_id UUID REFERENCES artists(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, artist_id)
);

-- 사용자 프로필 테이블
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 업데이트 트리거 생성
CREATE TRIGGER update_artists_updated_at BEFORE UPDATE ON artists
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_videos_updated_at BEFORE UPDATE ON videos
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookmarks_updated_at BEFORE UPDATE ON bookmarks
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_follows_updated_at BEFORE UPDATE ON follows
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 인덱스 생성

다음 SQL 쿼리를 실행하여 성능 최적화를 위한 인덱스를 생성합니다:

```sql
-- 외래 키 인덱스
CREATE INDEX idx_videos_artist_id ON videos(artist_id);
CREATE INDEX idx_reviews_video_id ON reviews(video_id);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_bookmarks_video_id ON bookmarks(video_id);
CREATE INDEX idx_bookmarks_user_id ON bookmarks(user_id);
CREATE INDEX idx_follows_artist_id ON follows(artist_id);
CREATE INDEX idx_follows_user_id ON follows(user_id);

-- 검색 인덱스
CREATE INDEX idx_artists_name ON artists(name);
CREATE INDEX idx_artists_group_name ON artists(group_name);
CREATE INDEX idx_videos_title ON videos(title);

-- 복합 인덱스
CREATE INDEX idx_bookmarks_user_collection ON bookmarks(user_id, collection_name);
CREATE INDEX idx_videos_platform_id ON videos(platform, platform_id);

-- 전문 검색 인덱스
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_artists_name_trgm ON artists USING GIN (name gin_trgm_ops);
CREATE INDEX idx_videos_title_trgm ON videos USING GIN (title gin_trgm_ops);
```

## 4. Row-Level Security 정책

다음 SQL 쿼리를 실행하여 RLS 정책을 설정합니다:

```sql
-- 모든 테이블에 RLS 활성화
ALTER TABLE artists ENABLE ROW LEVEL SECURITY;
ALTER TABLE videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 공개 읽기 정책 (artists, videos)
CREATE POLICY "Artists are viewable by everyone" ON artists
FOR SELECT USING (true);

CREATE POLICY "Videos are viewable by everyone" ON videos
FOR SELECT USING (true);

-- 관리자 쓰기 정책 (artists, videos)
CREATE POLICY "Artists are editable by admins" ON artists
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid() AND raw_user_meta_data->>'is_admin' = 'true'
  )
);

CREATE POLICY "Videos are editable by admins" ON videos
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid() AND raw_user_meta_data->>'is_admin' = 'true'
  )
);

-- 리뷰 정책
CREATE POLICY "Reviews are viewable by everyone" ON reviews
FOR SELECT USING (true);

CREATE POLICY "Users can create their own reviews" ON reviews
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reviews" ON reviews
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reviews" ON reviews
FOR DELETE USING (auth.uid() = user_id);

-- 북마크 정책
CREATE POLICY "Users can view their own bookmarks" ON bookmarks
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own bookmarks" ON bookmarks
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own bookmarks" ON bookmarks
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bookmarks" ON bookmarks
FOR DELETE USING (auth.uid() = user_id);

-- 팔로우 정책
CREATE POLICY "Users can view their own follows" ON follows
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own follows" ON follows
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own follows" ON follows
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own follows" ON follows
FOR DELETE USING (auth.uid() = user_id);

-- 프로필 정책
CREATE POLICY "Profiles are viewable by everyone" ON profiles
FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON profiles
FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
FOR UPDATE USING (auth.uid() = id);
```

## 5. API 키 및 URL 설정

1. `Project Settings` > `API` 메뉴로 이동합니다.
2. 두 가지 키를 기록해둡니다:
   - `anon` / `public`: 클라이언트 애플리케이션에서 사용
   - `service_role`: 서버 사이드 작업에만 사용 (주의: 이 키는 RLS를 우회합니다)
3. 프로젝트 URL을 기록합니다.
4. 이 키들을 안전하게 환경 변수로 저장합니다.

Flutter 앱의 `.env` 파일 예시:
```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## 6. 스토리지 버킷 설정

1. `Storage` 메뉴로 이동합니다.
2. 다음 버킷을 생성합니다:
   - `profile-images`: 사용자 프로필 이미지용
   - `artist-images`: 아티스트 이미지용
   - `thumbnails`: 비디오 썸네일 캐시용 (선택사항)

버킷 정책 설정:
```sql
-- 프로필 이미지 버킷 정책
CREATE POLICY "Profile images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-images');

CREATE POLICY "Users can upload their own profile image"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can update their own profile image"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can delete their own profile image"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 아티스트 이미지 버킷 정책
CREATE POLICY "Artist images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'artist-images');

CREATE POLICY "Only admins can manage artist images"
ON storage.objects FOR ALL
USING (
  bucket_id = 'artist-images' AND
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid() AND raw_user_meta_data->>'is_admin' = 'true'
  )
);

-- 썸네일 버킷 정책
CREATE POLICY "Thumbnails are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'thumbnails');

CREATE POLICY "Only admins can manage thumbnails"
ON storage.objects FOR ALL
USING (
  bucket_id = 'thumbnails' AND
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid() AND raw_user_meta_data->>'is_admin' = 'true'
  )
);
``` 