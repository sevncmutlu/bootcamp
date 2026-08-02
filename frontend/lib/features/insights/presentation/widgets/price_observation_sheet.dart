import 'package:flutter/material.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/widgets/money_field.dart';
import 'package:maki_app/features/insights/data/services/price_basket_service.dart';

class PriceObservationSheet extends StatefulWidget {
  const PriceObservationSheet({
    super.key,
    required this.service,
    this.initialDate,
  });

  final PriceBasketService service;
  final DateTime? initialDate;

  @override
  State<PriceObservationSheet> createState() => _PriceObservationSheetState();
}

class _PriceObservationSheetState extends State<PriceObservationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String _category = 'Market';
  late DateTime _date = widget.initialDate ?? DateTime.now();
  bool _saving = false;

  static const categories = [
    'Market',
    'Restoran',
    'Ulaşım',
    'Faturalar',
    'Sağlık',
    'Diğer',
  ];

  @override
  void dispose() {
    _productController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final priceMinor = MoneyField.tryParseMinor(_priceController.text)!;
    final quantity = double.parse(
      _quantityController.text.trim().replaceAll(',', '.'),
    );
    setState(() => _saving = true);
    await widget.service.addManualObservation(
      productName: _productController.text,
      category: _category,
      observedAt: _date,
      unitPriceMinor: priceMinor,
      quantityMilli: (quantity * 1000).round(),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sepetime fiyat ekle',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aynı ürün için farklı tarihlerde en az iki fiyat '
                  'girdiğinde kişisel enflasyonun hesaplanır.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _productController,
                  decoration: const InputDecoration(
                    labelText: 'Ürün adı',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ürün adını yaz.'
                      : null,
                ),
                const SizedBox(height: 12),
                MoneyField(
                  controller: _priceController,
                  labelText: 'Birim fiyat',
                  validator: (value) {
                    final minor = MoneyField.tryParseMinor(value);
                    return minor == null || minor <= 0
                        ? 'Geçerli bir fiyat yaz.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Miktar',
                    prefixIcon: Icon(Icons.scale_outlined),
                  ),
                  validator: (value) {
                    final quantity = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    return quantity == null || quantity <= 0
                        ? 'Geçerli bir miktar yaz.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Fiyat tarihi'),
                  subtitle: Text(
                    '${_date.day.toString().padLeft(2, '0')}.'
                    '${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final value = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (value != null) setState(() => _date = value);
                  },
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded),
                  label: const Text('Fiyatı kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
