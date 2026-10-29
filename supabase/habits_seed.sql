-- =========================================================================
-- GLOW APP: 5 Smart Habits World & Missions Migration / Seed
-- =========================================================================

DO $$
DECLARE
    habits_world_id UUID := 'a1000000-0000-4000-8000-000000000001';
    mission_1_id UUID := 'a1000000-0000-4000-8000-000000000011';
    mission_2_id UUID := 'a1000000-0000-4000-8000-000000000012';
    mission_3_id UUID := 'a1000000-0000-4000-8000-000000000013';
    mission_4_id UUID := 'a1000000-0000-4000-8000-000000000014';
    mission_5_id UUID := 'a1000000-0000-4000-8000-000000000015';
BEGIN
    -- 1. Create or Update World: عالم العادات الذكية للأبطال
    INSERT INTO worlds (id, title, description, image_url, created_at)
    VALUES (
        habits_world_id,
        'عالم العادات الذكية للأبطال',
        'رحلة ممتعة وتفاعلية مع الأصدقاء بورت، مورت، فورت، سورت، وكورت لاكتساب العادات الخمس الأساسية لبناء شخصية قوية وواثقة.',
        'https://images.unsplash.com/photo-1516627145497-ae6968895b74?auto=format&fit=crop&w=1200&q=80',
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        description = EXCLUDED.description,
        image_url = EXCLUDED.image_url;

    -- 2. Create or Update Missions (5 Habits)
    INSERT INTO missions (id, world_id, title, badge_name, stars_reward, order_index, created_at)
    VALUES (
        mission_1_id,
        habits_world_id,
        'العادة (1): القدرة على قول "لا"',
        'درع الشجاعة والأمان',
        50,
        1,
        NOW() + INTERVAL '0 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        badge_name = EXCLUDED.badge_name,
        stars_reward = EXCLUDED.stars_reward,
        order_index = EXCLUDED.order_index;
    INSERT INTO missions (id, world_id, title, badge_name, stars_reward, order_index, created_at)
    VALUES (
        mission_2_id,
        habits_world_id,
        'العادة (2): التعبير عن الرأي',
        'صوت الحكمة والأدب',
        60,
        2,
        NOW() + INTERVAL '1 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        badge_name = EXCLUDED.badge_name,
        stars_reward = EXCLUDED.stars_reward,
        order_index = EXCLUDED.order_index;
    INSERT INTO missions (id, world_id, title, badge_name, stars_reward, order_index, created_at)
    VALUES (
        mission_3_id,
        habits_world_id,
        'العادة (3): الثقة بالنفس',
        'شعلة الإيمان بالنفس',
        70,
        3,
        NOW() + INTERVAL '2 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        badge_name = EXCLUDED.badge_name,
        stars_reward = EXCLUDED.stars_reward,
        order_index = EXCLUDED.order_index;
    INSERT INTO missions (id, world_id, title, badge_name, stars_reward, order_index, created_at)
    VALUES (
        mission_4_id,
        habits_world_id,
        'العادة (4): اتخاذ القرار',
        'بوصلة القرار الحكيم',
        80,
        4,
        NOW() + INTERVAL '3 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        badge_name = EXCLUDED.badge_name,
        stars_reward = EXCLUDED.stars_reward,
        order_index = EXCLUDED.order_index;
    INSERT INTO missions (id, world_id, title, badge_name, stars_reward, order_index, created_at)
    VALUES (
        mission_5_id,
        habits_world_id,
        'العادة (5): تحمل المسؤولية',
        'تاج المسؤولية والصدق',
        100,
        5,
        NOW() + INTERVAL '4 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        badge_name = EXCLUDED.badge_name,
        stars_reward = EXCLUDED.stars_reward,
        order_index = EXCLUDED.order_index;

    -- 3. Create Stories for each Mission with 3D Character Timelines

    INSERT INTO stories (id, mission_id, title, character_name, content, image_url, order_index, audio_url, timeline_data, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000021',
        mission_1_id,
        'سَأَقُولُ (لَا) لِمَا قَدْ يُؤْذِينِي',
        'port_frontal.glb',
        'مَرْحَبًا يَا صَدِيقِي! /بورت
أَنَا PORT. /بورت
هَلْ سَبَقَ أَنْ طَلَبَ مِنْكَ أَحَدٌ أَنْ تَفْعَلَ شَيْئًا، لٰكِنَّ قَلْبَكَ أَخْبَرَكَ أَنَّ هٰذَا الشَّيْءَ لَيْسَ صَحِيحًا؟ /بورت
هٰذَا بِالضَّبْطِ مَا حَدَثَ مَعِي... /بورت
كُنْتُ أَلْعَبُ أَنَا وَMORT بِالْكُرَةِ مَعَ بَعْضِ الْأَطْفَالِ. /بورت
وَفَجْأَةً أَشَارَ FORT إِلَى سُورٍ مُرْتَفِعٍ وَقَالَ بِحَمَاسٍ: /بورت
"هَيَّا يَا PORT! مَنْ يَسْتَطِيعُ الْقَفْزَ أَوَّلًا؟" /فورت
نَظَرْتُ إِلَى السُّورِ... /بورت
كَانَ مُرْتَفِعًا جِدًّا، وَتَحْتَهُ حِجَارَةٌ. /بورت
شَعَرْتُ بِالْحَمَاسِ... /بورت
لٰكِنْ فِي دَاخِلِي كَانَ هُنَاكَ شُعُورٌ صَغِيرٌ يَقُولُ: /بورت
"مِمَّمْ... رُبَّمَا هٰذَا لَيْسَ آمِنًا." /بورت
فِي تِلْكَ اللَّحْظَةِ نَظَرْتُ إِلَى MORT. /بورت
ابْتَسَمَتْ لِي وَقَالَتْ: /بورت
"مَاذَا يُخْبِرُكَ قَلْبُكَ يَا PORT؟" /مورت
تَذَكَّرْتُ شَيْئًا عَلَّمَنِي إِيَّاهُ QORT مُنْذُ أَيَّامٍ. /بورت
قَالَ لِي وَقْتَهَا: /بورت
"عِنْدَمَا تَشْعُرُ أَنَّ شَيْئًا قَدْ يُؤْذِيكَ، أَوْ يَجْعَلُكَ تَفْعَلُ شَيْئًا غَيْرَ صَحِيحٍ... /كورت
فَلَا تَخَفْ مِنْ قَوْلِ (لَا)." /كورت
ابْتَسَمْتُ... /بورت
وَأَخَذْتُ نَفَسًا صَغِيرًا... /بورت
ثُمَّ قُلْتُ بِكُلِّ هُدُوءٍ: /بورت
"لَا... /بورت
أَنَا لَا أُرِيدُ أَنْ أَقْفِزَ." /بورت
ضَحِكَ أَحَدُ الْأَطْفَالِ وَقَالَ: /بورت
"أُوهْ... يَبْدُو أَنَّكَ خَائِفٌ!" /فورت
ابْتَسَمْتُ وَلَمْ أَغْضَبْ. /بورت
وَقُلْتُ: /بورت
"رُبَّمَا... /بورت
لٰكِنَّنِي أُحِبُّ أَنْ أُحَافِظَ عَلَى سَلَامَتِي. /بورت
هَيَّا نَلْعَبْ لُعْبَةً أُخْرَى." /بورت
وَبَعْدَ دَقَائِقَ... /بورت
حَاوَلَ أَحَدُ الْأَطْفَالِ الْقَفْزَ. /بورت
لٰكِنَّهُ تَعَثَّرَ وَكَادَ يَسْقُطُ. /بورت
رَكَضْنَا جَمِيعًا لِنَطْمَئِنَّ عَلَيْهِ. /بورت
اقْتَرَبَ مِنِّي FORT وَقَالَ: /بورت
"أَظُنُّ أَنَّكَ كُنْتَ مُحِقًّا يَا PORT." /فورت
أَمَّا MORT فَابْتَسَمَتْ وَقَالَتْ: /بورت
"أَرَأَيْتَ؟ أَحْيَانًا... كَلِمَةُ (لَا) تَحْمِينَا." /مورت
ابْتَسَمْتُ أَنَا أَيْضًا... /بورت
وَقُلْتُ فِي نَفْسِي: /بورت
"لَا بَأْسَ... لَقَدْ تَعَلَّمْتُ شَيْئًا جَدِيدًا!" /بورت
"مِنَ الْيَوْمِ... /بورت
سَأَقُولُ (لَا) لِكُلِّ شَيْءٍ قَدْ يُؤْذِينِي أَوْ يَجْعَلُنِي غَيْرَ مُرْتَاحٍ." /بورت
وَالْآنَ يَا صَدِيقِي... /بورت
هَلْ تُسَاعِدُنِي فِي الْإِجَابَةِ عَنِ الْأَسْئِلَةِ؟ /بورت',
        '',
        1,
        'https://sqvbbsqmwktxuapwivnk.supabase.co/storage/v1/object/public/story_audio/habit_1_voice_1792842127421.wav',
        '{"blocks":[{"characterId":"port","startTime":0,"endTime":2.6},{"characterId":"port","startTime":2.85,"endTime":4.61},{"characterId":"port","startTime":4.86,"endTime":17.26},{"characterId":"port","startTime":17.51,"endTime":20.99},{"characterId":"port","startTime":21.24,"endTime":28.02},{"characterId":"port","startTime":28.27,"endTime":37.98},{"characterId":"fort","startTime":38.23,"endTime":41.71},{"characterId":"port","startTime":41.96,"endTime":44.14},{"characterId":"port","startTime":44.39,"endTime":49.68},{"characterId":"port","startTime":49.93,"endTime":52.3},{"characterId":"port","startTime":52.55,"endTime":59.01},{"characterId":"port","startTime":59.26,"endTime":64.18},{"characterId":"port","startTime":64.43,"endTime":68.89},{"characterId":"port","startTime":69.14,"endTime":71.97},{"characterId":"mort","startTime":72.22,"endTime":75.19},{"characterId":"port","startTime":75.44,"endTime":82.64},{"characterId":"port","startTime":82.89,"endTime":84.93},{"characterId":"qort","startTime":85.18,"endTime":92.66},{"characterId":"qort","startTime":92.91,"endTime":95.65},{"characterId":"port","startTime":95.9,"endTime":97.57},{"characterId":"port","startTime":97.82,"endTime":101.07},{"characterId":"port","startTime":101.32,"endTime":104.25},{"characterId":"port","startTime":104.5,"endTime":105.38},{"characterId":"port","startTime":105.63,"endTime":109.02},{"characterId":"port","startTime":109.27,"endTime":112.89},{"characterId":"fort","startTime":113.14,"endTime":115.88},{"characterId":"port","startTime":116.13,"endTime":118.82},{"characterId":"port","startTime":119.07,"endTime":120.32},{"characterId":"port","startTime":120.57,"endTime":121.92},{"characterId":"port","startTime":122.17,"endTime":127.05},{"characterId":"port","startTime":127.3,"endTime":130.46},{"characterId":"port","startTime":130.71,"endTime":133.08},{"characterId":"port","startTime":133.33,"endTime":137},{"characterId":"port","startTime":137.25,"endTime":140.87},{"characterId":"port","startTime":141.12,"endTime":145.3},{"characterId":"port","startTime":145.55,"endTime":149.03},{"characterId":"fort","startTime":149.28,"endTime":151.83},{"characterId":"port","startTime":152.08,"endTime":156.4},{"characterId":"mort","startTime":156.65,"endTime":161.29},{"characterId":"port","startTime":161.54,"endTime":164.33},{"characterId":"port","startTime":164.58,"endTime":167.18},{"characterId":"port","startTime":167.43,"endTime":172.21},{"characterId":"port","startTime":172.46,"endTime":174.18},{"characterId":"port","startTime":174.43,"endTime":183.44},{"characterId":"port","startTime":183.69,"endTime":186.1},{"characterId":"port","startTime":186.35,"endTime":191.04}],"motionBlocks":[{"motionId":"talk","startTime":0,"endTime":2.6},{"motionId":"talk","startTime":2.85,"endTime":4.61},{"motionId":"talk","startTime":4.86,"endTime":17.26},{"motionId":"talk","startTime":17.51,"endTime":20.99},{"motionId":"talk","startTime":21.24,"endTime":28.02},{"motionId":"talk","startTime":28.27,"endTime":37.98},{"motionId":"encourage","startTime":38.23,"endTime":41.71},{"motionId":"talk","startTime":41.96,"endTime":44.14},{"motionId":"talk","startTime":44.39,"endTime":49.68},{"motionId":"talk","startTime":49.93,"endTime":52.3},{"motionId":"talk","startTime":52.55,"endTime":59.01},{"motionId":"talk","startTime":59.26,"endTime":64.18},{"motionId":"talk","startTime":64.43,"endTime":68.89},{"motionId":"smile","startTime":69.14,"endTime":71.97},{"motionId":"talk","startTime":72.22,"endTime":75.19},{"motionId":"thinking","startTime":75.44,"endTime":82.64},{"motionId":"talk","startTime":82.89,"endTime":84.93},{"motionId":"talk","startTime":85.18,"endTime":92.66},{"motionId":"talk","startTime":92.91,"endTime":95.65},{"motionId":"smile","startTime":95.9,"endTime":97.57},{"motionId":"talk","startTime":97.82,"endTime":101.07},{"motionId":"talk","startTime":101.32,"endTime":104.25},{"motionId":"talk","startTime":104.5,"endTime":105.38},{"motionId":"talk","startTime":105.63,"endTime":109.02},{"motionId":"laugh","startTime":109.27,"endTime":112.89},{"motionId":"nervous","startTime":113.14,"endTime":115.88},{"motionId":"smile","startTime":116.13,"endTime":118.82},{"motionId":"talk","startTime":119.07,"endTime":120.32},{"motionId":"talk","startTime":120.57,"endTime":121.92},{"motionId":"talk","startTime":122.17,"endTime":127.05},{"motionId":"encourage","startTime":127.3,"endTime":130.46},{"motionId":"talk","startTime":130.71,"endTime":133.08},{"motionId":"talk","startTime":133.33,"endTime":137},{"motionId":"talk","startTime":137.25,"endTime":140.87},{"motionId":"talk","startTime":141.12,"endTime":145.3},{"motionId":"talk","startTime":145.55,"endTime":149.03},{"motionId":"talk","startTime":149.28,"endTime":151.83},{"motionId":"smile","startTime":152.08,"endTime":156.4},{"motionId":"talk","startTime":156.65,"endTime":161.29},{"motionId":"smile","startTime":161.54,"endTime":164.33},{"motionId":"talk","startTime":164.58,"endTime":167.18},{"motionId":"talk","startTime":167.43,"endTime":172.21},{"motionId":"talk","startTime":172.46,"endTime":174.18},{"motionId":"talk","startTime":174.43,"endTime":183.44},{"motionId":"talk","startTime":183.69,"endTime":186.1},{"motionId":"talk","startTime":186.35,"endTime":191.04}],"hatBlocks":[],"glassesBlocks":[],"musclesBlocks":[],"jumpBlocks":[],"transitions":[{"time":38.23,"duration":0.5,"type":"slide"},{"time":41.96,"duration":0.5,"type":"pop"},{"time":72.22,"duration":0.5,"type":"slide"},{"time":75.44,"duration":0.5,"type":"pop"},{"time":85.18,"duration":0.5,"type":"pop"},{"time":95.9,"duration":0.5,"type":"pop"},{"time":113.14,"duration":0.5,"type":"pop"},{"time":116.13,"duration":0.5,"type":"slide"},{"time":149.28,"duration":0.5,"type":"slide"},{"time":152.08,"duration":0.5,"type":"pop"},{"time":156.65,"duration":0.5,"type":"slide"},{"time":161.54,"duration":0.5,"type":"pop"}],"totalDuration":191.29}',
        NOW() + INTERVAL '0 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        character_name = EXCLUDED.character_name,
        content = EXCLUDED.content,
        audio_url = EXCLUDED.audio_url,
        timeline_data = EXCLUDED.timeline_data;

    INSERT INTO stories (id, mission_id, title, character_name, content, image_url, order_index, audio_url, timeline_data, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000022',
        mission_2_id,
        'رَأْيِي يَسْتَحِقُّ أَنْ يُسْمَعَ',
        'port_frontal.glb',
        'مَرْحَبًا يَا صَدِيقِي! /بورت
أَنَا PORT. /بورت
الْيَوْمَ أُرِيدُ أَنْ أَحْكِيَ لَكَ مَوْقِفًا جَعَلَنِي أَتَعَلَّمُ أَنَّ رَأْيِي مُهِمٌّ، حَتَّى لَوْ كَانَ مُخْتَلِفًا. /بورت
كُنْتُ أَنَا وَMORT وَFORT وَSORT نُفَكِّرُ فِي لُعْبَةٍ نَلْعَبُهَا مَعًا. /بورت
قَالَ FORT بِحَمَاسٍ: /بورت
"هَيَّا نَلْعَبْ لُعْبَةَ الْمُطَارَدَةِ!" /فورت
ضَحِكَتْ MORT وَقَالَتْ: /بورت
"فِكْرَةٌ جَمِيلَةٌ!" /مورت
أَمَّا SORT فَبَدَأَ يُفَكِّرُ فِي قَوَانِينِ اللُّعْبَةِ. /بورت
أَمَّا أَنَا... /بورت
فَكُنْتُ هَادِئًا. /بورت
فِي الْحَقِيقَةِ... /بورت
كُنْتُ أَرْغَبُ فِي لُعْبَةٍ أُخْرَى، لٰكِنَّنِي لَمْ أَقُلْ شَيْئًا. /بورت
لَاحَظَ QORT أَنَّنِي صَامِتٌ. /بورت
ابْتَسَمَ وَسَأَلَنِي: /بورت
"مَا بِكَ يَا PORT؟" /كورت
قُلْتُ بِخَجَلٍ: /بورت
"الْجَمِيعُ أَعْجَبَتْهُمُ الْفِكْرَةُ... وَلَا أُرِيدُ أَنْ أُزْعِجَهُمْ." /بورت
ابْتَسَمَ QORT وَقَالَ جُمْلَتَهُ الَّتِي لَنْ أَنْسَاهَا: /بورت
"الرَّأْيُ الْمُهَذَّبُ لَا يُزْعِجُ أَحَدًا... بَلْ يُسَاعِدُ الْجَمِيعَ عَلَى أَنْ يَفْهَمُوا بَعْضَهُمْ." /كورت
أَخَذْتُ نَفَسًا عَمِيقًا... /بورت
ثُمَّ قُلْتُ: /بورت
"مَا رَأْيُكُمْ أَنْ نَلْعَبَ لُعْبَةَ الْبَحْثِ عَنِ الْكَنْزِ أَوَّلًا... ثُمَّ بَعْدَ ذٰلِكَ نَلْعَبَ الْمُطَارَدَةَ؟" /بورت
نَظَرَ الْجَمِيعُ إِلَى بَعْضِهِمْ. /بورت
ثُمَّ ابْتَسَمَ FORT وَقَالَ: /بورت
"فِكْرَةٌ رَائِعَةٌ!" /فورت
وَقَالَتْ MORT: /بورت
"هٰكَذَا سَنَلْعَبُ لُعْبَتَيْنِ بَدَلًا مِنْ وَاحِدَةٍ!" /مورت
أَمَّا SORT فَقَالَ وَهُوَ يَضْحَكُ: /بورت
"وَأَنَا سَأَرْسُمُ خَرِيطَةَ الْكَنْزِ!" /سورت
شَعَرْتُ بِسَعَادَةٍ كَبِيرَةٍ. /بورت
لَيْسَ لِأَنَّ الْجَمِيعَ وَافَقَنِي... /بورت
بَلْ لِأَنَّنِي عَبَّرْتُ عَنْ رَأْيِي بِأَدَبٍ وَاحْتِرَامٍ. /بورت
ابْتَسَمْتُ... /بورت
وَقُلْتُ فِي نَفْسِي: /بورت
"لَا بَأْسَ... لَقَدْ تَعَلَّمْتُ شَيْئًا جَدِيدًا!" /بورت
"مِنَ الْيَوْمِ... /بورت
سَأَقُولُ رَأْيِي بِأَدَبٍ، لِأَنَّ رَأْيِي لَهُ قِيمَةٌ." /بورت
"وَأَنَا أَثِقُ بِكَ." /مورت
"كُلُّ فِكْرَةٍ جَمِيلَةٍ تَبْدَأُ بِكَلِمَةٍ." /سورت
"وَأَحْيَانًا... أَفْضَلُ الْأَفْكَارِ هِيَ الَّتِي لَمْ نَسْمَعْهَا بَعْدُ." /فورت
"الرَّأْيُ الصَّادِقُ الَّذِي يُقَالُ بِاحْتِرَامٍ... يَبْنِي جُسُورًا بَيْنَ الْقُلُوبِ." /كورت
وَالْآنَ يَا صَدِيقِي... /بورت
هَلْ تُسَاعِدُنِي فِي الْإِجَابَةِ عَنِ الْأَسْئِلَةِ؟ /بورت',
        '',
        1,
        'https://sqvbbsqmwktxuapwivnk.supabase.co/storage/v1/object/public/story_audio/habit_2_voice_1792842218679.wav',
        '{"blocks":[{"characterId":"port","startTime":0,"endTime":2.6},{"characterId":"port","startTime":2.85,"endTime":4.61},{"characterId":"port","startTime":4.86,"endTime":17.77},{"characterId":"port","startTime":18.02,"endTime":26.61},{"characterId":"port","startTime":26.86,"endTime":29.23},{"characterId":"fort","startTime":29.48,"endTime":32.03},{"characterId":"port","startTime":32.28,"endTime":35.16},{"characterId":"mort","startTime":35.41,"endTime":37.36},{"characterId":"port","startTime":37.61,"endTime":43.97},{"characterId":"port","startTime":44.22,"endTime":45.89},{"characterId":"port","startTime":46.14,"endTime":48.18},{"characterId":"port","startTime":48.43,"endTime":50.33},{"characterId":"port","startTime":50.58,"endTime":57.36},{"characterId":"port","startTime":57.61,"endTime":61.09},{"characterId":"port","startTime":61.34,"endTime":63.99},{"characterId":"qort","startTime":64.24,"endTime":65.77},{"characterId":"port","startTime":66.02,"endTime":67.83},{"characterId":"port","startTime":68.08,"endTime":75.37},{"characterId":"port","startTime":75.62,"endTime":82.77},{"characterId":"qort","startTime":83.02,"endTime":92.26},{"characterId":"port","startTime":92.51,"endTime":95.99},{"characterId":"port","startTime":96.24,"endTime":97.87},{"characterId":"port","startTime":98.12,"endTime":109.22},{"characterId":"port","startTime":109.47,"endTime":112.91},{"characterId":"port","startTime":113.16,"endTime":116.32},{"characterId":"fort","startTime":116.57,"endTime":117.92},{"characterId":"port","startTime":118.17,"endTime":120.12},{"characterId":"mort","startTime":120.37,"endTime":124.09},{"characterId":"port","startTime":124.34,"endTime":128.24},{"characterId":"sort","startTime":128.49,"endTime":131.23},{"characterId":"port","startTime":131.48,"endTime":134.73},{"characterId":"port","startTime":134.98,"endTime":138.6},{"characterId":"port","startTime":138.85,"endTime":145.07},{"characterId":"port","startTime":145.32,"endTime":146.99},{"characterId":"port","startTime":147.24,"endTime":149.84},{"characterId":"port","startTime":150.09,"endTime":154.87},{"characterId":"port","startTime":155.12,"endTime":156.84},{"characterId":"port","startTime":157.09,"endTime":163.17},{"characterId":"mort","startTime":163.42,"endTime":165.32},{"characterId":"sort","startTime":165.57,"endTime":169.84},{"characterId":"fort","startTime":170.09,"endTime":175.01},{"characterId":"qort","startTime":175.26,"endTime":182.92},{"characterId":"port","startTime":183.17,"endTime":185.58},{"characterId":"port","startTime":185.83,"endTime":190.52}],"motionBlocks":[{"motionId":"talk","startTime":0,"endTime":2.6},{"motionId":"talk","startTime":2.85,"endTime":4.61},{"motionId":"talk","startTime":4.86,"endTime":17.77},{"motionId":"talk","startTime":18.02,"endTime":26.61},{"motionId":"talk","startTime":26.86,"endTime":29.23},{"motionId":"encourage","startTime":29.48,"endTime":32.03},{"motionId":"laugh","startTime":32.28,"endTime":35.16},{"motionId":"talk","startTime":35.41,"endTime":37.36},{"motionId":"talk","startTime":37.61,"endTime":43.97},{"motionId":"talk","startTime":44.22,"endTime":45.89},{"motionId":"talk","startTime":46.14,"endTime":48.18},{"motionId":"talk","startTime":48.43,"endTime":50.33},{"motionId":"talk","startTime":50.58,"endTime":57.36},{"motionId":"talk","startTime":57.61,"endTime":61.09},{"motionId":"smile","startTime":61.34,"endTime":63.99},{"motionId":"talk","startTime":64.24,"endTime":65.77},{"motionId":"talk","startTime":66.02,"endTime":67.83},{"motionId":"talk","startTime":68.08,"endTime":75.37},{"motionId":"smile","startTime":75.62,"endTime":82.77},{"motionId":"talk","startTime":83.02,"endTime":92.26},{"motionId":"talk","startTime":92.51,"endTime":95.99},{"motionId":"talk","startTime":96.24,"endTime":97.87},{"motionId":"talk","startTime":98.12,"endTime":109.22},{"motionId":"talk","startTime":109.47,"endTime":112.91},{"motionId":"smile","startTime":113.16,"endTime":116.32},{"motionId":"talk","startTime":116.57,"endTime":117.92},{"motionId":"talk","startTime":118.17,"endTime":120.12},{"motionId":"talk","startTime":120.37,"endTime":124.09},{"motionId":"talk","startTime":124.34,"endTime":128.24},{"motionId":"talk","startTime":128.49,"endTime":131.23},{"motionId":"talk","startTime":131.48,"endTime":134.73},{"motionId":"talk","startTime":134.98,"endTime":138.6},{"motionId":"talk","startTime":138.85,"endTime":145.07},{"motionId":"smile","startTime":145.32,"endTime":146.99},{"motionId":"talk","startTime":147.24,"endTime":149.84},{"motionId":"talk","startTime":150.09,"endTime":154.87},{"motionId":"talk","startTime":155.12,"endTime":156.84},{"motionId":"talk","startTime":157.09,"endTime":163.17},{"motionId":"smile","startTime":163.42,"endTime":165.32},{"motionId":"talk","startTime":165.57,"endTime":169.84},{"motionId":"talk","startTime":170.09,"endTime":175.01},{"motionId":"talk","startTime":175.26,"endTime":182.92},{"motionId":"talk","startTime":183.17,"endTime":185.58},{"motionId":"talk","startTime":185.83,"endTime":190.52}],"hatBlocks":[],"glassesBlocks":[],"musclesBlocks":[],"jumpBlocks":[],"transitions":[{"time":29.48,"duration":0.5,"type":"pop"},{"time":32.28,"duration":0.5,"type":"slide"},{"time":35.41,"duration":0.5,"type":"pop"},{"time":37.61,"duration":0.5,"type":"slide"},{"time":64.24,"duration":0.5,"type":"pop"},{"time":66.02,"duration":0.5,"type":"slide"},{"time":83.02,"duration":0.5,"type":"pop"},{"time":92.51,"duration":0.5,"type":"slide"},{"time":116.57,"duration":0.5,"type":"pop"},{"time":118.17,"duration":0.5,"type":"slide"},{"time":120.37,"duration":0.5,"type":"pop"},{"time":124.34,"duration":0.5,"type":"slide"},{"time":128.49,"duration":0.5,"type":"pop"},{"time":131.48,"duration":0.5,"type":"slide"},{"time":163.42,"duration":0.5,"type":"slide"},{"time":165.57,"duration":0.5,"type":"pop"},{"time":170.09,"duration":0.5,"type":"slide"},{"time":175.26,"duration":0.5,"type":"pop"},{"time":183.17,"duration":0.5,"type":"slide"}],"totalDuration":190.77}',
        NOW() + INTERVAL '1 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        character_name = EXCLUDED.character_name,
        content = EXCLUDED.content,
        audio_url = EXCLUDED.audio_url,
        timeline_data = EXCLUDED.timeline_data;

    INSERT INTO stories (id, mission_id, title, character_name, content, image_url, order_index, audio_url, timeline_data, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000023',
        mission_3_id,
        'أَسْتَطِيعُ أَنْ أُجَرِّبَ',
        'port_frontal.glb',
        'مَرْحَبًا يَا صَدِيقِي! /بورت
أَنَا PORT. /بورت
الْيَوْمَ أُرِيدُ أَنْ أَحْكِيَ لَكَ شَيْئًا جَعَلَنِي أُؤْمِنُ بِنَفْسِي أَكْثَرَ. /بورت
كُنْتُ أَنَا وَMORT وَFORT وَSORT نَبْنِي بُرْجًا كَبِيرًا بِالْمُكَعَّبَاتِ. /بورت
كَانَ SORT يُرَتِّبُ الْقِطَعَ بِدِقَّةٍ. /بورت
وَكَانَ FORT يَبْنِي بِسُرْعَةٍ. /بورت
أَمَّا MORT فَكَانَتْ تُشَجِّعُنَا جَمِيعًا. /بورت
وَقَفْتُ أَنْظُرُ إِلَيْهِمْ... /بورت
ثُمَّ قُلْتُ فِي نَفْسِي: /بورت
"لَنْ أَسْتَطِيعَ بِنَاءَ بُرْجٍ مِثْلَهُمْ..." /بورت
ابْتَسَمَتْ MORT وَقَالَتْ: /بورت
"مَا بِكَ يَا PORT؟" /مورت
قُلْتُ بِخَجَلٍ: /بورت
"أَخَافُ أَنْ يَسْقُطَ الْبُرْجُ إِذَا حَاوَلْتُ... رُبَّمَا أَنَا لَسْتُ جَيِّدًا مِثْلَهُمْ." /بورت
ابْتَسَمَتْ MORT، لٰكِنَّهَا لَمْ تُجِبْ. /بورت
فِي تِلْكَ اللَّحْظَةِ اقْتَرَبَ QORT بِهُدُوءٍ. /بورت
نَظَرَ إِلَيَّ وَقَالَ: /بورت
"يَا PORT... /كورت
هَلْ وُلِدْتَ وَأَنْتَ تَعْرِفُ كَيْفَ تَبْنِي الْأَبْرَاجَ؟" /كورت
ضَحِكْتُ وَقُلْتُ: /بورت
"لَا." /بورت
فَقَالَ: /بورت
"إِذَنْ... كَيْفَ سَيَتَعَلَّمُ مَنْ لَا يُحَاوِلُ؟" /كورت
بَقِيتُ أُفَكِّرُ قَلِيلًا... /بورت
ثُمَّ أَخَذْتُ أَوَّلَ مُكَعَّبٍ... /بورت
وَوَضَعْتُهُ بِحَذَرٍ. /بورت
ثُمَّ الثَّانِيَ... /بورت
ثُمَّ الثَّالِثَ... /بورت
وَفَجْأَةً... /بورت
قَالَ FORT مُبْتَسِمًا: /بورت
"انْظُرُوا! PORT بَدَأَ يَبْنِي!" /فورت
وَقَالَ SORT: /بورت
"وَالْبُرْجُ ثَابِتٌ أَيْضًا!" /سورت
ابْتَسَمَتْ MORT وَقَالَتْ: /بورت
"كُنْتَ تَحْتَاجُ فَقَطْ أَنْ تُؤْمِنَ بِنَفْسِكَ." /مورت
نَظَرْتُ إِلَى الْبُرْجِ. /بورت
لَمْ يَكُنْ أَطْوَلَ بُرْجٍ... /بورت
لٰكِنَّهُ كَانَ مِنْ صُنْعِي. /بورت
وَشَعَرْتُ بِفَخْرٍ كَبِيرٍ. /بورت
تَعَلَّمْتُ أَنَّنِي أَسْتَطِيعُ أَنْ أَتَعَلَّمَ أَيَّ شَيْءٍ إِذَا بَدَأْتُ بِالْمُحَاوَلَةِ. /بورت
"لَا بَأْسَ... لَقَدْ تَعَلَّمْتُ شَيْئًا جَدِيدًا!" /بورت
"مِنَ الْيَوْمِ... /بورت
سَأُؤْمِنُ بِنَفْسِي، وَأَمْنَحُهَا فُرْصَةً لِتَتَعَلَّمَ." /بورت
"وَأَنَا أَثِقُ بِكَ." /مورت
"كُلُّ مَهَارَةٍ كَبِيرَةٍ... تَبْدَأُ بِمُحَاوَلَةٍ صَغِيرَةٍ." /سورت
"الشَّجَاعَةُ لَيْسَتْ أَنْ تَكُونَ الْأَفْضَلَ... بَلْ أَنْ تَبْدَأَ." /فورت
"مَنْ يُؤْمِنُ أَنَّهُ يَسْتَطِيعُ التَّعَلُّمَ... يَفْتَحُ لِنَفْسِهِ أَبْوَابًا كَثِيرَةً." /كورت
وَالْآنَ يَا صَدِيقِي... /بورت
هَلْ تُسَاعِدُنِي فِي الْإِجَابَةِ عَنِ الْأَسْئِلَةِ؟ /بورت',
        '',
        1,
        'https://sqvbbsqmwktxuapwivnk.supabase.co/storage/v1/object/public/story_audio/habit_3_voice_1792842315685.wav',
        '{"blocks":[{"characterId":"port","startTime":0,"endTime":2.6},{"characterId":"port","startTime":2.85,"endTime":4.61},{"characterId":"port","startTime":4.86,"endTime":12.52},{"characterId":"port","startTime":12.77,"endTime":23.96},{"characterId":"port","startTime":24.21,"endTime":28.85},{"characterId":"port","startTime":29.1,"endTime":32.26},{"characterId":"port","startTime":32.51,"endTime":37.76},{"characterId":"port","startTime":38.01,"endTime":40.94},{"characterId":"port","startTime":41.19,"endTime":43.74},{"characterId":"port","startTime":43.99,"endTime":48.49},{"characterId":"port","startTime":48.74,"endTime":52.08},{"characterId":"mort","startTime":52.33,"endTime":54.05},{"characterId":"port","startTime":54.3,"endTime":56.11},{"characterId":"port","startTime":56.36,"endTime":66.16},{"characterId":"port","startTime":66.41,"endTime":71.38},{"characterId":"port","startTime":71.63,"endTime":77.2},{"characterId":"port","startTime":77.45,"endTime":80.05},{"characterId":"qort","startTime":80.3,"endTime":81.46},{"characterId":"qort","startTime":81.71,"endTime":86.45},{"characterId":"port","startTime":86.7,"endTime":88.84},{"characterId":"port","startTime":89.09,"endTime":90.07},{"characterId":"port","startTime":90.32,"endTime":91.62},{"characterId":"qort","startTime":91.87,"endTime":96.65},{"characterId":"port","startTime":96.9,"endTime":100.01},{"characterId":"port","startTime":100.26,"endTime":103.6},{"characterId":"port","startTime":103.85,"endTime":106.31},{"characterId":"port","startTime":106.56,"endTime":108.6},{"characterId":"port","startTime":108.85,"endTime":110.85},{"characterId":"port","startTime":111.1,"endTime":112.68},{"characterId":"port","startTime":112.93,"endTime":115.39},{"characterId":"fort","startTime":115.64,"endTime":117.87},{"characterId":"port","startTime":118.12,"endTime":119.84},{"characterId":"sort","startTime":120.09,"endTime":122.37},{"characterId":"port","startTime":122.62,"endTime":125.96},{"characterId":"mort","startTime":126.21,"endTime":129.55},{"characterId":"port","startTime":129.8,"endTime":132.26},{"characterId":"port","startTime":132.51,"endTime":135.25},{"characterId":"port","startTime":135.5,"endTime":138.43},{"characterId":"port","startTime":138.68,"endTime":141.56},{"characterId":"port","startTime":141.81,"endTime":151.75},{"characterId":"port","startTime":152,"endTime":156.78},{"characterId":"port","startTime":157.03,"endTime":158.75},{"characterId":"port","startTime":159,"endTime":165.46},{"characterId":"mort","startTime":165.71,"endTime":167.61},{"characterId":"sort","startTime":167.86,"endTime":174.41},{"characterId":"fort","startTime":174.66,"endTime":180.05},{"characterId":"qort","startTime":180.3,"endTime":187.54},{"characterId":"port","startTime":187.79,"endTime":190.2},{"characterId":"port","startTime":190.45,"endTime":195.14}],"motionBlocks":[{"motionId":"talk","startTime":0,"endTime":2.6},{"motionId":"talk","startTime":2.85,"endTime":4.61},{"motionId":"talk","startTime":4.86,"endTime":12.52},{"motionId":"talk","startTime":12.77,"endTime":23.96},{"motionId":"talk","startTime":24.21,"endTime":28.85},{"motionId":"talk","startTime":29.1,"endTime":32.26},{"motionId":"talk","startTime":32.51,"endTime":37.76},{"motionId":"talk","startTime":38.01,"endTime":40.94},{"motionId":"talk","startTime":41.19,"endTime":43.74},{"motionId":"talk","startTime":43.99,"endTime":48.49},{"motionId":"smile","startTime":48.74,"endTime":52.08},{"motionId":"talk","startTime":52.33,"endTime":54.05},{"motionId":"talk","startTime":54.3,"endTime":56.11},{"motionId":"talk","startTime":56.36,"endTime":66.16},{"motionId":"smile","startTime":66.41,"endTime":71.38},{"motionId":"talk","startTime":71.63,"endTime":77.2},{"motionId":"talk","startTime":77.45,"endTime":80.05},{"motionId":"talk","startTime":80.3,"endTime":81.46},{"motionId":"talk","startTime":81.71,"endTime":86.45},{"motionId":"talk","startTime":86.7,"endTime":88.84},{"motionId":"talk","startTime":89.09,"endTime":90.07},{"motionId":"talk","startTime":90.32,"endTime":91.62},{"motionId":"talk","startTime":91.87,"endTime":96.65},{"motionId":"talk","startTime":96.9,"endTime":100.01},{"motionId":"talk","startTime":100.26,"endTime":103.6},{"motionId":"talk","startTime":103.85,"endTime":106.31},{"motionId":"talk","startTime":106.56,"endTime":108.6},{"motionId":"talk","startTime":108.85,"endTime":110.85},{"motionId":"talk","startTime":111.1,"endTime":112.68},{"motionId":"talk","startTime":112.93,"endTime":115.39},{"motionId":"talk","startTime":115.64,"endTime":117.87},{"motionId":"talk","startTime":118.12,"endTime":119.84},{"motionId":"talk","startTime":120.09,"endTime":122.37},{"motionId":"smile","startTime":122.62,"endTime":125.96},{"motionId":"talk","startTime":126.21,"endTime":129.55},{"motionId":"talk","startTime":129.8,"endTime":132.26},{"motionId":"talk","startTime":132.51,"endTime":135.25},{"motionId":"talk","startTime":135.5,"endTime":138.43},{"motionId":"winCelebration","startTime":138.68,"endTime":141.56},{"motionId":"talk","startTime":141.81,"endTime":151.75},{"motionId":"talk","startTime":152,"endTime":156.78},{"motionId":"talk","startTime":157.03,"endTime":158.75},{"motionId":"talk","startTime":159,"endTime":165.46},{"motionId":"smile","startTime":165.71,"endTime":167.61},{"motionId":"talk","startTime":167.86,"endTime":174.41},{"motionId":"talk","startTime":174.66,"endTime":180.05},{"motionId":"talk","startTime":180.3,"endTime":187.54},{"motionId":"talk","startTime":187.79,"endTime":190.2},{"motionId":"talk","startTime":190.45,"endTime":195.14}],"hatBlocks":[],"glassesBlocks":[],"musclesBlocks":[],"jumpBlocks":[],"transitions":[{"time":52.33,"duration":0.5,"type":"pop"},{"time":54.3,"duration":0.5,"type":"slide"},{"time":80.3,"duration":0.5,"type":"pop"},{"time":86.7,"duration":0.5,"type":"pop"},{"time":91.87,"duration":0.5,"type":"slide"},{"time":96.9,"duration":0.5,"type":"pop"},{"time":115.64,"duration":0.5,"type":"slide"},{"time":118.12,"duration":0.5,"type":"pop"},{"time":120.09,"duration":0.5,"type":"slide"},{"time":122.62,"duration":0.5,"type":"pop"},{"time":126.21,"duration":0.5,"type":"slide"},{"time":129.8,"duration":0.5,"type":"pop"},{"time":165.71,"duration":0.5,"type":"pop"},{"time":167.86,"duration":0.5,"type":"slide"},{"time":174.66,"duration":0.5,"type":"pop"},{"time":180.3,"duration":0.5,"type":"slide"},{"time":187.79,"duration":0.5,"type":"pop"}],"totalDuration":195.39}',
        NOW() + INTERVAL '2 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        character_name = EXCLUDED.character_name,
        content = EXCLUDED.content,
        audio_url = EXCLUDED.audio_url,
        timeline_data = EXCLUDED.timeline_data;

    INSERT INTO stories (id, mission_id, title, character_name, content, image_url, order_index, audio_url, timeline_data, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000024',
        mission_4_id,
        'سَأُفَكِّرُ... ثُمَّ أَخْتَارُ',
        'port_frontal.glb',
        'مَرْحَبًا يَا صَدِيقِي! /بورت
أَنَا PORT. /بورت
الْيَوْمَ أُرِيدُ أَنْ أَحْكِيَ لَكَ مَوْقِفًا جَعَلَنِي أَتَعَلَّمُ أَنَّ الْقَرَارَ الْجَيِّدَ يَحْتَاجُ إِلَى لَحْظَةِ تَفْكِيرٍ. /بورت
كُنْتُ أَنَا وَMORT وَFORT وَSORT نَلْعَبُ لُعْبَةَ الْبَحْثِ عَنِ الْكَنْزِ. /بورت
وَبَعْدَ قَلِيلٍ وَجَدْنَا طَرِيقَيْنِ. /بورت
الطَّرِيقُ الْأَوَّلُ كَانَ قَصِيرًا جِدًّا، لٰكِنَّهُ مَلِيءٌ بِالطِّينِ. /بورت
أَمَّا الطَّرِيقُ الثَّانِي فَكَانَ أَطْوَلَ قَلِيلًا، لٰكِنَّهُ نَظِيفٌ وَآمِنٌ. /بورت
قَفَزَ FORT بِحَمَاسٍ وَقَالَ: /بورت
"هَيَّا يَا PORT! لِنَأْخُذِ الطَّرِيقَ الْقَصِيرَ، سَنَصِلُ أَوَّلًا!" /فورت
بِصَرَاحَةٍ... /بورت
كِدْتُ أُوَافِقُهُ بِسُرْعَةٍ. /بورت
لٰكِنَّنِي تَذَكَّرْتُ شَيْئًا. /بورت
أَنْ أُفَكِّرَ قَبْلَ أَنْ أَخْتَارَ. /بورت
نَظَرْتُ إِلَى QORT وَقُلْتُ: /بورت
"أَنَا مُحْتَارٌ... أَيَّ طَرِيقٍ أَخْتَارُ؟" /بورت
ابْتَسَمَ QORT وَقَالَ حِكْمَتَهُ الَّتِي لَنْ أَنْسَاهَا: /بورت
"الْقَرَارُ الْجَيِّدُ لَا يُحِبُّ الْعَجَلَةَ... بَلْ يُحِبُّ التَّفْكِيرَ." /كورت
نَظَرْتُ مَرَّةً أُخْرَى إِلَى الطَّرِيقَيْنِ. /بورت
ثُمَّ سَأَلْتُ نَفْسِي: /بورت
"أَيُّهُمَا أَكْثَرُ أَمَانًا؟" /بورت
ابْتَسَمْتُ... /بورت
وَقُلْتُ: /بورت
"سَأَخْتَارُ الطَّرِيقَ الْآمِنَ، حَتَّى لَوِ احْتَاجَ وَقْتًا أَطْوَلَ." /بورت
ابْتَسَمَتْ MORT وَقَالَتْ: /بورت
"أَحْبَبْتُ طَرِيقَتَكَ فِي التَّفْكِيرِ يَا PORT." /مورت
أَمَّا SORT فَقَالَ: /بورت
"الِاخْتِيَارُ الذَّكِيُّ يُوَفِّرُ عَلَيْنَا الْمُشْكِلَاتِ." /سورت
وَضَحِكَ FORT وَقَالَ: /بورت
"أَظُنُّ أَنَّ الْحَمَاسَ جَعَلَنِي أَنْسَى أَنْ أُفَكِّرَ!" /فورت
سِرْنَا فِي الطَّرِيقِ الْآمِنِ. /بورت
وَبَعْدَ قَلِيلٍ... /بورت
رَأَيْنَا آثَارَ أَقْدَامٍ زَلِقَتْ فِي الطَّرِيقِ الْآخَرِ. /بورت
نَظَرَ إِلَيَّ FORT وَقَالَ مُبْتَسِمًا: /بورت
"هٰذِهِ الْمَرَّةَ... كَانَ قَرَارُكَ هُوَ الْأَفْضَلَ." /فورت
ابْتَسَمْتُ... /بورت
وَشَعَرْتُ بِالْفَخْرِ. /بورت
"لَا بَأْسَ... لَقَدْ تَعَلَّمْتُ شَيْئًا جَدِيدًا!" /بورت
"مِنَ الْيَوْمِ... /بورت
سَأُفَكِّرُ أَوَّلًا... ثُمَّ أَخْتَارُ." /بورت
"وَأَنَا أَثِقُ بِكَ." /مورت
"كُلُّ قَرَارٍ صَغِيرٍ... يَرْسُمُ طَرِيقًا جَدِيدًا." /سورت
"الْحَمَاسُ جَمِيلٌ... وَالتَّفْكِيرُ يَجْعَلُهُ أَجْمَلَ." /فورت
"الْقَرَارُ الْجَيِّدُ لَا يُقَاسُ بِسُرْعَتِهِ... بَلْ بِحِكْمَةِ مَنِ اتَّخَذَهُ." /كورت
وَالْآنَ يَا صَدِيقِي... /بورت
هَلْ تُسَاعِدُنِي فِي الْإِجَابَةِ عَنِ الْأَسْئِلَةِ؟ /بورت',
        '',
        1,
        'https://sqvbbsqmwktxuapwivnk.supabase.co/storage/v1/object/public/story_audio/habit_4_voice_1792842414736.wav',
        '{"blocks":[{"characterId":"port","startTime":0,"endTime":2.6},{"characterId":"port","startTime":2.85,"endTime":4.61},{"characterId":"port","startTime":4.86,"endTime":19.3},{"characterId":"port","startTime":19.55,"endTime":28.61},{"characterId":"port","startTime":28.86,"endTime":32.9},{"characterId":"port","startTime":33.15,"endTime":42.16},{"characterId":"port","startTime":42.41,"endTime":52.67},{"characterId":"port","startTime":52.92,"endTime":56.36},{"characterId":"fort","startTime":56.61,"endTime":61.86},{"characterId":"port","startTime":62.11,"endTime":64.11},{"characterId":"port","startTime":64.36,"endTime":67.29},{"characterId":"port","startTime":67.54,"endTime":70.98},{"characterId":"port","startTime":71.23,"endTime":74.9},{"characterId":"port","startTime":75.15,"endTime":78.91},{"characterId":"port","startTime":79.16,"endTime":83.48},{"characterId":"port","startTime":83.73,"endTime":91.86},{"characterId":"qort","startTime":92.11,"endTime":98.84},{"characterId":"port","startTime":99.09,"endTime":103.69},{"characterId":"port","startTime":103.94,"endTime":106.12},{"characterId":"port","startTime":106.37,"endTime":109.39},{"characterId":"port","startTime":109.64,"endTime":111.31},{"characterId":"port","startTime":111.56,"endTime":112.81},{"characterId":"port","startTime":113.06,"endTime":120.49},{"characterId":"port","startTime":120.74,"endTime":124.08},{"characterId":"mort","startTime":124.33,"endTime":128.14},{"characterId":"port","startTime":128.39,"endTime":130.67},{"characterId":"sort","startTime":130.92,"endTime":137.24},{"characterId":"port","startTime":137.49,"endTime":140.09},{"characterId":"fort","startTime":140.34,"endTime":144.15},{"characterId":"port","startTime":144.4,"endTime":147.88},{"characterId":"port","startTime":148.13,"endTime":150.41},{"characterId":"port","startTime":150.66,"endTime":156.93},{"characterId":"port","startTime":157.18,"endTime":161.27},{"characterId":"fort","startTime":161.52,"endTime":164.96},{"characterId":"port","startTime":165.21,"endTime":166.88},{"characterId":"port","startTime":167.13,"endTime":169.45},{"characterId":"port","startTime":169.7,"endTime":174.48},{"characterId":"port","startTime":174.73,"endTime":176.45},{"characterId":"port","startTime":176.7,"endTime":181.3},{"characterId":"mort","startTime":181.55,"endTime":183.45},{"characterId":"sort","startTime":183.7,"endTime":189.83},{"characterId":"fort","startTime":190.08,"endTime":193.84},{"characterId":"qort","startTime":194.09,"endTime":200.92},{"characterId":"port","startTime":201.17,"endTime":203.58},{"characterId":"port","startTime":203.83,"endTime":208.52}],"motionBlocks":[{"motionId":"talk","startTime":0,"endTime":2.6},{"motionId":"talk","startTime":2.85,"endTime":4.61},{"motionId":"thinking","startTime":4.86,"endTime":19.3},{"motionId":"talk","startTime":19.55,"endTime":28.61},{"motionId":"talk","startTime":28.86,"endTime":32.9},{"motionId":"talk","startTime":33.15,"endTime":42.16},{"motionId":"talk","startTime":42.41,"endTime":52.67},{"motionId":"excited","startTime":52.92,"endTime":56.36},{"motionId":"encourage","startTime":56.61,"endTime":61.86},{"motionId":"talk","startTime":62.11,"endTime":64.11},{"motionId":"talk","startTime":64.36,"endTime":67.29},{"motionId":"thinking","startTime":67.54,"endTime":70.98},{"motionId":"talk","startTime":71.23,"endTime":74.9},{"motionId":"talk","startTime":75.15,"endTime":78.91},{"motionId":"confused","startTime":79.16,"endTime":83.48},{"motionId":"smile","startTime":83.73,"endTime":91.86},{"motionId":"talk","startTime":92.11,"endTime":98.84},{"motionId":"talk","startTime":99.09,"endTime":103.69},{"motionId":"talk","startTime":103.94,"endTime":106.12},{"motionId":"talk","startTime":106.37,"endTime":109.39},{"motionId":"smile","startTime":109.64,"endTime":111.31},{"motionId":"talk","startTime":111.56,"endTime":112.81},{"motionId":"talk","startTime":113.06,"endTime":120.49},{"motionId":"smile","startTime":120.74,"endTime":124.08},{"motionId":"talk","startTime":124.33,"endTime":128.14},{"motionId":"talk","startTime":128.39,"endTime":130.67},{"motionId":"talk","startTime":130.92,"endTime":137.24},{"motionId":"laugh","startTime":137.49,"endTime":140.09},{"motionId":"talk","startTime":140.34,"endTime":144.15},{"motionId":"talk","startTime":144.4,"endTime":147.88},{"motionId":"talk","startTime":148.13,"endTime":150.41},{"motionId":"talk","startTime":150.66,"endTime":156.93},{"motionId":"talk","startTime":157.18,"endTime":161.27},{"motionId":"talk","startTime":161.52,"endTime":164.96},{"motionId":"smile","startTime":165.21,"endTime":166.88},{"motionId":"talk","startTime":167.13,"endTime":169.45},{"motionId":"talk","startTime":169.7,"endTime":174.48},{"motionId":"talk","startTime":174.73,"endTime":176.45},{"motionId":"talk","startTime":176.7,"endTime":181.3},{"motionId":"smile","startTime":181.55,"endTime":183.45},{"motionId":"talk","startTime":183.7,"endTime":189.83},{"motionId":"talk","startTime":190.08,"endTime":193.84},{"motionId":"thinking","startTime":194.09,"endTime":200.92},{"motionId":"talk","startTime":201.17,"endTime":203.58},{"motionId":"talk","startTime":203.83,"endTime":208.52}],"hatBlocks":[],"glassesBlocks":[],"musclesBlocks":[],"jumpBlocks":[],"transitions":[{"time":56.61,"duration":0.5,"type":"slide"},{"time":62.11,"duration":0.5,"type":"pop"},{"time":92.11,"duration":0.5,"type":"slide"},{"time":99.09,"duration":0.5,"type":"pop"},{"time":124.33,"duration":0.5,"type":"slide"},{"time":128.39,"duration":0.5,"type":"pop"},{"time":130.92,"duration":0.5,"type":"slide"},{"time":137.49,"duration":0.5,"type":"pop"},{"time":140.34,"duration":0.5,"type":"slide"},{"time":144.4,"duration":0.5,"type":"pop"},{"time":161.52,"duration":0.5,"type":"pop"},{"time":165.21,"duration":0.5,"type":"slide"},{"time":181.55,"duration":0.5,"type":"pop"},{"time":183.7,"duration":0.5,"type":"slide"},{"time":190.08,"duration":0.5,"type":"pop"},{"time":194.09,"duration":0.5,"type":"slide"},{"time":201.17,"duration":0.5,"type":"pop"}],"totalDuration":208.77}',
        NOW() + INTERVAL '3 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        character_name = EXCLUDED.character_name,
        content = EXCLUDED.content,
        audio_url = EXCLUDED.audio_url,
        timeline_data = EXCLUDED.timeline_data;

    INSERT INTO stories (id, mission_id, title, character_name, content, image_url, order_index, audio_url, timeline_data, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000025',
        mission_5_id,
        'هٰذَا خَطَئِي... وَسَأُصْلِحُهُ',
        'port_frontal.glb',
        'مَرْحَبًا يَا صَدِيقِي! /بورت
أَنَا PORT. /بورت
الْيَوْمَ أُرِيدُ أَنْ أَحْكِيَ لَكَ شَيْئًا لَمْ يَكُنْ سَهْلًا بِالنِّسْبَةِ لِي... /بورت
لٰكِنَّهُ عَلَّمَنِي دَرْسًا لَنْ أَنْسَاهُ. /بورت
كُنْتُ أَنَا وَMORT وَFORT وَSORT نَلْعَبُ بِالرَّسْمِ. /بورت
وَكَانَ SORT قَدِ انْتَهَى لِلتَّوِّ مِنْ رَسْمِ خَرِيطَةٍ جَمِيلَةٍ جِدًّا. /بورت
قَالَ وَهُوَ يَبْتَسِمُ: /بورت
"اسْتَغْرَقْتُ وَقْتًا طَوِيلًا حَتَّى أَنْهَيْتُهَا." /سورت
اقْتَرَبْتُ مِنْهَا لِأُشَاهِدَهَا عَنْ قُرْبٍ... /بورت
لٰكِنَّنِي كُنْتُ مُتَحَمِّسًا جِدًّا. /بورت
وَفَجْأَةً... /بورت
دَفَعْتُ كُوبَ الْأَلْوَانِ بِالْمَاءِ دُونَ أَنْ أَنْتَبِهَ. /بورت
انْسَكَبَ الْمَاءُ فَوْقَ الْخَرِيطَةِ كُلِّهَا. /بورت
تَجَمَّدْتُ فِي مَكَانِي... /بورت
وَشَعَرْتُ أَنَّ قَلْبِي يَخْفِقُ بِسُرْعَةٍ. /بورت
قُلْتُ فِي نَفْسِي: /بورت
"مَاذَا أَفْعَلُ الْآنَ؟" /بورت
اقْتَرَبَ FORT بِسُرْعَةٍ وَقَالَ: /بورت
"لَا تَقُلْ شَيْئًا... /فورت
رُبَّمَا لَنْ يَعْرِفَ أَحَدٌ." /فورت
بِصَرَاحَةٍ... كِدْتُ أَفْعَلُ ذٰلِكَ. /بورت
لٰكِنَّنِي تَذَكَّرْتُ أَنَّنِي تَعَلَّمْتُ أَنْ أُفَكِّرَ قَبْلَ أَنْ أَخْتَارَ. /بورت
وَنَظَرْتُ إِلَى QORT. /بورت
ابْتَسَمَ وَقَالَ كَعَادَتِهِ: /بورت
"تَذَكَّرْ يَا PORT... /كورت
الْخَطَأُ لَا يَجْعَلُنَا أَقَلَّ جَمَالًا... /كورت
لٰكِنَّ الْهُرُوبَ مِنْهُ يَمْنَعُنَا مِنَ التَّعَلُّمِ." /كورت
بَقِيتُ أُفَكِّرُ... ثُمَّ أَخَذْتُ نَفَسًا عَمِيقًا. /بورت
وَتَقَدَّمْتُ نَحْوَ SORT. /بورت
وَقُلْتُ: /بورت
"SORT... أَنَا آسِفٌ. أَنَا الَّذِي أَسْقَطَ الْمَاءَ. لَمْ أَقْصِدْ ذٰلِكَ." /بورت
نَظَرَ إِلَيَّ SORT. ثُمَّ ابْتَسَمَ وَقَالَ: /بورت
"شُكْرًا لِأَنَّكَ أَخْبَرْتَنِي بِالْحَقِيقَةِ." /سورت
وَقَالَتْ MORT وَهِيَ تَبْتَسِمُ: /بورت
"وَأَنَا أَثِقُ بِكَ." /مورت
أَمَّا FORT فَحَكَّ رَأْسَهُ وَقَالَ ضَاحِكًا: /بورت
"كُنْتُ أَظُنُّ أَنَّ الِاعْتِرَافَ أَصْعَبُ... لٰكِنَّهُ جَعَلَكَ تَشْعُرُ بِرَاحَةٍ." /فورت
قُلْتُ: /بورت
"صَحِيحٌ... وَأَنَا سَأُسَاعِدُكَ فِي رَسْمِ خَرِيطَةٍ جَدِيدَةٍ." /بورت
ابْتَسَمَ SORT وَقَالَ: /بورت
"إِذَنْ سَتَكُونُ أَجْمَلَ مِنَ الْأُولَى." /سورت
شَعَرْتُ بِرَاحَةٍ كَبِيرَةٍ... لِأَنَّنِي تَحَمَّلْتُ مَسْؤُولِيَّتَهُ. /بورت
"لَا بَأْسَ... لَقَدْ تَعَلَّمْتُ شَيْئًا جَدِيدًا!" /بورت
"مِنَ الْيَوْمِ... /بورت
إِذَا أَخْطَأْتُ... سَأَعْتَرِفُ بِخَطَئِي... وَأُحَاوِلُ إِصْلَاحَهُ." /بورت
"وَأَنَا أَثِقُ بِكَ." /مورت
"لَدَيَّ فِكْرَةٌ... كُلُّ خَطَأٍ يُمْكِنُ أَنْ يُصْبِحَ بِدَايَةً لِشَيْءٍ أَجْمَلَ." /سورت
"هَيَّا! لِنُجَرِّبْ إِصْلَاحَهُ مَعًا!" /فورت
"تَذَكَّرْ يَا PORT... الْمَسْؤُولِيَّةُ لَيْسَتْ أَنْ لَا تُخْطِئَ... بَلْ أَنْ تَعْرِفَ كَيْفَ تَتَصَرَّفُ بَعْدَ الْخَطَأِ." /كورت
وَالْآنَ يَا صَدِيقِي... /بورت
هَلْ تُسَاعِدُنِي فِي الْإِجَابَةِ عَنِ الْأَسْئِلَةِ؟ /بورت',
        '',
        1,
        'https://sqvbbsqmwktxuapwivnk.supabase.co/storage/v1/object/public/story_audio/habit_5_voice_1792842525789.wav',
        '{"blocks":[{"characterId":"port","startTime":0,"endTime":2.6},{"characterId":"port","startTime":2.85,"endTime":4.61},{"characterId":"port","startTime":4.86,"endTime":12.8},{"characterId":"port","startTime":13.05,"endTime":17.32},{"characterId":"port","startTime":17.57,"endTime":24.77},{"characterId":"port","startTime":25.02,"endTime":33.19},{"characterId":"port","startTime":33.44,"endTime":35.85},{"characterId":"sort","startTime":36.1,"endTime":41.53},{"characterId":"port","startTime":41.78,"endTime":50.84},{"characterId":"port","startTime":51.09,"endTime":55.18},{"characterId":"port","startTime":55.43,"endTime":57.01},{"characterId":"port","startTime":57.26,"endTime":63.06},{"characterId":"port","startTime":63.31,"endTime":68.09},{"characterId":"port","startTime":68.34,"endTime":71.17},{"characterId":"port","startTime":71.42,"endTime":75.83},{"characterId":"port","startTime":76.08,"endTime":78.12},{"characterId":"port","startTime":78.37,"endTime":80.78},{"characterId":"port","startTime":81.03,"endTime":85.07},{"characterId":"fort","startTime":85.32,"endTime":86.95},{"characterId":"fort","startTime":87.2,"endTime":89.29},{"characterId":"port","startTime":89.54,"endTime":94.51},{"characterId":"port","startTime":94.76,"endTime":103.21},{"characterId":"port","startTime":103.46,"endTime":105.87},{"characterId":"port","startTime":106.12,"endTime":109.42},{"characterId":"qort","startTime":109.67,"endTime":111.43},{"characterId":"qort","startTime":111.68,"endTime":116.28},{"characterId":"qort","startTime":116.53,"endTime":120.43},{"characterId":"port","startTime":120.68,"endTime":127.27},{"characterId":"port","startTime":127.52,"endTime":130.35},{"characterId":"port","startTime":130.6,"endTime":131.85},{"characterId":"port","startTime":132.1,"endTime":141.76},{"characterId":"port","startTime":142.01,"endTime":147.63},{"characterId":"sort","startTime":147.88,"endTime":151.36},{"characterId":"port","startTime":151.61,"endTime":155.23},{"characterId":"mort","startTime":155.48,"endTime":157.38},{"characterId":"port","startTime":157.63,"endTime":162.55},{"characterId":"fort","startTime":162.8,"endTime":169.16},{"characterId":"port","startTime":169.41,"endTime":170.52},{"characterId":"port","startTime":170.77,"endTime":177.88},{"characterId":"port","startTime":178.13,"endTime":180.64},{"characterId":"sort","startTime":180.89,"endTime":183.54},{"characterId":"port","startTime":183.79,"endTime":191.27},{"characterId":"port","startTime":191.52,"endTime":196.3},{"characterId":"port","startTime":196.55,"endTime":198.27},{"characterId":"port","startTime":198.52,"endTime":207.2},{"characterId":"mort","startTime":207.45,"endTime":209.35},{"characterId":"sort","startTime":209.6,"endTime":218.84},{"characterId":"fort","startTime":219.09,"endTime":221.46},{"characterId":"qort","startTime":221.71,"endTime":231.65},{"characterId":"port","startTime":231.9,"endTime":234.31},{"characterId":"port","startTime":234.56,"endTime":239.25}],"motionBlocks":[{"motionId":"talk","startTime":0,"endTime":2.6},{"motionId":"talk","startTime":2.85,"endTime":4.61},{"motionId":"talk","startTime":4.86,"endTime":12.8},{"motionId":"talk","startTime":13.05,"endTime":17.32},{"motionId":"talk","startTime":17.57,"endTime":24.77},{"motionId":"talk","startTime":25.02,"endTime":33.19},{"motionId":"talk","startTime":33.44,"endTime":35.85},{"motionId":"talk","startTime":36.1,"endTime":41.53},{"motionId":"talk","startTime":41.78,"endTime":50.84},{"motionId":"talk","startTime":51.09,"endTime":55.18},{"motionId":"talk","startTime":55.43,"endTime":57.01},{"motionId":"talk","startTime":57.26,"endTime":63.06},{"motionId":"talk","startTime":63.31,"endTime":68.09},{"motionId":"nervous","startTime":68.34,"endTime":71.17},{"motionId":"nervous","startTime":71.42,"endTime":75.83},{"motionId":"talk","startTime":76.08,"endTime":78.12},{"motionId":"talk","startTime":78.37,"endTime":80.78},{"motionId":"talk","startTime":81.03,"endTime":85.07},{"motionId":"talk","startTime":85.32,"endTime":86.95},{"motionId":"talk","startTime":87.2,"endTime":89.29},{"motionId":"talk","startTime":89.54,"endTime":94.51},{"motionId":"thinking","startTime":94.76,"endTime":103.21},{"motionId":"talk","startTime":103.46,"endTime":105.87},{"motionId":"smile","startTime":106.12,"endTime":109.42},{"motionId":"thinking","startTime":109.67,"endTime":111.43},{"motionId":"talk","startTime":111.68,"endTime":116.28},{"motionId":"talk","startTime":116.53,"endTime":120.43},{"motionId":"talk","startTime":120.68,"endTime":127.27},{"motionId":"talk","startTime":127.52,"endTime":130.35},{"motionId":"talk","startTime":130.6,"endTime":131.85},{"motionId":"talk","startTime":132.1,"endTime":141.76},{"motionId":"smile","startTime":142.01,"endTime":147.63},{"motionId":"talk","startTime":147.88,"endTime":151.36},{"motionId":"talk","startTime":151.61,"endTime":155.23},{"motionId":"smile","startTime":155.48,"endTime":157.38},{"motionId":"laugh","startTime":157.63,"endTime":162.55},{"motionId":"talk","startTime":162.8,"endTime":169.16},{"motionId":"talk","startTime":169.41,"endTime":170.52},{"motionId":"talk","startTime":170.77,"endTime":177.88},{"motionId":"smile","startTime":178.13,"endTime":180.64},{"motionId":"talk","startTime":180.89,"endTime":183.54},{"motionId":"talk","startTime":183.79,"endTime":191.27},{"motionId":"talk","startTime":191.52,"endTime":196.3},{"motionId":"talk","startTime":196.55,"endTime":198.27},{"motionId":"talk","startTime":198.52,"endTime":207.2},{"motionId":"smile","startTime":207.45,"endTime":209.35},{"motionId":"talk","startTime":209.6,"endTime":218.84},{"motionId":"encourage","startTime":219.09,"endTime":221.46},{"motionId":"thinking","startTime":221.71,"endTime":231.65},{"motionId":"talk","startTime":231.9,"endTime":234.31},{"motionId":"talk","startTime":234.56,"endTime":239.25}],"hatBlocks":[],"glassesBlocks":[],"musclesBlocks":[],"jumpBlocks":[],"transitions":[{"time":36.1,"duration":0.5,"type":"pop"},{"time":41.78,"duration":0.5,"type":"slide"},{"time":85.32,"duration":0.5,"type":"slide"},{"time":89.54,"duration":0.5,"type":"slide"},{"time":109.67,"duration":0.5,"type":"slide"},{"time":120.68,"duration":0.5,"type":"pop"},{"time":147.88,"duration":0.5,"type":"slide"},{"time":151.61,"duration":0.5,"type":"pop"},{"time":155.48,"duration":0.5,"type":"slide"},{"time":157.63,"duration":0.5,"type":"pop"},{"time":162.8,"duration":0.5,"type":"slide"},{"time":169.41,"duration":0.5,"type":"pop"},{"time":180.89,"duration":0.5,"type":"slide"},{"time":183.79,"duration":0.5,"type":"pop"},{"time":207.45,"duration":0.5,"type":"pop"},{"time":209.6,"duration":0.5,"type":"slide"},{"time":219.09,"duration":0.5,"type":"pop"},{"time":221.71,"duration":0.5,"type":"slide"},{"time":231.9,"duration":0.5,"type":"pop"}],"totalDuration":239.5}',
        NOW() + INTERVAL '4 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        character_name = EXCLUDED.character_name,
        content = EXCLUDED.content,
        audio_url = EXCLUDED.audio_url,
        timeline_data = EXCLUDED.timeline_data;

    -- 4. Create Questions for each Mission
    -- أسئلة العادة (1)
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000311',
        mission_1_id,
        'لِمَاذَا لَمْ يَقْفِزْ PORT مِنْ فَوْقِ السُّورِ؟',
        '["لِأَنَّهُ شَعَرَ أَنَّ الْقَفْزَ قَدْ يُؤْذِيهِ.","لِأَنَّهُ لَمْ يَعُدْ يُحِبُّ اللَّعِبَ.","لِأَنَّهُ كَانَ يُرِيدُ الْعَوْدَةَ إِلَى الْمَنْزِلِ.","لِأَنَّهُ لَمْ يَكُنْ يُحِبُّ أَصْدِقَاءَهُ."]'::jsonb,
        0,
        NOW() + INTERVAL '0 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000312',
        mission_1_id,
        'مَاذَا سَاعَدَ PORT عَلَى اتِّخَاذِ قَرَارِهِ؟',
        '["تَذَكُّرُ نَصِيحَةِ QORT.","أَغْلَقَ عَيْنَيْهِ وَقَفَزَ.","انْتَظَرَ حَتَّى يَقْفِزَ الْجَمِيعُ.","غَضِبَ مِنْ أَصْدِقَائِهِ."]'::jsonb,
        0,
        NOW() + INTERVAL '1 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000313',
        mission_1_id,
        'مَاذَا فَعَلَ PORT بَعْدَ أَنْ قَالَ "لَا"؟',
        '["بَدَأَ يَصْرُخُ.","اقْتَرَحَ لُعْبَةً أُخْرَى لِيَسْتَمْتِعَ الْجَمِيعُ.","تَرَكَ أَصْدِقَاءَهُ وَغَادَرَ.","تَشَاجَرَ مَعَ FORT."]'::jsonb,
        1,
        NOW() + INTERVAL '2 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000314',
        mission_1_id,
        'مَاذَا تَعَلَّمَ FORT فِي نِهَايَةِ الْقِصَّةِ؟',
        '["أَنَّ مَنْ يَقُولُ \"لَا\" قَدْ يَكُونُ اخْتَارَ الْقَرَارَ الصَّحِيحَ.","أَنَّ الْقَفْزَ دَائِمًا مُمْتِعٌ.","أَنَّ عَلَيْهِ أَنْ يَضْحَكَ عَلَى أَصْدِقَائِهِ.","أَنَّ الْفَوْزَ أَهَمُّ مِنَ السَّلَامَةِ."]'::jsonb,
        0,
        NOW() + INTERVAL '3 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000315',
        mission_1_id,
        'لَوْ كُنْتَ مَكَانَ PORT، وَطَلَبَ مِنْكَ أَحَدٌ أَنْ تَفْعَلَ شَيْئًا تَشْعُرُ أَنَّهُ قَدْ يُؤْذِيكَ، مَاذَا سَتَفْعَلُ؟',
        '["سَأُوَافِقُ حَتَّى لَا يَضْحَكَ عَلَيَّ أَحَدٌ.","سَأَقُولُ \"لَا\" بِهُدُوءٍ، وَأَقْتَرِحُ شَيْئًا أَفْضَلَ.","سَأُقَلِّدُ الْجَمِيعَ دُونَ تَفْكِيرٍ.","سَأَغْضَبُ وَأَصْرُخُ."]'::jsonb,
        1,
        NOW() + INTERVAL '4 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    -- أسئلة العادة (2)
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000321',
        mission_2_id,
        'لِمَاذَا بَقِيَ PORT صَامِتًا فِي الْبِدَايَةِ؟',
        '["لِأَنَّهُ كَانَ خَجُولًا وَظَنَّ أَنَّ رَأْيَهُ قَدْ يُزْعِجُ الْآخَرِينَ.","لِأَنَّهُ لَمْ يَكُنْ يُرِيدُ اللَّعِبَ.","لِأَنَّهُ كَانَ غَاضِبًا مِنْ أَصْدِقَائِهِ.","لِأَنَّهُ أَرَادَ الْعَوْدَةَ إِلَى الْمَنْزِلِ."]'::jsonb,
        0,
        NOW() + INTERVAL '5 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000322',
        mission_2_id,
        'مَاذَا قَالَ QORT لِـ PORT؟',
        '["يَجِبُ أَنْ تُوَافِقَ الْجَمِيعَ دَائِمًا.","الرَّأْيُ الْمُهَذَّبُ لَا يُزْعِجُ أَحَدًا، بَلْ يُسَاعِدُ الْجَمِيعَ عَلَى أَنْ يَفْهَمُوا بَعْضَهُمْ.","لَا تَتَحَدَّثْ كَثِيرًا.","اتْرُكِ اللَّعِبَ."]'::jsonb,
        1,
        NOW() + INTERVAL '6 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000323',
        mission_2_id,
        'مَاذَا فَعَلَ PORT بَعْدَ كَلَامِ QORT؟',
        '["بَقِيَ صَامِتًا.","تَشَاجَرَ مَعَ أَصْدِقَائِهِ.","اقْتَرَحَ أَنْ يَلْعَبُوا لُعْبَتَيْنِ.","ذَهَبَ لِلَّعِبِ وَحْدَهُ."]'::jsonb,
        2,
        NOW() + INTERVAL '7 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000324',
        mission_2_id,
        'كَيْفَ اسْتَقْبَلَ أَصْدِقَاءُ PORT رَأْيَهُ؟',
        '["غَضِبُوا مِنْهُ.","سَخِرُوا مِنْهُ.","اسْتَمَعُوا إِلَيْهِ وَأَعْجَبَتْهُمْ فِكْرَتُهُ.","تَجَاهَلُوهُ."]'::jsonb,
        2,
        NOW() + INTERVAL '8 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000325',
        mission_2_id,
        'لَوْ كُنْتَ مَكَانَ PORT، وَأَرَدْتَ أَنْ تَقْتَرِحَ فِكْرَةً مُخْتَلِفَةً، مَاذَا سَتَفْعَلُ؟',
        '["سَأَبْقَى صَامِتًا دَائِمًا.","سَأَقُولُ رَأْيِي بِأَدَبٍ وَاحْتِرَامٍ.","سَأَغْضَبُ حَتَّى يَسْمَعَنِي الْجَمِيعُ.","سَأُوَافِقُ حَتَّى لَوْ لَمْ تُعْجِبْنِي الْفِكْرَةُ."]'::jsonb,
        1,
        NOW() + INTERVAL '9 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    -- أسئلة العادة (3)
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000331',
        mission_3_id,
        'لِمَاذَا لَمْ يَبْدَأْ PORT بِبِنَاءِ الْبُرْجِ فِي الْبِدَايَةِ؟',
        '["لِأَنَّهُ كَانَ يَظُنُّ أَنَّهُ لَنْ يَنْجَحَ.","لِأَنَّهُ لَمْ يُحِبَّ الْمُكَعَّبَاتِ.","لِأَنَّهُ كَانَ يُرِيدُ الذَّهَابَ إِلَى الْمَنْزِلِ.","لِأَنَّهُ كَانَ غَاضِبًا مِنْ أَصْدِقَائِهِ."]'::jsonb,
        0,
        NOW() + INTERVAL '10 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000332',
        mission_3_id,
        'مَاذَا قَالَ QORT لِـ PORT؟',
        '["دَعْ غَيْرَكَ يَبْنِي.","هَلْ وُلِدْتَ وَأَنْتَ تَعْرِفُ كَيْفَ تَبْنِي الْأَبْرَاجَ؟","لَا تُحَاوِلْ حَتَّى لَا تُخْطِئَ.","الْبُرْجُ لَيْسَ مُهِمًّا."]'::jsonb,
        1,
        NOW() + INTERVAL '11 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000333',
        mission_3_id,
        'مَاذَا فَعَلَ PORT بَعْدَ كَلَامِ QORT؟',
        '["بَقِيَ يُشَاهِدُ فَقَطْ.","بَدَأَ يَضَعُ الْمُكَعَّبَاتِ وَاحِدَةً تِلْوَ الْأُخْرَى.","غَضِبَ وَرَمَى الْمُكَعَّبَاتِ.","طَلَبَ مِنْ FORT أَنْ يَبْنِيَ مَكَانَهُ."]'::jsonb,
        1,
        NOW() + INTERVAL '12 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000334',
        mission_3_id,
        'كَيْفَ شَعَرَ PORT عِنْدَمَا انْتَهَى مِنْ بِنَاءِ بُرْجِهِ؟',
        '["شَعَرَ بِالْفَخْرِ لِأَنَّهُ حَاوَلَ وَتَعَلَّمَ.","شَعَرَ بِالْحُزْنِ.","شَعَرَ بِالْغَضَبِ.","شَعَرَ بِالْخَوْفِ."]'::jsonb,
        0,
        NOW() + INTERVAL '13 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000335',
        mission_3_id,
        'لَوْ كُنْتَ مَكَانَ PORT، وَوَجَدْتَ شَيْئًا جَدِيدًا لَمْ تُجَرِّبْهُ مِنْ قَبْلُ، مَاذَا سَتَفْعَلُ؟',
        '["سَأَقُولُ: لَا أَسْتَطِيعُ، قَبْلَ أَنْ أُجَرِّبَ.","سَأُجَرِّبُ بِهُدُوءٍ، وَأَتَعَلَّمُ خُطْوَةً بَعْدَ خُطْوَةٍ.","سَأَطْلُبُ مِنْ غَيْرِي أَنْ يَفْعَلَهُ دَائِمًا.","سَأَتْرُكُهُ لِأَنَّنِي قَدْ أُخْطِئُ."]'::jsonb,
        1,
        NOW() + INTERVAL '14 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    -- أسئلة العادة (4)
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000341',
        mission_4_id,
        'لِمَاذَا لَمْ يَخْتَرْ PORT الطَّرِيقَ الْقَصِيرَ مُبَاشَرَةً؟',
        '["لِأَنَّهُ تَوَقَّفَ لِيُفَكِّرَ أَيُّ الطَّرِيقَيْنِ أَكْثَرُ أَمَانًا.","لِأَنَّهُ تَعِبَ مِنَ الْمَشْيِ.","لِأَنَّهُ لَمْ يَعُدْ يُرِيدُ اللَّعِبَ.","لِأَنَّهُ نَسِيَ الطَّرِيقَ."]'::jsonb,
        0,
        NOW() + INTERVAL '15 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000342',
        mission_4_id,
        'مَاذَا قَالَ QORT لِـ PORT؟',
        '["اخْتَرْ بِسُرْعَةٍ.","الْقَرَارُ الْجَيِّدُ لَا يُحِبُّ الْعَجَلَةَ... بَلْ يُحِبُّ التَّفْكِيرَ.","اتَّبِعِ الْآخَرِينَ دَائِمًا.","لَا تَخْتَرْ أَيَّ طَرِيقٍ."]'::jsonb,
        1,
        NOW() + INTERVAL '16 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000343',
        mission_4_id,
        'لِمَاذَا اخْتَارَ PORT الطَّرِيقَ الثَّانِيَ؟',
        '["لِأَنَّهُ كَانَ الْأَقْصَرَ.","لِأَنَّهُ كَانَ أَكْثَرَ أَمَانًا.","لِأَنَّهُ أَجْمَلُ.","لِأَنَّهُ كَانَ فَارِغًا."]'::jsonb,
        1,
        NOW() + INTERVAL '17 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000344',
        mission_4_id,
        'مَاذَا تَعَلَّمَ FORT فِي نِهَايَةِ الْقِصَّةِ؟',
        '["أَنَّ الْحَمَاسَ وَحْدَهُ لَا يَكْفِي، وَيَجِبُ أَنْ نُفَكِّرَ قَبْلَ أَنْ نَخْتَارَ.","أَنَّ الطَّرِيقَ الْقَصِيرَ دَائِمًا أَفْضَلُ.","أَنْ يُقَلِّدَ PORT فِي كُلِّ شَيْءٍ.","أَنْ يَتَوَقَّفَ عَنِ اللَّعِبِ."]'::jsonb,
        0,
        NOW() + INTERVAL '18 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000345',
        mission_4_id,
        'لَوْ كُنْتَ مَكَانَ PORT، وَوَجَدْتَ أَمَامَكَ أَكْثَرَ مِنْ اخْتِيَارٍ، مَاذَا سَتَفْعَلُ؟',
        '["سَأَخْتَارُ بِسُرْعَةٍ دُونَ تَفْكِيرٍ.","سَأُقَلِّدُ أَوَّلَ شَخْصٍ أَمَامِي.","سَأُفَكِّرُ بِهُدُوءٍ، ثُمَّ أَخْتَارُ مَا أَرَاهُ مُنَاسِبًا.","سَأَتْرُكُ غَيْرِي يُقَرِّرُ عَنِّي دَائِمًا."]'::jsonb,
        2,
        NOW() + INTERVAL '19 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    -- أسئلة العادة (5)
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000351',
        mission_5_id,
        'مَاذَا حَدَثَ لِخَرِيطَةِ SORT؟',
        '["انْسَكَبَ عَلَيْهَا الْمَاءُ بِالْخَطَأِ.","ضَاعَتْ فِي الْحَدِيقَةِ.","أَخَذَهَا FORT.","مَزَّقَتْهَا MORT."]'::jsonb,
        0,
        NOW() + INTERVAL '20 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000352',
        mission_5_id,
        'مَاذَا اقْتَرَحَ FORT؟',
        '["أَنْ يَعْتَرِفَ PORT مُبَاشَرَةً.","أَلَّا يَقُولَ PORT شَيْئًا.","أَنْ يَرْسُمَ خَرِيطَةً جَدِيدَةً فَوْرًا.","أَنْ يُغَادِرَ الْمَكَانَ."]'::jsonb,
        1,
        NOW() + INTERVAL '21 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000353',
        mission_5_id,
        'مَاذَا قَالَ QORT؟',
        '["تَذَكَّرْ يَا PORT... الْخَطَأُ لَا يَجْعَلُنَا أَقَلَّ جَمَالًا... لٰكِنَّ الْهُرُوبَ مِنْهُ يَمْنَعُنَا مِنَ التَّعَلُّمِ.","لَا تُخْبِرْ أَحَدًا.","لَا بَأْسَ... انْسَ الْأَمْرَ.","لَيْسَ مُهِمًّا."]'::jsonb,
        0,
        NOW() + INTERVAL '22 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000354',
        mission_5_id,
        'مَاذَا فَعَلَ PORT بَعْدَ أَنِ اعْتَرَفَ؟',
        '["تَرَكَ SORT وَحْدَهُ.","سَاعَدَ SORT فِي رَسْمِ خَرِيطَةٍ جَدِيدَةٍ.","غَضِبَ.","عَادَ لِلَّعِبِ مُبَاشَرَةً."]'::jsonb,
        1,
        NOW() + INTERVAL '23 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;
    INSERT INTO questions (id, mission_id, question_text, options, correct_answer_index, created_at)
    VALUES (
        'a1000000-0000-4000-8000-000000000355',
        mission_5_id,
        'لَوْ أَخْطَأْتَ يَوْمًا دُونَ قَصْدٍ، مَاذَا سَتَفْعَلُ؟',
        '["سَأُخْفِي الْخَطَأَ.","سَأَجْعَلُ غَيْرِي يَتَحَمَّلُ الْمَسْؤُولِيَّةَ.","سَأَعْتَرِفُ بِخَطَئِي، وَأُحَاوِلُ إِصْلَاحَهُ.","سَأَهْرُبُ."]'::jsonb,
        2,
        NOW() + INTERVAL '24 seconds'
    )
    ON CONFLICT (id) DO UPDATE SET
        question_text = EXCLUDED.question_text,
        options = EXCLUDED.options,
        correct_answer_index = EXCLUDED.correct_answer_index;

END $$;
