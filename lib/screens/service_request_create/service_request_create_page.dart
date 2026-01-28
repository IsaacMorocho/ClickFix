import 'package:flutter/material.dart';
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
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  bool _isLoadingLocation = false;
  double? _currentLatitude;
  double? _currentLongitude;

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

    // Inicializar controladores de texto
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();

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
    _latitudeController.dispose();
    _longitudeController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ========================================================================
  // MÉTODOS CRUD
  // ========================================================================

  /// Obtener ubicación GPS (simulado)
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    // TODO: Implementar con geolocator package
    // Simulación de obtención de ubicación
    await Future.delayed(const Duration(seconds: 1));

    // Coordenadas de ejemplo (Colombia)
    const simulatedLatitude = 4.7110;
    const simulatedLongitude = -74.0720;

    setState(() {
      _currentLatitude = simulatedLatitude;
      _currentLongitude = simulatedLongitude;
      _latitudeController.text = simulatedLatitude.toString();
      _longitudeController.text = simulatedLongitude.toString();
      _isLoadingLocation = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación obtenida exitosamente'),
          backgroundColor: Color(0xFF555879),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Crear solicitud de servicio
  Future<void> _createServiceRequest() async {
    // Validar campos requeridos
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor describe el problema'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa la dirección'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentLatitude == null || _currentLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor obtén la ubicación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar formato de coordenadas
    final latitude = double.tryParse(_latitudeController.text);
    final longitude = double.tryParse(_longitudeController.text);

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las coordenadas deben ser números válidos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
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

    // Datos de la solicitud
    final serviceRequest = {
      'cliente_id': userId,
      'descripcion_problema': _descriptionController.text.trim(),
      'direccion': _addressController.text.trim(),
      'latitud': latitude,
      'longitud': longitude,
      'estado': 'solicitud',
    };

    try {
      // Guardar en Supabase
      await DatabaseService.createServiceRequest(serviceRequest);

      if (!mounted) return;

      // Mostrar éxito y volver
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud creada exitosamente'),
          backgroundColor: Color(0xFF27AE60),
          duration: Duration(seconds: 2),
        ),
      );

      // Limpiar formulario
      _descriptionController.clear();
      _addressController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      setState(() {
        _currentLatitude = null;
        _currentLongitude = null;
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
                _buildDescriptionSection(),
                const SizedBox(height: 24),
                _buildAddressSection(),
                const SizedBox(height: 24),
                _buildLocationSection(),
                const SizedBox(height: 32),
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
    );
  }

  /// Sección de descripción del problema
  Widget _buildDescriptionSection() {
    return _buildSectionContainer(
      icon: Icons.description,
      title: 'Descripción del Problema',
      content: Column(
        children: [
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Describe el problema que necesitas resolver...',
              hintStyle: const TextStyle(
                color: Color(0xFF98A1BC),
                fontFamily: 'Montserrat',
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
    );
  }

  /// Sección de dirección
  Widget _buildAddressSection() {
    return _buildSectionContainer(
      icon: Icons.location_on,
      title: 'Dirección',
      content: Column(
        children: [
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
    );
  }

  /// Sección de ubicación (GPS/Mapa)
  Widget _buildLocationSection() {
    return _buildSectionContainer(
      icon: Icons.map,
      title: 'Ubicación',
      content: Column(
        children: [
          // Mapa simulado
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF98A1BC), width: 1.5),
              color: const Color(0xFFDED3C4).withOpacity(0.3),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 48,
                    color: const Color(0xFF555879).withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  if (_currentLatitude != null && _currentLongitude != null)
                    Text(
                      'Ubicación obtenida',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF555879).withOpacity(0.7),
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      'Toca "Obtener ubicación"',
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.gps_fixed),
              label: Text(
                _isLoadingLocation ? 'Obteniendo ubicación...' : 'Obtener GPS',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Campos de coordenadas
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Latitud',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF98A1BC),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _latitudeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: '--',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.7),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFDED3C4),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        color: Color(0xFF555879),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Longitud',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF98A1BC),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _longitudeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: '--',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.7),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFDED3C4),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        color: Color(0xFF555879),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Botón de envío
  Widget _buildSubmitButton() {
    return Container(
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
            backgroundColor: const Color(0xFF555879),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.send),
          label: const Text(
            'Crear Solicitud',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
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
