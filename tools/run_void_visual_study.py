"""Serial, isolated visual study; no fixed-fps timing and no layout saves."""
from pathlib import Path
import argparse, hashlib, json, os, subprocess, sys
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
sys.stdout.reconfigure(encoding='utf8')
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/ports/2026-10-27-void-visual-profiles'
GODOT=os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')

def run(args):
    OUT.mkdir(parents=True,exist_ok=True)
    slot=acquire_native_slot('Void visual profile comparison')
    stage=stage_runtime()
    sources=['commons/void/rooms.json','commons/void/layout.json','commons/void/catalog.json']
    before={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
    destination=OUT/(args.renderer+('-quick' if args.quick else ''))
    destination.mkdir(exist_ok=True)
    with (destination/'engine.log').open('w',encoding='utf8') as log:
        command=[GODOT,'--no-window','--path',str(stage),'--rendering-method',args.renderer,'--xr-mode','off','res://tools/probes/void_visual_study.tscn','--','--no-bridges','--void-start-floor=16','--out='+str(destination)]
        if args.quick:command+=['--quick']
        p=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=600,creationflags=subprocess.CREATE_NO_WINDOW)
    text=(destination/'engine.log').read_text(encoding='utf8',errors='replace')
    errors,shutdown=split_errors(text,'VOID_VISUAL_COMPLETE ',allow_shutdown=p.returncode==0)
    after={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
    receipt={'exit':p.returncode,'engine_errors':errors,'shutdown':shutdown,'source_hashes':before,'unchanged':before==after,'command':command,'stage':str(stage)}
    (destination/'runner.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf8')
    print(text[-4500:])
    assert p.returncode==0 and not errors, errors
    result=json.loads((destination/'results.json').read_text(encoding='utf8'))
    assert result['passed'],result.get('failures')
    assert before==after,'Source layouts changed during study; investigate concurrent edits before asserting preservation.'
    print('PASS',destination)

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--renderer',choices=['forward_plus','mobile','gl_compatibility'],default='forward_plus')
    parser.add_argument('--quick',action='store_true')
    run(parser.parse_args())
