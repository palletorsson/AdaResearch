"""Care Unit / Model B: local observe/act/memory interface, without model weights.

Run an isolated, opt-in Godot session; a connected assistant supplies decisions.
Physics pauses between bounded actions. No layout writes or teleport commands.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import uuid

ROOT=Path(__file__).resolve().parents[1]

def read_json(path: Path):
    return json.loads(path.read_text(encoding='utf-8'))

class Client:
    def __init__(self,directory,timeout=40):
        self.directory=Path(directory).resolve();self.timeout=timeout

    def ready(self,timeout=120):
        end=time.monotonic()+timeout
        while time.monotonic()<end:
            try:
                state=read_json(self.directory/'session.json')
                if state['mode'] in ['awaiting_decision','handed_over'] and state['observation_id']:return state
                if state['mode']=='closed':raise RuntimeError('Model B session is closed')
            except (FileNotFoundError,json.JSONDecodeError):pass
            time.sleep(.1)
        raise TimeoutError('Model B did not publish a ready observation')

    def request(self,op,**fields):
        state=read_json(self.directory/'session.json')
        if state['mode']=='closed':raise RuntimeError('Model B session is closed')
        request={'id':'req_'+uuid.uuid4().hex,'session_id':state['session_id'],'op':op,**fields}
        path=self.directory/'inbox'/(request['id']+'.json')
        temporary=path.with_suffix('.tmp')
        temporary.write_text(json.dumps(request,allow_nan=False),encoding='utf-8');os.replace(temporary,path)
        response=self.directory/'outbox'/(request['id']+'.json');end=time.monotonic()+self.timeout
        while time.monotonic()<end:
            try:return read_json(response)
            except (FileNotFoundError,json.JSONDecodeError):time.sleep(.03)
        raise TimeoutError(f'Model B {op} did not respond; request remains {request["id"]}')

    def observe(self):return self.request('observe')

    def recall(self,query='',limit=20):
        """Read the persisted notebook, including after its native session closes."""
        if not 1<=limit<=50:raise ValueError('Recall limit must be between 1 and 50')
        state=read_json(self.directory/'session.json');notes=[];invalid=0
        for line in (self.directory/'events.jsonl').read_text(encoding='utf-8').splitlines():
            try:event=json.loads(line)
            except json.JSONDecodeError:invalid+=1;continue
            if event.get('type')!='memory':continue
            entry=event['entry']
            if query.casefold() not in json.dumps(entry,ensure_ascii=False).casefold():continue
            notes.append({'session_id':state['session_id'],'recorded_at':event['unix_time'],**entry})
        return {'ok':True,'entries':notes[-limit:],'matching_entries':len(notes),'invalid_records':invalid,
                'scope':'Recorded session claims and measurements; re-observe before applying them to a changed world.'}

    def act(self,action,reason,observation_id=None):
        if observation_id is None:observation_id=read_json(self.directory/'latest.json')['id']
        return self.request('act',action=action,reason=reason,observation_id=observation_id)

def run(args):
    from void_native_slot import acquire_native_slot
    from void_trial_runtime import stage_runtime
    from void_log_diagnostics import split_errors
    directory=Path(args.session).resolve() if args.session else ROOT/'ada_run/model-b/sessions'/(time.strftime('%Y%m%d-%H%M%S')+'-'+uuid.uuid4().hex[:8])
    if not directory.is_relative_to((ROOT/'ada_run').resolve()):raise ValueError('Session output must stay inside this workspace ada_run folder')
    directory.mkdir(parents=True,exist_ok=True)
    if (directory/'session.json').exists():raise ValueError('Use a fresh session folder; existing evidence is retained')
    print('Model B session:',directory,flush=True)
    slot=acquire_native_slot('Care Unit / Model B exploration')
    stage=stage_runtime()
    source_files=['commons/void/rooms.json','commons/void/layout.json','commons/void/game.gd','commons/void/walker.gd',
                  'tools/model_b/brain.gd','tools/probes/model_b_session.gd']
    launch={'session':str(directory),'stage':str(stage),'floor':args.floor,'role':'exploratory_playtester','reasoning_provider':'external_assistant','paused_between_decisions':True,
            'source_sha256':{name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in source_files}}
    (directory/'launch.json').write_text(json.dumps(launch,indent=2),encoding='utf-8')
    command=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
             '--windowed' if args.visible else '--no-window','--fixed-fps','60','--path',str(stage),
             '--rendering-method','gl_compatibility','--xr-mode','off','--script','res://tools/probes/model_b_session.gd','--',
             '--no-bridges','--void-start-floor='+str(args.floor),'--model-b-dir='+str(directory),'--model-b-idle='+str(args.idle)]
    process=None;failure=None
    with (directory/'native.log').open('w',encoding='utf-8') as log:
        try:
            process=subprocess.Popen(command,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
            end=time.monotonic()+120
            while process.poll() is None:
                try:
                    state=read_json(directory/'session.json')
                    if state.get('observation_id') and state.get('mode') in ['awaiting_decision','handed_over']:break
                except (FileNotFoundError,json.JSONDecodeError):pass
                if time.monotonic()>end:raise TimeoutError('Model B startup did not publish a ready observation in 120 seconds')
                time.sleep(.1)
            process.wait(timeout=1800)
        except (TimeoutError,subprocess.TimeoutExpired) as error:
            failure=str(error)
        finally:
            if process is not None and process.poll() is None:
                process.terminate()
                try:process.wait(timeout=10)
                except subprocess.TimeoutExpired:process.kill();process.wait()
    text=(directory/'native.log').read_text(encoding='utf-8',errors='replace')
    errors,shutdown=split_errors(text,'MODEL_B_SESSION_RESULT ',allow_shutdown=process.returncode==0)
    result={'passed':failure is None and process.returncode==0 and not errors and 'MODEL_B_SESSION_RESULT ' in text,'exit_code':process.returncode,'failure':failure,'runtime_errors':errors,'shutdown_diagnostics':shutdown}
    (directory/'run-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result));return 0 if result['passed'] else 1

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    sub=parser.add_subparsers(dest='command',required=True)
    launch=sub.add_parser('run');launch.add_argument('--session');launch.add_argument('--floor',type=int,default=14)
    launch.add_argument('--visible',action='store_true');launch.add_argument('--idle',type=float,default=180)
    for name in ['observe','act','remember','recall','goal','audit','stop','resume','close']:
        p=sub.add_parser(name);p.add_argument('--session',required=True)
        if name=='act':
            for flag in ['forward','strafe','yaw-degrees','pitch-degrees']:p.add_argument('--'+flag,type=float,default=0)
            p.add_argument('--seconds',type=float,default=.2);p.add_argument('--jump',action='store_true')
            p.add_argument('--reason',required=True);p.add_argument('--observation-id')
        if name=='remember':
            p.add_argument('--kind',choices=['hypothesis','interpretation','attention'],default='hypothesis')
            p.add_argument('--text',required=True);p.add_argument('--evidence',nargs='+',required=True)
        if name=='goal':p.add_argument('--instruction',required=True);p.add_argument('--target-checkpoint',type=int)
        if name=='recall':p.add_argument('--query',default='');p.add_argument('--limit',type=int,default=20)
    args=parser.parse_args()
    if args.command=='run':return run(args)
    client=Client(args.session)
    if args.command=='recall':result=client.recall(args.query,args.limit)
    elif args.command=='act':
        action={key:getattr(args,key) for key in ['forward','strafe','yaw_degrees','pitch_degrees','seconds','jump']}
        result=client.act(action,args.reason,args.observation_id)
    elif args.command=='remember':result=client.request('remember',kind=args.kind,text=args.text,evidence=args.evidence)
    elif args.command=='goal':
        fields={'instruction':args.instruction}
        if args.target_checkpoint is not None:fields['target_checkpoint']=args.target_checkpoint
        result=client.request('goal',**fields)
    else:result=client.request(args.command)
    print(json.dumps(result,indent=2));return 0 if result['ok'] else 2

if __name__=='__main__':sys.exit(main())
