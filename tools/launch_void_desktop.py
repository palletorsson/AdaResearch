"""Visible human play; reserve the native slot until the window is closed."""
import argparse,json,os,subprocess,time,uuid
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--floor',type=int,default=14)
    parser.add_argument('--spawn',type=float,nargs=3,help='Temporary floor-local start, without changing the saved map')
    parser.add_argument('--look-at',type=float,nargs=3,help='Floor-local point to face on opening')
    args=parser.parse_args();root=Path(__file__).resolve().parents[1]
    out=root/'ada_run/desktop-play'/('floor-'+str(args.floor)+'-'+uuid.uuid4().hex[:8]);out.mkdir(parents=True)
    print('Desktop play folder:',out,flush=True)
    slot=acquire_native_slot('Palle playing floor '+str(args.floor)+'; reserve until human game closes',timeout=60)
    stage=stage_runtime()
    config=stage/'project.godot'
    config.write_text(config.read_text(encoding='utf-8').replace('config/name="Ada Void Trial Test"','config/name="Ada Void Desktop Play"'),encoding='utf-8')
    with (out/'game.log').open('w',encoding='utf-8') as log:
        process=subprocess.Popen([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
            '--windowed','--position','120,80','--resolution','1440x900','--rendering-method','gl_compatibility','--xr-mode','off',
            '--path',str(stage),'--script','res://tools/probes/play_void_desktop.gd','--','--no-bridges',
            '--void-start-floor='+str(args.floor),'--play-output='+str(out),
            *(['--play-spawn='+','.join(map(str,args.spawn))] if args.spawn else []),
            *(['--play-look-at='+','.join(map(str,args.look_at))] if args.look_at else [])],cwd=root,stdout=log,stderr=subprocess.STDOUT,
            creationflags=subprocess.CREATE_NO_WINDOW)
        (out/'session.json').write_text(json.dumps({'pid':process.pid,'floor':args.floor,'started':time.time(),
            'native_slot':'held for human play until game closes'},indent=2),encoding='utf-8')
        code=process.wait()
    (out/'closed.json').write_text(json.dumps({'pid':process.pid,'exit_code':code,'closed':time.time()},indent=2),encoding='utf-8')
    if code:raise SystemExit(code)

if __name__=='__main__':main()
