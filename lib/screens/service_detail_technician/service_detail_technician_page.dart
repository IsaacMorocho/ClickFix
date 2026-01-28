import 'package:flutter/material.dart';

class ServiceDetailTechnicianPage extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceDetailTechnicianPage({super.key, required this.service});

  @override
  State<ServiceDetailTechnicianPage> createState() => _ServiceDetailTechnicianPageState();
}

class _ServiceDetailTechnicianPageState extends State<ServiceDetailTechnicianPage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO
  // ========================================================================

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();

    _currentStatus = widget.service['estado'] ?? 'pendiente';

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
  // METODOS CRUD
  // ========================================================================

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    // TODO: Actualizar en Supabase
    // await supabase.from('services')
    //   .update({'estado': newStatus})
    //   .eq('id', widget.service['id']);
    //
    // TODO: Enviar notificacion push al cliente
    // await sendPushNotification(
    //   userId: widget.service['cliente_id'],
    //   title: 'Estado del servicio actualizado',
    //   body: 'Tu servicio ahora esta: $newStatus',
    // );

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _currentStatus = newStatus;
      _isUpdating = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a: ${_getStateLabel(newStatus)}'),
          backgroundColor: const Color(0xFF27AE60),
        ),
      );
    }
  }

  void _callClient() {
    // TODO: Implementar llamada telefonica
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Llamando a ${widget.service['cliente_telefono']}...'),
        backgroundColor: const Color(0xFF555879),
      ),
    );
  }

  // ========================================================================
  // METODOS AUXILIARES
  // ========================================================================

  String _formatDate(DateTime date) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatMoney(int amount) {
    return '\$${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }

  Color _getStateColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFF39C12);
      case 'en_camino':
        return const Color(0xFF9B59B6);
      case 'en_progreso':
        return const Color(0xFF3498DB);
      case 'completado':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String _getStateLabel(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_camino':
        return 'En Camino';
      case 'en_progreso':
        return 'En Progreso';
      case 'completado':
        return 'Completado';
      default:
        return estado;
    }
  }

  IconData _getStateIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.schedule;
      case 'en_camino':
        return Icons.directions_car;
      case 'en_progreso':
        return Icons.build;
      case 'completado':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                _buildStatusSection(),
                const SizedBox(height: 20),
                _buildClientSection(),
                const SizedBox(height: 20),
                _buildServiceInfoSection(),
                const SizedBox(height: 20),
                _buildLocationSection(),
                const SizedBox(height: 24),
                if (_currentStatus != 'completado') _buildActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Detalle del Servicio',
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

  Widget _buildStatusSection() {
    final stateColor = _getStateColor(_currentStatus);
    final stateLabel = _getStateLabel(_currentStatus);
    final stateIcon = _getStateIcon(_currentStatus);

    return _buildSectionContainer(
      icon: Icons.info,
      title: 'Estado Actual',
      content: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: stateColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: stateColor, width: 2),
          ),
          child: Column(
            children: [
              Icon(stateIcon, size: 48, color: stateColor),
              const SizedBox(height: 12),
              Text(
                stateLabel,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: stateColor,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientSection() {
    return _buildSectionContainer(
      icon: Icons.person,
      title: 'Informacion del Cliente',
      content: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF555879), width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    widget.service['cliente_foto'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 30, color: Color(0xFF555879));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service['cliente_nombre'] ?? 'Cliente',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF555879),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Color(0xFF98A1BC)),
                        const SizedBox(width: 4),
                        Text(
                          widget.service['cliente_telefono'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF98A1BC),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _callClient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.call, size: 16),
                label: const Text(
                  'Llamar',
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
    );
  }

  Widget _buildServiceInfoSection() {
    return _buildSectionContainer(
      icon: Icons.description,
      title: 'Detalles del Servicio',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.service['descripcion'] ?? 'Descripcion del servicio',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFDED3C4)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fecha programada',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF98A1BC),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(widget.service['fecha_programada'] ?? DateTime.now()),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF555879),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Monto acordado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF98A1BC),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMoney(widget.service['monto'] ?? 0),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF555879),
                      fontFamily: 'Montserrat',
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

  Widget _buildLocationSection() {
    return _buildSectionContainer(
      icon: Icons.location_on,
      title: 'Ubicacion',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.service['direccion'] ?? 'Direccion',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Abrir en Google Maps
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Abriendo en Google Maps...'),
                    backgroundColor: Color(0xFF555879),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF555879),
                side: const BorderSide(color: Color(0xFF555879), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.map),
              label: const Text(
                'Ver en Mapa',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_currentStatus == 'pendiente')
          _buildActionButton(
            label: 'Estoy en Camino',
            icon: Icons.directions_car,
            color: const Color(0xFF9B59B6),
            onPressed: () => _updateStatus('en_camino'),
          ),
        if (_currentStatus == 'en_camino')
          _buildActionButton(
            label: 'Iniciar Trabajo',
            icon: Icons.build,
            color: const Color(0xFF3498DB),
            onPressed: () => _updateStatus('en_progreso'),
          ),
        if (_currentStatus == 'en_progreso')
          _buildActionButton(
            label: 'Marcar como Completado',
            icon: Icons.check_circle,
            color: const Color(0xFF27AE60),
            onPressed: () => _updateStatus('completado'),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isUpdating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon),
        label: Text(
          _isUpdating ? 'Actualizando...' : label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF98A1BC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF555879).withOpacity(0.08),
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
              Icon(icon, color: const Color(0xFF555879), size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}
