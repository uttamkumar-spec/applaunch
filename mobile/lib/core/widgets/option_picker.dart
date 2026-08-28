import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single/list-choice picker with a built-in "Other" option that reveals a
/// free-text field. Used anywhere in the app that offers a fixed set of
/// choices but shouldn't force an answer that doesn't fit — the free text is
/// preserved (never overwritten by the fixed options) so it can inform
/// future product changes.
///
/// [selected] is the option key, or [otherValue] when "Other" is chosen.
class OptionPicker extends StatefulWidget {
  const OptionPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.otherText,
    required this.onOtherTextChanged,
    this.otherLabel = 'Something else',
    this.otherHint = "Tell us in your own words — we're listening.",
    this.otherValue = 'other',
  });

  final Map<String, String> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final String otherText;
  final ValueChanged<String> onOtherTextChanged;
  final String otherLabel;
  final String otherHint;
  final String otherValue;

  @override
  State<OptionPicker> createState() => _OptionPickerState();
}

class _OptionPickerState extends State<OptionPicker> {
  late final TextEditingController _controller;

  bool get _isOtherSelected => widget.selected == widget.otherValue;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.otherText);
  }

  @override
  void didUpdateWidget(covariant OptionPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.otherText != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.otherText,
        selection: TextSelection.collapsed(offset: widget.otherText.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ...widget.options.entries.map((e) => _OptionTile(
              label: e.value,
              isSelected: e.key == widget.selected,
              onTap: () => widget.onSelect(e.key),
            )),
        _OptionTile(
          label: widget.otherLabel,
          isSelected: _isOtherSelected,
          onTap: () => widget.onSelect(widget.otherValue),
        ),
        if (_isOtherSelected) ...[
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: widget.otherHint,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE3E6DF)),
              ),
            ),
            controller: _controller,
            onChanged: widget.onOtherTextChanged,
          ),
        ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE3E6DF),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary)
              else
                const Icon(Icons.circle_outlined, color: Color(0xFFCBD1C7)),
            ],
          ),
        ),
      ),
    );
  }
}
