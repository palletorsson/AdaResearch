// Production editor operations on a draft; never save test placements.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia');
const ts=require(path.join(web,'node_modules/typescript')),context={exports:{},require,structuredClone};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(web,'src/components/lab-editor/void-model.ts'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
async function main(){
  const endpoint='http://localhost:3003/api/void-layout';
  const payload=await(await fetch(endpoint)).json();
  const models=JSON.parse(fs.readFileSync(path.join(web,'public/void-models/manifest.json'),'utf8'));
  const checks=[];
  function check(name,fn){fn();checks.push({name,passed:true});}
  check('one shared room replaces the separate black box',()=>{
    assert.equal(payload.rooms.floors[3].artifacts.filter(a=>a.id==='setting_out').length,1);
    assert.equal(payload.rooms.floors[3].artifacts.some(a=>a.id==='museum-point_lines-11-13'),false);
    assert.equal(models.floors['3'].artifacts['museum-point_lines-11-13'],undefined);
  });
  const {listEntries,place,turn,copyObject,pasteObject}=context.exports;
  const draft=structuredClone(payload.rooms),floor=draft.floors[3];
  let entries=listEntries(floor,payload,models,3);
  const room=entries.find(e=>e.kind==='part'&&e.artifactId==='setting_out'&&e.id==='MeasurementRoom');
  check('combined room has a real exported model',()=>{
    assert.ok(room?.model?.url);
    const file=path.join(web,'public',room.model.url.split('?')[0]);
    const bytes=fs.readFileSync(file);assert.equal(bytes.toString('ascii',0,4),'glTF');assert.ok(bytes.length>10000);
  });
  check('same editable room can move and rotate',()=>{
    place(floor,room,[room.position[0]+.5,room.position[1],room.position[2]-.5],payload);
    entries=listEntries(floor,payload,models,3);
    turn(floor,entries.find(e=>e.key===room.key));
    const moved=listEntries(floor,payload,models,3).find(e=>e.key===room.key);
    assert.equal(moved.rotation[1],room.rotation[1]+90);
    assert.equal(moved.position[0],room.position[0]+.5);
  });
  check('copy keeps the combined puzzle and measuring room as one part',()=>{
    const moved=listEntries(floor,payload,models,3).find(e=>e.key===room.key);
    const key=pasteObject(floor,copyObject(floor,moved,payload,3),4);
    const copy=listEntries(floor,payload,models,3).find(e=>e.key===key);
    assert.equal(copy.id,'MeasurementRoom');assert.notEqual(copy.artifactId,'setting_out');
  });
  const response=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rooms:draft,revision:payload.revision,validateOnly:true})});
  const validation=await response.json();
  check('production API validates the moved and copied draft',()=>assert.equal(validation.valid,true,JSON.stringify(validation)));
  check('native layout and Desktop mirror match; draft was not saved',()=>{
    assert.deepEqual(JSON.parse(fs.readFileSync(path.join(root,'commons/void/rooms.json'),'utf8')),payload.rooms);
    assert.deepEqual(JSON.parse(fs.readFileSync('C:/Users/palle/Desktop/Ada Void/rooms.json','utf8')),payload.rooms);
  });
  fs.writeFileSync(path.join(root,'ada_run/lines-combined-room/editor-checks.json'),JSON.stringify({passed:true,checks},null,2));
  console.log(`${checks.length} editor checks passed`);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
