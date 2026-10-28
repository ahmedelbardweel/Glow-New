// Skin repairs must share skin shading. EyeSocketSkin/EyeLids are not eyeballs.
// Leave authored metal, felt and prop materials intact.
export function applyCharacterSurface(object) {
  if(!object.isMesh)return;
  const skin=['Body','Scalp','EyeSocketSkin','EyeLids'].includes(object.name);
  const eye=['EyeLeft','EyeRight'].includes(object.name);
  const glasses=object.name==='Glasses';
  const mouth=object.name==='ExpressiveMouth';
  for(const material of [object.material].flat().filter(Boolean)) {
    if(!material.isMeshStandardMaterial)continue;
    if(skin){material.roughness=.64;material.metalness=0;material.roughnessMap=null;material.envMapIntensity=.8;}
    else if(eye){material.roughness=.17;material.metalness=0;material.envMapIntensity=1;}
    else if(glasses){material.roughness=.30;material.metalness=.06;material.envMapIntensity=1;}
    else if(mouth){material.roughness=.56;material.metalness=0;material.envMapIntensity=.6;}
    material.needsUpdate=true;
  }
}
