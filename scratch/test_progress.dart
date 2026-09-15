import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://sqvbbsqmwktxuapwivnk.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxdmJic3Ftd2t0e'
    'HVhcHdpdm5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxMzY3NTAsImV4cCI6MjEwNDcxMjc1MH0.w4rUqvb8eXZ77x6nHiDX004jPdctHX7CJLVdVVEa'
    'OnI',
  );

  // Sign in as parent using the dummy parent account or just query the table anonymously
  // We can't easily sign in unless we know a parent email/pass. 
  // Let's just query child_progress to see if we can get anything
  try {
    final response = await supabase.from('child_progress').select().limit(5);
    print('Child Progress: $response');
  } catch (e) {
    print('Error child_progress: $e');
  }
}
