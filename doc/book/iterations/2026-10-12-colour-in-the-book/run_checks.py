from pathlib import Path
import hashlib, json, os, re, shutil, subprocess, tempfile
from prepare import HERE

ROOT = HERE.parents[3]
ENGINE = os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
HALLS = ['Color_Rainbow','Color_Pillar','Color_Grid_Pallet','Color_Paint','Color_Walls']
VARIANTS = {
 'Color_Rainbow': {'start': [], 'two': [('Color(0.15, 0.55, 0.9), Color(1, 0.8, 0.15)', 'Color.WHITE')], 'four': [('Color(1, 0.8, 0.15)]','Color(1, 0.8, 0.15), Color.BLACK]')], 'one': [('Color(0.8, 0.2, 0.6), Color(0.15, 0.55, 0.9), Color(1, 0.8, 0.15)','Color(0.8, 0.2, 0.6)')]},
 'Color_Pillar': {'start': [], **{k:[('Vector3(6.4, 1.25, 9.6)',f'Vector3(6.4, {v}, 9.6)')] for k,v in [('low',0.65),('high',1.85),('beyond',2.5)]}},
 'Color_Grid_Pallet': {'start': [], 'one': [('Palette.new([sample, Color.WHITE, Color.BLACK])','Palette.new([sample])')], 'four': [('Palette.new([sample, Color.WHITE, Color.BLACK])','Palette.new([sample, Color.WHITE, Color.BLACK, Color(0.8, 0.2, 0.6)])')]},
 'Color_Paint': {'start': [], 'wide': [('var radius := 0.06','var radius := 0.12')], 'short': [('var max_distance := 3.0','var max_distance := 1.0')], 'automatic': [('var automatic := false','var automatic := true')], 'choice': [('var automatic := false','var automatic := true'),('sin(time * 1.3)','sin(time * 2.0)')]},
 'Color_Walls': {'start': [], 'thin': [('var opacity := 0.52','var opacity := 0.2')], 'full': [('var opacity := 0.52','var opacity := 1.0')], 'turned': [('= [0.0, 15.0]','= [0.0, 45.0]')]},
}
# Every mutation must reach and fail a specified behaviour assertion, not merely fail to parse.
FAULTS = {
 'grid_pointer_release': ('Color_Grid_Pallet','controls.gd','if event.event_type == 2:', 'if event.event_type == 3:', 'pointer_wraps_address'),
 'walls_pointer_noop': ('Color_Walls','controls.gd','get_parent().toggle_filter()', 'pass # deliberately unwired target', 'pointer_switches_filter'),
 'rainbow_extent': ('Color_Rainbow','lesson.gd','TOTAL_THICKNESS / float(palette.size())','0.3','fixed_outer'),
 'rainbow_colour': ('Color_Rainbow','lesson.gd','palette[i]','palette[0]','colour_1'),
 'pillar_frame': ('Color_Pillar','lesson.gd','to_local(point.global_position)','point.global_position','initial_colour'),
 'pillar_clamp': ('Color_Pillar','lesson.gd','clampf((hand.y - 0.65) / 1.2, 0, 1)','(hand.y - 0.65) / 1.2','height_clamped'),
 'grid_advance': ('Color_Grid_Pallet','palette.gd','index = (index + 1) % colours.size()','index = index','paint_before_advance'),
 'grid_alias': ('Color_Grid_Pallet','palette.gd','colours.assign(choices)','colours = choices','owns_choices'),
 'paint_gate': ('Color_Paint','lesson.gd','active = pressed and held','active = pressed','unheld_cannot_paint'),
 'paint_area': ('Color_Paint','lesson.gd','query.collide_with_areas = true','query.collide_with_areas = false','ray_hits_receiver'),
 'walls_mode': ('Color_Walls','lesson.gd','BaseMaterial3D.TRANSPARENCY_ALPHA if filter_mode else BaseMaterial3D.TRANSPARENCY_DISABLED','BaseMaterial3D.TRANSPARENCY_DISABLED','alpha_mode'),
 'walls_boundary': ('Color_Walls','lesson.gd','    filter_mode = not filter_mode','    panes[0].boundary.disabled = true\n    filter_mode = not filter_mode','opaque_collision'),
}

def put(path, text):
 path.parent.mkdir(parents=True,exist_ok=True)
 path.write_text(text,encoding='utf-8')

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def extract(text, name):
 blocks = re.findall(r'<!-- student-code:'+re.escape(name)+r' -->\s*```gdscript\n(.*?)^```',text,re.M|re.S)
 assert len(blocks)==1,(name,len(blocks))
 return blocks[0]

def student_files(hall):
 return [HERE/hall/n for n in re.findall(r"<!-- student-code:([^>]+) -->", (HERE/hall/"tutorial.md").read_text(encoding="utf-8"))]

