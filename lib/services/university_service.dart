import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import 'firebase_service.dart';

/// Service for managing university data
class UniversityService extends GetxService {
  final FirebaseService _firebaseService = FirebaseService();
  
  final RxList<UniversityModel> universities = <UniversityModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUniversities();
  }

  /// Load universities from local JSON or Firestore
  Future<void> loadUniversities() async {
    if (universities.isNotEmpty) return;
    
    isLoading.value = true;
    try {
      // Try to load from local JSON first
      final jsonString = await rootBundle.loadString(AppConstants.universitiesJsonPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      
      universities.value = jsonList
          .map((json) => UniversityModel.fromJson(json))
          .toList();
      
      // Sort alphabetically
      universities.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      print('Error loading universities from JSON: $e');
      
      // Fallback: try loading from Firestore
      try {
        final snapshot = await _firebaseService.universitiesCollection.get();
        universities.value = snapshot.docs
            .map((doc) => UniversityModel.fromFirestore(doc))
            .toList();
        
        universities.sort((a, b) => a.name.compareTo(b.name));
      } catch (firestoreError) {
        print('Error loading universities from Firestore: $firestoreError');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Get university by ID
  UniversityModel? getUniversityById(String id) {
    try {
      return universities.firstWhere((uni) => uni.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get university by domain
  UniversityModel? getUniversityByDomain(String domain) {
    try {
      return universities.firstWhere(
        (uni) => uni.domains.contains(domain.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  /// Validate email domain against university
  bool validateEmailDomain(String email, String universityId) {
    final university = getUniversityById(universityId);
    if (university == null) return false;
    
    final domain = email.split('@').last.toLowerCase();
    return university.domains.contains(domain);
  }

  /// Search universities by name
  List<UniversityModel> searchUniversities(String query) {
    if (query.isEmpty) return universities;
    
    final lowerQuery = query.toLowerCase();
    return universities
        .where((uni) => uni.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Upload universities from JSON to Firestore (admin tool)
  Future<void> seedUniversitiesToFirestore() async {
    if (universities.isEmpty) {
      await loadUniversities();
    }
    
    final batch = _firebaseService.firestore.batch();
    
    for (final university in universities) {
      final docRef = _firebaseService.universitiesCollection.doc(university.id);
      batch.set(docRef, university.toFirestore());
    }
    
    await batch.commit();
    print('Successfully seeded ${universities.length} universities to Firestore');
  }
}

