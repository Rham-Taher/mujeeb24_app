import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/features/auth/providers/auth_provider.dart';

class BusinessSelectionScreen extends StatelessWidget {
  final AuthProvider authProvider;
  final VoidCallback onBusinessSelected;
  final VoidCallback onLogout;

  const BusinessSelectionScreen({
    super.key,
    required this.authProvider,
    required this.onBusinessSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);
    final businesses = authProvider.accessibleBusinesses;
    final user = authProvider.currentPrincipal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings('select_business')),
        actions: [
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
              // User Greeting Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderHairline),
                  boxShadow: AppShadows.subtle,
                ),
                child: Row(
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
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user?.displayName.isNotEmpty == true
                              ? user!.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.onSurface,
                            ),
                          ),
                          if (user?.email != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              user!.email!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                strings('select_business_subtitle'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Empty or List
              if (businesses.isEmpty) ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.business_outlined,
                            size: 48,
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          strings('no_businesses'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          strings('no_businesses_desc'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton.icon(
                          onPressed: () => authProvider.reloadBusinesses(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(strings('retry')),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderHairline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ListView.separated(
                    itemCount: businesses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = businesses[index];
                      final isSelected =
                          authProvider.selectedBusiness?.business.id ==
                          item.business.id;

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderHairline,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : AppShadows.subtle,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          onTap: () {
                            authProvider.selectBusiness(item);
                            onBusinessSelected();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Icon(
                                    Icons.store_mall_directory_rounded,
                                    color: isSelected ? AppColors.primary : AppColors.outline,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.business.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceContainerLow,
                                              borderRadius:
                                                  BorderRadius.circular(AppRadius.full),
                                              border: Border.all(
                                                color: AppColors.borderHairline,
                                              ),
                                            ),
                                            child: Text(
                                              item.role ?? 'عضو',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          if (item.business.defaultCurrency !=
                                              null) ...[
                                            const SizedBox(width: AppSpacing.xs),
                                            Text(
                                              item.business.defaultCurrency!,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: isSelected ? AppColors.primary : AppColors.outline,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
