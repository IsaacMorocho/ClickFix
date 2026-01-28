import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_colors.dart';
import 'auth_service.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_input.dart';
import 'widgets/auth_layout.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  bool _showPasswordStrength = false;
  double _passwordStrength = 0.0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
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
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
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

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _loading = true);

      await _authService.updatePassword(_passwordCtrl.text.trim());

      if (mounted) {
        _showMessage('Contraseña actualizada correctamente');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Error al actualizar la contraseña');
    } finally {
      if (mounted) setState(() => _loading = false);
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
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(
                Icons.lock_reset,
                size: 70,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nueva contraseña',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tu nueva contraseña',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 32),
              AuthInput(
                controller: _passwordCtrl,
                label: 'Nueva contraseña',
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo no puede quedar vacio';
                  }
                  if (!(_hasMinLength && _hasNumber && _hasSymbol)) {
                    return 'La contraseña no cumple los requisitos';
                  }
                  return null;
                },
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
                  tween: Tween<double>(
                    begin: 0,
                    end: _passwordStrength,
                  ),
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
                    _PasswordCheck(
                      text: 'Contiene un numero',
                      checked: _hasNumber,
                    ),
                    _PasswordCheck(
                      text: 'Contiene un simbolo',
                      checked: _hasSymbol,
                    ),
                  ],
                ),
              ],
              AuthInput(
                controller: _confirmCtrl,
                label: 'Confirmar contraseña',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: (value) {
                  if (value != _passwordCtrl.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AuthButton(
                text: 'Actualizar contraseña',
                loading: _loading,
                onPressed: (_passwordStrength == 1.0 && !_loading)
                    ? _updatePassword
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordCheck extends StatelessWidget {
  final String text;
  final bool checked;

  const _PasswordCheck({
    required this.text,
    required this.checked,
  });

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
