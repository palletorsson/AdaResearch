// An explanatory field model; the real visitor and collision live in Godot.
(() => {
  const w=5,h=16,witness=32,el=id=>document.getElementById(id);
  let state, ticks=0, timer=null, source=true, near=true, sync=true, reverse=false, beginning='FULL';
  const neighbours=(i,values)=>{
    const x=i%w,z=Math.floor(i/w);
    return [[x,z+1],[x,z-1],[x+1,z],[x-1,z]].filter(([a,b])=>a>=0&&a<w&&b>=0&&b<h&&values[b*w+a]>0.5).length;
  };
  function hold(){clearInterval(timer);timer=null;}
  function replay(){
    hold();ticks=0;state=Array(80).fill(beginning==='FULL'?1:0);
    if(beginning==='CHAIN'){state[31]=0.6;state[32]=0.495;}
    draw();
  }
  function advance(){
    if(ticks===300){hold();draw();return;}
    const next=state.slice(),read=sync?state:next;
    const order=Array.from({length:80},(_,i)=>i);if(reverse)order.reverse();
    for(const i of order){
      const x=(i%w-2)*0.6,z=Math.floor(i/w)*0.6;
      const distance=Math.hypot(x-(near?0:-3),-0.15,z-3.6);
      next[i]=source&&distance<1.35?Math.max(0,state[i]-0.04):Math.min(1,state[i]+0.01*neighbours(i,read));
    }
    state=next;ticks++;if(ticks===300)hold();draw();
  }
  function colour(v){return `rgb(${Math.round(168+(140-168)*v)},${Math.round(108+(217-108)*v)},${Math.round(136+(190-136)*v)})`;}
  function draw(){
    const health=state[witness],n=neighbours(witness,state),support=state.filter(v=>v>=0.2).length;
    el('status').textContent=`${beginning} · ${timer?'RUN':ticks===300?'LIMIT':'HELD'} · ${(ticks*0.1).toFixed(1)} s · ${sync?'SYNC':'SCAN'} · ${reverse?'REVERSE':'FORWARD'} · ${source?(near?'PROBE NEAR':'PROBE FAR'):'NONE'}`;
    el('witness').textContent=`W (2,6) · HEALTH ${health.toFixed(3)} · SUPPORT ${health>=0.2?'ON':'OFF'} · NEIGHBOURS ${n}`;
    el('chain-values').textContent=`CHAIN (1,6) / (2,6) / (3,6): ${[31,32,33].map(i=>state[i].toFixed(3)).join(' / ')}`;
    el('support-count').textContent=`${support} of 80 tiles currently support a body in the Godot mapping. Below 0.20, the model shows a ghost; the real bridge has a basin beneath it.`;
    for(const [id,value] of [['run',!!timer],['source',source],['near',near],['order',sync],['reverse',reverse]])el(id).setAttribute('aria-pressed',String(value));
    const plane=['<svg viewBox="0 0 150 480" role="img" aria-label="Bridge health viewed from above. Gold marks W.">'];
    const wall=['<svg viewBox="0 0 480 150" role="img" aria-label="The same eighty health values mapped to a wall frieze.">'];
    state.forEach((v,i)=>{
      const x=i%w,z=Math.floor(i/w),ghost=v<0.2;
      const properties=`fill="${colour(v)}" fill-opacity="${ghost?0.18+v:1}" stroke="${i===witness?'#ffcc70':ghost?'#b2849e':'#18333b'}" stroke-width="${i===witness?3:1}" ${ghost?'stroke-dasharray="3 2"':''}`;
      plane.push(`<rect data-address="${x},${z}" data-health="${v}" x="${x*30+1}" y="${z*30+1}" width="28" height="28" ${properties}/>`);
      wall.push(`<rect x="${z*30+1}" y="${(4-x)*30+1}" width="28" height="28" ${properties}/>`);
    });
    plane.push('</svg>');wall.push('</svg>');el('plane').innerHTML=plane.join('');el('wall').innerHTML=wall.join('');
  }
  el('step').onclick=()=>{hold();advance();};
  el('run').onclick=()=>{if(timer)hold();else if(ticks<300)timer=setInterval(advance,100);draw();};
  el('restore').onclick=()=>{beginning='FULL';replay();};
  el('source').onclick=()=>{source=!source;draw();};
  el('near').onclick=()=>{source=true;near=!near;draw();};
  el('chain').onclick=()=>{beginning='CHAIN';source=false;replay();};
  el('order').onclick=()=>{sync=!sync;replay();};
  el('reverse').onclick=()=>{reverse=!reverse;replay();};
  window.addEventListener('pagehide',hold);replay();
})();
