// Capture the actual Three.js PBR test page after GLB/image decoding finishes.
import {spawn} from 'node:child_process';
import fs from 'node:fs/promises';
import path from 'node:path';
const [output,url='http://127.0.0.1:8874/tools/character/tripo/head_material_review.html']=process.argv.slice(2);
if(!output)throw new Error('Usage: node capture_material_review.mjs output.png [url]');
const browser=spawn('C:/Program Files/Google/Chrome/Application/chrome.exe',[
  '--headless=new','--no-first-run','--no-default-browser-check','--disable-extensions',
  '--use-angle=swiftshader','--enable-unsafe-swiftshader','--hide-scrollbars',
  '--remote-debugging-port=0','--remote-debugging-address=127.0.0.1',
  `--user-data-dir=${path.resolve('build/tripo/hat_review/chrome-capture-'+process.pid+'-'+Date.now())}`,'about:blank',
],{windowsHide:true,stdio:['ignore','ignore','pipe']});
let socket;
try{
  const endpoint=await new Promise((resolve,reject)=>{
    const timer=setTimeout(()=>reject(new Error('Browser did not start')),15000);
    let log='';browser.stderr.on('data',data=>{log+=data;const match=log.match(/DevTools listening on (ws:\/\/[^\s]+)/);if(match){clearTimeout(timer);resolve(match[1]);}});
    browser.once('error',reject);
  });
  socket=new WebSocket(endpoint);
  await new Promise((resolve,reject)=>{socket.onopen=resolve;socket.onerror=reject;});
  let id=0;const pending=new Map();
  socket.onmessage=event=>{const data=JSON.parse(event.data);if(data.method==='Runtime.exceptionThrown')console.error(JSON.stringify(data.params.exceptionDetails));if(data.method==='Log.entryAdded'&&data.params.entry.level==='error')console.error(data.params.entry.text);if(data.id){const task=pending.get(data.id);pending.delete(data.id);data.error?task.reject(new Error(JSON.stringify(data.error))):task.resolve(data.result);}};
  const call=(method,params={},sessionId)=>new Promise((resolve,reject)=>{const request=++id;pending.set(request,{resolve,reject});socket.send(JSON.stringify({id:request,method,params,sessionId}));});
  const {targetId}=await call('Target.createTarget',{url:'about:blank'});
  const {sessionId}=await call('Target.attachToTarget',{targetId,flatten:true});
  await call('Runtime.enable',{},sessionId);
  await call('Log.enable',{},sessionId);
  const studio=process.argv.includes('--studio');
  await call('Emulation.setDeviceMetricsOverride',{width:studio?1400:process.argv.includes('--sheet')?1600:800,height:studio?1000:process.argv.includes('--sheet')?1600:800,deviceScaleFactor:1,mobile:false},sessionId);
  await call('Page.navigate',{url},sessionId);
  let ready=false;
  for(let n=0;n<180;n++){
    const result=await call('Runtime.evaluate',{expression:studio?"document.querySelector('flt-glass-pane') ? 'Ready' : document.title":'document.title',returnByValue:true},sessionId);
    if(result.result?.value?.startsWith('Ready')){ready=true;break;}
    await new Promise(resolve=>setTimeout(resolve,200));
  }
  if(!ready){const status=await call('Runtime.evaluate',{expression:'JSON.stringify({url:location.href,title:document.title})',returnByValue:true},sessionId);throw new Error('Three.js review did not finish loading: '+status.result?.value);}
  if(process.argv.includes('--mobile')) {
    const result=await call('Runtime.evaluate',{awaitPromise:true,returnByValue:true,expression:`(async()=>{
      const ready=mobileMessages.find(m=>m.type==='ready');
      if(!ready||ready.clips.length!==20)throw Error('Missing mobile clips');
      for(const motion of ready.clips){
        GlowViewer.update({motion,playing:false,hat:true,glasses:true});
        await new Promise(r=>setTimeout(r,60));
      }
      GlowViewer.update({visible:false});
      await new Promise(r=>setTimeout(r,100));
      GlowViewer.update({visible:true,playing:true,motion:'UltimateWin',color:'#4a90b8',originalGreen:false,hat:false,glasses:false});
      await new Promise(r=>setTimeout(r,1000));
      const errors=mobileMessages.filter(m=>m.type==='error'||m.type==='localLoadFailed');
      if(errors.length)throw Error(JSON.stringify(errors));
      return {clips:ready.clips,triangles:ready.triangles,bridgeControls:true,suspendResume:true};
    })()`},sessionId);
    if(result.exceptionDetails)throw Error(JSON.stringify(result.exceptionDetails));
    await fs.writeFile(output+'.mobile-checks.json',JSON.stringify(result.result.value,null,2));
    console.log(JSON.stringify(result.result.value));
  }
  if(studio){
    await new Promise(resolve=>setTimeout(resolve,15000));
    await call('Runtime.evaluate',{expression:"document.querySelector('flt-semantics-placeholder')?.click()"},sessionId);
    await new Promise(resolve=>setTimeout(resolve,1500));
    const loaded=await call('Page.captureScreenshot',{format:'png'},sessionId);
    await fs.writeFile(output+'.loaded.png',Buffer.from(loaded.data,'base64'));
    const controls=await call('Runtime.evaluate',{returnByValue:true,expression:`(()=>{
      const nodes=[...document.querySelectorAll('[aria-label],flt-semantics')];
      const label=e=>(e.getAttribute('aria-label')||e.textContent).trim();
      const labels=nodes.map(label).filter(v=>v.length<100);
      const sequence=nodes.find(e=>label(e)==='تشغيل حركات الصورة بالتتابع');
      if(!sequence)throw Error('Sequence control missing: '+JSON.stringify(labels));
      sequence.click();return labels;
    })()`},sessionId);
    if(controls.exceptionDetails)throw Error(JSON.stringify(controls.exceptionDetails));
    await new Promise(resolve=>setTimeout(resolve,5000));
    const selected=await call('Runtime.evaluate',{returnByValue:true,expression:`(()=>{
      const button=[...document.querySelectorAll('[aria-label],flt-semantics')].find(e=>(e.getAttribute('aria-label')||e.textContent).trim()==='الفوز النهائي');
      if(!button)throw Error('Final win control missing');button.click();return true;
    })()`},sessionId);
    if(selected.exceptionDetails)throw Error(JSON.stringify(selected.exceptionDetails));
    await new Promise(resolve=>setTimeout(resolve,2000));
    await fs.writeFile(output+'.studio-checks.json',JSON.stringify({sequenceControl:true,ultimateWinSelected:true,labels:controls.result.value},null,2));
    console.log('Studio sequence and final-win controls verified');
  }
  if(process.argv.includes('--probe-mouth')){
    const hits=await call('Runtime.evaluate',{expression:'[probeMouth(620,432),probeMouth(620,445),probeMouth(630,455)]',returnByValue:true},sessionId);console.log(JSON.stringify(hits.result.value));
  }
  if(process.argv.includes('--verify-controls')){
    const checks=await call('Runtime.evaluate',{awaitPromise:true,returnByValue:true,expression:`(async()=>{
      const p=window.glowReviewPanels.find(p=>p.id==='after'),model=p.model;
      const assert=(ok,message)=>{if(!ok)throw Error(message)};
      const checkbox=(id,value)=>{const el=document.getElementById(id);el.checked=value;el.dispatchEvent(new Event('change'))};
      const slider=document.getElementById('blink');
      const closure=value=>{slider.value=value;slider.dispatchEvent(new Event('input'))};
      const frame=model.getObjectByName('Glasses'),hat=model.getObjectByName('Hat');
      const eyes=['EyeLeft','EyeRight'].map(name=>model.getObjectByName(name));
      const lids=model.getObjectByName('EyeLids');
      if(document.getElementById('play').textContent==='Pause')document.getElementById('play').click();
      const action=p.action,time=action.time;
      checkbox('glasses',false);assert(!frame.visible,'Frame did not hide');
      assert(eyes.every(e=>e.visible),'Eye disappeared with glasses');
      checkbox('hat',true);assert(hat.visible&&!frame.visible,'Hat and glasses are coupled');
      checkbox('glasses',true);assert(frame.visible&&hat.visible,'Frame did not return');
      assert(p.action===action&&action.time===time,'Accessory toggle reset motion');
      closure(1);assert(lids.visible&&lids.morphTargetInfluences.every((x,i)=>Math.abs(x-(i%2))<1e-8),'Lids do not close');
      closure(0);assert(lids.visible&&lids.morphTargetInfluences.every(x=>x===0),'Open eyelid rim is missing');
      const peaks=[];for(let i=0;i<160;i++){p.eyes.update(.02,'Wave');peaks.push(Math.max(...lids.morphTargetInfluences));}
      assert(Math.max(...peaks)>.9&&Math.min(...peaks)<.01,'Automatic blink did not close and reopen');
      assert(eyes.every(e=>e.parent.name==='Head')&&lids.parent.name==='Head','Eyes are not attached to head');
      closure(0);checkbox('hat',false);checkbox('autoBlink',true);
      await new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve)));
      return {glassesToggle:true,hatIndependent:true,eyesRemainVisible:true,motionPreserved:true,manualBlink:true,automaticBlink:true,headAttachment:true};
    })()`},sessionId);
    if(checks.exceptionDetails)throw new Error(JSON.stringify(checks.exceptionDetails));
    await fs.writeFile(output+'.checks.json',JSON.stringify(checks.result.value,null,2));
    console.log(JSON.stringify(checks.result.value));
  }
  if(process.argv.includes('--verify-mouth')){
    const checks=await call('Runtime.evaluate',{returnByValue:true,expression:`(()=>{
      const p=window.glowReviewPanels.find(p=>p.id==='after');
      const mouth=p.model.getObjectByName('ExpressiveMouth');
      const assert=(ok,msg)=>{if(!ok)throw Error(msg)};
      assert(mouth?.parent.name==='Head','Mouth detached from head');
      if(document.getElementById('play').textContent==='Pause')document.getElementById('play').click();
      const snapshots={};let samples=0;
      for(const clip of p.clips){
        p.mixer.stopAllAction();const action=p.mixer.clipAction(clip).reset().play();
        snapshots[clip.name]=[];
        for(let i=0;i<31;i++){
          action.time=clip.duration*i/31;p.mixer.update(0);
          const w=[...mouth.morphTargetInfluences];
          assert(w.length===4&&w.every(v=>Number.isFinite(v)&&v>=0&&v<=1.001),'Invalid mouth weights');
          snapshots[clip.name].push(w);samples++;
        }
      }
      assert(snapshots.Talk.some(w=>w[0]>.6)&&snapshots.Talk.some(w=>w[0]<.02),'Speech does not open and close');
      assert(snapshots.Smile.every(w=>w[1]>.9),'Smile missing');
      assert(snapshots.Sad.every(w=>w[2]>.9&&w[0]===0),'Sad mouth missing');
      assert(snapshots.Idle.every(w=>w[0]===0),'Idle mouth does not close');
      const parts=['Body','ExpressiveMouth','MouthTeeth','MouthTongue'].map(name=>p.model.getObjectByName(name));
      assert(parts.every(Boolean),'Missing mouth part');
      for(const clip of p.clips){
        p.mouth.update(0,clip.name,true,.63);
        assert(parts.every(part=>part.morphTargetInfluences.every((v,i)=>Math.abs(v-parts[0].morphTargetInfluences[i])<1e-7)),'Mouth parts out of sync');
      }
      p.blend.clear();
      p.mixer.stopAllAction();
      const select=document.getElementById('clip');select.value='Talk';select.dispatchEvent(new Event('change'));
      const seek=document.getElementById('time');seek.value=.08;seek.dispatchEvent(new Event('input'));
      return {headAttached:true,openClose:true,smile:true,sad:true,idleClosed:true,clips:p.clips.length,samples};
    })()`},sessionId);
    if(checks.exceptionDetails)throw Error(JSON.stringify(checks.exceptionDetails));
    await fs.writeFile(output+'.mouth-checks.json',JSON.stringify(checks.result.value,null,2));
    console.log(JSON.stringify(checks.result.value));
    await new Promise(resolve=>setTimeout(resolve,100));
  }
  if(process.argv.includes('--verify-motions')){
    const checks=await call('Runtime.evaluate',{awaitPromise:true,returnByValue:true,expression:`(async()=>{
      const p=window.glowReviewPanels.find(p=>p.id==='after'),select=document.getElementById('clip');
      const assert=(v,m)=>{if(!v)throw Error(m)},wait=ms=>new Promise(r=>setTimeout(r,ms));
      const play=document.getElementById('play'),sequence=document.getElementById('sequence');
      if(play.textContent==='Pause')play.click();
      assert(select.options.length===20&&p.clips.length===20,'Missing motions');
      const renderCalls=()=>{p.renderer.render(p.scene,p.camera);return p.renderer.info.render.calls;};
      select.value='Idle';select.dispatchEvent(new Event('change'));
      p.props.groups.forEach(g=>g.visible=true);const submitted=renderCalls();
      p.props.update();const culled=renderCalls();
      assert(culled<submitted,'Inactive effects still submit draw calls');
      for(const name of ['Body','Scalp','EyeLids','EyeSocketSkin'])assert(Math.abs(p.model.getObjectByName(name).material.roughness-.64)<1e-6,'Skin shading mismatch: '+name);
      assert(p.model.getObjectByName('CupBowl').material.metalness>.5,'Gold material overwritten');
      for(const name of ['CupTrophy','StarTrophy'])assert(p.model.getObjectByName(name).parent.name==='LeftHand','Trophy not attached to hand');
      const props={StarTrophy:'WinCelebration',CupTrophy:'UltimateWin',ConfettiFX:'UltimateWin',CuriosityFX:'Curious',ConfusionFX:'Confused',SweatFX:'Nervous',ExcitementFX:'Excited',VictoryFX:'Victory'};
      for(const option of select.options){
        select.value=option.value;select.dispatchEvent(new Event('change'));
        assert(p.action.getClip().name===option.value,'Wrong selected clip');
        assert(p.blend.weights.size===1,'Paused selection left outgoing action');
        for(const [name,motion] of Object.entries(props))assert(Math.abs(p.model.getObjectByName(name).scale.x-(motion===option.value?1:0))<1e-5,'Leaked prop '+name);
      }
      sequence.click();await wait(80);assert(select.value==='PowerPose','Sequence did not start');
      for(let i=0;i<40&&select.value==='PowerPose';i++)await wait(250);
      assert(select.value==='Neutral','Sequence did not advance');
      play.click();const time=p.action.time,selected=select.value;await wait(120);
      assert(p.action.time===time&&select.value===selected,'Pause did not freeze');
      sequence.click();select.value='UltimateWin';select.dispatchEvent(new Event('change'));
      return {clips:20,referenceSequence:true,pauseFreezes:true,propsIsolated:true,pausedSelection:true,consistentSkin:true,goldPreserved:true,trophiesAttached:true,idleDrawCalls:culled,unculledDrawCalls:submitted};
    })()`},sessionId);
    if(checks.exceptionDetails)throw Error(JSON.stringify(checks.exceptionDetails));
    await fs.writeFile(output+'.motion-checks.json',JSON.stringify(checks.result.value,null,2));
    console.log(JSON.stringify(checks.result.value));
  }
  if(process.argv.includes('--verify-palette')){
    const result=await call('Runtime.evaluate',{returnByValue:true,expression:`(()=>{
      const p=window.glowReviewPanels.find(p=>p.id==='after');
      const assert=(ok,msg)=>{if(!ok)throw Error(msg)};
      if(document.getElementById('play').textContent==='Pause')document.getElementById('play').click();
      const model=p.model,action=p.action,clipTime=action.time;
      for(const name of ['Body','Scalp','EyeSocketSkin','EyeLids']){
        const mesh=model.getObjectByName(name);
        assert(mesh.geometry.getAttribute('_glow_skin_region'),'Missing skin region: '+name);
        assert(mesh.material.customProgramCacheKey().startsWith('glow-skin-palette-'),'Missing color shader: '+name);
      }
      const eye=model.getObjectByName('EyeLeft'),uv=eye.geometry.getAttribute('uv'),mask=eye.geometry.getAttribute('_glow_skin_region');
      for(let i=0;i<uv.count;i++){
        const r=Math.hypot(uv.getX(i)*2-1,uv.getY(i)*2-1);
        if(r<.7)assert(mask.getX(i)===0,'Iris can be recolored');
        if(r>.9)assert(mask.getX(i)===1,'Eye skin rim missing');
      }
      const select=document.getElementById('character'),snapshots=[];
      for(const key of ['port','fort','lort','mort','qort','sort']){
        select.value=key;select.dispatchEvent(new Event('change'));
        assert(p.palette.strength.value===(key==='port'?0:1),'Wrong color strength');
        p.renderer.render(p.scene,p.camera);
        const gl=p.renderer.getContext(),w=gl.drawingBufferWidth,h=gl.drawingBufferHeight,pixels=new Uint8Array(w*h*4);
        gl.readPixels(0,0,w,h,gl.RGBA,gl.UNSIGNED_BYTE,pixels);
        assert(gl.getError()===0,'WebGL palette error');snapshots.push(pixels);
        assert(p.model===model&&p.action===action&&action.time===clipTime,'Color reset animation');
      }
      for(let n=1;n<snapshots.length;n++){
        let changed=0;for(let i=0;i<snapshots[n].length;i+=4)if(Math.abs(snapshots[n][i]-snapshots[0][i])+Math.abs(snapshots[n][i+1]-snapshots[0][i+1])+Math.abs(snapshots[n][i+2]-snapshots[0][i+2])>15)changed++;
        assert(changed>500,'Character color did not render');
      }
      select.value='qort';select.dispatchEvent(new Event('change'));p.renderer.render(p.scene,p.camera);
      return {colors:6,headAndLidsCovered:true,irisProtected:true,renderedColorsDistinct:true,motionPreserved:true};
    })()`},sessionId);
    if(result.exceptionDetails)throw Error(JSON.stringify(result.exceptionDetails));
    await fs.writeFile(output+'.palette-checks.json',JSON.stringify(result.result.value,null,2));
    console.log(JSON.stringify(result.result.value));
  }
  const shot=await call('Page.captureScreenshot',{format:'png'},sessionId);
  await fs.writeFile(output,Buffer.from(shot.data,'base64'));
  console.log(`Saved ${output}`);
  await call('Browser.close');
}finally{socket?.close();browser.kill();}
