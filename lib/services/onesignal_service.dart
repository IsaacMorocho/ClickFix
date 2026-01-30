import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static const String _appId = '5e951e24-852c-4bb4-a4b6-7801a21369b8';

  static Future<void> initialize() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    OneSignal.initialize(_appId);

    OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null) {
        _handleNotificationClick(data);
      }
    });
  }

  static void _handleNotificationClick(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final navigationKey = data['navigationKey'];

    switch (type) {
      case 'new_service_request':
        // Técnico: Nueva solicitud relevante basada en su especialidad
        if (navigationKey != null) {
          // Navigator.pushNamed(navigationKey.currentContext!, '/availableRequests');
        }
        break;
      case 'new_quote':
        // Cliente: Nueva cotización recibida
        if (navigationKey != null) {
          // Navigator.pushNamed(navigationKey.currentContext!, '/serviceRequests');
        }
        break;
      case 'quote_accepted':
        // Técnico: Cliente aceptó tu cotización
        if (navigationKey != null) {
          // Navigator.pushNamed(navigationKey.currentContext!, '/assignedServices');
        }
        break;
      case 'client_message':
        // Técnico: Mensaje del cliente
        final serviceId = data['service_id'];
        if (navigationKey != null && serviceId != null) {
          // Navigator.pushNamed(navigationKey.currentContext!, '/serviceTracking', arguments: {'serviceId': serviceId});
        }
        break;
      case 'technician_arrived':
        // Cliente: Técnico ha llegado
        break;
      case 'service_started':
        // Cliente: Servicio iniciado
        break;
      case 'service_completed':
        // Cliente/Técnico: Servicio completado
        break;
      case 'new_review':
        // Técnico: Nueva reseña recibida
        break;
      default:
        break;
    }
  }

  static Future<void> setUserId(String userId) async {
    await OneSignal.login(userId);
  }

  static Future<void> removeUserId() async {
    await OneSignal.logout();
  }

  static Future<void> setUserTags(Map<String, String> tags) async {
    for (var entry in tags.entries) {
      await OneSignal.User.addTagWithKey(entry.key, entry.value);
    }
  }

  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    // TODO: Implementar con el backend
    // Tipos de notificaciones:
    // - new_service_request: Nueva solicitud para técnico
    // - new_quote: Nueva cotización para cliente
    // - quote_accepted: Cotización aceptada
    // - client_message: Mensaje del cliente
    // - technician_arrived: Técnico ha llegado
    // - service_started: Servicio iniciado
    // - service_completed: Servicio completado
  }

  /// Enviar notificación cuando hay una nueva solicitud relevante para el técnico
  static Future<void> notifyNewServiceRequest({
    required String technicianId,
    required String serviceRequestId,
    required String serviceType,
  }) async {
    await sendNotificationToUser(
      userId: technicianId,
      title: '🔔 Nueva Solicitud Disponible',
      message: 'Hay una nueva solicitud de $serviceType en tu zona',
      data: {
        'type': 'new_service_request',
        'service_request_id': serviceRequestId,
      },
    );
  }

  /// Enviar notificación cuando el cliente acepta una cotización
  static Future<void> notifyQuoteAccepted({
    required String technicianId,
    required String serviceId,
    required String clientName,
  }) async {
    await sendNotificationToUser(
      userId: technicianId,
      title: '✅ Cotización Aceptada',
      message: '$clientName aceptó tu cotización. Prepárate para el servicio.',
      data: {'type': 'quote_accepted', 'service_id': serviceId},
    );
  }

  /// Enviar notificación cuando hay un mensaje del cliente
  static Future<void> notifyClientMessage({
    required String technicianId,
    required String serviceId,
    required String clientName,
    required String message,
  }) async {
    await sendNotificationToUser(
      userId: technicianId,
      title: '💬 Mensaje de $clientName',
      message: message,
      data: {'type': 'client_message', 'service_id': serviceId},
    );
  }
}
