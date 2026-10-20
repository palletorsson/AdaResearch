const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),path=require('node:path');
const els={};const docEvents={};let tick=null;
for(const id of ['motion-frame','motion-label','motion-play','motion-position','motion-step'])els[id]={value:'0',events:{},attrs:{},addEventListener(e,fn){this.events[e]=fn;},setAttribute(k,v){this.attrs[k]=v;}};
const context={document:{hidden:false,getElementById:id=>els[id],addEventListener:(e,fn)=>docEvents[e]=fn},Image:class{},setInterval(fn){tick=fn;return 1;},clearInterval(){tick=null;}};
vm.runInNewContext(fs.readFileSync(path.join(__dirname,'motion-viewer.js'),'utf8'),context);
const checks=[];function check(name,fn){fn();checks.push({name,passed:true});}
check('play starts',()=>{els['motion-play'].events.click();assert.equal(els['motion-play'].attrs['aria-pressed'],'true');assert.equal(typeof tick,'function');});
check('play advances a native frame',()=>{tick();assert.equal(els['motion-frame'].src,'motion-001.png');});
check('pause stops',()=>{els['motion-play'].events.click();assert.equal(tick,null);assert.equal(els['motion-play'].attrs['aria-pressed'],'false');});
check('scrub selects family and pauses',()=>{els['motion-position'].value='36';els['motion-position'].events.input();assert.match(els['motion-label'].textContent,/DIAMONDS/);assert.equal(els['motion-frame'].src,'motion-036.png');assert.equal(tick,null);});
check('next pose skips to the next exact pose',()=>{els['motion-step'].events.click();assert.equal(els['motion-frame'].src,'motion-040.png');});
check('last frame loops',()=>{els['motion-position'].value='95';els['motion-position'].events.input();els['motion-play'].events.click();tick();assert.equal(els['motion-frame'].src,'motion-000.png');});
check('hidden tab pauses',()=>{context.document.hidden=true;docEvents.visibilitychange();assert.equal(tick,null);assert.equal(els['motion-play'].attrs['aria-pressed'],'false');});
fs.writeFileSync(path.join(__dirname,'viewer-checks.json'),JSON.stringify({passed:true,checks,scope:'DOM event harness; not a browser rendering or click-session test.'},null,2)+'\n');
console.log('Viewer '+checks.length+'/'+checks.length);
