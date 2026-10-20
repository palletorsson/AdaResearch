"""Freeze the small invitation revision and compare its changed paragraphs."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import re
import shutil
import markdown

here=Path(__file__).resolve().parent
root=here.parents[3]
style='''*{box-sizing:border-box}body{margin:0;background:#f4f1e9;color:#292e2b;font:17px/1.6 system-ui,sans-serif}main{max-width:1400px;margin:auto;padding:30px}h1,h2{font-family:Georgia,serif;font-weight:normal}h1{font-size:42px;line-height:1.15}h2{margin-top:40px}a{color:#5b527c}.pair{display:grid;grid-template-columns:1fr 1fr;gap:28px;margin:20px 0 35px}.pair article{padding:20px;background:#fffdf8;border-top:3px solid #9e9d92}.pair article:last-child{border-color:#6d988a}.prose{font:20px/1.75 Georgia,serif}.eyebrow{font-size:13px;text-transform:uppercase;letter-spacing:.05em}.note{border-left:3px solid #6d988a;padding:15px 22px;background:#e6e9df}.gallery{display:grid;grid-template-columns:1fr 1fr;gap:24px}figure{margin:20px 0}img{width:100%;height:auto}figcaption{font-size:14px}nav{display:flex;gap:22px;flex-wrap:wrap}details{padding:15px;background:#ece7dc;margin:25px 0}summary{cursor:pointer}footer{border-top:1px solid #bcb6aa;margin-top:35px;padding-top:15px}@media(max-width:850px){main{padding:20px}.pair,.gallery{grid-template-columns:1fr}h1{font-size:32px}}'''

def read(path):return path.read_text(encoding='utf-8')
def words(s):
    s=re.sub(r'(?m)^#.*$','',re.split(r'(?m)^\[\^[^\]]+\]:',s)[0])
    return len(re.findall(r"\b\w+(?:['’-]\w+)*\b",re.sub(r'<!--.*?-->|\[\^[^\]]+\]','',s,flags=re.S)))
def prose(s):return markdown.markdown(re.sub(r'\[\^[^\]]+\]','',s))

report={'reader_response':'Both: difficult operation and actions visitors may not naturally choose','headset_trial':False,'maps':{},'native_runs':{},'sources':{}}
body='<p class="note">Physical operation and the reason to act are separate tests. This pass adds short local invitations and revises five paragraphs. It does not claim that a visitor will follow the narrated investigation.</p><nav><a href="#writing">Writing comparison</a><a href="#views">Installed cues</a><a href="notes.md">Decisions and next test</a></nav><h2 id="writing">The question before the control</h2>'
for name,label in [('Random_Entropies','Entropy Types'),('Random_Entropy','Entropy Workshop')]:
    folder=root/'commons/maps'/name
    before=here/'before/commons/maps'/name
    old,new=read(before/'final.md'),read(folder/'final.md')
    wall=json.loads(read(folder/'writing_wall.json'))
    old_wall=json.loads(read(before/'writing_wall.json'))
    order=[i for i in wall['order'] if any(m['id']==i and 'final' in m.get('tags',[]) for m in wall['magnets'])]
    assert re.findall(r'<!-- @([^\s>]+) -->',new)==order
    assert json.loads(read(folder/'map_data.json'))==json.loads(read(before/'map_data.json'))
    assert {k:v for k,v in wall.items() if k!='magnets'}=={k:v for k,v in old_wall.items() if k!='magnets'}
    for a,b in zip(wall['magnets'],old_wall['magnets']):assert {k:v for k,v in a.items() if k!='final'}=={k:v for k,v in b.items() if k!='final'}
    dest=here/'after'/name;dest.mkdir(parents=True,exist_ok=True)
    shutil.copy2(folder/'final.md',dest/'final.md')
    report['maps'][name]={'before_words':words(old),'after_words':words(new),'order':order,'map_and_magnet_layout_unchanged':True}
    body+=f'<h2>{label}</h2><p>Frozen complete sources: <a href="before/commons/maps/{name}/final.md">before</a> · <a href="after/{name}/final.md">revised final</a>.</p>'
    a,b=old.split('\n\n'),new.split('\n\n')
    for op,i,j,k,l in difflib.SequenceMatcher(a=a,b=b).get_opcodes():
        if op=='equal':continue
        body+='<div class="pair"><article><div class="eyebrow">Before</div><div class="prose">'+prose('\n\n'.join(a[i:j]))+'</div></article><article><div class="eyebrow">Revised</div><div class="prose">'+prose('\n\n'.join(b[k:l]))+'</div></article></div>'

assert json.loads(read(root/'commons/data/museum/em_plan.json'))==json.loads(read(here/'before/commons/data/museum/em_plan.json'))
body+='<h2 id="views">Small cues at the point of action</h2><p>Steady cap colours distinguish available actions; a selected guess has separate feedback. No flashing prompts or forced steps were added.</p><div class="gallery">'
captions={'doors-invitation':'The visible gap supplies the question; STEP remains a shared, deliberate advance.','guess-invitation':'Colour choices and a short question precede DRAW.','guess-result':'The chosen pink cap remains selected after release; DRAW is a momentary action.','cabinet-invitation':'An exchange across the divider has a stated purpose; SAME k names the within-tray alternative.','cabinet-result':'After an exchange, the outcome replaces the opening invitation. The short input hint remains.'}
for label,name in [('types','Random_Entropies'),('workshop','Random_Entropy')]:
    origin=root/'ada_run/encounter_pilot'/name/'entropy-invitations'
    native=json.loads(read(origin/'report.json'));assert native['passed'] and not native['failures']
    dest=here/label;dest.mkdir(exist_ok=True)
    for source in list(origin.glob('*.png'))+[origin/'report.json',origin/'source_manifest.json']:shutil.copy2(source,dest/source.name)
    report['native_runs'][label]={'checks':len(native['checks']),'report':label+'/report.json'}
    for filename in captions:
        path=dest/(filename+'.png')
        if path.exists():body+=f'<figure><a href="{label}/{path.name}"><img src="{label}/{path.name}" alt="{html.escape(captions[filename])}" loading="lazy"></a><figcaption>{captions[filename]}</figcaption></figure>'
body+='</div><details><summary>What these checks establish</summary><p>Native scene loading, supplied physics contacts and XR pointer dispatch, selected-state retention, and captured viewpoints. They do not establish tracked-hand comfort, headset legibility, discoverability or the desire to continue.</p><a href="verification.json">Verification record</a></details><h2>Next: an unprompted encounter</h2><p>Before naming a control, record what the visitor wants to inspect or change. Then record whether they find the target, activate it once and see the consequence. Staying, skipping or choosing another action remains evidence.</p>'
paths=['commons/artifacts/ordinary_entropies/'+p for p in ['study_controls.gd','door_study.gd','guess_table.gd']]+['commons/artifacts/entropy_compartments/entropy_compartments.gd']
for relative in paths:
    source=root/relative;dest=here/'sources'/relative;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,dest)
    report['sources'][relative]=hashlib.sha256(source.read_bytes()).hexdigest()
(here/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(here/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A reason to touch the control</title><style>'+style+'</style></head><body><main><div class="eyebrow">Ada Research · 16 October 2026</div><h1>A reason to touch the control</h1>'+body+'<footer>Room and final order preserved. First 48-value research pilot unchanged. Human discovery remains untested.</footer></main></body></html>',encoding='utf-8')
print(json.dumps({'maps':report['maps'],'native_runs':report['native_runs']},ensure_ascii=False))
