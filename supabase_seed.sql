-- =========================================================================
-- GLOW APP - Professional Database Seeder
-- =========================================================================

DO $$
DECLARE
    -- معرفات العوالم
    world_forest_id UUID := gen_random_uuid();
    world_space_id UUID := gen_random_uuid();
    world_ocean_id UUID := gen_random_uuid();
    world_future_id UUID := gen_random_uuid();

    -- معرفات المهام
    m_seed_id UUID := gen_random_uuid();
    m_bird_id UUID := gen_random_uuid();
    m_planet_id UUID := gen_random_uuid();
    m_stardust_id UUID := gen_random_uuid();
    m_coral_id UUID := gen_random_uuid();
    m_pearl_id UUID := gen_random_uuid();
    m_robot_id UUID := gen_random_uuid();
    m_energy_id UUID := gen_random_uuid();

BEGIN
    -- ---------------------------------------------------------------------
    -- 1. تنظيف البيانات التجريبية القديمة
    -- ---------------------------------------------------------------------
    DELETE FROM child_progress WHERE true;
    DELETE FROM questions WHERE true;
    DELETE FROM stories WHERE true;
    DELETE FROM missions WHERE true;
    DELETE FROM worlds WHERE true;

    -- ---------------------------------------------------------------------
    -- 2. إدخال العوالم (Worlds)
    -- ---------------------------------------------------------------------
    INSERT INTO worlds (id, title, description, image_url, created_at) VALUES
    (
        world_forest_id,
        'عالم غابة الشجعان',
        'غابة خضراء ساحرة مليئة بالأسرار والحيوانات اللطيفة التي تنتظر مساعدتك واستكشاف أسرارها الطبيعية.',
        'https://images.unsplash.com/photo-1507608616759-54f48f0af0ee?auto=format&fit=crop&w=1200&q=80',
        NOW()
    ),
    (
        world_space_id,
        'عالم فضاء النجوم المضيئة',
        'رحلة بين الكواكب والمجرات البعيدة لاكتشاف أسرار الكون وتجميع غبار النجوم اللامع.',
        'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=1200&q=80',
        NOW() + INTERVAL '1 second'
    ),
    (
        world_ocean_id,
        'عالم المحيط الساحر',
        'مغامرة في أعماق البحار الزرقاء بين الشعاب المرجانية الملونة والدلافين الودودة والكنوز المفقودة.',
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80',
        NOW() + INTERVAL '2 seconds'
    ),
    (
        world_future_id,
        'عالم مدينة المستقبل الذكية',
        'مدينة حديثة متطورة تعتمد على الطاقة النظيفة والروبوتات المساعدة والابتكارات العبقرية.',
        'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=1200&q=80',
        NOW() + INTERVAL '3 seconds'
    );

    -- ---------------------------------------------------------------------
    -- 3. إدخال المهام (Missions)
    -- ---------------------------------------------------------------------
    -- مهام عالم الغابة
    INSERT INTO missions (id, world_id, title, badge_name, stars_reward, order_index, created_at) VALUES
    (
        m_seed_id, world_forest_id, 'سر البذرة السحرية', 'حارس الطبيعة', 50, 1, NOW()
    ),
    (
        m_bird_id, world_forest_id, 'إنقاذ طائر الصباح الذهبي', 'صديق الحيوانات', 75, 2, NOW() + INTERVAL '1 second'
    );

    -- مهام عالم الفضاء
    INSERT INTO missions (id, world_id, title, badge_name, stars_reward, order_index, created_at) VALUES
    (
        m_planet_id, world_space_id, 'رحلة إلى الكوكب المضيء', 'رائد الفضاء الصغير', 80, 1, NOW() + INTERVAL '2 seconds'
    ),
    (
        m_stardust_id, world_space_id, 'تجميع غبار النجوم', 'صائد النيازك', 100, 2, NOW() + INTERVAL '3 seconds'
    );

    -- مهام عالم المحيط
    INSERT INTO missions (id, world_id, title, badge_name, stars_reward, order_index, created_at) VALUES
    (
        m_coral_id, world_ocean_id, 'كنز الأعماق المفقود', 'غواص الأعماق', 85, 1, NOW() + INTERVAL '4 seconds'
    ),
    (
        m_pearl_id, world_ocean_id, 'حامية اللؤلؤة البيضاء', 'حامي الشعاب', 110, 2, NOW() + INTERVAL '5 seconds'
    );

    -- مهام عالم المستقبل
    INSERT INTO missions (id, world_id, title, badge_name, stars_reward, order_index, created_at) VALUES
    (
        m_robot_id, world_future_id, 'اختراع الروبوت المساعد', 'المبتكر الصغير', 100, 1, NOW() + INTERVAL '6 seconds'
    ),
    (
        m_energy_id, world_future_id, 'طاقة الرياح النظيفة', 'بطل الطاقة الخضراء', 120, 2, NOW() + INTERVAL '7 seconds'
    );

    -- ---------------------------------------------------------------------
    -- 4. إدخال مشاهد القصص (Stories)
    -- ---------------------------------------------------------------------
    -- قصة: سر البذرة السحرية
    INSERT INTO stories (id, mission_id, title, character_name, content, image_url, order_index, created_at) VALUES
    (gen_random_uuid(), m_seed_id, 'اللقاء في الغابة', 'fort_frontal.glb', 'مرحباً بك. أنا فورت، حارس الغابة. اليوم عثرت على بذرة تتوهج بضوء ذهبي غريب تحت شجرة البلوط العظيمة.', '', 1, NOW()),
    (gen_random_uuid(), m_seed_id, 'لغز التربة الصالحة', 'lort_frontal.glb', 'أهلاً بك. أنا لورت. هذه البذرة تحتاج إلى عناية خاصة وماء نقي من ينبوع الأمل لتنمو وتصبح شجرة تعطي الثمار.', '', 2, NOW() + INTERVAL '1 second'),
    (gen_random_uuid(), m_seed_id, 'ازدهار الشجرة المباركة', 'fort_frontal.glb', 'بفضل عملك الدؤوب زرعنا البذرة وسقيناها. انظر كيف تفتحت أزهارها وبدأت تنشر العطر في كل أرجاء الغابة.', '', 3, NOW() + INTERVAL '2 seconds');

    -- قصة: إنقاذ طائر الصباح الذهبي
    INSERT INTO stories (id, mission_id, title, character_name, content, image_url, order_index, created_at) VALUES
    (gen_random_uuid(), m_bird_id, 'صوت حزين بين الأغصان', 'mort_frontal.glb', 'سمعت صوتاً خافتاً ينادي للمساعدة في قمة التل. طائر الصباح علق جناحه الصغير بين أغصان الشجيرات.', '', 1, NOW() + INTERVAL '3 seconds'),
    (gen_random_uuid(), m_bird_id, 'يد العون والرفق', 'fort_frontal.glb', 'اقتربنا بحذر، وبلطف حررنا جناحه وقدمنا له الماء الصافي. الرفق بالحيوان واجب علينا جميعاً.', '', 2, NOW() + INTERVAL '4 seconds');

    -- قصة: رحلة إلى الكوكب المضيء
    INSERT INTO stories (id, mission_id, title, character_name, content, image_url, order_index, created_at) VALUES
    (gen_random_uuid(), m_planet_id, 'الاستعداد للإقلاع', 'port_frontal.glb', 'مرحباً بك في مركبتنا الفضائية. أنا بورت، وقد قمنا بتجهيز محركات الصاروخ للانطلاق نحو الكوكب الكريستالي اللامع.', '', 1, NOW() + INTERVAL '5 seconds'),
    (gen_random_uuid(), m_planet_id, 'بين النجوم المتلألئة', 'qort_frontal.glb', 'أنا كورت قائد الرحلة. انظر من نافذة المركبة، الكواكب تدور بنظام دقيق في الفضاء الواسع. نحن نقترب من المدار.', '', 2, NOW() + INTERVAL '6 seconds'),
    (gen_random_uuid(), m_planet_id, 'الهبوط الناجح', 'port_frontal.glb', 'هبطنا بسلام على سطح الكوكب الكريستالي. انظر إلى الرمال التي تشع ضوءاً دافئاً.. هذا استكشاف فضائي عظيم.', '', 3, NOW() + INTERVAL '7 seconds');

    -- ---------------------------------------------------------------------
    -- 5. إدخال الأسئلة (Questions) بصيغة JSONB
    -- ---------------------------------------------------------------------
    -- أسئلة مهمة: سر البذرة السحرية
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index) VALUES
    (gen_random_uuid(), m_seed_id, 'ما الذي تحتاجه البذرة لتنمو وتصبح شجرة قوية؟', '["الماء النقي والضوء والتربة الصالحة", "المشروبات الغازية والحلويات", "البقاء في الظلام الدائم"]'::jsonb, 0),
    (gen_random_uuid(), m_seed_id, 'من هو حارس الغابة الذي ساعدنا في زراعة البذرة؟', '["كورت", "فورت", "بورت"]'::jsonb, 1);

    -- أسئلة مهمة: رحلة إلى الكوكب المضيء
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index) VALUES
    (gen_random_uuid(), m_planet_id, 'ما هي وسيلة النقل التي استخدمها الفريق للوصول إلى الفضاء؟', '["السيارة السريعة", "الصاروخ والمركبة الفضائية", "القارب الشراعي"]'::jsonb, 1),
    (gen_random_uuid(), m_planet_id, 'تدور الكواكب حول الشمس بنظام دقيق في:', '["أعماق البحار", "الفضاء الكوني الواسع", "باطن الأرض"]'::jsonb, 1);

    -- أسئلة مهمة: طاقة الرياح
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index) VALUES
    (gen_random_uuid(), m_energy_id, 'تعتبر طاقة الرياح المولدة من التوربينات طاقة:', '["نظيفة ومتجددة وصديقة للبيئة", "ملوثة للهواء", "مؤقتة وغير مستدامة"]'::jsonb, 0),
    (gen_random_uuid(), m_energy_id, 'أين تُوضع توربينات الرياح عادة للحصول على أفضل كفاءة؟', '["على قمم التلال والمناطق المفتوحة", "داخل الأماكن المغلقة", "في المناطق المنخفضة"]'::jsonb, 0);

END $$;
