import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
const folder=path.join(root,'commons/maps/Random_Definition');
const extension=path.join(folder,'seed-picture-extension.md');
if(!fs.existsSync(extension))fs.copyFileSync(path.join(here,'before/tutorial.md'),extension);
let text=fs.readFileSync(path.join(here,'tutorial-opening.md'),'utf8');
for(const [marker,file] of [['MOTION_CODE','motion_record.gd'],['SCENE_CODE','random_touch.gd']])text=text.replace('{{'+marker+'}}','```gdscript\n'+fs.readFileSync(path.join(root,'commons/artifacts/random_touch',file),'utf8').trimEnd()+'\n```');
const target=path.join(folder,'tutorial.md');
if(fs.readFileSync(target,'utf8')!==text){
 const temp=path.join(folder,`tutorial.${process.pid}.tmp`);
 fs.writeFileSync(temp,text);
 fs.renameSync(temp,target);
}
const body=text.replace(/```[\s\S]*?```/g,'').replace(/<!--[^]*?-->/g,'').replace(/\[([^\]]+)\]\([^)]+\)/g,'$1');
const words=body.split(/\s+/).filter(Boolean).length;
const codeLines=[...text.matchAll(/```gdscript\n([\s\S]*?)```/g)].reduce((n,m)=>n+m[1].split('\n').filter(l=>l.trim()).length,0);
console.log(JSON.stringify({tutorialWords:words,nonblankCodeLines:codeLines,completeSourceFiles:2}));
