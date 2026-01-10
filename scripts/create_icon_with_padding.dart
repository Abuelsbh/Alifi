import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  // Read the original logo
  final originalBytes = File('assets/images/logo.jpg').readAsBytesSync();
  final originalImage = img.decodeImage(originalBytes);
  
  if (originalImage == null) {
    print('Error: Could not decode image');
    exit(1);
  }
  
  // Calculate new size (70% of original for zoom out effect)
  final scaleFactor = 0.70;
  final newWidth = (originalImage.width * scaleFactor).round();
  final newHeight = (originalImage.height * scaleFactor).round();
  
  // Resize the image (zoom out)
  final resizedImage = img.copyResize(
    originalImage,
    width: newWidth,
    height: newHeight,
    interpolation: img.Interpolation.cubic,
  );
  
  // Create a new canvas with white background matching original size
  final paddedImage = img.Image(
    width: originalImage.width,
    height: originalImage.height,
  );
  
  // Fill with white background
  img.fill(paddedImage, color: img.ColorRgb8(255, 255, 255));
  
  // Calculate position to center the resized image
  final offsetX = (originalImage.width - newWidth) ~/ 2;
  final offsetY = (originalImage.height - newHeight) ~/ 2;
  
  // Composite the resized image onto the padded canvas
  img.compositeImage(paddedImage, resizedImage, dstX: offsetX, dstY: offsetY);
  
  // Save as JPEG
  final outputBytes = img.encodeJpg(paddedImage, quality: 95);
  File('assets/images/logo_with_padding.jpg').writeAsBytesSync(outputBytes);
  
  print('Successfully created logo_with_padding.jpg');
  print('Original size: ${originalImage.width}x${originalImage.height}');
  print('Resized to: ${newWidth}x${newHeight}');
  print('Final size: ${paddedImage.width}x${paddedImage.height}');
}

