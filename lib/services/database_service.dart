import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final _client = Supabase.instance.client;

  static String? get currentUserId => _client.auth.currentUser?.id;

  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  static Future<String?> getCurrentUserRole() async {
    final profile = await getCurrentUserProfile();
    return profile?['rol'] as String?;
  }

  static Future<List<Map<String, dynamic>>> getSpecialties() async {
    final response = await _client.from('specialties').select().order('nombre');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> getTechnicianProfile(
    String? userId,
  ) async {
    final id = userId ?? currentUserId;
    if (id == null) return null;

    final response = await _client
        .from('technicians')
        .select('*, users!technicians_user_id_fkey(*)')
        .eq('user_id', id)
        .maybeSingle();
    return response;
  }

  static Future<List<Map<String, dynamic>>> getTechnicianSpecialties(
    String technicianId,
  ) async {
    final response = await _client
        .from('technician_specialties')
        .select('*, specialties!technician_specialties_specialty_id_fkey(*)')
        .eq('technician_id', technicianId);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> updateTechnicianSpecialties(
    String technicianId,
    List<String> specialtyIds,
  ) async {
    await _client
        .from('technician_specialties')
        .delete()
        .eq('technician_id', technicianId);

    if (specialtyIds.isNotEmpty) {
      final inserts = specialtyIds
          .map((id) => {'technician_id': technicianId, 'specialty_id': id})
          .toList();
      await _client.from('technician_specialties').insert(inserts);
    }
  }

  static Future<List<Map<String, dynamic>>> getTechnicianCertificates(
    String technicianId,
  ) async {
    final response = await _client
        .from('technician_certificates')
        .select()
        .eq('technician_id', technicianId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> addCertificate(Map<String, dynamic> certificate) async {
    await _client.from('technician_certificates').insert(certificate);
  }

  static Future<void> deleteCertificate(String certificateId) async {
    await _client
        .from('technician_certificates')
        .delete()
        .eq('id', certificateId);
  }

  static Future<List<Map<String, dynamic>>> getServiceRequests({
    String? clientId,
    String? status,
  }) async {
    var query = _client
        .from('service_requests')
        .select('*, users!cliente_id(*)');

    if (clientId != null) {
      query = query.eq('cliente_id', clientId);
    }
    if (status != null) {
      query = query.eq('estado', status);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> getServiceRequestDetail(
    String requestId,
  ) async {
    final response = await _client
        .from('service_requests')
        .select('*, users!cliente_id(*)')
        .eq('id', requestId)
        .maybeSingle();
    return response;
  }

  static Future<void> createServiceRequest(Map<String, dynamic> request) async {
    await _client.from('service_requests').insert(request);
  }

  static Future<void> updateServiceRequestStatus(
    String requestId,
    String status,
  ) async {
    await _client
        .from('service_requests')
        .update({'estado': status})
        .eq('id', requestId);
  }

  static Future<List<Map<String, dynamic>>> getAvailableRequests({
    String? specialtyId,
  }) async {
    var query = _client
        .from('service_requests')
        .select('*, users!cliente_id(*)')
        .eq('estado', 'solicitud');

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getQuotesForRequest(
    String requestId,
  ) async {
    final response = await _client
        .from('quotes')
        .select('*, technicians(*, users(*))')
        .eq('service_request_id', requestId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getTechnicianQuotes(
    String technicianId,
  ) async {
    final response = await _client
        .from('quotes')
        .select('*, service_requests(*, users!cliente_id(*))')
        .eq('technician_id', technicianId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> createQuote(Map<String, dynamic> quote) async {
    await _client.from('quotes').insert(quote);
  }

  static Future<void> updateQuoteStatus(String quoteId, String status) async {
    await _client.from('quotes').update({'estado': status}).eq('id', quoteId);
  }

  static Future<void> acceptQuote(String quoteId, String requestId) async {
    await _client
        .from('quotes')
        .update({'estado': 'aceptada'})
        .eq('id', quoteId);
    await _client
        .from('quotes')
        .update({'estado': 'rechazada'})
        .eq('service_request_id', requestId)
        .neq('id', quoteId);
    await _client
        .from('service_requests')
        .update({'estado': 'asignado'})
        .eq('id', requestId);
  }

  static Future<List<Map<String, dynamic>>> getServices({
    String? technicianId,
    String? clientId,
    String? status,
  }) async {
    var query = _client
        .from('services')
        .select(
          '*, service_requests(*, users!service_requests_cliente_id_fkey(*)), technicians(*, users!technicians_user_id_fkey(*)), quotes(*)',
        );

    if (technicianId != null) {
      query = query.eq('technician_id', technicianId);
    }
    if (status != null) {
      query = query.eq('estado', status);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> getServiceDetail(
    String serviceId,
  ) async {
    final response = await _client
        .from('services')
        .select(
          '*, service_requests(*, users!service_requests_cliente_id_fkey(*)), technicians(*, users!technicians_user_id_fkey(*)), quotes(*)',
        )
        .eq('id', serviceId)
        .maybeSingle();
    return response;
  }

  static Future<void> updateServiceStatus(
    String serviceId,
    String status,
  ) async {
    final updates = <String, dynamic>{'estado': status};
    if (status == 'completado') {
      updates['fecha_fin'] = DateTime.now().toIso8601String();
    }
    await _client.from('services').update(updates).eq('id', serviceId);
  }

  static Future<void> createService(Map<String, dynamic> service) async {
    await _client.from('services').insert(service);
  }

  static Future<List<Map<String, dynamic>>> getReviews({
    String? receptorId,
    String? autorId,
  }) async {
    var query = _client
        .from('reviews')
        .select(
          '*, services(*, service_requests(*)), autor:users!reviews_autor_id_fkey(*), receptor:users!reviews_receptor_id_fkey(*)',
        );

    if (receptorId != null) {
      query = query.eq('receptor_id', receptorId);
    }
    if (autorId != null) {
      query = query.eq('autor_id', autorId);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> createReview(Map<String, dynamic> review) async {
    await _client.from('reviews').insert(review);
  }

  static Future<List<Map<String, dynamic>>> getNotifications(
    String userId,
  ) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'leida': true})
        .eq('id', notificationId);
  }

  static Future<void> createNotification(
    Map<String, dynamic> notification,
  ) async {
    await _client.from('notifications').insert(notification);
  }

  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('users').update(data).eq('id', userId);
  }

  static Future<void> updateTechnicianProfile(
    String technicianId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('technicians').update(data).eq('id', technicianId);
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await _client
        .from('users')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getAllTechnicians({
    bool? verified,
  }) async {
    var query = _client
        .from('technicians')
        .select(
          '*, users!technicians_user_id_fkey(*), technician_specialties(*, specialties(*)), certificates:technician_certificates(*)',
        );

    if (verified == true) {
      query = query.not('verificado_por', 'is', null);
    } else if (verified == false) {
      query = query.isFilter('verificado_por', null);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Obtener tecnicos verificados con su ubicacion para recomendaciones
  static Future<List<Map<String, dynamic>>> getTechniciansWithLocation() async {
    final response = await _client
        .from('technicians')
        .select(
          '*, users!technicians_user_id_fkey(*), technician_specialties(*, specialties!technician_specialties_specialty_id_fkey(*))',
        )
        .not('verificado_por', 'is', null)
        .order('rating_promedio', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> verifyTechnician(
    String technicianId,
    String adminId,
  ) async {
    await _client
        .from('technicians')
        .update({
          'verificado_por': adminId,
          'fecha_verificacion': DateTime.now().toIso8601String(),
        })
        .eq('id', technicianId);
  }

  static Future<void> toggleUserStatus(String userId, String status) async {
    await _client.from('users').update({'estado': status}).eq('id', userId);
  }

  static Future<void> createSpecialty(Map<String, dynamic> specialty) async {
    await _client.from('specialties').insert(specialty);
  }

  static Future<void> updateSpecialty(
    String specialtyId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('specialties').update(data).eq('id', specialtyId);
  }

  static Future<void> deleteSpecialty(String specialtyId) async {
    await _client.from('specialties').delete().eq('id', specialtyId);
  }

  static Future<Map<String, int>> getAdminStats() async {
    final users = await _client
        .from('users')
        .select('id')
        .count(CountOption.exact);
    final technicians = await _client
        .from('technicians')
        .select('id')
        .count(CountOption.exact);
    final requests = await _client
        .from('service_requests')
        .select('id')
        .count(CountOption.exact);
    final services = await _client
        .from('services')
        .select('id')
        .count(CountOption.exact);

    return {
      'users': users.count,
      'technicians': technicians.count,
      'requests': requests.count,
      'services': services.count,
    };
  }

  static Future<List<Map<String, dynamic>>> getPendingReviews() async {
    final response = await _client
        .from('reviews')
        .select(
          '*, services(*, service_requests(*)), autor:users!reviews_autor_id_fkey(*), receptor:users!reviews_receptor_id_fkey(*)',
        )
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ========================================================================
  // STORAGE - BUCKETS (avatars, portfolio, certificados)
  // ========================================================================

  /// Subir avatar de usuario al bucket 'avatars'
  /// Retorna la URL pública del archivo
  static Future<String?> uploadAvatar(
    String userId,
    Uint8List bytes,
    String extension,
  ) async {
    final path = '$userId/avatar.$extension';
    try {
      await _client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener URL del avatar de un usuario
  static String getAvatarUrl(String userId, {String extension = 'jpg'}) {
    return _client.storage
        .from('avatars')
        .getPublicUrl('$userId/avatar.$extension');
  }

  /// Eliminar avatar de usuario
  static Future<void> deleteAvatar(String userId, String extension) async {
    await _client.storage.from('avatars').remove(['$userId/avatar.$extension']);
  }

  /// Subir foto al portfolio del técnico
  /// Retorna la URL pública del archivo
  static Future<String?> uploadPortfolioImage(
    String technicianId,
    Uint8List bytes,
    String fileName,
  ) async {
    final path = '$technicianId/$fileName';
    try {
      await _client.storage
          .from('portfolio')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from('portfolio').getPublicUrl(path);
    } catch (e) {
      rethrow;
    }
  }

  /// Listar fotos del portfolio de un técnico
  static Future<List<String>> getPortfolioImages(String technicianId) async {
    try {
      final files = await _client.storage
          .from('portfolio')
          .list(path: technicianId);
      return files
          .map(
            (file) => _client.storage
                .from('portfolio')
                .getPublicUrl('$technicianId/${file.name}'),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Eliminar foto del portfolio
  static Future<void> deletePortfolioImage(
    String technicianId,
    String fileName,
  ) async {
    await _client.storage.from('portfolio').remove(['$technicianId/$fileName']);
  }

  /// Subir certificado del técnico
  /// Retorna la URL pública del archivo
  static Future<String?> uploadCertificate(
    String technicianId,
    Uint8List bytes,
    String fileName,
  ) async {
    final path = '$technicianId/$fileName';
    try {
      await _client.storage
          .from('certificados')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from('certificados').getPublicUrl(path);
    } catch (e) {
      rethrow;
    }
  }

  /// Listar certificados de un técnico
  static Future<List<Map<String, String>>> getCertificateFiles(
    String technicianId,
  ) async {
    try {
      final files = await _client.storage
          .from('certificados')
          .list(path: technicianId);
      return files
          .map(
            (file) => {
              'name': file.name,
              'url': _client.storage
                  .from('certificados')
                  .getPublicUrl('$technicianId/${file.name}'),
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Eliminar certificado del storage
  static Future<void> deleteCertificateFile(
    String technicianId,
    String fileName,
  ) async {
    await _client.storage.from('certificados').remove([
      '$technicianId/$fileName',
    ]);
  }

  /// Método genérico para subir archivo a cualquier bucket
  static Future<String?> uploadFile(
    String bucket,
    String path,
    Uint8List bytes,
  ) async {
    try {
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener URL pública de un archivo
  static String getFileUrl(String bucket, String path) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// Eliminar archivo de cualquier bucket
  static Future<void> deleteFile(String bucket, String path) async {
    await _client.storage.from(bucket).remove([path]);
  }
}
