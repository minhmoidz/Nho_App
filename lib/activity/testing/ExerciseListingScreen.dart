import 'package:flutter/material.dart';
import 'DetectionScreen.dart';
import 'Model/ExerciseDataModel.dart';

class ExerciseListingScreen extends StatefulWidget {
  const ExerciseListingScreen({super.key});
  @override
  State<ExerciseListingScreen> createState() => _ExerciseListingScreenState();
}

class _ExerciseListingScreenState extends State<ExerciseListingScreen> {
  List<ExerciseDataModel> exerciseList = [];

  void loadData() {
    exerciseList.add(ExerciseDataModel(
        "Chống đẩy", "pushup.gif", const Color(0xff005F9C), ExcerciseType.PushUps));
    exerciseList.add(ExerciseDataModel(
        "Squat", "squat.gif", const Color(0xffDF5089), ExcerciseType.Squats));
    exerciseList.add(ExerciseDataModel("Plank động", "plank.gif",
        const Color(0xffFD8636), ExcerciseType.DownwardDogPlank));
    exerciseList.add(ExerciseDataModel("Jumping Jack", "jumping.gif",
        const Color(0xff2E7D32), ExcerciseType.JumpingJack));
    exerciseList.add(ExerciseDataModel("Nâng gối cao", "jumping.gif",
        Colors.deepPurple, ExcerciseType.HighKnees));

    setState(() {
      exerciseList;
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Danh sách bài tập",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chọn bài tập để AI phân tích và chỉnh sửa tư thế của bạn',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final exercise = exerciseList[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetectionScreen(exerciseDataModel: exerciseList[index]),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: exercise.color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: exercise.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    height: 140,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exerciseList[index].title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Nhấn để bắt đầu',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Image.asset(
                            "assets/images/${exerciseList[index].image}",
                            width: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              itemCount: exerciseList.length,
            ),
          ),
        ],
      ),
    );
  }
}