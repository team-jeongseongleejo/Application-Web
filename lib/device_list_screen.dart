import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'header.dart';

class DeviceListScreen extends StatelessWidget {
  DeviceListScreen({super.key});

  final List<String> devices = ['전등', '빔프로젝터', '커튼', '선풍기', '텔레비전'];
  final List<String> devicesEng = ['light', 'projector', 'curtain', 'fan', 'television'];
  final List<String> imagePaths = [
    'assets/icons/light.png',
    'assets/icons/projector.png',
    'assets/icons/curtain.png',
    'assets/icons/fan.png',
    'assets/icons/television.png',
  ];

  @override
  Widget build(BuildContext context) {
    final db = FirebaseDatabase.instance;

    return SafeArea(
      child: Column(
        children: [
          const Header(),
          const Padding(
            padding: EdgeInsets.only(right: 16.0, top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.circle, color: Colors.green, size: 12),
                SizedBox(width: 4),
                Text('연결됨'),
                SizedBox(width: 16),
                Icon(Icons.circle, color: Colors.red, size: 12),
                SizedBox(width: 4),
                Text('사용할 수 없음'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: db.ref().onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return const Center(child: Text('연결된 장치 없음'));
                }

                final data = snapshot.data!.snapshot.value as Map;
                final gestureMap = (data['control_gesture'] ?? {}) as Map;
                final statusMap = (data['status'] ?? {}) as Map;

                final connectedSet = gestureMap.keys.map((e) => e.toString()).toSet();

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final deviceKey = devicesEng[index];
                    final isConnected = connectedSet.contains(deviceKey);

                    final powerStatus = statusMap[deviceKey]?['power'] ?? 'off';
                    final isOn = powerStatus == 'on';

                    return GestureDetector(
                      onTap: () {
                        if (!isConnected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('사용할 수 없는 상태입니다')),
                          );
                          return;
                        }

                        Navigator.pushNamed(
                          context,
                          '/device_detail_screen',
                          arguments: {
                            'label': devices[index],
                            'key': deviceKey,
                            'iconPath': imagePaths[index],
                          },
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            // 중앙 내용
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    imagePaths[index],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    devices[index],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 연결 상태 표시 (오른쪽 상단)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(
                                Icons.circle,
                                color: isConnected ? Colors.green : Colors.red,
                                size: 12,
                              ),
                            ),
                            // 전원 상태 표시 (왼쪽 상단)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.power_settings_new,
                                    size: 18,
                                    color: isOn ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOn ? 'on' : 'off',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isOn ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
