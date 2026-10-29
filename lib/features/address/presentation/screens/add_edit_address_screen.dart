import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/address_model.dart';
import '../providers/address_provider.dart';

/// `/add-address` and `/edit-address` (extra: Address), spec C23.
class AddEditAddressScreen extends ConsumerStatefulWidget {
  final Address? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  static const _labels = ['Home', 'Office', 'Other'];
  static const double _fieldHeight = 46;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _area;
  late final TextEditingController _addressLine;

  late String _division;
  late String _district;
  late String _label;
  late bool _isDefault;
  bool _saving = false;

  List<String> get _districts =>
      AppConstants.districtsByDivision[_division] ?? const [];

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _name = TextEditingController(text: a?.fullName ?? '');
    _phone = TextEditingController(
      text: a == null ? '' : PhoneField.normalize(a.phone),
    );
    _area = TextEditingController(text: a?.area ?? '');
    _addressLine = TextEditingController(text: a?.addressLine ?? '');

    _division = AppConstants.divisions.contains(a?.division)
        ? a!.division
        : AppConstants.divisions.first;
    _district = _districts.contains(a?.district)
        ? a!.district
        : _districts.first;
    final label = (a?.label ?? 'Home').toLowerCase();
    _label = _labels.firstWhere(
      (l) => l.toLowerCase() == label,
      orElse: () => 'Other',
    );
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _area.dispose();
    _addressLine.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save an address.')),
      );
      return;
    }

    setState(() => _saving = true);
    final existing = widget.address;
    final address = Address(
      id: existing?.id ?? '',
      userId: user.id,
      fullName: _name.text.trim(),
      phone: '0${PhoneField.normalize(_phone.text)}',
      division: _division,
      district: _district,
      area: _area.text.trim(),
      addressLine: _addressLine.text.trim(),
      city: _district,
      postalCode: existing?.postalCode ?? '',
      label: _label.toUpperCase(),
      isDefault: _isDefault,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final notifier = ref.read(addressListProvider.notifier);
      existing == null
          ? await notifier.addAddress(address)
          : await notifier.updateAddress(address);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Address saved' : 'Address updated'),
        ),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Couldn't save the address. ${ErrorView.describe(error)}",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    Key? key,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppText.captionStrong),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: key,
          initialValue: value,
          isExpanded: true,
          style: AppText.inputText,
          icon: const Icon(Icons.expand_more, color: AppColors.muted),
          decoration: const InputDecoration(
            constraints: BoxConstraints(minHeight: _fieldHeight),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppText.captionStrong;
    final isEdit = widget.address != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(
        title: isEdit ? 'Edit address' : 'Add address',
        fallbackRoute: '/addresses',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: AppSpacing.l,
          ),
          children: [
            Tooltip(
              message: 'Coming soon',
              child: OutlinedButton.icon(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: AppColors.primaryTint,
                  disabledBackgroundColor: AppColors.primaryTint,
                  disabledForegroundColor: AppColors.primary.withValues(
                    alpha: 0.6,
                  ),
                  side: const BorderSide(color: AppColors.primary),
                  textStyle: AppText.bodyStrong,
                ),
                icon: const Icon(Icons.my_location, size: AppSpacing.iconSmall),
                label: const Text('Use my current location'),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            _TwoColumns(
              left: AppTextField(
                label: 'Full name',
                labelStyle: labelStyle,
                controller: _name,
                height: _fieldHeight,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              right: PhoneField(
                label: 'Phone',
                labelStyle: labelStyle,
                controller: _phone,
                required: true,
                height: _fieldHeight,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            _dropdown(
              label: 'Division',
              value: _division,
              items: AppConstants.divisions,
              onChanged: (v) => setState(() {
                _division = v;
                _district = _districts.first;
              }),
            ),
            const SizedBox(height: AppSpacing.m),
            _TwoColumns(
              left: _dropdown(
                key: ValueKey('district-$_division'),
                label: 'District',
                value: _district,
                items: _districts,
                onChanged: (v) => setState(() => _district = v),
              ),
              right: AppTextField(
                label: 'Area',
                labelStyle: labelStyle,
                controller: _area,
                hint: 'e.g. Dhanmondi',
                height: _fieldHeight,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              label: 'Address',
              labelStyle: labelStyle,
              controller: _addressLine,
              hint: 'House, road, building, landmark',
              maxLines: 2,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Enter your full address'
                  : null,
            ),
            const SizedBox(height: AppSpacing.m),
            Text('Label', style: labelStyle),
            const SizedBox(height: 6),
            Wrap(
              spacing: AppSpacing.s,
              children: [
                for (final l in _labels)
                  AppChip(
                    label: l,
                    height: 40,
                    selected: _label == l,
                    onTap: () => setState(() => _label = l),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            CheckboxListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Make this my default address',
                style: AppText.menuLabel,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            AppSpacing.m,
            20,
            AppSpacing.xl,
          ),
          child: AppButton.primary(
            label: 'Save address',
            loading: _saving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}

/// Two fields side by side, stacked when the screen is narrow or the text is large.
class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final stacked =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.2;
    if (stacked) {
      return Column(
        children: [
          left,
          const SizedBox(height: AppSpacing.m),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSpacing.m),
        Expanded(child: right),
      ],
    );
  }
}
