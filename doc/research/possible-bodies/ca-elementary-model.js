'use strict';
// Independent web model: same transition semantics, deliberately smaller domain.
const W=14, N=W*W*W, centre=7+7*W+7*W*W;
const el=id=>document.getElementById(id), ns='http://www.w3.org/2000/svg';
let cells=new Uint8Array(N), generation=0, budget=20, changed=-1, timer=null, height=false, revealed=false;
const index=(x,y,z)=>x+y*W+z*W*W;
function neighbourCount(i){let n=0;for(let z=-1;z<=1;z++)for(let y=-1;y<=1;y++)for(let x=-1;x<=1;x++)if(x||y||z)n+=+(cells[i+x+y*W+z*W*W]===1);return n;}
function nextValue(state,n){return state===2?0:state===1?(n>=6&&n<=8?1:2):(n>=6&&n<=8?1:0);}
function visible(i){return [1,-1,W,-W,W*W,-W*W].some(d=>cells[i+d]===0);}
function hold(){if(timer!==null)clearInterval(timer);timer=null;}
function replay(){
 hold();cells=new Uint8Array(N);generation=0;budget=20;changed=-1;revealed=false;
 const fixture=el('fixture').value;
 if(fixture==='soup'){
  let seed=23090;const random=()=>{seed^=seed<<13;seed^=seed>>>17;seed^=seed<<5;return (seed>>>0)/4294967296;};
  for(let z=1;z<W-1;z++)for(let y=1;y<W-1;y++)for(let x=1;x<W-1;x++){
   const central=x>=4&&x<=10&&y>=4&&y<=10&&z>=4&&z<=10;
   cells[index(x,y,z)]=+(random()<(central?.55:.1));
  }
 }else if(fixture==='shell'){
  for(let z=6;z<=8;z++)for(let y=6;y<=8;y++)for(let x=6;x<=8;x++)cells[index(x,y,z)]=1;
 }else{
  cells[centre]=fixture==='fade'?2:0;
  for(const [x,y,z] of [[-1,0,0],[1,0,0],[0,-1,0],[0,1,0],[0,0,-1],[0,0,1],[1,1,1]])cells[index(7+x,7+y,7+z)]=1;
 }
 draw();
}
function tick(){
 if(generation>=budget){hold();draw();return;}
 const next=new Uint8Array(N);changed=0;
 for(let z=1;z<W-1;z++)for(let y=1;y<W-1;y++)for(let x=1;x<W-1;x++){
  const i=index(x,y,z);next[i]=nextValue(cells[i],neighbourCount(i));changed+=+(next[i]!==cells[i]);
 }
 cells=next;generation++;revealed=false;if(generation>=budget)hold();draw();
}
function node(name,attrs){const n=document.createElementNS(ns,name);for(const [k,v]of Object.entries(attrs))n.setAttribute(k,v);return n;}
function project(x,y,z){return [330+(x-z)*18,265+(x+z)*8-y*21];}
function cube(x,y,z,fill,attrs={}){
 const g=node('g',attrs),faces=[[[0,1,0],[1,1,0],[1,1,1],[0,1,1]],[[0,0,1],[1,0,1],[1,1,1],[0,1,1]],[[1,0,0],[1,0,1],[1,1,1],[1,1,0]]];
 faces.forEach((face,j)=>g.appendChild(node('polygon',{points:face.map(([a,b,c])=>project(x+a*.88,y+b*.88,z+c*.88).join(',')).join(' '),fill,stroke:'#122e35','stroke-width':.7,'fill-opacity':[1,.85,.65][j]})));
 return g;
}
function draw(){
 const svg=el('volume');svg.replaceChildren();let active=0,fading=0,drawn=0,shapes=[];
 const floor=node('polygon',{points:[[0,0,0],[W,0,0],[W,0,W],[0,0,W]].map(p=>project(...p).join(',')).join(' '),fill:'#32494f',stroke:'#5c7479','stroke-width':1});svg.appendChild(floor);
 for(let z=1;z<W-1;z++)for(let y=1;y<W-1;y++)for(let x=1;x<W-1;x++){
  const i=index(x,y,z),state=cells[i];active+=+(state===1);fading+=+(state===2);
  if(state>0&&visible(i)){drawn++;shapes.push({x,y,z,state,i});}
 }
 shapes.sort((a,b)=>(a.x+a.z)-(b.x+b.z)||a.y-b.y);
 for(const {x,y,z,state,i}of shapes){const colour=height?`hsl(193 16% ${30+y/W*62}%)`:(state===1?'#ec7fac':'#64c19a');svg.appendChild(cube(x,y,z,colour,{'data-index':i,'data-state':state}));}
 const outline=cube(7,7,7,'none',{'aria-label':'Inspected centre cell'});for(const p of outline.children){p.setAttribute('stroke','#fff3c5');p.setAttribute('stroke-width','1.4');}svg.appendChild(outline);
 const n=neighbourCount(centre),state=cells[centre];
 el('generation').textContent=`GEN ${generation} / ${timer===null?'HELD':'RUN'}`;
 el('counts').textContent=`${active} ACTIVE · ${fading} FADING · ${drawn} DRAWN`;
 el('counts').dataset.active=active;el('counts').dataset.fading=fading;el('counts').dataset.drawn=drawn;
 el('changes').textContent=changed<0?'No update yet':`${changed} cells changed in the last update`;
 el('witness').textContent=`CELL (7, 7, 7)\nSTATE ${state} · ${n} active neighbours\nNEXT ${revealed?nextValue(state,n):'…'}`;
 el('witness').style.whiteSpace='pre-line';
 el('budget-note').textContent=generation>=budget?`Budget of ${budget} reached. +20 permits another interval; this pause alone does not prove a fixed point.`:`Observation budget: ${budget}. Edges remain empty.`;
 el('view').textContent=height?'VIEW: height':'VIEW: states';el('run').textContent=timer===null?'RUN':'HOLD';el('reveal').textContent=revealed?'Hide next state':'Reveal next state';
 el('step').disabled=el('run').disabled=generation>=budget;
 svg.setAttribute('aria-label',`Isometric 3D cellular automaton, generation ${generation}, ${height?'height':'state'} colours`);
}
el('step').onclick=()=>{hold();tick();};
el('run').onclick=()=>{if(timer!==null)hold();else if(generation<budget)timer=setInterval(tick,500);draw();};
el('replay').onclick=replay;el('fixture').onchange=replay;
el('view').onclick=()=>{height=!height;draw();};
el('extend').onclick=()=>{hold();budget+=20;draw();};
el('reveal').onclick=()=>{revealed=!revealed;draw();};
document.addEventListener('visibilitychange',()=>{if(document.hidden){hold();draw();}});
replay();
