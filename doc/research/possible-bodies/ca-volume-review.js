// Read-only inspection of recorded states; the Godot workshop supplies real collision.
(async () => {
  const data = await (await fetch('ca-volume-data.json')).json();
  const el = id => document.getElementById(id), N = 13;
  let seed = 0, view = 2, rule = 0, generation = 6, section = 6, yaw = .7;
  const names = ['One cluster', 'Scattered cells', 'Two clusters'];
  const materials = ['Solid', 'Frame', 'Shell'];
  const faces = [
    [[-1,0,0],[[0,0,0],[0,0,1],[0,1,1],[0,1,0]]],
    [[1,0,0],[[1,0,1],[1,0,0],[1,1,0],[1,1,1]]],
    [[0,-1,0],[[0,0,1],[0,0,0],[1,0,0],[1,0,1]]],
    [[0,1,0],[[0,1,0],[0,1,1],[1,1,1],[1,1,0]]],
    [[0,0,-1],[[1,0,0],[0,0,0],[0,1,0],[1,1,0]]],
    [[0,0,1],[[0,0,1],[1,0,1],[1,1,1],[0,1,1]]]
  ];
  const inside = (a,x,y,z) => x>=0&&x<N&&y>=0&&y<N&&z>=0&&z<N ? a[(z*N+y)*N+x] : 0;
  const clear = id => {const c=el(id),p=c.getContext('2d');p.fillStyle='#10292f';p.fillRect(0,0,c.width,c.height);p.font='16px system-ui';return p;};
  function volume(a) {
    const p=clear('volume'),sy=Math.sin(yaw),cy=Math.cos(yaw),se=.5,ce=Math.sqrt(.75);
    const project = v => {const [x,y,z]=[v[0]-6.5,v[1]-5.5,v[2]-6.5];return [350+23*(cy*x+sy*z),275-23*(-sy*se*x+ce*y+cy*se*z),sy*ce*x+se*y-cy*ce*z];};
    const polys=[];
    for(let z=0;z<N;z++)for(let y=0;y<N;y++)for(let x=0;x<N;x++)if(inside(a,x,y,z)) {
      faces.forEach(([d,q])=>{
        if(inside(a,x+d[0],y+d[1],z+d[2]))return;
        const aperture=view===2&&d[1]===0&&(x+y+z)%3===0;
        const facing=d[0]*sy*ce+d[1]*se-d[2]*cy*ce;
        if(view===0&&facing<=0)return;
        const verts=q.map(v=>project([x+v[0],y+v[1],z+v[2]]));
        polys.push({verts,depth:verts.reduce((s,v)=>s+v[2],0)/4,aperture,back:facing<=0,colour:d[1]>0?'#e0decf':d[0]!==0?'#95aea6':'#b4bdb4',tint:(x+y+z)%2});
      });
    }
    polys.sort((a,b)=>a.depth-b.depth);
    for(const f of polys){
      p.beginPath();f.verts.forEach((v,i)=>i?p.lineTo(v[0],v[1]):p.moveTo(v[0],v[1]));p.closePath();
      if(view===0||view===2&&!f.aperture&&!f.back){p.fillStyle=view===2&&f.tint?'#8270a9':f.colour;p.fill();}
      if(view!==0){p.strokeStyle=f.back?'#734e66':'#ef9bbb';p.lineWidth=view===1?1.2:1;p.stroke();}
    }
    p.fillStyle='#c7d4ce';p.fillText('Recorded state / schematic architecture',20,490);
    if(!a.some(Boolean)){p.font='27px Georgia';p.fillText('No cells remain.',240,255);}
  }
  function slice(a){
    const p=clear('slice');let count=0;
    for(let y=0;y<N;y++)for(let x=0;x<N;x++){
      const v=inside(a,x,y,section);count+=v;p.fillStyle=v?'#b9c8bc':'#1c3940';p.fillRect(28+x*25,348-y*25,24,24);
    }
    p.fillStyle='#f2adc6';p.strokeStyle='#f2adc6';p.lineWidth=2;
    // Cell = 2 m; fixed-size body = 0.6 m × 1.8 m. Scale key outside the field.
    p.strokeRect(32,399,7.5,22.5);p.font='14px system-ui';p.fillText('1.8 m visitor / each cell is 2 m',52,418);
    p.fillStyle='#c7d4ce';p.fillText(`Z slice ${section}: ${count} occupied sites`,28,28);
  }
  function render(){
    const sample=data.cases.find(c=>c.seed===seed&&c.rule===rule&&!c.sine),a=sample.history[generation];
    const occupied=a.reduce((s,v)=>s+v,0),old=generation?sample.history[generation-1]:a;
    let births=0,deaths=0;a.forEach((v,i)=>{births+=!!v&&!old[i];deaths+=!v&&!!old[i];});
    document.querySelectorAll('[data-seed]').forEach(b=>b.setAttribute('aria-pressed',+b.dataset.seed===seed));
    document.querySelectorAll('[data-view]').forEach(b=>b.setAttribute('aria-pressed',+b.dataset.view===view));
    document.querySelectorAll('[data-rule]').forEach(b=>b.setAttribute('aria-pressed',+b.dataset.rule===rule));
    el('photo').src=`ca-volume-seed-${seed}-view-${view}.png`;
    el('photo').alt=`Actual Godot: ${names[seed]}, ${materials[view]}, growth rule, generation 6`;
    el('photo-caption').textContent=`Actual Godot / ${names[seed]} / ${materials[view]} / growth rule at G6. The time and rule controls below inspect the recorded data separately.`;
    el('reading').textContent=`${names[seed]} · G${generation} · ${occupied} occupied cells · ${births} births / ${deaths} deaths`;
    el('rule-reading').textContent=rule===0?'Growth rule: birth at exactly 4 neighbours; survive with 4–26.':'Turnover rule: birth at exactly 5 neighbours; survive with 4–7.';
    el('generation-value').textContent=`G${generation} / 6`;
    el('slice-value').textContent=`Z = ${section} / 12`;
    el('mapping-note').textContent=view===0?'Solid: occupied sites become filled blocks.':view===1?'Frame: unique edges of exposed faces become 8 cm bars. The cellular state is unchanged.':'Shell: the boundary frame receives faceted panels. One third of side-face addresses are deliberately left open; horizontal faces keep panels.';
    el('step').disabled=generation===6;volume(a);slice(a);
  }
  document.querySelectorAll('[data-seed]').forEach(b=>b.addEventListener('click',()=>{seed=+b.dataset.seed;render();}));
  document.querySelectorAll('[data-view]').forEach(b=>b.addEventListener('click',()=>{view=+b.dataset.view;render();}));
  document.querySelectorAll('[data-rule]').forEach(b=>b.addEventListener('click',()=>{rule=+b.dataset.rule;render();}));
  el('generation').addEventListener('input',e=>{generation=+e.target.value;render();});
  el('z-slice').addEventListener('input',e=>{section=+e.target.value;render();});
  el('angle').addEventListener('input',e=>{yaw=+e.target.value*Math.PI/180;render();});
  el('step').addEventListener('click',()=>{generation=Math.min(6,generation+1);el('generation').value=generation;render();});
  el('first').addEventListener('click',()=>{generation=0;el('generation').value=0;render();});
  render();
})().catch(e=>{document.getElementById('reading').textContent=`Could not load recorded states: ${e.message}`;});
