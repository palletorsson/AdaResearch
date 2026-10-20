// No writes to the user's layout. Exercise real exported lamps and Three groups.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const request=require('node:module').createRequire(path.join(web,'package.json'));
const ts=request('typescript'),THREE=request('three');
function moduleAt(name){const ctx={exports:{},require:request,structuredClone};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor',name),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,ctx);return ctx.exports;}
const {makeLamp,VoidLighting}=moduleAt('void-lighting.ts'),{listEntries,copyObject,pasteObject}=moduleAt('void-model.ts');
const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json')));
const checks=[];function check(name,fn){fn();checks.push({name,passed:true});}
const near=(a,b)=>assert.ok(Math.abs(a-b)<1e-5,`${a} != ${b}`);
async function main(){
  const payload=await(await fetch('http://localhost:3003/api/void-layout')).json();const before=JSON.stringify(payload.rooms);
  const entries=listEntries(payload.rooms.floors[3],payload,models,3);
  const work=entries.find(e=>e.kind==='prop'&&e.model?.lights?.length).model.lights[0];
  check('Placed work lamps use the actual reduced floor energy, not palette brightness',()=>{near(work.energy,1.2);near(work.range,10);near(work.angle,57);assert.equal(work.type,'spot');assert.equal(work.color,'ffe1b0');});
  check('Sky export contains real HDR data and evening source settings',()=>{near(models.lighting.sun_energy,.18);near(models.lighting.ambient_energy,.24);near(models.lighting.fog_end,30);assert.equal(fs.readFileSync(path.join(web,'public',models.lighting.sky_url)).readUInt32LE(0),20000630);});
  check('Spot direction follows exported -Z, including rotated and translated placements',()=>{
    const lamp=makeLamp(work),parent=new THREE.Group();parent.position.set(7,2,-3);parent.rotation.y=Math.PI/2;parent.add(lamp.rig);parent.updateMatrixWorld(true);
    const from=lamp.light.getWorldPosition(new THREE.Vector3()),to=lamp.light.target.getWorldPosition(new THREE.Vector3());
    const expected=new THREE.Vector3(0,0,-1).transformDirection(new THREE.Matrix4().multiplyMatrices(parent.matrixWorld,new THREE.Matrix4().fromArray(work.matrix)));
    near(to.sub(from).normalize().dot(expected),1);
    const old=from.clone();parent.position.x+=2;parent.updateMatrixWorld(true);near(lamp.light.getWorldPosition(new THREE.Vector3()).x-old.x,2);lamp.light.dispose();
  });
  const table=entries.find(e=>e.id==='FloorPlanTable');
  check('Ruler lamp survives a copy with its model-local position and inactive state',()=>{
    const floor=structuredClone(payload.rooms.floors[3]);const clip=copyObject(floor,table,payload,3);pasteObject(floor,clip,1);
    const copied=listEntries(floor,payload,models,3).find(e=>e.key.includes(floor.copies.at(-1).id)&&e.model?.lights?.length);
    assert.equal(JSON.stringify(copied.model.lights),JSON.stringify(table.model.lights));assert.equal(copied.model.lights[0].visible,false);
  });
  const scene=new THREE.Scene(),renderer={shadowMap:{autoUpdate:true,needsUpdate:false},toneMappingExposure:1};
  const lighting=new VoidLighting(scene,renderer,()=>{}),host=new THREE.Group();scene.add(host);
  lighting.add({lights:[work]},host,'work');lighting.add(table.model,host,'table');
  const lights=()=>{const found=[];host.traverse(o=>{if(o.isLight)found.push(o);});return found;};
  check('Pickup lamp starts off; selecting alone does not switch it on',()=>{lighting.select(['table']);assert.equal(lights().filter(l=>l.visible).length,1);});
  check('Selected lamp preview illuminates only the selection and restores rest on deselect',()=>{lighting.set('evening',true);assert.equal(lights().filter(l=>l.visible).length,2);lighting.select([]);assert.equal(lights().filter(l=>l.visible).length,1);});
  check('Neutral editing disables simulated local lamps without touching their source data',()=>{lighting.set('neutral',true);assert.equal(lights().filter(l=>l.visible).length,0);assert.equal(table.model.lights[0].visible,false);});
  check('Lamp shadows stay bounded; rebuilding disposes old lamps',()=>{lighting.set('evening',false);for(let i=0;i<10;i++)lighting.add({lights:[work]},host,String(i));assert.ok(lights().filter(l=>l.castShadow).length<=4);lighting.reset();assert.equal(lights().length,0);lighting.dispose();});
  check('Preview and copy tests leave the shared layout unchanged',()=>assert.equal(JSON.stringify(payload.rooms),before));
  const after=await(await fetch('http://localhost:3003/api/void-layout')).json();assert.equal(after.revision,payload.revision);
  const out=path.join(root,'doc/book/iterations/2026-10-19-editor-evening');fs.mkdirSync(out,{recursive:true});fs.writeFileSync(path.join(out,'checks.json'),JSON.stringify({passed:true,checks,layout_revision:after.revision},null,2));console.log(checks.length+' lighting checks passed');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
