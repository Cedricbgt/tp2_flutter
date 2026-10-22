import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Champ de saisie avec son libellé au-dessus, en version claire ou sombre.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.fieldKey,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.readOnly = false,
    this.dark = false,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
  });

  final String label;
  final Key? fieldKey;
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final bool readOnly;
  final bool dark;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final OutlineInputBorder? darkBorder = dark
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.inputLarge),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          )
        : null;

    final Color? fillColor = dark
        ? AppColors.darkInput
        : readOnly
        ? AppColors.readonlyFill
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: dark ? AppColors.textOnDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: fieldKey,
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          cursorColor: dark ? AppColors.accent : AppColors.ink,
          style: textTheme.bodyLarge?.copyWith(
            color: dark
                ? AppColors.surface
                : readOnly
                ? AppColors.textSecondary
                : AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            fillColor: fillColor,
            suffixIcon: suffix,
            constraints: BoxConstraints(minHeight: dark ? 54 : 48),
            contentPadding: EdgeInsets.symmetric(
              horizontal: dark ? 16 : 14,
              vertical: dark ? 17 : 14,
            ),
            enabledBorder: readOnly
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide.none,
                  )
                : darkBorder,
            focusedBorder: dark
                ? darkBorder!.copyWith(
                    borderSide: const BorderSide(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
