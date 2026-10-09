from pathlib import Path
import json,hashlib,difflib
base=Path('doc/book/iterations/2026-09-19-forces-review/motion')
snap=json.loads((base/'before-sha256.json').read_text())
paths=['algorithms/vectors/10_vector_field_flow/field_receivers.gd','commons/maps/Vectors_Act4a_KineticForces/map_data.json']
for path in paths:
 assert hashlib.sha256(Path(path).read_bytes()).hexdigest()==snap[path],path+' changed concurrently'
p=Path(paths[0]);s=p.read_text(encoding='utf8')
s=s.replace('var wall_markers: Array[Node3D] = []','var wall_markers: Array[Node3D] = []\nvar receiver_labels: Array[Label3D] = []')
s=s.replace('nameplate.text = "SET v" if i == 0 else "ADD to v"','nameplate.text = "CYAN" if i == 0 else "PINK"\n\t\treceiver_labels.append(nameplate)')
s=s.replace('Cyan: SET velocity. Pink: ADD to velocity.','Follow cyan and pink; pause and compare their paths.')
s=s.replace('Both sample the same field at their own positions.','RULE reveals how each body receives the field.')
s=s.replace('func update_views() -> void:\n\tupdate_markers()','func update_views() -> void:\n\tupdate_markers()\n\t# Keep body identity visible; the existing RULE control reveals the receiver operation.\n\tfor i in receiver_labels.size():\n\t\treceiver_labels[i].text = (["SET v", "ADD to v"] if rule_visible else ["CYAN", "PINK"])[i]')
p.write_text(s,encoding='utf8',newline='\n')
p=Path(paths[1]);d=json.loads(p.read_text(encoding='utf8'));g=d['layers']['interactables']
assert g[24][9].startswith('centrifuge_ring') and g[37][8]=='force_mower'
g[24][9],g[37][8]=g[37][8],g[24][9]
assert g[40][9]=='sisyphus_mower' and not g[37][21].strip()
blank=g[37][21];g[37][21]=g[40][9];g[40][9]=blank
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
for path in paths:
 old=(base/'before-source'/path).read_text(encoding='utf8');new=Path(path).read_text(encoding='utf8')
 (base/(Path(path).stem+'.diff')).write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+path,tofile=path)),encoding='utf8')
print('Applied FIELD reveal and4 changed Kinetic cells; no manuscript edit.')
