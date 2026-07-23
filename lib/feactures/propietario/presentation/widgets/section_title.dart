import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(children: [
      Container(width: 3, height: 18,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          )),
      const SizedBox(width: 8),
      // Expanded para que títulos largos hagan wrap en pantallas angostas
      // (Android) en vez de desbordar la fila.
      Expanded(
        child: Text(
          text,
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ]);
  }
}
