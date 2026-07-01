import 'package:flutter/material.dart';
import 'dart:io';
import 'prescription_model.dart';
import 'prescription_storage.dart';
import 'prescription_input_screen.dart';

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await PrescriptionStorage.getPrescriptions();
    if (mounted) setState(() { _prescriptions = list; _isLoading = false; });
  }

  Future<void> _delete(String id) async {
    await PrescriptionStorage.deletePrescription(id);
    _load();
  }

  void _confirmDelete(Prescription p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá thuốc', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có muốn xoá "${p.name}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { Navigator.pop(ctx); _delete(p.id); },
            child: const Text('Xoá', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tủ thuốc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF3B82F6), size: 28),
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionInputScreen()));
              if (result == true) _load();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _prescriptions.length,
                  itemBuilder: (_, i) => _buildCard(_prescriptions[i]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionInputScreen()));
          if (result == true) _load();
        },
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm thuốc', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Tủ thuốc trống', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text('Nhấn nút bên dưới để thêm đơn thuốc đầu tiên', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCard(Prescription p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ảnh hoặc icon
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: p.imagePath.isNotEmpty && File(p.imagePath).existsSync()
                  ? Image.file(File(p.imagePath), width: 72, height: 72, fit: BoxFit.cover)
                  : Container(
                      width: 72, height: 72,
                      color: const Color(0xFFEFF6FF),
                      child: const Icon(Icons.medication, size: 36, color: Color(0xFF3B82F6)),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  if (p.timeText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(p.timeText, style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6)))),
                    ]),
                  ],
                  if (p.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(p.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              onPressed: () => _confirmDelete(p),
            ),
          ],
        ),
      ),
    );
  }
}
