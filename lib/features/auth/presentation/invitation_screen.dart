import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mujeeb24_app/core/team/team_invitation_presentation.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/models/auth_models.dart';
import 'package:mujeeb24_app/features/auth/providers/auth_provider.dart';

class InvitationScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final VoidCallback onBackToLogin;

  final String? initialToken;

  const InvitationScreen({
    super.key,
    required this.authProvider,
    required this.onBackToLogin,
    this.initialToken,
  });

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  final _tokenController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();

  TeamInvitation? _inspectedInvitation;
  bool _isInspecting = false;
  bool _isAccepting = false;
  bool _obscurePassword = true;
  String? _localError;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
      _tokenController.text = widget.initialToken!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inspectToken();
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _inspectToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _localError = 'يرجى إدخال رمز الدعوة');
      return;
    }

    setState(() {
      _isInspecting = true;
      _localError = null;
      _successMessage = null;
    });

    final inv = await widget.authProvider.inspectInvitation(token);
    if (!mounted) return;
    if (_tokenController.text.trim() != token) {
      setState(() => _isInspecting = false);
      return;
    }
    setState(() {
      _isInspecting = false;
      _inspectedInvitation = inv;
      if (inv != null && inv.displayName.isNotEmpty) {
        _displayNameController.text = inv.displayName;
      }
    });
  }

  Future<void> _acceptInvitation() async {
    final invitation = _inspectedInvitation;
    if (invitation == null || _isAccepting) return;
    final token = _tokenController.text.trim();
    if (!invitation.canBeAccepted) {
      setState(() => _localError =
        'هذه الدعوة ليست صالحة للقبول الآن. اطلب من صاحب النشاط تجديدها.');
      return;
    }

    setState(() {
      _isAccepting = true;
      _localError = null;
      _successMessage = null;
    });

    bool ok = false;
    if (invitation.accountState == 'new') {
      final name = _displayNameController.text.trim();
      final pass = _passwordController.text;
      final passwordBytes = utf8.encode(pass).length;
      if (name.isEmpty || passwordBytes < 12 || passwordBytes > 72) {
        setState(() {
          _isAccepting = false;
          _localError =
              'أدخل الاسم وكلمة مرور تتراوح بين 12 و72 بايتًا.';
        });
        return;
      }
      ok = await widget.authProvider.acceptNewAccountInvitation(
        token: token,
        displayName: name,
        password: pass,
      );
    } else {
      // Existing account acceptance
      ok = await widget.authProvider.acceptTeamInvitation(token: token);
    }

    if (!mounted) return;
    if (!ok) {
      // On a stale invitation/seat race, re-inspect to reveal latest state.
      // Preserve the actionable failure even though inspect clears provider errors.
      final acceptanceError = widget.authProvider.errorMessage;
      final current = await widget.authProvider.inspectInvitation(token);
      if (!mounted) return;
      setState(() {
        _inspectedInvitation = current;
        _localError = acceptanceError ??
            'تعذر قبول الدعوة حاليًا. تواصل مع صاحب النشاط.';
        _isAccepting = false;
      });
      return;
    }
    _passwordController.clear();
    setState(() {
      _isAccepting = false;
      _inspectedInvitation = null;
      _successMessage = 'تم قبول الدعوة بنجاح! يمكنك الآن تسجيل الدخول.';
    });
  }

  @override
  Widget build(BuildContext context) {
    String strings(String key) => AppStrings.get(key, context);
    final auth = widget.authProvider;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings('invitation_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBackToLogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings('invitation_subtitle'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),

              // Token Field
              TextFormField(
                controller: _tokenController,
                enabled: !_isInspecting && !_isAccepting,
                onChanged: (_) => setState(() {
                  _inspectedInvitation = null;
                  _localError = null;
                  _successMessage = null;
                }),
                decoration: InputDecoration(
                  labelText: strings('acceptance_token'),
                  hintText: 'inv_...',
                  prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _isInspecting || _isAccepting ? null : _inspectToken,
                child: _isInspecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(strings('inspect_token')),
              ),
              const SizedBox(height: 16),

              // Error banner
              if (_localError != null || auth.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusErrorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.statusError.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _localError ?? auth.errorMessage ?? '',
                    style: const TextStyle(
                      color: AppColors.statusError,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Success banner
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccessContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.statusSuccess.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(
                      color: AppColors.statusSuccess,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Inspected Invitation Details Card
              if (_inspectedInvitation != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings('invitation_details'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Divider(height: 20),
                        _buildRow(
                          strings('business'),
                          _inspectedInvitation!.businessName,
                        ),
                        _buildRow(
                          strings('invited_email'),
                          _inspectedInvitation!.email,
                        ),
                        _buildRow(strings('role'),
                          teamRoleArabicLabel(_inspectedInvitation!.role)),
                        _buildRow('حالة الدعوة',
                          teamInvitationArabicStatus(_inspectedInvitation!.status)),
                        _buildRow(
                          'حالة الحساب',
                          teamAccountArabicLabel(_inspectedInvitation!.accountState),
                        ),
                        _buildRow(
                          strings('expires_at'),
                          formatTeamInvitationDate(context,
                            _inspectedInvitation!.expiresAt),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Form for New Account or Button for Existing Account
                if (!_inspectedInvitation!.canBeAccepted) ...[
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('هذه الدعوة غير قابلة للقبول حاليًا. تواصل مع صاحب النشاط لطلب دعوة جديدة.'),
                    ),
                  ),
                ] else if (_inspectedInvitation!.accountState == 'new') ...[
                  TextFormField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: strings('display_name'),
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: strings('new_password'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      helperText: '12–72 بايتًا؛ استخدم كلمة مرور قوية',
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isAccepting ? null : _acceptInvitation,
                    child: _isAccepting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(strings('accept_and_create')),
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('لديك حساب بالفعل. سجّل الدخول بالحساب المرتبط بالبريد المدعو قبل قبول الدعوة.'),
                  ),
                  TextButton(
                    onPressed: widget.onBackToLogin,
                    child: const Text('الذهاب إلى تسجيل الدخول'),
                  ),
                  ElevatedButton(
                    onPressed: !_isAccepting && auth.isAuthenticated
                      ? _acceptInvitation : null,
                    child: _isAccepting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(strings('accept_existing')),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(value,
              textAlign: TextAlign.end,
              softWrap: true,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
