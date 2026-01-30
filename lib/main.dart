import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

import 'auth/login_screen.dart';
import 'services/onesignal_service.dart';
import 'auth/reset_password_screen.dart';
import 'core/app_colors.dart';
import 'core/animations/page_transitions.dart';
import 'splash/splash_screen.dart';
import 'screens/location_permission/location_permission_page.dart';
import 'services/database_service.dart';

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
import 'screens/clients_map/clients_map_page.dart';
import 'screens/service_tracking/service_tracking_page.dart';
import 'screens/favorite_technicians/favorite_technicians_page.dart';
import 'screens/technician_filter/technician_filter_page.dart';
import 'screens/bidirectional_rating/rate_technician_page.dart';
import 'screens/bidirectional_rating/rate_client_page.dart';
import 'screens/technician_work_history/technician_work_history_page.dart';
import 'screens/price_calculator/price_calculator_page.dart';
import 'screens/service_arrival/service_arrival_page.dart';

bool isManualLogin = false;
String? pendingConfirmationMessage;

// GlobalKey para navegación desde deep links
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('No se pudo cargar el archivo .env: $e');
  }

  // Inicializar Supabase
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      debugPrint('✅ Supabase inicializado correctamente');
    } else {
      debugPrint('⚠️ Variables de Supabase no configuradas en .env');
    }
  } catch (e) {
    debugPrint('❌ Error al inicializar Supabase: $e');
  }

  // Inicializar OneSignal para notificaciones
  await OneSignalService.initialize();

  // Inicializar listener de Deep Links
  _initDeepLinks();

  runApp(const MyApp());
}

