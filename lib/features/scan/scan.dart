import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/features/scan/hasilscan.dart';

class ScanPage extends StatefulWidget {
  final VoidCallback? onBack;
  final ValueListenable<int>? activeIndexListenable;
  final int tabIndex;

  const ScanPage({
    super.key,
    this.onBack,
    this.activeIndexListenable,
    this.tabIndex = 2,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  // Gunakan variabel ini agar semua elemen merujuk pada ukuran yang sama
  final double scanBoxSize = 280.0;
  final double verticalOffset =
      -60.0; // Menggeser titik fokus sedikit ke atas tengah

  CameraController? _cameraController;
  CameraLensDirection _activeLens = CameraLensDirection.back;
  bool _isFrontCamera = false;
  String? _cameraError;
  bool _cameraInitScheduled = false;
  bool _isActive = true;
  VoidCallback? _activeIndexListener;
  int _cameraInitToken = 0;

  final ImagePicker _imagePicker = ImagePicker();
  bool _scanning = false;
  Map<String, dynamic>? _ingredient;
  String? _scanError;
  String? _lastCapturedPath;
  bool _freezePreview = false;
  bool _showResultsSheet = false;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final listenable = widget.activeIndexListenable;
    if (listenable != null) {
      _isActive = listenable.value == widget.tabIndex;
      _activeIndexListener = () {
        final nowActive = listenable.value == widget.tabIndex;
        if (nowActive == _isActive) return;
        setState(() {
          _isActive = nowActive;
        });

        if (nowActive) {
          _initCamera(preferLens: _activeLens);
        } else {
          _disposeCamera(invalidate: true);
        }
      };
      listenable.addListener(_activeIndexListener!);
    }

    if (_isActive) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final listenable = widget.activeIndexListenable;
    if (listenable != null && _activeIndexListener != null) {
      listenable.removeListener(_activeIndexListener!);
    }
    _cameraController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isActive) return;
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // Setelah permission dialog / background, jangan "nyangkut" di error.
        if (_cameraController == null) _initCamera(preferLens: _activeLens);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _disposeCamera(invalidate: true);
        break;
    }
  }

  Future<void> _disposeCamera({required bool invalidate}) async {
    if (invalidate) _cameraInitToken++;
    final c = _cameraController;
    if (c == null) return;
    _cameraController = null;
    try {
      await c.dispose();
    } catch (_) {
      // ignore
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _initCamera({CameraLensDirection? preferLens}) async {
    final int token = ++_cameraInitToken;
    try {
      setState(() {
        _cameraError = null;
      });

      final cams = await availableCameras();
      if (!mounted) return;
      if (!_isActive || token != _cameraInitToken) return;

      if (cams.isEmpty) {
        setState(() {
          _cameraError = 'Kamera tidak ditemukan di perangkat ini.';
        });
        return;
      }

      final desiredLens = preferLens ?? _activeLens;
      final CameraDescription chosen = cams.firstWhere(
        (c) => c.lensDirection == desiredLens,
        orElse: () => cams.first,
      );

      // Dispose previous controller without invalidating this init attempt.
      await _disposeCamera(invalidate: false);
      if (!mounted) return;
      if (!_isActive || token != _cameraInitToken) return;

      final next = CameraController(
        chosen,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Penting untuk Android CameraX terbaru:
      // mount CameraPreview (AndroidView) dulu supaya SurfaceProducer siap.
      setState(() {
        _cameraController = next;
        _activeLens = chosen.lensDirection;
        _isFrontCamera = _activeLens == CameraLensDirection.front;
      });

      // Yield 1 frame agar CameraPreview sempat dibuat.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      if (!_isActive || token != _cameraInitToken) {
        await next.dispose();
        return;
      }

      await next.initialize().timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (!_isActive || token != _cameraInitToken) {
        await next.dispose();
        return;
      }

      // Restore flash mode if possible.
      try {
        await next.setFlashMode(_flashMode);
      } catch (_) {
        _flashMode = FlashMode.off;
        try {
          await next.setFlashMode(FlashMode.off);
        } catch (_) {
          // ignore
        }
        if (mounted) setState(() {});
      }

      // Lens-like: keep camera on auto focus/exposure when available.
      try {
        await next.setFocusMode(FocusMode.auto);
      } catch (_) {
        // ignore
      }
      try {
        await next.setExposureMode(ExposureMode.auto);
      } catch (_) {
        // ignore
      }

      if (!mounted) {
        await next.dispose();
        return;
      }
    } catch (e) {
      if (!mounted) return;
      try {
        await _cameraController?.dispose();
      } catch (_) {
        // ignore
      }
      _cameraController = null;
      setState(() {
        if (e is CameraException) {
          final detail = <String>[
            if (e.code.isNotEmpty) e.code,
            if ((e.description ?? '').trim().isNotEmpty) e.description!.trim(),
          ].join('\n');
          _cameraError = detail.isEmpty
              ? 'Kamera tidak dapat dibuka. Cek izin kamera.'
              : detail;
        } else if (e is TimeoutException) {
          _cameraError = 'Kamera terlalu lama merespons. Coba buka ulang Scan.';
        } else {
          _cameraError = 'Kamera tidak dapat dibuka. Cek izin kamera.';
        }
      });
    }
  }

  void _ensureCameraReady() {
    if (!_isActive) return;
    if (_cameraController != null) return;
    if (_cameraError != null) return;
    if (_cameraInitScheduled) return;
    _cameraInitScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cameraInitScheduled = false;
      if (_cameraController != null || _cameraError != null) return;
      _initCamera();
    });
  }

  static String _asString(dynamic v) => (v ?? '').toString();

  static double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  static String _upperName(Map<String, dynamic>? ingredient) {
    final name = _asString(ingredient?['name']).trim();
    if (name.isEmpty) return '-';
    return name.toUpperCase();
  }

  static double _levelToProgress(String level) {
    final l = level.toLowerCase();
    if (l.contains('tinggi')) return 0.9;
    if (l.contains('sedang') || l.contains('cukup')) return 0.6;
    if (l.contains('rendah')) return 0.3;
    return 0.0;
  }

  Future<void> _scanIngredientImage(XFile file) async {
    setState(() {
      _scanning = true;
      _scanError = null;
      _ingredient = null;
      _showResultsSheet = true;
    });

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      final String filename = file.path.split(Platform.pathSeparator).last;
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: filename),
      });

      final resp = await dio.post(
        'https://tumbuh-production.up.railway.app/ingredients/scan',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = resp.data;
      if (data is Map && data['data'] is Map) {
        final ing = Map<String, dynamic>.from(data['data'] as Map);
        if (!mounted) return;
        setState(() {
          _ingredient = ing;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _scanError = 'Format respons tidak dikenali.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanError = 'Gagal memindai gambar. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _scanning = false;
        });
      }
    }
  }

  Future<void> _pickAndScan(ImageSource source) async {
    if (_scanning) return;

    final XFile? picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (!mounted) return;
    if (picked == null) return;

    setState(() {
      _lastCapturedPath = picked.path;
      _freezePreview = true;
      _showResultsSheet = true;
    });

    // Lens-like: keep frozen frame until user captures again.
    await _scanIngredientImage(picked);
  }

  Future<void> _captureAndScanInApp() async {
    if (_scanning) return;
    if (!_isActive) return;
    final c = _cameraController;
    if (c == null || !c.value.isInitialized) {
      setState(() {
        _scanError = 'Kamera belum siap.';
      });
      return;
    }

    try {
      // Jika sedang menampilkan freeze frame, hidupkan lagi preview sebentar
      // agar user bisa ambil foto baru (retake) seperti Google Lens.
      if (_freezePreview) {
        setState(() {
          _freezePreview = false;
        });
        try {
          await c.resumePreview();
          await Future<void>.delayed(const Duration(milliseconds: 120));
        } catch (_) {
          // ignore
        }
      }

      final XFile file = await c.takePicture();
      if (!mounted) return;
      setState(() {
        _lastCapturedPath = file.path;
        _freezePreview = true;
        _showResultsSheet = true;
      });
      await _scanIngredientImage(file);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanError = 'Gagal mengambil gambar. Coba lagi.';
      });
    }
  }

  Future<void> _toggleCameraDirection() async {
    if (!mounted) return;
    if (!_isActive) return;
    if (_scanning) return;
    final nextLens = _isFrontCamera
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    await _initCamera(preferLens: nextLens);
  }

  IconData _flashIconFor(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.torch:
        return Icons.flash_on;
      case FlashMode.off:
      default:
        return Icons.flash_off;
    }
  }

  Future<void> _cycleFlashMode() async {
    if (!mounted) return;
    if (!_isActive) return;
    if (_scanning) return;
    final c = _cameraController;
    if (c == null || !c.value.isInitialized) return;

    FlashMode next;
    switch (_flashMode) {
      case FlashMode.off:
        next = FlashMode.auto;
        break;
      case FlashMode.auto:
        next = FlashMode.torch;
        break;
      case FlashMode.torch:
        next = FlashMode.off;
        break;
      default:
        next = FlashMode.off;
    }

    try {
      await c.setFlashMode(next);
      if (!mounted) return;
      setState(() {
        _flashMode = next;
      });
    } catch (_) {
      // Device/lens may not support flash (e.g., front camera). Keep silent.
      if (!mounted) return;
      setState(() {
        _flashMode = FlashMode.off;
      });
    }
  }

  Future<void> _handleBack() async {
    if (_showResultsSheet) {
      _closeResultsToCamera();
      return;
    }

    await _disposeCamera(invalidate: true);

    if (!mounted) return;

    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }

    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  void _closeResultsToCamera() {
    if (!mounted) return;
    setState(() {
      _showResultsSheet = false;
      _freezePreview = false;
      _ingredient = null;
      _scanError = null;
    });

    final c = _cameraController;
    if (c != null && c.value.isInitialized) {
      // Best-effort resume; safe if already running.
      c.resumePreview().catchError((_) {});
    }
  }

  Widget _cameraErrorView(Object error) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off, color: Colors.white, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Kamera tidak dapat dibuka',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pastikan izin kamera sudah diizinkan di pengaturan perangkat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraView() {
    if (!_isActive) {
      return Container(color: Colors.black);
    }

    if (_freezePreview && _lastCapturedPath != null) {
      return Image.file(
        File(_lastCapturedPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          final c = _cameraController;
          if (c != null && c.value.isInitialized) return CameraPreview(c);
          return Container(color: Colors.black);
        },
      );
    }

    if (_cameraError != null) {
      return _cameraErrorView(_cameraError!);
    }

    final c = _cameraController;
    if (c == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Rebuild when controller state changes (initialized/error), so loading
    // indicator doesn't get stuck until user presses a button.
    return ValueListenableBuilder<CameraValue>(
      valueListenable: c,
      builder: (context, value, child) {
        if (value.hasError) {
          return _cameraErrorView(value.errorDescription ?? 'Kamera error');
        }

        // Make preview fill the whole screen (Lens-like), avoid black bars.
        Widget preview = child!;
        final previewSize = value.previewSize;
        if (value.isInitialized && previewSize != null) {
          preview = ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                // previewSize is landscape; swap in portrait so it covers.
                width: previewSize.height,
                height: previewSize.width,
                child: preview,
              ),
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            preview,
            if (!value.isInitialized)
              const Center(child: CircularProgressIndicator()),
          ],
        );
      },
      child: CameraPreview(c),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureCameraReady();

    final ing = _ingredient;
    final String nameUpper = _upperName(ing);
    final double confidence = _asDouble(ing?['confidence']);
    final String tooltipText = _scanning
        ? 'Memindai...'
        : ing == null
        ? 'Arahkan kamera ke bahan'
        : '$nameUpper cocok ${(confidence <= 0 ? 0 : (confidence * 100)).clamp(0, 100).toStringAsFixed(0)}%';

    final String calorieLevel = _asString(ing?['calorieLevel']).trim();
    final String proteinLevel = _asString(ing?['proteinLevel']).trim();
    final String vitaminLevel = _asString(ing?['vitaminLevel']).trim();

    final String imageUrl = _asString(ing?['imageUrl']).trim();
    final List<String> labels = _asStringList(ing?['label']);
    final List<String> vitamins = _asStringList(ing?['vitamin']);
    final List<String> highlights = _asStringList(ing?['highlights']);
    final String suitableFor = _asString(ing?['suitableFor']).trim();
    final String kategori = _asString(ing?['kategori']).trim();
    final String attention = _asString(ing?['attention']).trim();
    final int omegaValue = _asInt(ing?['omega']);
    final int kalsiumValue = _asInt(ing?['kalsium']);
    final String detectedAt = _formatIsoDateTime(ing?['detected_at']);
    final String createdAt = _formatIsoDateTime(ing?['createdAt']);
    final String updatedAt = _formatIsoDateTime(ing?['updatedAt']);

    final int caloriesValue = _asInt(ing?['caloriesValue']);
    final double proteinValue = _asDouble(ing?['proteinValue']);
    final double lemakValue = _asDouble(ing?['lemak']);

    final double caloriesProgress = ing == null
        ? 0
        : (calorieLevel.isNotEmpty
              ? _levelToProgress(calorieLevel)
              : (caloriesValue / 500).clamp(0.0, 1.0));
    final double proteinProgress = ing == null
        ? 0
        : (proteinLevel.isNotEmpty
              ? _levelToProgress(proteinLevel)
              : (proteinValue / 50).clamp(0.0, 1.0));
    final double lemakProgress = ing == null
        ? 0
        : (lemakValue / 20).clamp(0.0, 1.0);

    final bool canSystemPop = widget.onBack == null && !_showResultsSheet;

    return PopScope(
      canPop: canSystemPop,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_showResultsSheet) {
          _closeResultsToCamera();
          return;
        }

        final onBack = widget.onBack;
        if (onBack != null) {
          onBack();
          return;
        }

        final nav = Navigator.of(context);
        if (nav.canPop()) nav.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. KAMERA DASAR
            Positioned.fill(child: _cameraView()),

            // 2. LAYER OVERLAY & FRAME (Disatukan agar Presisi)
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double screenW = constraints.maxWidth;
                        final double screenH = constraints.maxHeight;

                        final double centerX = screenW / 2;
                        final double centerY = (screenH / 2) + verticalOffset;

                        final Rect scanRect = Rect.fromCenter(
                          center: Offset(centerX, centerY),
                          width: scanBoxSize,
                          height: scanBoxSize,
                        );

                        const double overlayOpacity = 0.28;
                        Widget dimmer() => Container(
                          color: Colors.black.withOpacity(overlayOpacity),
                        );

                        return Stack(
                          children: [
                            // Dim areas outside scan box
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: scanRect.top.clamp(0.0, screenH),
                              child: dimmer(),
                            ),
                            Positioned(
                              top: scanRect.bottom.clamp(0.0, screenH),
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: dimmer(),
                            ),
                            Positioned(
                              top: scanRect.top.clamp(0.0, screenH),
                              left: 0,
                              width: scanRect.left.clamp(0.0, screenW),
                              height: scanRect.height,
                              child: dimmer(),
                            ),
                            Positioned(
                              top: scanRect.top.clamp(0.0, screenH),
                              left: scanRect.right.clamp(0.0, screenW),
                              right: 0,
                              height: scanRect.height,
                              child: dimmer(),
                            ),

                            // Tooltip (centered above the scan box)
                            Positioned(
                              left: scanRect.left,
                              top: (scanRect.top - 48).clamp(0.0, screenH),
                              width: scanRect.width,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandGreen,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    tooltipText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Single white border
                            Positioned(
                              left: scanRect.left,
                              top: scanRect.top,
                              width: scanRect.width,
                              height: scanRect.height,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 3. HEADER (Safe Area Friendly)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: _handleBack,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  // Title
                  const Text(
                    'Pindai Makanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Right side: Flash + Camera Toggle
                  Row(
                    children: [
                      // Flash Button
                      GestureDetector(
                        onTap: _cycleFlashMode,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Icon(
                            _flashIconFor(_flashMode),
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Toggle Camera Button
                      GestureDetector(
                        onTap: _toggleCameraDirection,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4. ACTIONS (Lens-like) di layer kamera
            if (_isActive && !_showResultsSheet)
              Positioned(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 90,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: _scanning ? null : _captureAndScanInApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandGreen,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _scanning ? 'Memindai...' : 'Foto Bahan Pangan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _scanning
                          ? null
                          : () => _pickAndScan(ImageSource.gallery),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: AppTheme.brandGreen.withOpacity(0.5),
                        ),
                      ),
                      child: const Text(
                        'Upload dari Galeri',
                        style: TextStyle(
                          color: AppTheme.brandGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 5. RESULTS SHEET (muncul setelah jepret/upload)
            if (_showResultsSheet)
              NotificationListener<DraggableScrollableNotification>(
                onNotification: (n) {
                  if (!_scanning && n.extent <= 0.16) {
                    _closeResultsToCamera();
                  }
                  return false;
                },
                child: DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: 0.35,
                  minChildSize: 0.12,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(35),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 15),
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(25, 12, 25, 30),
                        children: [
                          // Handle Bar
                          Center(
                            child: Container(
                              width: 60,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          if (_scanning) ...[
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 6),
                                  CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.brandGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Memindai...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (!_scanning && _scanError != null) ...[
                            Text(
                              _scanError!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (!_scanning && ing == null) ...[
                            const Text(
                              'Belum ada hasil ditemukan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Coba jepret ulang atau upload dari galeri.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          if (!_scanning &&
                              _scanError == null &&
                              ing != null) ...[
                            Text(
                              nameUpper,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Kecocokan ${(confidence <= 0 ? 0 : (confidence * 100)).clamp(0, 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          const SizedBox(height: 25),
                          if (ing != null) ...[
                            // Chips
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildModernChip(
                                  calorieLevel.isEmpty
                                      ? 'Kalori -'
                                      : calorieLevel,
                                  AppTheme.brandGreen,
                                ),
                                _buildModernChip(
                                  proteinLevel.isEmpty
                                      ? 'Protein -'
                                      : proteinLevel,
                                  Colors.redAccent,
                                ),
                                _buildModernChip(
                                  vitaminLevel.isEmpty
                                      ? 'Vitamin -'
                                      : vitaminLevel,
                                  Colors.orange,
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),
                            // Progress Bars
                            _buildLabelBar(
                              'Kandungan Lemak',
                              lemakProgress,
                              '${lemakValue.toStringAsFixed(0)} G',
                              AppTheme.brandGreen,
                            ),
                            _buildLabelBar(
                              'Kandungan Protein',
                              proteinProgress,
                              '${proteinValue.toStringAsFixed(0)} G',
                              Colors.redAccent,
                            ),
                            _buildLabelBar(
                              'Kalori Total',
                              caloriesProgress,
                              '$caloriesValue Kal',
                              Colors.orange,
                            ),
                          ],

                          const SizedBox(height: 25),
                          if (ing != null) ...[
                            _buildSectionTitle('Foto Bahan'),
                            const SizedBox(height: 10),
                            _buildIngredientImage(
                              imageUrl: imageUrl,
                              fallbackPath: _lastCapturedPath,
                            ),
                            const SizedBox(height: 22),

                            if (labels.isNotEmpty) ...[
                              _buildSectionTitle('Label'),
                              const SizedBox(height: 10),
                              _buildPillWrap(
                                labels,
                                pillColor: AppTheme.brandGreen,
                              ),
                              const SizedBox(height: 22),
                            ],

                            if (vitamins.isNotEmpty) ...[
                              _buildSectionTitle('Vitamin'),
                              const SizedBox(height: 10),
                              _buildPillWrap(
                                vitamins,
                                pillColor: Colors.orange,
                              ),
                              const SizedBox(height: 22),
                            ],

                            if (highlights.isNotEmpty) ...[
                              _buildSectionTitle('Highlights'),
                              const SizedBox(height: 10),
                              _buildBulletList(highlights),
                              const SizedBox(height: 22),
                            ],

                            _buildSectionTitle('Info'),
                            const SizedBox(height: 10),
                            _buildInfoRow('Kategori', kategori),
                            _buildInfoRow('Cocok Untuk', suitableFor),
                            _buildInfoRow(
                              'Omega-3',
                              omegaValue > 0 ? '$omegaValue mg' : '-',
                            ),
                            _buildInfoRow(
                              'Kalsium',
                              kalsiumValue > 0 ? '$kalsiumValue mg' : '-',
                            ),
                            _buildInfoRow('Terdeteksi', detectedAt),
                            _buildInfoRow('Dibuat', createdAt),
                            _buildInfoRow('Diperbarui', updatedAt),

                            if (attention.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildAttentionBox(attention),
                            ],

                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.brandGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HasilScanPage(
                                        ingredientName: _asString(
                                          ing['name'],
                                        ).trim(),
                                        ingredient: Map<String, dynamic>.from(
                                          ing,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Rekomendasi resep masakan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(
                            height: 100,
                          ), // Spasi extra agar bisa di-scroll mentok
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // UI Helpers (Chip & Bar)
  Widget _buildModernChip(String label, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 95),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label.replaceFirst(' ', '\n'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLabelBar(
    String label,
    double progress,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _asStringList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v
          .map((e) => _asString(e).trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }

    final s = _asString(v).trim();
    if (s.isEmpty) return const [];
    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static String _formatIsoDateTime(dynamic v) {
    final raw = _asString(v).trim();
    if (raw.isEmpty) return '-';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}-${two(local.month)}-${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _buildIngredientImage({
    required String imageUrl,
    required String? fallbackPath,
  }) {
    final BorderRadius radius = BorderRadius.circular(18);

    Widget child;
    if (imageUrl.isNotEmpty) {
      child = Image.network(
        imageUrl,
        height: 170,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageFallback();
        },
      );
    } else if (!kIsWeb && (fallbackPath ?? '').trim().isNotEmpty) {
      child = Image.file(
        File(fallbackPath!),
        height: 170,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageFallback();
        },
      );
    } else {
      child = _buildImageFallback();
    }

    return ClipRRect(
      borderRadius: radius,
      child: Container(color: Colors.grey[100], child: child),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      height: 170,
      width: double.infinity,
      color: Colors.grey[100],
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 42),
    );
  }

  Widget _buildPillWrap(List<String> items, {required Color pillColor}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: pillColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: pillColor.withOpacity(0.18)),
              ),
              child: Text(
                t,
                style: TextStyle(
                  color: pillColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      children: items
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.brandGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final v = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
