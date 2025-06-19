import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/remote_control_service.dart';
import 'header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, String> _deviceNames = {
    'light': '전등',
    'fan': '선풍기',
    'television': '텔레비전',
    'curtain': '커튼',
    'projector': '빔프로젝터',
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Header(),
          const SizedBox(height: 16),
          const Text(
            '설정',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildSectionHeader('기기 관리'),
                _buildListTile(
                  title: '기기 추가',
                  subtitle: '새로운 스마트 기기 연결',
                  icon: Icons.add_circle_outline,
                  onTap: () => _showAddDeviceDialog(),
                ),
                _buildListTile(
                  title: '기기 이름 변경',
                  subtitle: '등록된 기기 이름 수정',
                  icon: Icons.edit,
                  onTap: () => _showRenameDeviceDialog(),
                ),
                _buildListTile(
                  title: '기기 삭제',
                  subtitle: '사용하지 않는 기기 제거',
                  icon: Icons.delete_outline,
                  iconColor: Colors.red,
                  onTap: () => _showDeleteDeviceDialog(),
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('시스템 정보'),
                _buildListTile(
                  title: '연결 방식',
                  subtitle: 'Firebase → 서버 → MQTT → 아두이노',
                  icon: Icons.cloud_queue,
                  onTap: () => _showSystemInfoDialog(),
                ),
                _buildListTile(
                  title: 'Firebase 상태',
                  subtitle: '실시간 연결됨',
                  icon: Icons.cloud_done,
                  iconColor: Colors.green,
                  onTap: () => _showFirebaseStatusDialog(),
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('앱 정보'),
                _buildListTile(
                  title: '도움말',
                  subtitle: '앱 사용법 및 문제 해결',
                  icon: Icons.help_outline,
                  onTap: () => _showHelpDialog(),
                ),
                _buildListTile(
                  title: '버전 정보',
                  subtitle: 'v1.2.0 (Build 10)',
                  icon: Icons.info_outline,
                  onTap: () => _showVersionInfo(),
                ),
                
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'made by 정성이조',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.blue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Colors.blue,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 72),
      ],
    );
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기기 추가'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('새로운 스마트 기기를 추가하려면:'),
            SizedBox(height: 12),
            Text('1. 기기가 같은 WiFi에 연결되어 있는지 확인'),
            Text('2. 기기의 페어링 모드를 활성화'),
            Text('3. 앱에서 자동 검색 시작'),
            SizedBox(height: 12),
            Text('⚠️ 현재 데이터베이스 구조상 수동 추가만 가능합니다.',
              style: TextStyle(color: Colors.orange, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('기기 검색 기능은 개발 중입니다.')),
              );
            },
            child: const Text('검색 시작'),
          ),
        ],
      ),
    );
  }

  void _showRenameDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기기 이름 변경'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _deviceNames.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              subtitle: Text('ID: ${entry.key}'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                Navigator.pop(context);
                _showEditNameDialog(entry.key, entry.value);
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

  void _showEditNameDialog(String deviceId, String currentName) {
    final controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이름 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '새 이름',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                // Firebase에 저장 (실제로는 로컬 상태만 업데이트)
                setState(() {
                  _deviceNames[deviceId] = newName;
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$deviceId 이름이 "$newName"으로 변경되었습니다')),
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기기 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _deviceNames.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              subtitle: Text('ID: ${entry.key}'),
              trailing: const Icon(Icons.delete, color: Colors.red),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteDevice(entry.key, entry.value);
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

  void _confirmDeleteDevice(String deviceId, String deviceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기기 삭제 확인'),
        content: Text('$deviceName을(를) 정말 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없으며, 모든 제스쳐 설정도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Firebase에서 삭제
              try {
                await FirebaseDatabase.instance.ref('control_gesture/$deviceId').remove();
                await FirebaseDatabase.instance.ref('status/$deviceId').remove();
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$deviceName이(가) 삭제되었습니다')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('삭제 중 오류가 발생했습니다')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('도움말'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📱 Smart Bridge 사용법:'),
            SizedBox(height: 12),
            Text('• 홈: 전체 기기 상태 확인'),
            Text('• 기기: 각 기기별 상세 제어'),
            Text('• 설정: 앱 및 기기 관리'),
            SizedBox(height: 12),
            Text('🎯 주요 기능:'),
            Text('• 제스쳐로 기기 제어'),
            Text('• 실시간 상태 모니터링'),
            Text('• 스마트 기기 관리'),
            SizedBox(height: 12),
            Text('📞 문의: 정성이조 개발팀'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smart Bridge'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('버전: 1.2.0'),
            Text('빌드: 10'),
            Text('출시일: 2024.01.15'),
            SizedBox(height: 16),
            Text('개발팀: 정성이조'),
            Text('문의: support@smartbridge.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showSystemInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시스템 정보'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('연결 방식: Firebase → 서버 → MQTT → 아두이노'),
            SizedBox(height: 12),
            Text('Firebase 상태: 실시간 연결됨'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showFirebaseStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firebase 상태'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Firebase 연결 상태: 실시간 연결됨'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
