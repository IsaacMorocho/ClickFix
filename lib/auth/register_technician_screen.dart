import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_colors.dart';
import 'auth_service.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_input.dart';
import 'widgets/auth_layout.dart';

class RegisterTechnicianScreen extends StatefulWidget {
  const RegisterTechnicianScreen({super.key});

  @override
  State<RegisterTechnicianScreen> createState() =>
      _RegisterTechnicianScreenState();
}

class _RegisterTechnicianScreenState extends State<RegisterTechnicianScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  final _nameCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _experienceCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();

  final _authService = AuthService();

  int _currentPage = 0;
  double _passwordStrength = 0.0;
  bool _obscurePassword = true;
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  bool _showPasswordStrength = false;
  bool _loading = false;
  bool _acceptedTerms = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _passwordCtrl.addListener(() {
      _onPasswordChanged(_passwordCtrl.text);
    });
    _animController.forward();
  }

  void _onPasswordChanged(String value) {
    setState(() {
      _showPasswordStrength = value.isNotEmpty;
      _hasMinLength = value.length >= 6;
      _hasNumber = RegExp(r'\d').hasMatch(value);
      _hasSymbol = RegExp(r'[-_!@#$%^&*(),.?":{}|<>]').hasMatch(value);

      int score = 0;
      if (_hasMinLength) score++;
      if (_hasNumber) score++;
      if (_hasSymbol) score++;

      _passwordStrength = score / 3;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    _nameCtrl.dispose();
    _cedulaCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _experienceCtrl.dispose();
    _descriptionCtrl.dispose();
    _rateCtrl.dispose();
    _zoneCtrl.dispose();
    super.dispose();
  }

  String get _passwordStrengthText {
    if (_passwordStrength < 0.34) {
      return 'Debil';
    } else if (_passwordStrength < 0.67) {
      return 'Media';
    } else {
      return 'Fuerte';
    }
  }

  Color get _passwordStrengthColor {
    if (_passwordStrength < 0.34) {
      return AppColors.error;
    } else if (_passwordStrength < 0.67) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (!_validatePage1()) return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage--);
  }

  bool _validatePage1() {
    final name = _nameCtrl.text.trim();
    final cedula = _cedulaCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || name.length < 3) {
      _showError('Ingresa un nombre valido');
      return false;
    }
    if (cedula.isEmpty || cedula.length < 8) {
      _showError('Ingresa una cedula valida');
      return false;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      _showError('El telefono debe tener 10 digitos');
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Correo electronico no valido');
      return false;
    }
    if (!(_hasMinLength && _hasNumber && _hasSymbol)) {
      _showError('La contrasena no cumple los requisitos');
      return false;
    }
    if (password != confirm) {
      _showError('Las contrasenas no coinciden');
      return false;
    }
    return true;
  }

  Future<void> _register() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      _showError('Debes aceptar los términos y condiciones para continuar');
      return;
    }

    final experience = int.tryParse(_experienceCtrl.text.trim());
    final rate = double.tryParse(_rateCtrl.text.trim());

    if (experience == null || experience < 0) {
      _showError('Ingresa anos de experiencia validos');
      return;
    }
    if (rate == null || rate <= 0) {
      _showError('Ingresa una tarifa valida');
      return;
    }
    if (_descriptionCtrl.text.trim().isEmpty) {
      _showError('Ingresa una descripcion profesional');
      return;
    }
    if (_zoneCtrl.text.trim().isEmpty) {
      _showError('Ingresa tu zona de cobertura');
      return;
    }

    try {
      setState(() => _loading = true);
      final email = _emailCtrl.text.trim().toLowerCase();

      await _authService.registerTechnician(
        email: email,
        password: _passwordCtrl.text.trim(),
        nombreCompleto: _nameCtrl.text.trim(),
        cedula: _cedulaCtrl.text.trim(),
        telefono: _phoneCtrl.text.trim(),
        aniosExperiencia: experience,
        descripcionProfesional: _descriptionCtrl.text.trim(),
        tarifaBase: rate,
        zonaCobertura: _zoneCtrl.text.trim(),
      );

      _showMessage(
        'Registro exitoso! Revisa tu correo para confirmar. Un administrador revisara tu perfil.',
      );

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on AuthException catch (e) {
      _handleAuthError(e.message);
    } catch (e) {
      _showError('Error al registrar usuario');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleAuthError(String message) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('already registered') ||
        lowerMessage.contains('user already registered') ||
        lowerMessage.contains('email already') ||
        lowerMessage.contains('already exists')) {
      _showError('Este correo ya esta registrado');
    } else if (lowerMessage.contains('password should be') ||
        lowerMessage.contains('password is too weak')) {
      _showError('La contrasena es muy debil');
    } else if (lowerMessage.contains('invalid email')) {
      _showError('El correo electronico no es valido');
    } else {
      _showError(message);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: '',
      showBackButton: true,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.build, size: 60, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Registro de Tecnico',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentPage == 0
                    ? 'Paso 1: Datos personales'
                    : 'Paso 2: Datos profesionales',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepIndicator(isActive: _currentPage >= 0, step: 1),
                  Container(
                    width: 40,
                    height: 2,
                    color: _currentPage >= 1
                        ? AppColors.primary
                        : AppColors.secondary.withOpacity(0.3),
                  ),
                  _StepIndicator(isActive: _currentPage >= 1, step: 2),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 480,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_buildPage1(), _buildPage2()],
                ),
              ),
              const SizedBox(height: 16),
              if (_currentPage == 0)
                AuthButton(text: 'Siguiente', onPressed: _nextPage)
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Atras'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AuthButton(
                        text: 'Registrarme',
                        loading: _loading,
                        onPressed: _register,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Ya tienes cuenta? Inicia sesion'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AuthInput(
            controller: _nameCtrl,
            label: 'Nombre completo',
            prefixIcon: Icons.person_outline,
          ),
          AuthInput(
            controller: _cedulaCtrl,
            label: 'Cedula',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
          ),
          AuthInput(
            controller: _phoneCtrl,
            label: 'Telefono',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          AuthInput(
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            controller: _emailCtrl,
            label: 'Correo electronico',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          AuthInput(
            controller: _passwordCtrl,
            label: 'Contrasena',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            keyboardType: TextInputType.visiblePassword,
          ),
          if (_showPasswordStrength) ...[
            const SizedBox(height: 6),
            Text(
              _passwordStrengthText,
              style: TextStyle(
                color: _passwordStrengthColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: _passwordStrength),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: AppColors.secondary.withOpacity(0.3),
                  color: _passwordStrengthColor,
                );
              },
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PasswordCheck(
                  text: 'Minimo 6 caracteres',
                  checked: _hasMinLength,
                ),
                _PasswordCheck(text: 'Contiene un numero', checked: _hasNumber),
                _PasswordCheck(
                  text: 'Contiene un simbolo',
                  checked: _hasSymbol,
                ),
              ],
            ),
          ],
          AuthInput(
            controller: _confirmCtrl,
            label: 'Confirmar contrasena',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AuthInput(
            controller: _experienceCtrl,
            label: 'Anos de experiencia',
            prefixIcon: Icons.work_history,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es requerido';
              }
              final exp = int.tryParse(value);
              if (exp == null || exp < 0) {
                return 'Ingresa un numero valido';
              }
              return null;
            },
          ),
          AuthInput(
            controller: _descriptionCtrl,
            label: 'Descripcion profesional',
            prefixIcon: Icons.description,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es requerido';
              }
              return null;
            },
          ),
          AuthInput(
            controller: _rateCtrl,
            label: 'Tarifa base por hora (\$)',
            prefixIcon: Icons.attach_money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es requerido';
              }
              final rate = double.tryParse(value);
              if (rate == null || rate <= 0) {
                return 'Ingresa una tarifa valida';
              }
              return null;
            },
          ),
          AuthInput(
            controller: _zoneCtrl,
            label: 'Zona de cobertura',
            prefixIcon: Icons.location_on,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Términos y condiciones para técnicos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Normas de uso importante',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• No se permite contactar a clientes fuera de la aplicación para realizar trabajos.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Todos los servicios deben coordinarse exclusivamente a través de ClickFix.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Contactar clientes por fuera puede resultar en la suspensión de tu cuenta.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Debes cumplir con los estándares de calidad y puntualidad acordados.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    setState(() => _acceptedTerms = !_acceptedTerms);
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _acceptedTerms,
                          onChanged: (value) {
                            setState(() => _acceptedTerms = value ?? false);
                          },
                          activeColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'He leído y acepto estas normas de uso',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Despues del registro, un administrador revisara tu perfil y certificados antes de aprobar tu cuenta.',
                    style: TextStyle(fontSize: 13, color: AppColors.textDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final bool isActive;
  final int step;

  const _StepIndicator({required this.isActive, required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : AppColors.secondary.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? AppColors.textLight : AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _PasswordCheck extends StatelessWidget {
  final String text;
  final bool checked;

  const _PasswordCheck({required this.text, required this.checked});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          checked ? Icons.check_circle : Icons.radio_button_unchecked,
          color: checked ? AppColors.success : AppColors.secondary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: checked ? AppColors.success : AppColors.secondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
