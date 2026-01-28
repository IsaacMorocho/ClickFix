import 'package:flutter/material.dart';
import '../service_request_detail/service_request_detail_page.dart';
import '../../services/database_service.dart';

class ServiceRequestsListPage extends StatefulWidget {
  const ServiceRequestsListPage({super.key});

  @override
  State<ServiceRequestsListPage> createState() =>
      _ServiceRequestsListPageState();
}

class _ServiceRequestsListPageState extends State<ServiceRequestsListPage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO
  // ========================================================================

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> serviceRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

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

    // Cargar datos de Supabase
    _loadServiceRequests();
  }

  Future<void> _loadServiceRequests() async {
    final userId = DatabaseService.currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final requests = await DatabaseService.getServiceRequests(clientId: userId);
      if (mounted) {
        setState(() {
          serviceRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar solicitudes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  /// Obtener color del estado
  Color _getStateColor(String estado) {
    switch (estado) {
      case 'solicitud':
        return const Color(0xFFF39C12); // Naranja
      case 'asignado':
        return const Color(0xFF3498DB); // Azul
      case 'completado':
        return const Color(0xFF27AE60); // Verde
      case 'cancelado':
        return const Color(0xFFE74C3C); // Rojo
      default:
        return const Color(0xFF95A5A6); // Gris
    }
  }

  /// Obtener icono del estado
  IconData _getStateIcon(String estado) {
    switch (estado) {
      case 'solicitud':
        return Icons.hourglass_bottom;
      case 'asignado':
        return Icons.assignment_ind;
      case 'completado':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  /// Obtener etiqueta de estado en español
  String _getStateLabel(String estado) {
    switch (estado) {
      case 'solicitud':
        return 'Solicitud';
      case 'asignado':
        return 'Asignado';
      case 'completado':
        return 'Completado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  /// Formatear fecha a formato relativo
  String _formatDate(dynamic dateValue) {
    DateTime date;
    if (dateValue is DateTime) {
      date = dateValue;
    } else if (dateValue is String) {
      date = DateTime.parse(dateValue);
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return 'Hace ${(difference.inDays / 7).ceil()}s';
    } else {
      return 'Hace ${(difference.inDays / 30).ceil()}m';
    }
  }

  /// Cancelar solicitud
  void _cancelServiceRequest(int index) {
    final requestId = serviceRequests[index]['id'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Cancelar Solicitud',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '¿Estás seguro de que deseas cancelar esta solicitud?',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DatabaseService.updateServiceRequestStatus(requestId, 'cancelado');
                setState(() {
                  serviceRequests[index]['estado'] = 'cancelado';
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solicitud cancelada'),
                      backgroundColor: Color(0xFF555879),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cancelar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  /// Ver detalle de la solicitud
  void _viewDetail(Map<String, dynamic> request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServiceRequestDetailPage(request: request),
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
          child: serviceRequests.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: serviceRequests.length,
                  itemBuilder: (context, index) {
                    return _buildRequestCard(serviceRequests[index], index);
                  },
                ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Mis Solicitudes',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      backgroundColor: const Color(0xFF555879),
      elevation: 4,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
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
            Icons.inbox,
            size: 80,
            color: const Color(0xFF98A1BC).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay solicitudes',
            style: TextStyle(
              fontSize: 18,
              color: const Color(0xFF555879).withOpacity(0.7),
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera solicitud de servicio',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF98A1BC).withOpacity(0.7),
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de solicitud
  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final stateColor = _getStateColor(request['estado']);
    final stateIcon = _getStateIcon(request['estado']);
    final stateLabel = _getStateLabel(request['estado']);
    final formattedDate = _formatDate(request['fecha']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF98A1BC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF555879).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado: Estado y Fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Estado
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: stateColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: stateColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(stateIcon, size: 14, color: stateColor),
                    const SizedBox(width: 6),
                    Text(
                      stateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: stateColor,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              // Fecha
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF98A1BC),
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Descripción
          Text(
            request['descripcion_problema'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          // Dirección
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF98A1BC)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  request['direccion'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF98A1BC),
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Separador
          Container(height: 1, color: const Color(0xFFDED3C4)),
          const SizedBox(height: 12),
          // Footer: Cotizaciones y Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cotizaciones
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: const Color(0xFF98A1BC),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${request['cotizaciones']} cotizacion${request['cotizaciones'] != 1 ? 'es' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF98A1BC),
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Botones de acción
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _viewDetail(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF555879),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Ver',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (request['estado'] != 'completado' &&
                      request['estado'] != 'cancelado')
                    ElevatedButton(
                      onPressed: () => _cancelServiceRequest(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE74C3C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
