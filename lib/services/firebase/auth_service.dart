import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Estado de autenticación del usuario actual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario actualmente logueado
  User? get currentUser => _auth.currentUser;

  /// Inicia sesión con Usuario y Contraseña (y los crea si no existen)
  Future<UserCredential?> signIn(BuildContext context, String username, String password) async {
    try {
      final userLower = username.trim().toLowerCase();
      if (userLower != 'luisito' && userLower != 'miri') {
        throw Exception('Usuario no válido. Usa "Luisito" o "Miri".');
      }

      String email = userLower == 'luisito' ? 'luisito@finanzas.com' : 'miri@finanzas.com';

      try {
        // Intentar iniciar sesión
        return await _auth.signInWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        // Si no existe o credenciales inválidas, intentamos crearlo
        // En versiones recientes de Firebase, a veces solo devuelve invalid-credential
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
          try {
            // Intentar crear el usuario (esto funcionará la primera vez)
            return await _auth.createUserWithEmailAndPassword(email: email, password: password);
          } on FirebaseAuthException catch (e2) {
            if (e2.code == 'email-already-in-use') {
              // Si el correo ya está en uso, significa que la contraseña estaba mal en el intento de login
              throw Exception('Contraseña incorrecta.');
            }
            throw Exception('Error al crear usuario: ${e2.message}');
          }
        }
        throw Exception('Error de autenticación: ${e.message}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Cierra sesión de Firebase
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
