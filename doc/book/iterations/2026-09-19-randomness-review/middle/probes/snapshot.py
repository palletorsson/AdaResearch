from pathlib import Path
import json,re,shutil,hashlib
root=Path.cwd();base=root/'doc/book/iterations/2026-09-19-randomness-review/middle'
maps=['Random_Rotate_Random_XYZ','Random_Walk','Random_Gaussian','Random_Mushrooms']
ids=set()
files=set(['commons/data/artifact_roles.json','commons/scenes/endless_museum.gd','doc/book/REVIEW_PRINCIPLES.md','doc/book/review-feedback/2026-09-18/randomness/01-review.md'])
for name in maps:
    folder=Path('commons/maps')/name
    files.update(str(p).replace('\\','/') for p in folder.glob('*.md'))
    files.add((folder/'map_data.json').as_posix())
    d=json.loads((folder/'map_data.json').read_text(encoding='utf8'))
    ids.update(re.split('[:#]',v)[0] for row in d['layers']['interactables'] for v in row if v.strip())
records={}
for registry in Path('commons/artifacts/registry').glob('*.json'):
    try:d=json.loads(registry.read_text(encoding='utf8')).get('artifacts',{})
    except:continue
    for id in ids:
        if id in d:
            records[id]={'registry':registry.as_posix(),'scene':d[id].get('scene')}
            files.add(registry.as_posix())
pending=[v['scene'].removeprefix('res://') for v in records.values() if v['scene']]
while pending:
    p=pending.pop()
    if p in files or not Path(p).is_file():continue
    files.add(p)
    if Path(p).suffix.lower() in ['.gd','.tscn','.tres','.gdshader']:
        for dep in re.findall(r'res://([^"\s]+)',Path(p).read_text(encoding='utf8')):
            if Path(dep).suffix.lower() in ['.gd','.tscn','.tres','.gdshader'] and dep not in files:pending.append(dep)
manifest={}
for p in sorted(files):
    src=root/p;dst=base/'before-source'/p
    dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
    manifest[p]=hashlib.sha256(src.read_bytes()).hexdigest()
(base/'before-sha256.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
(base/'artifact-source-index.json').write_text(json.dumps(records,indent=2),encoding='utf8')
print('frozen',len(files),'files;',len(records),'artifact entries')
