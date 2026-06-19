import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/cart_provider.dart';

import 'pos_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _paymentMethod = 'cash'; // 'cash', 'qris', 'transfer'
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  
  double _cashPaid = 0.0;
  String _bankName = '';
  bool _isProcessing = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _cashController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  // Quick cash helper options
  List<double> _getQuickCashOptions(double total) {
    final List<double> bases = [10000, 20000, 50000, 100000];
    final Set<double> options = {total};

    for (var base in bases) {
      if (base > total) {
        options.add(base);
      }
      // Combine bases (e.g., if total is 35k, add 50k, or if total is 65k, add 100k, etc.)
      double multiplier = (total / base).ceil() * base;
      if (multiplier > total) {
        options.add(multiplier);
      }
    }
    
    // Sort and take top 4 options
    final sorted = options.toList()..sort();
    return sorted.take(4).toList();
  }

  Future<void> _processCheckout() async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    double finalAmountPaid = cart.total;
    if (_paymentMethod == 'cash') {
      if (_cashPaid < cart.total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uang tunai yang dibayarkan kurang!')),
        );
        return;
      }
      finalAmountPaid = _cashPaid;
    }

    setState(() => _isProcessing = true);

    try {
      final response = await cart.checkout(
        paymentMethod: _paymentMethod,
        amountPaid: finalAmountPaid,
        userId: null, // user_id opsional (nullable di DB)
      );

      if (mounted) {
        _showSuccessDialog(response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaksi Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> response) {
    final double changeAmount = response['change_amount'] != null 
        ? double.parse(response['change_amount'].toString()) 
        : 0.0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button closing
          child: AlertDialog(
            icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            title: const Text('Pembayaran Berhasil!'),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Kode Transaksi: ${response['transaction_code']}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildReceiptRow('Subtotal', _currencyFormat.format(response['subtotal'])),
                    _buildReceiptRow('Total Bayar', _currencyFormat.format(response['total'])),
                    _buildReceiptRow('Metode', _paymentMethod.toUpperCase()),
                    _buildReceiptRow('Uang Diterima', _currencyFormat.format(response['total'] + changeAmount)),
                    const Divider(),
                    _buildReceiptRow(
                      'KEMBALIAN', 
                      _currencyFormat.format(changeAmount), 
                      isHighlight: true
                    ),
                    const SizedBox(height: 16),
                    // Receipt Styled Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.print, color: Colors.black54),
                          SizedBox(height: 4),
                          Text(
                            'Struk thermal siap dicetak...',
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6F4E37),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const PosPage()),
                    (route) => false, // Clear route history
                  );
                },
                child: const Text('Selesai & Buka POS Baru'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              fontSize: isHighlight ? 16 : 14,
              color: isHighlight ? const Color(0xFF6F4E37) : Colors.black87,
            )
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              fontSize: isHighlight ? 18 : 14,
              color: isHighlight ? const Color(0xFF6F4E37) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    final double change = _cashPaid - cart.total;
    final bool canPay = _paymentMethod != 'cash' || _cashPaid >= cart.total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selesaikan Pembayaran'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6F4E37)))
          : Row(
              children: [
                // Left side: Transaction Summary
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ringkasan Pesanan',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4E3629)),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.separated(
                                itemCount: cart.items.length,
                                separatorBuilder: (_, __) => const Divider(height: 12),
                                itemBuilder: (context, index) {
                                  final item = cart.items[index];
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.quantity.toInt()}x ',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.product.name,
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            if (item.variant != null)
                                              Text(
                                                'Varian: ${item.variant!.name}',
                                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text(_currencyFormat.format(item.subtotal)),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildReceiptRow('Subtotal', _currencyFormat.format(cart.subtotal)),
                            _buildReceiptRow('Diskon', '- ${_currencyFormat.format(cart.discount)}'),
                            _buildReceiptRow('Pajak PPN (11%)', _currencyFormat.format(cart.taxAmount)),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Tagihan',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4E3629)),
                                ),
                                Text(
                                  _currencyFormat.format(cart.total),
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6F4E37)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Right side: Payment Methods & Action
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0, right: 24.0, bottom: 24.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pilih Metode Pembayaran',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4E3629)),
                            ),
                            const SizedBox(height: 16),
                            
                            // Payment method tab bar
                            Row(
                              children: [
                                _buildMethodTab('cash', Icons.money_rounded, 'Uang Tunai'),
                                const SizedBox(width: 12),
                                _buildMethodTab('qris', Icons.qr_code_2_rounded, 'QRIS Dinamis'),
                                const SizedBox(width: 12),
                                _buildMethodTab('transfer', Icons.account_balance_rounded, 'Transfer Bank'),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Method Details Interface
                            Expanded(
                              child: SingleChildScrollView(
                                child: _buildMethodDetails(cart.total),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Process button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canPay ? const Color(0xFF6F4E37) : Colors.grey[400],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: canPay ? _processCheckout : null,
                                child: Text(
                                  _paymentMethod == 'cash' 
                                      ? 'Selesaikan Tunai (Kembalian: ${_currencyFormat.format(change < 0 ? 0.0 : change)})'
                                      : 'Konfirmasi Bayar',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMethodTab(String method, IconData icon, String label) {
    final isSelected = _paymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _paymentMethod = method;
            _cashPaid = 0.0;
            _cashController.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6F4E37) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF6F4E37) : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF6F4E37),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodDetails(double total) {
    if (_paymentMethod == 'cash') {
      final change = _cashPaid - total;
      final quickCash = _getQuickCashOptions(total);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Uang Tunai Diterima',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cashController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              border: const OutlineInputBorder(),
              errorText: _cashPaid > 0 && _cashPaid < total 
                  ? 'Jumlah bayar kurang dari total tagihan!' 
                  : null,
            ),
            onChanged: (val) {
              setState(() {
                _cashPaid = double.tryParse(val) ?? 0.0;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Uang Pas / Uang Cepat',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 8),
          
          // Quick Cash buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickCash.map((amount) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6F4E37),
                  side: const BorderSide(color: Color(0xFF6F4E37)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  setState(() {
                    _cashPaid = amount;
                    _cashController.text = amount.toInt().toString();
                  });
                },
                child: Text(
                  amount == total ? 'Uang Pas' : _currencyFormat.format(amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Uang Kembalian',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              Text(
                _currencyFormat.format(change < 0 ? 0.0 : change),
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: change < 0 ? Colors.red : Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      );
    } else if (_paymentMethod == 'qris') {
      // Mock QRIS payload format
      final qrisPayload = "00020101021226300016COM.QRIS.DEEPPING011893600002001234567852045812530336054${total.toInt()}5802ID5910KopiJoPOS6006Jakarta6304A1B2";
      
      return Center(
        child: Column(
          children: [
            const Text(
              'Scan Kode QRIS di Bawah Ini',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4E3629)),
            ),
            const SizedBox(height: 8),
            Text(
              'Nilai bayar otomatis diset ke ${_currencyFormat.format(total)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 20),
            
            // Dynamic QRIS visual representation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: QrImageView(
                data: qrisPayload,
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
                embeddedImageStyle: const QrEmbeddedImageStyle(
                  size: Size(30, 30),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security_rounded, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text('QRIS dinamis terverifikasi aman', style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ],
        ),
      );
    } else {
      // Bank Transfer details
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Rekening Bank Kopi Jo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bank Central Asia (BCA)', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('No. Rekening: 832-1234-998', style: TextStyle(fontSize: 16, color: Color(0xFF6F4E37), fontWeight: FontWeight.bold)),
                Text('Atas Nama: PT Kopi Jo Nusantara', style: TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nama Bank Pengirim / Catatan Referensi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bankController,
            decoration: const InputDecoration(
              hintText: 'Contoh: Mandiri - Budi Santoso',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description_outlined),
            ),
            onChanged: (val) {
              setState(() {
                _bankName = val;
              });
            },
          ),
        ],
      );
    }
  }
}
