import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> registerClient({
    required String email,
    required String password,
    required String nombreCompleto,
    required String cedula,
    required String telefono,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'clickfix://login-callback',
      data: {
        'nombre_completo': nombreCompleto,
        'cedula': cedula,
        'telefono': telefono,
        'rol': 'cliente',
      },
    );
    return response;
  }

  Future<AuthResponse> registerTechnician({
    required String email,
    required String password,
    required String nombreCompleto,
    required String cedula,
    required String telefono,
    required int aniosExperiencia,
    required String descripcionProfesional,
    required double tarifaBase,
    required String zonaCobertura,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'clickfix://login-callback',
      data: {
        'nombre_completo': nombreCompleto,
        'cedula': cedula,
        'telefono': telefono,
        'rol': 'tecnico',
        'anios_experiencia': aniosExperiencia,
        'descripcion_profesional': descripcionProfesional,
        'tarifa_base': tarifaBase,
        'zona_cobertura': zonaCobertura,
      },
    );
    return response;
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'clickfix://reset-password',
    );
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
  
  Session? get currentSession => _supabase.auth.currentSession;
}
