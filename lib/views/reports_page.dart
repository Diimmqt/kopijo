import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _salesData = {};
  List<dynamic> _popularProducts = [];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final sales = await ApiService.getSalesReport();
      final popular = await ApiService.getPopularProductsReport();
      setState(() {
        _salesData = sales;
        _popularProducts = popular;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat laporan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Calculate summaries safely
  double get _todayRevenue {
    final dailyList = _salesData['daily'] as List?;
    if (dailyList == null || dailyList.isEmpty) return 0.0;
    
    // Check if the latest date matches today
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayMatch = dailyList.firstWhere(
      (element) => element['date'].toString().substring(0, 10) == todayStr,
      orElse: () => null,
    );
    
    return todayMatch != null ? double.parse(todayMatch['revenue'].toString()) : 0.0;
  }

  double get _monthRevenue {
    final monthlyList = _salesData['monthly'] as List?;
    if (monthlyList == null || monthlyList.isEmpty) return 0.0;
    
    final currentMonthStr = DateFormat('yyyy-MM').format(DateTime.now());
    final monthMatch = monthlyList.firstWhere(
      (element) => element['month'] == currentMonthStr,
      orElse: () => null,
    );
    
    return monthMatch != null ? double.parse(monthMatch['revenue'].toString()) : 0.0;
  }

  int get _totalTransactions {
    final dailyList = _salesData['daily'] as List?;
    if (dailyList == null) return 0;
    return dailyList.fold(0, (sum, item) => sum + int.parse(item['transaction_count'].toString()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6F4E37)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI SUMMARY CARD ROW
                  Row(
                    children: [
                      _buildKpiCard(
                        context,
                        title: 'Pendapatan Hari Ini',
                        value: _currencyFormat.format(_todayRevenue),
                        icon: Icons.today_rounded,
                        color: const Color(0xFF6F4E37),
                      ),
                      const SizedBox(width: 16),
                      _buildKpiCard(
                        context,
                        title: 'Pendapatan Bulan Ini',
                        value: _currencyFormat.format(_monthRevenue),
                        icon: Icons.calendar_month_rounded,
                        color: const Color(0xFF4E3629),
                      ),
                      const SizedBox(width: 16),
                      _buildKpiCard(
                        context,
                        title: 'Total Transaksi Lunas',
                        value: '$_totalTransactions TRX',
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFFE5A65D),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // CHARTS GRID ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Daily line chart card
                      Expanded(
                        flex: 3,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tren Pendapatan Harian (30 Hari Terakhir)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4E3629)),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 300,
                                  child: _buildDailyLineChart(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Payment Methods Pie Chart card
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Metode Pembayaran Terpopuler',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4E3629)),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 300,
                                  child: _buildPaymentMethodPieChart(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // POPULAR PRODUCTS LIST
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Produk Terlaris (Top 10)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4E3629)),
                            ),
                            const SizedBox(height: 16),
                            _popularProducts.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Text(
                                        'Belum ada data penjualan produk.',
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    ),
                                  )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _popularProducts.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final prod = _popularProducts[index];
                                    final rank = index + 1;
                                    
                                    IconData icon;
                                    Color badgeColor;
                                    if (rank == 1) {
                                      icon = Icons.emoji_events;
                                      badgeColor = const Color(0xFFD4AF37); // Gold
                                    } else if (rank == 2) {
                                      icon = Icons.emoji_events;
                                      badgeColor = const Color(0xFFC0C0C0); // Silver
                                    } else if (rank == 3) {
                                      icon = Icons.emoji_events;
                                      badgeColor = const Color(0xFFCD7F32); // Bronze
                                    } else {
                                      icon = Icons.star_border;
                                      badgeColor = Colors.grey;
                                    }

                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: badgeColor.withOpacity(0.1),
                                        child: Icon(icon, color: badgeColor),
                                      ),
                                      title: Text(
                                        prod['name'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        'Kategori: ${prod['type']?.toString().toUpperCase() ?? '-'}',
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${double.parse(prod['quantity_sold'].toString()).toStringAsFixed(0)} Terjual',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          Text(
                                            _currencyFormat.format(double.parse(prod['total_revenue'].toString())),
                                            style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLineChart() {
    final dailyList = _salesData['daily'] as List?;
    if (dailyList == null || dailyList.isEmpty) {
      return const Center(child: Text('Belum ada data grafik harian'));
    }

    // Convert daily list into FlSpot. We reverse to show chronologically from past to today.
    final List<FlSpot> spots = [];
    final reversedList = dailyList.reversed.toList();
    
    // We only show up to 7 spots for visibility in UI
    final limitList = reversedList.length > 7 
        ? reversedList.sublist(reversedList.length - 7) 
        : reversedList;

    for (int i = 0; i < limitList.length; i++) {
      spots.add(FlSpot(i.toDouble(), double.parse(limitList[i]['revenue'].toString())));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final int idx = val.toInt();
                if (idx >= 0 && idx < limitList.length) {
                  final dateStr = limitList[idx]['date'].toString().substring(5, 10); // MM-DD
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 64,
              getTitlesWidget: (val, meta) {
                return Text(
                  _currencyFormat.format(val).replaceAll('Rp ', ''),
                  style: const TextStyle(fontSize: 9, color: Colors.black54),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF6F4E37),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF6F4E37).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodPieChart() {
    final payments = _salesData['payments'] as List?;
    if (payments == null || payments.isEmpty) {
      return const Center(child: Text('Belum ada data pembayaran'));
    }

    final colors = [
      const Color(0xFF6F4E37), // Cash
      const Color(0xFFE5A65D), // QRIS
      const Color(0xFFC5A880), // Transfer
    ];

    double totalRevenue = payments.fold(0.0, (sum, item) => sum + double.parse(item['revenue'].toString()));

    int colorIdx = 0;
    List<PieChartSectionData> sections = payments.map((item) {
      final double revenue = double.parse(item['revenue'].toString());
      final double percent = totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0.0;
      final color = colors[colorIdx % colors.length];
      colorIdx++;

      return PieChartSectionData(
        color: color,
        value: revenue,
        title: '${percent.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        // Legend
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: payments.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final color = colors[idx % colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  '${item['payment_method'].toString().toUpperCase()}: ${_currencyFormat.format(double.parse(item['revenue'].toString()))}',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
