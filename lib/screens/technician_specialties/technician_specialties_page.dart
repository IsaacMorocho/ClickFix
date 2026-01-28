import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class TechnicianSpecialtiesPage extends StatefulWidget {
  const TechnicianSpecialtiesPage({super.key});

  @override
  State<TechnicianSpecialtiesPage> createState() =>
      _TechnicianSpecialtiesPageState();
}

class _TechnicianSpecialtiesPageState extends State<TechnicianSpecialtiesPage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO
  // ========================================================================

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _availableSpecialties = [];
  List<String> _selectedSpecialtyIds = [];
  bool _isLoading = true;
  String? _technicianId;

  @override
  void initState() {
    super.initState();

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

    _loadData();
  }

  Future<void> _loadData() async {
    final userId = DatabaseService.currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Cargar todas las especialidades disponibles
      final specialties = await DatabaseService.getSpecialties();

      // Obtener el perfil del técnico
      final technicianProfile = await DatabaseService.getTechnicianProfile(
        userId,
      );

      if (technicianProfile != null) {
        _technicianId = technicianProfile['id'];

        // Cargar las especialidades seleccionadas del técnico
        final techSpecialties = await DatabaseService.getTechnicianSpecialties(
          _technicianId!,
        );
        final selectedIds = techSpecialties
            .map((s) => s['specialty_id'].toString())
            .toList();

        if (mounted) {
          setState(() {
            _availableSpecialties = specialties;
            _selectedSpecialtyIds = selectedIds;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _availableSpecialties = specialties;
            _isLoading = false;
          });
        }
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
    _slideController.dispose();
    super.dispose();
  }

  // ========================================================================
  // METODOS CRUD
  // ========================================================================

  void _toggleSpecialty(String specialtyId) {
    setState(() {
      if (_selectedSpecialtyIds.contains(specialtyId)) {
        _selectedSpecialtyIds.remove(specialtyId);
      } else {
        _selectedSpecialtyIds.add(specialtyId);
      }
    });
  }

  Future<void> _saveSpecialties() async {
    if (_selectedSpecialtyIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una especialidad'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_technicianId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se encontró el perfil de técnico'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await DatabaseService.updateTechnicianSpecialties(
        _technicianId!,
        _selectedSpecialtyIds,
      );

      // Recargar datos para reflejar cambios
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Especialidades guardadas correctamente'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar especialidades: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: _availableSpecialties.length,
                  itemBuilder: (context, index) {
                    return _buildSpecialtyCard(_availableSpecialties[index]);
                  },
                ),
              ),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Mis Especialidades',
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

  Widget _buildSpecialtyCard(Map<String, dynamic> specialty) {
    final isSelected = _selectedSpecialtyIds.contains(specialty['id']);

    return GestureDetector(
      onTap: () => _toggleSpecialty(specialty['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF555879).withOpacity(0.1)
              : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF555879)
                : const Color(0xFF98A1BC),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF555879).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF555879)
                    : const Color(0xFFDED3C4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getSpecialtyIcon(specialty['nombre']),
                color: isSelected ? Colors.white : const Color(0xFF555879),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    specialty['nombre'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF555879)
                          : const Color(0xFF555879).withOpacity(0.8),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialty['descripcion'],
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF98A1BC).withOpacity(0.9),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF555879)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF555879)
                      : const Color(0xFF98A1BC),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
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
      case 'aire acondicionado':
        return Icons.ac_unit;
      case 'electrodomesticos':
        return Icons.kitchen;
      default:
        return Icons.build;
    }
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF555879).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Text(
              '${_selectedSpecialtyIds.length} especialidad(es) seleccionada(s)',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF98A1BC),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSpecialties,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF555879),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  'Guardar Especialidades',
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
