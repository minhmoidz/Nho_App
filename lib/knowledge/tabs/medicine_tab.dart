import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../knowledge_data.dart'; // Đảm bảo đường dẫn import đúng

// Tôi để API Key ở đây vì chỉ file này dùng đến nó
const String _googleApiKey = "AIzaSyCORVLq4vzKSa71evffOKOWJtclOqVUIIcss";

class MedicineTab extends StatefulWidget {
  const MedicineTab({super.key});

  @override
  State<MedicineTab> createState() => _MedicineTabState();
}

class _MedicineTabState extends State<MedicineTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Medicine> _displayList = List.from(sampleMedicines);
  bool _isLoading = false;
  bool _isAIResult = false;

  Future<void> _handleSearch() async {
    String query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _displayList = List.from(sampleMedicines);
        _isAIResult = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final localResults = sampleMedicines.where((med) => med.name.toLowerCase().contains(query.toLowerCase())).toList();

    if (localResults.isNotEmpty) {
      setState(() {
        _displayList = localResults;
        _isLoading = false;
        _isAIResult = false;
      });
    } else {
      await _askAIForMedicine(query);
    }
  }

  Future<void> _askAIForMedicine(String drugName) async {
    try {
      const String prompt = "Bạn là dược sĩ. Trả về JSON thông tin thuốc: {name, usage, dosage, warning} cho từ khóa: ";
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_googleApiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": "$prompt '$drugName'. Trả lời tiếng Việt."}]}]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        text = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final jsonMap = jsonDecode(text);

        setState(() {
          _displayList = [Medicine(
              id: 'ai',
              name: jsonMap['name'] ?? 'Không rõ',
              usage: jsonMap['usage'] ?? '',
              dosage: jsonMap['dosage'] ?? '',
              warning: jsonMap['warning'] ?? ''
          )];
          _isAIResult = true;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm thuốc...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _handleSearch(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _handleSearch,
                icon: const Icon(Icons.search),
                style: IconButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              )
            ],
          ),
        ),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _displayList.length,
            itemBuilder: (context, index) {
              final med = _displayList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(_isAIResult ? Icons.smart_toy : Icons.medication, color: Colors.teal),
                  title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(med.usage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showModalBottomSheet(
                        context: context,
                        builder: (ctx) => Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(med.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const Divider(),
                              Text("Liều dùng: ${med.dosage}", style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 10),
                              Text("Lưu ý: ${med.warning}", style: const TextStyle(fontSize: 16, color: Colors.red)),
                            ],
                          ),
                        )
                    );
                  },
                ),
              );
            },
          ),
        )
      ],
    );
  }
}