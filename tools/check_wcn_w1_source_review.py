"""Source and arithmetic evidence for W1. Does not run Godot or certify VR."""
from pathlib import Path
import hashlib
import json
import math
import re
import struct

from gdtoolkit.parser import parser
from recover_spine_platforms import ROOT, OUT, read, save_json

ARCHIVE = ROOT / 'doc/space/wcn-w1-review-2026-09-10'
PENDULUM = Path('algorithms/wavefunctions/oscillation_driver/PendulumWave.gd')
CORRIDOR = Path('algorithms/wavefunctions/sine_wall/SineWallCorridor.gd')
PROBES = [Path('commons/testing/probe_wcn_pendulum.gd'), Path('commons/testing/probe_wcn_sine_space.gd')]


def wave(source, z, phase, offset=0.0, amplitude=0.2):
    # Evaluate the actual arithmetic expression, with the caller's phase
    # argument. Compare it below with an independently stated wave equation.
    expression = re.search(r'^\s*offset \+= (.+)$', source, re.M)[1]
    return sum(eval(expression, {'__builtins__': {}}, {
        'sin': math.sin, 'PI': math.pi, 'base_amplitude': amplitude,
        'amp_multiplier': 1.0, 'amp_mul': amp, 'base_frequency': 5.2,
        'freq_multiplier': 1.0, 'freq_mul': freq, 'z_norm': 2*z-1,
        'phase': phase, 'phase_shift': phase+offset, 'phase_layer': shift})
        for freq,amp,shift in [(1,1,0),(1.8,.35,.85),(2.6,.18,-.35)])


def expected_wave(z, phase, offset=0.0, amplitude=0.2):
    return sum(amplitude*a*math.sin(math.tau*5.2*f*(z-.5)+phase+offset+p)
               for f,a,p in [(1,1,0),(1.8,.35,.85),(2.6,.18,-.35)])


def simulate_record():
    """Independent Python model of the documented fixed-tick experiment.

    It reproduces the algorithm, including Vector3's single-precision storage,
    solely to check the prose's arithmetic. It is not execution of the scene.
    """
    f32 = lambda x: struct.unpack('f',struct.pack('f',x))[0]
    angle, velocity, t, sample_clock = math.pi/4, 0.0, 0.0, 0.0
    crossing, period, interval = None, 0.0, .025
    results, points = {}, []
    for mode,seconds in [('fine',9.0),('coarse',11.0),('strobe',10.5)]:
        interval = {'fine':.025,'coarse':.2,'strobe':period or math.tau*math.sqrt(2/9.8)}[mode]
        points=[];sample_clock=0.0
        for _ in range(round(seconds*60)):
            previous=angle
            velocity += -(9.8/2)*math.sin(angle)/60
            angle += velocity/60
            t += 1/60
            if previous < 0 <= angle and velocity > 0:
                if crossing is not None:
                    period=t-crossing
                    if mode=='strobe':interval=period
                crossing=t
            sample_clock+=1/60
            if sample_clock>=interval:
                sample_clock-=interval
                points.insert(0,(f32(2*math.sin(angle)),f32(t)))
            points=points[:300]
            while points and t-points[-1][1]>10:points.pop()
        gaps=[a[1]-b[1] for a,b in zip(points,points[1:])]
        results[mode]={'count':len(points),'oldest_age':t-points[-1][1],
                       'actual_gaps_ms':[min(gaps)*1000,max(gaps)*1000],
                       'x_spread':max(p[0] for p in points)-min(p[0] for p in points),
                       'measured_period':period}
        if mode=='fine':
            def count_crossings(xs):
                crossings=[i for i in range(1,len(xs)) if xs[i-1]<0<=xs[i]]
                return crossings[1]-crossings[0] if len(crossings)>=2 else -1
            results['probe_origin']={'room_origin_count':count_crossings([6.5-p[0] for p in points]),
                                     'pendulum_origin_count':count_crossings([p[0] for p in points])}
    return results


def curation_delta(name, rel):
    """The recovered structure, the utilities, the dimensions and the museum
    contract keys must equal the review baseline byte for byte in meaning; the
    interactables and the museum's placement keys may move (documented curation
    since the review: 2026-09-10 runtime pass) and are REPORTED, not asserted."""
    now=json.loads((ROOT/rel).read_text(encoding='utf-8-sig'))
    was=json.loads((ARCHIVE/'before'/rel).read_text(encoding='utf-8-sig'))
    for layer in ('structure','utilities'):
        assert now['layers'][layer]==was['layers'][layer],(name,layer)
    assert now['map_info']['dimensions']==was['map_info']['dimensions'],(name,'dimensions')
    for key in ('wall_height','gate_depth_rows'):
        assert now['map_info'].get('museum',{}).get(key)==was['map_info'].get('museum',{}).get(key),(name,key)
    def placed(doc):
        out={}
        for z,row in enumerate(doc['layers']['interactables']):
            for x,tok in enumerate(row):
                if str(tok).strip():out[(x,z)]=tok
        return out
    a,b=placed(was),placed(now)
    delta={'removed':sorted(f'{a[c]} @ {c}' for c in a if c not in b or a[c]!=b[c]),
           'added':sorted(f'{b[c]} @ {c}' for c in b if c not in a or a[c]!=b[c]),
           'museum_keys_added':sorted(set(now['map_info'].get('museum',{}))-set(was['map_info'].get('museum',{})))}
    return delta


