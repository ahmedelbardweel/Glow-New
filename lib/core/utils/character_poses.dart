/// Static poses of the Tripo character sheet, one `Pose_<id>` node each.
///
/// The file is served next to the web build (`web/character_poses/`), so it
/// does not enlarge the mobile app bundle.
class CharacterPose {
  const CharacterPose(this.id, this.label);
  final String id;
  final String label;

  String get nodeName => 'Pose_$id';
}

/// The new rigged Glow, served beside the web build like the pose sheet.
class CharacterRig {
  static const modelPath = 'character_rig/glow_rigged.glb';

  /// Bundled copy the phone player loads. The web studio uses [modelPath].
  static const assetPath = 'assets/3d/glow_rigged.glb';

  /// Linear luminance of the baked atlas green, for [CharacterSkinPalette].
  static const skinLuminance = 0.106;
}

class CharacterPoses {
  static const modelPath = 'character_poses/glow_poses.glb';

  /// Linear luminance of the sheet's original green skin.
  static const skinLuminance = 0.036;

  static const all = <CharacterPose>[
    CharacterPose('front', 'أمامي'),
    CharacterPose('power', 'قوة'),
    CharacterPose('power_2', 'قوة ٢'),
    CharacterPose('front_2', 'أمامي ٢'),
    CharacterPose('back', 'من الخلف'),
    CharacterPose('neutral', 'محايد'),
    CharacterPose('victorious', 'منتصر'),
    CharacterPose('happy', 'سعيد'),
    CharacterPose('laughing', 'ضاحك'),
    CharacterPose('excited', 'متحمس جدا'),
    CharacterPose('curious', 'فضولي'),
    CharacterPose('thinking', 'يفكر'),
    CharacterPose('cheer', 'تشجيع قوي'),
    CharacterPose('celebrate', 'احتفال بالفوز'),
    CharacterPose('frustrated', 'محبط'),
    CharacterPose('nervous', 'متوتر'),
    CharacterPose('confused', 'مرتبك'),
    CharacterPose('final_win', 'الفوز النهائي'),
  ];
}
