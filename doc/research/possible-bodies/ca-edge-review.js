/* Recorded states from the independently checked Godot experiment. */
const data=await fetch('ca-edge-data.json').then(r=>r.json());
const choice=document.querySelector('#case');const time=document.querySelector('#time');const depth=document.querySelector('#depth');
const names=['Scattered / integers / pull .25 / drive 1','Scattered / integers / pull 0 / drive 0','Scattered / integers / pull .25 / drive 0','Scattered / fractions / pull .25 / drive 0','Uniform / integers / pull .25 / drive 0','Uniform / fractions / pull .25 / drive 0','Matched A and B / integers / pull .25 / drive 1'];
names.forEach((name,i)=>{const o=document.createElement('option');o.value=i;o.textContent=name;choice.append(o)});choice.value=3;
function paint(){
 const c=data[+choice.value],g=+time.value,z=+depth.value,r=c.history[g],s=c.states[g];
 const gain=1/Math.max(r.max_difference,1e-6);
 document.querySelector('#reading').textContent=`G${g} · ${r.different} of 1,331 addresses differ · maximum ${r.max_difference.toFixed(6)} · mean ${r.mean_difference.toFixed(6)}`;
 document.querySelector('#generation').textContent=`G${g} / 20`;document.querySelector('#slice').textContent=`Z = ${z} / 10`;
 document.querySelector('#gain').textContent=`Difference display gain ×${gain.toFixed(1)}. Count threshold: 0.000001. A and B use the fixed 0–9 palette.`;
 for(let side=0;side<3;side++){
  const cv=document.querySelectorAll('.field')[side],ctx=cv.getContext('2d'),cell=cv.width/11;
  ctx.clearRect(0,0,cv.width,cv.height);
  for(let y=0;y<11;y++)for(let x=0;x<11;x++){
   const i=x+11*y+121*z,t=side===2?Math.min(1,Math.abs(s.a[i]-s.b[i])*gain):(side===0?s.a[i]:s.b[i])/9;
   const lo=side===2?[17,44,49]:[24,44,66],hi=side===2?[255,209,142]:[239,192,214];
   ctx.fillStyle=`rgb(${lo.map((v,j)=>Math.round(v+(hi[j]-v)*t)).join(',')})`;ctx.fillRect(x*cell,(10-y)*cell,cell-1,cell-1);
  }
 }
 const cv=document.querySelector('#history'),ctx=cv.getContext('2d');ctx.clearRect(0,0,cv.width,cv.height);
 const metrics=[['different','Affected addresses',1331,'#f2bfd3'],['max_difference','Maximum difference',1,'#ffd18e']];
 metrics.forEach(([key,label,max,color],j)=>{
  const left=55+j*330,top=38,w=270,h=135;ctx.strokeStyle='#526a70';ctx.strokeRect(left,top,w,h);ctx.font='14px sans-serif';ctx.fillStyle='#e9e5d4';ctx.fillText(label,left,20);ctx.fillText(String(max),left-36,top+5);ctx.fillText('0',left-15,top+h);ctx.fillText('update 0 → 20',left,top+h+25);
  ctx.strokeStyle=color;ctx.lineWidth=2;ctx.beginPath();c.history.forEach((p,i)=>{const x=left+i/20*w,y=top+h-p[key]/max*h;i?ctx.lineTo(x,y):ctx.moveTo(x,y)});ctx.stroke();ctx.fillStyle=color;ctx.beginPath();ctx.arc(left+g/20*w,top+h-r[key]/max*h,4,0,Math.PI*2);ctx.fill();
 });
 document.querySelector('#step').disabled=g===20;
}
[choice,time,depth].forEach(el=>el.addEventListener('input',paint));
document.querySelector('#first').addEventListener('click',()=>{time.value=0;paint()});
document.querySelector('#step').addEventListener('click',()=>{time.value=Math.min(20,+time.value+1);paint()});paint();
