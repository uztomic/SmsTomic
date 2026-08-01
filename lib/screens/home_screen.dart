import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/customer/customer_cubit.dart';
import '../blocs/history/history_cubit.dart';
import '../blocs/send_sms/send_sms_bloc.dart';
import '../blocs/template/template_cubit.dart';
import '../blocs/user_management/user_cubit.dart';
import '../core/sms_service.dart';
import '../core/theme.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/log_repository.dart';
import '../repositories/template_repository.dart';
import 'customers/customers_screen.dart';
import 'history/history_screen.dart';
import 'send_sms/send_sms_screen.dart';
import 'templates/templates_screen.dart';
import 'users/users_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppUser currentUser;

  const HomeScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CustomerCubit(CustomerRepository())),
        BlocProvider(create: (_) => TemplateCubit(TemplateRepository())),
        BlocProvider(create: (_) => HistoryCubit(LogRepository())),
        BlocProvider(
          create: (_) => SendSmsBloc(
            customerRepository: CustomerRepository(),
            templateRepository: TemplateRepository(),
            logRepository: LogRepository(),
            smsService: SmsService(),
          )..add(const SendSmsStarted()),
        ),
        if (currentUser.isAdmin) BlocProvider(create: (_) => UserCubit(AuthRepository())),
      ],
      child: _HomeTabs(currentUser: currentUser),
    );
  }
}

class _Tab {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;

  const _Tab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.screen,
  });
}

class _HomeTabs extends StatefulWidget {
  final AppUser currentUser;

  const _HomeTabs({required this.currentUser});

  @override
  State<_HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<_HomeTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    final tabs = <_Tab>[
      if (!kIsWeb && user.can(Permission.sendSms))
        const _Tab(
          icon: Icons.sms_outlined,
          selectedIcon: Icons.sms_rounded,
          label: 'SMS',
          screen: SendSmsScreen(),
        ),
      if (user.can(Permission.manageCustomers))
        const _Tab(
          icon: Icons.people_alt_outlined,
          selectedIcon: Icons.people_alt_rounded,
          label: 'Mijozlar',
          screen: CustomersScreen(),
        ),
      if (user.can(Permission.manageTemplates))
        const _Tab(
          icon: Icons.description_outlined,
          selectedIcon: Icons.description_rounded,
          label: 'Shablon',
          screen: TemplatesScreen(),
        ),
      if (user.can(Permission.viewHistory))
        const _Tab(
          icon: Icons.history_rounded,
          selectedIcon: Icons.history_rounded,
          label: 'Tarix',
          screen: HistoryScreen(),
        ),
      if (user.isAdmin)
        const _Tab(
          icon: Icons.manage_accounts_outlined,
          selectedIcon: Icons.manage_accounts_rounded,
          label: 'Xodimlar',
          screen: UsersScreen(),
        ),
    ];

    final safeIndex = tabs.isEmpty ? 0 : _index.clamp(0, tabs.length - 1);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.roseLight,
              child: Text(
                (user.name.isNotEmpty ? user.name[0] : user.email[0]).toUpperCase(),
                style: const TextStyle(color: AppColors.roseDark, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isEmpty ? user.email : user.name,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 15),
                  ),
                  Text(
                    user.isAdmin ? 'Administrator' : 'Xodim',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.rose,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Chiqish',
            onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: tabs.isEmpty
          ? const _NoPermissionsView()
          : IndexedStack(index: safeIndex, children: [for (final t in tabs) t.screen]),
      bottomNavigationBar: tabs.length < 2
          ? null
          : NavigationBar(
              selectedIndex: safeIndex,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final t in tabs)
                  NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon),
                    label: t.label,
                  ),
              ],
            ),
    );
  }
}

class _NoPermissionsView extends StatelessWidget {
  const _NoPermissionsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Hisobingizga hali hech qanday ruxsat berilmagan.\nAdministratoringiz bilan bog\'laning.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
