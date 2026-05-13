import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/colors.dart';
import 'core/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/chat_screen.dart';

// Pantallas existentes
import 'screens/home_screen.dart';
import 'screens/lighting_screen.dart';
import 'screens/instruments_screen.dart';
import 'screens/vinyls_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/mis_compras_screen.dart';
import 'screens/pedido_detail_screen.dart';
import 'screens/admin_products_screen.dart';
import 'screens/login_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/checkout_success_screen.dart';
import 'screens/checkout_cancel_screen.dart';
import 'utils/web_message_handler.dart';

// Dashboards admin
import 'screens/admin/super_admin_dashboard.dart';
import 'screens/admin/pedidos_dashboard.dart';
import 'screens/admin/usuarios_dashboard.dart';
import 'screens/admin/inventario_dashboard.dart';
import 'screens/admin/ventas_dashboard.dart';
import 'screens/admin/soporte_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar providers y restaurar sesión antes de mostrar la UI
  final authProvider = AuthProvider();
  await authProvider.init();

  // Solo restaurar historial de chat si el usuario ya está autenticado
  final chatProvider = ChatProvider();
  if (authProvider.estaAutenticado) {
    await chatProvider.init();
  }

  final cartProvider = CartProvider();
  await cartProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: chatProvider),
        ChangeNotifierProvider.value(value: cartProvider),
      ],
      child: const MusiluxApp(),
    ),
  );
}

class MusiluxApp extends StatelessWidget {
  const MusiluxApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Attach web message listener so other tabs/windows can instruct navigation
    try {
      attachMessageListener(navigatorKey);
    } catch (_) {}

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Musilux',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryPurple,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        // ── Públicas ────────────────────────────────────────────────────────
        AppRoutes.catalogoPublico: (context) => const HomeScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        '/instrumentos': (context) => const InstrumentsScreen(),
        '/iluminacion': (context) => const LightingScreen(),
        '/vinilos': (context) => const VinylsScreen(),
        '/contacto': (context) => const ContactScreen(),
        AppRoutes.perfil: (context) => const ProfileScreen(),
        '/mis-compras': (context) => const MisComprasScreen(),
        '/checkout/success': (context) => const CheckoutSuccessScreen(),
        '/checkout/cancel': (context) => const CheckoutCancelScreen(),

        // ── Panel legacy (mantiene compatibilidad) ───────────────────────
        AppRoutes.adminProducts: (context) =>
            const _AuthGuard(child: AdminProductsScreen()),
        '/admin_products': (context) =>
            const _AuthGuard(child: AdminProductsScreen()),

        // ── Dashboards admin por rol ─────────────────────────────────────
        AppRoutes.superAdminDashboard: (context) =>
            const _AuthGuard(child: SuperAdminDashboard()),
        AppRoutes.pedidosDashboard: (context) =>
            const _AuthGuard(child: PedidosDashboard()),
        AppRoutes.usuariosDashboard: (context) =>
            const _AuthGuard(child: UsuariosDashboard()),
        AppRoutes.inventarioDashboard: (context) =>
            const _AuthGuard(child: InventarioDashboard()),
        AppRoutes.ventasDashboard: (context) =>
            const _AuthGuard(child: VentasDashboard()),
        AppRoutes.soporteDashboard: (context) =>
            const _AuthGuard(child: SoporteDashboard()),

        // ── ChatBot IA ───────────────────────────────────────────────────────
        AppRoutes.chat: (context) => const _AuthGuard(child: ChatScreen()),
      },
      onGenerateRoute: (settings) {
        // Ruta dinámica de detalle de producto
        if (settings.name != null &&
            settings.name!.startsWith('/detalle-producto/')) {
          final productId = settings.name!.replaceFirst(
            '/detalle-producto/',
            '',
          );
          return MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: productId),
            settings: settings,
          );
        }
        if (settings.name == '/detalle-producto') {
          return MaterialPageRoute(
            builder: (context) => const ProductDetailScreen(),
            settings: settings,
          );
        }
        // detalle de pedido: /mis-compras/{id}
        if (settings.name != null &&
            settings.name!.startsWith('/mis-compras/')) {
          final pedidoIdStr = settings.name!.replaceFirst('/mis-compras/', '');
          // Permitir tanto IDs numéricos como UUIDs: pasar siempre la cadena.
          return MaterialPageRoute(
            builder: (context) => PedidoDetailScreen(pedidoId: pedidoIdStr),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

/// Guard que verifica autenticación antes de mostrar pantallas protegidas.
/// Redirige a /login si no hay sesión activa.
class _AuthGuard extends StatelessWidget {
  final Widget child;

  const _AuthGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.estaAutenticado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return child;
  }
}
