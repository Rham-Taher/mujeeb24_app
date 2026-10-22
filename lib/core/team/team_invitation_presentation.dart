import 'package:flutter/material.dart';
import '../errors/api_error.dart';

/// Merchant-safe text for backend invitation errors. Never present SQL,
/// internal persistence strings or raw English application messages.
String invitationErrorMessage(ApiErrorEnvelope failure, {required bool resend}) {
  final source = failure.error.message.toLowerCase();
  final base = resend ? 'تجديد الدعوة' : 'قبول الدعوة';
  if (source.contains('active subscription')) {
    return 'لا يمكن قبول الدعوة دون اشتراك نشط للنشاط التجاري. راجع الاشتراك.';
  }
  if (source.contains('available employee seat') ||
      source.contains('active seat limit')) {
    return 'اكتمل عدد مقاعد الموظفين في باقتك. أضف مقعدًا أو غيّر الباقة ثم أعد المحاولة.';
  }
  if (source.contains('account already exists') ||
      source.contains('principal already exists')) {
    return 'هذا البريد لديه حساب بالفعل. سجّل الدخول بالحساب الموجود لقبول الدعوة، بدل إنشاء حساب جديد.';
  }
  if (source.contains('no longer pending') ||
      source.contains('invitation is not pending')) {
    return 'الدعوة لم تعد معلّقة أو انتهت صلاحيتها. اطلب رابط دعوة جديدًا.';
  }
  if (source.contains('business is not active')) {
    return 'هذا النشاط غير نشط حاليًا. تواصل مع مالك النشاط.';
  }
  if (source.contains('accepted invitation cannot be resent')) {
    return 'تم قبول هذه الدعوة سابقًا ولا يمكن تجديدها. راجع قائمة أعضاء الفريق.';
  }
  if (failure.statusCode == 404 || failure.error.code == 'not_found') {
    return 'لم نعثر على الدعوة. تحقق من الرابط أو اطلب دعوة جديدة.';
  }
  if (failure.statusCode == 401) {
    return 'انتهت جلسة الدخول. سجّل الدخول مرة أخرى.';
  }
  if (failure.statusCode == 403) {
    return 'ليس لديك صلاحية لإجراء هذه العملية.';
  }
  if (failure.error.code == 'invalid_state_transition' ||
      failure.statusCode == 409) {
    return 'تعذر $base لأن حالة الدعوة أو شروط النشاط لا تسمح بذلك. تأكد من صلاحية الدعوة والاشتراك وعدد مقاعد الموظفين.';
  }
  if (failure.error.code == 'validation_error') {
    return 'تعذر $base بسبب بيانات غير مقبولة. راجع البيانات ثم حاول مجددًا.';
  }
  if (failure.error.code == 'external_dependency_unavailable') {
    return 'تعذر حفظ الدعوة على الخادم حاليًا. لا تكرر العملية دون مراجعة حالتها؛ تواصل مع الدعم برقم الطلب.';
  }
  return 'تعذر $base حاليًا. تحقق من الاتصال، ثم أعد المحاولة أو تواصل مع الدعم.';
}

String teamRoleArabicLabel(String role) => switch (role) {
  'owner' => 'مالك النشاط',
  'admin' => 'مسؤول',
  'manager' => 'مدير عمليات',
  'agent' => 'موظف مبيعات ودعم',
  'analyst' => 'محلل بيانات',
  'viewer' => 'مشاهد',
  _ => 'عضو فريق',
};

String teamAccountArabicLabel(String account) => switch (account) {
  'new' => 'حساب جديد',
  'existing' => 'حساب موجود',
  _ => 'غير محدد',
};

String teamInvitationArabicStatus(String status) => switch (status) {
  'pending' => 'بانتظار قبول الدعوة',
  'accepted' => 'تم قبول الدعوة',
  'revoked' => 'ألغيت الدعوة',
  'expired' => 'انتهت صلاحية الدعوة',
  _ => 'حالة غير معروفة',
};

String formatTeamInvitationDate(BuildContext context, String isoDate) {
  final date = DateTime.tryParse(isoDate)?.toLocal();
  if (date == null) return 'غير متاح';
  final localizations = MaterialLocalizations.of(context);
  final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date));
  return '${localizations.formatMediumDate(date)}، $time';
}
