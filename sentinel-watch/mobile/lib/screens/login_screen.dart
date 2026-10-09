import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService();

  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'Admin123!');
  final _fullNameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _serverController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _serverController.text = _apiService.baseUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _organizationController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final identifier = _usernameController.text.trim();
    final password = _passwordController.text;
    final serverUrl = _serverController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs obligatoires.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    Map<String, dynamic> result;
    if (_isRegisterMode) {
      result = await _apiService.register(
        identifier,
        '$identifier@sentinelwatch.com',
        password,
        fullName: _fullNameController.text.trim(),
        organization: _organizationController.text.trim().isNotEmpty ? _organizationController.text.trim() : null,
        serverUrl: serverUrl,
      );
    } else {
      result = await _apiService.login(identifier, password, serverUrl: serverUrl);
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = result['error'] ?? 'Échec de connexion';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Header
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),

                RichText(
                  text: const TextSpan(
                    text: 'Sentinel',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26, letterSpacing: 0.5),
                    children: [
                      TextSpan(text: 'Watch', style: TextStyle(color: Color(0xFF38BDF8))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Console d\'Intervention & Détection de Menaces SOC',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mode Selector (Connexion vs Inscription)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _isRegisterMode = false;
                                _errorMessage = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isRegisterMode ? const Color(0xFF1E293B) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Connexion',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !_isRegisterMode ? Colors.white : const Color(0xFF64748B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _isRegisterMode = true;
                                _errorMessage = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isRegisterMode ? const Color(0xFF1E293B) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Créer un Compte',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isRegisterMode ? Colors.white : const Color(0xFF64748B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Error message banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Server URL Field
                      const Text('ADRESSE DU SERVEUR SENTINELWATCH', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _serverController,
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.dns_rounded, color: Color(0xFF64748B), size: 18),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          hintText: 'http://192.168.1.38:8000/api/v1',
                          hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Full name and Organization if registering
                      if (_isRegisterMode) ...[
                        const Text('NOM COMPLET', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _fullNameController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF64748B), size: 18),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            hintText: 'Ex: Khaled - Administrateur',
                            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('NOM DE VOTRE ORGANISATION / ENTREPRISE', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _organizationController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF64748B), size: 18),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            hintText: 'Ex: Mon Entreprise SOC (Optionnel)',
                            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Username or Email
                      Text(
                        _isRegisterMode ? 'IDENTIFIANT / NOM D\'UTILISATEUR' : 'IDENTIFIANT OU EMAIL',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 18),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          hintText: 'admin',
                          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Password Field
                      const Text('MOT DE PASSE', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF64748B), size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: const Color(0xFF64748B),
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          hintText: '••••••••',
                          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_isRegisterMode ? Icons.person_add_rounded : Icons.login_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isRegisterMode ? 'Créer mon Accès SOC' : 'Se Connecter à la Console',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Demo credentials tip
                      Center(
                        child: Text(
                          'Compte Administrateur par défaut : admin / Admin123!',
                          style: TextStyle(color: const Color(0xFF38BDF8).withOpacity(0.8), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'SentinelWatch Entreprise v0.3 — Mobile Node',
                  style: TextStyle(color: Color(0xFF475569), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
