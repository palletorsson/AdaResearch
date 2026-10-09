from pathlib import Path
import json
r=Path.cwd();o=Path(__file__).parent
def edit(rel,fn):
 p=r/rel;assert p.read_bytes()==(o/'before'/rel).read_bytes(),rel
 p.write_text(fn(p.read_text(encoding='utf-8-sig')),encoding='utf-8')
def source(s):
 needle='\tvar field_changed: bool = false\n'
 assert s.count(needle)==1
 s=s.replace(needle,needle+'''	var material_changed: bool = false
	# Per-placement staging. Colour does not redraw the field or its collision.
	if config.has("surface_color"):
		var tint := Color.from_string(str(config["surface_color"]), surface_color)
		if not tint.is_equal_approx(surface_color):
			surface_color = tint
			material_changed = true
	if config.has("emission_strength"):
		var strength := clampf(float(config["emission_strength"]), 0.0, 4.0)
		if not is_equal_approx(strength, emission_strength):
			emission_strength = strength
			material_changed = true
''')
 needle='\t\trng.seed = seed_value\n\t\tgenerate_space()'
 assert s.count(needle)==1
 return s.replace(needle,needle+'\n\telif material_changed:\n\t\t_setup_material()')
edit('commons/context/walkgrids/RandomSpace.gd',source)
def map_edit(s):
 assert s.count('random_space:0:-0.3:1.4')==1
 s=s.replace('random_space:0:-0.3:1.4','random_space:0:-0.3:1.4#offset:0,0.2,0#surface_color:6b427d#emission_strength:0.02')
 assert s.count('worley_noise:0:-0.5#plinth:0.35')==1
 return s.replace('worley_noise:0:-0.5#plinth:0.35','worley_noise:0:-0.5#plinth:0.4')
edit('commons/maps/Random_Space/map_data.json',map_edit)
print('This hall opts into a 20 cm floor lift, violet material, low emission and a 5 cm higher cellular stand.')
