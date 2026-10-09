(() => {
  'use strict';
  const N=32, F=.037, K=.060, LIMIT=2400, W=15*N+12;
  const make=exchange=>({u:new Float32Array(N*N),v:new Float32Array(N*N),nu:new Float32Array(N*N),nv:new Float32Array(N*N),exchange});
  const a=make(true),b=make(false);
  let ticks=0,running=false,target=0,injections=0,viewU=false,coat=true;
  const $=id=>document.getElementById(id);
  function reset(){
    for(const f of [a,b]){f.u.fill(1);f.v.fill(0);for(let y=13;y<19;y++)for(let x=13;x<19;x++){f.u[y*N+x]=.5;f.v[y*N+x]=.25;}}
    ticks=0;injections=0;running=false;target=0;draw();
  }
  function lap(q,x,y){return q[y*N+(x+31)%N]+q[y*N+(x+1)%N]+q[((y+31)%N)*N+x]+q[((y+1)%N)*N+x]-4*q[y*N+x];}
  const clamp=v=>Math.max(0,Math.min(1,v));
  function step(f){
    for(let y=0;y<N;y++)for(let x=0;x<N;x++){
      const i=y*N+x,u=f.u[i],v=f.v[i],reaction=u*v*v;
      f.nu[i]=clamp(u+(f.exchange?.16*lap(f.u,x,y):0)-reaction+F*(1-u));
      f.nv[i]=clamp(v+(f.exchange?.08*lap(f.v,x,y):0)+reaction-(K+F)*v);
    }
    [f.u,f.nu]=[f.nu,f.u];[f.v,f.nv]=[f.nv,f.v];
  }
  function advance(n){for(let k=0;k<n&&ticks<LIMIT;k++){step(a);step(b);ticks++;}if(ticks===LIMIT||(target&&ticks>=target)){running=false;target=0;}draw();}
  function paint(canvas,f){
    const ctx=canvas.getContext('2d');ctx.imageSmoothingEnabled=false;
    const size=canvas.width/N,low=viewU?[36,30,70]:[18,45,61],high=viewU?[188,232,188]:[237,177,203];
    for(let y=0;y<N;y++)for(let x=0;x<N;x++){
      const t=viewU?f.u[y*N+x]:clamp(f.v[y*N+x]*2);
      ctx.fillStyle=`rgb(${low.map((v,i)=>Math.round(v+(high[i]-v)*t)).join(',')})`;
      ctx.fillRect(x*size,y*size,size,size);
    }
    ctx.strokeStyle='#ffe49a';ctx.lineWidth=2;ctx.strokeRect(12*size+1,15*size+1,size-2,size-2);
  }
  function draw(){
    $('model-clock').textContent=`${ticks===LIMIT?'LIMIT':running?'RUN':'HELD'} · tick ${ticks} / ${LIMIT} · dt 1 · injections ${injections}`;
    $('witness-a').textContent=`W (12,15): U ${a.u[W].toFixed(3)} · V ${a.v[W].toFixed(3)}`;
    $('witness-b').textContent=`W (12,15): U ${b.u[W].toFixed(3)} · V ${b.v[W].toFixed(3)}`;
    $('model-b-title').textContent=`B · exchange ${b.exchange?'ON':'OFF'}`;
    $('model-view').textContent=`Showing ${viewU?'U · violet → green':'V ×2 · blue → pink'}; feed .037, removal K .060. Edges wrap.`;
    $('coat-note').textContent=coat?'Wall coating linked: the same field also fills the tall panels below.':'Wall coating hidden; both table fields keep their state.';
    $('exchange').setAttribute('aria-pressed',String(b.exchange));$('view').setAttribute('aria-pressed',String(viewU));$('coat').setAttribute('aria-pressed',String(coat));
    for(const [i,f] of [a,b].entries()){paint($(`field-${i}`),f);const wall=$(`wall-${i}`);wall.hidden=!coat;paint(wall,f);}
  }
  $('step').onclick=()=>{running=false;target=0;advance(1);};
  $('run').onclick=()=>{running=!running&&ticks<LIMIT;target=0;draw();};
  $('replay').onclick=reset;
  $('hundred').onclick=()=>{target=Math.min(ticks+100,LIMIT);running=ticks<LIMIT;draw();};
  $('exchange').onclick=()=>{b.exchange=!b.exchange;reset();};
  $('inject').onclick=()=>{for(const f of [a,b])for(let y=14;y<=16;y++)for(let x=3;x<=5;x++){f.u[y*N+x]=.5;f.v[y*N+x]=.25;}injections++;draw();};
  $('view').onclick=()=>{viewU=!viewU;draw();};
  $('coat').onclick=()=>{coat=!coat;draw();};
  setInterval(()=>{if(running)advance(target?Math.min(4,target-ticks):4);},100);
  document.addEventListener('visibilitychange',()=>{if(document.hidden){running=false;target=0;draw();}});
  reset();
})();
