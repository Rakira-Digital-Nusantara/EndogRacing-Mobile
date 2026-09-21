import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class LoginSalesScreen extends StatefulWidget {
  const LoginSalesScreen({super.key});

  @override
  State<LoginSalesScreen> createState() => _LoginSalesScreenState();
}

class _LoginSalesScreenState extends State<LoginSalesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final success = await context.read<AuthProvider>().loginSales(
      _usernameController.text,
      _passwordController.text,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/sales/dashboard');
      } else {
        final errorMsg = context.read<AuthProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg ?? 'Login gagal')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {


    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Wallpaper HP3.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent, // Background tembus ke Container luar
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0, // Mencegah AppBar menjadi gelap saat konten lewat di bawahnya
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
            onPressed: () => context.pop(),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  // --- Bagian Atas: Logo dan Teks ---
                  // Gunakan Padding alih-alih Expanded agar tinggi logo tidak menyusut jadi 0 saat keyboard naik
                  Padding(
                    padding: const EdgeInsets.only(top: 100, bottom: 16), // Padding ditambah agar logo selalu di bawah tombol kembali
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/Logo Endog Racing Hijau.png',
                            height: 90, // diperkecil dari 120
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16), // dari 24
                          const Text(
                            'ENDOG RACING',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'HankenGrotesk',
                              fontSize: 26, // dari 28
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sistem Manajemen Peternakan Modern',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13, // dari 14
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16), // diperkecil dari 32
                        ],
                      ),
                    ),
                  ),
                  const Spacer(), // Mendorong panel putih ke bawah jika layar panjang, tapi bisa menyusut saat keyboard naik

                      // --- Bagian Bawah: Form Login ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24), // padding atas 24
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Masuk ke Sistem (Sales)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6), // dari 8
                        const Text(
                          'Kelola penjualan Anda dengan lebih mudah',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24), // dari 32

                        // === Input Username ===
              const Text(
                'NAMA PENGGUNA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Masukkan nama pengguna / email',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama pengguna tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16), // dari 24

              // === Input Password ===
              const Text(
                'KATA SANDI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6), // dari 8
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: 'Masukkan kata sandi',
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kata sandi tidak boleh kosong';
                  }

                  List<String> syarat = [];
                  if (value.length < 8) syarat.add('8 karakter');
                  if (!value.contains(RegExp(r'[A-Z]'))) syarat.add('huruf besar');
                  if (!value.contains(RegExp(r'[0-9]'))) syarat.add('angka');
                  if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) syarat.add('simbol');
                  
                  if (syarat.isNotEmpty) {
                    return 'Sandi kurang: ${syarat.join(', ')}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12), // dari 16

              // === Tombol Masuk ===
              AppButton(
                text: 'Masuk',
                trailingIcon: Icons.arrow_forward,
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 32), // dari 48

              // === Footer ===
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Belum punya akun? ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Hubungi Admin',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
                            ],
                          ), // end Column inside Form
                        ), // end Form
                      ), // end Container
                    ],
                  ), // end Column inside SliverFillRemaining
                ), // end SliverFillRemaining
              ],
            ), // end CustomScrollView
      ), // end Scaffold
    ); // end Container
  }
}
