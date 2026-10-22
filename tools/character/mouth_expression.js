// Stylized speech preview, synchronized to playback time (not audio phonemes).
export const MOUTH_TARGETS = ['MouthOpen', 'MouthSmile', 'MouthSad', 'MouthRound'];
const syllables = [
  [.06,.19,.70,.05], [.31,.14,.46,.10], [.52,.23,.83,.65],
  [.84,.17,.52,.15], [1.09,.26,.76,.48], [1.47,.15,.45,.05],
  [1.71,.21,.68,.72], [2.02,.18,.54,.12],
];
export function sampleMouth(time, motion='Idle', speaking=false) {
  let open=0, smile=.12, sad=0, round=0;
  switch(motion) {
    case 'Smile': smile=.95;open=.12;break;
    case 'Happy': smile=.80;open=.22;break;
    case 'Laugh': smile=.80;open=.12+.65*Math.max(0,Math.sin(time*Math.PI*6))**1.2;break;
    case 'Sad': smile=0;sad=.95;break;
    case 'Thinking': smile=0;round=.16;break;
    case 'Victory': smile=.80;open=.16;break;
    case 'Wave': smile=.50;open=.04;break;
    case 'Talk': smile=.16;break;
  }
  if(speaking || motion==='Talk') {
    const t=((time%2.8)+2.8)%2.8;
    open=0;round=0;
    for(const [start,duration,amplitude,vowel] of syllables) {
      const u=(t-start)/duration;
      if(u>0&&u<1) {
        const pulse=Math.sin(Math.PI*u)**1.35;
        open=amplitude*pulse;round=vowel*pulse;
      }
    }
    open*=1-.35*round;smile*=1-.65*round;sad*=.75;
  }
  return [open,smile,sad,round];
}
