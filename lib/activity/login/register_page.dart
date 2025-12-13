import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Chỉ giữ lại các controller cần thiết
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Tạo map dữ liệu: Chỉ lấy dữ liệu từ 4 trường nhập,
      // các trường còn lại gán giá trị mặc định (rỗng hoặc 0)
      Map<String, dynamic> userData = {
        "email": _emailController.text.trim(),
        "username": _usernameController.text.trim(),
        "password": _passwordController.text.trim(),
        "phone": _phoneController.text.trim(),

        // --- CÁC TRƯỜNG ẨN (GỬI MẶC ĐỊNH) ---
        "dob": 0,
        "gender": "",
        "first_name": "",
        "last_name": "",
        "full_name": "", // Có thể tự động gán bằng username nếu muốn
        "address": "",
        "identity_card": "",
        "identity_card_date": 0,
        "identity_card_place": "",
      };

      try {
        final response = await _apiService.register(userData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Đăng ký thành công! Vui lòng đăng nhập.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Quay lại trang đăng nhập
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo tài khoản'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Nhập thông tin để đăng ký",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // 1. Username
              _buildTextFormField(_usernameController, 'Tên đăng nhập *', Icons.person, isRequired: true),

              // 2. Password
              _buildTextFormField(_passwordController, 'Mật khẩu *', Icons.lock, isRequired: true, obscureText: true),

              // 3. Email
              _buildTextFormField(_emailController, 'Email *', Icons.email, isRequired: true, keyboardType: TextInputType.emailAddress),

              // 4. Phone
              _buildTextFormField(_phoneController, 'Số điện thoại', Icons.phone, keyboardType: TextInputType.phone),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                  backgroundColor: Colors.blue, // Thêm màu cho nút nổi bật hơn
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  'Đăng ký ngay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool isRequired = false,
        bool obscureText = false,
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: isRequired
            ? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Vui lòng nhập $label';
          }
          return null;
        }
            : null,
      ),
    );
  }
}