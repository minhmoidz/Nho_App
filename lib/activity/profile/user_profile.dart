class UserProfile {
  final String fullName;
  final String phone;
  final String? address;
  final String birthDate;
  final int? age;

  UserProfile({
    required this.fullName,
    required this.phone,
    required this.birthDate,
    required this.age,
    this.address,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['full_name'],
      phone: json['phone'],
      birthDate: json['birth_date'],
      age: json['age'],
      address: json['address'],
    );
  }
}
