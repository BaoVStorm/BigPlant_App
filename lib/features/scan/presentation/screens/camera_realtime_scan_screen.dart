import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/local_onnx_scan_service.dart';
import '../../domain/models/plant_scan_result.dart';
import '../../domain/scan_service.dart';
import 'scan_result_screen.dart';

class CameraRealtimeScanScreen extends StatefulWidget {
  const CameraRealtimeScanScreen({super.key});

  @override
  State<CameraRealtimeScanScreen> createState() =>
      _CameraRealtimeScanScreenState();
}

class _CameraRealtimeScanScreenState extends State<CameraRealtimeScanScreen> {
  final LocalOnnxScanService _localService = LocalOnnxScanService.instance;
  final ScanService _scanService = ScanService();
  final ImagePicker _imagePicker = ImagePicker();
  static const String _preferredRealtimeModelId = 'mobilenetv3large_segformer';

  CameraController? _controller;
  List<String> _modelIds = const [];
  String? _selectedModelId;

  bool _loading = true;
  bool _inferBusy = false;
  bool _isScanningEnabled = false;
  bool _isFlashEnabled = false;
  bool _showCaptureReview = false;
  String? _error;
  LocalInferenceResult? _latestResult;
  Uint8List? _latestFrameJpeg;
  Uint8List? _capturedFrameJpeg;
  LocalInferenceResult? _capturedResult;

  DateTime _lastInferAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _consecutiveInferFailures = 0;
  String? _lastInferError;
  int _lastInferLatencyMs = 0;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initAll() async {
    try {
      final ids = await _localService.availableRealtimeModelIds();
      final selected = await _localService.getSelectedModelId();

      final cameras = await availableCameras();
      final back = cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();
      final camera = (back.isNotEmpty ? back.first : cameras.first);

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      await controller.startImageStream(_onFrame);
      if (!mounted) return;

      setState(() {
        _modelIds = ids;
        _selectedModelId = _pickInitialModelId(ids, selected);
        _controller = controller;
        _loading = false;
        _isScanningEnabled = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onFrame(CameraImage cameraImage) async {
    if (!mounted ||
        !_isScanningEnabled ||
        _inferBusy ||
        _selectedModelId == null ||
        _showCaptureReview) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastInferAt).inMilliseconds < 500) return;

    _inferBusy = true;
    _lastInferAt = now;
    final sw = Stopwatch()..start();
    try {
      final converted = _convertCameraImage(cameraImage);
      if (converted == null) {
        _setInferError(
          'Unsupported camera format: ${cameraImage.format.group.name} (planes=${cameraImage.planes.length})',
        );
        return;
      }
      _latestFrameJpeg = Uint8List.fromList(
        img.encodeJpg(converted, quality: 85),
      );

      final result = await _localService.inferImage(
        converted,
        modelId: _selectedModelId,
        topK: 5,
      );
      if (!mounted) return;
      setState(() {
        _latestResult = result;
        _lastInferError = null;
        _lastInferLatencyMs = sw.elapsedMilliseconds;
      });
      _consecutiveInferFailures = 0;
    } catch (e, st) {
      debugPrint('Local realtime inference failed: $e');
      debugPrint('$st');
      _setInferError(e.toString());
      await _fallbackToPreferredModelIfNeeded();
    } finally {
      _inferBusy = false;
    }
  }

  img.Image? _convertCameraImage(CameraImage image) {
    if (image.format.group == ImageFormatGroup.bgra8888) {
      return _convertBgra8888(image);
    }
    if (image.format.group == ImageFormatGroup.nv21) {
      return _convertNv21(image);
    }
    if (image.format.group == ImageFormatGroup.yuv420) {
      return _convertYuv420(image);
    }
    return null;
  }

  img.Image _convertBgra8888(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final output = img.Image(width: width, height: height);
    final bytes = image.planes[0].bytes;
    var offset = 0;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final b = bytes[offset];
        final g = bytes[offset + 1];
        final r = bytes[offset + 2];
        output.setPixelRgba(x, y, r, g, b, 255);
        offset += 4;
      }
    }
    return output;
  }

