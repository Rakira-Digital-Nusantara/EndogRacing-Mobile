import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FaqBantuanScreen extends StatelessWidget {
  const FaqBantuanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('FAQ & Bantuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header / Hubungi Kami
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent_rounded, size: 48, color: Colors.white),
                const SizedBox(height: 16),
                const Text('Butuh Bantuan Cepat?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Tim Support kami siap membantu kendala Anda saat bekerja di lapangan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membuka WhatsApp... (Dummy)')));
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
                    label: const Text('Hubungi via WhatsApp', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const Text('PERTANYAAN UMUM (FAQ)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 12),

          // FAQ List
          _buildFaqItem(
            context,
            question: 'Bagaimana cara meretur telur yang pecah?',
            answer: 'Anda dapat masuk ke menu Stok & Deposit, lalu tekan tombol "Refund / Retur". Pilih telur yang pecah dan masukkan jumlahnya beserta alasan retur. Barang akan ditarik oleh Gudang Pusat.',
          ),
          _buildFaqItem(
            context,
            question: 'Apa yang harus dilakukan jika pelanggan ngutang (Piutang)?',
            answer: 'Saat membuat transaksi penjualan, sistem akan otomatis mencatat sisa pembayaran sebagai Piutang jika uang yang diterima kurang dari total tagihan. Anda dapat melihat tagihannya di menu Histori Penjualan.',
          ),
          _buildFaqItem(
            context,
            question: 'Bagaimana cara menyetor uang tunai ke Kas Besar?',
            answer: 'Masuk ke halaman Riwayat Setoran Uang atau Histori Penjualan, lalu pilih menu "Setor ke Kas Besar". Masukkan nominal uang fisik yang akan disetorkan dan jangan lupa unggah bukti transfer/setoran.',
          ),
          _buildFaqItem(
            context,
            question: 'Kenapa stok telur di mobil saya minus?',
            answer: 'Hal ini terjadi jika Anda belum mencatat penarikan barang dari Gudang, tetapi sudah membuat transaksi penjualan telur. Pastikan Anda mencatat Ambil Telur terlebih dahulu sebelum berjualan.',
          ),
          _buildFaqItem(
            context,
            question: 'Bagaimana jika aplikasi error saat offline?',
            answer: 'Aplikasi membutuhkan koneksi internet untuk mengirim data secara real-time. Jika Anda berada di daerah susah sinyal, harap tunggu hingga sinyal stabil sebelum menekan tombol Simpan.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, {required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: Colors.grey.shade400,
          title: Text(
            question,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          children: [
            Text(
              answer,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
