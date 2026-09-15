import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = 'YOUR_URL';
  final supabaseKey = 'YOUR_KEY';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  final supabase = Supabase.instance.client;
  print('Ready');
}
