import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class RecommendationService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // 📊 로그 데이터 가져오기
  static Future<List<Map<String, dynamic>>> getLogData({int? limit}) async {
    try {
      Query query = _database.child('log_table').orderByChild('createdAt');
      
      if (limit != null) {
        query = query.limitToLast(limit);
      }
      
      final snapshot = await query.once();
      
      if (!snapshot.snapshot.exists) {
        return [];
      }
      
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      
      return data.entries.map((entry) {
        final logData = Map<String, dynamic>.from(entry.value as Map);
        logData['id'] = entry.key;
        return logData;
      }).toList();
      
    } catch (e) {
      print('로그 데이터 가져오기 오류: $e');
      return [];
    }
  }

  // 📊 사용자 패턴 분석 (새로운 ir_commands 로그 기반)
  static Future<Map<String, dynamic>> analyzeUserPatterns() async {
    try {
      print('📊 사용자 패턴 분석 시작 (ir_commands 기반)...');
      
      // ir_commands에서 모든 명령 로그 가져오기
      final snapshot = await _database.child('ir_commands').once();
      
      if (!snapshot.snapshot.exists) {
        print('❌ ir_commands 데이터 없음');
        return _getEmptyAnalytics();
      }
      
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      final commands = <Map<String, dynamic>>[];
      
      // 데이터 변환 및 필터링 (최근 30일)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      
      data.forEach((key, value) {
        if (value is Map) {
          final commandData = Map<String, dynamic>.from(value);
          final timestamp = commandData['timestamp'] as int? ?? 0;
          
          if (timestamp > thirtyDaysAgo) {
            commandData['id'] = key.toString();
            commands.add(commandData);
          }
        }
      });
      
      print('📝 분석할 명령 개수: ${commands.length}');
      
      if (commands.isEmpty) {
        return _getEmptyAnalytics();
      }
      
      // 분석 수행
      final deviceUsage = <String, int>{};
      final commandUsage = <String, int>{};
      final timePatterns = <String, int>{};
      final sourceUsage = <String, int>{};
      
      for (final command in commands) {
        final deviceId = command['deviceId'] as String? ?? 'unknown';
        final commandName = command['command'] as String? ?? 'unknown';
        final timestamp = command['timestamp'] as int? ?? 0;
        final source = command['source'] as String? ?? 'unknown';
        
        // 기기별 사용량
        deviceUsage[deviceId] = (deviceUsage[deviceId] ?? 0) + 1;
        
        // 명령별 사용량
        commandUsage[commandName] = (commandUsage[commandName] ?? 0) + 1;
        
        // 출처별 사용량 (mobile_app, gesture 등)
        sourceUsage[source] = (sourceUsage[source] ?? 0) + 1;
        
        // 시간대별 패턴
        final hour = DateTime.fromMillisecondsSinceEpoch(timestamp).hour;
        final timeSlot = _getTimeSlot(hour);
        timePatterns[timeSlot] = (timePatterns[timeSlot] ?? 0) + 1;
      }
      
      // 패턴 점수 계산
      final patternScore = _calculatePatternScore(commands);
      
      // 기본 추천 생성
      final recommendations = _generateBasicRecommendations(deviceUsage, commandUsage, timePatterns, sourceUsage);
      
      final analytics = {
        'deviceUsage': deviceUsage,
        'commandUsage': commandUsage,
        'timePatterns': timePatterns,
        'sourceUsage': sourceUsage,
        'totalLogs': commands.length,
        'patternScore': patternScore,
        'analysisDate': DateTime.now().toIso8601String(),
        'dataSource': 'ir_commands', // 새로운 데이터 소스 명시
        'recommendations': recommendations,
      };
      
      print('✅ 패턴 분석 완료: ${commands.length}개 명령 분석됨');
      return analytics;
      
    } catch (e) {
      print('❌ 패턴 분석 오류: $e');
      return _getEmptyAnalytics();
    }
  }

  // 📊 빈 분석 데이터 반환
  static Map<String, dynamic> _getEmptyAnalytics() {
    return {
      'deviceUsage': <String, int>{},
      'commandUsage': <String, int>{},
      'timePatterns': <String, int>{},
      'sourceUsage': <String, int>{},
      'totalLogs': 0,
      'patternScore': 0.0,
      'analysisDate': DateTime.now().toIso8601String(),
      'dataSource': 'ir_commands',
      'recommendations': [
        '새로운 제스처를 추가해서 더 편리하게 사용해보세요!',
        '자주 사용하는 기기들로 루틴을 만들어보세요.',
        '제스처 설정을 커스터마이징해보세요.',
      ],
    };
  }

  // ⏰ 시간대 분류
  static String _getTimeSlot(int hour) {
    if (hour >= 6 && hour < 12) {
      return '아침';
    } else if (hour >= 12 && hour < 18) {
      return '오후';
    } else if (hour >= 18 && hour < 22) {
      return '저녁';
    } else {
      return '밤';
    }
  }

  // 📈 패턴 점수 계산 (새로운 방식)
  static double _calculatePatternScore(List<Map<String, dynamic>> commands) {
    if (commands.isEmpty) return 0.0;
    
    // 시간대별 분포의 균등성 측정
    final timeSlotCounts = <String, int>{};
    for (final command in commands) {
      final timestamp = command['timestamp'] as int? ?? 0;
      final hour = DateTime.fromMillisecondsSinceEpoch(timestamp).hour;
      final timeSlot = _getTimeSlot(hour);
      timeSlotCounts[timeSlot] = (timeSlotCounts[timeSlot] ?? 0) + 1;
    }
    
    // 엔트로피 기반 점수 (0.0~1.0)
    final total = commands.length;
    double entropy = 0.0;
    
    timeSlotCounts.values.forEach((count) {
      if (count > 0) {
        final probability = count / total;
        entropy -= probability * (log(probability) / ln2);
      }
    });
    
    // 최대 엔트로피로 정규화
    final maxEntropy = log(4) / ln2; // 4개 시간대
    return maxEntropy > 0 ? entropy / maxEntropy : 0.0;
  }

  // 📈 로컬 패턴 점수 계산 (기존 방식)
  static double _calculateLocalPatternScore(
    Map<String, int> deviceUsage, 
    Map<String, int> gestureUsage
  ) {
    if (deviceUsage.isEmpty || gestureUsage.isEmpty) return 0.0;
    
    // 엔트로피 기반 다양성 점수
    final deviceEntropy = _calculateEntropy(deviceUsage.values.toList());
    final gestureEntropy = _calculateEntropy(gestureUsage.values.toList());
    
    // 평균 엔트로피 (0~1 범위로 정규화)
    final avgEntropy = (deviceEntropy + gestureEntropy) / 2;
    final maxEntropy = log(max(deviceUsage.length, gestureUsage.length)) / ln2;
    
    return maxEntropy > 0 ? avgEntropy / maxEntropy : 0.0;
  }

  // 📊 엔트로피 계산
  static double _calculateEntropy(List<int> values) {
    if (values.isEmpty) return 0.0;
    
    final total = values.reduce((a, b) => a + b);
    double entropy = 0.0;
    
    for (final value in values) {
      if (value > 0) {
        final probability = value / total;
        entropy -= probability * (log(probability) / ln2);
      }
    }
    
    return entropy;
  }

  // 🏠 기존 로컬 분석 로직 (백업용)
  static Future<Map<String, dynamic>> _analyzeLocalPatterns() async {
    final logs = await getLogData(limit: 100); // 최근 100개 로그
    
    if (logs.isEmpty) {
      return {
        'mostUsedDevice': '',
        'mostUsedGesture': '',
        'favoriteTime': '',
        'patternScore': 0.0,
        'recommendations': <String>[],
        'deviceUsage': <String, int>{},
        'gestureUsage': <String, int>{},
        'timePatterns': <String, int>{},
        'totalLogs': 0,
      };
    }
    
    // 기기별 사용 빈도
    final deviceUsage = <String, int>{};
    // 제스처별 사용 빈도
    final gestureUsage = <String, int>{};
    // 시간대별 사용 패턴
    final timePatterns = <String, int>{};
    // 제어 타입별 패턴
    final controlPatterns = <String, int>{};
    
    for (final log in logs) {
      final device = log['device']?.toString() ?? '';
      final gesture = log['gesture']?.toString() ?? '';
      final control = log['control']?.toString() ?? '';
      final createdAt = log['createdAt']?.toString() ?? '';
      
      // 기기 사용량 집계
      deviceUsage[device] = (deviceUsage[device] ?? 0) + 1;
      
      // 제스처 사용량 집계
      gestureUsage[gesture] = (gestureUsage[gesture] ?? 0) + 1;
      
      // 제어 타입 집계
      controlPatterns[control] = (controlPatterns[control] ?? 0) + 1;
      
      // 시간대 패턴 분석
      if (createdAt.isNotEmpty) {
        try {
          final dateTime = DateTime.parse(createdAt);
          final hour = dateTime.hour;
          
          String timeSlot;
          if (hour >= 6 && hour < 12) {
            timeSlot = '아침';
          } else if (hour >= 12 && hour < 18) {
            timeSlot = '오후';
          } else if (hour >= 18 && hour < 22) {
            timeSlot = '저녁';
          } else {
            timeSlot = '밤';
          }
          
          timePatterns[timeSlot] = (timePatterns[timeSlot] ?? 0) + 1;
        } catch (e) {
          // 날짜 파싱 오류 무시
        }
      }
    }
    
    // 최다 사용 항목 찾기
    final mostUsedDevice = _getMostUsed(deviceUsage);
    final mostUsedGesture = _getMostUsed(gestureUsage);
    final favoriteTime = _getMostUsed(timePatterns);
    
    // 패턴 점수 계산 (다양성 기준)
    final patternScore = _calculateLocalPatternScore(deviceUsage, gestureUsage);
    
    // 추천 생성
    final recommendations = _generateRecommendations(
      deviceUsage, 
      gestureUsage, 
      timePatterns, 
      controlPatterns
    );
    
    return {
      'mostUsedDevice': mostUsedDevice,
      'mostUsedGesture': mostUsedGesture,
      'favoriteTime': favoriteTime,
      'patternScore': patternScore,
      'recommendations': recommendations,
      'deviceUsage': deviceUsage,
      'gestureUsage': gestureUsage,
      'timePatterns': timePatterns,
      'totalLogs': logs.length,
    };
  }

  // 🏆 가장 많이 사용된 항목 찾기
  static String _getMostUsed(Map<String, int> usage) {
    if (usage.isEmpty) return '';
    
    String mostUsed = '';
    int maxUsage = 0;
    
    usage.forEach((key, value) {
      if (value > maxUsage) {
        maxUsage = value;
        mostUsed = key;
      }
    });
    
    return mostUsed;
  }

  // 💡 추천 생성
  static List<String> _generateRecommendations(
    Map<String, int> deviceUsage,
    Map<String, int> gestureUsage,
    Map<String, int> timePatterns,
    Map<String, int> controlPatterns,
  ) {
    final recommendations = <String>[];
    
    // 기기 사용 패턴 기반 추천
    if (deviceUsage.isNotEmpty) {
      final topDevice = _getMostUsed(deviceUsage);
      if (topDevice.isNotEmpty) {
        recommendations.add('$topDevice을(를) 자주 사용하시네요! 제스처를 추가로 설정해보세요.');
      }
    }
    
    // 제스처 패턴 기반 추천
    if (gestureUsage.isNotEmpty) {
      final topGesture = _getMostUsed(gestureUsage);
      final gestureNames = {
        'thumbs_up': '좋아요',
        'swipe_up': '위로 스와이프',
        'swipe_down': '아래로 스와이프',
        'circle': '원 그리기',
        'pinch': '핀치',
      };
      
      final gestureName = gestureNames[topGesture] ?? topGesture;
      if (gestureName.isNotEmpty) {
        recommendations.add('$gestureName 제스처를 선호하시는군요! 다른 기기에도 적용해보세요.');
      }
    }
    
    // 시간대 패턴 기반 추천
    if (timePatterns.isNotEmpty) {
      final favoriteTime = _getMostUsed(timePatterns);
      if (favoriteTime == '아침') {
        recommendations.add('아침에 자주 사용하시네요! 모닝 루틴을 설정해보세요.');
      } else if (favoriteTime == '저녁') {
        recommendations.add('저녁에 활발히 사용하시네요! 이브닝 루틴을 만들어보세요.');
      }
    }
    
    // 제어 패턴 기반 추천
    if (controlPatterns.isNotEmpty) {
      final topControl = _getMostUsed(controlPatterns);
      if (topControl == 'brighter') {
        recommendations.add('밝기 조절을 자주 하시네요! 자동 밝기 조절 루틴을 설정해보세요.');
      } else if (topControl == 'power_on' || topControl == 'power_off') {
        recommendations.add('전원 제어를 자주 하시네요! 음성 제어도 고려해보세요.');
      }
    }
    
    // 기본 추천
    if (recommendations.isEmpty) {
      recommendations.addAll([
        '새로운 제스처를 추가해서 더 편리하게 사용해보세요!',
        '자주 사용하는 기기들로 루틴을 만들어보세요.',
        '제스처 설정을 커스터마이징해보세요.',
      ]);
    }
    
    return recommendations;
  }

  // 📅 일별 사용 통계 생성
  static Future<Map<String, dynamic>> getDailyStats() async {
    final logs = await getLogData(limit: 50);
    
    final dailyStats = <String, Map<String, int>>{};
    
    for (final log in logs) {
      final createdAt = log['createdAt']?.toString() ?? '';
      final device = log['device']?.toString() ?? '';
      
      if (createdAt.isNotEmpty && device.isNotEmpty) {
        try {
          final date = DateTime.parse(createdAt);
          final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          
          dailyStats[dateKey] ??= <String, int>{};
          dailyStats[dateKey]![device] = (dailyStats[dateKey]![device] ?? 0) + 1;
        } catch (e) {
          // 날짜 파싱 오류 무시
        }
      }
    }
    
    return {
      'dailyStats': dailyStats,
      'totalDays': dailyStats.length,
    };
  }

  // 🔮 개인화된 제스처 추천
  static Future<List<Map<String, String>>> getGestureRecommendations(String deviceId) async {
    final patterns = await analyzeUserPatterns();
    final gestureUsage = patterns['gestureUsage'] as Map<String, int>;
    
    // 사용자가 선호하는 제스처 순서대로 정렬
    final sortedGestures = gestureUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final recommendations = <Map<String, String>>[];
    
    // 기기별 맞춤 추천
    final deviceSpecificActions = {
      'light': ['전원 켜기', '전원 끄기', '밝게', '어둡게', '색상 변경'],
      'fan': ['전원 켜기', '전원 끄기', '풍량 증가', '풍량 감소', '회전 켜기'],
      'television': ['전원 켜기', '전원 끄기', '채널 올리기', '채널 내리기', '음량 조절'],
      'curtain': ['열기', '닫기', '반만 열기'],
      'projector': ['전원 켜기', '전원 끄기', '밝기 조절', '입력 변경'],
    };
    
    final actions = deviceSpecificActions[deviceId] ?? ['전원 켜기', '전원 끄기'];
    
    for (int i = 0; i < actions.length && i < 5; i++) {
      final action = actions[i];
      
      // 사용자 선호 제스처 우선 추천
      String recommendedGesture = 'swipe_up';
      if (sortedGestures.isNotEmpty && i < sortedGestures.length) {
        recommendedGesture = sortedGestures[i].key;
      }
      
      recommendations.add({
        'action': action,
        'gesture': recommendedGesture,
        'reason': '자주 사용하는 제스처입니다',
      });
    }
    
    return recommendations;
  }

  // 🧪 테스트용 샘플 로그 데이터 생성
  static Future<void> createSampleLogData() async {
    try {
      final now = DateTime.now();
      final logRef = _database.child('log_table');
      
      final sampleLogs = [
        {
          'device': 'light',
          'gesture': 'thumbs_up',
          'control': 'brighter',
          'label': '밝게',
          'color': '진구색',
          'power': 'on',
          'fan_mode': 'unknown',
          'wind_power': 'unknown',
          'createdAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'device': 'light',
          'gesture': 'swipe_up',
          'control': 'power_on',
          'label': '전원 켜기',
          'color': '#ffffff',
          'power': 'on',
          'fan_mode': 'unknown',
          'wind_power': 'unknown',
          'createdAt': now.subtract(const Duration(hours: 4)).toIso8601String(),
        },
        {
          'device': 'fan',
          'gesture': 'circle',
          'control': 'speed_up',
          'label': '풍량 증가',
          'color': 'unknown',
          'power': 'on',
          'fan_mode': 'high',
          'wind_power': '3',
          'createdAt': now.subtract(const Duration(hours: 6)).toIso8601String(),
        },
        {
          'device': 'television',
          'gesture': 'swipe_right',
          'control': 'channel_up',
          'label': '채널 올리기',
          'color': 'unknown',
          'power': 'on',
          'fan_mode': 'unknown',
          'wind_power': 'unknown',
          'createdAt': now.subtract(const Duration(hours: 8)).toIso8601String(),
        },
        {
          'device': 'light',
          'gesture': 'thumbs_up',
          'control': 'brighter',
          'label': '밝게',
          'color': '#ffcc00',
          'power': 'on',
          'fan_mode': 'unknown',
          'wind_power': 'unknown',
          'createdAt': now.subtract(const Duration(hours: 12)).toIso8601String(),
        },
        {
          'device': 'curtain',
          'gesture': 'swipe_up',
          'control': 'open',
          'label': '열기',
          'color': 'unknown',
          'power': 'on',
          'fan_mode': 'unknown',
          'wind_power': 'unknown',
          'createdAt': now.subtract(const Duration(hours: 24)).toIso8601String(),
        },
      ];
      
      for (final log in sampleLogs) {
        await logRef.push().set(log);
      }
      
      print('✅ 샘플 로그 데이터 생성 완료');
    } catch (e) {
      print('❌ 샘플 로그 데이터 생성 오류: $e');
    }
  }

  // 🏠 홈 화면용 간단한 추천 (로컬 분석만)
  static Future<Map<String, dynamic>?> getHomeRecommendation() async {
    print('🏠 홈 추천 시작 (로컬 모드)...');
    
    try {
      // 로컬 분석으로 간단한 추천
      print('🏠 🔄 로컬 분석 시작...');
      final logs = await getLogData(limit: 20);
      if (logs.isEmpty) {
        print('🏠 ⚠️ 로그 데이터 없음');
        return {
          'title': '💡 추천',
          'message': '스마트홈 기기를 사용해보세요!',
          'device': '',
          'gesture': '',
          'source': 'default',
        };
      }
      
      final deviceUsage = <String, int>{};
      final gestureUsage = <String, int>{};
      
      for (final log in logs) {
        final device = log['device']?.toString() ?? '';
        final gesture = log['gesture']?.toString() ?? '';
        deviceUsage[device] = (deviceUsage[device] ?? 0) + 1;
        gestureUsage[gesture] = (gestureUsage[gesture] ?? 0) + 1;
      }
      
      final mostUsedDevice = _getMostUsed(deviceUsage);
      final mostUsedGesture = _getMostUsed(gestureUsage);
      
      if (mostUsedDevice.isNotEmpty && mostUsedGesture.isNotEmpty) {
        print('🏠 ✅ 로컬 패턴 추천 반환: $mostUsedDevice, $mostUsedGesture');
        return {
          'title': '📊 사용 패턴',
          'message': '$mostUsedDevice 기기를 $mostUsedGesture 제스처로 자주 사용하시네요!',
          'device': mostUsedDevice,
          'gesture': mostUsedGesture,
          'source': 'local',
        };
      }
      
      print('🏠 ✅ 기본 추천 반환');
      return {
        'title': '💡 추천',
        'message': '더 많은 기기를 사용해보세요!',
        'device': '',
        'gesture': '',
        'source': 'default',
      };
      
    } catch (e) {
      print('🏠 ❌ 로컬 추천 생성 실패: $e');
      return {
        'title': '💡 추천',
        'message': '스마트홈 기기를 사용해보세요!',
        'device': '',
        'gesture': '',
        'source': 'error',
      };
    }
  }

  // 💡 기본 추천 생성
  static List<String> _generateBasicRecommendations(
    Map<String, int> deviceUsage,
    Map<String, int> commandUsage,
    Map<String, int> timePatterns,
    Map<String, int> sourceUsage,
  ) {
    final recommendations = <String>[];
    
    // 기기 사용 패턴 기반 추천
    if (deviceUsage.isNotEmpty) {
      final topDevice = _getMostUsed(deviceUsage);
      if (topDevice.isNotEmpty) {
        recommendations.add('$topDevice을(를) 자주 사용하시네요! 제스처를 추가로 설정해보세요.');
      }
    }
    
    // 시간대 패턴 기반 추천
    if (timePatterns.isNotEmpty) {
      final favoriteTime = _getMostUsed(timePatterns);
      if (favoriteTime == '아침') {
        recommendations.add('아침에 자주 사용하시네요! 모닝 루틴을 설정해보세요.');
      } else if (favoriteTime == '저녁') {
        recommendations.add('저녁에 활발히 사용하시네요! 이브닝 루틴을 만들어보세요.');
      }
    }
    
    // 제어 방식 기반 추천
    if (sourceUsage.isNotEmpty) {
      final gestureUsage = sourceUsage['gesture'] ?? 0;
      final appUsage = sourceUsage['mobile_app'] ?? 0;
      
      if (gestureUsage > appUsage) {
        recommendations.add('제스처 제어를 선호하시는군요! 더 많은 제스처를 추가해보세요.');
      } else if (appUsage > gestureUsage) {
        recommendations.add('앱 제어를 많이 사용하시네요! 제스처 제어도 시도해보세요.');
      }
    }
    
    // 기본 추천
    if (recommendations.isEmpty) {
      recommendations.addAll([
        '새로운 제스처를 추가해서 더 편리하게 사용해보세요!',
        '자주 사용하는 기기들로 루틴을 만들어보세요.',
        '제스처 설정을 커스터마이징해보세요.',
      ]);
    }
    
    return recommendations;
  }
} 