import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/core/di/injection_container.dart' as di;
import 'package:maki_app/core/utils/category_l10n.dart';
import 'package:maki_app/core/widgets/maki_app_bar_title.dart';
import 'package:maki_app/core/widgets/maki_background.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maki_app/core/widgets/money_field.dart';
import 'package:maki_app/features/insights/data/services/price_basket_service.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final _picker = ImagePicker();

  XFile? _selectedImage;
  bool _isUploading = false;
  bool? _ocrReady;

  bool _hasResult = false;
  final _storeController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String? _receiptSourceId;
  List<ReceiptLineScan> _receiptItems = const [];
  bool _addItemsToPriceBasket = false;

  @override
  void initState() {
    super.initState();
    final categories = context.read<TransactionBloc>().state.categories;
    if (categories.isNotEmpty) {
      _selectedCategory = categories.first.name;
    }
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    try {
      final capabilities = await MakiApi.instance.capabilities();
      if (mounted) {
        setState(() => _ocrReady = capabilities.receiptScanning);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _ocrReady = null);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _hasResult = false;
        });
      }
    } catch (e) {
      developer.log(
        'Fiş görseli seçilemedi.',
        error: e,
        name: 'ReceiptScannerScreen',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedSelectImage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _uploadAndParseReceipt() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      var mediaType = 'image/jpeg';
      final fileNameLower = _selectedImage!.name.toLowerCase();
      if (fileNameLower.endsWith('.png')) {
        mediaType = 'image/png';
      }
      final scan = await MakiApi.instance.scanReceipt(
        bytes: bytes,
        fileName: _selectedImage!.name,
        mediaType: mediaType,
      );

      final merchant = scan.merchantName?.trim();
      final category = merchant == null || merchant.isEmpty
          ? null
          : await di.sl<AppDatabase>().getMerchantCategory(merchant);
      final canAutoSave =
          !scan.requiresReview &&
          scan.totalConfidence >= 0.92 &&
          scan.merchantConfidence >= 0.85 &&
          scan.totalMinor != null &&
          scan.totalMinor! > 0 &&
          merchant != null &&
          merchant.isNotEmpty &&
          category != null;

      if (canAutoSave && mounted) {
        context.read<TransactionBloc>().add(
          AddExpenseEvent(
            ExpenseEntity(
              title: merchant,
              amount: scan.totalMinor! / 100,
              date: DateTime.now(),
              category: category,
              sourceType: 'receipt',
              sourceRef: scan.sourceId,
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$merchant fişi giderlere güvenle eklendi.')),
        );
        Navigator.of(context).pop();
        return;
      }

      if (mounted) {
        setState(() {
          _storeController.text = scan.merchantName ?? '';
          _amountController.text = scan.totalMinor == null
              ? ''
              : (scan.totalMinor! / 100).toStringAsFixed(2);
          _selectedDate = DateTime.now();
          _receiptSourceId = scan.sourceId;
          _receiptItems = scan.items;
          _addItemsToPriceBasket = false;
          if (category != null) _selectedCategory = category;
          _hasResult = true;
        });
      }
    } on MakiApiException catch (error, stackTrace) {
      developer.log(
        'Fiş çözümleme işlemi tamamlanamadı.',
        error: error.code,
        stackTrace: stackTrace,
        name: 'ReceiptScannerScreen',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.errorParsingReceipt(error.userMessage),
            ),
          ),
        );
      }
    } catch (e) {
      developer.log('Bilinmeyen hata', error: e, name: 'ReceiptScannerScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorParsingReceipt(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _saveExpense() async {
    final storeName = _storeController.text.trim();
    final amount = MoneyField.tryParse(_amountController.text) ?? 0;

    if (storeName.isNotEmpty && amount > 0 && _selectedCategory != null) {
      await di.sl<AppDatabase>().confirmMerchantCategory(
        storeName,
        _selectedCategory!,
      );
      if (_addItemsToPriceBasket &&
          _receiptItems.isNotEmpty &&
          _receiptSourceId != null) {
        await di.sl<PriceBasketService>().confirmReceiptItems(
          items: _receiptItems,
          category: _selectedCategory!,
          observedAt: _selectedDate,
          sourceRef: _receiptSourceId!,
        );
      }
      if (!mounted) return;
      context.read<TransactionBloc>().add(
        AddExpenseEvent(
          ExpenseEntity(
            title: storeName,
            amount: amount,
            date: _selectedDate,
            category: _selectedCategory!,
            sourceType: 'receipt',
            sourceRef: _receiptSourceId,
          ),
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'receipt':
        return Icons.receipt_long_outlined;
      case 'directions_bus':
        return Icons.directions_bus_outlined;
      case 'sports_esports':
        return Icons.sports_esports_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _parseHexColor(String hexStr) {
    try {
      final cleanHex = hexStr.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final categories = context.read<TransactionBloc>().state.categories;

    return Scaffold(
      appBar: AppBar(title: MakiAppBarTitle(title: l10n.scanReceipt)),
      body: MakiBackground(
        maxContentWidth: 720,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OcrStatusCard(ready: _ocrReady, onRetry: _loadCapabilities),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.05,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: kIsWeb
                            ? Image.network(
                                _selectedImage!.path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_selectedImage!.path),
                                fit: BoxFit.cover,
                              ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: Text(l10n.cameraButton),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: Text(l10n.galleryButton),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),

              if (_selectedImage != null && !_hasResult && !_isUploading)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selectedImage = null),
                        child: Text(l10n.clearButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _ocrReady == false
                            ? null
                            : _uploadAndParseReceipt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 0,
                        ),
                        child: Text(l10n.parseReceipt),
                      ),
                    ),
                  ],
                ),

              if (_isUploading)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      l10n.parsingStatus,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

              if (_hasResult) ...[
                const Divider(height: 40),
                Text(
                  l10n.reviewTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _storeController,
                  decoration: InputDecoration(
                    labelText: l10n.labelStoreName,
                    prefixIcon: const Icon(Icons.storefront_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.labelTotalAmount,
                    prefixIcon: const Icon(Icons.currency_lira),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: l10n.labelCategory,
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat.name,
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(cat.iconName),
                            color: _parseHexColor(cat.colorHex),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(getLocalizedCategoryName(context, cat.name)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_receiptItems.isNotEmpty) ...[
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _addItemsToPriceBasket,
                    onChanged: (value) =>
                        setState(() => _addItemsToPriceBasket = value ?? false),
                    title: Text(
                      '${_receiptItems.length} ürün fiyatını kişisel '
                      'enflasyon sepetime ekle',
                    ),
                    subtitle: const Text(
                      'Yalnızca sen onaylarsan ürün adı, miktar ve birim fiyat '
                      'cihazında saklanır.',
                    ),
                  ),
                  if (_addItemsToPriceBasket)
                    ..._receiptItems
                        .take(4)
                        .map(
                          (item) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.shopping_basket_outlined),
                            title: Text(item.productName),
                            trailing: Text(
                              '${(item.unitPriceMinor / 100).toStringAsFixed(2)} ₺',
                            ),
                          ),
                        ),
                  const SizedBox(height: 8),
                ],
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 18.0,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.15,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined),
                        const SizedBox(width: 16),
                        Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.addToExpenses,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OcrStatusCard extends StatelessWidget {
  const _OcrStatusCard({required this.ready, required this.onRetry});

  final bool? ready;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReady = ready == true;
    final title = switch (ready) {
      true => 'Fiş tarama hazır',
      false => 'Fiş tarama modeli henüz kurulmadı',
      null => 'Fiş tarama durumu denetlenemedi',
    };
    final body = switch (ready) {
      true => 'Fiş görseli bu Maki sunucusunda PaddleOCR ile işlenecek.',
      false =>
        'Bilgisayarda scripts\\setup_paddle_ocr.ps1 komutunu bir kez çalıştır.',
      null => 'Backend bağlantısını kontrol edip yeniden dene.',
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isReady
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.48)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: isReady
                ? theme.colorScheme.primary.withValues(alpha: 0.24)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isReady
                  ? Icons.check_circle_outline
                  : Icons.receipt_long_outlined,
              color: isReady
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(body, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (!isReady)
              IconButton(
                tooltip: 'Yeniden denetle',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