/// Configurar listener de deep links para recuperación de contraseña
void _initDeepLinks() {
  final appLinks = AppLinks();

  // Escuchar deep links entrantes
  appLinks.uriLinkStream.listen(
    (Uri uri) {
      debugPrint('🔗 Deep link recibido: $uri');

      // Verificar si es un link de reset password
      if (uri.host == 'reset-password' || uri.path.contains('reset-password')) {
        // Extraer el access_token del fragment o query
        final token = uri.fragment.isNotEmpty
            ? Uri.parse('?${uri.fragment}').queryParameters['access_token']
            : uri.queryParameters['access_token'];

        if (token != null) {
          debugPrint('✅ Token de reset encontrado');

          // Navegar a la pantalla de reset password
          Future.delayed(const Duration(milliseconds: 500), () {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const ResetPasswordScreen(),
              ),
            );
          });
        } else {
          debugPrint('⚠️ No se encontró token en el deep link');
        }
      }
    },
    onError: (error) {
      debugPrint('❌ Error en deep link: $error');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ⬅️ Agregar el GlobalKey
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
        // Configuración de transiciones de página por defecto
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: SplashScreen(nextScreen: const AuthGate()),
      // Generador de rutas personalizado para animaciones
      onGenerateRoute: (settings) {
        // Determinar el tipo de transición según la ruta
        PageTransitionType transitionType;
        Widget page;

        switch (settings.name) {
          case '/notifications':
            transitionType = PageTransitionType.slideDown;
            page = const NotificationsPage();
            break;
          case '/userProfile':
            transitionType = PageTransitionType.fadeScale;
            page = const UserProfilePage();
            break;
          case '/technicianProfile':
            transitionType = PageTransitionType.fadeScale;
            page = const TechnicianProfilePage();
            break;
          case '/serviceRequestCreate':
            transitionType = PageTransitionType.slideUp;
            page = const ServiceRequestCreatePage();
            break;
          case '/serviceRequests':
            transitionType = PageTransitionType.slideLeft;
            page = const ServiceRequestsListPage();
            break;
          case '/serviceInProgress':
            transitionType = PageTransitionType.slideLeft;
            page = const ServiceInProgressPage();
            break;
          case '/serviceHistory':
            transitionType = PageTransitionType.slideLeft;
            page = const ServiceHistoryPage();
            break;
          case '/technicianSpecialties':
            transitionType = PageTransitionType.fadeScale;
            page = const TechnicianSpecialtiesPage();
            break;
          case '/technicianCertificates':
            transitionType = PageTransitionType.fadeScale;
            page = const TechnicianCertificatesPage();
            break;
          case '/availableRequests':
            transitionType = PageTransitionType.slideLeft;
            page = const AvailableRequestsPage();
            break;
          case '/myQuotations':
            transitionType = PageTransitionType.slideLeft;
            page = const MyQuotationsPage();
            break;
          case '/assignedServices':
            transitionType = PageTransitionType.slideLeft;
            page = const AssignedServicesPage();
            break;
          case '/receivedReviews':
            transitionType = PageTransitionType.slideLeft;
            page = const ReceivedReviewsPage();
            break;
          case '/adminDashboard':
            transitionType = PageTransitionType.fadeScale;
            page = const AdminDashboardPage();
            break;
          case '/adminUsers':
            transitionType = PageTransitionType.slideLeft;
            page = const AdminUsersPage();
            break;
          case '/adminTechnicians':
            transitionType = PageTransitionType.slideLeft;
            page = const AdminTechniciansPage();
            break;
          case '/adminSpecialties':
            transitionType = PageTransitionType.slideLeft;
            page = const AdminSpecialtiesPage();
            break;
          case '/adminRequests':
            transitionType = PageTransitionType.slideLeft;
            page = const AdminRequestsPage();
            break;
          case '/adminServices':
            transitionType = PageTransitionType.slideLeft;
            page = const AdminServicesPage();
            break;
          case '/adminReviews':
            transitionType = PageTransitionType.slideLeft;
            page = const AdminReviewsPage();
            break;
          case '/clientsMap':
            transitionType = PageTransitionType.fadeScale;
            page = const ClientsMapPage();
            break;
          case '/serviceTracking':
            transitionType = PageTransitionType.slideLeft;
            final args = settings.arguments as Map<String, dynamic>?;
            page = ServiceTrackingPage(
              serviceId: args?['serviceId'] ?? '',
              requestTitle: args?['requestTitle'] ?? 'Servicio',
            );
            break;
          case '/favoriteTechnicians':
            transitionType = PageTransitionType.slideLeft;
            page = const FavoriteTechniciansPage();
            break;
          case '/technicianFilter':
            transitionType = PageTransitionType.slideUp;
            page = const TechnicianFilterPage();
            break;
          case '/rateTechnician':
            transitionType = PageTransitionType.slideUp;
            final args = settings.arguments as Map<String, dynamic>?;
            page = RateTechnicianPage(
              serviceId: args?['serviceId'] ?? '',
              technicianId: args?['technicianId'] ?? '',
              technicianName: args?['technicianName'] ?? 'Técnico',
              technicianPhoto: args?['technicianPhoto'],
            );
            break;
          case '/rateClient':
            transitionType = PageTransitionType.slideUp;
            final args = settings.arguments as Map<String, dynamic>?;
            page = RateClientPage(
              serviceId: args?['serviceId'] ?? '',
              clientId: args?['clientId'] ?? '',
              clientName: args?['clientName'] ?? 'Cliente',
            );
            break;
          case '/technicianWorkHistory':
            transitionType = PageTransitionType.slideLeft;
            page = const TechnicianWorkHistoryPage();
            break;
          case '/priceCalculator':
            transitionType = PageTransitionType.slideUp;
            final args = settings.arguments as Map<String, dynamic>?;
            page = PriceCalculatorPage(
              serviceRequestId: args?['serviceRequestId'] ?? '',
              serviceType: args?['serviceType'] ?? 'General',
              clientZone: args?['clientZone'],
            );
            break;
          case '/serviceArrival':
            transitionType = PageTransitionType.slideLeft;
            final args = settings.arguments as Map<String, dynamic>?;
            page = ServiceArrivalPage(
              serviceId: args?['serviceId'] ?? '',
              clientName: args?['clientName'] ?? 'Cliente',
              address: args?['address'] ?? 'Sin dirección',
            );
            break;
          default:
            return null;
        }

        return CustomPageTransition(
          page: page,
          type: transitionType,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
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
  bool _isLoading = false;
  String? _userRole;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    setState(() => _isLoading = true);

    try {
      // Verificar si hay sesión activa en Supabase
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        // Hay sesión activa, obtener rol del usuario
        final userId = session.user.id;
        DatabaseService.setCurrentUserId(userId);

        final profile = await DatabaseService.getCurrentUserProfile();
        final role = profile?['rol'] as String?;

        if (mounted) {
          setState(() {
            _userRole = role;
            _isLoggedIn = true;
            _isLoading = false;
          });
        }
      } else {
        // No hay sesión
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoggedIn = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error al verificar sesión: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = false;
        });
      }
    }
  }

  Future<void> _handleLoginSuccess(String role) async {
    // El login real ya se hizo en LoginScreen con Supabase
    // Solo actualizamos el estado local
    if (mounted) {
      setState(() {
        _userRole = role;
        _isLoggedIn = true;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      DatabaseService.setCurrentUserId(null);

      if (mounted) {
        setState(() {
          _userRole = null;
          _isLoggedIn = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showResetPassword) {
      return const ResetPasswordScreen();
    }

    // Si no hay sesión, mostrar pantalla de login
    if (!_isLoggedIn) {
      final msg = pendingConfirmationMessage;
      pendingConfirmationMessage = null;
      return LoginScreen(
        confirmationMessage: msg,
        onLoginSuccess: (String role) {
          _handleLoginSuccess(role);
        },
      );
    }

    // Mostrar loading mientras se carga
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4EBD3),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF555879)),
        ),
      );
    }

    // Si no hay rol definido, mostrar loading
    if (_userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rol = _userRole!;

    // Navegar según el rol
    if (rol == 'admin') {
      return AdminDashboardPage(onLogout: _handleLogout);
    } else if (rol == 'tecnico') {
      return TechnicianDashboard(onLogout: _handleLogout);
    } else {
      return ClientDashboard(onLogout: _handleLogout);
    }
  }
}

