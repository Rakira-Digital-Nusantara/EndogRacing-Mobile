import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../../home/providers/dashboard_provider.dart';

class KandangActivityScreen extends StatefulWidget {
  const KandangActivityScreen({super.key});

  @override
  State<KandangActivityScreen> createState() => _KandangActivityScreenState();
}

class _KandangActivityScreenState extends State<KandangActivityScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final String dateStr = _selectedDate.toIso8601String().split('T')[0];
    context.read<DashboardProvider>().fetchAktivitasHarian(dateStr);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final activities = dashboard.aktivitasHarian;
    final isLoading = dashboard.isLoadingAktivitas;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Kegiatan Input Harian',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        onSurface: Color(0xFF1E293B),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
                _fetchData();
              }
            },
            icon: const Icon(Icons.edit_calendar_rounded, color: AppColors.primary),
            tooltip: 'Ubah Tanggal',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Date Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal Kegiatan',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Activity Timeline
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : activities.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final item = activities[index];
                          final isLast = index == activities.length - 1;
                      
                      Color typeColor;
                      IconData typeIcon;
                      
                      switch (item['type']) {
                        case 'absensi':
                          typeColor = Colors.purple.shade500;
                          typeIcon = Icons.fingerprint_rounded;
                          break;
                        case 'penerimaan':
                          typeColor = Colors.blue.shade600;
                          typeIcon = Icons.inventory_2_rounded;
                          break;
                        case 'stok':
                          typeColor = Colors.orange.shade500;
                          typeIcon = Icons.sync_alt_rounded;
                          break;
                        case 'pakan':
                          typeColor = Colors.amber.shade700;
                          typeIcon = Icons.agriculture_rounded;
                          break;
                        case 'telur':
                          typeColor = Colors.orange.shade300;
                          typeIcon = Icons.egg_rounded;
                          break;
                        case 'kebersihan':
                          typeColor = Colors.teal.shade500;
                          typeIcon = Icons.cleaning_services_rounded;
                          break;
                        case 'populasi':
                          typeColor = Colors.indigo.shade500;
                          typeIcon = Icons.monitor_weight_rounded;
                          break;
                        case 'obat':
                          typeColor = Colors.red.shade500;
                          typeIcon = Icons.medical_services_rounded;
                          break;
                        case 'pencatatan':
                        default:
                          typeColor = Colors.green.shade500;
                          typeIcon = Icons.edit_document;
                          break;
                      }

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline Column
                            Column(
                              children: [
                                // Dot/Icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: typeColor.withValues(alpha: 0.3), width: 2),
                                  ),
                                  child: Icon(typeIcon, color: typeColor, size: 20),
                                ),
                                // Vertical Line
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: Colors.grey.shade300,
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Content Card
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(bottom: isLast ? 0 : 24),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.grey.shade400),
                                        const SizedBox(width: 6),
                                        Text(
                                          item['time']?.toString() ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['title']?.toString() ?? 'Kegiatan',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['description']?.toString() ?? item['subtitle']?.toString() ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Aktivitas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada kegiatan input yang tercatat\npada tanggal ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
