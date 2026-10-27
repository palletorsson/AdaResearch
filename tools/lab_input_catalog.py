"""Resolve lab inputs from the existing shared prefab catalogue, not a second mesh list."""
import hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def inputs():
    catalogue={v['id']:v for v in json.loads((ROOT/'commons/void/primitive-prefabs.json').read_text(encoding='utf8'))['prefabs']}
    result={}
    for entry in json.loads((ROOT/'commons/modular/lab.json').read_text(encoding='utf8'))['sources']:
        item={**catalogue.get(entry['id'],{}),**entry};scene=item.get('scene','')
        assert scene.startswith('res://') and (ROOT/scene[6:]).is_file(), 'Unavailable prefab: '+entry['id']
        item['label']=item.get('label',item.get('title',item['id']))
        result[item['id']]=item
    return result
def fingerprint(item):
    scene=ROOT/item['scene'][6:];files={scene}
    for script in re.findall(r'path="(res://[^\"]+\.gd)"',scene.read_text(encoding='utf8')):files.add(ROOT/script[6:])
    h=hashlib.sha256(json.dumps(item,sort_keys=True,ensure_ascii=False).encode())
    h.update((ROOT/'commons/modular/lab_input.gd').read_bytes())
    for file in sorted(files):h.update(file.read_bytes())
    return h.hexdigest()
