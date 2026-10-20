import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {fileURLToPath,pathToFileURL} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
const {load}=await import(pathToFileURL(path.resolve(root,'../ada_encyclopedia/tests/writing-wall/load.mjs')).href);
const {loadWall}=load('lib/writing-wall-store'),{roomLayoutIssues,walkingRoute}=load('lib/writing-room');
// Repair the initial staging height once: the third token field is absolute Y.
const file=path.join(root,'commons/maps/Random_Definition/map_data.json'),raw=fs.readFileSync(file,'utf8');
const token=JSON.parse(raw).layers.interactables[1][1];
if(token==='random_touch:270:1:1'){
 const r=await fetch('http://localhost:3003/api/maps/cell-edit',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({map:'Random_Definition',expect_sha256:createHash('sha256').update(raw).digest('hex'),operations:[{op:'set',layer:'interactables',cell:[1,0,1],expect:token,token:'random_touch:270:0:1'}],rebuild_strip:true})});
 const result=await r.json();assert.ok(r.ok&&!result.error);fs.writeFileSync(path.join(here,'height-correction.json'),JSON.stringify(result,null,2)+'\n');
}
assert.equal(JSON.parse(fs.readFileSync(file,'utf8')).layers.interactables[1][1],'random_touch:270:0:1');
const m=loadWall(root,'Random_Definition');
const selected=m.wall.order.filter(id=>m.wall.magnets.find(m=>m.id===id).tags?.includes('final'));
assert.equal(selected.length,6);assert.deepEqual(selected,m.passages.final.map(p=>p.lookup));
assert.deepEqual(roomLayoutIssues(m),[]);const route=walkingRoute(m,selected);assert.deepEqual(route.unreachable,[]);assert.equal(route.legs.length,5);
assert.ok(selected.every((id,i)=>!i||m.artifacts.find(a=>a.id===id).z>=m.artifacts.find(a=>a.id===selected[i-1]).z));
const tutorial=fs.readFileSync(path.join(root,'commons/maps/Random_Definition/tutorial.md'),'utf8');
const code=[...tutorial.matchAll(/```gdscript\n([\s\S]*?)```/g)].map(m=>m[1].trim());
for(const [i,name] of ['motion_record.gd','random_touch.gd'].entries())assert.equal(code[i],fs.readFileSync(path.join(root,'commons/artifacts/random_touch',name),'utf8').trim());
for(const rel of ['commons/maps/Random_Definition/tutorial.md','doc/book/course/text-plans/Random_Definition/final.md','doc/book/course/text-plans/Random_Definition/tutorial.md']){
 const f=path.join(root,rel),text=fs.readFileSync(f,'utf8');for(const match of text.matchAll(/\]\(([^)#]+)(?:#[^)]*)?\)/g)){if(/^(https?:|\/)/.test(match[1]))continue;assert.ok(fs.existsSync(path.resolve(path.dirname(f),match[1])),`${rel}: ${match[1]}`);}
}
const body=tutorial.replace(/```[\s\S]*?```/g,'').replace(/<!--[^]*?-->/g,'').replace(/\[([^\]]+)\]\([^)]+\)/g,'$1');
const result={finalWords:m.passages.final.map(p=>p.text).join(' ').split(/\s+/).filter(Boolean).length,tutorialWords:body.split(/\s+/).filter(Boolean).length,codeLines:code.reduce((n,c)=>n+c.split('\n').filter(l=>l.trim()).length,0),selected,optionalCount:m.artifacts.length-selected.length,sharedOrderMatches:true,mainRouteReachable:true,layoutIssues:[],touchRootY:0,printedCodeMatches:true,relativeLinksResolve:true,vrFeel:'Unobserved',readerResponse:'Not yet collected for six-stop edition'};
fs.writeFileSync(path.join(here,'current-checks.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result,null,2));
