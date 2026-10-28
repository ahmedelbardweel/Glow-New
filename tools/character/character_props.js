export const PROP_GROUPS=['StarTrophy','CupTrophy','ExcitementFX','CuriosityFX','ConfusionFX','SweatFX','VictoryFX','ConfettiFX'];
// A zero scale still submits draw calls. Cull entire inactive effect groups.
export class CharacterProps {
  constructor(model){this.groups=PROP_GROUPS.map(name=>model.getObjectByName(name)).filter(Boolean);this.update();}
  update(){for(const group of this.groups)group.visible=group.scale.lengthSq()>1e-8;}
}
