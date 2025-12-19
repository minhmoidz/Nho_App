import 'package:flutter/material.dart';
import 'package:nhoapp/constants/app_colors.dart';
// --- IMPORT CÁC FILE VỪA TẠO ---
import '../tabs/articles_tab.dart';
import '../tabs/videos_tab.dart';
import '../tabs/medicine_tab.dart';

class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        color: AppColors.surface,
        child: Column(
          children: [
            // --- THANH TAB BAR ---
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
              ),
              child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: "Montserrat"),
                tabs: [
                  Tab(text: 'Đọc báo', icon: Icon(Icons.article_outlined)),
                  Tab(text: 'Bài giảng', icon: Icon(Icons.video_library_outlined)),
                  Tab(text: 'Tra cứu', icon: Icon(Icons.medical_services_outlined)),
                ],
              ),
            ),

            // --- NỘI DUNG GỌI TỪ 3 FILE CON ---
            Expanded(
              child: TabBarView(
                children: [
                  const ArticlesTab(), // Gọi từ file articles_tab.dart
                  VideosTab(),   // Gọi từ file videos_tab.dart
                  const MedicineTab(), // Gọi từ file medicine_tab.dart
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}