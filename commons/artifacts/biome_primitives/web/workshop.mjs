import {Encounter,stages} from './model.mjs';
const data=await fetch('pilot.json').then(r=>{if(!r.ok)throw Error('Encounter data unavailable');return r.json();});
const model=new Encounter(data.form_dna), canvas=document.querySelector('#world'), ctx=canvas.getContext('2d');
const el=id=>document.getElementById(id);
let playing=false,demoIndex=0,demoElapsed=0,dragging=false,last=performance.now();
const requestedStage=stages.indexOf(decodeURIComponent(location.hash.slice(1)));
if(requestedStage>=0)model.setStage(requestedStage);
const gesture=()=>model.stage_index>=6?data.hinge_demo:(model.stage_index>=4?data.form_demo:data.demo);
const scale=39,centre=[450,380];
function project(p){return [centre[0]+(p[0]-p[2])*scale*.75,centre[1]+(p[0]+p[2])*scale*.34-p[1]*scale*.85];}
function path(points,color,width=1,fill=false){ctx.beginPath();points.forEach((p,i)=>{const q=project(p);i?ctx.lineTo(...q):ctx.moveTo(...q);});ctx.strokeStyle=color;ctx.lineWidth=width;if(fill){ctx.closePath();ctx.fillStyle=color;ctx.fill();}else ctx.stroke();}
function dot(p,r,color){ctx.beginPath();ctx.arc(...project(p),r,0,Math.PI*2);ctx.fillStyle=color;ctx.fill();}
function draw(){
  ctx.clearRect(0,0,900,700);
  path([[-6,-.25,6],[6,-.25,6],[6,0,6],[-6,0,6]],'#8e9988',1,true);
  path([[6,-.25,6],[6,-.25,-6],[6,0,-6],[6,0,6]],'#6f7e6d',1,true);
  path([[-6,0,-6],[6,0,-6],[6,0,6],[-6,0,6]],'#ddd9cd',1,true);
  if(model.level()>=3){
    for(let i=-6;i<=6;i++){path([[i,.01,-6],[i,.01,6]],'#aab5a5');path([[-6,.01,i],[6,.01,i]],'#aab5a5');}
    const c=model.address(),x=c[0]-6,z=c[1]-6;
    path([[x,.02,z],[x+1,.02,z],[x+1,.02,z+1],[x,.02,z+1],[x,.02,z]],'#a36220',2);
  }
  if(model.level()>=1){path([model.anchor,model.point],'#303b48',2);dot(model.anchor,4,'#ba6a35');}
  if(model.level()>=2){model.samples.forEach((s,i)=>{if(i&&!s.start)path([model.samples[i-1].p,s.p],'#ae4943',2);dot(s.p,2.4,'#702a29');});}
  for(const f of model.forms()){
    const [x,y,z]=f.center,[w,h,d]=f.size;
    const yaw=f.yaw||0,cs=Math.cos(yaw),sn=Math.sin(yaw),v=(px,py,pz)=>[x+cs*px+sn*pz,py,z-sn*px+cs*pz];
    const a=v(-w/2,0,d/2),b=v(w/2,0,d/2),c=v(w/2,h,d/2),e=v(-w/2,h,d/2);
    if(f.pivot){const p=f.pivot;path([p,[p[0],h+.14,p[2]]],'#141916',2);path(Array.from({length:25},(_,i)=>{const t=i/24*Math.PI*.5;return[p[0]+w*Math.cos(t),.03,p[2]-w*Math.sin(t)];}),'#997454',1);}
    path([v(w/2,0,-d/2),b,c,v(w/2,h,-d/2)],'#934b35',1,true);
    path([e,c,v(w/2,h,-d/2),v(-w/2,h,-d/2)],'#e0a27e',1,true);
    path([a,b,c],'#c47455',1,true);path([a,c,e],'#da9978',1,true);
  }
  if(model.level()>=0){const p=model.point;dot([p[0],.01,p[2]],8,'#acb0a0');dot(p,8,'#121820');dot([p[0]-.025,p[1]+.045,p[2]-.025],2,'#78877c');}
  el('coordinates').textContent=model.level()<0?'position unavailable':model.point.map(n=>n.toFixed(2)).join(' / ');
  el('count').textContent=model.level()>=2?model.samples.length:(model.samples.length?'hidden':'0');
  el('omitted').textContent=model.dropped;
  el('address').textContent=model.level()>=3?'['+model.address().join(', ')+']':'—';
}
function update(){
  const s=data.stages[model.stage_index];
  for(const button of document.querySelectorAll('[data-stage]'))button.setAttribute('aria-pressed',String(Number(button.dataset.stage)===model.stage_index));
  el('stage-name').textContent=s.title+(model.withdrawn?' / WITHDRAWN':'');el('question').textContent=s.question;
  el('room-question').textContent=s.question;el('room-poem').textContent=s.critical;el('inside').src='inside_'+s.map+'.png';el('inside').alt='Standing inside the full-size '+s.map+' ground';el('poem').textContent=s.critical;el('principle').textContent=s.principle;el('code').textContent=s.code;
  el('withdraw-note').textContent=s.withdraw;
  const names=['position','relation','memory','grid','surface','depth','motor','scale study'];
  el('withdraw').textContent=(model.withdrawn?'Return ':'Withdraw ')+names[model.stage_index];
  el('sampling').hidden=model.stage_index<2;
  el('godot').src=stages[model.stage_index]+'.png';el('godot').alt='Full-size Godot ground: '+s.title;
  el('godot-caption').textContent='Godot capture · '+s.map+(model.stage_index>=6?' · authored comparison pose':' · recorded gesture');
  el('status').textContent= model.withdrawn?'Capability withdrawn. Retained state is preserved.':'';
  el('inside-caption').textContent='Actual Godot capture · camera 1.65 m above the ground · '+(model.stage_index>=4?'shared front viewpoint for the form studies':'fixed early-stage viewpoint')+' · no in-world interface';
  el('inside').hidden=model.stage_index>=6;
  for(const [stage,prefix] of [[6,'hinge'],[7,'scale']]){
    const active=model.stage_index===stage,film=el(prefix+'-film');
    film.hidden=!active;el(prefix+'-study').hidden=!active;
    if(active){
      el('inside-caption').textContent='Actual Godot recording · '+(stage===7?'48 s · same turn at two widths':'20 s · hinged planes')+' · camera at 1.65 m · no in-world interface';
      if(!matchMedia('(prefers-reduced-motion: reduce)').matches)film.play().catch(()=>{});
    }else film.pause();
  }
  history.replaceState(null,'','#'+s.map);
  draw();
}
function stopDemo(){playing=false;el('demo').textContent='Try the recorded gesture';}
for(const b of document.querySelectorAll('[data-stage]'))b.addEventListener('click',()=>{stopDemo();model.setStage(Number(b.dataset.stage));update();});
el('withdraw').onclick=()=>{stopDemo();model.toggle();update();};
el('clear').onclick=()=>{stopDemo();model.clear();el('status').textContent='Memory cleared. The point and its reference remain.';draw();};
el('interval').onchange=e=>{model.interval=Number(e.target.value);model.elapsed=0;model.new_stroke=true;el('status').textContent='New interval begins a new stroke. Existing samples are retained.';};
el('demo').onclick=()=>{if(playing){stopDemo();return;}if(model.withdrawn){model.toggle();update();}playing=true;demoIndex=0;demoElapsed=0;model.new_stroke=true;model.elapsed=0;el('demo').textContent='Stop gesture';};
function moveFromPointer(e){
  const rect=canvas.getBoundingClientRect(),sx=(e.clientX-rect.left)*900/rect.width,sy=(e.clientY-rect.top)*700/rect.height;
  const diff=(sx-centre[0])/(scale*.75),sum=(sy-centre[1]+model.point[1]*scale*.85)/(scale*.34);
  model.move([(sum+diff)/2,model.point[1],(sum-diff)/2]);draw();
}
canvas.addEventListener('pointerdown',e=>{stopDemo();dragging=true;canvas.setPointerCapture(e.pointerId);canvas.focus();moveFromPointer(e);});
canvas.addEventListener('pointermove',e=>{if(dragging)moveFromPointer(e);});
canvas.addEventListener('pointerup',()=>dragging=false);canvas.addEventListener('pointercancel',()=>dragging=false);
canvas.addEventListener('keydown',e=>{const dirs={ArrowLeft:[-.2,0,0],ArrowRight:[.2,0,0],ArrowUp:[0,0,-.2],ArrowDown:[0,0,.2]};if(dirs[e.key]){e.preventDefault();stopDemo();model.move(model.point.map((p,i)=>p+dirs[e.key][i]));draw();}});
el('export').onclick=()=>{const blob=new Blob([JSON.stringify(model.snapshot(),null,2)],{type:'application/json'}),url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='biome-7-'+stages[model.stage_index]+'.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);};
function frame(now){
  const dt=(now-last)/1000;last=now;
  model.advanceHinge(dt,true);
  if(playing){const actions=gesture();demoElapsed+=dt;while(demoIndex<actions.length&&demoElapsed>=actions[demoIndex].dt){const a=actions[demoIndex++];demoElapsed-=a.dt;model.move(a.p);model.advance(a.dt);}if(demoIndex>=actions.length)stopDemo();}
  else model.advance(dt);
  draw();requestAnimationFrame(frame);
}
update();requestAnimationFrame(frame);
