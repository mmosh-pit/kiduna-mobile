import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/extensions/context_extensions.dart';

class KidunaOtpField extends StatefulWidget {
  const KidunaOtpField({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
  });

  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;

  @override
  State<KidunaOtpField> createState() => _KidunaOtpFieldState();
}

class _KidunaOtpFieldState extends State<KidunaOtpField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentCode => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    final code = _currentCode;
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  void _onPaste(int index, String pasted) {
    final digits = pasted.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < digits.length && index + i < widget.length; i++) {
      _controllers[index + i].text = digits[i];
    }
    final target = (index + digits.length).clamp(0, widget.length - 1);
    _focusNodes[target].requestFocus();
    final code = _currentCode;
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index < widget.length - 1 ? 10 : 0),
          child: SizedBox(
            width: 52,
            height: 58,
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace &&
                    _controllers[index].text.isEmpty &&
                    index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }
              },
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                maxLength: 1,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontFamily: 'GoudyHeavyface',
                  fontSize: 26,
                  color: colors.text,
                ),
                cursorColor: colors.sky,
                onChanged: (value) {
                  if (value.length > 1) {
                    _onPaste(index, value);
                  } else {
                    _onChanged(index, value);
                  }
                },
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: colors.deep.withValues(alpha: 0.7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colors.camel.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.sky),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
