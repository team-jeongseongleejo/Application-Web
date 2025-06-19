import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  void _showToast(String message) {
    Fluttertoast.showToast(msg: message);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // 🔙 뒤로가기 버튼 (필요할 때만 표시)
          if (canPop)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),

          // 🏷️ 'AIOT 스마트홈' 타이틀 버튼
          TextButton(
            onPressed: () {
              // PageView index = 1로 이동 (HOME)
              DefaultTabController.of(context)?.animateTo(1);
              Navigator.pushReplacementNamed(context, '/main_screen');
            },
            child: const Text(
              'AIOT 스마트홈',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),

          // ⚙️ 오른쪽 버튼들
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
            icon: const Icon(Icons.search, color: Colors.blue),
            tooltip: '검색',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/recommendation');
            },
            icon: const Icon(Icons.analytics, color: Colors.green),
            tooltip: '추천',
          ),
        ],
      ),
    );
  }
}
