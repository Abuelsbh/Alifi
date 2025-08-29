import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:video_compress/video_compress.dart';
import 'package:path/path.dart' as path;
import '../firebase/firebase_config.dart';

class MediaUploadService {
  static final FirebaseStorage _storage = FirebaseConfig.storage;

  // Upload image to Firebase Storage
  static Future<String> uploadImage({
    required File imageFile,
    required String folder,
    String? fileName,
    int? maxWidth,
    int? maxHeight,
    int quality = 85,
  }) async {
    try {
      print('📤 Starting image upload...');
      
      // Generate unique filename if not provided
      fileName ??= '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      
      // Compress and resize image
      File processedImage = await _processImage(
        imageFile,
        maxWidth: maxWidth ?? 1920,
        maxHeight: maxHeight ?? 1920,
        quality: quality,
      );

      // Create storage reference
      final ref = _storage.ref().child('$folder/$fileName');

      // Upload file
      final uploadTask = ref.putFile(
        processedImage,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalSize': imageFile.lengthSync().toString(),
            'processedSize': processedImage.lengthSync().toString(),
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('📤 Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      // Wait for upload completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up temporary file if it was created
      if (processedImage.path != imageFile.path) {
        await processedImage.delete();
      }

      print('✅ Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload video to Firebase Storage
  static Future<String> uploadVideo({
    required File videoFile,
    required String folder,
    String? fileName,
    VideoQuality quality = VideoQuality.MediumQuality,
  }) async {
    try {
      print('📤 Starting video upload...');
      
      // Generate unique filename if not provided
      fileName ??= '${DateTime.now().millisecondsSinceEpoch}_${path.basename(videoFile.path)}';
      
      // Compress video
      File? compressedVideo = await _compressVideo(videoFile, quality);
      File uploadFile = compressedVideo ?? videoFile;

      // Create storage reference
      final ref = _storage.ref().child('$folder/$fileName');

      // Upload file
      final uploadTask = ref.putFile(
        uploadFile,
        SettableMetadata(
          contentType: 'video/mp4',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalSize': videoFile.lengthSync().toString(),
            'processedSize': uploadFile.lengthSync().toString(),
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('📤 Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      // Wait for upload completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up compressed file if it was created
      if (compressedVideo != null && compressedVideo.path != videoFile.path) {
        await compressedVideo.delete();
      }

      print('✅ Video uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading video: $e');
      throw Exception('Failed to upload video: $e');
    }
  }

  // Upload multiple files
  static Future<List<String>> uploadMultipleFiles({
    required List<File> files,
    required String folder,
    Function(int current, int total)? onProgress,
  }) async {
    List<String> uploadedUrls = [];
    
    for (int i = 0; i < files.length; i++) {
      onProgress?.call(i, files.length);
      
      try {
        String url;
        if (_isImageFile(files[i])) {
          url = await uploadImage(
            imageFile: files[i],
            folder: folder,
          );
        } else if (_isVideoFile(files[i])) {
          url = await uploadVideo(
            videoFile: files[i],
            folder: folder,
          );
        } else {
          throw Exception('Unsupported file type');
        }
        
        uploadedUrls.add(url);
      } catch (e) {
        print('❌ Error uploading file ${i + 1}: $e');
        rethrow;
      }
    }
    
    onProgress?.call(files.length, files.length);
    return uploadedUrls;
  }

  // Process image (resize and compress)
  static Future<File> _processImage(
    File imageFile, {
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Could not decode image');
      }

      // Resize if needed
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > maxWidth ? maxWidth : null,
          height: image.height > maxHeight ? maxHeight : null,
          maintainAspect: true,
        );
      }

      // Compress and save
      final compressedBytes = img.encodeJpg(image, quality: quality);
      
      // Create temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);

      print('📷 Image processed: ${imageFile.lengthSync()} bytes → ${tempFile.lengthSync()} bytes');
      return tempFile;
    } catch (e) {
      print('⚠️ Error processing image, using original: $e');
      return imageFile;
    }
  }

  // Compress video
  static Future<File?> _compressVideo(File videoFile, VideoQuality quality) async {
    try {
      print('🎬 Compressing video...');
      
      final MediaInfo? info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: quality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info != null && info.file != null) {
        print('🎬 Video compressed: ${videoFile.lengthSync()} bytes → ${info.file!.lengthSync()} bytes');
        return info.file;
      }
      
      return null;
    } catch (e) {
      print('⚠️ Error compressing video, using original: $e');
      return null;
    }
  }

  // Check if file is an image
  static bool _isImageFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
  }

  // Check if file is a video
  static bool _isVideoFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(extension);
  }

  // Get file size in human readable format
  static String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Delete file from Firebase Storage
  static Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      print('✅ File deleted successfully');
    } catch (e) {
      print('❌ Error deleting file: $e');
      throw Exception('Failed to delete file: $e');
    }
  }

  // Get file metadata
  static Future<FullMetadata> getFileMetadata(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('❌ Error getting file metadata: $e');
      throw Exception('Failed to get file metadata: $e');
    }
  }
} 