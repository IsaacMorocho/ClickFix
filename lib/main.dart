import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/login_screen.dart';
import 'services/onesignal_service.dart';
import 'auth/reset_password_screen.dart';
import 'core/app_colors.dart';
import 'splash/splash_screen.dart';
import 'screens/location_permission/location_permission_page.dart';

import 'screens/user_profile/user_profile_page.dart';
import 'screens/technician_profile/technician_profile_page.dart';
import 'screens/notifications/notifications_page.dart';
import 'screens/service_request_create/service_request_create_page.dart';
import 'screens/service_requests/service_requests_list_page.dart';
import 'screens/services/services_in_progress_page.dart';
import 'screens/service_history/service_history_page.dart';
import 'screens/technician_specialties/technician_specialties_page.dart';
import 'screens/technician_certificates/technician_certificates_page.dart';
import 'screens/available_requests/available_requests_page.dart';
import 'screens/my_quotations/my_quotations_page.dart';
import 'screens/assigned_services/assigned_services_page.dart';
import 'screens/received_reviews/received_reviews_page.dart';
import 'screens/admin/admin_dashboard_page.dart';
import 'screens/admin/admin_users_page.dart';
import 'screens/admin/admin_technicians_page.dart';
import 'screens/admin/admin_specialties_page.dart';
import 'screens/admin/admin_requests_page.dart';
import 'screens/admin/admin_services_page.dart';
import 'screens/admin/admin_reviews_page.dart';

