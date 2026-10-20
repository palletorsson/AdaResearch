"""Extract the three visible listings unchanged; run, vary and challenge them."""
from pathlib import Path
import hashlib,json,os,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-shaping-a-rule-on-the-cube'
GODOT=os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):return 'res://'+p.relative_to(ROOT).as_posix()
def main():
    source=ROOT/'commons/maps/Shader_01_Shaping/tutorial.md'
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```(?:gdscript|glsl)\n(.*?)\n```',source.read_text(encoding='utf-8'),re.S))
    assert set(blocks)=={'shaping.gd','circle.gdshader','point_body.gd'}
    for name,path in json.loads((OUT/'carried-files.json').read_text()).items():assert blocks[name]==(ROOT/path).read_text().rstrip()
    changes={
      'printed':None,
      'off-centre':('circle.gdshader','vec2 centre = vec2(0.5, 0.5)','vec2 centre = vec2(0.35, 0.65)'),
      'missing-uniform':('shaping.gd','    material.set_shader_parameter("radius", radius)','    pass # Deliberate missing connection'),
      'inverted-mask':('circle.gdshader','float mask = 1.0 - step(radius, d);','float mask = step(radius, d);'),
      'wrong-frame':('shaping.gd','to_local(control.global_position).y','control.global_position.y'),
    }
    rows=[]
    for kind,edit in changes.items():
        folder=OUT/'learner'/kind;folder.mkdir(parents=True,exist_ok=True)
        for name,code in blocks.items():
            if edit and name==edit[0]:
                assert code.count(edit[1])==1;code=code.replace(edit[1],edit[2])
            (folder/name).write_text(code+'\n',encoding='utf-8')
        result=folder/'report.json';log=folder/'engine.log'
        cmd=[GODOT,'--path',str(ROOT),'--no-window','--rendering-method','gl_compatibility','--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/shader_shaping_student.gd','--','--no-bridges','--lesson='+res(folder/'shaping.gd'),'--report='+res(result)]
        if kind=='off-centre':cmd.append('--variation')
        with log.open('w',encoding='utf-8') as out:
            proc=subprocess.run(cmd,stdout=out,stderr=subprocess.STDOUT,timeout=75,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
        data=json.loads(result.read_text()) if result.exists() else {}
        errors=any(s in log.read_text(encoding='utf-8',errors='replace') for s in ['SCRIPT ERROR:','SHADER ERROR:','Parse Error:'])
        failed=[c['test'] for c in data.get('checks',[]) if not c['passed']]
        row={'kind':kind,'passed':proc.returncode==0 and data.get('passed',False) and not errors,'exit':proc.returncode,'checks':len(data.get('checks',[])),'failed_assertions':failed,'script_or_shader_errors':errors}
        rows.append(row);print(json.dumps(row),flush=True)
    passed=all(r['passed'] for r in rows[:2]) and all(r['exit']==1 and r['failed_assertions'] and not r['script_or_shader_errors'] for r in rows[2:])
    (OUT/'tests.json').write_text(json.dumps({'passed':passed,'source_sha256':sha(source),'files':{n:sha(OUT/'learner/printed'/n) for n in blocks},'runner_sha256':sha(Path(__file__)),'probe_sha256':sha(ROOT/'tools/probes/shader_shaping_student.gd'),'results':rows},indent=2)+'\n',encoding='utf-8')
    assert passed
if __name__=='__main__':main()
