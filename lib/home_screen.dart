import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'header.dart';
import 'services/recommendation_service.dart';
import 'services/api_service.dart';
import 'services/recommendation_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _recommendation;
  List<RecommendationItem>? _apiRecommendations; // API 추천
  bool _showRecommendation = true;
  bool _isLoadingRecommendation = true;
  bool _isLoadingApiRecommendations = false; // API 추천 로딩 상태
  bool _isRealApiData = false; // 실제 API 데이터 여부 추적

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
    _loadApiRecommendationsData(); // API 추천 로드
  }

  Future<void> _loadRecommendation() async {
    try {
      final rec = await RecommendationService.getHomeRecommendation();
      if (mounted) {
        setState(() {
          _recommendation = rec;
          _isLoadingRecommendation = false;
        });
      }
    } catch (e) {
      print('추천 로딩 오류: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecommendation = false;
        });
      }
    }
  }

  Future<void> _loadApiRecommendationsData() async {
    setState(() => _isLoadingApiRecommendations = true);
    
    try {
      print('🏠 Home: API 추천 데이터 로딩 시작...');
      
      final apiResponse = await RecommendationApiService.getGestureRecommendations();
      
      if (apiResponse != null) {
        final recommendations = RecommendationApiService.parseRecommendations(apiResponse);
        
        // source 필드로 실제 API 데이터와 샘플 데이터를 구분
        final isRealApiData = apiResponse['source'] != 'sample';
        
        setState(() {
          _apiRecommendations = recommendations.take(3).toList(); // 홈에서는 최대 3개만 표시
          _isLoadingApiRecommendations = false;
          _isRealApiData = isRealApiData;
        });
        
        if (isRealApiData) {
          print('🏠 Home: ✅ 실제 API 추천 데이터 로딩 완료 (${recommendations.length}개 → 3개 표시)');
        } else {
          print('🏠 Home: 📋 샘플 데이터로 테스트 중 (${recommendations.length}개 → 3개 표시)');
        }
      } else {
        setState(() {
          _apiRecommendations = null; // null로 설정하여 연결 실패 상태 표시
          _isLoadingApiRecommendations = false;
          _isRealApiData = false; // 연결 실패 시 false로 설정
        });
        print('🏠 Home: ❌ API 서버 연결 실패');
      }
    } catch (e) {
      print('🏠 Home: ❌ API 추천 데이터 로딩 실패: $e');
      setState(() {
        _apiRecommendations = null;
        _isLoadingApiRecommendations = false;
        _isRealApiData = false; // 예외 시에도 false로 설정
      });
    }
  }

  Widget _buildRecommendationCard() {
    if (!_showRecommendation || _recommendation == null) {
      return const SizedBox.shrink();
    }

    final title = _recommendation!['title'] as String;
    final message = _recommendation!['message'] as String;
    final source = _recommendation!['source'] as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.lightbulb_outline,
                color: Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/recommendation');
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.blue.shade100,
                    ),
                    child: Text(
                      '자세히 보기',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _showRecommendation = false;
                });
              },
              icon: Icon(
                Icons.close,
                color: Colors.grey.shade600,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiRecommendationsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.purple.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '🤖 AI 추천',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoadingApiRecommendations)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: _loadApiRecommendationsData,
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.purple.shade700,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: '새로고침',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_isLoadingApiRecommendations)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'AI 추천을 불러오는 중...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else if (_apiRecommendations == null || _apiRecommendations!.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Python 서버에 연결할 수 없습니다',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Python Flask 서버가 실행되지 않았습니다\n'
                      '• ngrok 터널이 활성화되지 않았습니다\n'
                      '• 샘플 데이터로 테스트 중입니다',
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _loadApiRecommendationsData,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('다시 시도'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[100],
                        foregroundColor: Colors.orange[700],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // API 상태 표시 (실제 데이터 vs 샘플 데이터)
                  Builder(
                    builder: (context) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isRealApiData ? Colors.green[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isRealApiData ? Colors.green[200]! : Colors.blue[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isRealApiData ? Icons.check_circle : Icons.code,
                              color: _isRealApiData ? Colors.green[700] : Colors.blue[700],
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isRealApiData ? '🤖 실시간 AI 추천 연결됨' : '🧪 샘플 데이터로 테스트 중',
                              style: TextStyle(
                                color: _isRealApiData ? Colors.green[700] : Colors.blue[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _isRealApiData ? Colors.green[700] : Colors.blue[700],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _isRealApiData ? 'LIVE' : 'TEST',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // 추천 목록
                  ..._apiRecommendations!.map((recommendation) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple[100]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _getConfidenceColor(recommendation.confidence),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${recommendation.gestureName} → ${recommendation.deviceName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (recommendation.action.isNotEmpty)
                                      Text(
                                        recommendation.action,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getConfidenceColor(recommendation.confidence).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getConfidenceColor(recommendation.confidence).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${(recommendation.confidence * 100).toInt()}%',
                                  style: TextStyle(
                                    color: _getConfidenceColor(recommendation.confidence),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (recommendation.reason.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple[25],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.purple[600],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      recommendation.reason,
                                      style: TextStyle(
                                        color: Colors.purple[700],
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            
            if (_apiRecommendations != null && _apiRecommendations!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/recommendation');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.purple.shade100,
                  ),
                  child: Text(
                    '더 많은 추천 보기',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 신뢰도에 따른 색상 반환
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseDatabase.instance;

    return SafeArea(
      child: Column(
        children: [
          const Header(),
          
          // 추천 카드 (로딩 중일 때는 보여주지 않음)
          if (!_isLoadingRecommendation) _buildRecommendationCard(),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    '현재 연결된 기기 모드',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 기기 정보 표시 (사진, 이름, 최근 손동작)
                  Container(
                    constraints: const BoxConstraints(minHeight: 300),
                    child: StreamBuilder<DatabaseEvent>(
                      stream: db.ref('user_info').onValue,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (!snapshot.hasData ||
                            snapshot.data?.snapshot.value == null ||
                            snapshot.data?.snapshot.value.toString().isEmpty == true) {
                          return Column(
                            children: const [
                              Icon(Icons.device_unknown, size: 100, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                '연결된 기기가 없습니다',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          );
                        }

                        final value = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                        final deviceGesture = value['current_device']?.toString() ?? '';
                        final lastGesture = value['last_gesture']?.toString() ?? '';
                        final modeRef = db.ref('mode_gesture/$deviceGesture');

                        return FutureBuilder<DatabaseEvent>(
                          future: modeRef.once(),
                          builder: (context, modeSnapshot) {
                            if (!modeSnapshot.hasData ||
                                modeSnapshot.data?.snapshot.value == null) {
                              return Column(
                                children: [
                                  const Icon(Icons.device_unknown,
                                      size: 100, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  Text(
                                    '알 수 없는 기기 ($deviceGesture)',
                                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 32),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '최근 인식한 손동작: "$lastGesture"',
                                      style: const TextStyle(fontSize: 16, color: Colors.black),
                                    ),
                                  ),
                                ],
                              );
                            }

                            final data = modeSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                            final label = data['label'] as String? ?? '알 수 없음';
                            final mode = data['mode'] as String? ?? 'unknown';

                            return Column(
                              children: [
                                // 기기 사진
                                Image.asset(
                                  'assets/icons/$mode.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.device_unknown,
                                      size: 100,
                                      color: Colors.grey,
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                
                                // 기기 이름
                                Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // 최근 인식한 손동작
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.gesture, color: Colors.blue[700], size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        '최근 인식한 손동작: "$lastGesture"',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // API 추천 섹션
                  _buildApiRecommendationsSection(),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
