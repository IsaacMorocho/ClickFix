import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/database_service.dart';

class TechnicianCertificatesPage extends StatefulWidget {
  const TechnicianCertificatesPage({super.key});

  @override
  State<TechnicianCertificatesPage> createState() => _TechnicianCertificatesPageState();
}

class _TechnicianCertificatesPageState extends State<TechnicianCertificatesPage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO
  // ========================================================================

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _certificates = [];
  final ImagePicker _imagePicker = ImagePicker();
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

    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    final userId = DatabaseService.currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Obtener el perfil del técnico para conseguir el technician_id
      final technicianProfile = await DatabaseService.getTechnicianProfile(userId);
      if (technicianProfile == null) {
        setState(() => _isLoading = false);
        return;
      }

      _technicianId = technicianProfile['id'];
      final certificates = await DatabaseService.getTechnicianCertificates(_technicianId!);
      
      if (mounted) {
        setState(() {
          _certificates = certificates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar certificados: $e'),
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

  void _showAddCertificateDialog() {
    final nombreController = TextEditingController();
    final institucionController = TextEditingController();
    File? selectedFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFF4EBD3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Agregar Certificado',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              color: Color(0xFF555879),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del certificado',
                    labelStyle: const TextStyle(color: Color(0xFF98A1BC)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF98A1BC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF555879), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: institucionController,
                  decoration: InputDecoration(
                    labelText: 'Institucion',
                    labelStyle: const TextStyle(color: Color(0xFF98A1BC)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF98A1BC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF555879), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final XFile? file = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (file != null) {
                      setDialogState(() {
                        selectedFile = File(file.path);
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedFile != null
                            ? const Color(0xFF555879)
                            : const Color(0xFF98A1BC),
                        width: selectedFile != null ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedFile != null ? Icons.check_circle : Icons.upload_file,
                          color: selectedFile != null
                              ? const Color(0xFF27AE60)
                              : const Color(0xFF98A1BC),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedFile != null ? 'Archivo seleccionado' : 'Subir archivo (PDF/Imagen)',
                          style: TextStyle(
                            color: selectedFile != null
                                ? const Color(0xFF555879)
                                : const Color(0xFF98A1BC),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Color(0xFF98A1BC), fontFamily: 'Montserrat'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.isEmpty || institucionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Completa todos los campos'),
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

                Navigator.pop(context);

                try {
                  String? archivoUrl;
                  
                  // Subir archivo al bucket si se seleccionó uno
                  if (selectedFile != null) {
                    final bytes = await selectedFile!.readAsBytes();
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${selectedFile!.path.split('/').last}';
                    archivoUrl = await DatabaseService.uploadCertificate(
                      _technicianId!,
                      bytes,
                      fileName,
                    );
                  }

                  // Guardar en la tabla technician_certificates
                  await DatabaseService.addCertificate({
                    'technician_id': _technicianId,
                    'nombre': nombreController.text,
                    'institucion': institucionController.text,
                    'fecha_emision': DateTime.now().toIso8601String(),
                    'archivo_url': archivoUrl,
                  });

                  // Recargar la lista
                  await _loadCertificates();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Certificado agregado correctamente'),
                        backgroundColor: Color(0xFF27AE60),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al guardar certificado: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF555879),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCertificate(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF4EBD3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar Certificado',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Color(0xFF555879),
          ),
        ),
        content: const Text(
          'Estas seguro de eliminar este certificado?',
          style: TextStyle(fontFamily: 'Montserrat', color: Color(0xFF555879)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF98A1BC), fontFamily: 'Montserrat'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DatabaseService.deleteCertificate(id);
                await _loadCertificates();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Certificado eliminado'),
                      backgroundColor: Color(0xFF98A1BC),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
            ),
          ),
        ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCertificateDialog,
        backgroundColor: const Color(0xFF555879),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Agregar',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF555879)))
              : _certificates.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _certificates.length,
                      itemBuilder: (context, index) {
                        return _buildCertificateCard(_certificates[index]);
                      },
                    ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Mis Certificados',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.workspace_premium,
            size: 80,
            color: const Color(0xFF98A1BC).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes certificados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tus certificados para aumentar tu credibilidad',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF98A1BC).withOpacity(0.7),
              fontFamily: 'Montserrat',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(Map<String, dynamic> certificate) {
    DateTime fecha;
    final fechaValue = certificate['fecha_emision'];
    if (fechaValue is DateTime) {
      fecha = fechaValue;
    } else if (fechaValue is String) {
      fecha = DateTime.parse(fechaValue);
    } else {
      fecha = DateTime.now();
    }
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFDED3C4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Color(0xFF555879),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      certificate['nombre'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF555879),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      certificate['institucion'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF98A1BC),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteCertificate(certificate['id']),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFDED3C4)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emitido: ${months[fecha.month - 1]} ${fecha.year}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF98A1BC),
                  fontFamily: 'Montserrat',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: certificate['verificado']
                      ? const Color(0xFF27AE60).withOpacity(0.2)
                      : const Color(0xFFF39C12).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: certificate['verificado']
                        ? const Color(0xFF27AE60)
                        : const Color(0xFFF39C12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      certificate['verificado'] ? Icons.verified : Icons.pending,
                      size: 14,
                      color: certificate['verificado']
                          ? const Color(0xFF27AE60)
                          : const Color(0xFFF39C12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      certificate['verificado'] ? 'Verificado' : 'Pendiente',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: certificate['verificado']
                            ? const Color(0xFF27AE60)
                            : const Color(0xFFF39C12),
                        fontFamily: 'Montserrat',
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
}
