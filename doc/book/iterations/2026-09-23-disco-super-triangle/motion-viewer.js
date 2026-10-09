const frame=document.getElementById('motion-frame');
const label=document.getElementById('motion-label');
const play=document.getElementById('motion-play');
const slider=document.getElementById('motion-position');
const families=['DIAGONALS','CHEVRONS','DIAMONDS','TURNING WAVES','LARGE DIAMONDS','SUPER DIAMONDS'];
let index=0,timer=null,preloaded=false;
function show(i){index=(i+96)%96;frame.src='motion-'+String(index).padStart(3,'0')+'.png';frame.alt='Native museum floor, triangle pose '+(index/4).toFixed(2);label.textContent=families[Math.floor(index/16)]+' · pose '+(index/4).toFixed(2);slider.value=String(index);}
function stop(){clearInterval(timer);timer=null;play.textContent='Play the movement';play.setAttribute('aria-pressed','false');}
play.addEventListener('click',()=>{if(timer!==null){stop();return;}if(!preloaded){for(let i=0;i<96;i++){const im=new Image();im.src='motion-'+String(i).padStart(3,'0')+'.png';}preloaded=true;}play.textContent='Pause';play.setAttribute('aria-pressed','true');timer=setInterval(()=>show(index+1),125);});
slider.addEventListener('input',()=>{stop();show(Number(slider.value));});
document.getElementById('motion-step').addEventListener('click',()=>{stop();show((Math.floor(index/4)+1)*4);});
document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});
