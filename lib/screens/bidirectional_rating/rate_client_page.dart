import 'package:flutter/material.dart';
import '../../services/database_service.dart';

/// Pantalla para que el técnico califique al cliente después del servicio
class RateClientPage extends StatefulWidget {
  final String serviceId;
  final String clientId;
  final String clientName;

  const RateClientPage({
    super.key,
    required this.serviceId,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<RateClientPage> createState() => _RateClientPageState();
}

class _RateClientPageState extends State<RateClientPage> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  // Criterios específicos para técnicos
  final Map<String, bool> _criteria = {
    'Descripción clara del problema': false,
    'Disponibilidad de materiales': false,
    'Pago puntual': false,
    'Trato respetuoso': false,
  };

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
      // Obtener ID del técnico actual (desde SharedPreferences o estado global)
      const technicianId =
          'current_technician_id'; // TODO: Obtener ID real del técnico

      // Agregar criterios al comentario
      String fullComment = _commentController.text.trim();
      final selectedCriteria = _criteria.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      if (selectedCriteria.isNotEmpty) {
        fullComment +=
            '\n\nCriterios positivos: ${selectedCriteria.join(', ')}';
      }

      await DatabaseService.rateClient(
        serviceId: widget.serviceId,
        technicianId: technicianId,
        clientId: widget.clientId,
        rating: _rating,
        comment: fullComment,
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
      appBar: AppBar(title: const Text('Calificar Cliente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Ícono del cliente
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 50,
                color: Color(0xFF6C63FF),
              ),
            ),

            const SizedBox(height: 16),

            // Nombre del cliente
            Text(
              widget.clientName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              '¿Cómo fue tu experiencia con este cliente?',
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

            // Criterios de evaluación
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Criterios de evaluación (opcional):',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._criteria.keys.map((criterion) {
                      return CheckboxListTile(
                        title: Text(criterion),
                        value: _criteria[criterion],
                        onChanged: (value) {
                          setState(() {
                            _criteria[criterion] = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF6C63FF),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Campo de comentario
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Comentario adicional (opcional)',
                hintText: 'Comparte más detalles sobre tu experiencia...',
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