class ClientDashboard extends StatefulWidget {
  final VoidCallback onLogout;

  const ClientDashboard({super.key, required this.onLogout});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  bool _checkingPermission = true;
  bool _showPermissionPage = false;
  String _userName = 'Usuario';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // TODO: Cargar datos del usuario desde el nuevo backend
    final profile = await DatabaseService.getCurrentUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _userName = profile['nombre_completo'] ?? 'Usuario';
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAskedPermission =
        prefs.getBool('location_permission_asked') ?? false;

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

    return Scaffold(
      backgroundColor: const Color(0xFFF4EBD3),
      appBar: AppBar(
        title: const Text(
          'ClickFix',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF555879),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
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
                    child: Icon(
                      Icons.person,
                      size: 35,
                      color: Color(0xFF555879),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $_userName!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const Text(
                          'Que necesitas reparar hoy?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Montserrat',
                          ),
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

  Widget _buildMenuCard(
    BuildContext context, {
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

class TechnicianDashboard extends StatefulWidget {
  final VoidCallback onLogout;

  const TechnicianDashboard({super.key, required this.onLogout});

  @override
  State<TechnicianDashboard> createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard>
    with SingleTickerProviderStateMixin {
  String _userName = 'Tecnico';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // TODO: Cargar datos del técnico desde el nuevo backend
    final profile = await DatabaseService.getCurrentUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _userName = profile['nombre_completo'] ?? 'Tecnico';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EBD3),
      appBar: AppBar(
        title: const Text(
          'ClickFix Tecnico',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF555879),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeScaleAnimation(
              duration: const Duration(milliseconds: 600),
              child: Container(
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
                      child: Icon(
                        Icons.engineering,
                        size: 35,
                        color: Color(0xFF555879),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, $_userName!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const Text(
                            'Panel de tecnico',
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SlideFadeAnimation(
              delay: const Duration(milliseconds: 200),
              offset: const Offset(-0.2, 0),
              child: const Text(
                'Buscar trabajo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
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
              index: 0,
            ),
            _buildMenuCard(
              context,
              icon: Icons.map,
              title: 'Mapa de Clientes',
              subtitle: 'Ver ubicación de clientes activos',
              route: '/clientsMap',
              color: const Color(0xFF16A085),
              index: 1,
            ),
            _buildMenuCard(
              context,
              icon: Icons.request_quote,
              title: 'Mis Cotizaciones',
              subtitle: 'Cotizaciones enviadas',
              route: '/myQuotations',
              color: const Color(0xFF3498DB),
              index: 2,
            ),
            const SizedBox(height: 16),
            SlideFadeAnimation(
              delay: const Duration(milliseconds: 500),
              offset: const Offset(-0.2, 0),
              child: const Text(
                'Mis servicios',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
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
              index: 3,
            ),
            _buildMenuCard(
              context,
              icon: Icons.star,
              title: 'Mis Resenas',
              subtitle: 'Ver calificaciones recibidas',
              route: '/receivedReviews',
              color: const Color(0xFF9B59B6),
              index: 4,
            ),
            const SizedBox(height: 16),
            SlideFadeAnimation(
              delay: const Duration(milliseconds: 700),
              offset: const Offset(-0.2, 0),
              child: const Text(
                'Mi perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
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
              index: 5,
            ),
            _buildMenuCard(
              context,
              icon: Icons.category,
              title: 'Mis Especialidades',
              subtitle: 'Gestionar especialidades',
              route: '/technicianSpecialties',
              color: const Color(0xFF1ABC9C),
              index: 6,
            ),
            _buildMenuCard(
              context,
              icon: Icons.workspace_premium,
              title: 'Mis Certificados',
              subtitle: 'Subir certificaciones',
              route: '/technicianCertificates',
              color: const Color(0xFFE74C3C),
              index: 7,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required Color color,
    required int index,
  }) {
    return SlideFadeAnimation(
      delay: Duration(milliseconds: 300 + (index * 50)),
      offset: const Offset(0.3, 0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
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
                  Hero(
                    tag: 'icon_$route',
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
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
      ),
    );
  }
}
