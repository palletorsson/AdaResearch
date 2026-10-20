import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
let text=fs.readFileSync(path.join(here,'tutorial-source.md'),'utf8');
for(const [marker,file] of [['MOTION_CODE','motion_record.gd'],['SCENE_CODE','random_touch.gd'],['HAND_CODE','hand_follower.gd']]) text=text.replace('{{'+marker+'}}','```gdscript\n'+fs.readFileSync(path.join(root,'commons/artifacts/random_touch',file),'utf8').trimEnd()+'\n```');
const target=path.join(root,'commons/maps/Random_Definition/tutorial.md');
if(fs.readFileSync(target,'utf8')!==text){const temp=target+'.tmp';fs.writeFileSync(temp,text);fs.renameSync(temp,target);}
const body=text.replace(/```[\s\S]*?```/g,'').replace(/<!--[\s\S]*?-->/g,'').replace(/\[([^\]]+)\]\([^)]+\)/g,'$1');
const result={tutorialWords:body.split(/\s+/).filter(Boolean).length,codeLines:[...text.matchAll(/```gdscript\n([\s\S]*?)```/g)].reduce((n,m)=>n+m[1].split('\n').filter(l=>l.trim()).length,0)};
fs.writeFileSync(path.join(here,'text-counts.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result));
