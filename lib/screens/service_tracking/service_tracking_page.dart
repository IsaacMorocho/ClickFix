import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/animations/page_transitions.dart';
import '../../services/database_service.dart';
import '../../services/onesignal_service.dart';

/// Pantalla de seguimiento en tiempo real de un servicio
class ServiceTrackingPage extends StatefulWidget {
  final String serviceId;
  final String requestTitle; // Agregar este parámetro

  const ServiceTrackingPage({
    super.key,
    required this.serviceId,
    this.requestTitle = 'Servicio', // Valor por defecto
  });

  @override
  State<ServiceTrackingPage> createState() => _ServiceTrackingPageState();
}

class _ServiceTrackingPageState extends State<ServiceTrackingPage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _serviceData;
  String _currentStatus = 'cotizando';
  bool _isLoading = true;
  Position? _technicianLocation;

  // Controlador de animación para el timeline
  late AnimationController _timelineController;
  late Animation<double> _timelineAnimation;

  // Estados del servicio
  final List<Map<String, dynamic>> _serviceStates = [
    {
      'id': 'cotizando',
      'title': 'Cotizando',
      'icon': Icons.pending_actions,
      'color': const Color(0xFF3498DB),
      'description': 'Esperando cotizaciones de técnicos',
    },
    {
      'id': 'aceptado',
      'title': 'Aceptado',
      'icon': Icons.check_circle,
      'color': const Color(0xFF27AE60),
      'description': 'Cotización aceptada, esperando técnico',
    },
    {
      'id': 'en_camino',
      'title': 'En Camino',
      'icon': Icons.directions_car,
      'color': const Color(0xFFF39C12),
      'description': 'El técnico está en camino',
    },
    {
      'id': 'en_progreso',
      'title': 'En Progreso',
      'icon': Icons.build,
      'color': const Color(0xFF9B59B6),
      'description': 'El técnico está trabajando',
    },
    {
      'id': 'completado',
      'title': 'Completado',
      'icon': Icons.done_all,
      'color': const Color(0xFF16A085),
      'description': 'Servicio finalizado',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timelineController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _timelineAnimation = CurvedAnimation(
      parent: _timelineController,
      curve: Curves.easeOutCubic,
    );
    _timelineController.forward();
    _loadServiceData();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceData() async {
    try {
      // TODO: Cargar datos del servicio desde el backend
      final service = await DatabaseService.getServiceById(widget.serviceId);

      if (mounted) {
        setState(() {
          _serviceData = service;
          _currentStatus = service['estado'] ?? 'cotizando';
          _isLoading = false;
        });

        // Configurar listener de notificaciones para actualizaciones en tiempo real
        _setupNotificationListener();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar servicio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupNotificationListener() {
    // Escuchar actualizaciones de estado vía OneSignal
    // TODO: Implementar listener real cuando se conecte el backend
  }

  Future<void> _startLocationTracking() async {
    // Solo rastrear ubicación cuando el técnico está en camino
    if (_currentStatus != 'en_camino') return;

    try {
      // Verificar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      // TODO: Obtener ubicación del técnico desde el backend
      // En una implementación real, el técnico enviaría su ubicación periódicamente
    } catch (e) {
      debugPrint('Error rastreando ubicación: $e');
    }
  }

  int _getCurrentStateIndex() {
    return _serviceStates.indexWhere((state) => state['id'] == _currentStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EBD3),
      appBar: AppBar(
        title: const Text(
          'Seguimiento del Servicio',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF555879),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadServiceData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildServiceInfoCard(),
                    const SizedBox(height: 24),
                    _buildTimelineTracker(),
                    const SizedBox(height: 24),
                    _buildCurrentStatusCard(),
                    const SizedBox(height: 24),
                    if (_currentStatus == 'en_camino')
                      _buildTechnicianLocationCard(),
                    if (_currentStatus == 'completado') _buildRatingPrompt(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildServiceInfoCard() {
    return FadeScaleAnimation(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF555879), Color(0xFF98A1BC)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF555879).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Servicio',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      Text(
                        _serviceData?['categoria'] ?? 'Reparación',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white24),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.person,
              'Técnico',
              _serviceData?['tecnico_nombre'] ?? 'Por asignar',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_on,
              'Dirección',
              _serviceData?['direccion'] ?? 'No especificada',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.attach_money,
              'Monto',
              '\$${_serviceData?['monto_total']?.toStringAsFixed(2) ?? '0.00'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontFamily: 'Montserrat',
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTracker() {
    final currentIndex = _getCurrentStateIndex();

    return SlideFadeAnimation(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF98A1BC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progreso del Servicio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF555879),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(_serviceStates.length, (index) {
              final state = _serviceStates[index];
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return AnimatedBuilder(
                animation: _timelineAnimation,
                builder: (context, child) {
                  final opacity = isCompleted ? _timelineAnimation.value : 0.3;

                  return Opacity(
                    opacity: opacity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline visual
                        Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? state['color']
                                    : Colors.grey.shade300,
                                border: Border.all(
                                  color: isCurrent
                                      ? state['color']
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                state['icon'],
                                color: isCompleted ? Colors.white : Colors.grey,
                                size: 20,
                              ),
                            ),
                            if (index < _serviceStates.length - 1)
                              Container(
                                width: 2,
                                height: 50,
                                color: isCompleted
                                    ? state['color']
                                    : Colors.grey.shade300,
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Información del estado
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isCompleted
                                        ? const Color(0xFF555879)
                                        : Colors.grey,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state['description'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCompleted
                                        ? const Color(0xFF98A1BC)
                                        : Colors.grey.shade400,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                if (isCurrent)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: state['color'].withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Estado actual',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: state['color'],
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final currentState = _serviceStates.firstWhere(
      (state) => state['id'] == _currentStatus,
      orElse: () => _serviceStates[0],
    );

    return SlideFadeAnimation(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: currentState['color'].withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: currentState['color']),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: currentState['color'],
                shape: BoxShape.circle,
              ),
              child: Icon(currentState['icon'], color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentState['title'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: currentState['color'],
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusMessage(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF555879),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusMessage() {
    switch (_currentStatus) {
      case 'cotizando':
        return 'Los técnicos están revisando tu solicitud. Recibirás notificaciones cuando lleguen cotizaciones.';
      case 'aceptado':
        return 'Has aceptado una cotización. El técnico confirmará su disponibilidad pronto.';
      case 'en_camino':
        return 'El técnico está en camino a tu ubicación. Tiempo estimado de llegada: ${_serviceData?['eta'] ?? '15-30 minutos'}.';
      case 'en_progreso':
        return 'El técnico está trabajando en tu servicio. Te notificaremos cuando esté completado.';
      case 'completado':
        return '¡Servicio finalizado! Por favor califica tu experiencia.';
      default:
        return 'Estado desconocido';
    }
  }

  Widget _buildTechnicianLocationCard() {
    return SlideFadeAnimation(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF39C12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.location_on, color: Color(0xFFF39C12), size: 24),
                SizedBox(width: 8),
                Text(
                  'Ubicación del Técnico',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555879),
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFDED3C4).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF98A1BC)),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Color(0xFF98A1BC)),
                    SizedBox(height: 8),
                    Text(
                      'Mapa en tiempo real',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF98A1BC),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'TODO: Integrar Google Maps',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF98A1BC),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Distancia aproximada:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF98A1BC),
                    fontFamily: 'Montserrat',
                  ),
                ),
                Text(
                  '2.5 km',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555879),
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingPrompt() {
    return SlideFadeAnimation(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF27AE60), Color(0xFF16A085)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF27AE60).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.star, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            const Text(
              '¿Cómo fue tu experiencia?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu opinión nos ayuda a mejorar el servicio',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navegar a pantalla de calificación
                  Navigator.pushNamed(
                    context,
                    '/rateService',
                    arguments: {'serviceId': widget.serviceId},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF27AE60),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.rate_review),
                label: const Text(
                  'Calificar Servicio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
