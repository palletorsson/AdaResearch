"""Render pinned learner scripts in an isolated Godot project; never edit the museum."""
from pathlib import Path
import hashlib, json, re, shutil, subprocess, tempfile, sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
OPENING = ROOT/'doc/book/iterations/2026-10-06-starter-one-course/lessons'
PRIMITIVES = json.loads((ROOT/'commons/maps/sequences/primitives.json').read_text(encoding='utf-8'))['sequences']['primitives']['maps']
TRANS = {
    'Trans_Pre': '2026-10-16-transformation-handoff/Trans_Pre',
    'Trans_Introduction': '2026-10-16-transformation-handoff/Trans_Introduction',
    'Trans_Translation': '2026-10-16-translation-carried-body/complete',
    'Trans_Rotation': '2026-10-16-rotation-carried-body/complete',
    'Trans_Scale': '2026-10-16-scale-carried-frame/complete',
    'Trans_Body': '2026-10-17-body-carried-opening/complete',
}
MAIN = {'Point_Zero':'counter.gd','Point_One':'point.gd','Point_Coordinates':'point.gd','Point_Lines':'line.gd','Point_Trace':'trace.gd','Point_Line_Grid':'grid.gd'}
def put(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8', newline='\n')
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    reuse = '--reuse' in sys.argv and (HERE/'render-project.txt').exists()
    work=Path((HERE/'render-project.txt').read_text().strip()) if reuse else Path(tempfile.mkdtemp(prefix='ada-tutorial-gallery-'))
    put(HERE/'render-project.txt',str(work))
    sources, originals, preservation = {}, {}, {}
    for hall in [*PRIMITIVES,*TRANS]:
        origin = OPENING/hall if hall in PRIMITIVES else ROOT/'doc/book/iterations'/TRANS[hall]
        tutorial=ROOT/'commons/maps'/hall/'tutorial.md'
        text=tutorial.read_text(encoding='utf-8')
        for name in ['tutorial.md','final.md']:
            path=ROOT/'commons/maps'/hall/name
            if path.exists(): preservation[path.relative_to(ROOT).as_posix()]=sha(path)
        printed=[]
        for name, block in re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)^```',text,re.M|re.S):
            if (origin/name).is_file():
                assert block==(origin/name).read_text(encoding='utf-8'),(hall,name,'printed/source mismatch')
                printed.append(name)
        assert MAIN.get(hall,'lesson.gd') in printed,(hall,'missing canonical complete script')
        for p in origin.iterdir():
            if p.suffix in ['.gd','.ttf','.txt']:
                dest=HERE/'sources'/hall/p.name
                dest.parent.mkdir(parents=True,exist_ok=True)
                shutil.copyfile(p,dest)
                originals[p.relative_to(ROOT).as_posix()]=sha(p)
                sources[dest.relative_to(HERE).as_posix()]=sha(dest)
        shutil.copytree(HERE/'sources'/hall,work/'sources'/hall,dirs_exist_ok=True)
    if not reuse: shutil.copytree(ROOT/'addons/godot-xr-tools',work/'addons/godot-xr-tools')
    config=f'''config_version=5
[application]
config/name="{work.name}"
config/features=PackedStringArray("4.6")
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[display]
window/size/viewport_width=1200
window/size/viewport_height=900
[rendering]
renderer/rendering_method="gl_compatibility"
textures/default_filters/use_nearest_mipmap_filter=false
anti_aliasing/quality/msaa_3d=2
'''
    put(work/'project.godot',config)
    put(HERE/'capture-project.godot',config)
    shutil.copyfile(HERE/'capture.gd',work/'capture.gd')
    (HERE/'images').mkdir(exist_ok=True)
    common=[ENGINE,'--path',str(work),'--xr-mode','off','--audio-driver','Dummy']
    def run(label,args):
        startup=subprocess.STARTUPINFO()
        startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow=0
        p=subprocess.run(common+args,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=180,creationflags=subprocess.CREATE_NO_WINDOW,startupinfo=startup)
        log=p.stdout+p.stderr
        put(HERE/'logs'/(label+'.log'),log)
        print(label,p.returncode,log[-1800:] if label=='render' or p.returncode else '',flush=True)
        assert p.returncode==0 and 'SCRIPT ERROR:' not in log and 'ERROR:' not in log,label
    run('import',['--headless','--editor','--import','--quit'])
    run('render',['--rendering-method','gl_compatibility','--position','-2400,0','--resolution','1200x900','--script','res://capture.gd','--',str(HERE).replace('\\','/')])
    native=json.loads((HERE/'native.json').read_text())
    assert native['passed'] and len(native['halls'])==21
    for frame in native['frames']: frame['sha256']=sha(HERE/frame['file'])
    for p,digest in {**originals,**preservation}.items(): assert sha(ROOT/p)==digest,p
    receipt=dict(passed=True,engine='Godot 4.6 stable / OpenGL Compatibility',source_files=sources,originals=originals,
        preserved=preservation,frames=native['frames'],checks=native['checks'],isolated_project=str(work),
        trace=native['trace'],capture_sha256=sha(HERE/'capture.gd'),runner_sha256=sha(HERE/'capture.py'),
        scope='Exact learner scripts, native rendering, specified synthetic inputs. Supplied camera, lighting and ground. No headset or human-learning verification; existing lesson tests remain separate.')
    put(HERE/'verification.json',json.dumps(receipt,indent=2)+'\n')
    print('PASS',len(native['frames']),'frames;',len(native['checks']),'capture checks;',len(sources),'pinned source files.',flush=True)

if __name__=='__main__': main()
