import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'../../..'),web=path.resolve(root,'../ada_encyclopedia');
const slug=path.basename(here),source=fs.readFileSync(path.join(here,'post.md'),'utf8');
const destination=path.join(web,'src/content/blog',slug+'.md');
assert.equal(fs.readFileSync(destination,'utf8'),source);
const checked=[];
for(const match of source.matchAll(/\]\((\/book-review\/[^)#]+|\/blog\/[^)#]+)\)/g)){
 const url=match[1];
 const target=url.startsWith('/book-review/')?path.join(root,url.slice('/book-review/'.length)):path.join(web,'src/content/blog',url.slice('/blog/'.length)+'.md');
 assert.ok(fs.existsSync(target),target);checked.push(url);
}
const processFiles=['doc/book/course/ENCOUNTER_RESEARCH_LOOP.md','doc/book/course/ENCOUNTER_CYCLE_TEMPLATE.md'];
for(const rel of processFiles){const filename=path.join(root,rel),body=fs.readFileSync(filename,'utf8');for(const m of body.matchAll(/\]\(([^)#]+)(?:#[^)]*)?\)/g)){if(/^(https?:|\/)/.test(m[1]))continue;assert.ok(fs.existsSync(path.resolve(path.dirname(filename),m[1])),m[1]);}}
const url='http://localhost:3003/blog/'+slug;
const response=await fetch(url);assert.equal(response.status,200);
const html=await response.text();assert.ok(html.includes('What an Encounter Makes Necessary'));assert.ok(html.includes('one row every two and a half seconds'));
const receipt={date:'2026-10-15',status:'local publication; no remote deployment or push',url,source:'post.md',local_publication:destination,post_sha256:createHash('sha256').update(source).digest('hex'),checked_links:checked,http_status:response.status,bodyPresent:true,visualInspection:false,processEntryPoints:['doc/book/STATE.md','doc/book/course/WRITING_ROLES_AND_DECISIONS.md','doc/book/RECURSIVE_ARCHITECTURE.md'],evidenceLimit:'Technical and editorial history described; revised reader comprehension and VR pacing remain unobserved.'};
fs.writeFileSync(path.join(here,'publication.json'),JSON.stringify(receipt,null,2)+'\n');console.log(JSON.stringify(receipt,null,2));
