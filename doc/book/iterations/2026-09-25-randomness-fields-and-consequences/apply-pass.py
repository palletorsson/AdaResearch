from pathlib import Path
import json
r=Path.cwd();o=Path(__file__).parent
def edit(rel,fn):
 p=r/rel;before=o/'before'/rel;assert p.read_bytes()==before.read_bytes(),f'Concurrent edit: {rel}'
 p.write_text(fn(p.read_text(encoding='utf-8-sig')),encoding='utf-8')
def rep(s,a,b):assert s.count(a)==1,repr(a);return s.replace(a,b)
def mushrooms(s):
 return rep(s,'func _prepare_stand() -> void:', '''func _prepare_stand() -> void:
	# Standalone preview furniture is not part of the specimen population.
	# Remove it only for this opt-in staging; leave the authored scene intact.
	for node_name in ["Camera3D", "FillLight", "MeshInstance3D"]:
		var demo := get_node_or_null(node_name)
		if demo != null:
			remove_child(demo)
			demo.queue_free()
	set_meta("specimen_scene_cleaned", true)''')
edit('algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.gd',mushrooms)
def geometry(s):
 d=json.loads(s);g=d['layers']['interactables'];new=[[' ']*12 for _ in range(24)]
 for z,row in enumerate(g):
  for x,v in enumerate(row):
   if str(v).strip():
    assert z>=23 and x<12
    assert d['layers']['structure'][z-7][x]=='1'
    new[z-7][x]=v
 d['layers']['interactables']=new
 d['map_info']['dimensions']['width']=12;d['map_info']['dimensions']['depth']=24
 return json.dumps(d,ensure_ascii=False,indent=2)+'\n'
edit('commons/maps/Random_Space_Geometry/map_data.json',geometry)
def dart(s):
 s=rep(s,'func _input(event: InputEvent) -> void:\n\tif event is InputEventKey and event.pressed:', 'func _input(event: InputEvent) -> void:\n\tif not keyboard_shortcuts:\n\t\treturn\n\tif event is InputEventKey and event.pressed and not event.echo:')
 s=rep(s,'func _input(event: InputEvent) -> void:', '## Standalone demo keys remain available; museum placements use the console.\n@export var keyboard_shortcuts: bool = true\n\nfunc _input(event: InputEvent) -> void:')
 return rep(s,'func apply_grid_config(config: Dictionary) -> void:', 'func apply_grid_config(config: Dictionary) -> void:\n\tif config.has("keyboard"):\n\t\tkeyboard_shortcuts = str(config["keyboard"]).to_lower() != "off"')
edit('algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.gd',dart)
def gallery(s):
 d=json.loads(s);hits=[v for row in d['layers']['interactables'] for v in row if 'monte_carlo_dartboard' in v];assert len(hits)==1
 return rep(s,hits[0],hits[0]+'#keyboard:off')
edit('commons/maps/Randomness_Examples_of_Randomness/map_data.json',gallery)
def mushroom_text(s):
 s=rep(s,'In the headset, hold one and bring it close to your face:', 'Hold one and bring it close to your face:')
 return rep(s,' The desktop carry lets you inspect it, but holds it beyond that eating distance.','')
edit('commons/maps/Random_Mushrooms/final.md',mushroom_text)
edit('commons/maps/Random_Space_Geometry/final.md',lambda s:rep(s,'Look closely at neighbouring columns','Through the connecting passage, the comparison bench stands among the shapes in the second room. Look closely at neighbouring columns'))
edit('commons/maps/Randomness_Examples_of_Randomness/final.md',lambda s:rep(s,'Four works have returned to the gallery.','Four works share the gallery.'))
def pheromone(s):return rep(rep(s,'signal-guided: 40%','signal-guided: 30%'),'the four walkers begin again','the five walkers begin again')
edit('commons/maps/Random_Pheromone/final.md',pheromone)
def space(s):
 needle='Back at the plinth, colour supplies another part of the picture\'s reading.'
 extra='''<!-- @worley_noise -->

On the floor to the right of the mixer, a small blue cellular field offers another way for neighbours to belong together. Here the value comes from a difference between distances: how far away are the nearest scattered point and the next nearest? Along a seam those distances nearly agree. Follow one seam, then look back at the mixer's broad layers. Both can suggest a landscape, but their neighbours have been related by different rules.

<!-- @shannon_entropy_meter -->

Farther along, on the left, the entropy gauge returns from the second room. It counts its own two hundred symbols; it is not measuring either field around it. Recall what its number kept of an arrangement and what it lost. A count of symbol shares cannot tell you whether similar values lie together, make a seam, or have been scattered apart. Here the familiar instrument gives us a limit to carry back to the images.

<!-- @noise_mixer -->

'''
 return rep(s,needle,extra+needle)
edit('commons/maps/Random_Space/final.md',space)
def game(s):
 s=rep(s,'In a headset, arrivals wait while either cube is held; a desktop carry does not pause them.','Arrivals wait while either cube is held.')
 s=rep(s,'At the last podium, wait for a small wooden cube.','<!-- @waiting_profile -->\n\nAt the last podium, wait for a small wooden cube.')
 s=rep(s,'In Noise Types we will carry that question between neighbouring places.','Carry that question through the biome ladder, where successive compositions gather the rules we have met. In Noise Types we will then take it between neighbouring places.')
 a='A clock that fires every half-second, or one that fires every tenth of a second with a one-in-five chance, would launch the same number of cubes an hour and make a different room to stand in; the podium\'s drawn delays, ahead, are the second kind.'
 b='A clock that tries every half-second and one that tries every tenth of a second with a one-in-five chance would make the same expected number of attempts over an hour, but different rhythms. The podium ahead uses another rule again: after each arrival, it draws the length of the next wait.'
 return rep(s,a,b)
edit('commons/maps/Random_Game/final.md',game)
print('Six chapters revised; two scene fixes and two local map repairs applied.')
