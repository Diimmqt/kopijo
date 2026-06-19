import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/menu_provider.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'paid', 'canceled'

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getTransactions();
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat transaksi: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Transaction> get _filteredTransactions {
    return _transactions.where((tx) {
      final matchesSearch = tx.transactionCode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      final matchesStatus = _statusFilter == 'all' || tx.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _showTransactionDetail(Transaction transaction) async {
    // Fetch detailed transaction with items
    if (transaction.id == null) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<Transaction>(
          future: ApiService.getTransactionById(transaction.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6F4E37)));
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text(snapshot.error.toString()),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
              );
            }
            final txDetail = snapshot.data!;
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final menu = Provider.of<MenuProvider>(context, listen: false);

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Detail Transaksi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: txDetail.status == 'paid' ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      txDetail.status == 'paid' ? 'LUNAS' : 'BATAL',
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: txDetail.status == 'paid' ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailRow('Kode', txDetail.transactionCode ?? ''),
                      _buildDetailRow('Tanggal', txDetail.createdAt != null ? _dateFormat.format(txDetail.createdAt!) : '-'),
                      _buildDetailRow('Metode', txDetail.paymentMethod.toUpperCase()),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('Daftar Produk:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...txDetail.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.quantity.toInt()}x ${item.productName ?? 'Produk'} ${item.variantName != null ? "(${item.variantName})" : ""}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(_currencyFormat.format(item.subtotal)),
                                ],
                              ),
                              if (item.modifiers.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12.0, top: 2),
                                  child: Text(
                                    '+ ' + item.modifiers.map((m) => '${m.modifierName} (+${_currencyFormat.format(m.priceAdjustment)})').join(', '),
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildDetailRow('Subtotal', _currencyFormat.format(txDetail.subtotal)),
                      _buildDetailRow('Diskon', '- ' + _currencyFormat.format(txDetail.discount)),
                      _buildDetailRow('Pajak PPN (11%)', _currencyFormat.format(txDetail.tax)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL AKHIR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            _currencyFormat.format(txDetail.total),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6F4E37)),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildDetailRow('Jumlah Bayar', _currencyFormat.format(txDetail.amountPaid)),
                      _buildDetailRow('Uang Kembalian', _currencyFormat.format(txDetail.changeAmount)),
                    ],
                  ),
                ),
              ),
              actions: [
                // Admin can cancel paid transactions
                if (auth.isAdmin && txDetail.status == 'paid')
                  TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Batalkan Transaksi?'),
                          content: const Text(
                            'Apakah Anda yakin ingin membatalkan transaksi ini? Stok produk akan otomatis dikembalikan ke gudang.',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () => Navigator.pop(context, true), 
                              child: const Text('Ya, Batalkan')
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await ApiService.updateTransactionStatus(txDetail.id!, 'canceled');
                          await menu.fetchMenu(); // Refresh stock in POS too!
                          if (context.mounted) {
                            Navigator.pop(context); // Close detail dialog
                            _fetchTransactions(); // Reload this page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Transaksi telah dibatalkan & stok dikembalikan!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal membatalkan: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Batalkan Transaksi', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
      ),
      body: Column(
        children: [
          // Filter section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Search field
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Cari Kode TRX...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Dropdown status filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Semua')),
                          DropdownMenuItem(value: 'paid', child: Text('Lunas')),
                          DropdownMenuItem(value: 'canceled', child: Text('Batal')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _statusFilter = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6F4E37)))
                : _filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('Tidak ada riwayat transaksi.', style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = _filteredTransactions[index];
                          final isPaid = tx.status == 'paid';
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              onTap: () => _showTransactionDetail(tx),
                              leading: CircleAvatar(
                                backgroundColor: isPaid ? Colors.green[50] : Colors.red[50],
                                child: Icon(
                                  isPaid ? Icons.check : Icons.close,
                                  color: isPaid ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                tx.transactionCode ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                tx.createdAt != null 
                                    ? _dateFormat.format(tx.createdAt!) + ' • ' + tx.paymentMethod.toUpperCase()
                                    : '',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currencyFormat.format(tx.total),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: isPaid ? const Color(0xFF6F4E37) : Colors.red,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    isPaid ? 'Lunas' : 'Batal',
                                    style: TextStyle(fontSize: 11, color: isPaid ? Colors.green : Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
