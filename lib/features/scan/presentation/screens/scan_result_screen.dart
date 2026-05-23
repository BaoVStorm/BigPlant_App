import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/plant_scan_result.dart';
import '../../domain/scan_service.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({
    required this.imageBytes,
    required this.result,
    this.fetchDetailsFromApi = false,
    this.detailFetchFileName = 'camera_scan.jpg',
    this.plantLabel,
    this.inferenceFramework,
    super.key,
  });

  final Uint8List imageBytes;
  final PlantScanResult result;
  final bool fetchDetailsFromApi;
  final String detailFetchFileName;
  final String? plantLabel;
  final String? inferenceFramework;

  static String valueOrPlaceholder(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
  }

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final FlutterTts _tts = FlutterTts();
  final ScanService _scanService = ScanService();

  bool _isSpeaking = false;
  bool _ttsReady = false;
  bool _fetchingDetails = false;
  bool _technicalExpanded = false;
  bool _successBannerVisible = false;
  String? _fetchError;
  PlantScanResult? _fetchedDetails;

  @override
  void initState() {
    super.initState();
    _initTts();
    if (widget.fetchDetailsFromApi) {
      _fetchDetailsFromApi();
    }
    _showSuccessBanner();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _showSuccessBanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _successBannerVisible = true);
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted) setState(() => _successBannerVisible = false);
      });
    });
  }

  PlantScanResult get _contentResult => _fetchedDetails ?? widget.result;

  String get _frameworkLabel {
    final explicit = widget.inferenceFramework?.trim() ?? '';
    if (explicit.isNotEmpty) return explicit;

    final initialBackend = widget.result.backend?.trim() ?? '';
    if (initialBackend.isNotEmpty) {
      if (initialBackend.toLowerCase() == 'tensorrt') return 'TensorRT';
      return initialBackend;
    }

    final apiBackend = _fetchedDetails?.backend?.trim() ?? '';
    if (apiBackend.isNotEmpty) {
      if (apiBackend.toLowerCase() == 'tensorrt') return 'TensorRT';
      return apiBackend;
    }

    return 'TensorRT';
  }

  Future<void> _fetchDetailsFromApi() async {
    setState(() {
      _fetchingDetails = true;
      _fetchError = null;
    });
    try {
      final apiResult =
          widget.plantLabel != null && widget.plantLabel!.isNotEmpty
          ? await _scanService.scanPlantByLabel(label: widget.plantLabel!)
          : await _scanService.scanPlant(
              imageBytes: widget.imageBytes,
              fileName: widget.detailFetchFileName,
            );
      if (!mounted) return;
      setState(() {
        _fetchedDetails = apiResult;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetchError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _fetchingDetails = false;
        });
      }
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      _ttsReady = true;
    } on MissingPluginException {
      _ttsReady = false;
    } on PlatformException {
      _ttsReady = false;
    }

    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((_) {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    });
  }

  Future<void> _toggleRead(BuildContext context) async {
    if (!_ttsReady) {
      _showTtsUnavailable(context);
      return;
    }

    if (_isSpeaking) {
      await _tts.stop();
      if (!mounted) return;
      setState(() => _isSpeaking = false);
      return;
    }

    final text = _buildReadText(context);
    if (text.isEmpty) return;

    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode.toLowerCase();
    try {
      await _tts.setLanguage(languageCode == 'vi' ? 'vi-VN' : 'en-US');
      final speakResult = await _tts.speak(text);
      if (!mounted) return;
      if (speakResult == 1) {
        setState(() => _isSpeaking = true);
      }
    } on MissingPluginException {
      if (!mounted) return;
      _ttsReady = false;
      _showTtsUnavailable(context);
    } on PlatformException {
      if (!mounted) return;
      _showTtsUnavailable(context);
    }
  }

  void _showTtsUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text-to-speech is unavailable. Please restart the app.'),
      ),
    );
  }

  String _buildReadText(BuildContext context) {
    final t = AppLocalizations.of(context);
    final plant = _contentResult;
    final lines = <String>[];

    void addLine(String label, String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      lines.add('$label: $trimmed.');
    }

    addLine(t.t('field_common_name'), plant.commonName);
    addLine(t.t('field_scientific_name'), plant.scientificName);
    addLine(t.t('field_family'), plant.family);
    addLine(t.t('field_order'), plant.order);
    addLine(t.t('field_genus'), plant.genus);
    addLine(t.t('field_species'), plant.species);
    addLine(t.t('field_description'), plant.description);
    addLine(t.t('field_uses'), plant.uses);
    addLine(t.t('field_advantages'), plant.advantages);
    addLine(t.t('plant_toxicity_warning_title'), plant.toxicityWarning);
    addLine(t.t('plant_safety_notes_title'), plant.safetyNotes);

    if (plant.distributionAreas.isNotEmpty) {
      addLine(t.t('distribution_map'), plant.distributionAreas.join(', '));
    }

    return lines.join(' ');
  }

  void _sharePlantDetail() {
    final plant = _contentResult;
    final payload = [
      plant.scientificName,
      if (plant.commonName.trim().isNotEmpty) plant.commonName,
      if (plant.description.trim().isNotEmpty) plant.description,
    ].join('\n');

    Clipboard.setData(ClipboardData(text: payload));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).t('toast_saved_clipboard')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final plant = _contentResult;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(24, 100, 24, 120),
            children: [
              _HeroSection(
                imageBytes: widget.imageBytes,
                familyLabel: plant.family,
                title: _primaryDisplayTitle(plant),
                subtitle: _secondaryDisplayTitle(plant),
                frameworkLabel: _frameworkLabel,
                modelLabel:
                    widget.result.modelName ?? _fetchedDetails?.modelName,
                confidence:
                    widget.result.confidence ?? _fetchedDetails?.confidence,
              ),
              const SizedBox(height: 24),
              if (_fetchingDetails) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    minHeight: 4,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primaryFixed,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_fetchError != null) ...[
                _InlineWarning(message: _fetchError!),
                const SizedBox(height: 16),
              ],
              _PlantSectionCard(
                title: t.t('plant_section_ecology'),
                icon: Icons.eco,
                source: plant.sourceForField('description'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      ScanResultScreen.valueOrPlaceholder(plant.description)
                          .split('\n')
                          .map((line) => line.trim())
                          .where((line) => line.isNotEmpty)
                          .map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                line,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      height: 1.5,
                                      fontSize: 15,
                                    ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 24),
              _PlantSectionCard(
                title: t.t('plant_section_taxonomy'),
                icon: Icons.account_tree,
                child: Column(
                  children: _taxonomyRows(
                    t,
                    plant,
                  ).map((row) => _TaxonomyRow(item: row)).toList(),
                ),
              ),
              const SizedBox(height: 24),
              _EvidenceSafetyCard(plant: plant),
              const SizedBox(height: 24),
              _UtilityBenefitsCard(items: _benefitItems(t, plant)),
              const SizedBox(height: 24),
              _DistributionCard(
                plant: plant,
                onOpenMap: () => _openExpandedMap(context),
                onOpenDetails: () => _showDistributionDetails(context),
              ),
              const SizedBox(height: 24),
              _TechnicalMetadataCard(
                expanded: _technicalExpanded,
                title: t.t('plant_section_technical'),
                metadata: _technicalMetadataText(plant),
                onToggle: () {
                  setState(() {
                    _technicalExpanded = !_technicalExpanded;
                  });
                },
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _PlantDetailTopBar(
              title: t.t('plant_report_title'),
              onBack: () => Navigator.of(context).pop(),
              onShare: _sharePlantDetail,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ScanSuccessBanner(
              visible: _successBannerVisible,
              plantName: _primaryDisplayTitle(plant),
            ),
          ),
        ],
      ),
      floatingActionButton: _VoiceButton(
        speaking: _isSpeaking,
        onTap: () => _toggleRead(context),
      ),
    );
  }

  String _primaryDisplayTitle(PlantScanResult plant) {
    final scientific = plant.scientificName.trim();
    if (scientific.isNotEmpty) return scientific;
    return plant.displayName.trim();
  }

  String _secondaryDisplayTitle(PlantScanResult plant) {
    final common = plant.commonName.trim();
    if (common.isNotEmpty) {
      // Return only the first name if multiple are separated by semicolons
      return common.split(';').first.trim();
    }
    final display = plant.displayName.trim();
    if (display.isNotEmpty && display != plant.scientificName.trim()) {
      return display;
    }
    return '';
  }

  String _technicalMetadataText(PlantScanResult plant) {
    if (plant.note.trim().isNotEmpty) return plant.note;

    final data = <String, dynamic>{
      'scientific_name': plant.scientificName,
      'scientific_name_search': plant.scientificNameSearch,
      'common_name': plant.commonName,
      'family': plant.family,
      'taxonomic_order': plant.order,
      'genus': plant.genus,
      'species': plant.species,
      'taxonomic_status': plant.taxonomicStatus,
      'evidence_level': plant.evidenceLevel,
      'source': plant.source,
      'confidence': plant.confidence,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  List<_TaxonomyItem> _taxonomyRows(AppLocalizations t, PlantScanResult plant) {
    return [
      _TaxonomyItem(
        label: t.t('field_scientific_name'),
        value: plant.scientificName,
        source: plant.sourceForField('scientific_name'),
        italic: false,
      ),
      _TaxonomyItem(
        label: t.t('field_family'),
        value: plant.family,
        source: plant.sourceForField('family'),
      ),
      _TaxonomyItem(
        label: t.t('field_order'),
        value: plant.order,
        source: plant.sourceForField('taxonomic_order'),
      ),
      _TaxonomyItem(
        label: t.t('field_genus'),
        value: plant.genus,
        source: plant.sourceForField('genus'),
        italic: false,
      ),
      _TaxonomyItem(
        label: t.t('field_species'),
        value: plant.species,
        source: plant.sourceForField('species'),
        italic: false,
      ),
      _TaxonomyItem(
        label: t.t('plant_taxonomic_status_label'),
        value: plant.taxonomicStatus.toLowerCase(),
        source: plant.sourceForField('taxonomic_status'),
      ),
    ].where((item) => item.value.trim().isNotEmpty).toList();
  }

  List<_BenefitItem> _benefitItems(AppLocalizations t, PlantScanResult plant) {
    final items = <_BenefitItem>[];

    if (plant.uses.trim().isNotEmpty) {
      items.add(
        _BenefitItem(
          title: t.t('field_uses'),
          description: plant.uses,
          icon: Icons.spa,
          source: plant.sourceForField('uses'),
        ),
      );
    }
    if (plant.advantages.trim().isNotEmpty) {
      items.add(
        _BenefitItem(
          title: t.t('field_advantages'),
          description: plant.advantages,
          icon: Icons.workspace_premium,
          source: plant.sourceForField('advantages'),
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        _BenefitItem(
          title: t.t('field_uses'),
          description: t.t('distribution_not_available'),
          icon: Icons.info_outline,
          source: '',
        ),
      );
    }

    return items;
  }

  Future<void> _openExpandedMap(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final plant = _contentResult;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DistributionMapScreen(
          title: t.t('distribution_map'),
          points: plant.distributionPoints,
          areas: plant.distributionAreas,
          onOpenDetails: _showDistributionDetails,
        ),
      ),
    );
  }

  Future<void> _showDistributionDetails(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final plant = _contentResult;
    final pointItems = plant.distributionPoints;
    final areaItems = plant.distributionAreas;

    IconData iconForPoint(PlantDistributionPoint point) {
      final label = point.label.toLowerCase();
      if (label.contains('forest')) return Icons.forest;
      if (label.contains('rain')) return Icons.public;
      if (label.contains('terrain')) return Icons.terrain;
      return Icons.landscape;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            height: 530,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.t('distribution_detail_title'),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontSize: 24,
                              ),
                        ),
                      ),
                      Material(
                        color: AppColors.surfaceContainer,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => Navigator.of(sheetContext).pop(),
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.close,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  color: AppColors.surfaceContainerHighest,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    children: [
                      if (pointItems.isNotEmpty)
                        for (final point in pointItems) ...[
                          _DistributionListTile(
                            icon: iconForPoint(point),
                            title: point.label.trim().isEmpty
                                ? t.t('distribution_location')
                                : point.label,
                            subtitle:
                                '${point.lat.toStringAsFixed(4)}, ${point.lng.toStringAsFixed(4)}',
                          ),
                          const SizedBox(height: 12),
                        ]
                      else
                        for (final area in areaItems) ...[
                          _DistributionListTile(
                            icon: Icons.public,
                            title: area,
                            subtitle: t.t('distribution_regions'),
                          ),
                          const SizedBox(height: 12),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlantDetailTopBar extends StatelessWidget {
  const _PlantDetailTopBar({
    required this.title,
    required this.onBack,
    required this.onShare,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(
                color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              _TopActionButton(icon: Icons.arrow_back, onTap: onBack),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontSize: 24,
                  ),
                ),
              ),
              _TopActionButton(icon: Icons.share, onTap: onShare),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.imageBytes,
    required this.familyLabel,
    required this.title,
    required this.subtitle,
    required this.frameworkLabel,
    this.modelLabel,
    required this.confidence,
  });

  final Uint8List imageBytes;
  final String familyLabel;
  final String title;
  final String subtitle;
  final String frameworkLabel;
  final String? modelLabel;
  final double? confidence;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(imageBytes, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (familyLabel.trim().isNotEmpty)
                    Text(
                      '${familyLabel.toUpperCase()} FAMILY',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryFixed,
                        letterSpacing: 2.8,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.white,
                      fontSize: 40,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 38),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _HeroChip(
                        icon: Icons.psychology,
                        label: frameworkLabel,
                        dark: true,
                      ),
                      _HeroChip(
                        icon: Icons.tune_rounded,
                        label: (modelLabel != null && modelLabel!.isNotEmpty)
                            ? _breakModelLabel(modelLabel!)
                            : 'Standard Model',
                        dark: true,
                      ),
                      _HeroChip(
                        icon: Icons.verified,
                        label: confidence == null
                            ? 'Unknown Confidence'
                            : '${(confidence! * 100).toStringAsFixed(1)}% Confidence',
                        dark: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _breakModelLabel(String value) {
  final text = value.trim();
  final firstSpace = text.indexOf(' ');
  if (firstSpace <= 0) return text;
  return '${text.substring(0, firstSpace)}\n${text.substring(firstSpace + 1)}';
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    required this.dark,
  });

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.1) : AppColors.primary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              softWrap: true,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD8A8)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF8A4B00))),
    );
  }
}

