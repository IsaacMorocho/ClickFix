import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO - DATOS DEL USUARIO
  // ========================================================================

  late TextEditingController _nombresController;
  late TextEditingController _telefonoController;

  bool _isEditing = false;
  bool _isLoading = true;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  late Map<String, dynamic> _originalData;
  late Map<String, dynamic> _currentData;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ========================================================================
  // INICIALIZACIÓN
  // ========================================================================

  @override
  void initState() {
    super.initState();

    // Inicializar con datos vacíos
    _originalData = {
      'id': '',
      'cedula': '',
      'nombres_completos': '',
      'email': '',
      'telefono': '',
      'rol': 'cliente',
      'foto_url': null,
      'estado': 'activo',
      'created_at': '',
    };

    _currentData = Map.from(_originalData);

    _nombresController = TextEditingController();
    _telefonoController = TextEditingController();

    // Animaciones
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

    // Cargar datos del usuario desde Supabase
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Obtener datos de la tabla users
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        _originalData = {
          'id': response['id'] ?? user.id,
          'cedula': response['cedula'] ?? '',
          'nombres_completos': response['nombre_completo'] ?? user.userMetadata?['nombre_completo'] ?? 'Usuario',
          'email': response['email'] ?? user.email ?? '',
          'telefono': response['telefono'] ?? '',
          'rol': response['rol'] ?? 'cliente',
          'foto_url': response['avatar_url'],
          'estado': response['estado'] ?? 'activo',
          'created_at': response['created_at'] ?? '',
        };
      } else {
        // Si no hay datos en la tabla users, usar los metadatos de auth
        _originalData = {
          'id': user.id,
          'cedula': user.userMetadata?['cedula'] ?? '',
          'nombres_completos': user.userMetadata?['nombre_completo'] ?? 'Usuario',
          'email': user.email ?? '',
          'telefono': user.userMetadata?['telefono'] ?? '',
          'rol': user.userMetadata?['rol'] ?? 'cliente',
          'foto_url': null,
          'estado': 'activo',
          'created_at': user.createdAt,
        };
      }

      _currentData = Map.from(_originalData);
      _nombresController.text = _currentData['nombres_completos'] ?? '';
      _telefonoController.text = _currentData['telefono'] ?? '';

    } catch (e) {
      // En caso de error, usar datos de auth como fallback
      _originalData = {
        'id': user.id,
        'cedula': user.userMetadata?['cedula'] ?? '',
        'nombres_completos': user.userMetadata?['nombre_completo'] ?? 'Usuario',
        'email': user.email ?? '',
        'telefono': user.userMetadata?['telefono'] ?? '',
        'rol': user.userMetadata?['rol'] ?? 'cliente',
        'foto_url': null,
        'estado': 'activo',
        'created_at': user.createdAt,
      };
      _currentData = Map.from(_originalData);
      _nombresController.text = _currentData['nombres_completos'] ?? '';
      _telefonoController.text = _currentData['telefono'] ?? '';
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward();
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _telefonoController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ========================================================================
  // MÉTODOS CRUD - OPERACIONES DE FOTO
  // ========================================================================

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========================================================================
  // MÉTODOS CRUD - GESTIÓN DE EDICIÓN
  // ========================================================================

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _selectedImage = null;
      _currentData = Map.from(_originalData);
      _nombresController.text = _originalData['nombres_completos'];
      _telefonoController.text = _originalData['telefono'];
    });
  }

  void _saveChanges() {
    // Validaciones
    if (_nombresController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre no puede estar vacío'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_telefonoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El teléfono no puede estar vacío'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Actualizar datos
    _currentData['nombres_completos'] = _nombresController.text.trim();
    _currentData['telefono'] = _telefonoController.text.trim();

    // TODO: Guardar en Supabase
    // 1. Actualizar tabla 'users' con nuevos nombres y teléfono
    // 2. Si hay foto seleccionada (_selectedImage), subirla a Storage:
    //    - Bucket: user_profiles
    //    - Ruta: $userId/profile.jpg
    //    - Actualizar campo foto_url en tabla users
    // Ejemplo:
    // final bytes = await _selectedImage!.readAsBytes();
    // await supabase.storage.from('user_profiles').uploadBinary(
    //   '${_currentData['id']}/profile.jpg',
    //   bytes,
    //   fileOptions: const FileOptions(upsert: true),
    // );
    // await supabase.from('users').update({
    //   'nombres_completos': _currentData['nombres_completos'],
    //   'telefono': _currentData['telefono'],
    //   'foto_url': urlDesdeStorage,
    // }).eq('id', _currentData['id']);

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil actualizado correctamente'),
        backgroundColor: Color(0xFF555879),
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF555879)),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      _buildProfilePhotoSection(),
                      const SizedBox(height: 32),
                      _buildPersonalDataSection(),
                      const SizedBox(height: 24),
                      _buildStateSection(),
                      const SizedBox(height: 24),
                      _buildReadOnlyFieldsSection(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: _isEditing
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.pop(context),
              backgroundColor: const Color(0xFF555879),
              child: const Icon(Icons.arrow_back),
            ),
    );
  }

  // ========================================================================
  // WIDGETS DE CONSTRUCCIÓN
  // ========================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Mi Perfil',
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

  Widget _buildProfilePhotoSection() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF555879), Color(0xFF98A1BC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF555879).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : null,
              child: _selectedImage == null
                  ? const Icon(Icons.person, size: 70, color: Color(0xFF98A1BC))
                  : null,
            ),
          ),
          if (_isEditing)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'gallery') {
                  _pickImage();
                } else if (value == 'camera') {
                  _takePhoto();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'gallery',
                  child: Row(
                    children: [
                      Icon(Icons.image, color: Color(0xFF555879)),
                      SizedBox(width: 8),
                      Text('Galería'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'camera',
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt, color: Color(0xFF555879)),
                      SizedBox(width: 8),
                      Text('Cámara'),
                    ],
                  ),
                ),
              ],
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFDED3C4),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF555879),
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalDataSection() {
    return _buildSectionContainer(
      icon: Icons.person,
      title: 'Datos Personales',
      content: _isEditing
          ? Column(
              children: [
                _buildEditableTextField(
                  label: 'Nombres Completos',
                  controller: _nombresController,
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildEditableTextField(
                  label: 'Teléfono',
                  controller: _telefonoController,
                  icon: Icons.phone,
                ),
              ],
            )
          : Column(
              children: [
                _buildInfoField(
                  'Nombres Completos',
                  _currentData['nombres_completos'],
                ),
                const SizedBox(height: 12),
                _buildInfoField('Teléfono', _currentData['telefono']),
                const SizedBox(height: 12),
                _buildInfoField('Email', _currentData['email']),
                const SizedBox(height: 12),
                _buildInfoField('Cédula', _currentData['cedula']),
              ],
            ),
    );
  }

  Widget _buildStateSection() {
    final estado = _currentData['estado'].toString().toUpperCase();
    final Color stateColor = _getStateColor(_currentData['estado']);

    return _buildSectionContainer(
      icon: Icons.verified_user,
      title: 'Estado del Perfil',
      content: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: stateColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stateColor, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              _getStateIcon(_currentData['estado']),
              color: stateColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              estado,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: stateColor,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyFieldsSection() {
    return _buildSectionContainer(
      icon: Icons.info_outline,
      title: 'Información del Sistema',
      content: Column(
        children: [
          _buildInfoField('Rol', _currentData['rol'].toUpperCase()),
          const SizedBox(height: 12),
          _buildInfoField('ID', _currentData['id']),
          const SizedBox(height: 12),
          _buildInfoField(
            'Fecha de Registro',
            _formatDate(_currentData['created_at']),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (!_isEditing)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startEditing,
              icon: const Icon(Icons.edit),
              label: const Text('Editar Perfil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF555879),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (_isEditing) const SizedBox(width: 12),
        if (_isEditing)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _cancelEditing,
              icon: const Icon(Icons.close),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF555879),
                side: const BorderSide(color: Color(0xFF555879), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
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

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF98A1BC),
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF555879),
            fontWeight: FontWeight.w500,
            fontFamily: 'Montserrat',
          ),
        ),
      ],
    );
  }

  Widget _buildEditableTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF98A1BC)),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF98A1BC), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF555879), width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 16,
        color: Color(0xFF555879),
      ),
    );
  }

  // ========================================================================
  // FUNCIONES AUXILIARES
  // ========================================================================

  Color _getStateColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'rechazado':
        return Colors.red;
      case 'inactivo':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStateIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return Icons.check_circle;
      case 'pendiente':
        return Icons.schedule;
      case 'rechazado':
        return Icons.cancel;
      case 'inactivo':
        return Icons.lock;
      default:
        return Icons.info;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
