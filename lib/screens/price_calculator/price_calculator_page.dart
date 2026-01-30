import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/database_service.dart';

/// Calculadora de precios sugeridos para técnicos
class PriceCalculatorPage extends StatefulWidget {
  final String serviceRequestId;
  final String serviceType;
  final String? clientZone;

  const PriceCalculatorPage({
    super.key,
    required this.serviceRequestId,
    required this.serviceType,
    this.clientZone,
  });

  @override
  State<PriceCalculatorPage> createState() => _PriceCalculatorPageState();
}

class _PriceCalculatorPageState extends State<PriceCalculatorPage> {
  bool _isLoading = true;
  double _suggestedPrice = 0;
  double _minPrice = 0;
  double _maxPrice = 0;
  double _userPrice = 0;

  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Factores de cálculo
  Map<String, dynamic> _priceFactors = {};

  @override
  void initState() {
    super.initState();
    _calculateSuggestedPrice();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _calculateSuggestedPrice() async {
    setState(() => _isLoading = true);

    try {
      final technicianId = DatabaseService.currentUserId;
      if (technicianId == null) return;

      // Obtener precio sugerido basado en múltiples factores
      final suggestion = await DatabaseService.calculateSuggestedPrice(
        serviceType: widget.serviceType,
        zone: widget.clientZone,
        technicianId: technicianId,
      );

      setState(() {
        _suggestedPrice = suggestion['suggested_price'] ?? 50;
        _minPrice = suggestion['min_price'] ?? 30;
        _maxPrice = suggestion['max_price'] ?? 100;
        _priceFactors = suggestion['factors'] ?? {};
        _userPrice = _suggestedPrice;
        _priceController.text = _suggestedPrice.toStringAsFixed(0);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al calcular precio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitQuotation() async {
    if (_userPrice < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El precio mínimo es \$10'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa la duración estimada'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final technicianId = DatabaseService.currentUserId;
      await DatabaseService.createQuotation(
        serviceRequestId: widget.serviceRequestId,
        technicianId: technicianId!,
        amount: _userPrice,
        estimatedDuration: int.parse(_durationController.text),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cotización enviada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar cotización: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Calcular Cotización',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Precio sugerido
                  _buildSuggestedPriceCard(),

                  const SizedBox(height: 16),

                  // Factores de precio
                  _buildPriceFactorsCard(),

                  const SizedBox(height: 16),

                  // Rango de precios
                  _buildPriceRangeCard(),

                  const SizedBox(height: 24),

                  // Formulario de cotización
                  _buildQuotationForm(),

                  const SizedBox(height: 24),

                  // Botón de enviar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitQuotation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Enviar Cotización',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSuggestedPriceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.lightbulb, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Precio Sugerido',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_suggestedPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Basado en historial y zona',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFactorsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Color(0xFF6C63FF)),
                SizedBox(width: 8),
                Text(
                  'Factores Considerados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFactorItem(
              'Tipo de Servicio',
              widget.serviceType,
              Icons.build,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildFactorItem(
              'Zona del Cliente',
              widget.clientZone ?? 'Desconocida',
              Icons.location_on,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildFactorItem(
              'Tu Experiencia',
              '${_priceFactors['experience_years'] ?? 0} años',
              Icons.star,
              Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildFactorItem(
              'Precio Promedio del Mercado',
              '\$${_priceFactors['market_average'] ?? 0}',
              Icons.trending_up,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRangeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rango de Precios del Mercado',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPriceRangeItem('Mínimo', _minPrice, Colors.red),
                _buildPriceRangeItem('Sugerido', _suggestedPrice, Colors.green),
                _buildPriceRangeItem('Máximo', _maxPrice, Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_suggestedPrice - _minPrice) / (_maxPrice - _minPrice),
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6C63FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeItem(String label, double price, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            '\$${price.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuotationForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu Cotización',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Precio personalizado
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Precio (\$)',
                prefixIcon: const Icon(
                  Icons.attach_money,
                  color: Color(0xFF6C63FF),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Puedes ajustar el precio sugerido',
              ),
              onChanged: (value) {
                setState(() {
                  _userPrice = double.tryParse(value) ?? _suggestedPrice;
                });
              },
            ),

            const SizedBox(height: 16),

            // Duración estimada
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Duración estimada (horas)',
                prefixIcon: const Icon(
                  Icons.schedule,
                  color: Color(0xFF6C63FF),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Descripción
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Descripción del servicio (opcional)',
                prefixIcon: const Icon(
                  Icons.description,
                  color: Color(0xFF6C63FF),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
