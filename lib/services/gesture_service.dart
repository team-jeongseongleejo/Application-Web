import 'package:firebase_database/firebase_database.dart';

class GestureService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // 🎮 실제 Firebase DB에 존재하는 제스처 목록
  static Map<String, Map<String, dynamic>> getAvailableGestures() {
    return {
      'one': {
        'name': '1️⃣ 숫자 1',
        'description': '집게손가락으로 1을 표현',
        'icon': '☝️',
      },
      'two': {
        'name': '2️⃣ 숫자 2',
        'description': '집게손가락과 중지로 V자',
        'icon': '✌️',
      },
      'three': {
        'name': '3️⃣ 숫자 3',
        'description': '집게손가락, 중지, 약지로 3을 표현',
        'icon': '🤟',
      },
      'four': {
        'name': '4️⃣ 숫자 4',
        'description': '4개 손가락으로 4를 표현',
        'icon': '🖐️',
      },
      'small_heart': {
        'name': '💖 작은 하트',
        'description': '엄지와 집게손가락으로 하트 모양',
        'icon': '💖',
      },
      'horizontal_V': {
        'name': '➡️ 수평 V자',
        'description': '수평으로 누운 V자 모양',
        'icon': '🔄',
      },
      'vertical_V': {
        'name': '⬆️ 수직 V자',
        'description': '수직으로 선 V자 모양',
        'icon': '✌️',
      },
      'ok': {
        'name': '👌 OK 사인',
        'description': '엄지와 집게손가락으로 원 모양',
        'icon': '👌',
      },
      'promise': {
        'name': '📞 전화 제스처',
        'description': '전화 받을 때 손의 모습 (엄지와 새끼손가락)',
        'icon': '🤙',
      },
      'rotate': {
        'name': '🔄 회전',
        'description': '손목을 회전시키는 동작',
        'icon': '🌀',
      },
      'side_moving': {
        'name': '↔️ 좌우 움직임',
        'description': '손을 좌우로 흔드는 동작',
        'icon': '↔️',
      },
      'spider_man': {
        'name': '🕷️ 스파이더맨',
        'description': '중지와 약지를 접고 엄지, 집게, 새끼 펴기',
        'icon': '🕷️',
      },
      'thumbs_up': {
        'name': '👍 좋아요',
        'description': '엄지손가락 위로',
        'icon': '👍',
      },
      'thumbs_down': {
        'name': '👎 싫어요',
        'description': '엄지손가락 아래로',
        'icon': '👎',
      },
      'thumbs_left': {
        'name': '👈 왼쪽 엄지',
        'description': '엄지손가락 왼쪽',
        'icon': '👈',
      },
      'thumbs_right': {
        'name': '👉 오른쪽 엄지',
        'description': '엄지손가락 오른쪽',
        'icon': '👉',
      },
    };
  }

  // 🏠 기기별 사용 가능한 동작 목록 (실제 Firebase 구조 기반)
  static Map<String, List<Map<String, String>>> getDeviceActions() {
    return {
      'light': [
        {'control': 'power', 'label': '전원'},
        {'control': 'brighter', 'label': '밝게'},
        {'control': 'dimmer', 'label': '어둡게'},
        {'control': 'color', 'label': '색상 변경'},
        {'control': 'light', 'label': '조명 모드'},
        {'control': 'projector', 'label': '프로젝터'},
        {'control': 'curtain', 'label': '커튼'},
        {'control': 'fan', 'label': '선풍기'},
      ],
      'projector': [
        {'control': 'power', 'label': '전원'},
        {'control': 'up', 'label': '위'},
        {'control': 'down', 'label': '아래'},
        {'control': 'left', 'label': '왼쪽'},
        {'control': 'right', 'label': '오른쪽'},
        {'control': 'mid', 'label': '선택/확인'},
        {'control': 'menu', 'label': '메뉴'},
        {'control': 'home', 'label': '홈'},
        {'control': 'back', 'label': '뒤로'},
        {'control': 'light', 'label': '전등'},
        {'control': 'curtain', 'label': '커튼'},
        {'control': 'fan', 'label': '선풍기'},
      ],
      'curtain': [
        {'control': 'power', 'label': '전원'},
        {'control': 'open', 'label': '열기'},
        {'control': 'close', 'label': '닫기'},
        {'control': 'stop', 'label': '정지'},
        {'control': 'half_open', 'label': '반만 열기'},
        {'control': 'light', 'label': '전등'},
        {'control': 'projector', 'label': '프로젝터'},
        {'control': 'fan', 'label': '선풍기'},
      ],
      'fan': [
        {'control': 'power', 'label': '전원'},
        {'control': 'stronger', 'label': '바람 강하게'},
        {'control': 'weaker', 'label': '바람 약하게'},
        {'control': 'horizontal', 'label': '수평 회전'},
        {'control': 'vertical', 'label': '수직 회전'},
        {'control': 'fan_mode', 'label': '선풍기 모드'},
        {'control': 'timer', 'label': '타이머'},
        {'control': 'light', 'label': '전등'},
        {'control': 'projector', 'label': '프로젝터'},
        {'control': 'curtain', 'label': '커튼'},
      ],
      'television': [
        {'control': 'power', 'label': '전원'},
        {'control': 'vol_up', 'label': '볼륨 올리기'},
        {'control': 'vol_down', 'label': '볼륨 내리기'},
        {'control': 'channel_up', 'label': '채널 올리기'},
        {'control': 'channel_down', 'label': '채널 내리기'},
        {'control': 'menu', 'label': '메뉴'},
        {'control': 'home', 'label': '홈'},
        {'control': 'back', 'label': '뒤로'},
        {'control': 'ok', 'label': '확인'},
        {'control': 'mute', 'label': '음소거'},
        {'control': 'input', 'label': '입력 변경'},
        {'control': 'guide', 'label': '가이드'},
        {'control': 'info', 'label': '정보'},
        {'control': 'exit', 'label': '나가기'},
        {'control': 'light', 'label': '전등'},
        {'control': 'projector', 'label': '프로젝터'},
        {'control': 'curtain', 'label': '커튼'},
        {'control': 'fan', 'label': '선풍기'},
      ],
    };
  }

  // 📱 특정 기기의 현재 제스처 매핑 가져오기
  static Future<Map<String, Map<String, dynamic>>> getDeviceGestureMapping(String deviceId) async {
    try {
      print('🔍 Firebase에서 제스처 매핑 가져오기: control_gesture/$deviceId');
      
      final snapshot = await _database.child('control_gesture/$deviceId').once();
      
      if (!snapshot.snapshot.exists) {
        print('❌ 제스처 매핑 데이터 없음: $deviceId');
        return {};
      }
      
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      print('📊 Firebase 원본 데이터: $data');
      
      final mappings = Map<String, Map<String, dynamic>>.from(
        data.map((key, value) => MapEntry(
          key.toString(),
          Map<String, dynamic>.from(value as Map),
        )),
      );
      
      print('✅ 제스처 매핑 로드 완료: ${mappings.length}개');
      print('📝 매핑 상세: $mappings');
      
      return mappings;
    } catch (e) {
      print('❌ 제스처 매핑 로드 오류: $e');
      return {};
    }
  }

  // 🏠 기기별 통계
  static Future<Map<String, dynamic>> getDeviceGestureStats(String deviceId) async {
    try {
      final mappings = await getDeviceGestureMapping(deviceId);
      final totalGestures = getAvailableGestures().length;
      final usedGestures = mappings.length;
      final unusedGestures = totalGestures - usedGestures;
      
      // 가장 많이 사용된 제스처
      String mostUsedGesture = '';
      int maxUsage = 0;
      
      mappings.forEach((gestureId, mapping) {
        final usageCount = mapping['usageCount'] as int? ?? 0;
        if (usageCount > maxUsage) {
          maxUsage = usageCount;
          mostUsedGesture = gestureId;
        }
      });
      
      return {
        'totalGestures': totalGestures,
        'usedGestures': usedGestures,
        'unusedGestures': unusedGestures,
        'usageRate': usedGestures / totalGestures,
        'mostUsedGesture': mostUsedGesture,
        'maxUsageCount': maxUsage,
      };
    } catch (e) {
      print('❌ 제스처 통계 조회 오류: $e');
      return {};
    }
  }

  // 🎭 제스처 아이콘 가져오기
  static String getGestureIcon(String gestureId) {
    final gestures = getAvailableGestures();
    return gestures[gestureId]?['icon'] ?? '🤚';
  }

  // 🏷️ 제스처 이름 가져오기
  static String getGestureName(String gestureId) {
    final gestures = getAvailableGestures();
    return gestures[gestureId]?['name'] ?? gestureId;
  }

  // 📝 제스처 설명 가져오기
  static String getGestureDescription(String gestureId) {
    final gestures = getAvailableGestures();
    return gestures[gestureId]?['description'] ?? '';
  }

  // 🔍 특정 기기에서 사용 중인 제스처 목록
  static Future<List<String>> getUsedGestures(String deviceId) async {
    try {
      final mappings = await getDeviceGestureMapping(deviceId);
      return mappings.keys.toList();
    } catch (e) {
      print('❌ 사용 중인 제스처 조회 오류: $e');
      return [];
    }
  }

  // 🆓 사용 가능한(미사용) 제스처 목록
  static Future<List<String>> getUnusedGestures(String deviceId) async {
    try {
      final allGestures = getAvailableGestures().keys.toSet();
      final usedGestures = (await getUsedGestures(deviceId)).toSet();
      return allGestures.difference(usedGestures).toList();
    } catch (e) {
      print('❌ 미사용 제스처 조회 오류: $e');
      return [];
    }
  }

  // 🎯 제스처로 동작 실행
  static Future<String?> executeGestureAction(String deviceId, String gestureId) async {
    try {
      print('🎯 제스처 동작 실행: $deviceId/$gestureId');
      
      final mappings = await getDeviceGestureMapping(deviceId);
      final mapping = mappings[gestureId];
      
      if (mapping == null) {
        print('❌ 매핑되지 않은 제스처: $gestureId');
        return null;
      }
      
      final control = mapping['control'] as String;
      print('🎮 실행할 동작: $control');
      
      // 사용 횟수 증가
      await incrementGestureUsage(deviceId, gestureId);
      
      return control;
    } catch (e) {
      print('❌ 제스처 동작 실행 오류: $e');
      return null;
    }
  }

  // 💾 제스처 매핑 저장
  static Future<bool> saveGestureMapping({
    required String deviceId,
    required String gestureId,
    required String control,
    required String label,
  }) async {
    try {
      print('💾 제스처 매핑 저장: $deviceId/$gestureId → $control ($label)');
      
      final mappingData = {
        'control': control,
        'action': control, // Firebase 문서 호환성
        'label': label,
        'createdAt': DateTime.now().toIso8601String(),
        'usageCount': 0,
      };
      
      await _database
          .child('control_gesture/$deviceId/$gestureId')
          .set(mappingData);
      
      print('✅ 제스처 매핑 저장 완료');
      return true;
    } catch (e) {
      print('❌ 제스처 매핑 저장 오류: $e');
      return false;
    }
  }

  // 🔄 제스처 매핑 업데이트
  static Future<bool> updateGestureMapping({
    required String deviceId,
    required String gestureId,
    required String control,
    required String label,
  }) async {
    try {
      print('🔄 제스처 매핑 업데이트: $deviceId/$gestureId → $control ($label)');
      
      final updates = {
        'control': control,
        'action': control, // Firebase 문서 호환성
        'label': label,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      await _database
          .child('control_gesture/$deviceId/$gestureId')
          .update(updates);
      
      print('✅ 제스처 매핑 업데이트 완료');
      return true;
    } catch (e) {
      print('❌ 제스처 매핑 업데이트 오류: $e');
      return false;
    }
  }

  // 🗑️ 제스처 매핑 삭제
  static Future<bool> deleteGestureMapping(String deviceId, String gestureId) async {
    try {
      print('🗑️ 제스처 매핑 삭제: $deviceId/$gestureId');
      
      await _database
          .child('control_gesture/$deviceId/$gestureId')
          .remove();
      
      print('✅ 제스처 매핑 삭제 완료');
      return true;
    } catch (e) {
      print('❌ 제스처 매핑 삭제 오류: $e');
      return false;
    }
  }

  // 📈 제스처 사용 횟수 증가
  static Future<void> incrementGestureUsage(String deviceId, String gestureId) async {
    try {
      final ref = _database.child('control_gesture/$deviceId/$gestureId/usageCount');
      await ref.set(ServerValue.increment(1));
      print('📈 제스처 사용 횟수 증가: $deviceId/$gestureId');
    } catch (e) {
      print('❌ 사용 횟수 업데이트 오류: $e');
    }
  }
} 