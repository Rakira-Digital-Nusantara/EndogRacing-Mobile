# Update: Endpoint Riwayat Stok Mobil
**Endpoint:** GET /api/sales/riwayat-stok-mobil

**Field Response Utama:**
- 	anggal & waktu_format (misal: "2026-09-12", "06:30 AM")
- jenis_transaksi (misal: "Ambil Gudang", "Penjualan", "Retur")
- sku_name + qty_kg + qty_kas (misal: "Telur Utuh", 150.0, 10)
- label_perubahan (misal: "+150.0 Kg" atau "-30.0 Kg")
- rah (misal: "IN" atau "OUT")
- stock_akhir_kg & stock_akhir_kas (Sisa stok setelah mutasi)

## Bug Fix: Terima Cicilan dan Saldo
- **Bug 1:** ayarPiutang() di *backend* sebelumnya tidak menambahkan uang_diterima. Telah diperbaiki sehingga uang_diterima += nominal_bayar.
- **Bug 2:** getSaldo() di *backend* sebelumnya salah query. Telah diperbaiki menggunakan emp_code dan SUM(uang_diterima) untuk mencerminkan uang fisik riil di tangan Sales.
- **Status:** *Fix* di *backend* selesai. Aplikasi Mobile tidak perlu mengubah apa-apa, data /api/sales/saldo sekarang sudah akurat.


<?php

namespace App\Http\Controllers\Api\Sales;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\TrPenjualanH;
use App\Models\MsProductBusiness;
use App\Models\MsCogs;
use App\Models\TrMutasiStockGudang;
use App\Models\TrAbsensiSales;
use Carbon\Carbon;

