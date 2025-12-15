import 'package:flutter/material.dart';

// --- IMPORT CÁC FILE VỪA TẠO ---
import 'tabs/articles_tab.dart';
import 'tabs/videos_tab.dart';
import 'tabs/medicine_tab.dart';

class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: Column(
          children: [
            // --- THANH TAB BAR ---
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
              ),
              child: const TabBar(
                labelColor: Colors.teal,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.teal,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: [
                  Tab(text: 'Đọc báo', icon: Icon(Icons.article_outlined)),
                  Tab(text: 'Bài giảng', icon: Icon(Icons.video_library_outlined)),
                  Tab(text: 'Tra cứu', icon: Icon(Icons.medical_services_outlined)),
                ],
              ),
            ),

            // --- NỘI DUNG GỌI TỪ 3 FILE CON ---
            const Expanded(
              child: TabBarView(
                children: [
                  ArticlesTab(), // Gọi từ file articles_tab.dart
                  VideosTab(),   // Gọi từ file videos_tab.dart
                  MedicineTab(), // Gọi từ file medicine_tab.dart
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}