def runtime_status():
    """What the museum probes reported, if they have run; never a source claim.
    `_live` = the same probe under project startup (probe_live.tscn: autoloads present,
    the project's desktop rig pressing panels through its pointer)."""
    out={}
    rooms=[('WaveFunctions_Intro','probe_intro'),('Random_Definition','probe_random_definition'),
           ('Noise_Perlin_Simplex','probe_noise_pair'),('WaveFunctions_Pendulum','probe_pendulum'),
           ('WaveFunctions_Sine_Space','probe_sine_space'),('WaveFunctions_Effect_Sound','probe_effect_sound'),('WaveFunctions_AirMusic','probe_air_music'),
           ('WaveFunctions_Synthesis_Lab','probe_synthesis_lab'),('Random_Entropy','probe_entropy'),('Random_Remove','probe_remove'),('Random_Walk','probe_walk'),('Random_Gaussian','probe_gaussian'),('Random_Mushrooms','probe_mushrooms')]
    for name,stem in rooms:
        for suffix in ('','_live'):
            p=ROOT/'ada_run/waves_chance_noise'/name/f'{stem}{suffix}.json'
            if not p.exists():continue
            d=json.loads(p.read_text(encoding='utf-8-sig'));m=d.get('measurements',{})
            row={'checks':d.get('checks'),'failures':d.get('failures'),'status':d.get('status','n/a')}
            if 'skipped' in d:row['skipped']=d['skipped']
            if 'release_exercised' in m:row['release_exercised']=m['release_exercised']
            di=m.get('desktop_input')
            if isinstance(di,dict):
                press=di.get('press') or {}
                row['desktop_input']={'pressed':press.get('control','')[-40:],'hover':press.get('hover','')[-40:],
                                      'walker_cam_guard_stopped':di.get('walker_cam_guard_stopped')}
                if 'carry_hover' in di:row['desktop_input']['carry_hover']=di['carry_hover']
            if 'streaming' in m:row['museum_streaming']=m['streaming']
            out[f'{name}{suffix}']=row
    for stem in ('probe_clear_rects','probe_w1_reload'):
        p=ROOT/'ada_run/waves_chance_noise'/f'{stem}.json'
        if p.exists():
            d=json.loads(p.read_text(encoding='utf-8-sig'))
            out[stem]={'checks':d.get('checks'),'failures':d.get('failures')}
    return out or 'no probe report found'


def main():
    curation={}
    parser._cache_dirpath = str(ROOT/'ada_run/gdtoolkit-cache')
    sources={p:(ROOT/p).read_text(encoding='utf-8-sig') for p in [PENDULUM,CORRIDOR,*PROBES]}
    for source in sources.values():parser.parse(source)
    old=(ARCHIVE/'before'/CORRIDOR).read_text(encoding='utf-8-sig');new=sources[CORRIDOR]
    phase_errors=[];old_errors=[];cancel_errors=[]
    for phase in [0,.73,1.9,math.pi,5.7]:
        for z in [.03,.19,.37,.5,.81,.98]:
            phase_errors.append(abs(wave(new,z,phase)-expected_wave(z,phase)))
            old_errors.append(abs(wave(old,z,phase)-expected_wave(z,phase)))
            cancel_errors.append(abs(wave(new,z,phase)+wave(new,z,phase,math.pi)))
    assert max(phase_errors)<1e-12 and max(cancel_errors)<1e-12
    assert max(old_errors)>.05, 'The negative baseline must expose the double-phase bug'
    expr=re.search(r'var intensity: float = (.+)',new)[1]
    flat=eval(expr,{'__builtins__':{}},{'displacement':0,'base_amplitude':0,'maxf':max,'absf':abs})
    assert math.isfinite(flat)
    model=simulate_record()
    assert model['fine']['count']==300
    assert 7.4<model['fine']['oldest_age']<7.6
    assert 16.6<model['fine']['actual_gaps_ms'][0]<16.8
    assert 33.2<model['fine']['actual_gaps_ms'][1]<33.5
    assert 49<=model['coarse']['count']<=51
    assert model['probe_origin']['room_origin_count']==-1
    assert 110<model['probe_origin']['pendulum_origin_count']<125
    assert model['strobe']['x_spread']<.12
    excerpts=0
    for name,script in [('WaveFunctions_Pendulum',PENDULUM),('WaveFunctions_Sine_Space',CORRIDOR)]:
        available={line.strip() for line in sources[script].splitlines()}
        for filename in ['final.md','tutorial.md','technical.md']:
            path=ROOT/'commons/maps'/name/filename
            for block in re.findall(r'```gdscript\s*\n(.*?)```',path.read_text(encoding='utf-8-sig'),re.S):
                for line in block.splitlines():
                    if line.strip():assert line.strip() in available,(str(path),line)
                excerpts+=1
        rel=Path('commons/maps')/name/'map_data.json'
        curation[name]=curation_delta(name,rel)
    runtime=runtime_status()
    report={'mode':'source expressions + independent arithmetic model; no Godot execution',
            'gdscript_parses':4,'verbatim_gdscript_excerpts':excerpts,
            'map_structure_and_utilities':'unchanged against the review baseline',
            'map_curation_since_review':curation,
            'phase_error_before':max(old_errors),'phase_error_after':max(phase_errors),
            'half_turn_cancellation_error':max(cancel_errors),'flat_colour_intensity':flat,
            'pattern_repeat_seconds':math.tau/.35,'record_model':model,
            'runtime':runtime,
            'source_sha256':{p.as_posix():hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}}
    save_json(ROOT/'ada_run/waves_chance_noise/astra-w1-source-checks.json',report)
    save_json(ARCHIVE/'source-checks.json',report)
    print(json.dumps(report,indent=2))


if __name__=='__main__':main()
