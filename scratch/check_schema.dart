import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabase = SupabaseClient(
    'https://sqvbbsqmwktxuapwivnk.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxdmJic3Ftd2t0e'
    'HVhcHdpdm5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxMzY3NTAsImV4cCI6MjEwNDcxMjc1MH0.w4rUqvb8eXZ77x6nHiDX004jPdctHX7CJLVdVVEa'
    'OnI',
  );

  try {
    final response = await supabase.from('children_profiles').select().limit(1);
    print('Children Profiles Columns:');
    if (response.isNotEmpty) {
       print(response.first.keys.toList());
       print('Data: ${response.first}');
    } else {
       print('No data');
    }
  } catch (e) {
    print('Error: $e');
  }
}
