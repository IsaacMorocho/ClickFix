import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

class RecommendedTechniciansWidget extends StatefulWidget {
  final String? specialtyId;
  final Function(Map<String, dynamic>)? onTechnicianSelected;

  const RecommendedTechniciansWidget({
    super.key,
    this.specialtyId,
    this.onTechnicianSelected,
  });

  @override
  State<RecommendedTechniciansWidget> createState() => _RecommendedTechniciansWidgetState();
}

class _RecommendedTechniciansWidgetState extends State<RecommendedTechniciansWidget> {
  List<Map<String, dynamic>> _technicians = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    try {
      final position = await LocationService.getCurrentLocation();
      final technicians = await DatabaseService.getTechniciansWithLocation();

      List<Map<String, dynamic>> filteredTechnicians = technicians;

      // Filtrar por especialidad si se especifica
      if (widget.specialtyId != null) {
        filteredTechnicians = technicians.where((t) {
          final specialties = t['technician_specialties'] as List<dynamic>? ?? [];
          return specialties.any((s) => s['specialty_id'] == widget.specialtyId);
        }).toList();
      }

      // Calcular distancia si tenemos ubicacion
      if (position != null) {
        for (var tech in filteredTechnicians) {
          final techLat = tech['latitud'] as double?;
          final techLon = tech['longitud'] as double?;

          if (techLat != null && techLon != null) {
            tech['distancia'] = LocationService.calculateDistance(
              position.latitude, position.longitude,
              techLat, techLon,
            );
          } else {
            tech['distancia'] = 999.0; // Sin ubicacion, al final
          }
        }

        // Ordenar por distancia
        filteredTechnicians.sort((a, b) =>
            (a['distancia'] as double).compareTo(b['distancia'] as double));
      }

      if (mounted) {
        setState(() {
          _technicians = filteredTechnicians.take(5).toList(); // Top 5
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar tecnicos';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFF555879)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_technicians.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No hay técnicos disponibles en tu zona',
          style: TextStyle(color: Color(0xFF98A1BC)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFF555879), size: 20),
              SizedBox(width: 8),
              Text(
                'Tecnicos cercanos a ti',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _technicians.length,
            itemBuilder: (context, index) {
              final tech = _technicians[index];
              return _buildTechnicianCard(tech);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianCard(Map<String, dynamic> tech) {
    final user = tech['users'] as Map<String, dynamic>?;
    final nombre = user?['nombre_completo'] ?? 'Tecnico';
    final rating = tech['rating_promedio'] ?? 0.0;
    final distancia = tech['distancia'] as double?;

    return GestureDetector(
      onTap: () => widget.onTechnicianSelected?.call(tech),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF98A1BC).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF555879),
              child: Text(
                nombre.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nombre.split(' ').first,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF555879),
                fontFamily: 'Montserrat',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Color(0xFFF39C12), size: 14),
                const SizedBox(width: 2),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF555879)),
                ),
              ],
            ),
            if (distancia != null && distancia < 100) ...[
              const SizedBox(height: 4),
              Text(
                '${distancia.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF27AE60),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
