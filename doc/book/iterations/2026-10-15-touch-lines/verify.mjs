import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const wall=JSON.parse(read('commons/maps/Random_Definition/writing_wall.json'));
const registry=JSON.parse(read('commons/artifacts/registry/randomness.json'));
const final=read('commons/maps/Random_Definition/final.md'),tutorial=read('commons/maps/Random_Definition/tutorial.md');
const markers=[...final.matchAll(/<!-- @([^ ]+) -->/g)].map(m=>m[1]);
const selected=wall.order.filter(id=>wall.magnets.find(m=>m.id===id)?.tags?.includes('final'));
const blocks=[...tutorial.matchAll(/```gdscript\n([\s\S]*?)```/g)].map(m=>m[1].trim());
assert.equal(blocks.length,2);
for(const [i,file] of ['motion_record.gd','random_touch.gd'].entries())assert.equal(blocks[i],read('commons/artifacts/random_touch/'+file).trim());
assert.ok(fs.existsSync(path.join(root,registry.artifacts.random_touch.scene.replace('res://',''))));
for(const rel of ['commons/maps/Random_Definition/tutorial.md','doc/book/course/text-plans/Random_Definition/final.md','doc/book/course/text-plans/Random_Definition/tutorial.md']){
 for(const m of read(rel).matchAll(/\]\(([^)#]+)(?:#[^)]*)?\)/g)){
  if(/^(https?:|\/)/.test(m[1]))continue;
  assert.ok(fs.existsSync(path.resolve(root,path.dirname(rel),m[1])),rel+': '+m[1]);
 }
}
const prose=final.split('<!-- @ -->')[0].replace(/^#.*$/gm,'').replace(/<!--[\s\S]*?-->/g,'').replace(/\[\^.*?\]/g,'');
const result={finalWords:prose.trim().split(/\s+/).length,...JSON.parse(fs.readFileSync(path.join(here,'text-counts.json'),'utf8')),printedCodeMatches:true,relativeLinksResolve:true,mainPassages:markers,selectedWallOrder:selected,orderMatches:JSON.stringify(markers)===JSON.stringify(selected),artifactLookup:'random_touch',physicalHeadsetFeel:'Unobserved',proseWinner:'None selected'};
fs.writeFileSync(path.join(here,'verification.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result,null,2));
