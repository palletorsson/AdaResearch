"""Check anchored Shaping continuation equals the printed source, then execute it."""
from pathlib import Path
import hashlib,json,os,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-pink-three-amounts'
GODOT=os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):return 'res://'+p.relative_to(ROOT).as_posix()
def main():
    source=ROOT/'commons/maps/Shader_12_PinkExtravaganza/tutorial.md'
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```(?:gdscript|glsl)\n(.*?)\n```',source.read_text(encoding='utf-8'),re.S))
    assert set(blocks)=={'shaping.gd','recipe.gdshader','point_body.gd'}
    chain=json.loads((OUT/'continuation.json').read_text())
    for name,item in chain['incoming'].items():
        p=ROOT/item['path'];assert sha(p)==item['sha256'];code=p.read_text(encoding='utf-8').rstrip()
        for old,new in chain['edits'][name]:
            assert code.count(old)==1;code=code.replace(old,new)
        assert code==blocks[name],name
    changes={
      'printed':None,
      'four-by-two':('shaping.gd','const REPEATS := Vector2(3, 3)','const REPEATS := Vector2(4, 2)'),
      'missing-repeat':('recipe.gdshader','fract(UV * repeats)','UV * repeats'),
      'missing-rim':('recipe.gdshader','edge * (1.5 * amounts.y)','edge * 0.0'),
      'missing-glow':('recipe.gdshader','colour * (0.8 * amounts.z)','colour * 0.0'),
    }
    rows=[]
    for kind,edit in changes.items():
        folder=OUT/'learner'/kind;folder.mkdir(parents=True,exist_ok=True)
        for name,code in blocks.items():
            if edit and name==edit[0]:
                assert code.count(edit[1])==1;code=code.replace(edit[1],edit[2])
            (folder/name).write_text(code+'\n',encoding='utf-8')
        result=folder/'report.json';log=folder/'engine.log'
        if result.exists():result.unlink()
        cmd=[GODOT,'--path',str(ROOT),'--no-window','--rendering-method','gl_compatibility','--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/shader_pink_student.gd','--','--no-bridges','--lesson='+res(folder/'shaping.gd'),'--report='+res(result)]
        if kind=='four-by-two':cmd.append('--variation')
        with log.open('w',encoding='utf-8') as out:
            proc=subprocess.run(cmd,stdout=out,stderr=subprocess.STDOUT,timeout=80,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
        data=json.loads(result.read_text()) if result.exists() else {}
        errors=any(s in log.read_text(encoding='utf-8',errors='replace') for s in ['SCRIPT ERROR:','SHADER ERROR:','Parse Error:'])
        failed=[c['test'] for c in data.get('checks',[]) if not c['passed']]
        row={'kind':kind,'passed':proc.returncode==0 and data.get('passed',False) and not errors,'exit':proc.returncode,'checks':len(data.get('checks',[])),'failed_assertions':failed,'script_or_shader_errors':errors}
        rows.append(row);print(json.dumps(row),flush=True)
    passed=all(r['passed'] for r in rows[:2]) and all(r['exit']==1 and r['failed_assertions'] and not r['script_or_shader_errors'] for r in rows[2:])
    (OUT/'tests.json').write_text(json.dumps({'passed':passed,'source_sha256':sha(source),'continuation_sha256':sha(OUT/'continuation.json'),'files':{n:sha(OUT/'learner/printed'/n) for n in blocks},'runner_sha256':sha(Path(__file__)),'probe_sha256':sha(ROOT/'tools/probes/shader_pink_student.gd'),'results':rows},indent=2)+'\n',encoding='utf-8')
    assert passed
if __name__=='__main__':main()

