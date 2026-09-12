import 'dart:isolate';
import 'package:file_picker/file_picker.dart';

void main() async {
  final uri = await Isolate.resolvePackageUri(Uri.parse('package:file_picker/file_picker.dart'));
  print(uri);
}
