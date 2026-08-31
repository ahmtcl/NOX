import 'package:flutter/material.dart';

class NoxStripeBackground extends StatelessWidget {
  const NoxStripeBackground({super.key, this.blur = 0});

  /// Kept for existing callers; the static verification layout has no blur.
  final double blur;

  @override
  Widget build(BuildContext context) => const _AnimatedStripes();
}

class _AnimatedStripes extends StatefulWidget {
  const _AnimatedStripes();

  @override
  State<_AnimatedStripes> createState() => _AnimatedStripesState();
}

class _AnimatedStripesState extends State<_AnimatedStripes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = Curves.easeInOut.transform(_controller.value);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < 12; index++)
                    Expanded(
                      child: ClipRect(
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            (index.isEven ? 1 : -1) * (progress - .5) * 10,
                          ),
                          child: SizedBox(
                            height: constraints.maxHeight + 12,
                            child: ColoredBox(
                              color: index.isEven
                                  ? const Color(0xFFD3E4F8)
                                  : const Color(0xFFEEF5FD),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      );
}
