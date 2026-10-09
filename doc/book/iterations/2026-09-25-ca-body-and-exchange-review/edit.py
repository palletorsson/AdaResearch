from pathlib import Path
import hashlib,json
r=Path.cwd();o=Path(__file__).resolve().parent
baseline=json.loads((o/'baseline.json').read_text())
changes={
 'commons/maps/CA_ExpandingSpace/final.md':[
  ('Begin at the desk. SOURCE can nominate the pink probe in your place. With PROBE / NEAR showing, press RUN.', 'Begin at the desk. Press SOURCE once to put the pink probe in your place. The readout shows PROBE / NEAR. Press RUN.'),
  ('The frieze uses the same health materials, but its coloured panels supply no bridge collision.', 'The frieze wears the same changing colours. Its solid backing remains even when the tile can no longer carry you.')],
 'commons/maps/CA_SoftRules/final.md':[
  ('At the side desk, find W. It lies just outside the seeded square. Its V reading is zero in both fields.', 'Find the small gold frame on either table, just outside the seeded square. This is W; the side desk reads its values. V is zero there in both fields.'),
  ('Two choices have changed: a cell holds two fractions instead of one bit, and what it consults is not a count but a difference.', 'Each cell now holds two fractions, and a neighbour matters by how much its concentration differs.')],
 'algorithms/cellularautomata/living_architecture/proximity_study.gd':[
  ('# The frieze wears the same graded state, with no collision mapping.', '# The panels share the bridge state; the fixed backing is solid at every health.'),
  ('Vector3(3.1,1.45,4.5),Color("20373a"))', 'Vector3(3.1,1.45,4.5),Color("20373a"),true)'),
  ('var tag:=label("WitnessTag","W (2,6)",32);tag.position=at+Vector3(-0.85,0.01,0);tag.rotation_degrees=Vector3(-90,0,0);add_child(tag)', 'var tag:=label("WitnessTag","W (2,6)",40);tag.position=at+Vector3(-0.85,0.01,0);tag.rotation_degrees=Vector3(-90,180,0);tag.modulate=Color("273941");add_child(tag)'),
  ('var warning:=label("BasinNote","FIXED BASIN 0.60 m BELOW / RECOVERY RAMPS ON LEFT",27)\n\twarning.position=Vector3(0,0.025,-0.95);warning.rotation_degrees=Vector3(-90,0,0);add_child(warning)', 'var warning:=label("BasinNote","BASIN 0.60 m BELOW\\nRAMPS ON RIGHT / DESK SIDE",40)\n\twarning.pixel_size=0.002;warning.modulate=Color("273941")\n\twarning.position=Vector3(0,0.025,-0.95);warning.rotation_degrees=Vector3(-90,180,0);add_child(warning)')]
}
for rel,pairs in changes.items():
 p=r/rel;assert hashlib.sha256(p.read_bytes()).hexdigest()==baseline[rel], 'Concurrent change: '+rel
 text=p.read_text(encoding='utf-8')
 for old,new in pairs:
  assert text.count(old)==1,(rel,old);text=text.replace(old,new)
 p.write_bytes(text.encode('utf-8'))
(o/'changed-files.json').write_bytes((json.dumps(list(changes),indent=2)+'\n').encode())
print('Changed',len(changes),'files')
