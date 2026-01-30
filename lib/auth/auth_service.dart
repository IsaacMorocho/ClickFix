import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_service.dart';

/// Servicio de autenticación con Supabase
/// Maneja login, registro, recuperación de contraseña y sesiones
class AuthService {
  // Obtener instancia de Supabase
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Login con email y contraseña
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        // Guardar ID de usuario en DatabaseService
        DatabaseService.setCurrentUserId(response.user!.id);
      }

      return AuthResponse(
        user: response.user?.toJson(),
        session: response.session?.toJson(),
      );
    } on AuthException catch (e) {
      // Errores específicos de autenticación
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error de conexión. Verifica tu internet.';
    }
  }

  /// Registro de cliente
  Future<AuthResponse> registerClient({
    required String email,
    required String password,
    required String nombreCompleto,
    required String cedula,
    required String telefono,
  }) async {
    try {
      // 1. Crear usuario en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'nombre_completo': nombreCompleto,
          'cedula': cedula,
          'telefono': telefono,
          'rol': 'cliente',
        },
      );

      if (response.user == null) {
        throw 'No se pudo crear el usuario. Intenta de nuevo.';
      }

      // 2. El trigger handle_new_user() en Supabase creará automáticamente
      //    el registro en la tabla 'users'

      // Guardar ID de usuario
      DatabaseService.setCurrentUserId(response.user!.id);

      return AuthResponse(
        user: response.user?.toJson(),
        session: response.session?.toJson(),
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Error al registrar. Intenta de nuevo.';
    }
  }

  /// Registro de técnico
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
    try {
      // 1. Crear usuario en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
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

      if (response.user == null) {
        throw 'No se pudo crear el usuario. Intenta de nuevo.';
      }

      // Guardar ID de usuario
      DatabaseService.setCurrentUserId(response.user!.id);

      // 2. Esperar un momento para que el trigger handle_new_user() cree
      //    el registro en public.users
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Intentar crear perfil de técnico
      try {
        await _supabase.from('technician_profiles').insert({
          'user_id': response.user!.id,
          'anios_experiencia': aniosExperiencia,
          'descripcion_profesional': descripcionProfesional,
          'tarifa_base': tarifaBase,
          'zona_cobertura': zonaCobertura,
        });
      } on PostgrestException catch (e) {
        // Si falla crear el perfil técnico, el usuario ya existe en auth
        // pero el registro fue exitoso, solo falta el perfil
        print('Error al crear perfil técnico: ${e.message}');
        print('El usuario se creó exitosamente pero falta el perfil técnico');
        // No lanzar error, el usuario se creó correctamente
        // El perfil se puede crear después o manualmente
      }

      return AuthResponse(
        user: response.user?.toJson(),
        session: response.session?.toJson(),
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Error al registrar técnico. Intenta de nuevo.';
    }
  }

  /// Enviar correo de recuperación de contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'com.example.clickfixapp://reset-password',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al enviar correo. Verifica tu conexión.';
    }
  }

  /// Actualizar contraseña (desde reset_password_screen)
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw 'No se pudo actualizar la contraseña.';
      }

      return UserResponse(user: response.user?.toJson());
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Error al actualizar contraseña.';
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      DatabaseService.setCurrentUserId(null);
    } catch (e) {
      throw 'Error al cerrar sesión.';
    }
  }

  /// Obtener usuario actual
  User? get currentUser => _supabase.auth.currentUser;

  /// Obtener sesión actual
  Session? get currentSession => _supabase.auth.currentSession;

  /// Manejar excepciones de autenticación
  String _handleAuthException(AuthException e) {
    switch (e.statusCode) {
      case '400':
        if (e.message.contains('Invalid login credentials')) {
          return 'Correo o contraseña incorrectos.';
        }
        if (e.message.contains('User already registered')) {
          return 'Este correo ya está registrado.';
        }
        if (e.message.contains('Password should be at least')) {
          return 'La contraseña debe tener al menos 6 caracteres.';
        }
        return 'Datos inválidos. Verifica la información.';

      case '422':
        if (e.message.contains('email')) {
          return 'Formato de correo inválido.';
        }
        return 'Datos inválidos.';

      case '429':
        return 'Demasiados intentos. Espera unos minutos.';

      default:
        return e.message.isNotEmpty ? e.message : 'Error de autenticación.';
    }
  }
}

// Clases auxiliares para mantener compatibilidad con código existente
class AuthResponse {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? session;

  AuthResponse({this.user, this.session});
}

class UserResponse {
  final Map<String, dynamic>? user;

  UserResponse({this.user});
}
