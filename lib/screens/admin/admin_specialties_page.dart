import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class AdminSpecialtiesPage extends StatefulWidget {
  const AdminSpecialtiesPage({super.key});

  @override
  State<AdminSpecialtiesPage> createState() => _AdminSpecialtiesPageState();
}

class _AdminSpecialtiesPageState extends State<AdminSpecialtiesPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _specialties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    try {
      final specialties = await DatabaseService.getSpecialties();

      if (mounted) {
        setState(() {
          _specialties = specialties.map((s) {
            final technicianCount =
                s['technician_specialties'] as List<dynamic>? ?? [];
            return {...s, 'tecnicos': technicianCount.length};
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar especialidades: $e'),
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

  void _showAddEditDialog({Map<String, dynamic>? specialty}) {
    final nombreController = TextEditingController(
      text: specialty?['nombre'] ?? '',
    );
    final descripcionController = TextEditingController(
      text: specialty?['descripcion'] ?? '',
    );
    final isEditing = specialty != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF4EBD3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEditing ? 'Editar Especialidad' : 'Nueva Especialidad',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Color(0xFF555879),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre',
                labelStyle: const TextStyle(color: Color(0xFF98A1BC)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF98A1BC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF555879),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descripcionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Descripcion',
                labelStyle: const TextStyle(color: Color(0xFF98A1BC)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF98A1BC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF555879),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF98A1BC)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El nombre es requerido'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                if (isEditing) {
                  specialty!['nombre'] = nombreController.text;
                  specialty['descripcion'] = descripcionController.text;
                } else {
                  _specialties.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'nombre': nombreController.text,
                    'descripcion': descripcionController.text,
                    'tecnicos': 0,
                  });
                }
              });

              Navigator.pop(context);
              // TODO: Guardar en Supabase
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEditing
                        ? 'Especialidad actualizada'
                        : 'Especialidad creada',
                  ),
                  backgroundColor: const Color(0xFF27AE60),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF555879),
            ),
            child: Text(
              isEditing ? 'Guardar' : 'Crear',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteSpecialty(Map<String, dynamic> specialty) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF4EBD3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar Especialidad',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Color(0xFF555879),
          ),
        ),
        content: Text(
          'Deseas eliminar "${specialty['nombre']}"? Esta accion no se puede deshacer.',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            color: Color(0xFF555879),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF98A1BC)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _specialties.remove(specialty);
              });
              Navigator.pop(context);
              // TODO: Eliminar de Supabase
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Especialidad eliminada'),
                  backgroundColor: Color(0xFF98A1BC),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
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
          'Gestion de Especialidades',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF555879),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF555879),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva',
          style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _specialties.length,
          itemBuilder: (context, index) =>
              _buildSpecialtyCard(_specialties[index]),
        ),
      ),
    );
  }

  Widget _buildSpecialtyCard(Map<String, dynamic> specialty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF98A1BC)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFDED3C4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getSpecialtyIcon(specialty['nombre']),
              color: const Color(0xFF555879),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  specialty['nombre'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF555879),
                    fontFamily: 'Montserrat',
                  ),
                ),
                Text(
                  specialty['descripcion'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF98A1BC),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${specialty['tecnicos']} tecnicos',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF555879),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showAddEditDialog(specialty: specialty),
            icon: const Icon(Icons.edit, color: Color(0xFF555879)),
          ),
          IconButton(
            onPressed: () => _deleteSpecialty(specialty),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  IconData _getSpecialtyIcon(String nombre) {
    switch (nombre.toLowerCase()) {
      case 'plomeria':
        return Icons.plumbing;
      case 'electricidad':
        return Icons.electrical_services;
      case 'carpinteria':
        return Icons.carpenter;
      case 'pintura':
        return Icons.format_paint;
      case 'albanileria':
        return Icons.construction;
      case 'cerrajeria':
        return Icons.lock;
      default:
        return Icons.build;
    }
  }
}
