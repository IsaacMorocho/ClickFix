import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';

/// Historial de trabajos del técnico con estadísticas de progreso
class TechnicianWorkHistoryPage extends StatefulWidget {
  const TechnicianWorkHistoryPage({super.key});

  @override
  State<TechnicianWorkHistoryPage> createState() =>
      _TechnicianWorkHistoryPageState();
}

class _TechnicianWorkHistoryPageState extends State<TechnicianWorkHistoryPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _completedServices = [];

  // Estadísticas
  int _totalServices = 0;
  double _totalEarnings = 0;
  int _uniqueClients = 0;
  double _averageRating = 0;

  late AnimationController _statsAnimController;
  late Animation<double> _statsAnimation;

  @override
  void initState() {
    super.initState();
    _statsAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _statsAnimation = CurvedAnimation(
      parent: _statsAnimController,
      curve: Curves.easeOutCubic,
    );
    _loadWorkHistory();
  }

  @override
  void dispose() {
    _statsAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkHistory() async {
    setState(() => _isLoading = true);

    try {
      final technicianId = DatabaseService.currentUserId;
      if (technicianId == null) return;

      // Obtener servicios completados del técnico
      final services = await DatabaseService.getTechnicianCompletedServices(
        technicianId,
      );

      // Calcular estadísticas
      final clientIds = <String>{};
      double totalRating = 0;
      int ratedServices = 0;

      for (var service in services) {
        _totalEarnings += (service['monto'] ?? 0).toDouble();

        final clientId = service['client_id'] as String?;
        if (clientId != null) clientIds.add(clientId);

        final rating = service['calificacion_cliente'] as double?;
        if (rating != null) {
          totalRating += rating;
          ratedServices++;
        }
      }

      setState(() {
        _completedServices = services;
        _totalServices = services.length;
        _uniqueClients = clientIds.length;
        _averageRating = ratedServices > 0 ? totalRating / ratedServices : 0;
        _isLoading = false;
      });

      _statsAnimController.forward();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar historial: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Mi Historial de Trabajos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkHistory,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWorkHistory,
              child: CustomScrollView(
                slivers: [
                  // Estadísticas principales
                  SliverToBoxAdapter(child: _buildStatsSection()),

                  // Gráfico de progreso
                  SliverToBoxAdapter(child: _buildProgressChart()),

                  // Lista de trabajos
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: _completedServices.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmptyState())
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return _buildServiceCard(
                                _completedServices[index],
                              );
                            }, childCount: _completedServices.length),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Tu Progreso Profesional',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.check_circle,
                  _totalServices.toString(),
                  'Servicios\nCompletados',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.people,
                  _uniqueClients.toString(),
                  'Clientes\nAtendidos',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.attach_money,
                  NumberFormat.currency(
                    symbol: '\$',
                    decimalDigits: 0,
                  ).format(_totalEarnings),
                  'Ganancias\nTotales',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.star,
                  _averageRating.toStringAsFixed(1),
                  'Calificación\nPromedio',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _statsAnimation.value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    if (_totalServices == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas del Mes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            'Servicios Completados',
            _totalServices,
            100,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildProgressBar('Clientes Nuevos', _uniqueClients, 50, Colors.blue),
          const SizedBox(height: 12),
          _buildProgressBar(
            'Calificación',
            (_averageRating * 20).round(),
            100,
            Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int max, Color color) {
    final percentage = (value / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            Text(
              '$value / $max',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final fecha = service['fecha_completado'] != null
        ? DateTime.parse(service['fecha_completado'])
        : DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completado',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy').format(fecha),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Cliente
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF6C63FF),
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['cliente_nombre'] ?? 'Cliente',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        service['direccion'] ?? 'Sin dirección',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Descripción
            Text(
              service['descripcion'] ?? 'Sin descripción',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Calificación
                if (service['calificacion_cliente'] != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        service['calificacion_cliente'].toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Sin calificar',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),

                // Monto ganado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        color: Colors.green,
                        size: 18,
                      ),
                      Text(
                        NumberFormat.currency(
                          symbol: '',
                          decimalDigits: 0,
                        ).format(service['monto'] ?? 0),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay trabajos completados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa tu primer servicio para ver tu progreso',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
