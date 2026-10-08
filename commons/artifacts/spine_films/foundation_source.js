// Browser-only teaching sketches. These do not control the museum.
const byId = id => document.getElementById(id);
const svgText = (x,y,s,cls='') => `<text x="${x}" y="${y}" class="${cls}">${s}</text>`;
const circle = (x,y,r,fill,stroke='#272d31') => `<circle cx="${x}" cy="${y}" r="${r}" fill="${fill}" stroke="${stroke}" stroke-width="2"/>`;
const line = (x1,y1,x2,y2,stroke='#afb7b4',extra='') => `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${stroke}" stroke-width="2" ${extra}/>`;
const pink = '#ca628f', ink = '#273330';

function drawPoint(){
  const h=Number(byId('height').value), wrong=byId('wrong-frame').checked, actual=h+(wrong?1:0);
  const base=245, py=base-actual*49, expected=base-h*49;
  let s=line(80,base,430,base)+line(250,base,250,32,pink);
  for(let i=0;i<5;i++)s+=line(244,base-i*49,256,base-i*49)+svgText(264,base-i*49+4,`${i} m`);
  s+=`<ellipse cx="210" cy="253" rx="34" ry="7" fill="#d5d9d6"/>`;
  if(wrong)s+=`<circle cx="210" cy="${expected}" r="16" fill="none" stroke="${pink}" stroke-width="2" stroke-dasharray="4 4"/>`;
  s+=circle(210,py,16,'#fff')+line(210,py,242,py,pink)+svgText(30,28,'A position value → a displayed body');
  byId('point-svg').innerHTML=s;
  byId('height-value').textContent=h.toFixed(1)+' m';
  byId('point-status').textContent=wrong?`Expected local Y ${h.toFixed(1)}; displayed Y ${actual.toFixed(1)}. An extra 1 m frame offset was incorrectly passed to this local receiver. Dashed circle = expected.`:`centre.y = ${h.toFixed(1)}. Radius and the other coordinates stay fixed.`;
}
byId('height').addEventListener('input',drawPoint);byId('wrong-frame').addEventListener('change',drawPoint);drawPoint();

const candidates=[[0,0],[.3,.1],[1,.2],[1.2,.1],[2,1],[3,1.5],[3.1,1.5],[4,0]];
let candidate=0, points=[candidates[0]], joined=0, traceMessage='The list begins with one position. Read the next candidate.';
const project=p=>[55+p[0]*100,185-p[1]*65];
function drawTrace(){
  let s=svgText(24,25,'Distance rule: keep a sample when distance ≥ 0.8 m');
  candidates.forEach((p,i)=>{const [x,y]=project(p);s+=circle(x,y,4,'#dbe0dc','#b7c0ba');});
  for(let i=0;i<joined;i++){const a=project(points[i]),b=project(points[i+1]);s+=line(...a,...b,pink);}
  points.forEach((p,i)=>{const [x,y]=project(p);s+=circle(x,y,7,ink)+svgText(x-4,y+25,String(i));});
  const [cx,cy]=project(candidates[candidate]);s+=`<circle cx="${cx}" cy="${cy}" r="14" fill="none" stroke="${pink}" stroke-width="2"/>`;
  s+=svgText(24,243,`points.size() = ${points.length}     joined segments = ${joined}`);
  byId('trace-svg').innerHTML=s;
  byId('trace-status').textContent=traceMessage;
  byId('next-sample').disabled=candidate>=candidates.length-1;
  byId('join-next').disabled=joined>=points.length-1;
}
byId('next-sample').addEventListener('click',()=>{
  candidate++;const p=candidates[candidate],last=points[points.length-1],d=Math.hypot(p[0]-last[0],p[1]-last[1]);
  const keep=d>=.8;if(keep)points.push(p.slice());
  traceMessage=`Distance ${d.toFixed(2)} m → ${keep?'true: append this position.':'false: leave the list unchanged.'}`;drawTrace();
});
byId('join-next').addEventListener('click',()=>{joined++;traceMessage=`Loop step: join points[${joined-1}] to points[${joined}]. The stored positions stay unchanged.`;drawTrace();});
byId('trace-reset').addEventListener('click',()=>{candidate=0;points=[candidates[0]];joined=0;traceMessage='One starting position; no joined segments.';drawTrace();});drawTrace();

let frames=0, elapsed=0, near=false, visited=false;
function drawState(){
  const fraction=Math.min(elapsed/2,1), x=65+fraction*340;
  let s=svgText(24,26,`_ready: 1 call     _process: ${frames} calls     elapsed: ${elapsed.toFixed(1)} s`);
  s+=line(65,92,405,92)+`<rect x="${x-14}" y="61" width="28" height="28" fill="${pink}"/>`;
  s+=svgText(40,120,'start')+svgText(390,120,'stop');
  const gate=(cx,open,label)=>`<rect x="${cx-50}" y="158" width="100" height="73" fill="none" stroke="#d0d7d2"/><rect x="${cx-50}" y="158" width="${open?15:50}" height="73" fill="${ink}"/><rect x="${cx+(open?35:0)}" y="158" width="${open?15:50}" height="73" fill="${ink}"/>`+svgText(cx-60,259,label);
  s+=gate(135,near,'Current proximity')+gate(365,visited,'Retained visit');
  byId('state-svg').innerHTML=s;
  byId('state-status').textContent=`elapsed < 2: ${elapsed<2}. Near now: ${near}. Has visited: ${visited}. Step away to compare the two responses.`;
  byId('proximity-toggle').textContent=near?'Step away':'Approach';
}
byId('frame-step').addEventListener('click',()=>{frames++;elapsed+=.5;drawState();});
byId('proximity-toggle').addEventListener('click',()=>{near=!near;if(near)visited=true;drawState();});
byId('state-reset').addEventListener('click',()=>{frames=0;elapsed=0;near=false;visited=false;drawState();});drawState();

