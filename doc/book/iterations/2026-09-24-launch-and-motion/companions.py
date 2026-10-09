from pathlib import Path
import hashlib,json
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-launch-and-motion';base=json.loads((out/'baseline.json').read_text(encoding='utf-8'))
changed=[f'commons/maps/{m}/final.md' for m in ['VFM_05_Launch','VFM_03_Motion']]
for m in ['VFM_05_Launch','VFM_03_Motion']:
 rel=f'commons/maps/{m}/tutorial.md';p=root/rel
 assert hashlib.sha256(p.read_bytes()).hexdigest()==base[rel]
 s=p.read_text(encoding='utf-8-sig')
 s+='\n## Reading and retained detail\n\nThe canonical [chapter](final.md) follows the encounter. Exact control steps, arrow scales, timing, bounded histories and reset rules remain here. The complete [pre-pass chapter](../../../doc/book/iterations/2026-09-24-launch-and-motion/before/commons/maps/'+m+'/final.md) is retained for comparison. This reading pass does not claim a new runtime or headset test.\n'
 p.write_text(s,encoding='utf-8');changed.append(rel)
rel='commons/maps/VFM_03_Motion/walked.md';p=root/rel
assert hashlib.sha256(p.read_bytes()).hexdigest()==base[rel]
s=p.read_text(encoding='utf-8-sig');title,body=s.split('\n',1)
s=title+'\n\n> Historical exploratory draft, retained as written. The current [chapter](final.md) follows the motion chamber and friction ramp. Its distinction between a continuing velocity and an applied force supersedes the closing claim here about what forces have “most recently decided.”\n'+body
p.write_text(s,encoding='utf-8');changed.append(rel)
(out/'changed-files.json').write_text(json.dumps(changed,indent=2)+'\n',encoding='utf-8')
(out/'images').mkdir(exist_ok=True)
for name in ['launch_chamber_inside.png','motion_chamber_inside.png']:(out/'images'/name).write_bytes((root/'doc/research/possible-bodies'/name).read_bytes())
print('Companion links, historical draft note and unchanged native image copies saved.')
