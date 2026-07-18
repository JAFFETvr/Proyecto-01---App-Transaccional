import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/theme_extensions.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../providers/card_provider.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parts = _expiryCtrl.text.split('/');
    final month = int.tryParse(parts[0].trim()) ?? 0;
    final year = int.tryParse('20${parts[1].trim()}') ?? 0;

    final provider = context.read<CardProvider>();
    final ok = await provider.addCard(
      cardNumber: _numberCtrl.text.replaceAll(' ', ''),
      cardholderName: _nameCtrl.text.trim(),
      expirationMonth: month,
      expirationYear: year,
      securityCode: _cvvCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'No se pudo guardar la tarjeta'),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardProvider>();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Agregar tarjeta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(children: [
                  Icon(Icons.lock_outline, size: 16, color: context.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tu tarjeta se valida directo con Mercado Pago; nunca pasa por nuestros servidores.',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _numberCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                decoration: const InputDecoration(
                  labelText: 'Número de tarjeta',
                  hintText: '4509 9535 6623 3704',
                  prefixIcon: Icon(Icons.credit_card_rounded),
                ),
                validator: (v) => (v == null || v.replaceAll(' ', '').length < 13) ? 'Número inválido' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Nombre del titular',
                  hintText: 'APRO',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryDateFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Vencimiento',
                      hintText: 'MM/AA',
                    ),
                    validator: (v) => (v == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) ? 'MM/AA' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvvCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                    ),
                    validator: (v) => (v == null || v.length < 3) ? 'CVV inválido' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 28),
              PrimaryGradientButton(
                label: provider.loading ? 'Guardando...' : 'Guardar tarjeta',
                icon: Icons.lock_outline,
                height: 55,
                onPressed: provider.loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 2) {
      return TextEditingValue(text: digits, selection: TextSelection.collapsed(offset: digits.length));
    }
    final formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
