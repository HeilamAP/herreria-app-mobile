import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedSection = 'admin'; // 'admin' | 'equipo1' | 'equipo2'

  @override
  void initState() {
    super.initState();
    _selectSection('admin');
  }

  void _selectSection(String section) {
    setState(() {
      _selectedSection = section;
      if (section == 'admin') {
        _usernameController.text = 'heilamay';
        _passwordController.text = 'admin123';
      } else if (section == 'equipo1') {
        _usernameController.text = 'joseay';
        _passwordController.text = '1234';
      } else if (section == 'equipo2') {
        _usernameController.text = 'nefydzul';
        _passwordController.text = '1234';
      }
    });
  }

  void _handleLogin() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final success = auth.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
      onError: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppTheme.dangerRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido, ${auth.currentUser?.nombre}!'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1325),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryCyan, width: 1.5),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.door_sliding_outlined,
                              size: 20,
                              color: AppTheme.primaryCyan,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AY OY',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryCyan,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            'Herrería Artística en General',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryCyan),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline, size: 14, color: AppTheme.primaryCyan),
                        SizedBox(width: 6),
                        Text(
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Main Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Main Circular Logo with Cyan Glow Ring
                        Container(
                          width: 110,
                          height: 110,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0F172A),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryCyan.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                            border: Border.all(color: AppTheme.primaryCyan, width: 2.5),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.door_sliding_outlined,
                                size: 55,
                                color: AppTheme.primaryCyan,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Main Title & Subtitle (AY OY Large)
                        Text(
                          'AY OY',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Herrería Artística en General',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFCBD5E1),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Section Selector Title
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'SELECCIONE SU SECCIÓN DE TRABAJO:',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 3 Segmented Section Tabs
                        Row(
                          children: [
                            _buildSectionTab(
                              id: 'admin',
                              label: 'Administrador',
                              icon: Icons.shield_outlined,
                            ),
                            const SizedBox(width: 8),
                            _buildSectionTab(
                              id: 'equipo1',
                              label: 'Equipo 1',
                              icon: Icons.home_repair_service_outlined,
                            ),
                            const SizedBox(width: 8),
                            _buildSectionTab(
                              id: 'equipo2',
                              label: 'Equipo 2',
                              icon: Icons.home_repair_service_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Dynamic Access Form Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131C31),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryCyan.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card Header Title
                              Row(
                                children: [
                                  Icon(
                                    _getSectionIcon(),
                                    color: AppTheme.primaryCyan,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _getSectionTitle(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getSectionSubtitle(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Username Input
                              Text(
                                _getUsernameLabel(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _usernameController,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  fillColor: const Color(0xFF1E293B),
                                  filled: true,
                                  hintText: 'Ingrese usuario',
                                  prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryCyan, size: 20),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF334155)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF334155)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.primaryCyan),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password Input
                              Text(
                                'Contraseña',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  fillColor: const Color(0xFF1E293B),
                                  filled: true,
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryCyan, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: const Color(0xFF94A3B8),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF334155)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF334155)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.primaryCyan),
                                  ),
                                ),
                                onSubmitted: (_) => _handleLogin(),
                              ),
                              const SizedBox(height: 24),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryCyan,
                                    foregroundColor: const Color(0xFF0F172A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.login, size: 20, color: Color(0xFF0F172A)),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getSubmitButtonText(),
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTab({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedSection == id;

    return Expanded(
      child: InkWell(
        onTap: () => _selectSection(id),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryCyan.withValues(alpha: 0.18) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryCyan : const Color(0xFF334155),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryCyan : const Color(0xFF94A3B8),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSectionIcon() {
    switch (_selectedSection) {
      case 'equipo1':
      case 'equipo2':
        return Icons.home_repair_service_outlined;
      default:
        return Icons.shield_outlined;
    }
  }

  String _getSectionTitle() {
    switch (_selectedSection) {
      case 'equipo1':
        return 'Acceso Equipo 1 (Jose Ay)';
      case 'equipo2':
        return 'Acceso Equipo 2 (Nefy Dzul)';
      default:
        return 'Acceso Administrador';
    }
  }

  String _getSectionSubtitle() {
    switch (_selectedSection) {
      case 'equipo1':
        return 'Trabajos, Instalaciones y Comprobantes de Equipo 1';
      case 'equipo2':
        return 'Trabajos, Instalaciones y Comprobantes de Equipo 2';
      default:
        return 'Gestión Financiera, Nómina y Administración General';
    }
  }

  String _getUsernameLabel() {
    switch (_selectedSection) {
      case 'equipo1':
        return 'Usuario (Equipo 1)';
      case 'equipo2':
        return 'Usuario (Equipo 2)';
      default:
        return 'Usuario (Acceso Administrador)';
    }
  }

  String _getSubmitButtonText() {
    switch (_selectedSection) {
      case 'equipo1':
        return 'INGRESAR COMO EQUIPO 1';
      case 'equipo2':
        return 'INGRESAR COMO EQUIPO 2';
      default:
        return 'INGRESAR COMO ADMIN';
    }
  }
}
