import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class AdminServicesPage extends StatefulWidget {
  const AdminServicesPage({super.key});

  @override
  State<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends State<AdminServicesPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _services = [];
  String _selectedFilter = 'todos';
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
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final services = await DatabaseService.getServices();
      
      if (mounted) {
        setState(() {
          _services = services.map((s) {
            final serviceRequest = s['service_requests'] as Map<String, dynamic>?;
            final cliente = serviceRequest?['users'] as Map<String, dynamic>?;
            final technician = s['technicians'] as Map<String, dynamic>?;
            final techUser = technician?['users'] as Map<String, dynamic>?;
            final quote = s['quotes'] as Map<String, dynamic>?;
            return {
              ...s,
              'descripcion': serviceRequest?['descripcion_problema'] ?? 'Sin descripción',
              'cliente': cliente?['nombre_completo'] ?? 'Cliente',
              'tecnico': techUser?['nombre_completo'] ?? 'Técnico',
              'monto': quote?['monto'] ?? 0,
              'estado': s['estado'] ?? 'pendiente',
              'fecha': s['created_at'] != null ? DateTime.parse(s['created_at']) : DateTime.now(),
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
            content: Text('Error al cargar servicios: $e'),
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

  List<Map<String, dynamic>> get _filteredServices {
    if (_selectedFilter == 'todos') return _services;
    return _services.where((s) => s['estado'] == _selectedFilter).toList();
  }

  Color _getStateColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFF39C12);
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
      case 'en_progreso':
        return 'En Progreso';
      case 'completado':
        return 'Completado';
      default:
        return estado;
    }
  }

  String _formatMoney(int amount) {
    return '\$${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
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
          'Supervision de Servicios',
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
                itemCount: _filteredServices.length,
                itemBuilder: (context, index) => _buildServiceCard(_filteredServices[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final pendientes = _services.where((s) => s['estado'] == 'pendiente').length;
    final enProgreso = _services.where((s) => s['estado'] == 'en_progreso').length;
    final completados = _services.where((s) => s['estado'] == 'completado').length;
    final totalIngresos = _services
        .where((s) => s['estado'] == 'completado')
        .fold<int>(0, (sum, s) => sum + (s['monto'] as int));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF98A1BC)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Pendientes', pendientes.toString(), const Color(0xFFF39C12)),
              Container(width: 1, height: 40, color: const Color(0xFFDED3C4)),
              _buildStatItem('En Progreso', enProgreso.toString(), const Color(0xFF3498DB)),
              Container(width: 1, height: 40, color: const Color(0xFFDED3C4)),
              _buildStatItem('Completados', completados.toString(), const Color(0xFF27AE60)),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFDED3C4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.attach_money, color: Color(0xFF27AE60)),
              const SizedBox(width: 8),
              Text(
                'Ingresos completados: ${_formatMoney(totalIngresos)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF27AE60),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
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
    final filters = ['todos', 'pendiente', 'en_progreso', 'completado'];
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
                filter == 'todos' ? 'Todos' : _getStateLabel(filter),
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

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final stateColor = _getStateColor(service['estado']);
    final stateLabel = _getStateLabel(service['estado']);

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
                  service['descripcion'],
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Color(0xFF98A1BC)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Cliente: ${service['cliente']}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF98A1BC)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.engineering, size: 14, color: Color(0xFF98A1BC)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Tecnico: ${service['tecnico']}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF98A1BC)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFFDED3C4)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Color(0xFF98A1BC)),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(service['fecha']),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF98A1BC)),
                  ),
                ],
              ),
              Text(
                _formatMoney(service['monto']),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
