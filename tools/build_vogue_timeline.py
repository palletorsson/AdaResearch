"""Generate original loop and install one artifact; preserve other museum rows."""
from pathlib import Path
import json, math, random, struct, sys, wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-vogue-a-phrase-of-your-own'
OUT.mkdir(parents=True, exist_ok=True)

def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
def save(path, value, compact=False):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=None if compact else 2) + '\n', encoding='utf-8')

def main():
    # Original four-on-the-floor eight-beat practice loop, no borrowed recording.
    rate, bpm = 22050, 112
    duration = 8 * 60 / bpm
    rng = random.Random(112)
    samples = []
    for i in range(round(duration * rate)):
        t = i / rate
        beat = t * bpm / 60
        k = (beat % 1) * 60 / bpm
        kick = math.sin(2 * math.pi * (48*k + 2.5*(1-math.exp(-k*32)))) * math.exp(-k*18)
        hat_t = (beat % .5) * 60 / bpm
        hat = rng.uniform(-1, 1) * math.exp(-hat_t*100) * .18
        clap_t = ((beat-1) % 2) * 60 / bpm
        clap = rng.uniform(-1, 1)*math.exp(-clap_t*35)*.3
        note = [110,110,130.813,146.832][int(beat/2)%4]
        bass = math.sin(2*math.pi*note*t)*math.exp(-k*9)*.16
        samples.append(struct.pack('<h', int(max(-1,min(1,.52*kick+hat+clap+bass))*24000)))
    with wave.open(str(ROOT/'commons/artifacts/vogue_timeline/phrase_112.wav'), 'wb') as wav:
        wav.setnchannels(1); wav.setsampwidth(2); wav.setframerate(rate); wav.writeframes(b''.join(samples))
    paths = ['commons/maps/ML_Perception/map_data.json', 'commons/artifacts/registry/machinelearning.json', 'commons/data/museum/em_plan.json']
    for relative in paths:
        target=OUT/'before'/relative
        if not target.exists():
            target.parent.mkdir(parents=True,exist_ok=True)
            target.write_bytes((ROOT/relative).read_bytes())
    registry_path=ROOT/paths[1]
    registry=read(registry_path)
    registry['artifacts']['vogue_timeline']={
        'lookup_name':'vogue_timeline','name':'Vogue — a phrase of your own',
        'scene':'res://commons/artifacts/vogue_timeline/vogue_timeline.tscn',
        'category':'machinelearning','sequence':'machinelearning','map_sequences':['machinelearning'],
        'map_ready':True,'include_in_map_data':True,'interaction':'dance / record / replay / teach poses / teach height / teach phrases A and B / train / test / check intention',
        'description':'Two airborne hand paths follow a 32-beat dance reference. Beside it, the same sphere learns pose categories, continuous hand-height control, one four-second two-hand phrase or two labelled phrases A and B. Unfamiliar and ambiguous performances can be withheld. CHECK compares declared intention with predictions and preserves earlier model results. Fresh tests and local saves remain separate from training. These measured relations do not judge dance quality.',
        'tags':['vogue','ballroom','pose','dance','timeline','template_matching','supervised_learning','neural_network','pose_classifier','linear_regression','temporal_prototype','two_hand_phrase'],
        'spatial_needs':{'platform':'none','footprint_cells':6,'clearance':{'front':2,'back':0,'left':1,'right':1}},
        'parameters':{'reach':'0.45 / 0.65 / 0.85 metres','tempo':'96 / 112 / 128 BPM','tolerance':'adjustable distance, not probability'},
        'qfep_connection':'A dancer can replace the supplied reference with their own phrase. The measured relation remains smaller than the dance.'}
    # Preserve the formatting and contents of every unrelated registry entry.
    registry_text=registry_path.read_text(encoding='utf-8')
    entry=registry['artifacts']['vogue_timeline']
    marker='"vogue_timeline":'
    if marker in registry_text:
        start=registry_text.index(marker)+len(marker)
        while registry_text[start].isspace(): start+=1
        _,length=json.JSONDecoder().raw_decode(registry_text[start:])
        value=json.dumps(entry,ensure_ascii=False,indent='\t').replace('\n','\n\t\t')
        registry_text=registry_text[:start]+value+registry_text[start+length:]
    else:
        value=json.dumps({'vogue_timeline':entry},ensure_ascii=False,indent='\t')[2:-2]
        inserted='\n'+'\n'.join('\t'+line for line in value.splitlines())+','
        registry_text=registry_text.replace('"artifacts": {','"artifacts": {'+inserted,1)
    assert json.loads(registry_text)==registry
    registry_path.write_text(registry_text,encoding='utf-8')
    path=ROOT/paths[0]
    data=read(path)
    # Widen only the eastern open gallery, preserving the original two exhibits.
    for name, layer in data['layers'].items():
        for z,row in enumerate(layer):
            if len(row)==13:
                if name=='structure':
                    row[-1:] = ['w']*5 if z in (0,len(layer)-1) else ['1']*4+['w']
                else: row.extend(['']*4)
    data['map_info']['dimensions']['width']=max(17,len(data['layers']['structure'][0]))
    placed=[cell for row in data['layers']['interactables'] for cell in row if cell.split(':')[0]=='vogue_timeline']
    separate_bay=any('#learning_bay:1' in cell for cell in placed)
    if not placed:
        data['layers']['interactables'][5][12]='vogue_timeline:0:0:1#plinth:0#pin:1'
    data['layers']['interactables'][3][3]='computer_vision_vr:0:0:0.28'
    if not separate_bay:
        data['map_info']['museum']['vogue_note']='Eastern gallery widened for a 5.2 m dance installation; guide is illustrative, head and hands are measured.'
    data['map_info']['museum']['artifact_placement']='map'
    if not separate_bay:
        data['map_info']['museum']['sculpture_clear_rects']=[[9,1,15,8]]
    save(path,data)
    sys.path.insert(0,str(ROOT/'tools'))
    import em_map_halls
    plan_path=ROOT/paths[2]
    plan=read(plan_path)
    for i,old in enumerate(plan['plans']):
        if old.get('map')=='ML_Perception':
            row=em_map_halls.derive_row(old['pearl'],'ML_Perception',old['museum'],old['pearl_index'],old['pearls_total'],'machinelearning')
            # Map already has the museum walls and a deliberate continuous dance floor.
            plan['plans'][i]=row
            break
    save(plan_path,plan,True)
    print('Installed vogue_timeline in ML_Perception; generated original 112 BPM loop.')

if __name__=='__main__': main()
