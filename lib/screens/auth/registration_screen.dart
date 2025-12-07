import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:health_app/screens/auth/auth_service.dart';
import 'package:health_app/services/api_service.dart';
import 'package:health_app/constants/constants.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 🚀 ОНОВЛЕНО: Контролери для лікаря
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();

  UserRole _selectedRole = UserRole.patient;
  String? _selectedSpecialization;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bioController.dispose();
    _addressController.dispose(); // Не забуваємо
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Icon(Icons.local_hospital, size: 80, color: primaryTeal),
              const SizedBox(height: 20),
              Text(
                'Create account',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- Вибір Ролі ---
              SegmentedButton<UserRole>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: primaryTeal.withOpacity(0.1),
                  selectedForegroundColor: primaryTeal,
                ),
                segments: const [
                  ButtonSegment<UserRole>(
                    value: UserRole.patient,
                    label: Text('Patient'),
                    icon: Icon(Icons.person_outline),
                  ),
                  ButtonSegment<UserRole>(
                    value: UserRole.doctor,
                    label: Text('Doctor'),
                    icon: Icon(Icons.medical_services_outlined),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (Set<UserRole> newSelection) {
                  setState(() {
                    _selectedRole = newSelection.first;
                  });
                },
              ),

              const SizedBox(height: 30),

              // --- Загальні поля ---
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '+380...'
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Repeat Password', prefixIcon: Icon(Icons.lock)),
              ),

              // --- БЛОК ЛІКАРЯ ---
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                firstChild: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),

                    Text("Doctor's Information", style: theme.textTheme.titleMedium?.copyWith(color: primaryTeal)),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Specialization',
                        prefixIcon: Icon(Icons.work_outline),
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedSpecialization,
                      items: kSpecializations.map((String spec) {
                        return DropdownMenuItem(value: spec, child: Text(spec));
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() { _selectedSpecialization = newValue; });
                      },
                    ),
                    const SizedBox(height: 15),

                    // 🚀 НОВЕ ПОЛЕ: Адреса
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                          labelText: 'Clinic/Cabinet Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          hintText: 'City, Street, Building, Room'
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'About me (experience, education)',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your profile will be reviewed by admin. We may call you to verify details.',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.brown),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                secondChild: Container(),
                crossFadeState: _selectedRole == UserRole.doctor
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                child: _isLoading
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : const Text('Sign up'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Already have an account? Sign in'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  _signup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all general fields.')));
      return;
    }

    if (_selectedRole == UserRole.doctor) {
      if (_selectedSpecialization == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a specialization.')));
        return;
      }
      // 🚀 ПЕРЕВІРКА: Адреса обов'язкова для лікаря
      if (_addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your clinic/cabinet address.')));
        return;
      }
      if (_bioController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in info about yourself.')));
        return;
      }
    }

    setState(() { _isLoading = true; });

    try {
      await _auth.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _selectedRole,
        phoneNumber: _phoneController.text.trim(),
        // 🚀 Передаємо дані лікаря
        bio: _selectedRole == UserRole.doctor ? _bioController.text.trim() : null,
        specialization: _selectedRole == UserRole.doctor ? _selectedSpecialization : null,
        address: _selectedRole == UserRole.doctor ? _addressController.text.trim() : null,
      );

      if (mounted) {
        if (_selectedRole == UserRole.doctor) {
          Navigator.pushReplacementNamed(context, '/pending_verification');
        } else {
          Navigator.pushReplacementNamed(context, '/patient_dashboard');
        }
      }
    } catch (e) {
      log("Reg error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Error: $e')));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }
}