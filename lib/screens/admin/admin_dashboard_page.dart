import 'package:flutter/material.dart';
import 'admin_users_page.dart';
import 'admin_technicians_page.dart';
import 'admin_specialties_page.dart';
import 'admin_requests_page.dart';
import 'admin_services_page.dart';
import 'admin_reviews_page.dart';
import '../../services/database_service.dart';
import '../../auth/auth_service.dart';
import '../../auth/login_screen.dart';

class AdminDashboardPage extends StatefulWidget {
  final VoidCallback? onLogout;

  const AdminDashboardPage({super.key, this.onLogout});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO
  // ========================================================================

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Estadisticas
  Map<String, dynamic> _stats = {
    'total_usuarios': 0,
    'total_tecnicos': 0,
    'tecnicos_pendientes': 0,
    'total_solicitudes': 0,
    'solicitudes_activas': 0,
    'total_servicios': 0,
    'servicios_completados': 0,
    'total_resenas': 0,
    'resenas_pendientes': 0,
  };
  bool _isLoading = true;

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

    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Cargar estadísticas desde Supabase
      final users = await DatabaseService.getAllUsers();
      final technicians = await DatabaseService.getAllTechnicians();
      final serviceRequests = await DatabaseService.getServiceRequests();
      final services = await DatabaseService.getServices();
      final reviews = await DatabaseService.getReviews();

      if (mounted) {
        setState(() {
          _stats = {
            'total_usuarios': users.where((u) => u['rol'] == 'cliente').length,
            'total_tecnicos': technicians.length,
            'tecnicos_pendientes': technicians
                .where((t) => t['verificado_por'] == null)
                .length,
            'total_solicitudes': serviceRequests.length,
            'solicitudes_activas': serviceRequests
                .where(
                  (r) =>
                      r['estado'] == 'pendiente' || r['estado'] == 'en_proceso',
                )
                .length,
            'total_servicios': services.length,
            'servicios_completados': services
                .where((s) => s['estado'] == 'completado')
                .length,
            'total_resenas': reviews.length,
            'resenas_pendientes': reviews
                .where((r) => r['estado'] == 'pendiente')
                .length,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estadísticas: $e'),
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
  // CONSTRUIR INTERFAZ
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EBD3),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                const SizedBox(height: 24),
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildPendingAlerts(),
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
        'Panel de Administracion',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: const Color(0xFF555879),
      elevation: 4,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            // TODO: Ver notificaciones admin
          },
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFFF4EBD3),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF555879), Color(0xFF98A1BC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 35,
                      color: Color(0xFF555879),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Administrador',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const Text(
                    'admin@clickfix.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              Icons.dashboard,
              'Dashboard',
              () => Navigator.pop(context),
            ),
            _buildDrawerItem(Icons.people, 'Gestion de Usuarios', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUsersPage()),
              );
            }),
            _buildDrawerItem(Icons.engineering, 'Verificar Tecnicos', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminTechniciansPage()),
              );
            }),
            _buildDrawerItem(Icons.category, 'Especialidades', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSpecialtiesPage()),
              );
            }),
            _buildDrawerItem(Icons.assignment, 'Solicitudes', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminRequestsPage()),
              );
            }),
            _buildDrawerItem(Icons.build, 'Servicios', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminServicesPage()),
              );
            }),
            _buildDrawerItem(Icons.rate_review, 'Moderar Resenas', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminReviewsPage()),
              );
            }),
            const Divider(),
            _buildDrawerItem(Icons.logout, 'Cerrar Sesion', () async {
              Navigator.pop(context);
              try {
                await AuthService().logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cerrar sesión: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF555879)),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          color: Color(0xFF555879),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF555879), Color(0xFF98A1BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF555879).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenido, Admin',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tienes ${_stats['tecnicos_pendientes']} tecnicos pendientes de verificacion',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 35,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadisticas Generales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF555879),
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Usuarios',
              _stats['total_usuarios'],
              Icons.people,
              const Color(0xFF3498DB),
            ),
            _buildStatCard(
              'Tecnicos',
              _stats['total_tecnicos'],
              Icons.engineering,
              const Color(0xFF27AE60),
            ),
            _buildStatCard(
              'Solicitudes',
              _stats['total_solicitudes'],
              Icons.assignment,
              const Color(0xFFF39C12),
            ),
            _buildStatCard(
              'Servicios',
              _stats['total_servicios'],
              Icons.build,
              const Color(0xFF9B59B6),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF98A1BC),
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rapidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF555879),
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Verificar Tecnicos',
                Icons.verified_user,
                const Color(0xFF27AE60),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminTechniciansPage(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Moderar Resenas',
                Icons.rate_review,
                const Color(0xFFF39C12),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminReviewsPage()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertas Pendientes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF555879),
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 16),
        _buildAlertItem(
          '${_stats['tecnicos_pendientes']} tecnicos esperando verificacion',
          Icons.engineering,
          const Color(0xFFF39C12),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminTechniciansPage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildAlertItem(
          '${_stats['resenas_pendientes']} resenas por moderar',
          Icons.rate_review,
          const Color(0xFF3498DB),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminReviewsPage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildAlertItem(
          '${_stats['solicitudes_activas']} solicitudes activas',
          Icons.assignment,
          const Color(0xFF27AE60),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminRequestsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem(
    String message,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF98A1BC), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF98A1BC),
            ),
          ],
        ),
      ),
    );
  }
}
