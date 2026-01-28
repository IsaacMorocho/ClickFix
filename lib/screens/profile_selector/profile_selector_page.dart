import 'package:flutter/material.dart';
import '../service_quotations/service_quotations_page.dart';
import '../services/services_in_progress_page.dart';

class ProfileSelectorPage extends StatelessWidget {
  const ProfileSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4EBD3), Color(0xFFDED3C4)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle,
                size: 80,
                color: Color(0xFF555879),
              ),
              const SizedBox(height: 32),
              const Text(
                'Seleccionar Perfil',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 48),
              _buildProfileButton(
                context,
                icon: Icons.build,
                title: 'Perfil Técnico',
                route: '/technicianProfile',
              ),
              const SizedBox(height: 20),
              _buildProfileButton(
                context,
                icon: Icons.person,
                title: 'Perfil de Usuario',
                route: '/userProfile',
              ),
              const SizedBox(height: 20),
              _buildProfileButton(
                context,
                icon: Icons.add_circle,
                title: 'Nueva Solicitud',
                route: '/serviceRequestCreate',
              ),
              const SizedBox(height: 20),
              _buildProfileButton(
                context,
                icon: Icons.list_alt,
                title: 'Mis Solicitudes',
                route: '/serviceRequests',
              ),
              const SizedBox(height: 20),
              _buildCotizacionesButton(context),
              const SizedBox(height: 20),
              _buildServicioEnProgresoButton(context),
              const SizedBox(height: 40),
              _buildNotificationsButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF98A1BC), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF555879).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: const Color(0xFF555879)),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555879),
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCotizacionesButton(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ServiceQuotationsPage(
            serviceRequestId: '1',
            serviceDescription: 'Reparación de grieta en pared',
          ),
        ),
      );
    },
    child: Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF98A1BC), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF555879).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money, size: 36, color: Color(0xFF555879)),
          const SizedBox(width: 16),
          const Text(
            'Cotizaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildNotificationsButton(BuildContext context) {
  return GestureDetector(
    onTap: () => Navigator.pushNamed(context, '/notifications'),
    child: Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF98A1BC), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF555879).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              const Icon(
                Icons.notifications,
                size: 36,
                color: Color(0xFF555879),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          const Text(
            'Notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildServicioEnProgresoButton(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ServiceInProgressPage()),
      );
    },
    child: Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF98A1BC), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF555879).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.build, size: 36, color: Color(0xFF555879)),
          const SizedBox(width: 16),
          const Text(
            'En Progreso',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    ),
  );
}
