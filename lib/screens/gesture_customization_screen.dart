import 'package:flutter/material.dart';
import '../header.dart';
import '../services/gesture_service.dart';
import 'package:firebase_database/firebase_database.dart';

class GestureCustomizationScreen extends StatefulWidget {
  final String keyName;
  final String deviceName;

  const GestureCustomizationScreen({
    super.key,
    required this.keyName,
    required this.deviceName,
  });

  @override
  State<GestureCustomizationScreen> createState() => _GestureCustomizationScreenState();
}

class _GestureCustomizationScreenState extends State<GestureCustomizationScreen> {
  Map<String, Map<String, dynamic>> _availableGestures = {};
  List<Map<String, String>> _deviceActions = [];
  bool _isLoading = true;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    print('🚀 GestureCustomizationScreen 초기화 시작');
    print('📱 전달받은 keyName: ${widget.keyName}');
    print('📱 전달받은 deviceName: ${widget.deviceName}');
    print('📱 keyName 타입: ${widget.keyName.runtimeType}');
    print('📱 keyName이 null인가? ${widget.keyName == null}');
    print('📱 keyName이 empty인가? ${widget.keyName?.isEmpty}');
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 라우트 arguments도 확인
    final args = ModalRoute.of(context)?.settings.arguments;
    print('🔍 ModalRoute arguments: $args');
    print('🔍 Arguments 타입: ${args.runtimeType}');
    if (args is Map<String, dynamic>) {
      print('🔍 Arguments 내용:');
      args.forEach((key, value) {
        print('  - $key: $value (${value.runtimeType})');
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _debugInfo = '데이터 로딩 중...';
    });
    
    try {
      print('🔍 제스처 커스터마이징 데이터 로딩 시작...');
      print('📱 기기 ID: ${widget.keyName}');
      print('📱 기기 이름: ${widget.deviceName}');
      
      // 사용 가능한 제스처 로드
      final availableGestures = GestureService.getAvailableGestures();
      print('🤚 사용 가능한 제스처 개수: ${availableGestures.length}');
      
      // 기기 동작 로드
      final allDeviceActions = GestureService.getDeviceActions();
      print('🏠 전체 기기 동작 데이터: ${allDeviceActions.keys}');
      
      final deviceActions = allDeviceActions[widget.keyName] ?? [];
      print('🎯 ${widget.keyName} 기기 동작 개수: ${deviceActions.length}');
      print('📝 ${widget.keyName} 기기 동작 목록: $deviceActions');
      
      // 디버그 정보 업데이트
      String debugMsg = '✅ 로딩 완료\n';
      debugMsg += '📱 기기: ${widget.deviceName} (${widget.keyName})\n';
      debugMsg += '🤚 사용가능 제스처: ${availableGestures.length}개\n';
      debugMsg += '🎯 기기 동작: ${deviceActions.length}개';
      
      if (deviceActions.isEmpty) {
        debugMsg += '\n❌ 기기 동작이 없습니다. 기기 ID를 확인해주세요.';
        debugMsg += '\n💡 사용 가능한 기기: ${allDeviceActions.keys.join(', ')}';
      }
      
      setState(() {
        _availableGestures = availableGestures;
        _deviceActions = deviceActions;
        _isLoading = false;
        _debugInfo = debugMsg;
      });
      
      print('✅ 데이터 로딩 완료');
    } catch (e) {
      print('❌ 데이터 로딩 오류: $e');
      setState(() {
        _isLoading = false;
        _debugInfo = '❌ 데이터 로딩 오류: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 오류: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Header(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.deviceName} 제스처 설정',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '원하는 동작에 제스처를 연결하세요',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 디버그 정보 버튼
                  IconButton(
                    onPressed: _showDebugInfo,
                    icon: const Icon(Icons.info_outline),
                    tooltip: '디버그 정보',
                  ),
                  // 새로고침 버튼
                  IconButton(
                    onPressed: () {
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🔄 데이터 새로고침 완료')),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    tooltip: '새로고침',
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _buildCustomizationContent(),
            ),
          ],
        ),
      ),
    );
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 디버그 정보'),
        content: SingleChildScrollView(
          child: Text(_debugInfo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _testFirebaseConnection();
            },
            child: const Text('Firebase 테스트'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationContent() {
    // 기기 액션이 없는 경우 에러 처리
    if (_deviceActions.isEmpty) {
      return _buildNoActionsView();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 기기 동작 기반 매핑 섹션 (주요 기능)
        _buildDeviceActionMappingSection(),
        
        const SizedBox(height: 24),
        
        // 현재 설정된 제스처들 (요약)
        _buildCurrentMappingsSummary(),
        
        const SizedBox(height: 24),
        
        // 사용 가능한 제스처 목록
        _buildAvailableGesturesSection(),
        
        const SizedBox(height: 24),
        
        // 기기 동작 목록 (디버그용)
        _buildDeviceActionsDebugView(),
      ],
    );
  }

  Widget _buildNoActionsView() {
    // keyName이 null인 경우와 기기 동작이 없는 경우를 구분
    final isKeyNameNull = widget.keyName == null || widget.keyName.isEmpty;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isKeyNameNull ? Icons.error : Icons.error_outline, 
              size: 64, 
              color: isKeyNameNull ? Colors.red[400] : Colors.orange[400]
            ),
            const SizedBox(height: 16),
            Text(
              isKeyNameNull ? '기기 정보가 전달되지 않았습니다' : '기기 동작을 찾을 수 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isKeyNameNull ? Colors.red[700] : Colors.orange[700],
              ),
            ),
            const SizedBox(height: 8),
            if (isKeyNameNull) ...[
              Text(
                '기기 ID: ${widget.keyName ?? "null"}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Text(
                '이 오류는 다음과 같은 경우에 발생합니다:\n'
                '• 기기 목록에서 정상적으로 접근하지 않은 경우\n'
                '• 앱 내부 라우팅 오류\n'
                '• 기기 정보가 손실된 경우',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/main_screen',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('홈으로 돌아가기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showDeviceSelectionDialog,
                icon: const Icon(Icons.devices),
                label: const Text('기기 직접 선택'),
              ),
            ] else ...[
              Text(
                '기기 ID: ${widget.keyName}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Text(
                '지원되는 기기:\n• light (전등)\n• fan (선풍기)\n• projector (프로젝터)\n• curtain (커튼)\n• television (텔레비전)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showDebugInfo,
                icon: const Icon(Icons.info),
                label: const Text('상세 정보 보기'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeviceSelectionDialog() {
    final availableDevices = {
      'light': '전등',
      'fan': '선풍기', 
      'projector': '프로젝터',
      'curtain': '커튼',
      'television': '텔레비전',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🏠 기기 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableDevices.entries.map((entry) {
            return ListTile(
              leading: const Icon(Icons.devices),
              title: Text(entry.value),
              subtitle: Text('ID: ${entry.key}'),
              onTap: () {
                Navigator.pop(context);
                // 새로운 GestureCustomizationScreen으로 교체
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GestureCustomizationScreen(
                      keyName: entry.key,
                      deviceName: entry.value,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceActionsDebugView() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 ${widget.deviceName} 사용 가능한 동작',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_deviceActions.isEmpty)
              const Text('사용 가능한 동작이 없습니다.')
            else
              ...(_deviceActions.map((action) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${action['label']} (${action['control']})'),
                  ],
                ),
              ))),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceActionMappingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '🎯 ${widget.deviceName} 동작별 제스처 설정',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_deviceActions.length}개 동작',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '각 동작에 원하는 제스처를 연결하세요',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance
                  .ref('control_gesture/${widget.keyName}')
                  .onValue,
              builder: (context, snapshot) {
                // 현재 매핑된 제스처들 파악
                Map<String, Map<String, dynamic>> currentMappings = {};
                if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                  final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  currentMappings = Map<String, Map<String, dynamic>>.from(
                    data.map((key, value) => MapEntry(
                      key.toString(),
                      Map<String, dynamic>.from(value as Map),
                    )),
                  );
                }
                
                // 동작별로 현재 매핑된 제스처 찾기
                Map<String, String> actionToGesture = {};
                for (final entry in currentMappings.entries) {
                  final gestureId = entry.key;
                  final mapping = entry.value;
                  final control = mapping['control']?.toString();
                  if (control != null) {
                    actionToGesture[control] = gestureId;
                  }
                }
                
                return Column(
                  children: _deviceActions.map((action) {
                    final control = action['control']!;
                    final label = action['label']!;
                    final currentGesture = actionToGesture[control];
                    final hasGesture = currentGesture != null;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasGesture ? Colors.green[50] : Colors.grey[50],
                        border: Border.all(
                          color: hasGesture ? Colors.green[200]! : Colors.grey[200]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // 동작 정보
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  control,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // 현재 매핑된 제스처 또는 추가 버튼
                          Expanded(
                            flex: 2,
                            child: hasGesture
                              ? Row(
                                  children: [
                                    Text(
                                      GestureService.getGestureIcon(currentGesture),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        GestureService.getGestureName(currentGesture),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  '제스처 없음',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                          ),
                          
                          // 액션 버튼들
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasGesture)
                                IconButton(
                                  onPressed: () => _showGestureChangeDialog(
                                    control, 
                                    label, 
                                    currentGesture
                                  ),
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  tooltip: '제스처 변경',
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                ),
                              IconButton(
                                onPressed: hasGesture
                                  ? () => _deleteGestureMapping(
                                      currentGesture, 
                                      GestureService.getGestureName(currentGesture)
                                    )
                                  : () => _showGestureSelectionForAction(control, label),
                                icon: Icon(
                                  hasGesture ? Icons.delete_outline : Icons.add_circle_outline,
                                  size: 16,
                                  color: hasGesture ? Colors.red : Colors.blue,
                                ),
                                tooltip: hasGesture ? '제스처 삭제' : '제스처 추가',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGestureSelectionForAction(String control, String label) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label 동작에 연결할 제스처 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance
                .ref('control_gesture/${widget.keyName}')
                .onValue,
            builder: (context, snapshot) {
              // 현재 사용 중인 제스처 목록 파악
              Set<String> usedGestures = {};
              if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                usedGestures = data.keys.map((k) => k.toString()).toSet();
              }
              
              // 사용 가능한 제스처 목록
              final availableGestures = _availableGestures.entries
                  .where((entry) => !usedGestures.contains(entry.key))
                  .toList();
              
              if (availableGestures.isEmpty) {
                return const Text('사용 가능한 제스처가 없습니다.\n기존 제스처를 수정하거나 삭제해주세요.');
              }
              
              return SizedBox(
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: availableGestures.length,
                  itemBuilder: (context, index) {
                    final entry = availableGestures[index];
                    final gestureId = entry.key;
                    final gesture = entry.value;
                    
                    return GestureDetector(
                      onTap: () => _connectGestureToAction(gestureId, control, label),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              GestureService.getGestureIcon(gestureId),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                GestureService.getGestureName(gestureId),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMappingsSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '📊 제스처 연결 현황',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance
                      .ref('control_gesture/${widget.keyName}')
                      .onValue,
                  builder: (context, snapshot) {
                    int mappedCount = 0;
                    if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                      final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      mappedCount = data.length;
                    }
                    int totalActions = _deviceActions.length;
                    return Text(
                      '$mappedCount / $totalActions 연결됨',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance
                  .ref('control_gesture/${widget.keyName}')
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      '아직 연결된 제스처가 없습니다\n위의 동작 목록에서 제스처를 추가해보세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                
                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                int totalActions = _deviceActions.length;
                int mappedCount = data.length;
                double percentage = mappedCount / totalActions;
                
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage >= 0.7 ? Colors.green : 
                        percentage >= 0.4 ? Colors.orange : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '연결률 ${(percentage * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${totalActions - mappedCount}개 동작 남음',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableGesturesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '🤚 빠른 제스처 추가',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance
                      .ref('control_gesture/${widget.keyName}')
                      .onValue,
                  builder: (context, snapshot) {
                    int totalGestures = _availableGestures.length;
                    int usedCount = 0;
                    
                    if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                      final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      usedCount = data.length;
                    }
                    
                    int unusedCount = totalGestures - usedCount;
                    
                    return Text(
                      '$unusedCount개 제스처 사용 가능',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '동작이 정해지지 않은 제스처를 먼저 선택하세요',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance
                  .ref('control_gesture/${widget.keyName}')
                  .onValue,
              builder: (context, snapshot) {
                // 현재 사용 중인 제스처 목록 파악
                Set<String> usedGestures = {};
                if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                  final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  usedGestures = data.keys.map((k) => k.toString()).toSet();
                }
                
                // 사용되지 않은 제스처만 필터링
                final unusedGestures = Map<String, Map<String, dynamic>>.fromEntries(
                  _availableGestures.entries.where((entry) => 
                    !usedGestures.contains(entry.key)
                  )
                );

                if (unusedGestures.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, size: 48, color: Colors.green[400]),
                        const SizedBox(height: 8),
                        Text(
                          '모든 제스처가 연결되었습니다!',
                          style: TextStyle(
                            color: Colors.green[700], 
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '위의 동작 목록에서 기존 연결을 수정할 수 있어요',
                          style: TextStyle(color: Colors.green[600], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                } else {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.0,
                    ),
                    itemCount: unusedGestures.length,
                    itemBuilder: (context, index) {
                      final entry = unusedGestures.entries.elementAt(index);
                      final gestureId = entry.key;
                      final gesture = entry.value;
                      
                      return GestureDetector(
                        onTap: () => _showActionSelectionDialog(gestureId, GestureService.getGestureName(gestureId)),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                GestureService.getGestureIcon(gestureId),
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  GestureService.getGestureName(gestureId),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showActionSelectionDialog(String gestureId, String gestureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$gestureName 제스처에 연결할 동작 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance
                .ref('control_gesture/${widget.keyName}')
                .onValue,
            builder: (context, snapshot) {
              // 현재 매핑된 제스처들 확인
              Map<String, Map<String, dynamic>> currentMappings = {};
              if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                currentMappings = Map<String, Map<String, dynamic>>.from(
                  data.map((key, value) => MapEntry(
                    key.toString(),
                    Map<String, dynamic>.from(value as Map),
                  )),
                );
              }
              
              final isCurrentlyUsed = currentMappings.containsKey(gestureId);
              final currentMapping = isCurrentlyUsed ? currentMappings[gestureId] : null;
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCurrentlyUsed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '현재 설정:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            currentMapping!['label'] ?? '',
                            style: TextStyle(color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    ),
                  
                  const Text(
                    '새로운 동작 선택:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _deviceActions.length,
                      itemBuilder: (context, index) {
                        final action = _deviceActions[index];
                        final control = action['control']!;
                        final label = action['label']!;
                        final isCurrentAction = isCurrentlyUsed && currentMapping?['control'] == control;
                        
                        // 다른 제스처에 이미 매핑된 동작인지 확인
                        bool isUsedByOther = false;
                        for (final entry in currentMappings.entries) {
                          final otherGestureId = entry.key;
                          final otherMapping = entry.value;
                          if (otherGestureId != gestureId && 
                              otherMapping['control'] == control) {
                            isUsedByOther = true;
                            break;
                          }
                        }
                        
                        return ListTile(
                          enabled: !isUsedByOther,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCurrentAction 
                                ? Colors.blue[100] 
                                : isUsedByOther 
                                  ? Colors.grey[200] 
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              isCurrentAction 
                                ? Icons.radio_button_checked 
                                : isUsedByOther 
                                  ? Icons.block 
                                  : Icons.radio_button_unchecked,
                              color: isCurrentAction 
                                ? Colors.blue 
                                : isUsedByOther 
                                  ? Colors.grey 
                                  : Colors.green,
                            ),
                          ),
                          title: Text(
                            label,
                            style: TextStyle(
                              fontWeight: isCurrentAction ? FontWeight.bold : FontWeight.normal,
                              color: isUsedByOther ? Colors.grey : Colors.black,
                            ),
                          ),
                          subtitle: isCurrentAction 
                            ? const Text('현재 설정된 동작', style: TextStyle(color: Colors.blue))
                            : isUsedByOther 
                              ? const Text('다른 제스처에서 사용 중', style: TextStyle(color: Colors.grey))
                              : null,
                          onTap: isUsedByOther || isCurrentAction
                            ? null 
                            : () => _connectGestureToAction(gestureId, control, label),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance
                .ref('control_gesture/${widget.keyName}/$gestureId')
                .onValue,
            builder: (context, snapshot) {
              final hasMapping = snapshot.hasData && snapshot.data?.snapshot.value != null;
              
              if (hasMapping) {
                return TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteGestureMapping(gestureId, gestureName);
                  },
                  child: const Text('연결 해제', style: TextStyle(color: Colors.red)),
                );
              }
              return const SizedBox();
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectGestureToAction(String gestureId, String control, String label) async {
    Navigator.pop(context); // 다이얼로그 닫기
    
    try {
      // 먼저 해당 동작에 이미 연결된 제스처가 있는지 확인
      final snapshot = await FirebaseDatabase.instance
          .ref('control_gesture/${widget.keyName}')
          .once();
      
      String? existingGestureId;
      if (snapshot.snapshot.exists && snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        for (final entry in data.entries) {
          final existingControl = entry.value['control']?.toString();
          if (existingControl == control) {
            existingGestureId = entry.key.toString();
            break;
          }
        }
      }
      
      // 기존 제스처가 있으면 먼저 삭제
      if (existingGestureId != null) {
        print('🔄 기존 제스처 삭제 중: $existingGestureId');
        await GestureService.deleteGestureMapping(widget.keyName, existingGestureId);
      }
      
      // 새로운 제스처 연결
      final success = await GestureService.saveGestureMapping(
        deviceId: widget.keyName,
        gestureId: gestureId,
        control: control,
        label: label,
      );
      
      if (success) {
        final gestureName = GestureService.getGestureName(gestureId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $label → $gestureName 제스처로 변경 완료!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // 데이터 새로고침
      } else {
        throw Exception('저장 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 제스처 연결 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteGestureMapping(String gestureId, String gestureName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('제스처 삭제'),
        content: Text('$gestureName 제스처 설정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final success = await GestureService.deleteGestureMapping(widget.keyName, gestureId);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $gestureName 제스처 삭제 완료'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // 데이터 새로고침
        } else {
          throw Exception('삭제 실패');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 제스처 삭제 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGestureChangeDialog(String control, String label, String currentGesture) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label 동작에 연결할 제스처 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance
                .ref('control_gesture/${widget.keyName}')
                .onValue,
            builder: (context, snapshot) {
              // 현재 사용 중인 제스처 목록 파악 (현재 제스처 제외)
              Set<String> usedGestures = {};
              if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                usedGestures = data.keys.map((k) => k.toString()).toSet();
                usedGestures.remove(currentGesture); // 현재 제스처는 변경 가능하므로 제외
              }
              
              // 사용 가능한 제스처 목록 (현재 제스처 포함)
              final availableGestures = _availableGestures.entries
                  .where((entry) => !usedGestures.contains(entry.key))
                  .toList();
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 현재 제스처 정보 표시
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '현재: ',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          GestureService.getGestureIcon(currentGesture),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          GestureService.getGestureName(currentGesture),
                          style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  
                  const Text(
                    '새로운 제스처 선택:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  if (availableGestures.isEmpty)
                    const Text('사용 가능한 제스처가 없습니다.')
                  else
                    SizedBox(
                      height: 300,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: availableGestures.length,
                        itemBuilder: (context, index) {
                          final entry = availableGestures[index];
                          final gestureId = entry.key;
                          final isCurrentGesture = gestureId == currentGesture;
                          
                          return GestureDetector(
                            onTap: isCurrentGesture 
                              ? null 
                              : () => _connectGestureToAction(gestureId, control, label),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCurrentGesture ? Colors.grey[200] : Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCurrentGesture ? Colors.grey[400]! : Colors.blue[200]!,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    GestureService.getGestureIcon(gestureId),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isCurrentGesture ? Colors.grey[600] : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      isCurrentGesture 
                                        ? '${GestureService.getGestureName(gestureId)}\n(현재 설정)'
                                        : GestureService.getGestureName(gestureId),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrentGesture ? Colors.grey[600] : Colors.black,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Future<void> _testFirebaseConnection() async {
    print('🧪 Firebase 연결 테스트 시작...');
    
    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Firebase 연결 테스트 중...'),
            ],
          ),
        ),
      );
      
      // 1. Firebase 읽기 테스트
      print('🔍 1단계: Firebase 읽기 테스트');
      final snapshot = await FirebaseDatabase.instance
          .ref('control_gesture/${widget.keyName}')
          .once();
      
      print('📊 Firebase 읽기 결과: ${snapshot.snapshot.value}');
      
      // 2. 데이터가 없으면 샘플 데이터 생성 제안
      if (!snapshot.snapshot.exists || snapshot.snapshot.value == null) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        
        final createSample = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('📝 테스트 데이터 생성'),
            content: Text(
              'Firebase에 ${widget.deviceName} 기기의 제스처 데이터가 없습니다.\n\n'
              '테스트용 샘플 제스처를 생성하시겠습니까?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('생성'),
              ),
            ],
          ),
        );
        
        if (createSample == true) {
          await _createSampleGestureData();
        }
      } else {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Firebase 연결 성공! 제스처 데이터가 존재합니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      
      print('❌ Firebase 연결 테스트 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Firebase 연결 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createSampleGestureData() async {
    try {
      print('🧪 샘플 제스처 데이터 생성 시작...');
      
      // 기기별 샘플 데이터 정의
      final sampleMappings = <String, Map<String, String>>{};
      
      switch (widget.keyName) {
        case 'light':
          sampleMappings['one'] = {'control': 'power', 'label': '전원'};
          sampleMappings['two'] = {'control': 'brighter', 'label': '밝게'};
          sampleMappings['three'] = {'control': 'dimmer', 'label': '어둡게'};
          break;
        case 'fan':
          sampleMappings['one'] = {'control': 'power', 'label': '전원'};
          sampleMappings['two'] = {'control': 'stronger', 'label': '바람 강하게'};
          sampleMappings['three'] = {'control': 'weaker', 'label': '바람 약하게'};
          break;
        case 'projector':
          sampleMappings['one'] = {'control': 'power', 'label': '전원'};
          sampleMappings['two'] = {'control': 'up', 'label': '위'};
          sampleMappings['three'] = {'control': 'down', 'label': '아래'};
          break;
        default:
          sampleMappings['one'] = {'control': 'power', 'label': '전원'};
          sampleMappings['ok'] = {'control': 'light', 'label': '전등'};
      }
      
      // Firebase에 샘플 데이터 저장
      for (final entry in sampleMappings.entries) {
        final gestureId = entry.key;
        final mapping = entry.value;
        
        await GestureService.saveGestureMapping(
          deviceId: widget.keyName,
          gestureId: gestureId,
          control: mapping['control']!,
          label: mapping['label']!,
        );
        
        print('✅ 샘플 제스처 저장: $gestureId → ${mapping['label']}');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${sampleMappings.length}개의 샘플 제스처가 생성되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
      
      print('🎉 샘플 제스처 데이터 생성 완료');
    } catch (e) {
      print('❌ 샘플 제스처 데이터 생성 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 샘플 데이터 생성 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 