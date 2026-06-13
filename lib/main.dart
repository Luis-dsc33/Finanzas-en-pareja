import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math' as math;
import 'firebase_options.dart';
import 'features/budget/budget_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/menstrual/menstrual_screen.dart';
import 'services/firebase/auth_service.dart';
import 'services/firebase/transaction_service.dart';
import 'services/firebase/budget_service.dart';
import 'models/transaction_models.dart';
import 'models/budget_models.dart';

// ─────────────────────────────────────────────
// PUNTO DE ENTRADA
// ─────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es_ES', null);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const FinanceAppMockup());
}

// ─────────────────────────────────────────────
// PALETA DE COLORES PASTEL
// ─────────────────────────────────────────────
class AppColors {
  // Fondos
  static const Color background = Color(0xFFF8F5FF);       // Lavanda muy suave
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFCF9FF);

  // Colores principales
  static const Color lavender = Color(0xFFB8A9E8);          // Lavanda principal
  static const Color lavenderDark = Color(0xFF9381D4);       // Lavanda oscuro
  static const Color lavenderLight = Color(0xFFE8E0FF);      // Lavanda claro

  // Acentos pastel
  static const Color pink = Color(0xFFF2B5D4);              // Rosa pastel
  static const Color pinkLight = Color(0xFFFDE2EF);
  static const Color mint = Color(0xFFA8E6CF);              // Menta pastel
  static const Color mintLight = Color(0xFFDDF5E7);
  static const Color peach = Color(0xFFFFD3B6);             // Melocotón pastel
  static const Color peachLight = Color(0xFFFFEBDE);
  static const Color skyBlue = Color(0xFFA8D8EA);           // Azul cielo pastel
  static const Color skyBlueLight = Color(0xFFDDF0F7);
  static const Color lemon = Color(0xFFFFF5BA);             // Limón pastel
  static const Color lemonLight = Color(0xFFFFFBE0);
  static const Color coral = Color(0xFFFFADAD);             // Coral pastel

  // Texto
  static const Color textPrimary = Color(0xFF3D3456);       // Morado oscuro
  static const Color textSecondary = Color(0xFF8E82A6);     // Gris lavanda
  static const Color textLight = Color(0xFFB8AECB);         // Gris claro
}

