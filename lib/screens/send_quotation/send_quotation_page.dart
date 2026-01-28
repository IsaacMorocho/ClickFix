import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class SendQuotationPage extends StatefulWidget {
  final Map<String, dynamic> request;

  const SendQuotationPage({super.key, required this.request});

  @override
  State<SendQuotationPage> createState() => _SendQuotationPageState();
}

class _SendQuotationPageState extends State<SendQuotationPage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO
  // ========================================================================

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _tiempoController = TextEditingController();
  bool _isSubmitting = false;

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _montoController.dispose();
    _descripcionController.dispose();
    _tiempoController.dispose();
    super.dispose();
  }

  // ========================================================================
  // METODOS CRUD
  // ========================================================================

  Future<void> _submitQuotation() async {
    if (_montoController.text.isEmpty ||
        _descripcionController.text.isEmpty ||
        _tiempoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final monto = int.tryParse(_montoController.text.replaceAll('.', ''));
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto valido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Obtener el perfil del técnico
      final userId = DatabaseService.currentUserId;
      if (userId == null) {
        throw Exception('Debes iniciar sesión');
      }

      final technicianProfile = await DatabaseService.getTechnicianProfile(userId);
      if (technicianProfile == null) {
        throw Exception('No se encontró el perfil de técnico');
      }

      // Guardar cotización en Supabase
      await DatabaseService.createQuote({
        'service_request_id': widget.request['id'],
        'technician_id': technicianProfile['id'],
        'monto': monto,
        'descripcion': _descripcionController.text.trim(),
        'tiempo_estimado': _tiempoController.text.trim(),
        'estado': 'pendiente',
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cotizacion enviada correctamente'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar cotización: $e'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                _buildRequestInfo(),
                const SizedBox(height: 24),
                _buildQuotationForm(),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Enviar Cotizacion',
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

  Widget _buildRequestInfo() {
    return _buildSectionContainer(
      icon: Icons.description,
      title: 'Solicitud del Cliente',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF555879), width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    widget.request['cliente_foto'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Color(0xFF555879));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request['cliente_nombre'] ?? 'Cliente',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF555879),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      widget.request['especialidad'] ?? 'Servicio',
                      style: const TextStyle(
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
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFDED3C4)),
          const SizedBox(height: 16),
          Text(
            widget.request['descripcion'] ?? 'Descripcion del problema',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF98A1BC)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.request['direccion'] ?? 'Direccion',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF98A1BC),
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

  Widget _buildQuotationForm() {
    return _buildSectionContainer(
      icon: Icons.attach_money,
      title: 'Tu Cotizacion',
      content: Column(
        children: [
          // Monto
          TextField(
            controller: _montoController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monto (COP)',
              labelStyle: const TextStyle(color: Color(0xFF98A1BC)),
              prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF555879)),
              hintText: 'Ej: 150000',
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
            ),
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              color: Color(0xFF555879),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Tiempo estimado
          TextField(
            controller: _tiempoController,
            decoration: InputDecoration(
              labelText: 'Tiempo estimado',
              labelStyle: const TextStyle(color: Color(0xFF98A1BC)),
              prefixIcon: const Icon(Icons.schedule, color: Color(0xFF555879)),
              hintText: 'Ej: 2 horas, 1 dia',
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
            ),
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: Color(0xFF555879),
            ),
          ),
          const SizedBox(height: 16),
          // Descripcion
          TextField(
            controller: _descripcionController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Descripcion del trabajo',
              labelStyle: const TextStyle(color: Color(0xFF98A1BC)),
              alignLabelWithHint: true,
              hintText: 'Describe que incluye tu cotizacion, materiales, garantia, etc.',
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
            ),
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: Color(0xFF555879),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitQuotation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF555879),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF555879).withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send),
        label: Text(
          _isSubmitting ? 'Enviando...' : 'Enviar Cotizacion',
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
