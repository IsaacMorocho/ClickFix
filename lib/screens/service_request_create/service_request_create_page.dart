import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/animations/page_transitions.dart';
import '../../services/database_service.dart';

class ServiceRequestCreatePage extends StatefulWidget {
  const ServiceRequestCreatePage({super.key});

  @override
  State<ServiceRequestCreatePage> createState() =>
      _ServiceRequestCreatePageState();
}

class _ServiceRequestCreatePageState extends State<ServiceRequestCreatePage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO
  // ========================================================================

  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _budgetController;

  String? _selectedCategory;
  File? _selectedImage;
  bool _isLoadingLocation = false;
  bool _needsCheckup = false;
  double? _currentLatitude;
  double? _currentLongitude;
  String? _currentAddress;

  final ImagePicker _picker = ImagePicker();

  // Categorías disponibles - Servicios Técnicos en Informática y Computadoras
  final List<Map<String, dynamic>> _categories = [
    {'id': 'reparacion_pc', 'name': 'Reparación de PC', 'icon': Icons.computer},
    {
      'id': 'reparacion_laptop',
      'name': 'Reparación de Laptop',
      'icon': Icons.laptop,
    },
    {
      'id': 'mantenimiento',
      'name': 'Mantenimiento Preventivo',
      'icon': Icons.build_circle,
    },
    {
      'id': 'instalacion_software',
      'name': 'Instalación de Software',
      'icon': Icons.apps,
    },
    {'id': 'redes', 'name': 'Redes y Conectividad', 'icon': Icons.lan},
    {
      'id': 'recuperacion_datos',
      'name': 'Recuperación de Datos',
      'icon': Icons.settings_backup_restore,
    },
    {
      'id': 'actualizacion_hardware',
      'name': 'Actualización de Hardware',
      'icon': Icons.memory,
    },
    {
      'id': 'soporte_tecnico',
      'name': 'Soporte Técnico General',
      'icon': Icons.support_agent,
    },
  ];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Precio base mínimo
  static const double minBudget = 10.0;
  static const double checkupFee = 5.0;
  static const double ivaRate = 0.15;

  // ========================================================================
  // INICIALIZACIÓN
  // ========================================================================

  @override
  void initState() {
    super.initState();

    // Inicializar controladores de texto
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();
    _budgetController = TextEditingController(
      text: minBudget.toStringAsFixed(2),
    );

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
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _budgetController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ========================================================================
  // MÉTODOS CRUD
  // ========================================================================

  /// Obtener ubicación GPS real
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente');
      }

      // Obtener posición actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Obtener dirección desde coordenadas
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = 'Ubicación obtenida';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address =
            '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
      }

      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
        _currentAddress = address;
        if (_addressController.text.isEmpty) {
          _addressController.text = address;
        }
        _isLoadingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Ubicación obtenida exitosamente'),
            backgroundColor: Color(0xFF27AE60),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Seleccionar imagen desde galería
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
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

  /// Tomar foto con cámara
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
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
            content: Text('Error al tomar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mostrar opciones de imagen
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF555879),
              ),
              title: const Text(
                'Galería',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF555879)),
              title: const Text(
                'Cámara',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Eliminar',
                  style: TextStyle(fontFamily: 'Montserrat'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedImage = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Mostrar información de términos y condiciones
  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Información Importante',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Color(0xFF555879),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTermItem(
                '💰 Precios',
                'Los precios exhibidos incluyen IVA vigente (15%). La plataforma factura la comisión.',
              ),
              const SizedBox(height: 16),
              _buildTermItem(
                '🔍 Chequeo (\$5)',
                'Si desconoce la falla, puede solicitar un chequeo por \$5, pagado por adelantado.',
              ),
              const SizedBox(height: 16),
              _buildTermItem(
                '⏱️ Cancelaciones',
                '• 0-10 min: reembolso 100%\n'
                    '• Hasta 2h antes de la cita: retención 20%\n'
                    '• Menos de 2h antes: retención 50%\n'
                    '• Si el Técnico llegó: no reembolsable',
              ),
              const SizedBox(height: 16),
              _buildTermItem(
                '💳 Pago',
                'El pago se libera después de la confirmación del Cliente, o automáticamente tras 24 horas sin reclamo.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                color: Color(0xFF555879),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF555879),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Color(0xFF98A1BC),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// Crear solicitud de servicio
  Future<void> _createServiceRequest() async {
    // Validar categoría
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una categoría'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar descripción
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor describe el problema'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar dirección
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa la dirección'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar ubicación
    if (_currentLatitude == null || _currentLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor obtén la ubicación GPS'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar presupuesto
    final budget = double.tryParse(_budgetController.text);
    if (budget == null || budget < minBudget) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El presupuesto mínimo es \$${minBudget.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar imagen si no es chequeo
    if (!_needsCheckup && _selectedImage == null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            '¿Continuar sin imagen?',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Se recomienda adjuntar una imagen del problema para que los técnicos puedan ofrecer mejores cotizaciones.',
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Continuar',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    // Obtener el ID del usuario actual
    final userId = DatabaseService.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para crear una solicitud'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Calcular precio con IVA si aplica chequeo
    final totalAmount = _needsCheckup ? checkupFee : budget;
    final ivaAmount = totalAmount * ivaRate;
    final totalWithIva = totalAmount + ivaAmount;

    // Datos de la solicitud
    final serviceRequest = {
      'client_id': userId,
      'titulo': _selectedCategory ?? 'Servicio solicitado',
      'descripcion_problema': _descriptionController.text.trim(),
      'direccion': _addressController.text.trim(),
      'latitude': _currentLatitude,
      'longitude': _currentLongitude,
      'presupuesto_estimado': totalWithIva,
      'requiere_domicilio': true,
      'estado': 'pendiente',
      'imagenes_urls': [], // TODO: Subir imagen al backend y obtener URL
    };

    try {
      // Guardar en la base de datos
      await DatabaseService.createServiceRequest(serviceRequest);

      if (!mounted) return;

      // Mostrar éxito y volver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _needsCheckup
                ? '✓ Solicitud de chequeo creada (\$${checkupFee.toStringAsFixed(2)})'
                : '✓ Solicitud creada exitosamente',
          ),
          backgroundColor: const Color(0xFF27AE60),
          duration: const Duration(seconds: 3),
        ),
      );

      // Limpiar formulario
      _descriptionController.clear();
      _addressController.clear();
      _budgetController.text = minBudget.toStringAsFixed(2);
      setState(() {
        _selectedCategory = null;
        _selectedImage = null;
        _currentLatitude = null;
        _currentLongitude = null;
        _currentAddress = null;
        _needsCheckup = false;
      });

      // Ir atrás
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                _buildInfoBanner(),
                const SizedBox(height: 20),
                _buildCategorySection(),
                const SizedBox(height: 20),
                _buildCheckupOption(),
                const SizedBox(height: 20),
                _buildDescriptionSection(),
                const SizedBox(height: 20),
                _buildImageSection(),
                const SizedBox(height: 20),
                _buildAddressSection(),
                const SizedBox(height: 20),
                _buildLocationSection(),
                const SizedBox(height: 20),
                if (!_needsCheckup) _buildBudgetSection(),
                if (!_needsCheckup) const SizedBox(height: 24),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // WIDGETS DE CONSTRUCCIÓN
  // ========================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Nueva Solicitud',
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
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showTermsDialog,
          tooltip: 'Términos y condiciones',
        ),
      ],
    );
  }

  /// Banner informativo
  Widget _buildInfoBanner() {
    return FadeScaleAnimation(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF555879), Color(0xFF98A1BC)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF555879).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información Importante',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Presupuesto mínimo: \$${minBudget.toStringAsFixed(2)} • IVA incluido (15%)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              onPressed: _showTermsDialog,
            ),
          ],
        ),
      ),
    );
  }

  /// Sección de categorías
  Widget _buildCategorySection() {
    return SlideFadeAnimation(
      delay: const Duration(milliseconds: 200),
      child: _buildSectionContainer(
        icon: Icons.category,
        title: 'Categoría del Servicio',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el tipo de reparación que necesitas:',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF98A1BC),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category['id'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = category['id']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF555879)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF555879)
                            : const Color(0xFF98A1BC),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category['icon'],
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF555879),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF555879),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Opción de chequeo
  Widget _buildCheckupOption() {
    return SlideFadeAnimation(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _needsCheckup
              ? const Color(0xFFFFF3E0)
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _needsCheckup
                ? const Color(0xFFF39C12)
                : const Color(0xFF98A1BC),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _needsCheckup,
              onChanged: (value) =>
                  setState(() => _needsCheckup = value ?? false),
              activeColor: const Color(0xFFF39C12),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 20,
                        color: Color(0xFFF39C12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Solicitar Chequeo (\$${checkupFee.toStringAsFixed(2)})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF555879),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Si desconoces la falla exacta, un técnico puede realizar un diagnóstico. Pago por adelantado.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF98A1BC),
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

  /// Sección de descripción del problema
  Widget _buildDescriptionSection() {
    return SlideFadeAnimation(
      delay: const Duration(milliseconds: 400),
      child: _buildSectionContainer(
        icon: Icons.description,
        title: 'Descripción del Problema',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe detalladamente el problema que necesitas resolver:',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF98A1BC),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Ejemplo: "El interruptor de la cocina no funciona, hace chispas cuando intento encenderlo..."',
                hintStyle: const TextStyle(
                  color: Color(0xFF98A1BC),
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF98A1BC),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF555879),
                    width: 2.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                counterStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  color: Color(0xFF98A1BC),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: Color(0xFF555879),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sección de imagen
  Widget _buildImageSection() {
    return SlideFadeAnimation(
      delay: const Duration(milliseconds: 500),
      child: _buildSectionContainer(
        icon: Icons.image,
        title: 'Imagen del Problema',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _needsCheckup
                  ? 'Opcional para chequeo. Ayuda al técnico a prepararse mejor.'
                  : 'Adjunta una foto para que los técnicos comprendan mejor el problema.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF98A1BC),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _selectedImage = null),
                      ),
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: _showImageOptions,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF98A1BC),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: const Color(0xFF555879).withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Toca para agregar imagen',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF98A1BC),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_selectedImage != null) const SizedBox(height: 12),
            if (_selectedImage != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showImageOptions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF98A1BC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text(
                    'Cambiar imagen',
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Sección de presupuesto
  Widget _buildBudgetSection() {
    return SlideFadeAnimation(
      delay: const Duration(milliseconds: 600),
      child: _buildSectionContainer(
        icon: Icons.attach_money,
        title: 'Presupuesto Estimado',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indica cuánto estás dispuesto a pagar (mínimo \$${minBudget.toStringAsFixed(2)}):',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF98A1BC),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
                hintText: minBudget.toStringAsFixed(2),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF98A1BC),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF555879),
                    width: 2.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF555879),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF27AE60),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este es un presupuesto base. Los técnicos podrán enviarte cotizaciones que puedes comparar.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF27AE60),
                        fontFamily: 'Montserrat',
                      ),
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

  /// Sección de dirección
  Widget _buildAddressSection() {
    return SlideFadeAnimation(
      delay: const Duration(milliseconds: 700),
      child: _buildSectionContainer(
        icon: Icons.location_on,
        title: 'Dirección',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa la dirección completa donde se realizará el servicio:',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF98A1BC),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Calle, número, apartamento, ciudad...',
                hintStyle: const TextStyle(
                  color: Color(0xFF98A1BC),
                  fontFamily: 'Montserrat',
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.home, color: Color(0xFF98A1BC)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF98A1BC),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF555879),
                    width: 2.5,
                  ),
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
            ),
          ],
        ),
      ),
    );
  }

  /// Sección de ubicación (GPS/Mapa)
  Widget _buildLocationSection() {
    return SlideFadeAnimation(
      delay: const Duration(milliseconds: 800),
      child: _buildSectionContainer(
        icon: Icons.map,
        title: 'Ubicación GPS',
        content: Column(
          children: [
            const Text(
              'Obtén tu ubicación GPS para que el técnico llegue sin problemas:',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF98A1BC),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),
            // Mapa simulado
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF98A1BC), width: 1.5),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFDED3C4).withOpacity(0.3),
                    const Color(0xFF98A1BC).withOpacity(0.1),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentLatitude != null
                          ? Icons.location_on
                          : Icons.location_off,
                      size: 56,
                      color: _currentLatitude != null
                          ? const Color(0xFF27AE60)
                          : const Color(0xFF555879).withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    if (_currentLatitude != null &&
                        _currentLongitude != null) ...[
                      const Text(
                        '✓ Ubicación obtenida',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF27AE60),
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_currentLatitude!.toStringAsFixed(6)}, ${_currentLongitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF555879).withOpacity(0.7),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ] else
                      Text(
                        'Toca "Obtener ubicación GPS"',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF555879).withOpacity(0.5),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Botón obtener ubicación
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF555879),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFF555879,
                  ).withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.gps_fixed),
                label: Text(
                  _isLoadingLocation
                      ? 'Obteniendo ubicación...'
                      : 'Obtener Ubicación GPS',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

  /// Botón de envío
  Widget _buildSubmitButton() {
    return SlideFadeAnimation(
      delay: const Duration(milliseconds: 900),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF555879).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _createServiceRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: _needsCheckup
                  ? const Color(0xFFF39C12)
                  : const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: Icon(_needsCheckup ? Icons.search : Icons.send),
            label: Text(
              _needsCheckup
                  ? 'Solicitar Chequeo (\$${checkupFee.toStringAsFixed(2)})'
                  : 'Crear Solicitud',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Contenedor de sección reutilizable
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