  img.Image _convertYuv420(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final output = img.Image(width: width, height: height);

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (var y = 0; y < height; y++) {
      final yRow = y * yRowStride;
      final uvRow = (y >> 1) * uvRowStride;

      for (var x = 0; x < width; x++) {
        final yValue = yBytes[yRow + x];
        final uvOffset = uvRow + (x >> 1) * uvPixelStride;
        final uValue = uBytes[uvOffset];
        final vValue = vBytes[uvOffset];

        final r = (yValue + 1.402 * (vValue - 128)).round();
        final g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .round();
        final b = (yValue + 1.772 * (uValue - 128)).round();

        output.setPixelRgba(
          x,
          y,
          _clamp8(r),
          _clamp8(g),
          _clamp8(b),
          255,
        );
      }
    }

    return output;
  }

  img.Image? _convertNv21(CameraImage image) {
    if (image.planes.isEmpty) return null;
    final width = image.width;
    final height = image.height;
    final yuvBytes = image.planes[0].bytes;
    final frameSize = width * height;
    if (yuvBytes.length < frameSize) return null;

    final output = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      final yOffset = y * width;
      final uvRowOffset = frameSize + (y >> 1) * width;
      for (var x = 0; x < width; x++) {
        final yValue = yuvBytes[yOffset + x];
        final uvIndex = uvRowOffset + (x & ~1);
        if (uvIndex + 1 >= yuvBytes.length) continue;
        final vValue = yuvBytes[uvIndex];
        final uValue = yuvBytes[uvIndex + 1];

        final r = (yValue + 1.402 * (vValue - 128)).round();
        final g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .round();
        final b = (yValue + 1.772 * (uValue - 128)).round();

        output.setPixelRgba(
          x,
          y,
          _clamp8(r),
          _clamp8(g),
          _clamp8(b),
          255,
        );
      }
    }
    return output;
  }

  int _clamp8(int value) => math.min(255, math.max(0, value));

  String? _pickInitialModelId(List<String> ids, String selected) {
    if (ids.isEmpty) return null;
    if (ids.contains(selected)) return selected;
    if (ids.contains(_preferredRealtimeModelId)) return _preferredRealtimeModelId;
    return ids.first;
  }

  void _setInferError(String message) {
    _consecutiveInferFailures++;
    if (!mounted) return;
    setState(() {
      _lastInferError = message;
    });
  }

  Future<void> _fallbackToPreferredModelIfNeeded() async {
    if (_consecutiveInferFailures < 3) return;
    if (_selectedModelId == _preferredRealtimeModelId) return;
    if (!_modelIds.contains(_preferredRealtimeModelId)) return;

    await _localService.setSelectedModelId(_preferredRealtimeModelId);
    if (!mounted) return;
    setState(() {
      _selectedModelId = _preferredRealtimeModelId;
      _latestResult = null;
      _lastInferError =
          'Auto switched to $_preferredRealtimeModelId after repeated failures';
    });
    _consecutiveInferFailures = 0;
  }

  Future<void> _changeModel(String modelId) async {
    await _localService.setSelectedModelId(modelId);
    if (!mounted) return;
    setState(() {
      _selectedModelId = modelId;
      _latestResult = null;
    });
  }

  Future<void> _toggleFlashMode() async {
    final controller = _controller;
    if (controller == null) return;
    final enabled = !_isFlashEnabled;
    try {
      await controller.setFlashMode(enabled ? FlashMode.torch : FlashMode.off);
      if (!mounted) return;
      setState(() => _isFlashEnabled = enabled);
    } catch (_) {
      if (!mounted) return;
      AppToast.showError(
        context,
        'Flash is unavailable on this device.',
      );
    }
  }

  Future<void> _openGalleryFromCamera() async {
    if (_loading) return;
    _pauseScanning();

    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final result = await _scanService.scanPlant(
        imageBytes: bytes,
        fileName: file.name.isEmpty ? 'plant_scan.jpg' : file.name,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(
            imageBytes: bytes,
            result: result,
            inferenceFramework: 'TensorRT',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(
        context,
        e.toString(),
      );
    } finally {
      _resumeScanning();
    }
  }

  Future<void> _captureCurrentFrame() async {
    final jpeg = _latestFrameJpeg;
    final result = _latestResult;
    if (jpeg == null || result == null) {
      if (!mounted) return;
      AppToast.showError(
        context,
        'No stable plant prediction yet.',
      );
      return;
    }

    _pauseScanning();
    setState(() {
      _capturedFrameJpeg = jpeg;
      _capturedResult = result;
      _showCaptureReview = true;
    });
  }

  Future<void> _openFullAnalysis() async {
    final prediction = _capturedResult;
    final jpeg = _capturedFrameJpeg;
    if (prediction == null || jpeg == null) return;

    const detailFetchFileName = 'camera_realtime.jpg';
    final topkText = prediction.topPredictions
        .map(
          (item) =>
              '${item.classIndex}: ${item.label} (${(item.confidence * 100).toStringAsFixed(1)}%)',
        )
        .join('\n');

    final result = PlantScanResult(
      displayName: prediction.label,
      scientificName: prediction.label,
      scientificNameSearch: '',
      commonName: '',
      family: '',
      order: '',
      genus: '',
      species: '',
      taxonomicStatus: '',
      uses: '',
      advantages: '',
      description: '',
      toxicityWarning: '',
      safetyNotes: '',
      evidenceLevel: '',
      confidence: prediction.confidence,
      modelName: prediction.modelDisplayName,
      backend: 'ONNX Runtime',
      distributionAreas: const [],
      distributionPoints: const [],
      note: 'Local ONNX model: ${prediction.modelDisplayName}\nTop-5:\n$topkText',
    );

    await Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ScanResultScreen(
              imageBytes: jpeg,
              result: result,
              fetchDetailsFromApi: true,
              detailFetchFileName: detailFetchFileName,
              plantLabel: prediction.label,
              inferenceFramework: 'ONNX Runtime',
            ),
          ),
        )
        .whenComplete(() {
          if (!mounted) return;
          setState(() {
            _showCaptureReview = false;
            _capturedFrameJpeg = null;
            _capturedResult = null;
          });
          _resumeScanning();
        });
  }

  void _handleClose() {
    if (_showCaptureReview) {
      setState(() {
        _showCaptureReview = false;
        _capturedFrameJpeg = null;
        _capturedResult = null;
      });
      _resumeScanning();
      return;
    }
    Navigator.of(context).pop();
  }

  void _pauseScanning() {
    if (!mounted) return;
    setState(() {
      _isScanningEnabled = false;
    });
  }

  void _resumeScanning() {
    if (!mounted) return;
    setState(() {
      _isScanningEnabled = true;
      _lastInferError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.white),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _showCaptureReview
                  ? _buildCompleteState(context, t)
                  : _buildPendingState(context, t),
    );
  }

  Widget _buildPendingState(BuildContext context, AppLocalizations t) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: Text(
          t.t('scan_camera_init_failed'),
          style: const TextStyle(color: AppColors.white),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: CameraPreview(controller)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.12),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.28),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GlassCircleButton(
                      icon: Icons.close,
                      onTap: _handleClose,
                    ),
                    _ModelSelectorPill(
                      label: _multilineFriendlyModelLabel(_selectedModelId),
                      onTap: _showModelPicker,
                    ),
                  ],
                ),
                const Spacer(),
                _TargetFrame(),
                const Spacer(),
                _CompactPredictionCard(
                  title: _latestResult == null
                      ? t.t('scan_pending_prediction_title')
                      : _formatPlantLabel(_latestResult!.label),
                  subtitle: _latestResult == null
                      ? t.t('scan_pending_prediction_subtitle')
                      : t.t('scan_pending_prediction_ready'),
                  confidenceText: _latestResult == null
                      ? null
                      : '${(_latestResult!.confidence * 100).toStringAsFixed(0)}%',
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GlassCircleButton(
                      icon: Icons.photo_library,
                      onTap: _openGalleryFromCamera,
                    ),
                    const SizedBox(width: 24),
                    _CaptureButton(onTap: _captureCurrentFrame),
                    const SizedBox(width: 24),
                    _GlassCircleButton(
                      icon: _isFlashEnabled ? Icons.flash_on : Icons.flash_off,
                      onTap: _toggleFlashMode,
                    ),
                  ],
                ),
                if (_lastInferError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _lastInferError!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteState(BuildContext context, AppLocalizations t) {
    final captured = _capturedFrameJpeg;
    final prediction = _capturedResult;
    if (captured == null || prediction == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(captured, fit: BoxFit.cover),
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.1)),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Align(
              alignment: Alignment.topLeft,
              child: _GlassCircleButton(icon: Icons.close, onTap: _handleClose),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 4),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ),
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) {
            return FractionalTranslation(
              translation: offset,
              child: child,
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  t.t('scan_analysis_complete_title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.t('scan_analysis_complete_subtitle'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                _CaptureSummaryCard(
                  icon: Icons.timer,
                  label: t.t('scan_latency_label'),
                  value: '$_lastInferLatencyMs ms',
                ),
                const SizedBox(height: 16),
                _CaptureSummaryCard(
                  icon: Icons.memory,
                  label: t.t('scan_identified_plant_label'),
                  value: _formatPlantLabel(prediction.label),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _openFullAnalysis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.t('scan_open_full_analysis')),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ],
    );
  }

  void _showModelPicker() {
    if (_modelIds.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Choose model',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize:
                        (Theme.of(context).textTheme.titleMedium?.fontSize ?? 18) -
                        2,
                  ),
                ),
                const SizedBox(height: 14),
                ..._modelIds.map(
                  (id) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ModelPickerTile(
                      title: _friendlyModelLabel(id),
                      subtitle: id,
                      selected: _selectedModelId == id,
                      onTap: () {
                        Navigator.of(context).pop();
                        _changeModel(id);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _friendlyModelLabel(String? modelId) {
    if (modelId == null || modelId.trim().isEmpty) {
      return 'Botanical-V2';
    }

    const aliases = {
      'mobilenetv3large': 'MobileNetV3-Large',
      'resnet50': 'ResNet50',
      'deeplabv3': 'DeepLabV3',
      'mask2former': 'Mask2Former',
      'segformer': 'SegFormer',
      'b4': 'B4',
    };

    return modelId
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) {
          final alias = aliases[part.toLowerCase()];
          if (alias != null) return alias;
          if (RegExp(r'^\d+$').hasMatch(part)) return part;
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join(' ');
  }

  String _multilineFriendlyModelLabel(String? modelId) {
    final label = _friendlyModelLabel(modelId);
    final firstSpace = label.indexOf(' ');
    if (firstSpace <= 0) return label;
    return '${label.substring(0, firstSpace)}\n${label.substring(firstSpace + 1)}';
  }

  static String _formatPlantLabel(String raw) {
    return raw
        .split('_')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.7),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _ModelSelectorPill extends StatelessWidget {
  const _ModelSelectorPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.psychology, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  softWrap: true,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.expand_more,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelPickerTile extends StatelessWidget {
  const _ModelPickerTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? AppColors.secondaryContainer.withValues(alpha: 0.55)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.psychology_alt_rounded,
                  color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize:
                            (theme.textTheme.titleMedium?.fontSize ?? 18) - 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.outlineVariant,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, size: 16, color: AppColors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  children: [
                    const _FrameCorner(alignment: Alignment.topLeft),
                    const _FrameCorner(alignment: Alignment.topRight),
                    const _FrameCorner(alignment: Alignment.bottomLeft),
                    const _FrameCorner(alignment: Alignment.bottomRight),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
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
}

class _FrameCorner extends StatelessWidget {
  const _FrameCorner({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final top = alignment.y < 0;
    final left = alignment.x < 0;

    return Align(
      alignment: alignment,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(8) : Radius.zero,
            topRight: top && !left ? const Radius.circular(8) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(8) : Radius.zero,
            bottomRight: !top && !left ? const Radius.circular(8) : Radius.zero,
          ),
          border: Border(
            top: top
                ? BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 2)
                : BorderSide.none,
            bottom: !top
                ? BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 2)
                : BorderSide.none,
            left: left
                ? BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 2)
                : BorderSide.none,
            right: !left
                ? BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 2)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _CompactPredictionCard extends StatelessWidget {
  const _CompactPredictionCard({
    required this.title,
    required this.subtitle,
    required this.confidenceText,
  });

  final String title;
  final String subtitle;
  final String? confidenceText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          if (confidenceText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondaryFixed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    confidenceText!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
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

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 4),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(
            Icons.center_focus_strong,
            color: AppColors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _CaptureSummaryCard extends StatelessWidget {
  const _CaptureSummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}
