import 'package:dio/dio.dart';
import '../../../shared/widgets/app_button.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/success_screen.dart';
import 'package:endog_racing/shared/widgets/notification_bell.dart';
import '../../home/screens/main_screen.dart';
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}
class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingPO = false;
  List<dynamic> _pendingPOs = [];
  // Form states
  String? _selectedPoCode;
  final List<Map<String, dynamic>> _receiptItems = [];
  List<dynamic> _masterProducts = [];
  bool _isLoadingProducts = false;
  final TextEditingController _penerimaNameController = TextEditingController();
  final TextEditingController _noSuratJalanController = TextEditingController();
  File? _fotoSuratJalan;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  // History states
  bool _showForm = false;
  bool _isLoadingHistory = false;
  List<dynamic> _historyList = [];
  String _historyError = '';
  // Stock states
  bool _isLoadingStock = false;
  List<dynamic> _stockList = [];
  String _stockError = '';
  @override
  void initState() {
    super.initState();
    // 2 Tabs: Stok Tersedia & Penerimaan
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _fetchStock();
      } else if (_tabController.index == 1) {
        _fetchPendingPOs();
        _fetchHistory();
        if (_masterProducts.isEmpty) _fetchMasterProducts();
      }
    });
    
    // Fetch initial stock
    _fetchStock();
  }
  Future<void> _fetchStock() async {
    if (_isLoadingStock) return;
    setState(() {
      _isLoadingStock = true;
      _stockError = '';
    });
    try {
      final response = await DioClient().dio.get('/inventory/stok');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        setState(() {
          _stockList = data is List ? data : [];
        });
      }
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioException) {
        errMsg = e.response?.data?.toString() ?? e.message ?? e.toString();
      }
      setState(() {
        _stockError = 'Gagal memuat stok: $errMsg';
      });
    } finally {
      if (mounted) setState(() => _isLoadingStock = false);
    }
  }
  Future<void> _fetchHistory() async {
    if (_isLoadingHistory) return;
    setState(() {
      _isLoadingHistory = true;
      _historyError = '';
    });
    try {
      final response = await DioClient().dio.get('/penerimaan-barang');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['data'] != null) {
          final historyData = data['data'];
          setState(() {
            if (historyData is List) {
              _historyList = historyData;
            } else if (historyData is Map && historyData.containsKey('data') && historyData['data'] is List) {
              _historyList = historyData['data'];
            } else {
              _historyList = [];
            }
          });
        } else {
          setState(() {
            _historyError = 'Format histori tidak dikenali: type of data is ${data.runtimeType}';
          });
        }
      } else {
        setState(() {
          _historyError = 'Gagal memuat: ${response.statusCode}';
        });
      }
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioException) {
        errMsg = e.response?.data?.toString() ?? e.message ?? e.toString();
      }
      setState(() {
        _historyError = 'Gagal memuat riwayat: $errMsg';
      });
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }
  Future<void> _fetchMasterProducts() async {
    if (_isLoadingProducts) return;
    setState(() => _isLoadingProducts = true);
    try {
      final response = await DioClient().dio.get('/master/product-business');
      if (response.statusCode == 200 && response.data['data'] != null) {
        setState(() {
          _masterProducts = response.data['data'] is List ? response.data['data'] : [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching master products: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }
  Future<void> _fetchPendingPOs() async {
    if (_isLoadingPO) return;
    setState(() => _isLoadingPO = true);
    try {
      final response = await DioClient().dio.get('/pembelian/pending');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        List<dynamic> poList = response.data['data'];
        
        // Backend sudah memperbaiki endpoint ini sehingga hanya mengembalikan PO yang benar-benar belum ada draf penerimaannya.
        // Kita tidak perlu lagi mem-filter secara lokal.
        
        // Backend has been fixed to include details.product (eager loading)
        setState(() {
          _pendingPOs = poList;
        });
      }
    } catch (e) {
      // Dummy fallback based on user request
      setState(() {
        _pendingPOs = [
          {
            "po_h": "PO-DUMMY-001",
            "tanggal": "2026-08-24",
            "supplier": {"sup_nama": "Gudang Pusat (Bpk. Yanto)"},
            "details": [
              {
                "sku_product": "PKN-001",
                "product": {"prd_nama": "Layer Mash"},
                "qty": 50
              },
              {
                "sku_product": "PKN-002",
                "product": {"prd_nama": "Vita Stress"},
                "qty": 20
              }
            ]
          }
        ];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingPO = false);
      }
    }
  }
  @override
  void dispose() {
    _tabController.dispose();
    _penerimaNameController.dispose();
    _noSuratJalanController.dispose();
    for (var item in _receiptItems) {
      (item['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final kandangName = context.watch<AuthProvider>().kandang?.kdgNama ?? 'KANDANG';
    final userFoto = context.watch<AuthProvider>().user?.foto;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset(
              'assets/images/Logo Endog Racing Hijau.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Inventory Gudang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kandangName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.primary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const NotificationBell(),
          GestureDetector(
            onTap: () {
              final mainScreen = context.findAncestorStateOfType<MainScreenState>();
              if (mainScreen != null) {
                mainScreen.changeTab(3);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 20, left: 4),
              child: Container(
                width: 32.0,
                height: 32.0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: (userFoto != null && userFoto.isNotEmpty) 
                    ? NetworkImage(userFoto) 
                    : null,
                  child: (userFoto == null || userFoto.isEmpty)
                      ? const Icon(Icons.warehouse_rounded, size: 20, color: AppColors.primary)
                      : null,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Stok Tersedia'),
            Tab(text: 'Penerimaan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStokTersediaTab(),
          _buildPenerimaanTab(),
        ],
      ),
    );
  }
  // ===========================================================================
  // TAB 1: STOK TERSEDIA
  // ===========================================================================
  Widget _buildStokTersediaTab() {
    if (_isLoadingStock) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_stockError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_stockError, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchStock, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    if (_stockList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Stok kosong / tidak ditemukan', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    // Grouping Logic
    final Map<String, List<dynamic>> groupedStocks = {
      'Pakan': [],
      'Obat & Vitamin': [],
      'Telur': [],
      'Lainnya': [],
    };
    for (var item in _stockList) {
      final String name = (item['sku_name'] ?? item['sku_product'] ?? '-').toLowerCase();
      if (name.contains('pakan') || name.contains('mash') || name.contains('konsentrat')) {
        groupedStocks['Pakan']!.add(item);
      } else if (name.contains('obat') || name.contains('vitamin') || name.contains('vita') || name.contains('vaksin') || name.contains('nd')) {
        groupedStocks['Obat & Vitamin']!.add(item);
      } else if (name.contains('telur')) {
        groupedStocks['Telur']!.add(item);
      } else {
        groupedStocks['Lainnya']!.add(item);
      }
    }
    // Remove empty groups
    groupedStocks.removeWhere((key, value) => value.isEmpty);
    return RefreshIndicator(
      onRefresh: _fetchStock,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: groupedStocks.length,
        itemBuilder: (context, index) {
          final category = groupedStocks.keys.elementAt(index);
          final items = groupedStocks[category]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              ...items.map((item) {
                final String name = item['sku_name'] ?? item['sku_product'] ?? '-';
                final double quantity = double.tryParse(item['stock_akhir']?.toString() ?? '0') ?? 0;
                final String unit = item['sku_uom'] ?? 'PCS';
                final String gudang = item['gudang_name'] ?? '';
                
                IconData icon = Icons.inventory_2_outlined;
                Color color = const Color(0xFFF59E0B);
                
                final lowerName = name.toLowerCase();
                if (lowerName.contains('pakan') || lowerName.contains('mash') || lowerName.contains('konsentrat')) {
                  icon = Icons.spa_outlined; // Elegan leaf/spa shape
                  color = const Color(0xFFF59E0B);
                } else if (lowerName.contains('obat') || lowerName.contains('vitamin') || lowerName.contains('vita') || lowerName.contains('vaksin') || lowerName.contains('nd')) {
                  icon = Icons.science_outlined; // Elegan lab flask
                  color = const Color(0xFF2563EB);
                } else if (lowerName.contains('desinfektan') || lowerName.contains('sanitizer')) {
                  icon = Icons.sanitizer_outlined;
                  color = const Color(0xFF0D9488);
                } else if (lowerName.contains('telur')) {
                  icon = Icons.egg_outlined;
                  color = const Color(0xFFF59E0B); // Kuning/Oranye
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (gudang.isNotEmpty) ...[
                        Text(gudang, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                      ],
                      _buildStockCard(
                        name: name,
                        quantity: quantity,
                        unit: unit,
                        maxCapacity: quantity > 0 ? (quantity * 1.5).clamp(100, 10000).toDouble() : 1000,
                        icon: icon,
                        color: color,
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
  Widget _buildStockCard({
    required String name,
    required double quantity,
    required String unit,
    required double maxCapacity,
    required IconData icon,
    required Color color,
  }) {
    final double percentage = (quantity / maxCapacity).clamp(0.0, 1.0);
    // Tentukan warna progress bar berdasarkan persentase
    Color progressColor = AppColors.primary;
    if (percentage < 0.2) {
      progressColor = const Color(0xFFDC2626); // Merah (Kritis)
    } else if (percentage < 0.5) {
      progressColor = const Color(0xFFF59E0B); // Kuning (Menipis)
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15), // Transparan agar tidak terlalu pekat
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28), // Iconnya yang pakai warna solid
          ),
          const SizedBox(width: 16),
          // Info & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '$quantity $unit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: percentage < 0.2 ? const Color(0xFFDC2626) : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ===========================================================================
  // ===========================================================================
  // TAB 2: PENERIMAAN
  // ===========================================================================
  Widget _buildPenerimaanTab() {
    if (_showForm) return _buildPenerimaanFormView();
    return _buildHistoryView();
  }
  Widget _buildHistoryView() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _showForm = true);
                _fetchPendingPOs(); // Ambil data PO terbaru
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Penerimaan Barang', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Riwayat Penerimaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          if (_historyError.isNotEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_historyError, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
              ),
            )
          else if (_historyList.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Belum ada riwayat penerimaan', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchHistory,
                color: AppColors.primary,
                child: ListView.builder(
                  itemCount: _historyList.length,
                itemBuilder: (context, index) {
                  final item = _historyList[index];
                  final String poH = item['po_h'] ?? '-';
                  final String date = item['tanggal_terima'] ?? '-';
                  final poObj = item['po'] ?? item['purchase_order'] ?? {};
                  
                  final String poStatusPenerimaan = poObj['status_penerimaan']?.toString() ?? poObj['status']?.toString() ?? '';

                  final String itemStatus = item['status_penerimaan']?.toString() ?? item['status']?.toString() ?? item['rec_status']?.toString() ?? '';
                  
                  final String rawStatus = itemStatus.isNotEmpty && itemStatus.toLowerCase() != 'a' && itemStatus.toLowerCase() != 'n' ? itemStatus : (poStatusPenerimaan.isNotEmpty ? poStatusPenerimaan : '0');
                  
                  String statusLabel = rawStatus.isEmpty ? 'Menunggu Admin' : rawStatus;
                  bool isDraft = true;
                  
                  final lowerStatus = rawStatus.toLowerCase();
                  if (lowerStatus.contains('selesai') || rawStatus == '1') {
                    statusLabel = 'Selesai Diterima';
                    isDraft = false;
                  } else if (lowerStatus.contains('draft') || rawStatus == '0' || lowerStatus.contains('pending')) {
                    statusLabel = 'Draft / Menunggu Konfirmasi';
                    isDraft = true;
                  } else {
                    isDraft = true; // By default if not explicitly finished, it's pending (Orange)
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showDetailBottomSheet(context, item, isDraft: isDraft),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icon on the left
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDraft ? Colors.orange.withOpacity(0.15) : const Color(0xFF16A34A).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isDraft ? Icons.time_to_leave_outlined : Icons.local_shipping_outlined,
                                  color: isDraft ? Colors.orange : const Color(0xFF16A34A),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Info in the middle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      poH,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontSize: 13, 
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDraft ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isDraft ? Colors.orange.withOpacity(0.2) : const Color(0xFF16A34A).withOpacity(0.2),
                                            ),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isDraft ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Chevron right
                              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
             ),
            ),
        ],
      ),
    );
  }
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))),
          const Text(':', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
  void _showDetailBottomSheet(BuildContext context, Map<String, dynamic> item, {bool isDraft = false}) {
    final String poH = item['po_h'] ?? '-';
    final String terimaCode = item['terima_code'] ?? '-';
    final String gudang = item['gudang_code'] ?? '-';
    final String tglTerima = item['tanggal_terima'] ?? '-';
    final String penerima = item['penerima_name'] ?? '-';
    // ignore: unused_local_variable
    final String? foto = item['foto_surat_jalan']; // Can be rendered later if backend provides full URL
    final List<dynamic> details = item['details'] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Detail Penerimaan: $poH', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('No. Terima', terimaCode),
                      _buildDetailRow('Tgl Terima', tglTerima),
                      _buildDetailRow('Gudang', gudang),
                      _buildDetailRow('Penerima', penerima),
                      if (foto != null && foto.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Foto Surat Jalan:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: InteractiveViewer(
                                  child: Image.network(
                                    foto.startsWith('http') 
                                        ? foto 
                                        : 'https://api-endogracing.rakiradigital.com/${foto.startsWith('storage/') ? '' : 'storage/'}${foto.startsWith('/') ? foto.substring(1) : foto}',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                foto.startsWith('http') 
                                    ? foto 
                                    : 'https://api-endogracing.rakiradigital.com/${foto.startsWith('storage/') ? '' : 'storage/'}${foto.startsWith('/') ? foto.substring(1) : foto}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                                    const SizedBox(height: 4),
                                    Text('Gagal memuat foto', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Item Barang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: details.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: Text('Tidak ada detail barang', style: TextStyle(color: Colors.grey.shade500))),
                            )
                          ]
                        : details.map((d) {
                            final sku = d['sku_product'] ?? '-';
                            final qtyPo = d['qty_po']?.toString() ?? '0';
                            final qtyTerima = d['qty_terima']?.toString() ?? '0';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1))],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(sku, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Dipesan: $qtyPo', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                        Text('Diterima: $qtyTerima', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildPenerimaanFormView() {
    if (_isLoadingPO) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_pendingPOs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Belum ada pesanan yang datang', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => setState(() => _showForm = false),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali ke Riwayat'),
            )
          ],
        ),
      );
    }
    // Get selected PO object
    final selectedPoObj = _pendingPOs.firstWhere(
      (p) => p['po_h'] == _selectedPoCode,
      orElse: () => {},
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _showForm = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Form Penerimaan Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 1. Dropdown Kode PO
            const Text('Kode PO (Surat Jalan)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPoCode,
              isExpanded: true,
              hint: const Text('Pilih Kode PO'),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _pendingPOs.map<DropdownMenuItem<String>>((po) {
                return DropdownMenuItem<String>(
                  value: po['po_h'].toString(),
                  child: Text(po['po_h'].toString(), style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPoCode = value;
                  for (var item in _receiptItems) {
                    if (item['controller'] is TextEditingController) {
                       (item['controller'] as TextEditingController).dispose();
                    }
                  }
                  _receiptItems.clear();
                  if (value != null) {
                    _receiptItems.add({'sku': null, 'controller': TextEditingController()});
                  }
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // 1b. Nomor Surat Jalan
            const Text('Nomor Surat Jalan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            TextField(
              controller: _noSuratJalanController,
              decoration: InputDecoration(
                hintText: 'Contoh: SJ-2026-09-001',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 2. Daftar Produk dalam PO (Blind Receipt)
            if (_selectedPoCode != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daftar Produk yang Diterima', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  ..._receiptItems.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final item = entry.value;
                    final controller = item['controller'] as TextEditingController;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Produk ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              if (_receiptItems.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      controller.dispose();
                                      _receiptItems.removeAt(index);
                                    });
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                )
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: item['sku'],
                            isExpanded: true,
                            hint: const Text('Pilih Produk (SKU)'),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _masterProducts.map<DropdownMenuItem<String>>((prod) {
                              final sku = prod['sku_product']?.toString() ?? '';
                              final name = prod['sku_name']?.toString() ?? '';
                              return DropdownMenuItem<String>(
                                value: sku,
                                child: Text('$sku - $name', style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                item['sku'] = val;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Qty Diterima (Contoh: 50)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _receiptItems.add({'sku': null, 'controller': TextEditingController()});
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Barang'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFF16A34A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            
            // 5. Nama Penerima
            const Text('Nama Penerima', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            TextField(
              controller: _penerimaNameController,
              decoration: InputDecoration(
                hintText: 'Contoh: Nama anak kandang',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 6. Foto Surat Jalan
            const Text('Foto Surat Jalan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 50,
                  maxWidth: 1024,
                  maxHeight: 1024,
                );
                if (image != null) {
                  setState(() => _fotoSuratJalan = File(image.path));
                }
              },
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _fotoSuratJalan != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_fotoSuratJalan!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 32, color: Colors.grey.shade500),
                          const SizedBox(height: 8),
                          Text('Ambil Foto Surat Jalan', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
            // Submit Button
            AppButton(
              onPressed: _submitPenerimaan,
              isLoading: _isSubmitting,
              text: 'Simpan Data',
              trailingIcon: Icons.check_circle,
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _submitPenerimaan() async {
    // Validasi Basic
    if (_selectedPoCode == null || _penerimaNameController.text.isEmpty || _fotoSuratJalan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih PO, isi Nama Penerima, dan lampirkan Foto Surat Jalan')),
      );
      return;
    }
    
    // Validasi isi Qty dan SKU
    bool isAllQtyFilled = true;
    for (var item in _receiptItems) {
      if (item['sku'] == null || (item['controller'] as TextEditingController).text.isEmpty) {
        isAllQtyFilled = false;
        break;
      }
    }
    
    if (!isAllQtyFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi SKU dan isi Qty Barang Diterima untuk semua baris produk')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      // Get the selected PO object
      final selectedPoObj = _pendingPOs.firstWhere((p) => p['po_h'] == _selectedPoCode, orElse: () => {});
      final String gudangCode = selectedPoObj['gudang_code']?.toString() ?? '';
      
      final Map<String, dynamic> formDataMap = {
        'po_h': _selectedPoCode,
        'gudang_code': gudangCode,
        'tanggal_terima': DateTime.now().toIso8601String().split('T')[0],
        'penerima_name': _penerimaNameController.text,
        'no_surat_jalan': _noSuratJalanController.text.isNotEmpty ? _noSuratJalanController.text : '-',
        'foto_surat_jalan': await MultipartFile.fromFile(
          _fotoSuratJalan!.path,
          filename: _fotoSuratJalan!.path.split('/').last,
        ),
      };
      
      // Loop through all items to create details array (Blind Receipt)
      for (int i = 0; i < _receiptItems.length; i++) {
        final sku = _receiptItems[i]['sku'].toString();
        final qtyTerima = (_receiptItems[i]['controller'] as TextEditingController).text;
        
        formDataMap['details[$i][sku_product]'] = sku;
        formDataMap['details[$i][qty_terima]'] = qtyTerima;
      }
      final formData = FormData.fromMap(formDataMap);
      final response = await DioClient().dio.post('/penerimaan-barang', data: formData);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Reset form & view
        setState(() {
          _selectedPoCode = null;
          for (var item in _receiptItems) {
            (item['controller'] as TextEditingController).dispose();
          }
          _receiptItems.clear();
          _penerimaNameController.clear();
          _fotoSuratJalan = null;
          _showForm = false;
        });
        // Refresh Lists
        _fetchPendingPOs();
        _fetchHistory();
        showDialog(
          context: context,
          builder: (context) => SuccessDialog(
            title: 'Penerimaan Disimpan',
            subtitle: 'Data penerimaan barang berhasil dicatat.',
            time: '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} WIB',
            primaryButtonText: 'Selesai',
            onPrimaryPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Gagal menyimpan data'), backgroundColor: Colors.red),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      
      String errorMessage = 'Terjadi kesalahan koneksi';
      if (e.response != null && e.response?.data != null) {
        try {
          File('d:/_Kerjaan/_EndogRacing/EndogRacingMobile/debug_error.json').writeAsStringSync(e.response?.data.toString() ?? '');
        } catch (_) {}
        final data = e.response?.data;
        if (data is Map) {
          if (data.containsKey('errors') && data['errors'] is Map) {
            final errors = data['errors'] as Map;
            final errorList = <String>[];
            for (var v in errors.values) {
              if (v is List) {
                errorList.addAll(v.map((e) => e.toString()));
              } else {
                errorList.add(v.toString());
              }
            }
            errorMessage = errorList.join('\n');
          } else if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}

