import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseSeeder {
  final SupabaseClient supabaseClient;

  DatabaseSeeder(this.supabaseClient);

  Future<void> seedDatabase() async {
    // 1. Worlds
    final worldForest = await supabaseClient.from('worlds').insert({
      'title': 'عالم غابة الشجعان',
      'description': 'غابة خضراء ساحرة مليئة بالأسرار والحيوانات اللطيفة التي تنتظر مساعدتك واستكشاف أسرارها الطبيعية.',
      'image_url': 'https://images.unsplash.com/photo-1507608616759-54f48f0af0ee?auto=format&fit=crop&w=1200&q=80',
    }).select().single();

    final worldSpace = await supabaseClient.from('worlds').insert({
      'title': 'عالم فضاء النجوم المضيئة',
      'description': 'رحلة بين الكواكب والمجرات البعيدة لاكتشاف أسرار الكون وتجميع غبار النجوم اللامع.',
      'image_url': 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=1200&q=80',
    }).select().single();

    final worldOcean = await supabaseClient.from('worlds').insert({
      'title': 'عالم المحيط الساحر',
      'description': 'مغامرة في أعماق البحار الزرقاء بين الشعاب المرجانية الملونة والدلافين الودودة والكنوز المفقودة.',
      'image_url': 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80',
    }).select().single();

    final worldFuture = await supabaseClient.from('worlds').insert({
      'title': 'عالم مدينة المستقبل الذكية',
      'description': 'مدينة حديثة متطورة تعتمد على الطاقة النظيفة والروبوتات المساعدة والابتكارات العبقرية.',
      'image_url': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=1200&q=80',
    }).select().single();

    // 2. Missions for Forest
    final mSeed = await supabaseClient.from('missions').insert({
      'world_id': worldForest['id'],
      'title': 'سر البذرة السحرية',
      'badge_name': 'حارس الطبيعة 🌿',
      'stars_reward': 50,
      'order_index': 1,
    }).select().single();

    final mBird = await supabaseClient.from('missions').insert({
      'world_id': worldForest['id'],
      'title': 'إنقاذ طائر الصباح الذهبي',
      'badge_name': 'صديق الحيوانات 🕊️',
      'stars_reward': 75,
      'order_index': 2,
    }).select().single();

    // Stories & Questions for Forest - Seed Mission
    await supabaseClient.from('stories').insert([
      {
        'mission_id': mSeed['id'],
        'title': 'اللقاء في الغابة',
        'character_name': 'fort_frontal.glb',
        'content': 'مرحباً يا بطل! أنا فورت، حارس الغابة الأخضر. اليوم عثرت على بذرة تتوهج بضوء ذهبي غريب تحت شجرة البلوط العظيمة!',
        'image_url': '',
        'order_index': 1,
      },
      {
        'mission_id': mSeed['id'],
        'title': 'لغز التربة الصالحة',
        'character_name': 'lort_frontal.glb',
        'content': 'أهلاً بك! أنا لورت الذكي. هذه البذرة تحتاج إلى عناية خاصة وماء نقي من ينبوع الأمل لتنمو وتصبح شجرة تعطي الثمار لكل حيوانات الغابة.',
        'image_url': '',
        'order_index': 2,
      },
      {
        'mission_id': mSeed['id'],
        'title': 'ازدهار الشجرة المباركة',
        'character_name': 'fort_frontal.glb',
        'content': 'بفضل همتك وعملك الرائع زرعنا البذرة وسقيناها! انظر كيف تفتحت أزهارها وبدأت تنشر العطر والبهجة في كل أرجاء الغابة!',
        'image_url': '',
        'order_index': 3,
      },
    ]);

    await supabaseClient.from('questions').insert([
      {
        'mission_id': mSeed['id'],
        'question_text': 'ما الذي تحتاجه البذرة لتنمو وتصبح شجرة قوية؟',
        'options': ['الماء النقي والضوء والتربة الصالحة', 'المشروبات الغازية والحلويات', 'البقاء في الظلام الدائم'],
        'correct_answer_index': 0,
      },
      {
        'mission_id': mSeed['id'],
        'question_text': 'من هو الحارس الأخضر للغابة الذي ساعدنا في زراعة البذرة؟',
        'options': ['كورت', 'فورت (Fort)', 'بورت'],
        'correct_answer_index': 1,
      },
    ]);

    // Stories & Questions for Forest - Bird Mission
    await supabaseClient.from('stories').insert([
      {
        'mission_id': mBird['id'],
        'title': 'صوت حزين بين الأغصان',
        'character_name': 'mort_frontal.glb',
        'content': 'سمعت صوتاً خافتاً ينادي للمساعدة في قمة التل! طائر الصباح الجميل علق جناحه الصغير بين أغصان الشجيرات الشائكة.',
        'image_url': '',
        'order_index': 1,
      },
      {
        'mission_id': mBird['id'],
        'title': 'يد العون والرفق',
        'character_name': 'fort_frontal.glb',
        'content': 'اقتربنا بحذر وهدوء حتى لا نخيفه، وبلطف شديد حررنا جناحه وقدمنا له حبات الماء الصافية. الحيوانات تشعر باللطف دائماً!',
        'image_url': '',
        'order_index': 2,
      },
    ]);

    await supabaseClient.from('questions').insert([
      {
        'mission_id': mBird['id'],
        'question_text': 'كيف تصرف الأبطال عند مساعدة الطائر الصغير؟',
        'options': ['بالصراخ والركض السريع', 'بهدوء ولطف وحذر شديد', 'تجاهلوه ومضوا في طريقهم'],
        'correct_answer_index': 1,
      },
      {
        'mission_id': mBird['id'],
        'question_text': 'الرفق بالحيوان ومساعدته يعتبر دليلاً على:',
        'options': ['الشهامة وحسن الخلق والرحمة', 'إضاعة الوقت فقط', 'الخوف والتردد'],
        'correct_answer_index': 0,
      },
    ]);

    // 3. Missions for Space
    final mPlanet = await supabaseClient.from('missions').insert({
      'world_id': worldSpace['id'],
      'title': 'رحلة إلى الكوكب المضيء',
      'badge_name': 'رائد الفضاء الصغير 🚀',
      'stars_reward': 80,
      'order_index': 1,
    }).select().single();

    await supabaseClient.from('stories').insert([
      {
        'mission_id': mPlanet['id'],
        'title': 'الاستعداد للإقلاع',
        'character_name': 'port_frontal.glb',
        'content': 'مرحباً بك في مركبتنا الفضائية! أنا بورت المغامر، وقد قمنا بتجهيز محركات الصاروخ للانطلاق نحو الكوكب الكريستالي اللامع!',
        'image_url': '',
        'order_index': 1,
      },
      {
        'mission_id': mPlanet['id'],
        'title': 'بين النجوم المتلألئة',
        'character_name': 'qort_frontal.glb',
        'content': 'أنا كورت قائد الرحلة. انظر من نافذة المركبة، الكواكب تدور بنظام بديع في الفضاء الواسع. تمسك جيداً نحن نقترب من مدار الكوكب!',
        'image_url': '',
        'order_index': 2,
      },
    ]);

    await supabaseClient.from('questions').insert([
      {
        'mission_id': mPlanet['id'],
        'question_text': 'ما هي وسيلة النقل التي استخدمها الأبطال للوصول إلى الفضاء؟',
        'options': ['السيارة السريعة', 'الصاروخ والمركبة الفضائية', 'القارب الشراعي'],
        'correct_answer_index': 1,
      },
    ]);

    // 4. Missions for Ocean
    final mOcean = await supabaseClient.from('missions').insert({
      'world_id': worldOcean['id'],
      'title': 'كنز الأعماق المفقود',
      'badge_name': 'غواص الأعماق 🐬',
      'stars_reward': 85,
      'order_index': 1,
    }).select().single();

    await supabaseClient.from('stories').insert([
      {
        'mission_id': mOcean['id'],
        'title': 'الغوص تحت الأمواج',
        'character_name': 'mort_frontal.glb',
        'content': 'ارتدينا بدلات الغوص وانطلقنا معاً في أعماق المحيط الأزرق الصافي. الأسماك الملونة ترحب بنا وتسبح حولنا بود وسعادة!',
        'image_url': '',
        'order_index': 1,
      },
    ]);

    await supabaseClient.from('questions').insert([
      {
        'mission_id': mOcean['id'],
        'question_text': 'ماذا وجد الأبطال داخل صندوق الكنز المغمور؟',
        'options': ['بوصلة نادرة وخرائط قديمة تحكي تاريخ البحر', 'ألعاب بلاستيكية مكسورة', 'صناديق فارغة'],
        'correct_answer_index': 0,
      },
    ]);

    // 5. Missions for Future City
    final mFuture = await supabaseClient.from('missions').insert({
      'world_id': worldFuture['id'],
      'title': 'اختراع الروبوت المساعد',
      'badge_name': 'المبتكر الصغير 🤖',
      'stars_reward': 100,
      'order_index': 1,
    }).select().single();

    await supabaseClient.from('stories').insert([
      {
        'mission_id': mFuture['id'],
        'title': 'في معمل الابتكار',
        'character_name': 'qort_frontal.glb',
        'content': 'مرحباً بك في معمل المستقبل الذكي! نعمل اليوم على تجميع روبوت صغير ذكي يساعد كبار السن في حمل الأغراض وسقاية النباتات.',
        'image_url': '',
        'order_index': 1,
      },
    ]);

    await supabaseClient.from('questions').insert([
      {
        'mission_id': mFuture['id'],
        'question_text': 'ما هو الهدف الأساسي من اختراع الروبوت المساعد؟',
        'options': ['مساعدة كبار السن وحمل الأغراض وسقاية النباتات', 'التسابق في الشوارع وإزعاج الناس', 'الجلوس دون عمل'],
        'correct_answer_index': 0,
      },
    ]);
  }
}