function column(cx,height,sides){
  const radius=49,base=221,top=base-height*60;
  const v=(i,y)=>{const a=i/sides*Math.PI*2;return [cx+radius*Math.cos(a),y+radius*.30*Math.sin(a)];};
  const faces=[];
  for(let i=0;i<sides;i++){
    const vertices=[v(i,base),v(i+1,base),v(i+1,top),v(i,top)];
    const depth=Math.sin((i+.5)/sides*Math.PI*2);
    faces.push({depth,shape:`<polygon points="${vertices.map(p=>p.join(',')).join(' ')}" fill="hsl(40 13% ${74-depth*10}%)" stroke="#626b65" stroke-width=".8"/>`});
  }
  let s=faces.sort((a,b)=>a.depth-b.depth).map(f=>f.shape).join('');
  s+=`<polygon points="${Array.from({length:sides},(_,i)=>v(i,top).join(',')).join(' ')}" fill="#f5f2e9" stroke="#626b65"/>`;
  return s;
}
function drawFunction(){
  const sides=Number(byId('sides').value),height=Number(byId('column-height').value);
  byId('function-svg').innerHTML=svgText(24,24,'Same generator; explicit inputs; two outputs')+column(140,2,4)+column(360,height,sides)+svgText(70,274,'height 2 · sides 4')+svgText(291,274,`height ${height} · sides ${sides}`);
  byId('column-height-value').textContent=height.toFixed(1)+' m';
  byId('function-status').textContent=`For this two-ring study: ${sides} positions per ring × 2 = ${sides*2} positions. The supplied display joins them. The left reference stays fixed.`;
}
byId('sides').addEventListener('change',drawFunction);byId('column-height').addEventListener('input',drawFunction);drawFunction();

let selected=[1,1], cells=Array.from({length:4},()=>Array(4).fill(true));
const grid=byId('grid-cells');
for(let z=0;z<4;z++)for(let x=0;x<4;x++){
  const b=document.createElement('button');b.type='button';b.dataset.x=x;b.dataset.z=z;
  b.addEventListener('click',()=>{selected=[x,z];drawGrid();});grid.appendChild(b);
}
function drawGrid(){
  for(const b of grid.children){const x=Number(b.dataset.x),z=Number(b.dataset.z),v=cells[x][z],sel=x===selected[0]&&z===selected[1];b.className=`cell ${v?'occupied':''} ${sel?'selected':''}`;b.textContent=`${x},${z}`;b.setAttribute('aria-label',`Address ${x}, ${z}: ${v?'occupied':'empty'}`);b.setAttribute('aria-pressed',String(sel));}
  byId('grid-status').textContent=`Selected cells[${selected[0]}][${selected[1]}] = ${cells[selected[0]][selected[1]]}. Selecting an address does not write it. An empty address still exists.`;
}
byId('grid-write').addEventListener('click',()=>{const [x,z]=selected;cells[x][z]=!cells[x][z];drawGrid();});
byId('grid-rule').addEventListener('click',()=>{for(let x=0;x<4;x++)for(let z=0;z<4;z++)cells[x][z]=(x+z)%2===0;drawGrid();});
byId('grid-reset').addEventListener('click',()=>{cells=Array.from({length:4},()=>Array(4).fill(true));selected=[1,1];drawGrid();});drawGrid();

const inks=['#cf709b','#5db7b0','#d9b358'];
function newPalette(){return {index:0};}
let paletteA=newPalette(),paletteB=newPalette();
function drawPalettes(){
  const shared=paletteA===paletteB;
  byId('palette-svg').innerHTML=svgText(24,26,shared?'One Palette instance · two references':'One class · two independent Palette instances')+
    `<rect x="155" y="48" width="190" height="34" rx="3" fill="#e2e8e2"/>`+svgText(178,70,'Palette: state + methods')+
    line(220,85,140,137)+line(280,85,360,137)+
    `<rect x="75" y="142" width="130" height="72" fill="${inks[paletteA.index]}" stroke="${ink}"/><rect x="295" y="142" width="130" height="72" fill="${inks[paletteB.index]}" stroke="${ink}"/>`+
    svgText(84,240,`A → index ${paletteA.index}`)+svgText(304,240,`B → index ${paletteB.index}`)+
    (shared?line(205,178,295,178,pink,'stroke-dasharray="5 4"'):'');
  byId('palette-status').textContent=shared?'A and B refer to the same state. Advancing either changes the value read by both previews.':'Advance A. B keeps its own index. Both previews read their referenced palette after each action.';
}
byId('palette-a').addEventListener('click',()=>{paletteA.index=(paletteA.index+1)%inks.length;drawPalettes();});
byId('palette-b').addEventListener('click',()=>{paletteB.index=(paletteB.index+1)%inks.length;drawPalettes();});
function resetPalettes(){paletteA=newPalette();paletteB=byId('shared-palette').checked?paletteA:newPalette();drawPalettes();}
byId('shared-palette').addEventListener('change',resetPalettes);byId('palette-reset').addEventListener('click',resetPalettes);drawPalettes();

// Show the requested hall/sequence when arriving through a fragment link.
function openTarget(){const t=document.getElementById(location.hash.slice(1));if(t){let p=t;while(p){if(p.tagName==='DETAILS')p.open=true;p=p.parentElement;}}}
window.addEventListener('hashchange',openTarget);openTarget();
