import 'package:meta/meta.dart';

/// 비디오 모델
@immutable
class Video {
  /// 비디오 생성자
  const Video({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.platform,
    required this.platformId,
    required this.artistId,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.thumbnailUrl,
    this.viewCount = 0,
    this.likeCount = 0,
    this.eventName,
    this.recordedDate,
  });

  /// 비디오 ID
  final String id;

  /// 비디오 제목
  final String title;

  /// 비디오 URL
  final String videoUrl;

  /// 비디오 플랫폼 (YouTube, Vimeo 등)
  final String platform;

  /// 플랫폼에서의 ID
  final String platformId;

  /// 아티스트 ID
  final String artistId;

  /// 생성 일시
  final DateTime createdAt;

  /// 수정 일시
  final DateTime updatedAt;

  /// 비디오 설명
  final String? description;

  /// 썸네일 URL
  final String? thumbnailUrl;

  /// 조회수
  final int viewCount;

  /// 좋아요 수
  final int likeCount;

  /// 이벤트 이름
  final String? eventName;

  /// 촬영 날짜
  final DateTime? recordedDate;

  /// JSON으로부터 비디오 객체 생성
  factory Video.fromJson(Map<String, dynamic> json) {
    try {
      // 유효성 검사 추가 - 필수 필드가 있는지 확인
      final requiredFields = ['id', 'title', 'video_url'];
      final missingFields =
          requiredFields.where((field) => !json.containsKey(field) || json[field] == null).toList();

      if (missingFields.isNotEmpty) {
        print('필수 필드 누락: $missingFields');
        throw FormatException('필수 필드 누락: $missingFields');
      }

      // 필드 매핑 처리 - API 응답과 모델 필드 간의 차이 해결
      String artistId = '';
      if (json.containsKey('artist_id')) {
        artistId = json['artist_id']?.toString() ?? '';
      } else if (json.containsKey('artist')) {
        // 'artist' 필드가 있고 'artist_id'가 없는 경우, 'artist'를 'artist_id'로 사용
        artistId = json['artist']?.toString() ?? '';
      }

      String platformId = '';
      if (json.containsKey('platform_id')) {
        platformId = json['platform_id']?.toString() ?? '';
      } else {
        // platform_id가 없는 경우 비디오 URL에서 추출하거나 빈 문자열 사용
        platformId = '';
      }

      String platform = '';
      if (json.containsKey('platform')) {
        platform = json['platform']?.toString() ?? 'YouTube';
      } else {
        // 기본적으로 YouTube 가정
        platform = 'YouTube';
      }

      // thumbnailUrl 처리 개선
      String? thumbnailUrl;
      if (json.containsKey('thumbnail_url')) {
        if (json['thumbnail_url'] == null) {
          // null인 경우 YouTube 썸네일 URL 생성
          if (json.containsKey('platform_id') && platform.toLowerCase() == 'youtube') {
            thumbnailUrl = 'https://i.ytimg.com/vi/${json['platform_id']}/hqdefault.jpg';
            print('thumbnailUrl이 null이어서 기본값 생성: $thumbnailUrl');
          } else {
            thumbnailUrl = null;
          }
        } else {
          thumbnailUrl = json['thumbnail_url']?.toString();
        }
      }

      // 안전한 숫자 변환
      int safeGetInt(String key, int defaultValue) {
        try {
          final value = json[key];
          if (value == null) return defaultValue;
          if (value is int) return value;
          if (value is num) return value.toInt();
          return int.tryParse(value.toString()) ?? defaultValue;
        } catch (e) {
          print('int 필드 접근 오류($key): $e');
          return defaultValue;
        }
      }

      // 안전한 날짜 변환
      DateTime? safeParseDate(String key) {
        try {
          final dateStr = json[key]?.toString();
          if (dateStr == null || dateStr.isEmpty) return null;
          return DateTime.parse(dateStr);
        } catch (e) {
          print('날짜 파싱 오류($key): $e');
          return null;
        }
      }

      return Video(
        id: json['id'].toString(),
        title: json['title'].toString(),
        videoUrl: json['video_url'].toString(),
        platform: platform,
        platformId: platformId,
        artistId: artistId,
        createdAt: safeParseDate('created_at') ?? DateTime.now(),
        updatedAt: safeParseDate('updated_at') ?? DateTime.now(),
        description: json['description']?.toString(),
        thumbnailUrl: thumbnailUrl,
        viewCount: safeGetInt('view_count', 0),
        likeCount: safeGetInt('like_count', 0),
        eventName: json['event_name']?.toString(),
        recordedDate: safeParseDate('recorded_date'),
      );
    } catch (e) {
      print('Video fromJson 에러: $e, json: $json');

      // 심각한 오류시에도 최선을 다해 객체 생성 시도
      try {
        // 안전한 데이터 추출 함수
        String safeGetString(String key) {
          try {
            final value = json[key];
            return value?.toString() ?? '';
          } catch (e) {
            print('필드 접근 오류($key): $e');
            return '';
          }
        }

        int safeGetInt(String key, int defaultValue) {
          try {
            final value = json[key];
            if (value == null) return defaultValue;
            if (value is int) return value;
            if (value is num) return value.toInt();
            return int.tryParse(value.toString()) ?? defaultValue;
          } catch (e) {
            print('int 필드 접근 오류($key): $e');
            return defaultValue;
          }
        }

        DateTime safeParseDate(String key) {
          try {
            final dateStr = safeGetString(key);
            if (dateStr.isEmpty) return DateTime.now();
            return DateTime.parse(dateStr);
          } catch (e) {
            print('날짜 파싱 오류($key): $e');
            return DateTime.now();
          }
        }

        // 기본값으로 대체하면서 객체 생성
        return Video(
          id: safeGetString('id').isNotEmpty
              ? safeGetString('id')
              : 'unknown-${DateTime.now().millisecondsSinceEpoch}',
          title: safeGetString('title').isNotEmpty ? safeGetString('title') : '불러올 수 없는 비디오',
          videoUrl: safeGetString('video_url'),
          platform: safeGetString('platform').isNotEmpty ? safeGetString('platform') : 'YouTube',
          platformId: safeGetString('platform_id'),
          artistId:
              json.containsKey('artist_id') ? safeGetString('artist_id') : safeGetString('artist'),
          createdAt: safeParseDate('created_at'),
          updatedAt: safeParseDate('updated_at'),
          description: json['description']?.toString(),
          thumbnailUrl: json['thumbnail_url']?.toString(),
          viewCount: safeGetInt('view_count', 0),
          likeCount: safeGetInt('like_count', 0),
          eventName: json['event_name']?.toString(),
          recordedDate: json.containsKey('recorded_date')
              ? DateTime.tryParse(json['recorded_date'].toString())
              : null,
        );
      } catch (innerError) {
        print('심각한 Video 파싱 오류: $innerError, 기본 객체 반환');
        // 최후의 수단으로 빈 비디오 객체 반환
        return Video(
          id: 'error-${DateTime.now().millisecondsSinceEpoch}',
          title: '불러올 수 없는 비디오',
          videoUrl: '',
          platform: 'YouTube',
          platformId: '',
          artistId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          viewCount: 0,
          likeCount: 0,
        );
      }
    }
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'video_url': videoUrl,
      'platform': platform,
      'platform_id': platformId,
      'artist_id': artistId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'view_count': viewCount,
      'like_count': likeCount,
      'event_name': eventName,
      'recorded_date': recordedDate?.toIso8601String(),
    };
  }

  /// 복사본 생성
  Video copyWith({
    String? id,
    String? title,
    String? videoUrl,
    String? platform,
    String? platformId,
    String? artistId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? thumbnailUrl,
    int? viewCount,
    int? likeCount,
    String? eventName,
    DateTime? recordedDate,
  }) {
    return Video(
      id: id ?? this.id,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      platform: platform ?? this.platform,
      platformId: platformId ?? this.platformId,
      artistId: artistId ?? this.artistId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      eventName: eventName ?? this.eventName,
      recordedDate: recordedDate ?? this.recordedDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Video &&
        other.id == id &&
        other.title == title &&
        other.videoUrl == videoUrl &&
        other.platform == platform &&
        other.platformId == platformId &&
        other.artistId == artistId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.description == description &&
        other.thumbnailUrl == thumbnailUrl &&
        other.viewCount == viewCount &&
        other.likeCount == likeCount &&
        other.eventName == eventName &&
        other.recordedDate == recordedDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      videoUrl,
      platform,
      platformId,
      artistId,
      createdAt,
      updatedAt,
      description,
      thumbnailUrl,
      viewCount,
      likeCount,
      eventName,
      recordedDate,
    );
  }

  @override
  String toString() {
    return 'Video(id: $id, title: $title, platform: $platform)';
  }
}
