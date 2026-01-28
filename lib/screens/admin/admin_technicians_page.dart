import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/database_service.dart';

class AdminTechniciansPage extends StatefulWidget {
  const AdminTechniciansPage({super.key});

  @override
  State<AdminTechniciansPage> createState() => _AdminTechniciansPageState();
}

class _AdminTechniciansPageState extends State<AdminTechniciansPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _technicians = [];
  String _selectedFilter = 'pendientes';
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
    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    try {
      final technicians = await DatabaseService.getAllTechnicians();
      
      if (mounted) {
        setState(() {
          _technicians = technicians.map((t) {
            final user = t['users'] as Map<String, dynamic>?;
            final specialties = t['technician_specialties'] as List<dynamic>? ?? [];
            final certificates = t['certificates'] as List<dynamic>? ?? [];
            return {
              ...t,
              'nombre': user?['nombre_completo'] ?? 'Sin nombre',
              'email': user?['email'] ?? '',
              'telefono': user?['telefono'] ?? '',
              'especialidades': specialties.map((s) => s['specialties']?['nombre'] ?? '').toList(),
              'anios_experiencia': t['anios_experiencia'] ?? 0,
              'verificado': t['verificado_por'] != null,
              'certificados': certificates.length,
              'created_at': t['created_at'] != null ? DateTime.parse(t['created_at']) : DateTime.now(),
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
            content: Text('Error al cargar técnicos: $e'),
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

  List<Map<String, dynamic>> get _filteredTechnicians {
    if (_selectedFilter == 'pendientes') {
      return _technicians.where((t) => t['verificado'] == false).toList();
    } else if (_selectedFilter == 'verificados') {
      return _technicians.where((t) => t['verificado'] == true).toList();
    }
    return _technicians;
  }

  void _verifyTechnician(Map<String, dynamic> technician) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFFF4EBD3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Verificar Tecnico',
        style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: Color(0xFF555879)),
      ),
      content: Text(
        'Deseas verificar a ${technician['nombre']}?',
        style: const TextStyle(fontFamily: 'Montserrat', color: Color(0xFF555879)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Color(0xFF98A1BC))),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              // Actualizar en Supabase
              final adminId = DatabaseService.currentUserId;
              if (adminId != null) {
                await DatabaseService.verifyTechnician(technician['id'], adminId);
              }
              
              // Enviar correo de aprobacion
              await Supabase.instance.client.functions.invoke(
                'send-technician-email',
                body: {
                  'email': technician['email'],
                  'nombre': technician['nombre'],
                  'tipo': 'aprobado',
                },
              );
              
              setState(() {
                technician['verificado'] = true;
              });
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tecnico verificado y notificado'),
                    backgroundColor: Color(0xFF27AE60),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60)),
          child: const Text('Verificar', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

  void _rejectTechnician(Map<String, dynamic> technician) {
  final motivoController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFFF4EBD3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Rechazar Tecnico',
        style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: Color(0xFF555879)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Deseas rechazar a ${technician['nombre']}?',
            style: const TextStyle(fontFamily: 'Montserrat', color: Color(0xFF555879)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: motivoController,
            decoration: const InputDecoration(
              labelText: 'Motivo del rechazo',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Color(0xFF98A1BC))),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              // Enviar correo de rechazo
              await Supabase.instance.client.functions.invoke(
                'send-technician-email',
                body: {
                  'email': technician['email'],
                  'nombre': technician['nombre'],
                  'tipo': 'rechazado',
                  'motivo': motivoController.text.isNotEmpty 
                      ? motivoController.text 
                      : 'Documentacion incompleta',
                },
              );
              
              setState(() {
                _technicians.remove(technician);
              });
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tecnico rechazado y notificado'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EBD3),
      appBar: AppBar(
        title: const Text(
          'Verificar Tecnicos',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF555879),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child: _filteredTechnicians.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredTechnicians.length,
                      itemBuilder: (context, index) => _buildTechnicianCard(_filteredTechnicians[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['pendientes', 'verificados', 'todos'];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter == 'pendientes' ? 'Pendientes' : filter == 'verificados' ? 'Verificados' : 'Todos',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF555879),
                  fontFamily: 'Montserrat',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.engineering, size: 80, color: const Color(0xFF98A1BC).withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'pendientes'
                ? 'No hay tecnicos pendientes'
                : 'No hay tecnicos verificados',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(Map<String, dynamic> technician) {
    final isVerified = technician['verificado'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified ? const Color(0xFF27AE60) : const Color(0xFFF39C12),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF555879),
                radius: 25,
                child: Text(
                  technician['nombre'].substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          technician['nombre'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF555879),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.verified, color: Color(0xFF27AE60), size: 18),
                        ],
                      ],
                    ),
                    Text(
                      technician['email'],
                      style: const TextStyle(fontSize: 12, color: Color(0xFF98A1BC)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFDED3C4)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(Icons.work, '${technician['anios_experiencia']} anos'),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.workspace_premium, '${technician['certificados']} cert.'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: (technician['especialidades'] as List).map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF555879).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                e,
                style: const TextStyle(fontSize: 11, color: Color(0xFF555879), fontFamily: 'Montserrat'),
              ),
            )).toList(),
          ),
          if (!isVerified) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectTechnician(technician),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _verifyTechnician(technician),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60)),
                    child: const Text('Verificar', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDED3C4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF555879)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF555879), fontFamily: 'Montserrat')),
        ],
      ),
    );
  }
}
