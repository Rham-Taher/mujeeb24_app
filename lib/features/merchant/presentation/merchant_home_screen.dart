import 'package:flutter/material.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/merchant_models.dart';
import 'package:mujeeb24_app/features/auth/providers/auth_provider.dart';
import 'package:mujeeb24_app/features/catalog/presentation/catalogs_screen.dart';
import 'package:mujeeb24_app/features/catalog/providers/catalog_provider.dart';
import 'package:mujeeb24_app/features/channels/presentation/channels_screen.dart';
import 'package:mujeeb24_app/features/channels/providers/channel_automation_provider.dart';
import 'package:mujeeb24_app/features/crm/presentation/customers_tab.dart';
import 'package:mujeeb24_app/features/crm/presentation/leads_tab.dart';
import 'package:mujeeb24_app/features/crm/providers/crm_provider.dart';
import 'package:mujeeb24_app/features/merchant/presentation/business_settings_tab.dart';
import 'package:mujeeb24_app/features/merchant/presentation/conversation_detail_screen.dart';
import 'package:mujeeb24_app/features/merchant/presentation/dashboard_tab.dart';
import 'package:mujeeb24_app/features/merchant/presentation/inbox_tab.dart';
import 'package:mujeeb24_app/features/merchant/providers/merchant_provider.dart';
import 'package:mujeeb24_app/features/platform/presentation/platform_hub_screen.dart';
import 'package:mujeeb24_app/features/platform/providers/platform_provider.dart';
import 'package:mujeeb24_app/features/team/presentation/audit_logs_screen.dart';
import 'package:mujeeb24_app/features/team/presentation/team_screen.dart';
import 'package:mujeeb24_app/features/team/providers/team_audit_provider.dart';
import 'package:mujeeb24_app/features/transactions/presentation/transactions_screen.dart';
import 'package:mujeeb24_app/features/transactions/providers/transaction_provider.dart';

class MerchantHomeScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final MerchantProvider merchantProvider;
  final CrmProvider? crmProvider;
  final TransactionProvider? transactionProvider;
  final CatalogProvider? catalogProvider;
  final ChannelAutomationProvider? channelAutomationProvider;
  final TeamAuditProvider? teamAuditProvider;
  final PlatformProvider? platformProvider;
  final AppLocaleProvider localeProvider;
  final VoidCallback onSwitchBusiness;
  final VoidCallback onLogout;

  const MerchantHomeScreen({
    super.key,
    required this.authProvider,
    required this.merchantProvider,
    this.crmProvider,
    this.transactionProvider,
    this.catalogProvider,
    this.channelAutomationProvider,
    this.teamAuditProvider,
    this.platformProvider,
    required this.localeProvider,
    required this.onSwitchBusiness,
    required this.onLogout,
  });

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.merchantProvider.addListener(_onStateChange);
    widget.crmProvider?.addListener(_onStateChange);
    widget.transactionProvider?.addListener(_onStateChange);
    widget.catalogProvider?.addListener(_onStateChange);
    widget.channelAutomationProvider?.addListener(_onStateChange);
    widget.teamAuditProvider?.addListener(_onStateChange);
    widget.platformProvider?.addListener(_onStateChange);
  }

  @override
  void dispose() {
    widget.merchantProvider.removeListener(_onStateChange);
    widget.crmProvider?.removeListener(_onStateChange);
    widget.transactionProvider?.removeListener(_onStateChange);
    widget.catalogProvider?.removeListener(_onStateChange);
    widget.channelAutomationProvider?.removeListener(_onStateChange);
    widget.teamAuditProvider?.removeListener(_onStateChange);
    widget.platformProvider?.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _openConversation(Conversation conversation) {
    final business = widget.authProvider.selectedBusiness?.business;
    if (business == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConversationDetailScreen(
          merchantProvider: widget.merchantProvider,
          businessId: business.id,
          conversationId: conversation.id,
        ),
      ),
    );
  }

  void _openTransactions([String? filter]) {
    final business = widget.authProvider.selectedBusiness?.business;
    if (business == null || widget.transactionProvider == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionsScreen(
          transactionProvider: widget.transactionProvider!,
          businessId: business.id,
          initialStateFilter: filter,
        ),
      ),
    );
  }

  void _openCatalogs() {
    final business = widget.authProvider.selectedBusiness?.business;
    if (business == null || widget.catalogProvider == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CatalogsScreen(
          catalogProvider: widget.catalogProvider!,
          businessId: business.id,
          businessCurrency: business.defaultCurrency,
        ),
      ),
    );
  }

  void _openChannels() {
    final business = widget.authProvider.selectedBusiness?.business;
    if (business == null || widget.channelAutomationProvider == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChannelsScreen(
          channelProvider: widget.channelAutomationProvider!,
          businessId: business.id,
        ),
      ),
    );
  }

  void _openTeam() {
    final business = widget.authProvider.selectedBusiness?.business;
    if (business == null || widget.teamAuditProvider == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeamScreen(
          provider: widget.teamAuditProvider!,
          businessId: business.id,
        ),
      ),
    );
  }

  void _openAuditLogs() {
    final business = widget.authProvider.selectedBusiness?.business;
    if (business == null || widget.teamAuditProvider == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuditLogsScreen(
          provider: widget.teamAuditProvider!,
          businessId: business.id,
        ),
      ),
    );
  }

  void _openPlatform() {
    if (widget.platformProvider == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlatformHubScreen(
          provider: widget.platformProvider!,
          authProvider: widget.authProvider,
          onBackToWorkspace: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);
    final business = widget.authProvider.selectedBusiness?.business;
    final hasCrm = widget.crmProvider != null;

    final tabs = <Widget>[
      DashboardTab(
        merchantProvider: widget.merchantProvider,
        currentBusiness: business,
        onNavigateToInbox: () => setState(() => _currentIndex = 1),
        onNavigateToCustomers: hasCrm
            ? () => setState(() => _currentIndex = 2)
            : null,
        onNavigateToLeads: hasCrm
            ? () => setState(() => _currentIndex = 3)
            : null,
        onNavigateToTransactions: widget.transactionProvider != null
            ? () => _openTransactions(null)
            : null,
        onNavigateToReviews: widget.transactionProvider != null
            ? () => _openTransactions('review')
            : null,
        onNavigateToCatalogs: widget.catalogProvider != null
            ? _openCatalogs
            : null,
        onNavigateToChannels: widget.channelAutomationProvider != null
            ? _openChannels
            : null,
        onNavigateToTeam: widget.teamAuditProvider != null ? _openTeam : null,
        onNavigateToAuditLogs:
            widget.teamAuditProvider != null ? _openAuditLogs : null,
        onSessionExpired: widget.onLogout,
      ),
      InboxTab(
        merchantProvider: widget.merchantProvider,
        currentBusiness: business,
        onConversationSelected: _openConversation,
      ),
      if (hasCrm) ...[
        CustomersTab(
          crmProvider: widget.crmProvider!,
          businessId: business?.id ?? '',
        ),
        LeadsTab(
          crmProvider: widget.crmProvider!,
          businessId: business?.id ?? '',
        ),
      ],
      BusinessSettingsTab(
        merchantProvider: widget.merchantProvider,
        currentBusiness: business,
        onSwitchBusiness: widget.onSwitchBusiness,
        onLogout: widget.onLogout,
        onToggleLanguage: () => widget.localeProvider.toggleLocale(),
        onNavigateToTeam: widget.teamAuditProvider != null ? _openTeam : null,
        onNavigateToAuditLogs:
            widget.teamAuditProvider != null ? _openAuditLogs : null,
        onNavigateToPlatform:
            (widget.authProvider.isPlatformAdmin && widget.platformProvider != null)
                ? _openPlatform
                : null,
      ),
    ];

    final navItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.dashboard_rounded),
        label: strings('nav_home'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.forum_rounded),
        label: strings('nav_inbox'),
      ),
      if (hasCrm) ...[
        BottomNavigationBarItem(
          icon: const Icon(Icons.people_alt_rounded),
          label: strings('nav_customers'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.trending_up_rounded),
          label: strings('nav_leads'),
        ),
      ],
      BottomNavigationBarItem(
        icon: const Icon(Icons.settings_rounded),
        label: strings('nav_settings'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          business?.name ?? strings('app_name'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          if (widget.catalogProvider != null)
            IconButton(
              tooltip: strings('catalogs_title'),
              onPressed: _openCatalogs,
              icon: const Icon(Icons.inventory_2_outlined),
            ),
          PopupMenuButton<String>(
            key: const Key('merchant_more_actions'),
            tooltip: 'المزيد من أدوات النشاط',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'business':
                  widget.onSwitchBusiness();
                case 'transactions':
                  _openTransactions(null);
                case 'catalogs':
                  _openCatalogs();
                case 'channels':
                  _openChannels();
                case 'team':
                  _openTeam();
                case 'platform':
                  _openPlatform();
                case 'language':
                  widget.localeProvider.toggleLocale();
                case 'logout':
                  widget.onLogout();
              }
            },
            itemBuilder: (context) => [
              if (widget.authProvider.accessibleBusinesses.length > 1)
                PopupMenuItem(value: 'business',
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.swap_horiz_rounded),
                    title: Text(strings('select_business')))),
              if (widget.transactionProvider != null)
                PopupMenuItem(value: 'transactions',
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(strings('transactions_title')))),
              if (widget.catalogProvider != null)
                PopupMenuItem(value: 'catalogs',
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(strings('catalogs_title')))),
              if (widget.channelAutomationProvider != null)
                PopupMenuItem(value: 'channels',
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.hub_outlined),
                    title: Text(strings('channels_title')))),
              if (widget.teamAuditProvider != null)
                PopupMenuItem(
                  value: 'team',
                  key: const Key('btn_appbar_team'),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.groups_outlined),
                    title: Text(strings('team_and_audit')))),
              if (widget.authProvider.isPlatformAdmin &&
                  widget.platformProvider != null)
                PopupMenuItem(
                  value: 'platform',
                  key: const Key('btn_appbar_platform'),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: Text(strings('platform_title')))),
              PopupMenuItem(value: 'language',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.language_rounded),
                  title: Text(strings('switch_language')))),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'logout',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.logout_rounded),
                  title: Text(strings('logout')))),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex.clamp(0, tabs.length - 1),
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex.clamp(0, navItems.length - 1),
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.surfaceCanvas,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
