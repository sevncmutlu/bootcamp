import 'dart:developer' as developer;
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:maki_app/database/database.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/services/maki_api_client.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final _database = AppDatabase.instance;
  final _picker = ImagePicker();

  XFile? _selectedImage;
  bool _isUploading = false;

  bool _hasResult = false;
  final _storeController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _database.getAllCategories();
    setState(() {
      _categories = categories;
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first.name;
      }
    });
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
          SnackBar(content: Text(AppLocalizations.of(context)!.ocrError)),
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

      if (mounted) {
        setState(() {
          _storeController.text = scan.merchantName ?? '';
          _amountController.text = scan.totalMinor == null
              ? ''
              : (scan.totalMinor! / 100).toStringAsFixed(2);
          _selectedDate = DateTime.now();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.userMessage)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _saveExpense() async {
    final storeName = _storeController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (storeName.isNotEmpty && amount > 0 && _selectedCategory != null) {
      await _database.insertExpense(
        ExpensesCompanion.insert(
          title: storeName,
          amount: amount,
          date: _selectedDate,
          category: _selectedCategory!,
          notes: const drift.Value(null),
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanReceipt)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                      child: Image.file(
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
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: Text(l10n.cameraButton),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(l10n.galleryButton),
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
                      onPressed: _uploadAndParseReceipt,
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
                  prefixIcon: const Icon(Icons.attach_money_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: l10n.labelCategory,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: _categories.map((cat) {
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
                        Text(cat.name),
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
                      color: theme.colorScheme.outline.withValues(alpha: 0.15),
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
    );
  }
}
