from pathlib import Path
p=Path(__file__).with_name('museum-probe.gd')
s=p.read_text()
s=s.replace('(hall.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()', 'mesh.global_transform*mesh.get_aabb()')
s=s.replace('box.position.x<0.5 or box.end.x>12.5 or box.position.z<0.5 or box.end.z>15.5', 'box.position.x<1.0 or box.end.x>12.0 or box.position.z<1.0 or box.end.z>15.0')
s=s.replace('"hall_local_bounds"','"world_bounds"')
s=s.replace('hall.to_global(Vector3(10.8,1.7,11.0)),hall.to_global(Vector3(6,0.4,12.8))', 'Vector3(10.8,1.7,13.3),Vector3(6,0.42,13)')
for num in [3,4]:
 old=f'\tsampler._stand_panel.find_child("Btn_{num}",true,false).pressed.emit()'
 new=f'\tvar button_{num}: Node=sampler._stand_panel.find_child("Btn_{num}",true,false).get_node("InteractableAreaButton")\n\tbutton_{num}.button_pressed.emit(button_{num})'
 s=s.replace(old,new)
p.write_text(s,encoding='utf-8')
