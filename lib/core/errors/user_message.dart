/// Turns any thrown error into a sentence a person can act on.
String userMessage(Object? error, {String? fallback}) {
  const generic = 'حدث خطأ. حاول مرة أخرى.';
  final text = _unwrap(error?.toString() ?? '');
  if (text.isEmpty) return fallback ?? generic;
  final known = _known(text.toLowerCase());
  if (known != null) return known;
  final arabic = _arabic(text);
  if (arabic != null) return arabic;
  return fallback ?? generic;
}

String _unwrap(String raw) {
  var text = raw.trim();
  final prefix = RegExp(r'^(Exception|Error):\s*', caseSensitive: false);
  while (prefix.hasMatch(text)) {
    text = text.replaceFirst(prefix, '').trim();
  }
  return text;
}

String? _arabic(String text) {
  final matches = RegExp(
    r'[\u0600-\u06FF][\u0600-\u06FF\s\d\.،,؟!?!:؛\-«»]+',
  ).allMatches(text);
  String? best;
  for (final match in matches) {
    final sentence = match.group(0)!.trim();
    if (sentence.length < 6) continue;
    if (best == null || sentence.length > best.length) best = sentence;
  }
  return best;
}

String? _known(String lower) {
  if (lower.contains('invalid login') ||
      lower.contains('invalid_credentials') ||
      lower.contains('invalid credentials')) {
    return 'البريد أو كلمة المرور غير صحيحة.';
  }
  if (lower.contains('user not found')) {
    return 'ما لقينا هذا الحساب.';
  }
  if (lower.contains('email not confirmed') ||
      lower.contains('email_not_confirmed') ||
      lower.contains('not confirmed')) {
    return 'أكّد بريدك من الرسالة التي وصلتك، ثم حاول مرة أخرى.';
  }
  if (lower.contains('invalid email') ||
      lower.contains('unable to validate email') ||
      lower.contains('email_address_invalid')) {
    return 'البريد غير صحيح.';
  }
  if (lower.contains('already registered') ||
      lower.contains('user already') ||
      lower.contains('already been registered') ||
      lower.contains('23505') ||
      lower.contains('duplicate key') ||
      lower.contains('unique constraint')) {
    return 'هذا البريد أو هذه البيانات مسجّلة من قبل.';
  }
  if (lower.contains('weak password') ||
      lower.contains('weak_password') ||
      lower.contains('password should be at least') ||
      lower.contains('at least 6')) {
    return 'كلمة المرور قصيرة. استخدم ستة أحرف على الأقل.';
  }
  if (lower.contains('rate limit') ||
      lower.contains('too many') ||
      lower.contains('once every') ||
      lower.contains('over_request') ||
      lower.contains('over_email_send_rate')) {
    return 'انتظر قليلاً ثم حاول مرة أخرى.';
  }
  if (lower.contains('jwt') ||
      lower.contains('not authenticated') ||
      lower.contains('session expired') ||
      lower.contains('session missing') ||
      lower.contains('refresh token') ||
      lower.contains('pgrst301') ||
      RegExp(r'\b401\b').hasMatch(lower)) {
    return 'انتهت الجلسة. سجّل الدخول من جديد.';
  }
  if (lower.contains('otp') ||
      lower.contains('expired') ||
      (lower.contains('token') && lower.contains('invalid'))) {
    return 'الرمز غير صحيح أو انتهت صلاحيته.';
  }
  if (lower.contains('signup') && lower.contains('disabled')) {
    return 'التسجيل مغلق حالياً.';
  }
  if (lower.contains('socket') ||
      lower.contains('failed host lookup') ||
      lower.contains('network') ||
      lower.contains('connection') ||
      lower.contains('timed out') ||
      lower.contains('timeout') ||
      lower.contains('handshake') ||
      lower.contains('clientexception') ||
      lower.contains('offline')) {
    return 'لا يوجد اتصال بالإنترنت. حاول مرة أخرى.';
  }
  if (lower.contains('row-level security') ||
      lower.contains('row level security') ||
      lower.contains('42501') ||
      lower.contains('permission denied') ||
      lower.contains('not authorized') ||
      lower.contains('unauthorized') ||
      RegExp(r'\b403\b').hasMatch(lower)) {
    return 'ما عندك صلاحية لهذا الإجراء.';
  }
  if (lower.contains('23503') || lower.contains('foreign key')) {
    return 'البيانات المرتبطة ناقصة. حاول مرة أخرى.';
  }
  if (lower.contains('pgrst116') || lower.contains('0 rows')) {
    return 'ما لقينا المطلوب.';
  }
  if (lower.contains('payload too large') ||
      lower.contains('entity too large') ||
      RegExp(r'\b413\b').hasMatch(lower)) {
    return 'الملف كبير جداً.';
  }
  if (lower.contains('bucket not found') || lower.contains('storage')) {
    return 'تعذر رفع الملف. حاول مرة أخرى.';
  }
  return null;
}
