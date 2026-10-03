import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/admin_api_keys.dart';
import '../../../../core/config/eleven_credit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

Future<void> showAdminApiKeysSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    heightFactor: 0.9,
    builder: (sheetContext) => const _AdminApiKeysSheet(),
  );
}

class _AdminApiKeysSheet extends StatefulWidget {
  const _AdminApiKeysSheet();

  @override
  State<_AdminApiKeysSheet> createState() => _AdminApiKeysSheetState();
}

class _AdminApiKeysSheetState extends State<_AdminApiKeysSheet> {
  final _gemini = TextEditingController();
  final _eleven = TextEditingController();
  ElevenCredit? _credit;
  var _model = AdminApiKeys.defaultGeminiModel;
  var _saved = false;
  var _cloudFailed = false;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _model = AdminApiKeys.geminiModel;
    _load();
  }

  @override
  void dispose() {
    _gemini.dispose();
    _eleven.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await AdminApiKeys.sync();
    if (!mounted) return;
    setState(() => _model = AdminApiKeys.geminiModel);
    await _loadCredit();
  }

  Future<void> _loadCredit() async {
    final credit = await ElevenCredit.load();
    if (!mounted) return;
    setState(() {
      _credit = credit;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final gemini = _gemini.text.trim();
    final eleven = _eleven.text.trim();
    if (gemini.isNotEmpty) await AdminApiKeys.saveGemini(gemini);
    if (eleven.isNotEmpty) await AdminApiKeys.saveEleven(eleven);
    final savedOnAccount = await AdminApiKeys.push();
    if (!mounted) return;
    setState(() {
      _saved = savedOnAccount;
      _cloudFailed = !savedOnAccount;
      _loading = true;
    });
    _gemini.clear();
    _eleven.clear();
    await _loadCredit();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final credit = _credit;
    final geminiOut = AdminApiKeys.geminiExhausted;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(AppColors.border_radius),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'مفاتيح الصوت والمونتاج',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لما يخلص رصيد Gemini أو Eleven، الصق المفتاح الجديد هنا. اترك الخانة فارغة إذا ما بدك تغيّرها.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            _StatusLine(
              title: 'Eleven',
              value: _loading ? 'جاري قراءة الرصيد' : (credit?.label ?? 'تعذر قراءة الرصيد'),
              alert: credit?.exhausted == true || credit?.state == ElevenCreditState.invalid,
            ),
            if (geminiOut) ...[
              const SizedBox(height: 8),
              const _StatusLine(
                title: 'Gemini',
                value: 'خلص الرصيد',
                alert: true,
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _model,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'موديل Gemini',
              ),
              items: [
                for (final model in geminiModelChoices)
                  DropdownMenuItem(
                    value: model.id,
                    child: Text(model.label),
                  ),
              ],
              onChanged: (value) async {
                if (value == null) return;
                setState(() => _model = value);
                await AdminApiKeys.saveGeminiModel(value);
                final savedOnAccount = await AdminApiKeys.push();
                if (!mounted) return;
                setState(() => _cloudFailed = !savedOnAccount);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gemini,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'مفتاح Gemini',
                helperText: geminiOut
                    ? 'خلص رصيد Gemini'
                    : AdminApiKeys.hasGemini
                        ? 'محفوظ على الحساب'
                        : 'يستخدم المفتاح الأصلي',
                helperStyle: geminiOut ? const TextStyle(color: AppColors.error) : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _eleven,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'مفتاح Eleven',
                helperText: credit == null
                    ? 'يستخدم المفتاح الحالي'
                    : credit.label,
                helperStyle: credit != null &&
                        (credit.exhausted || credit.state == ElevenCreditState.invalid)
                    ? const TextStyle(color: AppColors.error)
                    : null,
              ),
            ),
            if (_saved) ...[
              const SizedBox(height: 12),
              Text(
                'تم الحفظ على الحساب',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (_cloudFailed) ...[
              const SizedBox(height: 12),
              Text(
                'ما انحفظ على الحساب. شغّل ملف admin_settings من Supabase مرة واحدة.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const Spacer(),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _save();
                    },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.title,
    required this.value,
    required this.alert,
  });

  final String title;
  final String value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = alert ? AppColors.error : AppColors.secondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: alert ? const Color(0xFFFFF1F0) : AppColors.background,
        borderRadius: BorderRadius.circular(AppColors.border_radius),
        border: Border.all(color: alert ? AppColors.error : AppColors.inputBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
