import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/features/auth/providers/auth_provider.dart';

class WorkspaceScreen extends StatelessWidget {
  final AuthProvider authProvider;
  final VoidCallback onSwitchBusiness;
  final VoidCallback onLogout;

  const WorkspaceScreen({
    super.key,
    required this.authProvider,
    required this.onSwitchBusiness,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);
    final business = authProvider.selectedBusiness?.business;
    final role = authProvider.selectedBusiness?.role;
    final permissions = authProvider.selectedBusiness?.permissions ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(business?.name ?? strings('app_name')),
        actions: [
          if (authProvider.accessibleBusinesses.length > 1)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: strings('select_business'),
              onPressed: onSwitchBusiness,
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: strings('logout'),
            onPressed: () async {
              await authProvider.logout();
              onLogout();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Business Identity Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderHairline),
                  boxShadow: AppShadows.subtle,
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
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                business?.name ?? '',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'المعرف: ${business?.slug ?? business?.id ?? ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Divider(height: 1, color: AppColors.borderHairline),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            'الدور في النشاط: ${role ?? 'عضو'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Text(
                          'العملة: ${business?.defaultCurrency ?? 'SAR'}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              const Text(
                'صلاحيات العضوية المعتمدة من الخادم:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onSurface),
              ),
              const SizedBox(height: AppSpacing.sm),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderHairline),
                    boxShadow: AppShadows.subtle,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    itemCount: permissions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderHairline),
                    itemBuilder: (context, index) {
                      final perm = permissions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: AppColors.statusSuccess,
                        ),
                        title: Text(
                          perm,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                            color: AppColors.onSurface,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
