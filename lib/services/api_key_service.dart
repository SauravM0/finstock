import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiKeyService {
  static final _storage = FlutterSecureStorage();
  
  // Method to get Gemini API key from secure storage
  static Future<String> getGeminiApiKey() async {
    try {
      String? apiKey = await _storage.read(key: 'gemini_api_key');
      
      if (apiKey == null || apiKey.isEmpty) {
        // Return placeholder API key - user should replace with real one
        return 'API key';
      }
      
      return apiKey;
    } catch (e) {
      print('Error retrieving Gemini API key: $e');
      return '';
    }
  }
  
  // Method to save Gemini API key to secure storage
  static Future<bool> saveGeminiApiKey(String apiKey) async {
    try {
      await _storage.write(key: 'gemini_api_key', value: apiKey);
      return true;
    } catch (e) {
      print('Error saving Gemini API key: $e');
      return false;
    }
  }
  
  // Method to validate if API key is working
  static Future<bool> validateGeminiApiKey(String apiKey) async {
    // Skip validation if API key is empty
    if (apiKey.isEmpty) {
      return false;
    }
    
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      final response = await http.get(url).timeout(Duration(seconds: 10));
      
      // Status code 200 means the API key is valid
      if (response.statusCode == 200) {
        return true;
      }
      
      // Log the error for debugging
      print('API key validation failed. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return false;
    } catch (e) {
      print('Error validating Gemini API key: $e');
      return false;
    }
  }
} 
