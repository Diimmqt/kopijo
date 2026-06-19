import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/cart_provider.dart';
import 'services/api_service.dart';
import 'views/role_selection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init(); // Initialize dynamic backend IP setup
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()..fetchMenu()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Kopi Jo POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4E3629), // Rich Espresso
            primary: const Color(0xFF6F4E37),    // Coffee Brown
            secondary: const Color(0xFFC5A880),  // Warm Latte
            tertiary: const Color(0xFFE5A65D),   // Amber Caramel
            surface: const Color(0xFFFAF7F5),    // Warm Cream background
            background: const Color(0xFFFAF7F5),
          ),
          cardTheme: const CardTheme(
            color: Colors.white,
            elevation: 2,
            margin: EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF4E3629),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          fontFamily: 'Roboto', // Default fallback, custom look with styling
          textTheme: const TextTheme(
            headlineLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4E3629)),
            headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4E3629)),
            titleLarge: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4E3629)),
            bodyLarge: TextStyle(color: Color(0xFF2C1E17)),
          ),
        ),
        home: const RoleSelectionPage(),
      ),
    );
  }
}
