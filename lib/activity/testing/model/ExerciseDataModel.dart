import "dart:ui";
enum ExcerciseType{PushUps,Squats,DownwardDogPlank,JumpingJack,HighKnees}
class ExerciseDataModel{
  String title;
  String image;
  Color color;
  ExcerciseType type;
  ExerciseDataModel(this.title,this.image,this.color,this.type);

}
