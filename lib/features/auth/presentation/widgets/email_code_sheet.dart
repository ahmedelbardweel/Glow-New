import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../data/email_login_code.dart';

/// Asks for the 8-digit code. False means the person closed the sheet.
Future<bool> confirmOwnEmail(BuildContext context, String email) async {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return true;
  final ok = await showEmailCodeSheet(context, email: trimmed);
  if (ok) return true;
  await sl<EmailLoginCode>().cancelLogin();
  return false;
}

/// Proves a newly created mailbox, then returns to the account that created it.
Future<void> confirmCreatedEmail(BuildContext context, String email) async {
  final codes = sl<EmailLoginCode>();
  await codes.holdKeeper();
  try {
    final ok = await showEmailCodeSheet(context, email: email.trim());
    if (!ok) {
      throw Exception('أدخل رمز البريد لإكمال إنشاء الحساب');
    }
  } finally {
    await codes.restoreKeeper();
  }
}

Future<bool> showEmailCodeSheet(BuildContext context, {required String email}) {
  return showAppSheet<bool>(
    context: context,
    heightFactor: 0.46,
    avoidKeyboard: true,
    builder: (sheetContext) => _EmailCodeForm(
      email: email,
      onDone: (ok) => Navigator.of(sheetContext).pop(ok),
    ),
  ).then((value) => value ?? false);
}

class _EmailCodeForm extends StatefulWidget {
  const _EmailCodeForm({required this.email, required this.onDone});

  final String email;
  final ValueChanged<bool> onDone;

  @override
  State<_EmailCodeForm> createState() => _EmailCodeFormState();
}

class _EmailCodeFormState extends State<_EmailCodeForm> {
  static const _length = 8;

  final _code = TextEditingController();
  var _busy = false;
  var _sending = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _send();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    _code.clear();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await sl<EmailLoginCode>().send(widget.email);
      if (!mounted) return;
      setState(() => _sending = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = userMessage(error, fallback: 'تعذر إرسال الرمز. حاول مرة أخرى.');
      });
    }
  }

  Future<void> _verify() async {
    if (_busy || _sending) return;
    final code = _code.text.trim();
    if (code.length != _length) {
      setState(() => _error = 'اكتب الرمز المكوّن من 8 أرقام');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await sl<EmailLoginCode>().verify(widget.email, code);
      if (!mounted) return;
      widget.onDone(true);
    } catch (error) {
      if (!mounted) return;
      _code.clear();
      setState(() {
        _busy = false;
        _error = userMessage(error, fallback: 'الرمز غير صحيح. حاول مرة أخرى.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 48, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'رمز التحقق',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أرسلنا رمزاً من 8 أرقام إلى\n${widget.email}',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            _CodeBoxes(
              controller: _code,
              length: _length,
              enabled: !_busy && !_sending,
              hasError: _error != null,
              onCompleted: _verify,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.burgundy),
              ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: _busy || _sending ? null : _verify,
              child: Text(_busy ? 'جارٍ التحقق' : 'تأكيد'),
            ),
            TextButton(
              onPressed: _busy || _sending ? null : _send,
              child: Text(_sending ? 'جارٍ الإرسال' : 'إعادة إرسال الرمز'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeBoxes extends StatefulWidget {
  const _CodeBoxes({
    required this.controller,
    required this.length,
    required this.enabled,
    required this.hasError,
    required this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool enabled;
  final bool hasError;
  final VoidCallback onCompleted;

  @override
  State<_CodeBoxes> createState() => _CodeBoxesState();
}

class _CodeBoxesState extends State<_CodeBoxes> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCode);
  }

  @override
  void didUpdateWidget(covariant _CodeBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onCode);
      widget.controller.addListener(_onCode);
    }
    if (!oldWidget.enabled && widget.enabled) {
      _focus.requestFocus();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCode);
    _focus.dispose();
    super.dispose();
  }

  void _onCode() {
    if (mounted) setState(() {});
    if (widget.enabled && widget.controller.text.length == widget.length) {
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final active = code.length.clamp(0, widget.length - 1);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 52,
        child: Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _DigitBox(
                      digit: i < code.length ? code[i] : '',
                      active: widget.enabled && i == active && i == code.length,
                      hasError: widget.hasError,
                    ),
                  ),
                ],
              ],
            ),
            Positioned.fill(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofocus: widget.enabled,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: widget.length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                cursorColor: Colors.transparent,
                showCursor: false,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => widget.onCompleted(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.digit,
    required this.active,
    required this.hasError,
  });

  final String digit;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.burgundy
        : active
            ? AppColors.primary
            : AppColors.inputBorder;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: active || hasError ? 2 : 1),
      ),
      child: Center(
        child: Text(
          digit,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}
