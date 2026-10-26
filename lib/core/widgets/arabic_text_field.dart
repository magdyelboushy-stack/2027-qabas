import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ArabicTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String?)? onSaved;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function()? onTap;
  final bool enabled;
  final int maxLines;
  final TextEditingController? controller;
  final bool isDark;
  final String? initialValue;

  const ArabicTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onSaved,
    this.validator,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.maxLines = 1,
    this.controller,
    required this.isDark,
    this.initialValue,
  });

  @override
  State<ArabicTextField> createState() => _ArabicTextFieldState();
}

class _ArabicTextFieldState extends State<ArabicTextField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = widget.controller ?? TextEditingController();

    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark
        ? (_isFocused
            ? const Color(0xFFD4AF37)
            : const Color(0xFFD4AF37).withOpacity(0.3))
        : (_isFocused ? const Color(0xFFD4AF37) : Colors.grey.shade400);

    final fillColor = widget.isDark
        ? const Color(0xFF1E4D3E).withOpacity(0.5)
        : Colors.white.withOpacity(0.8);

    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final hintColor =
        widget.isDark ? Colors.white.withOpacity(0.6) : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: _isFocused ? 2 : 1),
        boxShadow: widget.isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: _isFocused ? 8 : 4,
                  offset: Offset(0, _isFocused ? 4 : 2),
                )
              ],
      ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          height: 1.4,
        ),
        textAlign: TextAlign.right, // Force RTL text alignment
        textDirection: TextDirection.rtl, // Force RTL text direction
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          labelStyle: TextStyle(
            color: hintColor,
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 14,
          ),
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon,
                  color: const Color(0xFFD4AF37), size: 22)
              : null,
          suffixIcon: widget.suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.prefixIcon != null ? 16 : 20,
            vertical: widget.maxLines > 1 ? 16 : 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: widget.validator,
        onSaved: widget.onSaved,
        onChanged: widget.onChanged,
        onTap: widget.onTap,
        // Enable better Arabic keyboard support
        inputFormatters: [
          FilteringTextInputFormatter.deny(
              RegExp(r'[a-zA-Z]')), // Block English letters by default
          // Allow Arabic letters, numbers, and special characters
          LengthLimitingTextInputFormatter(1000),
        ],
      ),
    );
  }


}

// Enhanced Arabic text field with better keyboard support
class EnhancedArabicTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String?)? onSaved;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function()? onTap;
  final bool enabled;
  final int maxLines;
  final TextEditingController? controller;
  final bool isDark;
  final String? initialValue;
  final bool allowEnglish; // Option to allow English input

  const EnhancedArabicTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onSaved,
    this.validator,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.maxLines = 1,
    this.controller,
    required this.isDark,
    this.allowEnglish = false,
    this.initialValue,
  });

  @override
  State<EnhancedArabicTextField> createState() =>
      _EnhancedArabicTextFieldState();
}

class _EnhancedArabicTextFieldState extends State<EnhancedArabicTextField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isFocused = false;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = widget.controller ?? TextEditingController();
    _obscureText = widget.obscureText;

    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark
        ? (_isFocused
            ? const Color(0xFFD4AF37)
            : const Color(0xFFD4AF37).withOpacity(0.3))
        : (_isFocused ? const Color(0xFFD4AF37) : Colors.grey.shade400);

    final fillColor = widget.isDark
        ? const Color(0xFF1E4D3E).withOpacity(0.5)
        : Colors.white.withOpacity(0.8);

    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final hintColor =
        widget.isDark ? Colors.white.withOpacity(0.6) : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: _isFocused ? 2 : 1),
        boxShadow: widget.isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: _isFocused ? 8 : 4,
                  offset: Offset(0, _isFocused ? 4 : 2),
                )
              ],
      ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          height: 1.4,
          fontFamily: 'Cairo', // Use Arabic-friendly font
        ),
        textAlign: TextAlign.right, // Force RTL text alignment
        textDirection: TextDirection.rtl, // Force RTL text direction
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          labelStyle: TextStyle(
            color: hintColor,
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 14,
          ),
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon,
                  color: const Color(0xFFD4AF37), size: 22)
              : null,
          suffixIcon: widget.obscureText
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: hintColor,
                    size: 22,
                  ),
                )
              : widget.suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.prefixIcon != null ? 16 : 20,
            vertical: widget.maxLines > 1 ? 16 : 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: widget.validator,
        onSaved: widget.onSaved,
        onChanged: widget.onChanged,
        onTap: widget.onTap,
        // Enhanced input formatters for better Arabic support
        inputFormatters: widget.allowEnglish
            ? [
                LengthLimitingTextInputFormatter(1000),
              ]
            : [
                FilteringTextInputFormatter.deny(
                    RegExp(r'[a-zA-Z]')), // Block English letters
                LengthLimitingTextInputFormatter(1000),
              ],
        // Enable better text selection and cursor behavior
        enableInteractiveSelection: true,
        scrollPhysics: const ClampingScrollPhysics(),
      ),
    );
  }


}