class _PlantSectionCard extends StatelessWidget {
  const _PlantSectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.source,
    this.accentColor,
    this.borderLeft,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? source;
  final Color? accentColor;
  final BorderSide? borderLeft;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
        border: borderLeft == null ? null : Border(left: borderLeft!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontSize: 24,
                  ),
                ),
              ),
              if ((source ?? '').trim().isNotEmpty)
                _SourceBadge(source: source!),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});

  final String source;

  String get _displaySource {
    final cleaned = source.trim();
    if (cleaned.isEmpty) return cleaned;
    return cleaned.split('_').first.trim();
  }

  @override
  Widget build(BuildContext context) {
    final label = _displaySource;
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.outlineSource,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EvidenceSafetyCard extends StatelessWidget {
  const _EvidenceSafetyCard({required this.plant});

  final PlantScanResult plant;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return _PlantSectionCard(
      title: t.t('plant_section_evidence'),
      icon: Icons.health_and_safety,
      source: plant.sourceForField('evidence_level'),
      accentColor: AppColors.error,
      borderLeft: const BorderSide(color: AppColors.error, width: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.t('plant_evidence_level_label'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (plant.evidenceLevel.trim().isEmpty)
            Text(
              t.t('plant_evidence_unknown'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plant.evidenceLevel
                  .split(';')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fact_check,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _prettyEnum(e),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 20),
          if (plant.toxicityWarning.trim().isNotEmpty)
            _DangerInfoCard(
              title: t.t('plant_toxicity_warning_title'),
              icon: Icons.warning,
              background: AppColors.errorContainer.withValues(alpha: 0.2),
              border: AppColors.errorContainer,
              titleColor: AppColors.error,
              content: plant.toxicityWarning,
            ),
          if (plant.toxicityWarning.trim().isNotEmpty)
            const SizedBox(height: 16),
          if (plant.safetyNotes.trim().isNotEmpty)
            _DangerInfoCard(
              title: t.t('plant_safety_notes_title'),
              icon: Icons.info,
              background: AppColors.surfaceContainer,
              border: Colors.transparent,
              titleColor: AppColors.primary,
              content: plant.safetyNotes,
              bullet: true,
            ),
        ],
      ),
    );
  }

  String _prettyEnum(String value) {
    return value
        .split(RegExp(r'[_\s]+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _DangerInfoCard extends StatelessWidget {
  const _DangerInfoCard({
    required this.title,
    required this.icon,
    required this.background,
    required this.border,
    required this.titleColor,
    required this.content,
    this.bullet = false,
  });

  final String title;
  final IconData icon;
  final Color background;
  final Color border;
  final Color titleColor;
  final String content;
  final bool bullet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: titleColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: titleColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (bullet)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _asBulletLines(content)
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(color: AppColors.onSurfaceVariant),
                          ),
                          Expanded(
                            child: Text(
                              line,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    height: 1.6,
                                    fontSize: 14,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.6,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  List<String> _asBulletLines(String raw) {
    final lines = raw
        .split(RegExp(r'\n|•|;'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return lines.isEmpty ? [raw.trim()] : lines;
  }
}

class _TechnicalMetadataCard extends StatelessWidget {
  const _TechnicalMetadataCard({
    required this.expanded,
    required this.title,
    required this.metadata,
    required this.onToggle,
  });

  final bool expanded;
  final String title;
  final String metadata;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.code, color: AppColors.outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.outline,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1C1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SelectableText(
                  metadata,
                  style: const TextStyle(
                    color: AppColors.primaryFixed,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaxonomyItem {
  const _TaxonomyItem({
    required this.label,
    required this.value,
    required this.source,
    this.italic = false,
  });

  final String label;
  final String value;
  final String source;
  final bool italic;
}

class _TaxonomyRow extends StatelessWidget {
  const _TaxonomyRow({required this.item});

  final _TaxonomyItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              if (item.source.trim().isNotEmpty)
                _SourceBadge(source: item.source),
            ],
          ),
          const SizedBox(height: 6),
          if (item.label ==
              AppLocalizations.of(context).t('plant_taxonomic_status_label'))
            _StatusTag(status: item.value)
          else
            Text(
              item.value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});
  final String status;

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF2E7D32); // Green
      case 'synonym':
        return const Color(0xFFF57C00); // Orange
      case 'ambiguous':
        return const Color(0xFF7B1FA2); // Purple
      case 'unmatched':
        return const Color(0xFFD32F2F); // Red
      case 'unknown':
      default:
        return const Color(0xFF616161); // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BenefitItem {
  const _BenefitItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.source,
  });

  final String title;
  final String description;
  final IconData icon;
  final String source;
}

class _UtilityBenefitsCard extends StatelessWidget {
  const _UtilityBenefitsCard({required this.items});

  final List<_BenefitItem> items;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: AppColors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.t('plant_section_utility'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < items.length; i++) ...[
            _BenefitTile(item: items[i]),
            if (i != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({required this.item});

  final _BenefitItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (item.source.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(210, 255, 255, 255),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.source.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: AppColors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: item.description
                      .split('\n')
                      .map((line) => line.trim())
                      .where((line) => line.isNotEmpty)
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Text(
                            line,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.5,
                                  fontSize: 13,
                                ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({
    required this.plant,
    required this.onOpenMap,
    required this.onOpenDetails,
  });

  final PlantScanResult plant;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasMap = plant.distributionPoints.isNotEmpty;
    final summary = plant.distributionAreas.isNotEmpty
        ? plant.distributionAreas.first
        : t.t('distribution_not_available');

    return _PlantSectionCard(
      title: t.t('plant_section_distribution'),
      icon: Icons.public,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 224,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpenMap,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasMap)
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: _centerPoint(
                              plant.distributionPoints,
                            ),
                            initialZoom: 2.8,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.bigplant.app',
                            ),
                            MarkerLayer(
                              markers: plant.distributionPoints
                                  .map(
                                    (point) => Marker(
                                      point: LatLng(point.lat, point.lng),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: AppColors.primary,
                                        size: 36,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        )
                      else
                        Container(color: AppColors.surfaceContainerHigh),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _DottedMapOverlayPainter(),
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onOpenDetails,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.format_list_bulleted),
            label: Text(t.t('distribution_view_details')),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onOpenMap,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainer,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 52),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(t.t('plant_view_interactive_map')),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LatLng _centerPoint(List<PlantDistributionPoint> points) {
    if (points.isEmpty) return const LatLng(16.0471, 108.2068);
    final latAvg =
        points.fold<double>(0, (sum, item) => sum + item.lat) / points.length;
    final lngAvg =
        points.fold<double>(0, (sum, item) => sum + item.lng) / points.length;
    return LatLng(latAvg, lngAvg);
  }
}

class _DottedMapOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary.withValues(alpha: 0.18);
    const spacing = 16.0;
    const radius = 1.5;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VoiceButton extends StatelessWidget {
  const _VoiceButton({required this.speaking, required this.onTap});

  final bool speaking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: FloatingActionButton(
        onPressed: onTap,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Icon(
          speaking ? Icons.stop_rounded : Icons.record_voice_over,
          size: 30,
        ),
      ),
    );
  }
}

class _DistributionListTile extends StatelessWidget {
  const _DistributionListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _DistributionMapScreen extends StatefulWidget {
  const _DistributionMapScreen({
    required this.title,
    required this.points,
    required this.areas,
    required this.onOpenDetails,
  });

  final String title;
  final List<PlantDistributionPoint> points;
  final List<String> areas;
  final Future<void> Function(BuildContext context) onOpenDetails;

  @override
  State<_DistributionMapScreen> createState() => _DistributionMapScreenState();
}

class _DistributionMapScreenState extends State<_DistributionMapScreen> {
  final MapController _mapController = MapController();

  LatLng get _center {
    if (widget.points.isEmpty) return const LatLng(16.0471, 108.2068);
    final latAvg =
        widget.points.fold<double>(0, (sum, item) => sum + item.lat) /
        widget.points.length;
    final lngAvg =
        widget.points.fold<double>(0, (sum, item) => sum + item.lng) /
        widget.points.length;
    return LatLng(latAvg, lngAvg);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locationCount = widget.points.isNotEmpty
        ? widget.points.length
        : widget.areas.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: _center, initialZoom: 4.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bigplant.app',
                ),
                MarkerLayer(
                  markers: widget.points
                      .map(
                        (point) => Marker(
                          point: LatLng(point.lat, point.lng),
                          width: 40,
                          height: 40,
                          child: Column(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surface,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  color: AppColors.surface.withValues(alpha: 0.8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontSize: 24,
                              ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 280,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.eco, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  t.t('distribution_ecology_title'),
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: AppColors.onSurface),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t
                                  .t('distribution_found_template')
                                  .replaceFirst('{count}', '$locationCount'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MapChip(label: t.t('distribution_biome_chip')),
                                _MapChip(
                                  label: t.t('distribution_humidity_chip'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => widget.onOpenDetails(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.format_list_bulleted),
                        label: Text(t.t('distribution_detail_button')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

class _ScanSuccessBanner extends StatelessWidget {
  const _ScanSuccessBanner({required this.visible, required this.plantName});

  final bool visible;
  final String plantName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -1.5),
        duration: const Duration(milliseconds: 420),
        curve: visible ? Curves.easeOutBack : Curves.easeInCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color.fromARGB(255, 30, 134, 85), Color(0xFF25A26A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF25A26A).withValues(alpha: 0.40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context).t('scan_success_title'),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plantName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      AppLocalizations.of(context).t('scan_success_badge'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
