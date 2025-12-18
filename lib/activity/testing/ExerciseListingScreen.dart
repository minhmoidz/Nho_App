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
        "Push Ups", "pushup.gif", const Color(0xff005F9C), ExcerciseType.PushUps));
    exerciseList.add(ExerciseDataModel(
        "Squats", "squat.gif", const Color(0xffDF5089), ExcerciseType.Squats));
    exerciseList.add(ExerciseDataModel("Plank to Downward", "plank.gif",
        const Color(0xffFD8636), ExcerciseType.DownwardDogPlank));
    exerciseList.add(ExerciseDataModel("Jumping Jack", "jumping.gif",
        const Color(0xff000000), ExcerciseType.JumpingJack));
    exerciseList.add(ExerciseDataModel("High Knees", "jumping.gif",
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
      appBar: AppBar(title: const Text("AI Exercises")),
      body: ListView.builder(
        itemBuilder: (context, index) {
          final exercise = exerciseList[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>DetectionScreen(exerciseDataModel:exerciseList[index]),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: exercise.color,
                borderRadius: BorderRadius.circular(20),
              ),
              height: 150,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      exerciseList[index].title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
        itemCount:exerciseList.length,
      ),
    );
  }
}