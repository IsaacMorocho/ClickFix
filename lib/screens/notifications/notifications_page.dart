import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO
  // ========================================================================

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Lista de notificaciones de ejemplo (será reemplazada por datos de Supabase)
  late List<Map<String, dynamic>> _notifications;
  late List<Map<String, dynamic>> _originalNotifications;

  // ========================================================================
  // INICIALIZACIÓN
  // ========================================================================

  @override
  void initState() {
    super.initState();

    // Datos de ejemplo - tabla notifications
    _originalNotifications = [
      {
        'id': '1',
        'user_id': '550e8400-e29b-41d4-a716-446655440000',
        'titulo': 'Servicio Completado',
        'mensaje':
            'Tu servicio de reparación de electrodomésticos ha sido completado exitosamente.',
        'leido': false,
        'tipo': 'servicio',
        'related_id': 'srv-001',
        'created_at': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'id': '2',
        'user_id': '550e8400-e29b-41d4-a716-446655440000',
        'titulo': 'Nueva Cotización Disponible',
        'mensaje':
            'El técnico ha enviado una cotización para tu solicitud de reparación.',
        'leido': false,
        'tipo': 'cotizacion',
        'related_id': 'cot-045',
        'created_at': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'id': '3',
        'user_id': '550e8400-e29b-41d4-a716-446655440000',
        'titulo': 'Técnico Asignado',
        'mensaje': 'Se ha asignado un técnico profesional a tu solicitud.',
        'leido': true,
        'tipo': 'servicio',
        'related_id': 'srv-002',
        'created_at': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'id': '4',
        'user_id': '550e8400-e29b-41d4-a716-446655440000',
        'titulo': 'Solicitud Cancelada',
        'mensaje': 'Tu solicitud de servicio ha sido cancelada por el usuario.',
        'leido': true,
        'tipo': 'servicio',
        'related_id': 'srv-003',
        'created_at': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': '5',
        'user_id': '550e8400-e29b-41d4-a716-446655440000',
        'titulo': 'Cotización Aceptada',
        'mensaje':
            'Felicidades, la cotización ha sido aceptada. El trabajo comenzará pronto.',
        'leido': true,
        'tipo': 'cotizacion',
        'related_id': 'cot-044',
        'created_at': DateTime.now().subtract(const Duration(days: 3)),
      },
    ];

    _notifications = List.from(_originalNotifications);

    // Configurar animaciones
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ========================================================================
  // MÉTODOS CRUD
  // ========================================================================

  /// Marcar notificación como leída
  void _markAsRead(int index) {
    setState(() {
      _notifications[index]['leido'] = true;
    });

    // TODO: Actualizar en Supabase
    // await supabase
    //   .from('notifications')
    //   .update({'leido': true})
    //   .eq('id', _notifications[index]['id']);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificación marcada como leída'),
        backgroundColor: Color(0xFF555879),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Marcar todas como leídas
  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['leido'] = true;
      }
    });

    // TODO: Actualizar en Supabase
    // await supabase
    //   .from('notifications')
    //   .update({'leido': true})
    //   .neq('leido', true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todas las notificaciones marcadas como leídas'),
        backgroundColor: Color(0xFF555879),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Navegar al evento relacionado
  void _navigateToRelated(Map<String, dynamic> notification) {
    final tipo = notification['tipo'];
    final relatedId = notification['related_id'];

    // TODO: Implementar navegación real
    // switch (tipo) {
    //   case 'servicio':
    //     Navigator.pushNamed(context, '/serviceDetail', arguments: relatedId);
    //   case 'cotizacion':
    //     Navigator.pushNamed(context, '/quotationDetail', arguments: relatedId);
    //   default:
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('Tipo de notificación desconocido')),
    //     );
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando a ${tipo.toUpperCase()}: $relatedId'),
        backgroundColor: const Color(0xFF98A1BC),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ========================================================================
  // CONSTRUIR INTERFAZ
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EBD3),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
        ),
      ),
    );
  }

  // ========================================================================
  // WIDGETS DE CONSTRUCCIÓN
  // ========================================================================

  PreferredSizeWidget _buildAppBar() {
    final unreadCount = _notifications.where((n) => n['leido'] == false).length;

    return AppBar(
      title: const Text(
        'Notificaciones',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      backgroundColor: const Color(0xFF555879),
      elevation: 4,
      centerTitle: true,
      actions: [
        if (unreadCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Lista de notificaciones
  Widget _buildNotificationsList() {
    return Column(
      children: [
        // Botón "Marcar todas como leídas"
        if (_notifications.any((n) => n['leido'] == false)) ...[
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: GestureDetector(
              onTap: _markAllAsRead,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF98A1BC),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF555879),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Marcar todas como leídas',
                      style: TextStyle(
                        color: Color(0xFF555879),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        // Lista de notificaciones
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(index);
            },
          ),
        ),
      ],
    );
  }

  /// Card de notificación individual
  Widget _buildNotificationCard(int index) {
    final notification = _notifications[index];
    final isRead = notification['leido'] as bool;
    final createdAt = notification['created_at'] as DateTime;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white.withOpacity(0.5)
              : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? const Color(0xFFDED3C4) : const Color(0xFF98A1BC),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF555879).withOpacity(isRead ? 0.04 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Título + indicador leído
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador de leído
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRead
                          ? const Color(0xFFDED3C4)
                          : const Color(0xFF555879),
                      boxShadow: [
                        if (!isRead)
                          BoxShadow(
                            color: const Color(0xFF555879).withOpacity(0.3),
                            blurRadius: 4,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Título
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['titulo'] ?? 'Sin título',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF555879),
                            fontFamily: 'Montserrat',
                            decoration: isRead ? TextDecoration.none : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Fecha
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF98A1BC),
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de tipo
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(
                        notification['tipo'],
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getTypeColor(notification['tipo']),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getTypeLabel(notification['tipo']),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getTypeColor(notification['tipo']),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Mensaje
              Text(
                notification['mensaje'] ?? 'Sin mensaje',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF555879),
                  fontFamily: 'Montserrat',
                  height: 1.5,
                  fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // Botones de acción
              Row(
                children: [
                  if (!isRead)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _markAsRead(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF555879).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF555879),
                              width: 1.5,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check,
                                color: Color(0xFF555879),
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Marcar leída',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF555879),
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (!isRead) const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToRelated(notification),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF98A1BC).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF98A1BC),
                            width: 1.5,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF98A1BC),
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Ver detalles',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF98A1BC),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Estado vacío
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: const Color(0xFF98A1BC).withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'No hay notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aquí aparecerán tus notificaciones',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF98A1BC),
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // FUNCIONES AUXILIARES
  // ========================================================================

  /// Formatear fecha
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Obtener color según tipo
  Color _getTypeColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'servicio':
        return Colors.blue;
      case 'cotizacion':
        return Colors.orange;
      default:
        return const Color(0xFF555879);
    }
  }

  /// Obtener etiqueta según tipo
  String _getTypeLabel(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'servicio':
        return 'SERVICIO';
      case 'cotizacion':
        return 'COTIZACIÓN';
      default:
        return 'OTRO';
    }
  }
}