def main():
 protected = [f'commons/maps/{h}/{n}' for h in HALLS for n in ['tutorial.md','final.md','map_data.json']] + ['commons/maps/sequences/color.json','doc/book/course/execution-plan/plan.json']
 before={p:sha(ROOT/p) for p in protected}
 put(HERE/'preserved-before.json',json.dumps(before,indent=2))
 for hall in HALLS:
  assert sha(HERE/hall/'final.md') == sha(ROOT/'commons/maps'/hall/'final.md')
  text=(HERE/hall/'tutorial.md').read_text(encoding='utf-8')
  for f in student_files(hall):
   assert extract(text,f.name)==f.read_text(encoding='utf-8').rstrip()+'\n',(hall,f)
  assert '$' not in (HERE/hall/'lesson.gd').read_text()
 for hall in ['Color_Pillar','Color_Paint']:
  assert sha(HERE/hall/'point_body.gd') == sha(HERE/'Color_Nails/point_body.gd')
 assert sha(HERE/'Color_Walls/palette.gd')==sha(HERE/'Color_Grid_Pallet/palette.gd')
 work=Path(tempfile.mkdtemp(prefix='ada-colour-complete-'))
 shutil.copytree(ROOT/'addons/godot-xr-tools',work/'addons/godot-xr-tools')
 project='''config_version=5
[application]
config/name="Ada Colour reviewer examples"
config/features=PackedStringArray("4.6")
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
[display]
window/size/viewport_width=64
window/size/viewport_height=64
'''
 put(work/'project.godot',project)
 put(HERE/'native-project.godot',project)
 shutil.copyfile(HERE/'verify.gd',work/'verify.gd')
 cases={}
 for group in ['normal',*FAULTS]:
  cases[group]=[]
  halls=HALLS if group=='normal' else [FAULTS[group][0]]
  for hall in halls:
   variants=VARIANTS[hall] if group=='normal' else {'start':[]}
   for variant,edits in variants.items():
    dest=Path(group)/hall/variant
    cases[group].append({'hall':hall,'variant':variant,'path':dest.as_posix()})
    for f in student_files(hall):
     text=extract((HERE/hall/'tutorial.md').read_text(encoding='utf-8'),f.name)
     for old,new in (edits if f.name=='lesson.gd' else []):
      assert text.count(old)==1,(hall,variant,old)
      text=text.replace(old,new)
     if group!='normal' and f.name==FAULTS[group][1]:
      old,new=FAULTS[group][2:4]
      assert text.count(old)==1,(group,old)
      text=text.replace(old,new)
     put(work/dest/f.name,text)
     if group=='normal': put(HERE/'variants'/hall/variant/f.name,text)
 put(work/'cases.json',json.dumps(cases))
 put(HERE/'cases.json',json.dumps(cases,indent=2))
 base=[ENGINE,'--path',str(work),'--xr-mode','off','--audio-driver','Dummy','--max-fps','120']
 def run(name,args,expected=0,gpu=False):
  startup=subprocess.STARTUPINFO(); startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=subprocess.SW_HIDE
  result=subprocess.run(base+(['--rendering-method','gl_compatibility','--rendering-driver','opengl3'] if gpu else ['--headless'])+args,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=90,creationflags=subprocess.CREATE_NO_WINDOW,startupinfo=startup)
  log=result.stdout+result.stderr
  put(HERE/'logs'/(name+'.log'),log)
  print(name,result.returncode,log[-750:],flush=True)
  assert result.returncode==expected and 'SCRIPT ERROR:' not in log and 'ERROR:' not in log,log
 run('import',['--editor','--import','--quit'])
 results={}
 for group in cases:
  path=work/(group+'.json')
  run(group,['--quit-after','2500','--script','res://verify.gd','--',group,str(path)],0 if group=='normal' else 1,gpu=True)
  data=json.loads(path.read_text())
  results[group]=data
  put(HERE/(group+'-report.json'),json.dumps(data,indent=2))
  if group!='normal':
   hall,_,_,_,failure=FAULTS[group]
   assert hall+'/start/'+failure in data['failure_ids'],group
 assert {p:sha(ROOT/p) for p in protected}==before
 report={'passed':True,'engine':'Godot 4.6 stable','native_assertions':len(results['normal']['checks']),'variants':sum(map(len,VARIANTS.values())),'faults_rejected':len(FAULTS),'variant_edits':VARIANTS,'faults':FAULTS,'test_project':str(work),'preserved':before,'scope':'Exact printed sources; native geometry/material/state/physics assertions; XR Tools pickup and action signals with synthetic controller. No headset, museum integration or human learning test.'}
 inputs=[HERE/'run_checks.py',HERE/'verify.gd',HERE/'native-project.godot']+[f for h in HALLS for f in (HERE/h).iterdir() if f.suffix in ['.gd','.md']]
 report['inputs']={f.relative_to(HERE).as_posix():sha(f) for f in inputs}
 put(HERE/'verification.json',json.dumps(report,indent=2))
 print('PASS',report['native_assertions'],'assertions;',report['variants'],'variants;',len(FAULTS),'faults rejected',flush=True)

if __name__=='__main__':main()
