import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../core/animations/page_transitions.dart';

/// Pantalla de filtro inteligente de técnicos
/// Permite ordenar y filtrar técnicos por precio, rating, cercanía y especialidad
class TechnicianFilterPage extends StatefulWidget {
  const TechnicianFilterPage({super.key});

  @override
  State<TechnicianFilterPage> createState() => _TechnicianFilterPageState();
}

class _TechnicianFilterPageState extends State<TechnicianFilterPage> {
  String _sortBy = 'rating'; // 'price', 'rating', 'distance'
  double? _maxPrice;
  double _minRating = 0.0;
  double? _maxDistance; // en kilómetros
  String? _selectedSpecialty;

  final List<String> _specialties = [
    'Reparación de PC',
    'Reparación de Laptop',
    'Mantenimiento Preventivo',
    'Instalación de Software',
    'Redes y Conectividad',
    'Recuperación de Datos',
    'Actualización de Hardware',
    'Soporte Técnico General',
  ];

  List<Map<String, dynamic>> _technicians = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    setState(() => _isLoading = true);

    final technicians = await DatabaseService.filterTechnicians(
      sortBy: _sortBy,
      maxPrice: _maxPrice,
      minRating: _minRating,
      maxDistance: _maxDistance,
      specialty: _selectedSpecialty,
    );

    setState(() {
      _technicians = technicians;
      _isLoading = false;
    });
  }

  void _clearFilters() {
    setState(() {
      _sortBy = 'rating';
      _maxPrice = null;
      _minRating = 0.0;
      _maxDistance = null;
      _selectedSpecialty = null;
    });
    _loadTechnicians();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buscar Técnico',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTechnicians,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFilterSection(),

          const Divider(height: 1),

          // Lista de técnicos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _technicians.isEmpty
                ? _buildEmptyState()
                : _buildTechniciansList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ordenar por
          Row(
            children: [
              const Icon(Icons.sort, color: Color(0xFF6C63FF), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Ordenar por:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    _buildSortChip('rating', 'Calificación', Icons.star),
                    _buildSortChip('price', 'Precio', Icons.attach_money),
                    _buildSortChip('distance', 'Cercanía', Icons.location_on),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Especialidad
          _buildSpecialtyFilter(),

          const SizedBox(height: 12),

          // Precio máximo
          _buildPriceFilter(),

          const SizedBox(height: 12),

          // Rating mínimo
          _buildRatingFilter(),

          const SizedBox(height: 12),

          // Distancia máxima
          _buildDistanceFilter(),

          const SizedBox(height: 16),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Limpiar Filtros'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loadTechnicians,
                  icon: const Icon(Icons.search),
                  label: const Text('Aplicar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      onSelected: (selected) {
        setState(() => _sortBy = value);
      },
      selectedColor: const Color(0xFF6C63FF).withOpacity(0.2),
      checkmarkColor: const Color(0xFF6C63FF),
    );
  }

  Widget _buildSpecialtyFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Especialidad:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSpecialty,
          decoration: InputDecoration(
            hintText: 'Todas las especialidades',
            prefixIcon: const Icon(Icons.work_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Todas las especialidades'),
            ),
            ..._specialties.map(
              (specialty) =>
                  DropdownMenuItem(value: specialty, child: Text(specialty)),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedSpecialty = value);
          },
        ),
      ],
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Precio máximo:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(
              _maxPrice != null
                  ? '\$${_maxPrice!.toStringAsFixed(0)}'
                  : 'Sin límite',
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _maxPrice ?? 500,
          min: 10,
          max: 500,
          divisions: 49,
          activeColor: const Color(0xFF6C63FF),
          onChanged: (value) {
            setState(() => _maxPrice = value);
          },
          onChangeEnd: (value) {
            if (value == 500) {
              setState(() => _maxPrice = null);
            }
          },
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Calificación mínima:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Row(
              children: [
                Text(
                  _minRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.star, color: Colors.amber, size: 18),
              ],
            ),
          ],
        ),
        Slider(
          value: _minRating,
          min: 0,
          max: 5,
          divisions: 10,
          activeColor: const Color(0xFF6C63FF),
          onChanged: (value) {
            setState(() => _minRating = value);
          },
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Distancia máxima:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(
              _maxDistance != null
                  ? '${_maxDistance!.toStringAsFixed(0)} km'
                  : 'Sin límite',
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _maxDistance ?? 50,
          min: 1,
          max: 50,
          divisions: 49,
          activeColor: const Color(0xFF6C63FF),
          onChanged: (value) {
            setState(() => _maxDistance = value);
          },
          onChangeEnd: (value) {
            if (value == 50) {
              setState(() => _maxDistance = null);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTechniciansList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _technicians.length,
      itemBuilder: (context, index) {
        final technician = _technicians[index];
        return _buildTechnicianCard(technician);
      },
    );
  }

  Widget _buildTechnicianCard(Map<String, dynamic> technician) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navegar a detalles del técnico
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: technician['photo_url'] != null
                        ? NetworkImage(technician['photo_url'])
                        : null,
                    child: technician['photo_url'] == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Información básica
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                technician['nombre_completo'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (technician['verificado'] == true)
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF6C63FF),
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          technician['especialidad'] ?? 'Sin especialidad',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Métricas
              Row(
                children: [
                  // Rating
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          (technician['rating'] ?? 0).toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Precio
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          color: Colors.green,
                          size: 16,
                        ),
                        Text(
                          '\$${technician['precio_hora'] ?? 0}/h',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Distancia
                  if (technician['distancia'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${technician['distancia'].toStringAsFixed(1)} km',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Botón de solicitar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navegar a crear solicitud con este técnico pre-seleccionado
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Solicitar Servicio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No se encontraron técnicos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta ajustar los filtros de búsqueda',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('Limpiar Filtros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
