import 'package:flutter/material.dart';
import 'package:artefacto/model/user_model.dart';
import 'package:artefacto/service/user_service.dart';

class UserProviderService extends ChangeNotifier {
  User? _user;
  User? get user => _user;
  final _userService = UserService();

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      final updatedUser = await _userService.getCurrentUser();
      if (updatedUser != null) {
        setUser(updatedUser);
      }
    } catch (e) {
      print('Error refreshing user: $e');
    }
  }
}
