import pathlib,json
R=pathlib.Path.cwd();old=R/'doc/space/randomness-spatial-2026-09-16';out=R/'doc/space/randomness-arrivals-2026-09-16'
s=(old/'probe.gd').read_text(encoding='utf-8').replace('randomness-spatial-2026-09-16','randomness-arrivals-2026-09-16')
needle='\tawait exercise(found,player,em)'
insert='''
	if found.has("silhouette_arrivals"):
		var arrivals: Node3D = found.silhouette_arrivals
		arrivals.automatic = false; arrivals.replay()
		for i in range(8): arrivals.arrive()
		check(arrivals.people.size()==6,"Population capped at six")
		var order: Array = arrivals.history.duplicate()
		check(order.size()==6 and arrivals.available.is_empty(),"Sampling exhausts six different positions")
		arrivals.redress()
		check(arrivals.history==order,"Dress leaves occupied places unchanged")
		arrivals.replay()
		for i in range(6): arrivals.arrive()
		check(arrivals.history==order,"Replay repeats arrival order after redress")
		await capture_state(em,arrivals.global_position+Vector3(0,1.7,-3.6),arrivals.global_position+Vector3(0,1,0),"visitors")
	if found.has("random_walk_128"):
		for cell in [Vector2(2,17),Vector2(16,17),Vector2(5,10)]:
			var start: Vector3 = origin+Vector3(cell.x,0.3,cell.y)
			var hit := em.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,start-Vector3(0,1,0)))
			check(hit.is_empty(),"Moat is open at "+str(cell))
		for cell in [Vector2(9,10),Vector2(9,24),Vector2(4,17)]:
			var start: Vector3 = origin+Vector3(cell.x,0.3,cell.y)
			var hit := em.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,start-Vector3(0,1,0)))
			check(not hit.is_empty(),"Bridge or inner apron supported at "+str(cell))
'''
s=s.replace(needle,insert+needle);(out/'probe.gd').write_bytes(s.encode('utf-8'))
s=(old/'run_probe.py').read_text(encoding='utf-8').replace('randomness-spatial-2026-09-16','randomness-arrivals-2026-09-16');(out/'run_probe.py').write_bytes(s.encode('utf-8'))
manifest=json.loads((old/'manifest.json').read_text(encoding='utf-8'))
manifest=[r for r in manifest if r['map'] in ['Random_Walk','Random_Mushrooms']]
for r in manifest:
 if r['map']=='Random_Mushrooms':r['placements'].append(dict(x=13,z=4,lookup='silhouette_arrivals',token='silhouette_arrivals'));r['count']+=1
(out/'manifest.json').write_bytes(json.dumps(manifest,indent=2).encode('utf-8'))
