import 'package:flutter/material.dart';

class StyledTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final dynamic keyboardType;
  final double? height;

  const StyledTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.keyboardType,
    this.height,
  }) : super(key: key);

  @override
  _StyledTextFieldState createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<StyledTextField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height ?? 45,
      width: 250,
      child: TextField(
        keyboardType: widget.keyboardType ?? TextInputType.text,
        style: const TextStyle(fontSize: 14.0),
        controller: widget.controller,
        obscureText:
            widget.obscureText ? _isObscured : false, // Check the condition
        cursorColor: const Color(0xFF252525),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.only(bottom: 16, left: 10, right: 10),
          hintText: widget.hintText,
          filled: true,
          fillColor: Colors.white,
          border: InputBorder.none,
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8),
            ),
            borderSide: BorderSide(
              color: Color(0xFF00A2FF),
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8),
            ),
            borderSide: BorderSide(
              color: Color(0xFF00A2FF),
            ),
          ),
          suffixIcon: widget.obscureText
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                  icon: Icon(
                    _isObscured ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
