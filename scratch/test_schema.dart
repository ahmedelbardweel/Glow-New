import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://sqvbbsqmwktxuapwivnk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxdmJic3Ftd2t0e'
    'HVhcHdpdm5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkxMzY3NTAsImV4cCI6MjEwNDcxMjc1MH0.w4rUqvb8eXZ77x6nHiDX004jPdctHX7CJLVdVVEaOnI',
  );

  final client = Supabase.instance.client;
  
  // Try to find ANY row in children_profiles, using the admin/service key if possible? We don't have it.
  // Instead, let's just create a new child profile to see if it throws an error about missing columns!
  
  try {
    // Generate a random email
    final email = 'test_${DateTime.now().millisecondsSinceEpoch}@test.com';
    final password = 'password123';
    
    final authRes = await client.auth.signUp(email: email, password: password);
    final user = authRes.user;
    
    if (user != null) {
      print('Created user: \${user.id}');
      
      final data = await client.from('children_profiles').insert({
        'id': user.id,
        'name': 'Test Child',
        'age': 5,
        'avatar_url': 'avatar1',
        'child_code': 'CH-0000',
        'total_stars': 0,
        'total_badges': 0,
        // 'total_missions': 0, // let's see if this throws
      }).select().single();
      
      print('Profile inserted: \$data');
      
      // Let's try to update total_stars
      await client.from('children_profiles').update({
        'total_stars': 50,
      }).eq('id', user.id);
      
      final updated = await client.from('children_profiles').select().eq('id', user.id).single();
      print('Profile updated: \$updated');
      
    }
  } catch (e) {
    print('Error occurred: \$e');
  }
}
