import 'package:flutter/material.dart';
import 'package:gioapp/constants/app_colors.dart';
import './profile_api_service.dart';
import './user_profile.dart';
import 'package:intl/intl.dart';

class UpdateProfileScreen extends StatefulWidget {
  final UserProfile user;

  const UpdateProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreen();
}


class _UpdateProfileScreen extends State<UpdateProfileScreen> {
  final _fullNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  DateTime? _selectedBirthDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final user = widget.user;

    _fullNameController.text = user.fullName;
    _phoneController.text = user.phone;
    _addressController.text = user.address ?? '';

    if (user.birthDate.isNotEmpty) {
      _selectedBirthDate = DateTime.parse(user.birthDate);

      _birthDateController.text =
          DateFormat('dd/MM/yyyy').format(_selectedBirthDate!);

      _ageController.text =
          _calculateAge(_selectedBirthDate!).toString();
    }
  }


  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('vi', 'VN'),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedBirthDate = pickedDate;

        // Hiển thị cho người dùng
        _birthDateController.text =
            DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }



  void _submitProfile() async {
    if (_isLoading) return;

    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ngày sinh")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedProfile = await ProfileApiService.updateProfile(
        fullName: _fullNameController.text.trim(),
        birthDate: DateFormat('yyyy-MM-dd').format(_selectedBirthDate!),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        age: _calculateAge(_selectedBirthDate!),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật hồ sơ thành công")),
      );

      Navigator.pop(context, updatedProfile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Cập nhật hồ sơ",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên đầy đủ',
                  prefixIcon: Icon(Icons.person),
                ),
              ),


              const SizedBox(height: 16),

              TextField(
                controller: _birthDateController,
                readOnly: true,
                onTap: _selectBirthDate,
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _ageController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Tuổi',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
              ),


              const SizedBox(height: 16),

              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ',
                  prefixIcon: Icon(Icons.home_filled),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Cập nhật tài khoản',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }
}
