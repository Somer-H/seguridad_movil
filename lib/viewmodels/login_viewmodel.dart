import 'package:flutter/material.dart';
import '../models/user_model.dart';

class LoginViewModel extends ChangeNotifier {
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;

  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  Future<void> login() async {
    if (_email.isEmpty || _password.isEmpty) {
      _errorMessage = 'Por favor ingresa correo y contraseña';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulamos un retraso de red (ej: llamada a API)
      await Future.delayed(const Duration(seconds: 2));

      // Simulamos la validación de credenciales
      if (_email == 'admin@test.com' && _password == '123456') {
        _user = UserModel(email: _email, token: 'fake_jwt_token_123');
      } else {
        _errorMessage = 'Credenciales inválidas';
      }
    } catch (e) {
      _errorMessage = 'Error de conexión';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
