"""Native end-to-end protocol checks on the actual desktop body and floor 14."""
import concurrent.futures
import json
import os
from pathlib import Path
import struct
import subprocess
import time
import uuid
from model_b import Client, read_json
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors

ROOT=Path(__file__).resolve().parents[1]
def main():
    OUT=ROOT/'ada_run/model-b-brain-2026-10-26'/('protocol-'+uuid.uuid4().hex[:8])
    OUT.mkdir(parents=True)
    checks=[]

    def check(name,condition):
        checks.append({'name':name,'passed':bool(condition)})
        print(('PASS ' if condition else 'FAIL ')+name,flush=True)
        assert condition,name

    slot=acquire_native_slot('Model B / native protocol and handover checks')
    stage=stage_runtime();process=None;failure=None;client=Client(OUT)
    with (OUT/'native.log').open('w',encoding='utf-8') as log:
        try:
            process=subprocess.Popen([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
                '--no-window','--fixed-fps','60','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off',
                '--script','res://tools/probes/model_b_session.gd','--','--no-bridges','--void-start-floor=14',
                '--model-b-dir='+str(OUT),'--model-b-idle=8'],stdout=log,stderr=subprocess.STDOUT,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
            state=client.ready(timeout=100)
            check('explicit external reasoning provider',state['reasoning_provider']=='external_assistant')
            result=client.observe();obs=result['observation'];first=obs['id']
            data=(OUT/obs['image']).read_bytes()
            check('real player-eye PNG at 960 by 600',data[:8]==b'\x89PNG\r\n\x1a\n' and struct.unpack('>II',data[16:24])==(960,600))
            check('perception omits route, world position and editor inventory',not {'route','position','audit','artifacts','inventory'}&obs.keys() and 'position' not in obs['body'])
            check('checkpoint evidence is separate from semantic task completion',not obs['checkpoint_target_reached'] and obs['semantic_goal_completion']=='not_assessed' and 'goal_verified' not in obs)
            check('fresh isolated body is grounded with full charge',obs['body']['grounded'] and obs['body']['charge']==100)
            original_goal=obs['goal']
            result=client.request('goal',instruction='This invalid request must not change the goal',target_checkpoint=-5)
            check('invalid goal is rejected without a partial edit',result.get('error')=='invalid_target_checkpoint' and client.observe()['observation']['goal']==original_goal)
            result=client.request('remember',kind='hypothesis',text='The stripes may mark a ramp.',evidence=[first])
            check('hypothesis retains explicit visual evidence',result['ok'] and result['memory']['kind']=='hypothesis' and result['memory']['evidence']==[first])
            result=client.request('remember',kind='fact',text='Unverified certainty',evidence=[first])
            check('reasoner cannot relabel a claim as an observed fact',result.get('error')=='invalid_memory')
            result=client.request('remember',kind='attention',text='An unsupported claim',evidence=['obs_not_seen'])
            check('unknown evidence is rejected',result.get('error')=='unknown_evidence')
            result=client.request('observe',session_id='another_session')
            check('commands from another session are rejected',result.get('error')=='wrong_session')
            current=client.observe()['observation']['id']
            result=client.act({'yaw_degrees':30,'seconds':.1},'Inspect another direction.',current)
            check('look action turns the actual player camera',result['ok'] and abs(result['observation']['body']['heading_degrees']-30)<.02)
            check('completed action is present in the returned memory',result['observation']['memory'][-1]['kind']=='observed_outcome' and result['observation']['id'] in result['observation']['memory'][-1]['evidence'])
            result=client.act({'forward':1,'seconds':.2},'Old frame must not drive the body.',current)
            check('stale observation cannot execute a second action',result.get('error')=='stale_observation')
            before=client.request('audit')['audit']['position']
            for name,action,error in [
                ('excessive movement',{'forward':2},'action_out_of_range'),
                ('unbounded duration',{'seconds':30},'action_out_of_range'),
                ('teleport field',{'position':[0,0,0]},'unknown_action_field'),
                ('non-numeric movement',{'forward':'fast'},'invalid_number'),
                ('non-boolean jump',{'jump':1},'invalid_jump')]:
                result=client.act(action,'Reject invalid input.')
                check(name+' rejected',result.get('error')==error)
            check('unknown operation cannot teleport',client.request('teleport',position=[0,0,0]).get('error')=='unknown_operation')
            after=client.request('audit')['audit']['position']
            check('rejected actions leave the paused body unchanged',sum((x-y)**2 for x,y in zip(before,after))<1e-10)
            check('action explanation is required',client.act({'seconds':.1},'').get('error')=='reason_required')
            result=client.act({'forward':-1,'seconds':.35},'Step back briefly and inspect the result.')
            check('movement uses real physics and charge',result['ok'] and .05<result['outcome']['moved_metres']<3 and result['outcome']['charge_used']>0 and result['outcome']['deaths']==0)
            with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
                future=pool.submit(client.act,{'seconds':1.5},'Wait while testing an immediate human handover.')
                end=time.monotonic()+5
                while time.monotonic()<end and not future.done():
                    if read_json(OUT/'session.json')['mode']=='acting':break
                    time.sleep(.005)
                result=Client(OUT).request('stop')
                interrupted=future.result(timeout=10)
            check('human stop interrupts an in-flight action',result['ok'] and interrupted.get('error')=='interrupted_by_handover')
            state=read_json(OUT/'session.json')
            check('handover restores human input and clears drive',state['mode']=='handed_over' and not state['controlled'] and state['drive']==[0,0] and state['input_processing'] and state['mouse_mode']==0 and not state['simulation_paused'])
            check('motion is refused while human owns the body',client.act({'forward':1},'Must not override the human.').get('error')=='human_has_control')
            result=client.request('resume')
            state=read_json(OUT/'session.json')
            check('explicit resume produces a fresh observation',result['ok'] and state['controlled'] and not state['input_processing'] and state['simulation_paused'] and result['observation']['image_available'])
            process.wait(timeout=25)
            state=read_json(OUT/'session.json')
            check('idle session exits with input released',process.returncode==0 and state['mode']=='closed' and not state['controlled'] and state['drive']==[0,0])
            events=[json.loads(line) for line in (OUT/'events.jsonl').read_text(encoding='utf-8').splitlines()]
            check('privileged diagnostic requests are recorded',sum(e['type']=='privileged_audit_requested' for e in events)==2)
            recalled=client.recall('stripes')
            check('evidence-linked notebook can be recalled after shutdown',recalled['matching_entries']==1 and recalled['entries'][0]['kind']=='hypothesis' and recalled['entries'][0]['evidence']==[first])
        except Exception as error:
            failure=repr(error)
            print(failure,flush=True)
        finally:
            if process is not None and process.poll() is None:
                try:client.request('close');process.wait(timeout=12)
                except Exception:
                    process.terminate()
                    try:process.wait(timeout=5)
                    except subprocess.TimeoutExpired:process.kill();process.wait()
    text=(OUT/'native.log').read_text(encoding='utf-8',errors='replace')
    errors,shutdown=split_errors(text,'MODEL_B_SESSION_RESULT ',allow_shutdown=process is not None and process.returncode==0)
    report={'passed':failure is None and not errors,'checks':checks,'failure':failure,'runtime_errors':errors,'shutdown_diagnostics':shutdown,
        'scope':'Real Godot floor 14, player camera, physical body, source charge, production file protocol, memory evidence, stale/invalid command rejection, preemptive handover, resumption and idle closure. Not a trained model or a navigation-generalization benchmark.'}
    (OUT/'checks.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print('Receipt:',OUT/'checks.json',flush=True)
    if not report['passed']:
        print(text[-4000:]);raise SystemExit(1)


if __name__=="__main__":
    main()