bool isManualLogin = false;
String? pendingConfirmationMessage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    debug: false,
  );
  
  await OneSignalService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClickFix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.background,
        ),
      ),
      home: SplashScreen(nextScreen: const AuthGate()),
      routes: {
        '/notifications': (context) => const NotificationsPage(),
        '/userProfile': (context) => const UserProfilePage(),
        '/technicianProfile': (context) => const TechnicianProfilePage(),
        '/serviceRequestCreate': (context) => const ServiceRequestCreatePage(),
        '/serviceRequests': (context) => const ServiceRequestsListPage(),
        '/serviceInProgress': (context) => const ServiceInProgressPage(),
        '/serviceHistory': (context) => const ServiceHistoryPage(),
        '/technicianSpecialties': (context) => const TechnicianSpecialtiesPage(),
        '/technicianCertificates': (context) => const TechnicianCertificatesPage(),
        '/availableRequests': (context) => const AvailableRequestsPage(),
        '/myQuotations': (context) => const MyQuotationsPage(),
        '/assignedServices': (context) => const AssignedServicesPage(),
        '/receivedReviews': (context) => const ReceivedReviewsPage(),
        '/adminDashboard': (context) => const AdminDashboardPage(),
        '/adminUsers': (context) => const AdminUsersPage(),
        '/adminTechnicians': (context) => const AdminTechniciansPage(),
        '/adminSpecialties': (context) => const AdminSpecialtiesPage(),
        '/adminRequests': (context) => const AdminRequestsPage(),
        '/adminServices': (context) => const AdminServicesPage(),
        '/adminReviews': (context) => const AdminReviewsPage(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showResetPassword = false;
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();

    //Si ya hay sesion cargar rol
    final session = Supabase.instance.client.auth.currentSession;
    if (session?.user != null) {
      _loadUserRole();
    } else {
      _isLoading = false;
    }
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.passwordRecovery) {
        setState(() => _showResetPassword = true);
        return;
      }

      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        if (mounted) {
          setState(() => _isLoading = true);
        }

        await OneSignalService.setUserId(session!.user.id);
        await _loadUserRole();

        if (_userRole != null) {
          await OneSignalService.setUserTags({'rol': _userRole!});
        }

        isManualLogin = false;
      }

      if (event == AuthChangeEvent.signedOut) {
        await OneSignalService.removeUserId();
        _userRole = null;
        _isLoading = true;
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _loadUserRole() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    if (mounted) setState(() => _isLoading = false);
    return;
  }

  try {
    debugPrint('AUTH UID: ${user.id}');
    debugPrint('EMAIL: ${user.email}');

    final response = await Supabase.instance.client
        .from('users')
        .select('rol')
        .eq('id', user.id)
        .maybeSingle();

    debugPrint('RESPUESTA USERS: $response');

    if (response == null) {
      debugPrint('❌ No existe fila en users para este UID');
      if (mounted) {
        setState(() {
          _userRole = null;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _userRole = response['rol'];
        _isLoading = false;
      });
    }
  } catch (e, st) {
    debugPrint('ERROR cargando rol: $e');
    debugPrint('$st');

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    if (_showResetPassword) {
      return const ResetPasswordScreen();
    }

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      final msg = pendingConfirmationMessage;
      pendingConfirmationMessage = null;
      return LoginScreen(confirmationMessage: msg);
    }

    // Mostrar loading mientras se carga el rol
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4EBD3),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF555879)),
        ),
      );
    }

    if (_userRole == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final rol = _userRole!;

    if (rol == 'admin') {
      return const AdminDashboardPage();
    } else if (rol == 'tecnico') {
      return const TechnicianDashboard();
    } else {
      return const ClientDashboard();
    }
  }
}

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  bool _checkingPermission = true;
  bool _showPermissionPage = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAskedPermission = prefs.getBool('location_permission_asked') ?? false;
    
    if (!hasAskedPermission) {
      if (mounted) {
        setState(() {
          _showPermissionPage = true;
          _checkingPermission = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _checkingPermission = false;
        });
      }
    }
  }

  Future<void> _onPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_permission_asked', true);
    await prefs.setBool('location_permission_granted', true);
    if (mounted) {
      setState(() {
        _showPermissionPage = false;
      });
    }
  }

  Future<void> _onPermissionDenied() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_permission_asked', true);
    await prefs.setBool('location_permission_granted', false);
    if (mounted) {
      setState(() {
        _showPermissionPage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermission) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4EBD3),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF555879)),
        ),
      );
    }

    if (_showPermissionPage) {
      return LocationPermissionPage(
        onPermissionGranted: _onPermissionGranted,
        onPermissionDenied: _onPermissionDenied,
      );
    }

    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final nombre = metadata?['nombre_completo'] ?? 'Usuario';

    return Scaffold(
      backgroundColor: const Color(0xFFF4EBD3),
      appBar: AppBar(
        title: const Text(
          'ClickFix',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF555879),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF555879), Color(0xFF98A1BC)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Color(0xFF555879)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $nombre!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const Text(
                          'Que necesitas reparar hoy?',
                          style: TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Acciones rapidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF555879),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context,
              icon: Icons.add_circle,
              title: 'Nueva Solicitud',
              subtitle: 'Solicita un servicio tecnico',
              route: '/serviceRequestCreate',
              color: const Color(0xFF27AE60),
            ),
            _buildMenuCard(
              context,
              icon: Icons.list_alt,
              title: 'Mis Solicitudes',
              subtitle: 'Ver estado de tus solicitudes',
              route: '/serviceRequests',
              color: const Color(0xFF3498DB),
            ),
            _buildMenuCard(
              context,
              icon: Icons.build,
              title: 'Servicios en Progreso',
              subtitle: 'Seguimiento en tiempo real',
              route: '/serviceInProgress',
              color: const Color(0xFFF39C12),
            ),
            _buildMenuCard(
              context,
              icon: Icons.history,
              title: 'Historial',
              subtitle: 'Servicios completados',
              route: '/serviceHistory',
              color: const Color(0xFF9B59B6),
            ),
            _buildMenuCard(
              context,
              icon: Icons.person,
              title: 'Mi Perfil',
              subtitle: 'Editar datos personales',
              route: '/userProfile',
              color: const Color(0xFF555879),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF98A1BC)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF555879),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF98A1BC),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF98A1BC)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TechnicianDashboard extends StatelessWidget {
  const TechnicianDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final nombre = metadata?['nombre_completo'] ?? 'Tecnico';

    return Scaffold(
      backgroundColor: const Color(0xFFF4EBD3),
      appBar: AppBar(
        title: const Text(
          'ClickFix Tecnico',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF555879),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF555879), Color(0xFF98A1BC)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.engineering, size: 35, color: Color(0xFF555879)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $nombre!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const Text(
                          'Panel de tecnico',
                          style: TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Buscar trabajo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF555879),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context,
              icon: Icons.search,
              title: 'Solicitudes Disponibles',
              subtitle: 'Encuentra nuevos trabajos',
              route: '/availableRequests',
              color: const Color(0xFF27AE60),
            ),
            _buildMenuCard(
              context,
              icon: Icons.request_quote,
              title: 'Mis Cotizaciones',
              subtitle: 'Cotizaciones enviadas',
              route: '/myQuotations',
              color: const Color(0xFF3498DB),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mis servicios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF555879),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context,
              icon: Icons.assignment,
              title: 'Servicios Asignados',
              subtitle: 'Trabajos pendientes',
              route: '/assignedServices',
              color: const Color(0xFFF39C12),
            ),
            _buildMenuCard(
              context,
              icon: Icons.star,
              title: 'Mis Resenas',
              subtitle: 'Ver calificaciones recibidas',
              route: '/receivedReviews',
              color: const Color(0xFF9B59B6),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mi perfil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF555879),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              context,
              icon: Icons.person,
              title: 'Perfil Tecnico',
              subtitle: 'Editar datos profesionales',
              route: '/technicianProfile',
              color: const Color(0xFF555879),
            ),
            _buildMenuCard(
              context,
              icon: Icons.category,
              title: 'Mis Especialidades',
              subtitle: 'Gestionar especialidades',
              route: '/technicianSpecialties',
              color: const Color(0xFF1ABC9C),
            ),
            _buildMenuCard(
              context,
              icon: Icons.workspace_premium,
              title: 'Mis Certificados',
              subtitle: 'Subir certificaciones',
              route: '/technicianCertificates',
              color: const Color(0xFFE74C3C),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF98A1BC)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF555879),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF98A1BC),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF98A1BC)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
