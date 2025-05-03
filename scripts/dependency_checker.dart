/// 의존성 일관성 검사 스크립트
///
/// Pulse 프로젝트의 모든 패키지에서 의존성 버전이 일관되게 사용되고 있는지 검사합니다.
/// 실행 방법: dart run scripts/dependency_checker.dart

import 'dart:io';
import 'dart:convert';

void main() async {
  print('Pulse 의존성 일관성 검사 시작');
  print('---------------------------\n');

  // 모든 pubspec.yaml 파일 찾기
  final pubspecFiles = findPubspecFiles();
  print('분석할 패키지 수: ${pubspecFiles.length}\n');

  // 각 pubspec.yaml 파일에서 의존성 정보 추출
  final dependencyVersions = <String, Map<String, String>>{};
  final allDependencies = <String, Set<String>>{};

  for (final file in pubspecFiles) {
    final packageName = extractPackageName(file);
    final deps = extractDependencies(file);

    dependencyVersions[packageName] = deps;

    // 모든 의존성 추적
    for (final dep in deps.keys) {
      if (!allDependencies.containsKey(dep)) {
        allDependencies[dep] = {};
      }
      allDependencies[dep]!.add(deps[dep]!);
    }
  }

  // 의존성 버전 불일치 검사
  print('의존성 버전 일관성 검사 결과:');
  print('---------------------------');

  final inconsistentDeps = <String, Set<String>>{};

  for (final dep in allDependencies.keys) {
    if (allDependencies[dep]!.length > 1) {
      inconsistentDeps[dep] = allDependencies[dep]!;
      print('⚠️ 불일치: $dep - 버전: ${allDependencies[dep]!.join(', ')}');
    }
  }

  if (inconsistentDeps.isEmpty) {
    print('✅ 모든 의존성 버전이 일관적으로 사용되고 있습니다.');
  } else {
    print('\n총 ${inconsistentDeps.length}개의 불일치 발견.');
    print('권장 사항: melos.yaml에 의존성 오버라이드를 설정하거나 패키지별 pubspec.yaml 파일을 수정하세요.');
  }

  // 패키지 의존성 그래프 출력
  print('\n패키지 의존성 그래프:');
  print('------------------');

  for (final package in dependencyVersions.keys) {
    final internalDeps =
        dependencyVersions[package]!.keys
            .where((dep) => dependencyVersions.containsKey(dep))
            .toList();

    if (internalDeps.isNotEmpty) {
      print('$package -> ${internalDeps.join(', ')}');
    } else {
      print('$package -> (내부 의존성 없음)');
    }
  }
}

List<File> findPubspecFiles() {
  final files = <File>[];

  void searchDirectory(Directory dir) {
    try {
      for (final entity in dir.listSync()) {
        if (entity is File && entity.path.endsWith('pubspec.yaml')) {
          files.add(entity);
        } else if (entity is Directory &&
            !entity.path.contains('.dart_tool') &&
            !entity.path.contains('build') &&
            !entity.path.contains('.git')) {
          searchDirectory(entity);
        }
      }
    } catch (e) {
      print('디렉토리 검색 중 오류 발생: $e');
    }
  }

  searchDirectory(Directory.current);
  return files;
}

String extractPackageName(File pubspecFile) {
  final content = pubspecFile.readAsStringSync();
  final lines = LineSplitter.split(content).toList();

  for (final line in lines) {
    if (line.startsWith('name:')) {
      return line.split('name:')[1].trim();
    }
  }

  return 'unknown-${pubspecFile.path}';
}

Map<String, String> extractDependencies(File pubspecFile) {
  final content = pubspecFile.readAsStringSync();
  final lines = LineSplitter.split(content).toList();

  final deps = <String, String>{};
  bool inDependencies = false;
  bool inDevDependencies = false;

  for (final line in lines) {
    if (line.trim() == 'dependencies:') {
      inDependencies = true;
      inDevDependencies = false;
      continue;
    } else if (line.trim() == 'dev_dependencies:') {
      inDependencies = false;
      inDevDependencies = true;
      continue;
    } else if (line.trim() == 'flutter:' || line.trim() == 'environment:') {
      inDependencies = false;
      inDevDependencies = false;
      continue;
    }

    if ((inDependencies || inDevDependencies) &&
        line.trim().isNotEmpty &&
        line.contains(':')) {
      final parts = line.split(':');
      if (parts.length >= 2) {
        final name = parts[0].trim();

        // SDK 의존성이나 path 의존성은 건너뜀
        if (name.isEmpty || line.contains('sdk:') || line.contains('path:')) {
          continue;
        }

        // 버전 추출
        String version = parts.sublist(1).join(':').trim();
        if (version.startsWith('^')) {
          version = version.substring(1);
        }

        deps[name] = version;
      }
    }
  }

  return deps;
}
