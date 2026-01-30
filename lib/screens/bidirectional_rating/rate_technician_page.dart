import 'package:flutter/material.dart';
import '../../services/database_service.dart';

/// Pantalla para que el cliente califique al técnico después del servicio
class RateTechnicianPage extends StatefulWidget {
  final String serviceId;
  final String technicianId;
  final String technicianName;
  final String? technicianPhoto;

  const RateTechnicianPage({
    super.key,
    required this.serviceId,
    required this.technicianId,
    required this.technicianName,
    this.technicianPhoto,
  });

  @override
  State<RateTechnicianPage> createState() => _RateTechnicianPageState();
}

class _RateTechnicianPageState extends State<RateTechnicianPage> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una calificación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Obtener ID del cliente actual (desde SharedPreferences o estado global)
      const clientId = 'current_client_id'; // TODO: Obtener ID real del cliente

      await DatabaseService.rateTechnician(
        serviceId: widget.serviceId,
        clientId: clientId,
        technicianId: widget.technicianId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Calificación enviada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Retorna true para indicar que se calificó
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar calificación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calificar Técnico')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar del técnico
            CircleAvatar(
              radius: 50,
              backgroundImage: widget.technicianPhoto != null
                  ? NetworkImage(widget.technicianPhoto!)
                  : null,
              child: widget.technicianPhoto == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),

            const SizedBox(height: 16),

            // Nombre del técnico
            Text(
              widget.technicianName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              '¿Cómo fue tu experiencia con este técnico?',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Estrellas de calificación
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  onPressed: () {
                    setState(() => _rating = starValue.toDouble());
                  },
                  icon: Icon(
                    starValue <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 48,
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // Texto de la calificación
            if (_rating > 0)
              Text(
                _getRatingText(_rating),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C63FF),
                ),
              ),

            const SizedBox(height: 32),

            // Campo de comentario
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Cuéntanos más sobre tu experiencia...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón de enviar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Enviar Calificación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Botón de omitir
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Omitir por ahora'),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating == 1) return 'Muy malo';
    if (rating == 2) return 'Malo';
    if (rating == 3) return 'Regular';
    if (rating == 4) return 'Bueno';
    if (rating == 5) return 'Excelente';
    return '';
  }
}
