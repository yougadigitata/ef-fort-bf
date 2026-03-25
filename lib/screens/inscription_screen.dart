import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/logo_widget.dart';
import 'home_screen.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedNiveau = 'BAC';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _niveaux = ['CEP', 'BEPC', 'BAC', 'BAC+2', 'LICENCE', 'MASTER'];

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.inscription(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      telephone: _phoneController.text.trim(),
      niveau: _selectedNiveau,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _errorMessage = result['error'] as String? ?? 'Erreur lors de l\'inscription';
      });
    }
  }

  Widget _buildField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 6),
        field,
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  const LogoWidget(size: 90, borderRadius: 18),
                  const SizedBox(height: 20),
                  const Text(
                    'Creer mon compte',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rejoignez la communaute EF-FORT',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildField(
                    'Nom',
                    TextFormField(
                      controller: _nomController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                      decoration: const InputDecoration(
                        hintText: 'Ex: KONE',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  _buildField(
                    'Prenom',
                    TextFormField(
                      controller: _prenomController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                      decoration: const InputDecoration(
                        hintText: 'Ex: Seydou',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  _buildField(
                    'Numero de telephone',
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 8,
                      style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: '7X XX XX XX',
                        counterText: '',
                        prefixIcon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('+226', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                              Container(height: 20, width: 1, margin: const EdgeInsets.only(left: 6), color: AppColors.textLight.withValues(alpha: 0.3)),
                            ],
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requis';
                        final clean = ApiService.cleanPhone(value);
                        if (clean.length != 8) return '8 chiffres requis';
                        return null;
                      },
                    ),
                  ),
                  _buildField(
                    'Niveau d\'etude',
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedNiveau,
                        dropdownColor: AppColors.white,
                        style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        items: _niveaux.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                        onChanged: (v) => setState(() => _selectedNiveau = v!),
                      ),
                    ),
                  ),
                  _buildField(
                    'Mot de passe',
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Min. 6 caracteres',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (v.length < 6) return 'Min. 6 caracteres';
                        return null;
                      },
                    ),
                  ),
                  _buildField(
                    'Confirmer le mot de passe',
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Repetez le mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                        return null;
                      },
                    ),
                  ),
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _inscrire,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                          : const Text('CREER MON COMPTE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Deja un compte ? ', style: TextStyle(color: AppColors.white.withValues(alpha: 0.7), fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Se connecter', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
