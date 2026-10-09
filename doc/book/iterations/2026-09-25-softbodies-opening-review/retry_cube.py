from pathlib import Path
import shutil
o=Path(__file__).resolve().parent
shutil.copytree(o/'cube-native',o/'cube-diagnostic',dirs_exist_ok=True)
p=o/'cube_probe.gd';s=p.read_text(encoding='utf-8')
old='\tdesk=find_scene("/soft_workshop.gd");cube=find_scene("/jelly_cube.gd")'
new='''	var loaded_at:=Time.get_ticks_msec()
	while Time.get_ticks_msec()-loaded_at<20000:
		desk=find_scene("/soft_workshop.gd");cube=find_scene("/jelly_cube.gd")
		if desk!=null and cube!=null:break
		await process_frame
	if desk==null or cube==null:
		observations["loaded_scripts"]=[]
		for n in hall.find_children("*","Node3D",true,false):
			if n.get_script()!=null:observations["loaded_scripts"].append(str(n.get_script().resource_path))'''
assert s.count(old)==1;s=s.replace(old,new);p.write_bytes(s.encode())
