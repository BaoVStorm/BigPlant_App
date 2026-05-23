import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

import '../../auth/data/storage_service.dart';
import 'models/local_model_catalog.dart';

class LocalOnnxScanService {
  LocalOnnxScanService._();

  static final LocalOnnxScanService instance = LocalOnnxScanService._();

  static const String _catalogAsset = 'assets/ml/configs/model_catalog.json';

  LocalModelCatalog? _catalog;
  final Map<String, _LoadedModel> _loadedModels = {};

  Future<LocalModelCatalog> loadCatalog() async {
    if (_catalog != null) return _catalog!;
    final content = _stripBom(await rootBundle.loadString(_catalogAsset));
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw Exception('Invalid model catalog format');
    }
    final normalized = decoded.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    _catalog = LocalModelCatalog.fromJson(normalized);
    return _catalog!;
  }

  Future<List<String>> availableRealtimeModelIds() async {
    final catalog = await loadCatalog();
    return catalog.models.entries
        .where((entry) => entry.value.supportsCameraRealtime)
        .map((entry) => entry.key)
        .toList();
  }

  Future<String> getSelectedModelId() async {
    final catalog = await loadCatalog();
    final saved = await StorageService.getScanLocalModel();
    if (saved != null && catalog.models.containsKey(saved)) {
      return saved;
    }
    return catalog.defaultModel;
  }

  Future<void> setSelectedModelId(String modelId) async {
    final catalog = await loadCatalog();
    if (!catalog.models.containsKey(modelId)) {
      throw Exception('Unknown model id: $modelId');
    }
    await StorageService.setScanLocalModel(modelId);
  }

  Future<List<String>> getLabels(String modelId) async {
    final model = await _loadModel(modelId);
    return model.labels;
  }

  Future<void> preloadModel(String modelId) async {
    await _loadModel(modelId);
  }

  bool isModelLoaded(String modelId) {
    return _loadedModels.containsKey(modelId);
  }

  void evictModel(String modelId) {
    final loaded = _loadedModels.remove(modelId);
    loaded?.session.release();
  }

  void clearLoadedModels() {
    final loadedModels = _loadedModels.values.toList();
    _loadedModels.clear();
    for (final loaded in loadedModels) {
      loaded.session.release();
    }
  }

  Future<LocalInferenceResult> inferJpegBytes(
    Uint8List jpegBytes, {
    String? modelId,
    int topK = 5,
  }) async {
    final decoded = img.decodeImage(jpegBytes);
    if (decoded == null) {
      throw Exception('Failed to decode image bytes for local inference');
    }
    return inferImage(decoded, modelId: modelId, topK: topK);
  }

  Future<LocalInferenceResult> inferImage(
    img.Image image, {
    String? modelId,
    int topK = 5,
  }) async {
    final selectedId = modelId ?? await getSelectedModelId();
    final model = await _loadModel(selectedId);
    final input = _preprocessImage(image, model.config);

    final inputTensor = OrtValueTensor.createTensorWithDataList(
      input,
      [1, 3, model.config.imageSize, model.config.imageSize],
    );

    final inputs = <String, OrtValue>{
      model.config.inputNames.first: inputTensor,
    };
    OrtValueTensor? organTensor;
    if (model.config.requiresOrganPrior) {
      final organSize = model.config.organPriorSize;
      final organPrior = Float32List.fromList(
        List<double>.filled(organSize, 1 / organSize),
      );
      organTensor = OrtValueTensor.createTensorWithDataList(
        organPrior,
        [1, organSize],
      );
      final organName = model.config.inputNames.firstWhere(
        (name) => name == 'organ_prior',
        orElse: () => model.config.inputNames.length > 1
            ? model.config.inputNames[1]
            : 'organ_prior',
      );
      inputs[organName] = organTensor;
    }

    final runOptions = OrtRunOptions();
    List<OrtValue?> outputs = const [];
    try {
      outputs = model.session.run(runOptions, inputs);
    } finally {
      inputTensor.release();
      organTensor?.release();
      runOptions.release();
    }

    if (outputs.isEmpty) {
      throw Exception('No output returned from ONNX runtime');
    }

    final firstOutput = outputs.first;
    if (firstOutput == null) {
      _releaseOutputs(outputs);
      throw Exception('Invalid ONNX output tensor');
    }

    final logits = _flattenNumbers(firstOutput.value);
    _releaseOutputs(outputs);
    if (logits.isEmpty) {
      throw Exception('Unable to parse model logits');
    }

    final probs = _softmax(logits);
    final ranked = List<int>.generate(probs.length, (index) => index)
      ..sort((a, b) => probs[b].compareTo(probs[a]));

    final effectiveTopK = math.min(math.max(topK, 1), probs.length);
    final topPredictions = ranked.take(effectiveTopK).map((index) {
      final label = index < model.labels.length ? model.labels[index] : 'Unknown';
      return LocalTopPrediction(
        classIndex: index,
        label: label,
        confidence: probs[index],
      );
    }).toList();

    final best = topPredictions.first;
    return LocalInferenceResult(
      modelId: selectedId,
      classIndex: best.classIndex,
      label: best.label,
      confidence: best.confidence,
      topPredictions: topPredictions,
    );
  }

  Future<_LoadedModel> _loadModel(String modelId) async {
    final cached = _loadedModels[modelId];
    if (cached != null) return cached;

    final catalog = await loadCatalog();
    final entry = catalog.models[modelId];
    if (entry == null) {
      throw Exception('Missing model entry in catalog: $modelId');
    }

    final configRaw = _stripBom(await rootBundle.loadString(entry.configPath));
    final labelsRaw = _stripBom(await rootBundle.loadString(entry.labelsPath));
    final modelBytes = await rootBundle.load(entry.onnxPath);

    final configDecoded = jsonDecode(configRaw);
    final labelsDecoded = jsonDecode(labelsRaw);
    if (configDecoded is! Map || labelsDecoded is! Map) {
      throw Exception('Invalid model assets for $modelId');
    }

    final config = LocalModelConfig.fromJson(
      configDecoded.map((key, value) => MapEntry(key.toString(), value)),
    );
    final labels = _parseLabels(labelsDecoded);

    OrtEnv.instance.init();
    final sessionOptions = OrtSessionOptions();
    sessionOptions.setInterOpNumThreads(1);
    sessionOptions.setIntraOpNumThreads(1);
    final modelBuffer = modelBytes.buffer.asUint8List(
      modelBytes.offsetInBytes,
      modelBytes.lengthInBytes,
    );
    final session = OrtSession.fromBuffer(modelBuffer, sessionOptions);
    sessionOptions.release();

    final loaded = _LoadedModel(config: config, labels: labels, session: session);
    _loadedModels[modelId] = loaded;
    return loaded;
  }

  List<String> _parseLabels(Map<dynamic, dynamic> json) {
    final labels = json['labels'];
    if (labels is! List) return const [];
    return labels.map((item) => item.toString()).toList();
  }

  String _stripBom(String content) {
    if (content.startsWith('\uFEFF')) {
      return content.substring(1);
    }
    return content;
  }

  Float32List _preprocessImage(img.Image input, LocalModelConfig config) {
    final resized = img.copyResize(
      input,
      width: config.imageSize,
      height: config.imageSize,
      interpolation: img.Interpolation.average,
    );

    final output = Float32List(config.imageSize * config.imageSize * 3);
    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];
    final normalize = config.preprocessMode == 'imagenet_norm';

    var offset = 0;
    final channelPlane = config.imageSize * config.imageSize;
    for (var y = 0; y < config.imageSize; y++) {
      for (var x = 0; x < config.imageSize; x++) {
        final pixel = resized.getPixel(x, y);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;

        output[offset] = normalize ? (r - mean[0]) / std[0] : r;
        output[offset + channelPlane] = normalize ? (g - mean[1]) / std[1] : g;
        output[offset + (2 * channelPlane)] = normalize ? (b - mean[2]) / std[2] : b;
        offset++;
      }
    }
    return output;
  }

  List<double> _flattenNumbers(dynamic raw) {
    if (raw is num) {
      return [raw.toDouble()];
    }
    if (raw is List) {
      final out = <double>[];
      for (final item in raw) {
        out.addAll(_flattenNumbers(item));
      }
      return out;
    }
    return const [];
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((value) => math.exp(value - maxLogit)).toList();
    final sum = exps.fold<double>(0, (acc, value) => acc + value);
    if (sum == 0) {
      return List<double>.filled(logits.length, 0);
    }
    return exps.map((value) => value / sum).toList();
  }

  void _releaseOutputs(List<OrtValue?> outputs) {
    for (final output in outputs) {
      output?.release();
    }
  }
}

class LocalInferenceResult {
  const LocalInferenceResult({
    required this.modelId,
    required this.classIndex,
    required this.label,
    required this.confidence,
    required this.topPredictions,
  });

  final String modelId;
  final int classIndex;
  final String label;
  final double confidence;
  final List<LocalTopPrediction> topPredictions;
}

class LocalTopPrediction {
  const LocalTopPrediction({
    required this.classIndex,
    required this.label,
    required this.confidence,
  });

  final int classIndex;
  final String label;
  final double confidence;
}

class _LoadedModel {
  const _LoadedModel({
    required this.config,
    required this.labels,
    required this.session,
  });

  final LocalModelConfig config;
  final List<String> labels;
  final OrtSession session;
}
