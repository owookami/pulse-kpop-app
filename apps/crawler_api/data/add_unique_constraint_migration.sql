-- videos 테이블에 unique 제약조건 추가

-- 1. 기존 중복 데이터 확인
-- 아래 쿼리를 실행해 중복 데이터를 확인할 수 있습니다.
-- SELECT platform_id, platform, COUNT(*) 
-- FROM videos 
-- GROUP BY platform_id, platform 
-- HAVING COUNT(*) > 1;

-- 2. 중복 데이터 처리 (가장 최근 항목 유지)
DO $$
DECLARE
    duplicate_record RECORD;
BEGIN
    -- 각 중복 그룹에서 가장 최근의 ID를 제외한 모든 레코드를 삭제
    FOR duplicate_record IN (
        SELECT platform_id, platform
        FROM videos
        GROUP BY platform_id, platform
        HAVING COUNT(*) > 1
    ) LOOP
        -- 중복 찾기 (가장 최근에 생성된 레코드를 제외한 나머지 삭제)
        DELETE FROM videos
        WHERE id IN (
            SELECT id
            FROM videos
            WHERE platform_id = duplicate_record.platform_id 
              AND platform = duplicate_record.platform
            ORDER BY created_at DESC, id DESC
            OFFSET 1
        );
        
        -- 로그
        RAISE NOTICE '% - % 중복 레코드 정리 완료', duplicate_record.platform, duplicate_record.platform_id;
    END LOOP;
END
$$;

-- 3. 제약조건 추가
ALTER TABLE videos
ADD CONSTRAINT videos_platform_id_platform_unique UNIQUE (platform_id, platform);

-- 4. 완료 로그
DO $$
BEGIN
    RAISE NOTICE '마이그레이션 완료: videos 테이블에 platform_id + platform 유니크 제약조건 추가됨';
END
$$; 