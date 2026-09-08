import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../absensi/selfie_camera_screen.dart';
import '../../absensi/providers/absensi_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SalesAbsensiScreen extends StatefulWidget {
  final String type; // dipertahankan untuk backward compatibility

  const SalesAbsensiScreen({super.key, required this.type});

  @override
  State<SalesAbsensiScreen> createState() => _SalesAbsensiScreenState();
}

class _SalesAbsensiScreenState extends State<SalesAbsensiScreen> {
  bool _isCheckingLocation = true;
  String? _photoPath;
  Position? _currentPosition;
  String _locationMessage = "Memeriksa lokasi...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AbsensiProvider>().fetchHistory();
      _checkLocation();
    });
  }

  Future<void> _checkLocation() async {
    setState(() {
      _isCheckingLocation = true;
      _locationMessage = "Mencari sinyal GPS...";
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isCheckingLocation = false;
        _locationMessage = "GPS tidak aktif";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isCheckingLocation = false;
          _locationMessage = "Izin lokasi ditolak";
        });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isCheckingLocation = false;
        _locationMessage = "Izin lokasi ditolak permanen";
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
          
          bool isDalamArea = true; // Dummy sementara selalu true
          
          _locationMessage = isDalamArea ? "Area Sesuai" : "Di luar area";
          _isCheckingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationMessage = "Gagal mendapat lokasi";
          _isCheckingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Absensi Sales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Consumer<AbsensiProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderInfo(),
                const SizedBox(height: 20),
                _buildLocationStatus(),
                const SizedBox(height: 16),
                _buildShiftSchedule(),
                const SizedBox(height: 24),
                _buildSelfieSection(),
                const SizedBox(height: 24),
                _buildSubmitButton(provider),
                const SizedBox(height: 32),
                _buildHistorySection(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final authProvider = context.read<AuthProvider>();
    final userName = authProvider.user?.usrLoginname ?? "Sales Team";
    String dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.directions_car_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('PT ENDOG RACING', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text('$userName | $dateStr', style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    final hasLocation = _currentPosition != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isCheckingLocation ? Colors.grey.shade300 : (hasLocation ? Colors.green.shade200 : Colors.red.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  const Text('STATUS LOKASI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _checkLocation,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (_isCheckingLocation)
            const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasLocation ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasLocation ? Icons.check_circle : Icons.cancel,
                    color: hasLocation ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _locationMessage,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasLocation ? Colors.green.shade700 : Colors.red.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildShiftSchedule() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              const Text('JADWAL SHIFT SALES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTimeRow('Masuk', '06:00 – 08:00'),
          const SizedBox(height: 8),
          _buildTimeRow('Pulang', '15:00 – 17:00'),
          const Divider(height: 24),
          Text('Waktu saat ini: ${DateFormat('HH:mm').format(DateTime.now())} WIB', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSelfieSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SelfieCameraScreen()),
            );
            if (result != null && result is String) {
              setState(() {
                _photoPath = result;
              });
            }
          },
          icon: const Icon(Icons.camera_alt),
          label: const Text('AMBIL SELFIE (WAJIB)'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_photoPath != null) ...[
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_photoPath!),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildSubmitButton(AbsensiProvider provider) {
    final bool canSubmit = _currentPosition != null && _photoPath != null && !provider.isLoading;
    final String nextType = provider.nextAbsenType; // "Masuk" atau "Pulang"
    
    final Color btnColor = nextType == 'Masuk' ? AppColors.primary : Colors.orange.shade800;
    final IconData btnIcon = nextType == 'Masuk' ? Icons.login : Icons.logout;

    return ElevatedButton.icon(
      onPressed: canSubmit
          ? () async {
              final success = await provider.submitAbsensi(
                photoPath: _photoPath!,
                latitude: _currentPosition!.latitude,
                longitude: _currentPosition!.longitude,
              );

              if (!mounted) return;
              
              if (success) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => SuccessDialog(
                    title: 'Absen $nextType Berhasil',
                    subtitle: 'Data absensi Anda telah tercatat di sistem.',
                    time: '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} WIB',
                    onPrimaryPressed: () {
                      Navigator.pop(context); // Tutup dialog
                      Navigator.pop(this.context); // Kembali ke dashboard
                    },
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Gagal absensi'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          : null,
      icon: provider.isLoading 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
        : Icon(btnIcon, size: 20),
      label: Text(provider.isLoading ? 'MENGIRIM...' : 'ABSEN ${nextType.toUpperCase()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        disabledBackgroundColor: Colors.grey.shade300,
      ),
    );
  }

  Widget _buildHistorySection(AbsensiProvider provider) {
    if (provider.isLoading && provider.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('📋 Riwayat Absensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () => provider.fetchHistory(),
            )
          ],
        ),
        const SizedBox(height: 8),
        if (provider.history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text('Belum ada riwayat absensi.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.history.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = provider.history[index];
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.tanggalAbsen, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(item.status ?? 'Tercatat', style: TextStyle(fontSize: 12, color: item.status == 'Terlambat' ? Colors.red : Colors.grey)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            item.tipeAbsen.toLowerCase() == 'masuk' ? Icons.login : Icons.logout, 
                            size: 16, 
                            color: item.tipeAbsen.toLowerCase() == 'masuk' ? Colors.green : Colors.orange
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.waktuAbsen ?? item.tipeAbsen,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: item.tipeAbsen.toLowerCase() == 'masuk' ? Colors.green : Colors.orange
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
