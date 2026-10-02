import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class SelfieCameraScreen extends StatefulWidget {
  const SelfieCameraScreen({super.key});

  @override
  State<SelfieCameraScreen> createState() => _SelfieCameraScreenState();
}

class _SelfieCameraScreenState extends State<SelfieCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      
      // Cari kamera depan
      final frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first, // Fallback ke kamera pertama jika tidak ada
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final XFile picture = await _controller!.takePicture();
      
      // Kompresi agar ukuran maksimal 1MB (1024 KB)
      final bytes = await File(picture.path).readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      
      if (decodedImage != null) {
        int quality = 85;
        List<int> compressedBytes = img.encodeJpg(decodedImage, quality: quality);
        
        while (compressedBytes.length > 1024 * 1024 && quality > 15) {
          quality -= 15;
          compressedBytes = img.encodeJpg(decodedImage, quality: quality);
        }
        
        await File(picture.path).writeAsBytes(compressedBytes);
      }

      // Mengembalikan path file gambar ke layar sebelumnya
      if (mounted) {
        Navigator.pop(context, picture.path);
      }
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Tampilan Kamera Full Screen (Cropped)
          Builder(
            builder: (context) {
              final size = MediaQuery.of(context).size;
              var scale = size.aspectRatio * _controller!.value.aspectRatio;
              
              // Mencegah scale mengecil (menimbulkan bar hitam)
              if (scale < 1) scale = 1 / scale;
              
              return Transform.scale(
                scale: scale,
                child: Center(
                  child: CameraPreview(_controller!),
                ),
              );
            }
          ),
          
          // Tombol Kembali
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Tombol Ambil Foto
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
