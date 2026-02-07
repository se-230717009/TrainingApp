import 'package:flutter/material.dart';

class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double scaleAmount; // Ne kadar küçülecek? (Varsayılan 0.95)

  const ScaleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.scaleAmount = 0.95,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), // Çok hızlı tepki versin
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleAmount,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward(); // Basınca küçült
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse(); // Bırakınca büyüt
    widget.onPressed(); // İşlemi yap
  }

  void _onTapCancel() {
    _controller.reverse(); // Vazgeçerse büyüt
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value, // Animasyon değeri (1.0 -> 0.95)
            child: widget.child,
          );
        },
      ),
    );
  }
}
