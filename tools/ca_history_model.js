// Remote explanatory model: same 15-site periodic Rule 30, not a Godot physics preview.
const width = 15, limit = 24;
let rows = [], selected = 0, pair = false, flipped = false, timer = null;
const el = id => document.getElementById(id);
const nextRow = row => row.map((_, x) => (30 >> ((row[(x+width-1)%width]<<2)|(row[x]<<1)|row[(x+1)%width])) & 1);
function halt(){if(timer!==null)clearInterval(timer);timer=null;el('run').setAttribute('aria-pressed','false');}
function replay(){halt();const r=Array(width).fill(0);if(pair){r[5]=r[9]=1;}else r[7]=1;if(flipped)r[9]=1-r[9];rows=[r];selected=0;draw();}
function advance(){if(rows.length<limit){rows.push(nextRow(rows.at(-1)));selected=rows.length-1;}if(rows.length===limit)halt();draw();}
function colour(g){const a=[120,217,189],b=[226,164,222],t=g/23;return `rgb(${a.map((v,i)=>Math.round(v+(b[i]-v)*t)).join(',')})`;}
function svg(id,body){el(id).innerHTML=`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 440 470" role="img" aria-label="${id==='desk'?'Flat recorded generations':id==='tiles'?'Oblique view of occupied tiles':'History mapped onto a screen'}">${body}</svg>`;}
function draw(){
 let a='',b='',c='';
 for(let g=0;g<limit;g++)for(let x=0;x<width;x++){
  const present=g<rows.length,alive=present&&rows[g][x]===1,fill=alive?colour(g):present?'#355058':'#172d34';
  a+=`<rect x="${55+x*22}" y="${24+g*16}" width="20" height="14" fill="${fill}"/>`;
  if(alive){const px=64+x*15+g*4.6,py=90+g*11-x*3;b+=`<path d="M${px},${py}l14,-2.8l4.2,10l-14,2.8z" fill="${colour(g)}"/><path d="M${px+4.2},${py+10}l14,-2.8v7l-14,2.8z" fill="${colour(g)}" opacity=".65"/>`;c+=`<rect x="${24+g*16}" y="${345-x*19}" width="14" height="17" fill="${colour(g)}"/>`;}
 }
 a+=`<rect x="52" y="${22+selected*16}" width="334" height="18" fill="none" stroke="#ffcc72" stroke-width="2"/>`;
 const px=64+selected*4.6,py=90+selected*11;
 b+=`<path d="M${px},${py+3}l225,-45" stroke="#ffcc72" stroke-width="2"/>`;
 c+=`<rect x="20" y="68" width="392" height="303" fill="none" stroke="#b18c66" stroke-width="5"/><path d="M${30+selected*16},70v300" stroke="#ffcc72" stroke-width="2"/>`;
 for(const id of ['desk','tiles','screen']){const body=id==='desk'?a:id==='tiles'?b:c;svg(id,body+`<text x="24" y="432" fill="#e4e5d8" font-size="19" font-family="sans-serif">Gold follows generation ${selected}</text>`);}
 el('status').textContent=`Rule 30 · generations 0–${rows.length-1} · following ${selected} · ${pair?'PAIR':'SINGLE'}${flipped?' + FLIP X9':''} · ${timer!==null?'RUN':rows.length===24?'RECORD FULL':'HELD'}`;
 el('count').textContent=String(rows.reduce((n,row)=>n+row.reduce((a,b)=>a+b,0),0));
}
el('step').onclick=()=>{halt();advance();};
el('replay').onclick=replay;
el('run').onclick=()=>{if(timer!==null){halt();draw();}else if(rows.length<limit){timer=setInterval(advance,500);el('run').setAttribute('aria-pressed','true');draw();}};
el('seed').onclick=()=>{pair=!pair;flipped=false;replay();};
el('flip').onclick=()=>{flipped=!flipped;replay();};
el('row').onclick=()=>{halt();selected=(selected+rows.length-1)%rows.length;draw();};
replay();for(let i=0;i<11;i++)advance();
