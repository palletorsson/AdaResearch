from pathlib import Path
import hashlib,json,datetime
base=Path(__file__).resolve().parent
manifest={}
for label,dt in [('coarse','0.05'),('fine','0.025')]:
    folder=base/'variants'/label; folder.mkdir(parents=True,exist_ok=True)
    for name in ['field.gd','study.gd','point_body.gd','study.tscn']:
        text=(base/'reconstructed'/'flow'/name).read_text(encoding='utf-8')
        if name=='field.gd':
            text=text.replace('const DT := 0.05',f'const DT := {dt}')
            a=text.index('func set_patch() -> void:'); b=text.index('\nfunc edit_cell',a)
            text=text[:a]+'''func set_patch() -> void:
\tvectors.fill(Vector2.RIGHT)
\tfor y in range(WIDTH):
\t\tfor x in range(7,9):
\t\t\tvectors[x+y*WIDTH] = Vector2.ZERO
'''+text[b:]
            text=text.replace('\tset_patch()\n','\tset_patch()\n\tpositions[0] = Vector2(7.6,1.5)\n\tvelocities[0] = Vector2(3,0)\n',1)
        p=folder/name; p.write_bytes(text.encode())
        manifest[str(p.relative_to(base))]=hashlib.sha256(p.read_bytes()).hexdigest()
(base/'variants'/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
p=base/'PREDICTIONS.md'
(base/'prediction_freeze.json').write_text(json.dumps({'frozen_before_execution_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()},indent=2),encoding='utf-8')