// ─────────────────────────────────────────────
// APP PRINCIPAL
// ─────────────────────────────────────────────
class FinanceAppMockup extends StatelessWidget {
  const FinanceAppMockup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nuestras Finanzas 💕',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.lavender,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.lavender,
          surface: AppColors.cardBackground,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// PANTALLA DE LOGIN
// ─────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F5FF),
              Color(0xFFFDE2EF),
              Color(0xFFE8E0FF),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono/Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.lavenderLight,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lavender.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '💰',
                          style: TextStyle(fontSize: 52),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Título
                    const Text(
                      'Nuestras\nFinanzas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Juntos construimos\nnuestro futuro 💕',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Formulario de inicio de sesión
                    const _LoginForm(),
                    const SizedBox(height: 16),
                    Text(
                      'Al iniciar sesión, aceptas nuestros\ntérminos y condiciones',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({Key? key}) : super(key: key);

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_userController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    final userCred = await AuthService().signIn(
      context,
      _userController.text,
      _passwordController.text,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (userCred != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _userController,
          decoration: InputDecoration(
            hintText: 'Usuario (Luisito o Miri)',
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.person_outline, color: AppColors.lavender),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Contraseña',
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.lavender),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lavender,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Entrar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// NAVEGACIÓN PRINCIPAL (Bottom Nav)
// ─────────────────────────────────────────────
class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    BudgetScreen(),
    GoalsScreen(),
    MenstrualScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.lavender.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.home_rounded,
                label: 'Inicio',
                isSelected: _currentIndex == 0,
                color: AppColors.lavender,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavBarItem(
                icon: Icons.receipt_long_rounded,
                label: 'Gastos',
                isSelected: _currentIndex == 1,
                color: AppColors.pink,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavBarItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Plan',
                isSelected: _currentIndex == 2,
                color: AppColors.skyBlue,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavBarItem(
                icon: Icons.savings_rounded,
                label: 'Metas',
                isSelected: _currentIndex == 3,
                color: AppColors.mint,
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _NavBarItem(
                icon: Icons.favorite_rounded,
                label: 'Ciclo',
                isSelected: _currentIndex == 4,
                color: AppColors.pink,
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context),
        backgroundColor: AppColors.lavender,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
    // Si se guardó una transacción, refrescar la pantalla actual
    if (result == true) {
      setState(() {}); // Forzar rebuild para que TransactionsScreen recargue
    }
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textLight,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PANTALLA DASHBOARD
// ─────────────────────────────────────────────
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, Miri & Luisito 👋',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Junio 2026',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                // Avatares (Botón para cerrar sesión)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: const Text('Cerrar sesión',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar',
                                style: TextStyle(color: AppColors.textSecondary)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.coral,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              await AuthService().signOut();
                            },
                            child: const Text('Salir'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.lavenderLight),
                    ),
                    child: Row(
                      children: [
                        _buildAvatar('M', AppColors.pink),
                        Transform.translate(
                          offset: const Offset(-8, 0),
                          child: _buildAvatar('L', AppColors.lavender),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.logout_rounded, size: 16, color: AppColors.coral),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tarjeta de Balance
            _buildBalanceCard(),
            const SizedBox(height: 20),

            // Ingreso vs Gasto rápido
            Row(
              children: [
                Expanded(
                    child: _buildQuickStat(
                        '📥', 'Ingresos', '\$30,000', AppColors.mintLight,
                        AppColors.mint)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildQuickStat(
                        '📤', 'Gastos', '\$11,550', AppColors.pinkLight,
                        AppColors.pink)),
              ],
            ),
            const SizedBox(height: 24),

            // Metas de ahorro mini
            _buildSectionTitle('Metas de ahorro', '✨'),
            const SizedBox(height: 12),
            SizedBox(
              height: 115,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildMiniGoalCard(
                    emoji: '🏠',
                    title: 'Casa Querétaro',
                    progress: 0.30,
                    color: AppColors.lavender,
                    bgColor: AppColors.lavenderLight,
                  ),
                  const SizedBox(width: 12),
                  _buildMiniGoalCard(
                    emoji: '🏖️',
                    title: 'Puerto Escondido',
                    progress: 0.375,
                    color: AppColors.skyBlue,
                    bgColor: AppColors.skyBlueLight,
                  ),
                  const SizedBox(width: 12),
                  _buildMiniGoalCard(
                    emoji: '🚗',
                    title: 'Auto nuevo',
                    progress: 0.12,
                    color: AppColors.peach,
                    bgColor: AppColors.peachLight,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gastos recientes
            _buildSectionTitle('Gastos recientes', '📝'),
            const SizedBox(height: 12),
            _buildTransactionItem(
              emoji: '🛒',
              title: 'Supermercado',
              subtitle: 'Hoy · Miri',
              amount: -1250.00,
              color: AppColors.peach,
            ),
            _buildTransactionItem(
              emoji: '💡',
              title: 'Pago de Luz',
              subtitle: 'Ayer · Luisito',
              amount: -350.00,
              color: AppColors.lemon,
            ),
            _buildTransactionItem(
              emoji: '🍕',
              title: 'Salida a cenar',
              subtitle: 'Lun · Ambos',
              amount: -480.00,
              color: AppColors.coral,
            ),
            _buildTransactionItem(
              emoji: '💰',
              title: 'Depósito quincena',
              subtitle: 'Dom · Luisito',
              amount: 15000.00,
              color: AppColors.mint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String letter, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardBackground, width: 2.5),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFCBB6F0),
            Color(0xFFE8A4C8),
            Color(0xFFF2C6A0),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavender.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '💕 Presupuesto juntos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '\$18,450',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const Text(
            'disponible este mes',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          // Barra de progreso del presupuesto
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.385,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '38.5% del presupuesto gastado',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      String emoji, String label, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String emoji) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$emoji $title',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Ver todo',
            style: TextStyle(
              color: AppColors.lavender,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniGoalCard({
    required String emoji,
    required String title,
    required double progress,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text('${(progress * 100).toInt()}%',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String emoji,
    required String title,
    required String subtitle,
    required double amount,
    required Color color,
  }) {
    bool isIncome = amount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}\$${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isIncome ? const Color(0xFF5FB87A) : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PANTALLA TRANSACCIONES
// ─────────────────────────────────────────────
// TransactionsScreen ahora está en features/transactions/transactions_screen.dart

// ─────────────────────────────────────────────
// PANTALLA METAS DE AHORRO
// ─────────────────────────────────────────────
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nuestras metas 🎯',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Juntos lo logramos 💪',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Resumen total ahorrado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA8E6CF), Color(0xFF88D8B0)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mint.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  const Text(
                    'Total ahorrado',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const Text(
                    '\$24,300',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'de \$112,000 en total',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tarjetas de metas individuales
            _buildGoalDetailCard(
              emoji: '🏠',
              title: 'Fondo Casa Querétaro',
              current: 15000,
              target: 50000,
              monthlyTarget: 3780,
              color: AppColors.lavender,
              bgColor: AppColors.lavenderLight,
              daysLeft: 180,
            ),
            const SizedBox(height: 16),
            _buildGoalDetailCard(
              emoji: '🏖️',
              title: 'Viaje Puerto Escondido',
              current: 4500,
              target: 12000,
              monthlyTarget: 1000,
              color: AppColors.skyBlue,
              bgColor: AppColors.skyBlueLight,
              daysLeft: 90,
            ),
            const SizedBox(height: 16),
            _buildGoalDetailCard(
              emoji: '🚗',
              title: 'Auto nuevo',
              current: 4800,
              target: 50000,
              monthlyTarget: 2500,
              color: AppColors.peach,
              bgColor: AppColors.peachLight,
              daysLeft: 365,
            ),
            const SizedBox(height: 24),

            // Deudas activas
            const Text(
              'Deudas activas 💳',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildDebtCard(
              title: 'Tarjeta BBVA',
              balance: 8500,
              monthlyPayment: 1200,
              color: AppColors.pink,
            ),
            const SizedBox(height: 10),
            _buildDebtCard(
              title: 'Crédito Coppel',
              balance: 3200,
              monthlyPayment: 450,
              color: AppColors.coral,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalDetailCard({
    required String emoji,
    required String title,
    required double current,
    required double target,
    required double monthlyTarget,
    required Color color,
    required Color bgColor,
    required int daysLeft,
  }) {
    double progress = current / target;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary)),
                    Text('Faltan $daysLeft días',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${current.toStringAsFixed(0)} ahorrado',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              Text(
                'Meta: \$${target.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  'Aporte mensual: \$${monthlyTarget.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard({
    required String title,
    required double balance,
    required double monthlyPayment,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
                child: Text('💳', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 15)),
                Text('Pago mensual: \$${monthlyPayment.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            '\$${balance.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PANTALLA ASESOR IA (GEMINI)
// ─────────────────────────────────────────────
class GeminiAdvisorScreen extends StatelessWidget {
  const GeminiAdvisorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Asesora financiera ✨',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Impulsada por Gemini AI',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Insight principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.lavender.withOpacity(0.15),
                    AppColors.pink.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lavender.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lavender.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('🧠', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Resumen del mes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Hola Miri y Luisito! 💕 Este mes van por buen camino. Han gastado el 38.5% de su presupuesto y estamos a mitad de mes, eso es excelente.\n\nSin embargo, noté que el gasto en "Comida fuera" subió un 15% respecto al mes pasado. Si lo mantienen controlado, podrían aportar \$500 extras al viaje a Puerto Escondido 🏖️',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Alertas
            const Text(
              'Alertas 🔔',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildAlertCard(
              emoji: '⚠️',
              title: 'Gasto en comida elevado',
              description:
                  'Llevan \$2,541 en comida fuera. El promedio mensual es \$2,100.',
              color: AppColors.peach,
              bgColor: AppColors.peachLight,
            ),
            const SizedBox(height: 10),
            _buildAlertCard(
              emoji: '✅',
              title: 'Meta casa en buen ritmo',
              description:
                  'El aporte de \$3,780 al Fondo Casa Querétaro está al día. ¡Sigan así!',
              color: AppColors.mint,
              bgColor: AppColors.mintLight,
            ),
            const SizedBox(height: 10),
            _buildAlertCard(
              emoji: '💡',
              title: 'Tip de ahorro',
              description:
                  'Si reducen salidas a cenar a 2 veces por semana, ahorrarían ~\$800/mes.',
              color: AppColors.lavender,
              bgColor: AppColors.lavenderLight,
            ),
            const SizedBox(height: 24),

            // Validación de metas
            const Text(
              'Estado de metas 📊',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildGoalStatus('🏠', 'Casa Querétaro', 'En buen ritmo', AppColors.mint, true),
            const SizedBox(height: 8),
            _buildGoalStatus('🏖️', 'Puerto Escondido', 'Necesita atención', AppColors.peach, false),
            const SizedBox(height: 8),
            _buildGoalStatus('🚗', 'Auto nuevo', 'Atrasado', AppColors.coral, false),
            const SizedBox(height: 24),

            // Botón de consulta
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lavender,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('✨', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'Pedir nuevo análisis',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String emoji,
    required String title,
    required String description,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStatus(
      String emoji, String title, String status, Color color, bool isOnTrack) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOnTrack
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM SHEET – AGREGAR TRANSACCIÓN
// ─────────────────────────────────────────────
class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({Key? key}) : super(key: key);

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  final BudgetService _budgetService = BudgetService();

  int _selectedCategory = 0;
  String _selectedPaidBy = 'Ambos';
  bool _isAntExpense = false;
  bool _isSaving = false;

  List<ExpenseCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final weekId = BudgetService.getCurrentWeekId();
    final budget = await _budgetService.getBudget(weekId);
    if (budget != null && mounted) {
      setState(() => _categories = budget.expenseCategories);
    } else if (mounted) {
      setState(() => _categories = [
            ExpenseCategory(name: 'Casa', emoji: '🏠'),
            ExpenseCategory(name: 'Comida', emoji: '🍔'),
            ExpenseCategory(name: 'Familia', emoji: '❤️'),
            ExpenseCategory(name: 'Transporte', emoji: '🚗'),
            ExpenseCategory(name: 'Viajes', emoji: '✈️'),
            ExpenseCategory(name: 'Deudas', emoji: '💳'),
            ExpenseCategory(name: 'Salud', emoji: '🏥'),
            ExpenseCategory(name: 'Suscripciones', emoji: '📱'),
            ExpenseCategory(name: 'Cuidado personal', emoji: '💅'),
            ExpenseCategory(name: 'Entretenimiento', emoji: '🎭'),
            ExpenseCategory(name: 'Otros', emoji: '📦'),
          ]);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty ||
        _descriptionController.text.isEmpty) return;

    setState(() => _isSaving = true);

    final cat = _categories[_selectedCategory];
    final item = TransactionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: _descriptionController.text,
      amount: double.tryParse(_amountController.text) ?? 0,
      categoryName: cat.name,
      categoryEmoji: cat.emoji,
      paidBy: _selectedPaidBy,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      date: DateTime.now(),
      isAntExpense: _isAntExpense,
    );

    final weekId = BudgetService.getCurrentWeekId();
    await _transactionService.addTransaction(weekId, item);

    if (mounted) {
      Navigator.pop(context, true); // true = se guardó algo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Título
            const Text(
              'Nuevo gasto ✏️',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Descripción
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '¿En qué gastaste?',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.lavenderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.lavenderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppColors.pink, width: 2),
                ),
                prefixIcon: const Icon(Icons.shopping_bag_outlined,
                    color: AppColors.pink),
              ),
            ),
            const SizedBox(height: 14),

            // Campo de monto
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                prefixStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.pink,
                  fontSize: 18,
                ),
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.lavenderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.lavenderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppColors.pink, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Categorías
            const Text(
              'Categoría',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_categories.length, (index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == index;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.pink.withOpacity(0.2)
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.pink
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${cat.emoji} ${cat.name}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.pink
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),

            // ¿Quién pagó?
            const Text(
              '¿Quién pagó?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: ['Miri', 'Luisito', 'Ambos'].map((name) {
                final isSelected = _selectedPaidBy == name;
                Color chipColor;
                if (name == 'Miri') {
                  chipColor = AppColors.pink;
                } else if (name == 'Luisito') {
                  chipColor = AppColors.skyBlue;
                } else {
                  chipColor = AppColors.lavender;
                }
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPaidBy = name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? chipColor.withOpacity(0.2)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? chipColor
                                : AppColors.lavenderLight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isSelected
                                  ? chipColor
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Nota y Hormiga
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Nota (opcional)',
                      labelStyle:
                          TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: AppColors.lavenderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: AppColors.lavenderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: AppColors.pink, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.edit_note_rounded,
                          color: AppColors.textLight, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () =>
                      setState(() => _isAntExpense = !_isAntExpense),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isAntExpense
                          ? AppColors.lemon.withOpacity(0.4)
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isAntExpense
                            ? AppColors.lemon
                            : AppColors.lavenderLight,
                      ),
                    ),
                    child: const Center(
                      child: Text('🐜', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _saveTransaction,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Guardar gasto ✨',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
