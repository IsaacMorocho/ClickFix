import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _requests = [];
  String _selectedFilter = 'todas';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final requests = await DatabaseService.getServiceRequests();
      
      if (mounted) {
        setState(() {
          _requests = requests.map((r) {
            final user = r['users'] as Map<String, dynamic>?;
            final quotes = r['quotes'] as List<dynamic>? ?? [];
            return {
              ...r,
              'descripcion': r['descripcion_problema'] ?? 'Sin descripción',
              'cliente': user?['nombre_completo'] ?? 'Cliente',
              'direccion': r['direccion'] ?? 'Sin dirección',
              'estado': r['estado'] ?? 'pendiente',
              'cotizaciones': quotes.length,
              'fecha': r['created_at'] != null ? DateTime.parse(r['created_at']) : DateTime.now(),
            };
          }).toList();
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
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_selectedFilter == 'todas') return _requests;
    return _requests.where((r) => r['estado'] == _selectedFilter).toList();
  }

  Color _getStateColor(String estado) {
    switch (estado) {
      case 'solicitud':
        return const Color(0xFFF39C12);
      case 'asignado':
        return const Color(0xFF3498DB);
      case 'completado':
        return const Color(0xFF27AE60);
      case 'cancelado':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF95A5A6);
    }
  }

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

  String _formatDate(DateTime date) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EBD3),
      appBar: AppBar(
        title: const Text(
          'Supervision de Solicitudes',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF555879),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildStats(),
            _buildFilterChips(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredRequests.length,
                itemBuilder: (context, index) => _buildRequestCard(_filteredRequests[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final solicitudes = _requests.where((r) => r['estado'] == 'solicitud').length;
    final asignados = _requests.where((r) => r['estado'] == 'asignado').length;
    final completados = _requests.where((r) => r['estado'] == 'completado').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF98A1BC)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Pendientes', solicitudes, const Color(0xFFF39C12)),
          Container(width: 1, height: 40, color: const Color(0xFFDED3C4)),
          _buildStatItem('Asignados', asignados, const Color(0xFF3498DB)),
          Container(width: 1, height: 40, color: const Color(0xFFDED3C4)),
          _buildStatItem('Completados', completados, const Color(0xFF27AE60)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Montserrat',
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF98A1BC), fontFamily: 'Montserrat'),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['todas', 'solicitud', 'asignado', 'completado', 'cancelado'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter == 'todas' ? 'Todas' : _getStateLabel(filter),
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF555879),
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF555879),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final stateColor = _getStateColor(request['estado']);
    final stateLabel = _getStateLabel(request['estado']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stateColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request['descripcion'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555879),
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: stateColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stateColor),
                ),
                child: Text(
                  stateLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: stateColor,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: Color(0xFF98A1BC)),
              const SizedBox(width: 4),
              Text(
                request['cliente'],
                style: const TextStyle(fontSize: 12, color: Color(0xFF98A1BC)),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today, size: 14, color: Color(0xFF98A1BC)),
              const SizedBox(width: 4),
              Text(
                _formatDate(request['fecha']),
                style: const TextStyle(fontSize: 12, color: Color(0xFF98A1BC)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFF98A1BC)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request['direccion'],
                  style: const TextStyle(fontSize: 12, color: Color(0xFF98A1BC)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${request['cotizaciones']} cotizaciones',
                style: const TextStyle(fontSize: 11, color: Color(0xFF555879), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
