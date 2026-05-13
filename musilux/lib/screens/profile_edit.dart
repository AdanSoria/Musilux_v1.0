import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_constants.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../widgets/shared_components.dart';

class ProfileEditScreen extends StatefulWidget {
  final AuthUser? currentUser;

  const ProfileEditScreen({super.key, this.currentUser});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  // Controllers para contraseña
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Controllers para dirección
  final _direccionController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _municipioController = TextEditingController();
  final _codigoPostalController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _direccionController.dispose();
    _departamentoController.dispose();
    _municipioController.dispose();
    _codigoPostalController.dispose();
    super.dispose();
  }

  Future<void> _cambiarContrasena() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Por favor completa todos los campos de contraseña.';
        _successMessage = null;
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Las contraseñas nuevas no coinciden.';
        _successMessage = null;
      });
      return;
    }

    if (_newPasswordController.text.length < 6) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'La nueva contraseña debe tener al menos 6 caracteres.';
        _successMessage = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Sesión expirada. Por favor inicia sesión de nuevo.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/usuario/cambiar-contrasena'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'contrasena_actual': _currentPasswordController.text,
          'contrasena_nueva': _newPasswordController.text,
          'contrasena_confirmacion': _confirmPasswordController.text,
        }),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _successMessage = 'Contraseña actualizada correctamente.';
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _errorMessage =
              data['message'] ?? 'Error al cambiar la contraseña.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Editar Perfil',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.headerBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Actualiza tu información personal y contraseña',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 30),

                    // Mensajes de éxito y error
                    if (_successMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          _successMessage!,
                          style:
                              TextStyle(color: Colors.green.shade700, fontSize: 13),
                        ),
                      ),
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),

                    // ===== SECCIÓN: CAMBIAR CONTRASEÑA =====
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lock_outlined,
                                  color: AppColors.primaryPurple),
                              SizedBox(width: 10),
                              Text(
                                'Cambiar Contraseña',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.headerBg,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            'Contraseña Actual',
                            _currentPasswordController,
                            _obscureCurrentPassword,
                            (value) => setState(
                                () => _obscureCurrentPassword = value),
                          ),
                          const SizedBox(height: 12),
                          _buildPasswordField(
                            'Nueva Contraseña',
                            _newPasswordController,
                            _obscureNewPassword,
                            (value) => setState(() => _obscureNewPassword = value),
                          ),
                          const SizedBox(height: 12),
                          _buildPasswordField(
                            'Confirmar Nueva Contraseña',
                            _confirmPasswordController,
                            _obscureConfirmPassword,
                            (value) => setState(
                                () => _obscureConfirmPassword = value),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _cambiarContrasena,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPurple,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Actualizar Contraseña',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    IconData? icon,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryPurple),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    Function(bool) onToggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryPurple),
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: () => onToggle(!obscure),
        ),
      ),
    );
  }
}
