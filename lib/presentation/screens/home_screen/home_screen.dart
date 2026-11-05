import 'package:flutter/material.dart';

import '../../../application/auth/auth_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/user_role.dart';
import '../../../utils/routes.dart';
import '../../widgets/home_widgets/health_dashboard.dart';
import '../../widgets/home_widgets/reference_ui.dart';
import '../../widgets/home_widgets/sanad_bottom_navigation.dart';

const _pureBlack = Color(0xFFFFFFFF);
const _darkCard = Color(0xFFF7F7F8);

const _muted = Color(0xFF85858B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.authService});
  final AuthService? authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthService _auth = widget.authService ?? AuthService.firebase();
  late Future<AppUser?> _profile;
  bool _signingOut = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _profile = _auth.getCurrentUserProfile();
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.splash, (_) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.signOutFailed)));
      setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ReferenceUi.theme(Theme.of(context), context.l10n.isArabic),
    child: Builder(builder: _buildHome),
  );

  Widget _buildHome(BuildContext context) {
    final ar = context.l10n.isArabic;
    String tr(String en, String arabic) => ar ? arabic : en;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _pureBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: FutureBuilder<AppUser?>(
                  future: _profile,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final loading =
                        snapshot.connectionState != ConnectionState.done;
                    final failed =
                        !loading && (snapshot.hasError || user == null);

                    return AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      reverseDuration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 120),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, .012),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: SingleChildScrollView(
                        key: ValueKey('dashboard-scroll-$_tab'),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          SanadBottomNavigation.height +
                              SanadBottomNavigation.bottomSpacing +
                              SanadBottomNavigation.contentClearance +
                              bottomInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_tab != 4)
                              HealthDashboard(
                                tab: _tab,
                                userName: user?.name,
                                onOpenProfile: () => setState(() => _tab = 4),
                                onOpenTab: (tab) => setState(() => _tab = tab),
                              )
                            else if (loading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 80),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF6750A4),
                                  ),
                                ),
                              )
                            else if (failed) ...[
                              Text(
                                tr(
                                  'Could not load your profile',
                                  'تعذر تحميل بيانات حسابك',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF171719),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: OutlinedButton.icon(
                                  onPressed: () => setState(
                                    () => _profile = _auth
                                        .getCurrentUserProfile(),
                                  ),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 19,
                                    color: Color(0xFF171719),
                                  ),
                                  label: Text(
                                    tr('Try again', 'إعادة المحاولة'),
                                    style: const TextStyle(
                                      color: Color(0xFF171719),
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (user != null) ...[
                              // Account & Profile Header
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => setState(() => _tab = 0),
                                    tooltip: tr('Home', 'الرئيسية'),
                                    icon: Icon(
                                      ar
                                          ? Icons.chevron_right_rounded
                                          : Icons.chevron_left_rounded,
                                      color: Color(0xFF171719),
                                      size: 28,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      tr('My profile', 'حسابي'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF171719),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _signingOut ? null : _signOut,
                                    tooltip: tr('Sign out', 'تسجيل الخروج'),
                                    icon: const Icon(
                                      Icons.logout_rounded,
                                      color: Color(0xFFFF453A),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: _darkCard,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE9E5FF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.person_rounded,
                                            color: Color(0xFF6750A4),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF171719),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                user.role == UserRole.patient
                                                    ? context.l10n.patient
                                                    : context.l10n.caregiver,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6750A4),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (user.username?.isNotEmpty == true) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        '@${user.username}',
                                        textDirection: TextDirection.ltr,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: _muted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final cards = [
                                    _DetailCard(
                                      label: tr('Email', 'البريد الإلكتروني'),
                                      value: user.email,
                                      icon: Icons.email_rounded,
                                      ltr: true,
                                    ),
                                    _DetailCard(
                                      label: tr('WhatsApp', 'واتساب'),
                                      value: user.phoneNumber,
                                      icon: Icons.chat_rounded,
                                      ltr: true,
                                    ),
                                    _DetailCard(
                                      label: tr('Country', 'الدولة'),
                                      value: user.country,
                                      icon: Icons.public_rounded,
                                    ),
                                    _DetailCard(
                                      label: tr('Region', 'المنطقة'),
                                      value: user.region,
                                      icon: Icons.location_on_rounded,
                                    ),
                                  ];
                                  final columns = constraints.maxWidth < 330
                                      ? 1
                                      : 2;
                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: cards
                                        .map(
                                          (card) => SizedBox(
                                            width:
                                                (constraints.maxWidth -
                                                    12 * (columns - 1)) /
                                                columns,
                                            child: card,
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: _darkCard,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('Address', 'العنوان المسجل'),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF171719),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      user.address?.trim().isNotEmpty == true
                                          ? user.address!
                                          : '—',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomInset + SanadBottomNavigation.bottomSpacing,
            child: SanadBottomNavigation(
              selectedIndex: _tab,
              isArabic: ar,
              onSelected: (index) => setState(() => _tab = index),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.label,
    required this.value,
    required this.icon,
    this.ltr = false,
  });
  final String label;
  final String? value;
  final IconData icon;
  final bool ltr;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _darkCard,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF8E8E93)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value?.trim().isNotEmpty == true ? value! : '—',
          textDirection: ltr ? TextDirection.ltr : null,
          style: const TextStyle(
            color: Color(0xFF171719),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
