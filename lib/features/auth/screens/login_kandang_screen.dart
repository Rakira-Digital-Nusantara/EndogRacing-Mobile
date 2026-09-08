import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import 'barcode_scanner_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../kandang/data/models/kandang_model.dart';
import '../../kandang/data/repositories/kandang_repository.dart';
import '../providers/auth_provider.dart';

class LoginKandangScreen extends StatefulWidget {
  const LoginKandangScreen({super.key});

  @override
  State<LoginKandangScreen> createState() => _LoginKandangScreenState();
}

class _LoginKandangScreenState extends State<LoginKandangScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isLoadingKandang = true;

  List<KandangModel> _kandangList = [];
  String? _selectedKandangCode;

  @override
  void initState() {
    super.initState();
    _loadKandangs();
  }

  Future<void> _loadKandangs() async {
    try {
      final repo = context.read<KandangRepository>();
      final list = await repo.getKandangs();
      if (mounted) {
        setState(() {
          _kandangList = list;
          _isLoadingKandang = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  Future<void> _scanQR() async {
    // 1. Request Location Permission first
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akses Lokasi (GPS) wajib diizinkan untuk fitur ini.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akses Lokasi diblokir permanen di pengaturan HP Anda.')),
        );
      }
      return;
    }

    // 2. Buka Barcode Scanner
    final scannedBarcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      final authProvider = context.read<AuthProvider>();
      
      // 3. Ambil GPS secara Presisi
      try {
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final response = await authProvider.verifyBarcode(scannedBarcode, latitude: position.latitude, longitude: position.longitude);

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

      if (response != null && response.containsKey('kdg_code')) {
        final code = response['kdg_code'];
        // Cek apakah code ini ada di list kandang
        if (_kandangList.any((k) => k.kdgCode == code)) {
          setState(() {
            _selectedKandangCode = code;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil memindai: ${response['kdg_nama']}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kandang tidak ditemukan di daftar Anda.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Gagal memverifikasi barcode.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan lokasi GPS: '),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final success = await context.read<AuthProvider>().loginKandang(
      _selectedKandangCode!,
      _passwordController.text,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/home');
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
    final screenHeight = MediaQuery.of(context).size.height;

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
                                'Masuk ke Sistem (Kandang)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6), // dari 8
                        const Text(
                          'Kelola peternakan Anda dengan lebih mudah',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24), // dari 32

                        // === Input Dropdown Kandang ===
              const Text(
                'PILIH KANDANG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              _isLoadingKandang
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedKandangCode,
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 8,
                            decoration: InputDecoration(
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: SvgPicture.asset(
                                  'assets/vectors/LogoKandang.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.textSecondary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              hintText: 'Pilih kandang Anda',
                            ),
                            items: _kandangList.map((kandang) {
                              return DropdownMenuItem<String>(
                                value: kandang.kdgCode,
                                child: Text(kandang.kdgNama),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedKandangCode = newValue;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Silakan pilih kandang terlebih dahulu' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 54, // Matches standard TextFormField height approximately
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                            onPressed: _isLoading ? null : _scanQR,
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 16),

              // === Input PIN ===
              const Text(
                'PIN KANDANG',
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
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: 'Masukkan 6 digit PIN',
                  counterText: '', // Sembunyikan text counter
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
                    return 'PIN tidak boleh kosong';
                  }
                  
                  if (value.length != 6) {
                    return 'PIN harus 6 karakter';
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
