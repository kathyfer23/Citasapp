import 'package:flutter/foundation.dart';
import '../models/patient_model.dart';
import '../services/patient_service.dart';

class PatientProvider with ChangeNotifier {
  final PatientService _patientService = PatientService();
  
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String _searchQuery = '';

  List<Patient> get patients => _patients;
  Patient? get selectedPatient => _selectedPatient;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMorePages => _currentPage < _totalPages;

  Future<void> loadPatients({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _patients = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _patientService.getPatients(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      page: _currentPage,
    );

    _isLoading = false;

    if (result['success']) {
      final List<Patient> newPatients = result['patients'];
      
      if (refresh) {
        _patients = newPatients;
      } else {
        _patients.addAll(newPatients);
      }
      
      final pagination = result['pagination'];
      _totalPages = pagination['totalPages'] ?? 1;
    } else {
      _error = result['message'];
    }

    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasMorePages || _isLoading) return;
    _currentPage++;
    await loadPatients();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadPatients(refresh: true);
  }

  Future<void> loadPatient(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _patientService.getPatient(id);

    _isLoading = false;

    if (result['success']) {
      _selectedPatient = result['patient'];
    } else {
      _error = result['message'];
    }

    notifyListeners();
  }

  Future<bool> createPatient(Patient patient) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _patientService.createPatient(patient);

    _isLoading = false;

    if (result['success']) {
      _patients.insert(0, result['patient']);
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePatient(String id, Patient patient) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _patientService.updatePatient(id, patient);

    _isLoading = false;

    if (result['success']) {
      final index = _patients.indexWhere((p) => p.id == id);
      if (index != -1) {
        _patients[index] = result['patient'];
      }
      _selectedPatient = result['patient'];
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePatient(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _patientService.deletePatient(id);

    _isLoading = false;

    if (result['success']) {
      _patients.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  void clearSelectedPatient() {
    _selectedPatient = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
