import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio de base de datos con Supabase
/// Maneja todas las operaciones CRUD con la base de datos
class DatabaseService {
  // Obtener instancia de Supabase
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ID de usuario actual
  static String? _currentUserId;
  static String? get currentUserId => _currentUserId;

  static void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  // ========================================================================
  // MÉTODOS DE PERFIL DE USUARIO
  // ========================================================================

  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } on PostgrestException catch (e) {
      throw 'Error al obtener perfil: ${e.message}';
    } catch (e) {
      throw 'Error de conexión al obtener perfil.';
    }
  }

  static Future<String?> getCurrentUserRole() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?['rol'] as String?;
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'Usuario no autenticado';

      await _supabase.from('users').update(updates).eq('id', userId);
    } on PostgrestException catch (e) {
      throw 'Error al actualizar perfil: ${e.message}';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Error al actualizar perfil.';
    }
  }

  // ========================================================================
  // MÉTODOS DE ESPECIALIDADES
  // ========================================================================

  static Future<List<Map<String, dynamic>>> getSpecialties() async {
    try {
      final response = await _supabase
          .from('especialidades')
          .select()
          .order('nombre');

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw 'Error al cargar especialidades: ${e.message}';
    } catch (e) {
      throw 'Error de conexión al cargar especialidades.';
    }
  }

  // ========================================================================
  // MÉTODOS DE PERFIL DE TÉCNICO
  // ========================================================================

  static Future<Map<String, dynamic>?> getTechnicianProfile(
    String? userId,
  ) async {
    try {
      final id = userId ?? _supabase.auth.currentUser?.id;
      if (id == null) return null;

      final response = await _supabase
          .from('technician_profiles')
          .select('*, users!technician_profiles_user_id_fkey(*)')
          .eq('user_id', id)
          .single();

      return response;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') return null; // No rows returned
      throw 'Error al obtener perfil de técnico: ${e.message}';
    } catch (e) {
      throw 'Error de conexión al obtener perfil de técnico.';
    }
  }

  static Future<void> updateTechnicianProfile(
    String technicianId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _supabase
          .from('technician_profiles')
          .update(updates)
          .eq('id', technicianId);
    } on PostgrestException catch (e) {
      throw 'Error al actualizar perfil de técnico: ${e.message}';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Error al actualizar perfil de técnico.';
    }
  }

  static Future<List<Map<String, dynamic>>> getTechnicianSpecialties(
    String technicianId,
  ) async {
    try {
      final response = await _supabase
          .from('technician_specialties')
          .select('*, especialidades(*)')
          .eq('technician_id', technicianId);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw 'Error al cargar especialidades del técnico: ${e.message}';
    } catch (e) {
      throw 'Error de conexión.';
    }
  }

  static Future<void> updateTechnicianSpecialties(
    String technicianId,
    List<String> specialtyIds,
  ) async {
    try {
      // 1. Eliminar especialidades existentes
      await _supabase
          .from('technician_specialties')
          .delete()
          .eq('technician_id', technicianId);

      // 2. Insertar nuevas especialidades
      if (specialtyIds.isNotEmpty) {
        final inserts = specialtyIds
            .map(
              (specialtyId) => {
                'technician_id': technicianId,
                'specialty_id': specialtyId,
              },
            )
            .toList();

        await _supabase.from('technician_specialties').insert(inserts);
      }
    } on PostgrestException catch (e) {
      throw 'Error al actualizar especialidades: ${e.message}';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Error al actualizar especialidades.';
    }
  }

  // ========================================================================
  // MÉTODOS DE CERTIFICADOS
  // ========================================================================

  static Future<List<Map<String, dynamic>>> getTechnicianCertificates(
    String technicianId,
  ) async {
    try {
      final response = await _supabase
          .from('certificates')
          .select()
          .eq('technician_id', technicianId)
          .order('fecha_emision', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw 'Error al cargar certificados: ${e.message}';
    } catch (e) {
      throw 'Error de conexión.';
    }
  }

  static Future<void> addCertificate(Map<String, dynamic> certificate) async {
    try {
      await _supabase.from('certificates').insert(certificate);
    } on PostgrestException catch (e) {
      throw 'Error al agregar certificado: ${e.message}';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Error al agregar certificado.';
    }
  }

  static Future<void> deleteCertificate(String certificateId) async {
    try {
      await _supabase.from('certificates').delete().eq('id', certificateId);
    } on PostgrestException catch (e) {
      throw 'Error al eliminar certificado: ${e.message}';
    } catch (e) {
      throw 'Error al eliminar certificado.';
    }
  }

  // ========================================================================
  // MÉTODOS DE SOLICITUDES DE SERVICIO
  // ========================================================================

  static Future<List<Map<String, dynamic>>> getServiceRequests({
    String? clientId,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('service_requests')
          .select(
            '*, specialty:especialidades!service_requests_specialty_id_fkey(*)',
          );

      if (clientId != null) {
        query = query.eq('client_id', clientId);
      }

      if (status != null) {
        query = query.eq('estado', status);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw 'Error al cargar solicitudes: ${e.message}';
    } catch (e) {
      throw 'Error de conexión.';
    }
  }

  static Future<Map<String, dynamic>?> getServiceRequestDetail(
    String requestId,
  ) async {
    try {
      final response = await _supabase
          .from('service_requests')
          .select(
            '*, specialty:especialidades!service_requests_specialty_id_fkey(*), client:users!service_requests_client_id_fkey(*)',
          )
          .eq('id', requestId)
          .single();

      return response;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') return null;
      throw 'Error al obtener detalle: ${e.message}';
    } catch (e) {
      throw 'Error de conexión.';
    }
  }

  static Future<void> createServiceRequest(Map<String, dynamic> request) async {
    try {
      await _supabase.from('service_requests').insert(request);
    } on PostgrestException catch (e) {
      throw 'Error al crear solicitud: ${e.message}';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Error al crear solicitud.';
    }
  }

  static Future<void> updateServiceRequestStatus(
    String requestId,
    String status,
  ) async {
    try {
      await _supabase
          .from('service_requests')
          .update({'estado': status})
          .eq('id', requestId);
    } on PostgrestException catch (e) {
      throw 'Error al actualizar estado: ${e.message}';
    } catch (e) {
      throw 'Error al actualizar estado.';
    }
  }

  // ========================================================================
  // MÉTODOS DE SOLICITUDES DISPONIBLES
  // ========================================================================

  static Future<List<Map<String, dynamic>>> getAvailableRequests({
    String? specialtyId,
  }) async {
    try {
      var query = _supabase
          .from('service_requests')
          .select(
            '*, specialty:especialidades!service_requests_specialty_id_fkey(*), client:users!service_requests_client_id_fkey(*)',
          )
          .inFilter('estado', ['pendiente', 'cotizando']);

      if (specialtyId != null) {
        query = query.eq('specialty_id', specialtyId);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw 'Error al cargar solicitudes disponibles: ${e.message}';
    } catch (e) {
      throw 'Error de conexión.';
    }
  }

  // ========================================================================
  // MÉTODOS DE COTIZACIONES
  // ========================================================================

  static Future<List<Map<String, dynamic>>> getQuotesForRequest(
    String requestId,
  ) async {
    try {
      final response = await _supabase
          .from('quotations')
          .select(
            '*, technician_profiles!inner(*, users!technician_profiles_user_id_fkey(*))',
          )
          .eq('service_request_id', requestId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw 'Error al cargar cotizaciones: ${e.message}';
    } catch (e) {
      throw 'Error de conexión.';
    }
  }

  static Future<List<Map<String, dynamic>>> getTechnicianQuotes(
    String technicianId,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  static Future<void> createQuote(Map<String, dynamic> quote) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<void> updateQuoteStatus(String quoteId, String status) async {
    try {
      await _supabase
          .from('quotations')
          .update({'estado': status})
          .eq('id', quoteId);
    } on PostgrestException catch (e) {
      throw 'Error al actualizar cotización: ${e.message}';
    } catch (e) {
      throw 'Error de conexión al actualizar cotización.';
    }
  }

  static Future<void> acceptQuote(String quoteId, String requestId) async {
    try {
      // 1. Actualizar estado de la cotización a 'aceptada'
      await _supabase
          .from('quotations')
          .update({'estado': 'aceptada'})
          .eq('id', quoteId);

      // 2. Rechazar todas las demás cotizaciones de esta solicitud
      await _supabase
          .from('quotations')
          .update({'estado': 'rechazada'})
          .eq('service_request_id', requestId)
          .neq('id', quoteId);

      // 3. Actualizar estado de la solicitud a 'asignado'
      await _supabase
          .from('service_requests')
          .update({'estado': 'asignado'})
          .eq('id', requestId);
    } on PostgrestException catch (e) {
      throw 'Error al aceptar cotización: ${e.message}';
    } catch (e) {
      throw 'Error de conexión al aceptar cotización.';
    }
  }

  // ========================================================================
  // MÉTODOS DE SERVICIOS
  // ========================================================================

  static Future<List<Map<String, dynamic>>> getServices({
    String? technicianId,
    String? clientId,
    String? status,
  }) async {
    try {
      // Buscar en service_requests
      var query = _supabase.from('service_requests').select('''
            *,
            client:users!service_requests_client_id_fkey(*),
            specialty:especialidades!service_requests_specialty_id_fkey(*)
          ''');

      if (clientId != null) {
        query = query.eq('client_id', clientId);
      }

      if (status != null) {
        query = query.eq('estado', status);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw 'Error al cargar servicios: ${e.message}';
    } catch (e) {
      throw 'Error de conexión al cargar servicios.';
    }
  }

  static Future<Map<String, dynamic>?> getServiceDetail(
    String serviceId,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return null;
  }

  static Future<void> updateServiceStatus(
    String serviceId,
    String status,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<void> createService(Map<String, dynamic> service) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ========================================================================
  // MÉTODOS DE RESEÑAS
  // ========================================================================

  static Future<List<Map<String, dynamic>>> getReviews({
    String? receptorId,
    String? autorId,
  }) async {
    try {
      var query = _supabase.from('reviews').select();

      if (receptorId != null) {
        query = query.eq('receptor_id', receptorId);
      }

      if (autorId != null) {
        query = query.eq('autor_id', autorId);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw 'Error al cargar reseñas: ${e.message}';
    } catch (e) {
      throw 'Error de conexión al cargar reseñas.';
    }
  }

  static Future<void> createReview(Map<String, dynamic> review) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ========================================================================
  // MÉTODOS DE NOTIFICACIONES
  // ========================================================================

  static Future<List<Map<String, dynamic>>> getNotifications(
    String userId,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<void> createNotification(
    Map<String, dynamic> notification,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Nota: Los métodos updateUserProfile y updateTechnicianProfile ya están implementados arriba

  // ========================================================================
  // MÉTODOS DE ADMINISTRACIÓN
  // ========================================================================

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  static Future<List<Map<String, dynamic>>> getAllTechnicians({
    bool? verified,
  }) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  static Future<List<Map<String, dynamic>>> getTechniciansWithLocation() async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  static Future<void> verifyTechnician(
    String technicianId,
    String adminId,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<void> toggleUserStatus(String userId, String status) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<void> createSpecialty(Map<String, dynamic> specialty) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<void> updateSpecialty(
    String specialtyId,
    Map<String, dynamic> data,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<void> deleteSpecialty(String specialtyId) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<Map<String, int>> getAdminStats() async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return {'users': 0, 'technicians': 0, 'requests': 0, 'services': 0};
  }

  static Future<List<Map<String, dynamic>>> getPendingReviews() async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  // ========================================================================
  // MÉTODOS DE ALMACENAMIENTO (STORAGE)
  // ========================================================================

  static Future<String?> uploadAvatar(
    String userId,
    Uint8List bytes,
    String extension,
  ) async {
    // TODO: Implementar con Supabase Storage
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://via.placeholder.com/150';
  }

  static String getAvatarUrl(String userId, {String extension = 'jpg'}) {
    // TODO: Implementar con Supabase Storage
    return 'https://via.placeholder.com/150';
  }

  static Future<void> deleteAvatar(String userId, String extension) async {
    // TODO: Implementar con Supabase Storage
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<String?> uploadPortfolioImage(
    String technicianId,
    Uint8List bytes,
    String fileName,
  ) async {
    // TODO: Implementar con Supabase Storage
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://via.placeholder.com/300';
  }

  static Future<List<String>> getPortfolioImages(String technicianId) async {
    // TODO: Implementar con Supabase Storage
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  static Future<void> deletePortfolioImage(
    String technicianId,
    String fileName,
  ) async {
    // TODO: Implementar con Supabase Storage
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<String?> uploadCertificate(
    String technicianId,
    Uint8List bytes,
    String fileName,
  ) async {
    // TODO: Implementar con Supabase Storage
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://via.placeholder.com/400';
  }

  static Future<List<Map<String, String>>> getCertificateFiles(
    String technicianId,
  ) async {
    // TODO: Implementar con Supabase Storage
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  static Future<void> deleteCertificateFile(
    String technicianId,
    String fileName,
  ) async {
    // TODO: Implementar con Supabase Storage
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<String?> uploadFile(
    String bucket,
    String path,
    Uint8List bytes,
  ) async {
    // TODO: Implementar con Supabase Storage
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://via.placeholder.com/200';
  }

  static String getFileUrl(String bucket, String path) {
    // TODO: Implementar con Supabase Storage
    return 'https://via.placeholder.com/200';
  }

  static Future<void> deleteFile(String bucket, String path) async {
    // TODO: Implementar con Supabase Storage
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ========================================================================
  // TÉCNICOS FAVORITOS
  // ========================================================================

  // ========================================================================
  // MÉTODO PARA OBTENER CLIENTES CON SOLICITUDES (MAPA)
  // ========================================================================

  static Future<List<Map<String, dynamic>>>
  getAcceptedQuotationsClients() async {
    try {
      // Obtener todas las solicitudes activas con ubicación
      final response = await _supabase
          .from('service_requests')
          .select('''
            *,
            client:users!service_requests_client_id_fkey(*),
            specialty:especialidades!service_requests_specialty_id_fkey(*)
          ''')
          .inFilter('estado', ['pendiente', 'en_progreso', 'asignado'])
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw 'Error al cargar clientes: ${e.message}';
    } catch (e) {
      throw 'Error de conexión al cargar clientes.';
    }
  }

  static Future<List<Map<String, dynamic>>> getFavoriteTechnicians(
    String clientId,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  static Future<void> addFavoriteTechnician(
    String clientId,
    String technicianId,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<void> removeFavoriteTechnician(
    String clientId,
    String technicianId,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<bool> isFavoriteTechnician(
    String clientId,
    String technicianId,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return false;
  }

  // ========================================================================
  // CALIFICACIONES BIDIRECCIONALES
  // ========================================================================

  static Future<void> rateTechnician({
    required String serviceId,
    required String clientId,
    required String technicianId,
    required double rating,
    required String comment,
  }) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<void> rateClient({
    required String serviceId,
    required String technicianId,
    required String clientId,
    required double rating,
    required String comment,
  }) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ========================================================================
  // SEGUIMIENTO DE SERVICIOS
  // ========================================================================

  static Future<Map<String, dynamic>> getServiceById(String serviceId) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return {};
  }

  // ========================================================================
  // FILTROS DE TÉCNICOS
  // ========================================================================

  static Future<List<Map<String, dynamic>>> filterTechnicians({
    String? sortBy,
    double? maxPrice,
    double? minRating,
    double? maxDistance,
    String? specialty,
  }) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  // ========================================================================
  // HISTORIAL DE TRABAJOS TÉCNICO
  // ========================================================================

  static Future<List<Map<String, dynamic>>> getTechnicianCompletedServices(
    String technicianId,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  // ========================================================================
  // CALCULADORA DE PRECIOS
  // ========================================================================

  static Future<Map<String, dynamic>> calculateSuggestedPrice({
    required String serviceType,
    String? zone,
    required String technicianId,
  }) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'suggested_price': 50.0,
      'min_price': 30.0,
      'max_price': 100.0,
      'factors': {
        'experience_years': 2,
        'market_average': 45.0,
        'zone_factor': 1.1,
      },
    };
  }

  static Future<void> createQuotation({
    required String serviceRequestId,
    required String technicianId,
    required double amount,
    required int estimatedDuration,
    required String description,
  }) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ========================================================================
  // PROTECCIÓN DE PRECIOS
  // ========================================================================

  static Future<bool> canEditPrice(String quotationId) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  static Future<List<Map<String, dynamic>>> getPriceHistory(
    String serviceId,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  // ========================================================================
  // SERVICIOS A DOMICILIO
  // ========================================================================

  static Future<void> confirmTechnicianArrival({
    required String serviceId,
    required String technicianId,
    double? latitude,
    double? longitude,
  }) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<String?> uploadProblemPhoto({
    required String serviceId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    // TODO: Conectar con Supabase Storage
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  static Future<String?> uploadCompletedWorkPhoto({
    required String serviceId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    // TODO: Conectar con Supabase Storage
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  static Future<List<Map<String, dynamic>>> getServicePhotos(
    String serviceId,
  ) async {
    // TODO: Conectar con Supabase
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }
}
