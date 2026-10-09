from pathlib import Path

H=Path(__file__).resolve().parent
src=(H.parent/'2026-09-20-collective-review/check_hall.py').read_text(encoding='utf-8')
src=src.replace('SpeculativeComputation_Collective_Knowledge','SpeculativeComputation_Rhizome_Network').replace('peer_production_tool','rhizome_grower')
start=src.index("spec={'required'")
end=src.index('\npath=HERE/',start)
src=src[:start]+'''spec={'required':'rhizome_grower','shots':[{'tag':'rhizome-'+mode,'mode':mode} for mode in ['one','one-cut','three','three-cut','side','replay']],
'walks':[
{'tag':'entry','from':[6.5,.1,.7],'to':[6.5,.1,2.8],'seconds':3},
{'tag':'controls','from':[6.5,.1,2.8],'to':[5.5,.1,3.9],'seconds':3},
{'tag':'left approach','from':[5.5,.1,3.9],'to':[3.4,.1,4.0],'seconds':3},
{'tag':'along exhibit','from':[3.4,.1,4.0],'to':[3.4,.1,7.9],'seconds':4},
{'tag':'exit approach','from':[3.4,.1,7.9],'to':[6.5,.1,8.4],'seconds':3},
{'tag':'exit throat','from':[6.5,.1,8.4],'to':[6.5,.1,10.5],'seconds':3},
{'tag':'exit','from':[6.5,.1,10.5],'to':[6.5,.1,11.65],'seconds':3}]}
''' +src[end:]
src=src.replace('Vector3(0,1.7,3.5)','Vector3(0,2.05,3.3)').replace('Vector3(0,1.35,0)','Vector3(0,1.2,0)').replace('Vector3(2.5,1.7,2.6)','Vector3(2.7,2.1,2.7)')
src=src.replace('"record":str(study._records[study._selected]) if study._selected>=0 else "empty",','"positions":study._positions.map(func(v): return arr(v)),"active":study._active.duplicate(),"degrees":study._degrees.duplicate(),')
start=src.index('func counts(s: Node)')
end=src.index("'''",start)
src=src[:start]+'''func counts(s: Node) -> Array:
	return [s._node_total,s._active.count(true),s._visible_edges,s._components,s.links_per_node]
func seed_study(s: Node) -> void:
	s.apply_grid_config({"interactive":true,"spread":.85,"sample_seed":47,"max_nodes":40,"links_per_node":1})
	s._paused=true
	for i in range(22): s._grow_shoot()
	s._selected=s._degrees.find(s._degrees.max())
	s._refresh_graph()
func prepare_view(s: Node, mode: String) -> void:
	if mode=="one": seed_study(s)
	if mode=="one-cut": press(s,4)
	if mode=="three":
		press(s,4)
		press(s,2)
	if mode=="three-cut": press(s,4)
	if mode=="side": press(s,4)
	if mode=="replay": press(s,5)
''' +src[end:]
(H/'check_hall.py').write_text(src,encoding='utf-8')
