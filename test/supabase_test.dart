import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Check children profiles', () async {
    await Supabase.initialize(
      url: 'https://sqvbbsqmwktxuapwivnk.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxdmJic3Ftd2t0e'
      'HVhcHdpdm5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxMzY3NTAsImV4cCI6MjEwNDcxMjc1MH0.w4rUqvb8eXZ77x6nHiDX004jPdctHX7CJLVdVVEaOnI',
    );
    final client = Supabase.instance.client;
    
    // Login as the parent
    final authRes = await client.auth.signInWithPassword(
      email: 'a@a.com', // Need to know the parent email... I don't know it.
      password: 'password123',
    );
    
    final res = await client.from('children_profiles').select().limit(5);
    print('Profiles: \$res');
  });
}
