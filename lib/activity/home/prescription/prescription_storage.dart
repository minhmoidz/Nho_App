import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'prescription_model.dart';

class PrescriptionStorage {
  static const String _key = 'prescriptions_data';

  static Future<List<Prescription>> getPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => Prescription.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePrescriptions(List<Prescription> prescriptions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(prescriptions.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  static Future<void> addPrescription(Prescription prescription) async {
    final list = await getPrescriptions();
    list.insert(0, prescription);
    await savePrescriptions(list);
  }

  static Future<void> deletePrescription(String id) async {
    final list = await getPrescriptions();
    list.removeWhere((p) => p.id == id);
    await savePrescriptions(list);
  }
}
