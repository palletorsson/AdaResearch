// Remote explanatory model. No Godot collision, lighting or headset performance.
(() => {
  const size = 24, sites = [[10,10],[13,13],[16,16]], letters = ['A','B','C'];
  const el = id => document.getElementById(id);
  let cells, generation = 0, preset = 'GLIDER', linked = true, timer = null;
  let changed = 0, onsets = [0,0,0];
  const blank = () => Array.from({length:size}, () => Array(size).fill(false));
  function hold() { clearInterval(timer); timer = null; }
  function replay() {
    hold(); cells = blank(); generation = 0; changed = 0; onsets = [0,0,0];
    if (preset === 'BLINKER') [9,10,11].forEach(x => cells[10][x] = true);
    else {
      [[7,6],[8,7],[6,8],[7,8],[8,8]].forEach(([x,y]) => cells[y][x] = true);
      if (preset === 'MEET') [10,11].forEach(y => [10,11].forEach(x => cells[y][x] = true));
    }
    draw();
  }
  function advance() {
    if (generation === 48) { hold(); draw(); return; }
    const next = blank(); changed = 0;
    for (let y=0;y<size;y++) for (let x=0;x<size;x++) {
      let count=0;
      for(let dy=-1;dy<=1;dy++) for(let dx=-1;dx<=1;dx++) {
        if(dx || dy) count += Number(cells[(y+dy+size)%size][(x+dx+size)%size]);
      }
      next[y][x] = count === 3 || (cells[y][x] && count === 2);
      changed += Number(next[y][x] !== cells[y][x]);
    }
    sites.forEach(([x,y],i) => { if(linked && next[y][x] && !cells[y][x]) onsets[i]++; });
    cells = next; generation++;
    if(generation===48) hold();
    draw();
  }
  function draw() {
    const population = cells.flat().filter(Boolean).length;
    el('status').textContent = `${preset} · GEN ${generation} · ${timer?'RUNNING':generation===48?'LIMIT / REPLAY':'HELD'} · POP ${population} · CHANGED ${changed} · LAMPS ${linked?'LINKED':'UNLINKED'}`;
    el('run').setAttribute('aria-pressed',String(!!timer));
    el('link').setAttribute('aria-pressed',String(linked));
    ['GLIDER','BLINKER','MEET'].forEach(name => el(name.toLowerCase()).setAttribute('aria-pressed',String(preset===name)));
    let grid = `<svg viewBox="0 0 480 480" role="img" aria-label="Life plane at generation ${generation}, ${population} occupied cells. Gold squares mark fixed addresses A, B and C.">`;
    for(let y=0;y<size;y++) for(let x=0;x<size;x++) grid += `<rect x="${20*x+1}" y="${20*y+1}" width="18" height="18" fill="${cells[y][x]?'#90ebca':'#273e49'}"/>`;
    sites.forEach(([x,y],i) => {
      grid += `<rect x="${20*x}" y="${20*y}" width="20" height="20" fill="none" stroke="#ffcc70" stroke-width="3"/><text x="${20*x-4}" y="${20*y+14}" text-anchor="end" fill="#ffdfb8" stroke="#112a30" stroke-width="3" paint-order="stroke" font-size="16">${letters[i]}</text>`;
      const occupied = cells[y][x], lit = occupied && linked;
      el('lamp-'+i).classList.toggle('lit',lit);
      el('lamp-state-'+i).textContent = `(${x},${y}) · CELL ${Number(occupied)} · ${lit?'LIT':'DARK'} · ONSETS ${onsets[i]}`;
    });
    el('plane').innerHTML = grid+'</svg>';
  }
  el('step').onclick = () => {hold();advance();};
  el('run').onclick = () => {if(timer) hold();else if(generation<48) timer=setInterval(advance,500);draw();};
  el('replay').onclick = replay;
  el('link').onclick = () => {linked=!linked;draw();};
  ['GLIDER','BLINKER','MEET'].forEach(name => el(name.toLowerCase()).onclick=()=>{preset=name;replay();});
  window.addEventListener('pagehide',hold);
  replay();
})();