class SalesDashboardController extends Controller
{
    /**
     * Dashboard Sales (Mobile)
     */
    public function index(Request $request)
    {
        try {
            // Ambil semua produk yang masuk kategori Telur, kecuali Telur Rusak
            $produkTelur = MsProductBusiness::where(function($q) {
                $q->where('sku_category', 'Telur')
                  ->orWhere('sku_category', 'Produk')
                  ->orWhere('sku_name', 'like', '%Telur%');
            })
            ->where('sku_name', 'not like', '%Rusak%')
            ->where('rec_status', 1)->get();

            // Set Tanggal Filter (Parse aman untuk menghindari format ISO dari mobile)
            $tanggal = Carbon::now()->format('Y-m-d');
            if ($request->filled('tanggal')) {
                try {
                    $tanggal = \Carbon\Carbon::parse($request->tanggal)->format('Y-m-d');
                } catch (\Exception $e) {
                    // Abaikan jika tidak bisa diparse, tetap gunakan hari ini
                }
            }

            $empCode = $request->user() ? $request->user()->emp_code : 'EMP-001';
            $employee = \App\Models\MsEmployee::find($empCode);
            $gudangMobilCode = $employee && $employee->gudang_code_mobil ? $employee->gudang_code_mobil : 'GDG-MOBIL';

            // Ambil semua gudang_code yang sedang direlasikan ke Employee/Sales
            $gudangSalesCodes = \App\Models\MsEmployee::whereNotNull('gudang_code_mobil')
                ->where('gudang_code_mobil', '!=', '')
                ->pluck('gudang_code_mobil')
                ->toArray();
                
            $gudangLain = \App\Models\MsGudang::whereNotIn('gudang_code', $gudangSalesCodes)
                ->where('rec_status', 1)
                ->pluck('gudang_code');

            $rincianStokMobil = [];
            $rincianStokPusat = [];
            $listHargaHariIni = [];
            $totalStokMobilKg = 0;
            $totalStokPusatKg = 0;
            $totalStokMobilKas = 0;
            $totalStokPusatKas = 0;
            $totalKgTerjual = 0;
            $totalKasTerjual = 0;
            $telurSkus = [];
            $hargaSentral = 0;

            foreach ($produkTelur as $index => $prod) {
                $telurSkus[] = $prod->sku_product;
                $cogs = MsCogs::where('sku_product', $prod->sku_product)
                    ->where('rec_status', 1)
                    ->where('cogs_effective_date', '<=', $tanggal)
                    ->orderBy('cogs_effective_date', 'desc')
                    ->first();
                $cogsPrice = $cogs ? (float)$cogs->cogs_price : 0;

                // Tetapkan harga sentral global dari produk pertama yang ditemukan
                if ($index === 0) {
                    $hargaSentral = $cogsPrice;
                }

                $listHargaHariIni[] = [
                    'sku_name' => $prod->sku_name,
                    'harga' => $cogsPrice
                ];

                $konversi = (float)($prod->sku_uom_conversion ?? 15);
                if ($konversi <= 0) $konversi = 15;

                // Hitung Stok Mobil untuk produk ini
                $lastMutasiMobil = TrMutasiStockGudang::where('gudang_code', $gudangMobilCode)
                    ->where('sku_product', $prod->sku_product)
                    ->whereDate('rec_datecreated', '<=', $tanggal)
                    ->orderBy('id', 'desc')
                    ->first();
                $qtyMobilKg = $lastMutasiMobil ? (float)$lastMutasiMobil->stock_akhir : 0;
                $qtyMobilKas = floor($qtyMobilKg / $konversi);

                $rincianStokMobil[] = [
                    'sku_product' => $prod->sku_product,
                    'sku_name' => $prod->sku_name,
                    'harga_sentral' => $cogsPrice,
                    'qty_kg' => $qtyMobilKg,
                    'qty_kas' => $qtyMobilKas
                ];
                $totalStokMobilKg += $qtyMobilKg;
                $totalStokMobilKas += $qtyMobilKas;

                // Hitung Stok Pusat untuk produk ini
                $qtyPusatKg = 0;
                foreach ($gudangLain as $gCode) {
                    $lastMutasi = TrMutasiStockGudang::where('gudang_code', $gCode)
                        ->where('sku_product', $prod->sku_product)
                        ->whereDate('rec_datecreated', '<=', $tanggal)
                        ->orderBy('id', 'desc')
                        ->first();
                    if ($lastMutasi) {
                        $qtyPusatKg += $lastMutasi->stock_akhir;
                    }
                }
                $qtyPusatKas = floor($qtyPusatKg / $konversi);

                $rincianStokPusat[] = [
                    'sku_product' => $prod->sku_product,
                    'sku_name' => $prod->sku_name,
                    'harga_sentral' => $cogsPrice,
                    'qty_kg' => $qtyPusatKg,
                    'qty_kas' => $qtyPusatKas
                ];
                $totalStokPusatKg += $qtyPusatKg;
                $totalStokPusatKas += $qtyPusatKas;

                // Hitung Penjualan (Terjual) untuk SKU ini khusus Sales bersangkutan
                $qtyTerjualKg = \Illuminate\Support\Facades\DB::table('edg_tr_penjualan_detail')
                    ->join('edg_tr_penjualan', 'edg_tr_penjualan.jual_code', '=', 'edg_tr_penjualan_detail.jual_code')
                    ->where('edg_tr_penjualan.tanggal', $tanggal)
                    ->where('edg_tr_penjualan.emp_code', $empCode)
                    ->where('edg_tr_penjualan.rec_status', 1)
                    ->where('edg_tr_penjualan_detail.sku_product', $prod->sku_product)
                    ->where('edg_tr_penjualan_detail.rec_status', 1)
                    ->sum('edg_tr_penjualan_detail.qty');
                
                $totalKgTerjual += $qtyTerjualKg;
                $totalKasTerjual += floor($qtyTerjualKg / $konversi);
            }

            // Fallback agar totalKgTerjual tidak error jika $telurSkus kosong
            if (empty($telurSkus)) {
                $telurSkus = ['TLR-001'];
            }

            // 4. Perhitungan Tagihan / Piutang (Khusus untuk transaksi Sales ini pada Hari Ini)
            // Lunas = Total uang yang sudah dibayar dari transaksi hari ini (meskipun parsial)
            $totalPaid = TrPenjualanH::where('tanggal', $tanggal)
                ->where('emp_code', $empCode)
                ->sum('total_dibayar'); 

            // Belum = Total sisa tagihan/piutang dari transaksi hari ini
            $totalUnpaid = TrPenjualanH::where('tanggal', $tanggal)
                ->where('emp_code', $empCode)
                ->sum('sisa_piutang');

            // List detail unpaid (Seluruh tagihan yang belum lunas milik sales ini, bisa lintas hari/sebelumnya)
            $listUnpaid = TrPenjualanH::with('customer')
                ->where('emp_code', $empCode)
                ->whereIn('status_bayar', ['Unpaid', 'Parsial'])
                ->where('sisa_piutang', '>', 0)
                ->get()
                ->map(function ($item) {
                    return [
                        'jual_code' => $item->jual_code,
                        'customer_name' => $item->customer->customer_name ?? 'Unknown',
                        'sisa_piutang' => $item->sisa_piutang,
                        'tanggal' => $item->tanggal
                    ];
                });

            // Cek Absensi pada tanggal tersebut
            $absenMasuk = TrAbsensiSales::where('emp_code', $empCode)->where('tanggal', $tanggal)->where('tipe_absen', 'Masuk')->exists();
            $absenPulang = TrAbsensiSales::where('emp_code', $empCode)->where('tanggal', $tanggal)->where('tipe_absen', 'Pulang')->exists();

            // 5. Total Disetor dan Saldo di Tangan
            $totalDisetor = \App\Models\TrSetoranSales::where('emp_code', $empCode)
                ->whereDate('tanggal', $tanggal)
                ->where('rec_status', 1)
                ->sum('nominal');
                
            $totalDiterima = $totalPaid; // Uang yang sudah diterima hari ini dari transaksi
            $saldoDiTangan = $totalDiterima - $totalDisetor;

            return response()->json([
                'status' => 'success',
                'data' => [
                    'harga_sentral' => (float) $hargaSentral,
                    'list_harga_hari_ini' => $listHargaHariIni,
                    'stok_mobil' => (float) $totalStokMobilKg, 
                    'stok_mobil_kas' => (float) $totalStokMobilKas,
                    'stok_pusat' => (float) $totalStokPusatKg, 
                    'stok_pusat_kas' => (float) $totalStokPusatKas,
                    'stok_sales' => (float) $totalStokMobilKg, // Alias
                    'stok_gudang' => (float) $totalStokPusatKg, // Alias
                    'total_kg_terjual' => (float) $totalKgTerjual,
                    'total_kas_terjual' => (float) $totalKasTerjual,
                    'rincian_stok_mobil' => $rincianStokMobil,
                    'rincian_stok_pusat' => $rincianStokPusat,
                    'total_cash_paid' => (float) $totalPaid,
                    'total_piutang' => (float) $totalUnpaid,
                    'total_diterima' => (float) $totalDiterima,
                    'total_disetor' => (float) $totalDisetor,
                    'saldo_di_tangan' => (float) $saldoDiTangan,
                    'list_unpaid' => $listUnpaid,
                    'absensi' => [
                        'sudah_masuk' => $absenMasuk,
                        'sudah_pulang' => $absenPulang
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => 'Gagal memuat dashboard', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Rekap Penjualan Harian
     * Endpoint: GET /api/sales/rekap-harian
     */
    public function rekapHarian(Request $request)
    {
        try {
            $tanggal = $request->date ?? Carbon::now()->format('Y-m-d');
            $user = $request->user();
            $empCode = $user->emp_code ?? null;

            $queryPenjualan = TrPenjualanH::with(['details.product', 'customer'])
                ->where('tanggal', $tanggal);
                
            if ($empCode) {
                $queryPenjualan->where('emp_code', $empCode);
            } else {
                $queryPenjualan->where('rec_usercreated', $user->usr_loginname);
            }

            $penjualanList = $queryPenjualan->orderBy('rec_datecreated', 'desc')->get();

            $totalOmset = $penjualanList->sum('total_akhir');
            $totalLunas = $penjualanList->sum('total_dibayar');
            $totalPiutang = $penjualanList->sum('sisa_piutang');

            $totalTelurKg = 0;
            $transactions = [];

            foreach ($penjualanList as $p) {
                $telurTrxKg = 0;
                foreach ($p->details as $d) {
                    $isTelur = stripos($d->product->sku_category ?? '', 'Telur') !== false || stripos($d->product->sku_name ?? '', 'Telur') !== false;
                    if ($isTelur) {
                        $totalTelurKg += $d->qty;
                        $telurTrxKg += $d->qty;
                    }
                }

                $customerName = $p->customer->customer_name ?? 'Unknown';
                
                $transactions[] = [
                    'invoice_number' => $p->jual_code,
                    'customer_name' => $customerName,
                    'total_kg' => (float) $telurTrxKg,
                    'total_harga' => (float) $p->total_akhir,
                    'status' => $p->status_bayar == 'Paid' ? 'LUNAS' : 'PIUTANG'
                ];
            }

            return response()->json([
                'status' => 'success',
                'data' => [
                    'summary' => [
                        'total_omzet' => (float) $totalOmset,
                        'total_lunas' => (float) $totalLunas,
                        'total_piutang' => (float) $totalPiutang,
                        'total_kg_terjual' => (float) $totalTelurKg
                    ],
                    'transactions' => $transactions
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => 'Gagal memuat rekap harian', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Riwayat Setoran
     * Endpoint: GET /api/sales/riwayat-setoran
     */
    public function riwayatSetoran(Request $request)
    {
        try {
            $empCode = auth()->user()->emp_code ?? null;
            $querySetoran = \App\Models\TrSetoranSales::query();

            if ($empCode) {
                $querySetoran->where('emp_code', $empCode);
            }

            if ($request->has('tanggal_awal') && $request->has('tanggal_akhir')) {
                $querySetoran->whereBetween('tanggal', [$request->tanggal_awal, $request->tanggal_akhir]);
            } elseif ($request->has('tanggal')) {
                $querySetoran->whereDate('tanggal', $request->tanggal);
            }

            $setoranList = $querySetoran->orderBy('tanggal', 'desc')->orderBy('rec_datecreated', 'desc')->get();

            $totalSetoranSemua = $setoranList->sum('nominal');
            $jumlahTransaksiSetoran = $setoranList->count();

            $history = $setoranList->map(function($s) {
                // Gunakan rec_datecreated agar terdapat jam & menit
                $waktuLengkap = \Carbon\Carbon::parse($s->rec_datecreated)->format('Y-m-d\TH:i:s\Z');
                
                return [
                    'setoran_code' => $s->setoran_code,
                    'tanggal' => $waktuLengkap,
                    'nominal_setoran' => (float) $s->nominal,
                    'tujuan' => $s->kas_bank_tujuan ?? 'Kas Besar',
                    'catatan' => $s->keterangan,
                    'foto_bukti' => $s->foto_bukti ? asset('storage/' . $s->foto_bukti) : null
                ];
            });

            return response()->json([
                'status' => 'success',
                'data' => [
                    'total_setoran_semua' => (float) $totalSetoranSemua,
                    'jumlah_transaksi_setoran' => $jumlahTransaksiSetoran,
                    'history' => $history
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => 'Gagal memuat riwayat setoran', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Rekap Bulanan (Akun)
     * Endpoint: GET /api/sales/rekap-bulanan
     */
    public function rekapBulanan(Request $request)
    {
        try {
            $bulan = $request->bulan ?? Carbon::now()->format('m');
            $tahun = $request->tahun ?? Carbon::now()->format('Y');
            $empCode = auth()->user()->emp_code ?? null;

            $queryPenjualan = TrPenjualanH::whereMonth('tanggal', $bulan)
                ->whereYear('tanggal', $tahun);

            if ($empCode) {
                $queryPenjualan->where('emp_code', $empCode);
            }

            $penjualanList = $queryPenjualan->get();

            $totalOmsetBulanan = $penjualanList->sum('total_akhir');
            $jumlahTransaksiBulanan = $penjualanList->count();
            $totalLunasBulanan = $penjualanList->sum('total_dibayar');
            $totalPiutangBulanan = $penjualanList->sum('sisa_piutang');

            return response()->json([
                'status' => 'success',
                'data' => [
                    'periode' => "$tahun-$bulan",
                    'total_omset_bulanan' => (float) $totalOmsetBulanan,
                    'total_lunas_bulanan' => (float) $totalLunasBulanan,
                    'total_piutang_bulanan' => (float) $totalPiutangBulanan,
                    'jumlah_transaksi_bulanan' => $jumlahTransaksiBulanan
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => 'Gagal memuat rekap bulanan', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Profil Sales (Mobile)
     * Endpoint: GET /api/sales/profile
     */
    public function profile(Request $request)
    {
        try {
            $user = $request->user();
            $empCode = $user->emp_code ?? null;
            
            // Kalkulasi penjualan bulan ini
            $bulanIni = Carbon::now()->format('m');
            $tahunIni = Carbon::now()->format('Y');

            $queryPenjualan = TrPenjualanH::whereMonth('tanggal', $bulanIni)
                ->whereYear('tanggal', $tahunIni);
                
            if ($empCode) {
                $queryPenjualan->where('emp_code', $empCode);
            } else {
                // Fallback jika tidak ada emp_code, gunakan usr_loginname sebagai pencatat
                $queryPenjualan->where('rec_usercreated', $user->usr_loginname);
            }

            $totalPenjualan = $queryPenjualan->sum('total_akhir');
            $totalTransaksi = $queryPenjualan->count('jual_code');

            return response()->json([
                'status' => 'success',
                'data' => [
                    'name' => $user->usr_loginname,
                    'role' => $user->usr_rolecode,
                    'status' => $user->rec_status == 1 ? 'Aktif' : 'Tidak Aktif',
                    'penjualan_bulan_ini' => (float) $totalPenjualan,
                    'total_transaksi' => (int) $totalTransaksi
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => 'Gagal memuat profil', 'error' => $e->getMessage()], 500);
        }
    }
}


inicontrollernyauntukdashboard