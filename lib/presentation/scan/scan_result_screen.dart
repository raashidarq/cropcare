import 'dart:io';
import 'package:flutter/material.dart';

import '../../domain/entities/scan.dart';
import '../../domain/usecases/scan/get_scan_by_id_use_case.dart';
import '../onboarding/localization/localization_provider.dart';

class ScanResultScreen extends StatefulWidget {
  final Scan? scan;
  final String? scanId;
  final GetScanByIdUseCase? getScanByIdUseCase;

  const ScanResultScreen({
    super.key,
    this.scan,
    this.scanId,
    this.getScanByIdUseCase,
  }) : assert(scan != null || (scanId != null && getScanByIdUseCase != null));

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  Scan? _scan;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.scan != null) {
      _scan = widget.scan;
    } else {
      _fetchScan();
    }
  }

  Future<void> _fetchScan() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetched = await widget.getScanByIdUseCase!(widget.scanId!);
      setState(() {
        _scan = fetched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('scan_result_title')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : _scan == null
                  ? const Center(child: Text('Scan not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (File(_scan!.imageLocalPath).existsSync())
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 250,
                                width: double.infinity,
                                color: Colors.black12,
                                child: Image.file(
                                  File(_scan!.imageLocalPath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  _buildFieldRow(
                                    context,
                                    context.tr('scan_id'),
                                    _scan!.id,
                                  ),
                                  const Divider(),
                                  _buildFieldRow(
                                    context,
                                    context.tr('crop'),
                                    _scan!.cropId,
                                  ),
                                  const Divider(),
                                  _buildFieldRow(
                                    context,
                                    context.tr('status'),
                                    _scan!.status.value,
                                    badgeColor: theme.colorScheme.primary,
                                  ),
                                  const Divider(),
                                  _buildFieldRow(
                                    context,
                                    context.tr('captured_at'),
                                    _scan!.capturedAt.toIso8601String(),
                                  ),
                                  const Divider(),
                                  _buildFieldRow(
                                    context,
                                    context.tr('image_path'),
                                    _scan!.imageLocalPath,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildFieldRow(
    BuildContext context,
    String label,
    String value, {
    Color? badgeColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: badgeColor != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor),
                    ),
                    child: Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: theme.textTheme.bodyMedium,
                  ),
          ),
        ],
      ),
    );
  }
}
