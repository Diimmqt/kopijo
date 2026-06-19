import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'pos_page.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ipController.text = ApiService.baseUrl;
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _showIpSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pengaturan API Backend'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan alamat IP dan port server backend Node.js Anda:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'Alamat Server URL',
                  hintText: 'http://localhost:3000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dns),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final url = _ipController.text.trim();
                if (url.isNotEmpty) {
                  await ApiService.updateBaseUrl(url);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Server API diupdate ke: $url')),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showPinDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Color(0xFF6F4E37)),
              SizedBox(width: 8),
              Text('Autentikasi Admin'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan PIN Admin untuk masuk ke halaman Manajemen & Laporan:'),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 16, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                  hintText: '••••',
                ),
                onChanged: (val) async {
                  if (val.length == 4) {
                    final success = await auth.loginAsAdmin(val);
                    if (context.mounted) {
                      if (success) {
                        Navigator.pop(context); // Close dialog
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const PosPage()),
                        );
                      } else {
                        pinController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PIN salah! Silakan coba lagi.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          // Background soft decor
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top settings bar
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Color(0xFF4E3629), size: 28),
                      onPressed: _showIpSettings,
                      tooltip: 'Pengaturan Server API',
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Coffee App Logo
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.coffee_rounded,
                    size: 80,
                    color: Color(0xFF6F4E37),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'KOPI JO',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    letterSpacing: 2,
                    color: const Color(0xFF4E3629),
                  ),
                ),
                Text(
                  'Sistem POS Kasir Premium',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Selection Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Cashier card
                      GestureDetector(
                        onTap: () async {
                          await auth.loginAsCashier();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const PosPage()),
                            );
                          }
                        },
                        child: _buildRoleCard(
                          context,
                          title: 'KASIR',
                          subtitle: 'Buka POS & layani transaksi pelanggan',
                          icon: Icons.point_of_sale_rounded,
                          color: const Color(0xFF6F4E37),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Admin card
                      GestureDetector(
                        onTap: () => _showPinDialog(context),
                        child: _buildRoleCard(
                          context,
                          title: 'ADMINISTRATOR',
                          subtitle: 'Atur menu, kelola stok, & lihat laporan',
                          icon: Icons.admin_panel_settings_rounded,
                          color: const Color(0xFF4E3629),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 3),
                
                // Footer
                Text(
                  'v1.0.0 • Google DeepMind Pair Programming',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5)),
        ],
      ),
    );
  }
}
