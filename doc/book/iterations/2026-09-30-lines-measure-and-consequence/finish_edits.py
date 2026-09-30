from pathlib import Path
import os, runpy
ROOT = Path(__file__).resolve().parents[4]

def write(path, text):
    path = path.resolve()
    assert path.is_relative_to(ROOT)
    temporary = path.with_name(path.name+'.ada-tmp')
    temporary.write_text(text,encoding='utf-8')
    os.replace(temporary,path)

p=ROOT/'commons/primitives/laser_measure/laser_measure.gd'
s=p.read_text(encoding='utf-8')
needle='\tget_parent().set_meta("desktop_hook_target", self)\n'
assert needle in s
s=s.replace(needle,needle+'''\t# The museum configures the packed scene root; this child owns the ray.
\tvar config := {}
\tfor source in [get_parent(), self]:
\t\tfor key in source.get_meta_list():
\t\t\tif str(key).begins_with("config_"):
\t\t\t\tconfig[str(key).trim_prefix("config_")] = source.get_meta(key)
\tapply_grid_config(config)
''')
write(p,s)
p=Path(__file__).parent/'probe.gd'
write(p,p.read_text(encoding='utf-8').replace('var centre := surface.global_position','var centre: Vector3 = rod.to_global(Vector3(0.65,0,0))'))
p=Path(__file__).parent/'update_text.py'
s=p.read_text(encoding='utf-8').replace("s = p.read_text(encoding='utf-8')", "s = (Path(__file__).parent/'before/commons/maps/Point_Lines/final.md').read_text(encoding='utf-8')")
# Write text through temporary siblings because Godot/editor may map the old file.
s=s.replace("import json\n",'''import json, os
def atomic_text(path, text, encoding='utf-8'):
    temporary = path.with_name(path.name+'.ada-tmp')
    temporary.write_text(text,encoding=encoding)
    os.replace(temporary,path)
''')
s=s.replace('p.write_text(s,encoding=', 'atomic_text(p,s,encoding=')
import re
s=re.sub(r"\(MAP/'([^']+)'\)\.write_text\(",r"atomic_text(MAP/'\1',",s)
write(p,s)
runpy.run_path(str(p))
