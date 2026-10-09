"""Freeze pre-revision sources once and publish the editable plan and journal."""
from pathlib import Path
import hashlib, html, json, re, shutil
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision'
PLAN=ROOT/'doc/book/course/randomness-revision'
BLOG=ROOT/'doc/blog/2026-10-09-what-a-tutorial-must-keep'
STYLE='''*{box-sizing:border-box}body{margin:0;background:#f5f1e9;color:#25252c;font:19px/1.7 Georgia,serif}main{max-width:1000px;margin:auto;padding:50px 35px}h1{font-size:clamp(35px,6vw,62px);line-height:1.08}h2{margin-top:2em}h3{margin-top:2em;border-top:1px solid #c8c0b9;padding-top:24px}a{color:#7c365b}nav{font:14px/1.6 system-ui;display:flex;gap:18px;flex-wrap:wrap}img{width:100%;height:auto}p,li{max-width:800px}pre{overflow:auto;background:#e7e4df;padding:20px;font:14px/1.5 monospace}code{font-size:.88em}table{border-collapse:collapse;font:14px/1.6 system-ui;width:100%}td,th{padding:10px;border-bottom:1px solid #aaa;text-align:left}summary{cursor:pointer;font-family:system-ui}@media print{nav{display:none}body{background:white;font-size:11pt}h1{font-size:30pt}}'''

def page(title, body, nav=''):
    return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{STYLE}</style><main><nav>{nav}</nav>{markdown.markdown(body,extensions=["extra"])}</main></html>'

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    seq=json.loads((ROOT/'commons/maps/sequences/randomness.json').read_text(encoding='utf8'))['sequences']['randomness']
    if not (OUT/'before-manifest.json').exists():
        hashes={}
        for m in seq['maps']:
            for name in ['tutorial.md','final.md','map_data.json']:
                src=ROOT/'commons/maps'/m/name
                target=OUT/'before'/m/name;target.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(src,target)
                hashes[src.relative_to(ROOT).as_posix()]=hashlib.sha256(src.read_bytes()).hexdigest()
        shutil.copy2(ROOT/'commons/maps/sequences/randomness.json',OUT/'before/sequence.json')
        (OUT/'before-manifest.json').write_text(json.dumps(hashes,indent=2),encoding='utf8')
    status_path=PLAN/'STATUS.json'
    if not status_path.exists():
        status_path.write_text(json.dumps({'scope':'14 halls; one revision at a time. No production-code or sequence-order change.', 'halls':[{'map':m,'status':'in_progress' if i==0 else 'planned','tutorial_test':'not_yet_run','museum_test':'not_yet_run'} for i,m in enumerate(seq['maps'])]},indent=2),encoding='utf8')
    inventory=[]
    for m in seq['maps']:
        text=(OUT/'before'/m/'tutorial.md').read_text(encoding='utf8')
        blocks=re.findall(r'```gdscript\s*\n(.*?)```',text,re.S)
        inventory.append({'map':m,'gdscript_blocks':len(blocks),'printed_lines':sum(len(b.strip().splitlines()) for b in blocks),'named_complete_listings':len(re.findall('<!-- student-code:',text)), 'dollar_reference':bool(re.search(r'\$[A-Za-z]',text)), 'proposed_focus_note':'proposed focus' in text.lower()})
    (OUT/'initial-inventory.json').write_text(json.dumps(inventory,indent=2),encoding='utf8')
    raw=(BLOG/'post.md').read_text(encoding='utf8')
    front,body=raw.split('---',2)[1:]
    meta={k:json.loads(v.strip()) for k,v in (line.split(':',1) for line in front.strip().splitlines())}
    canonical=ROOT.parent/'ada_encyclopedia/src/content/blog'/f'{BLOG.name}.md'
    canonical.write_text(raw,encoding='utf8')
    image=ROOT/'doc/book/iterations/2026-10-08-wavefunctions-ghost-student/museum/WaveFunctions_Intro/student.png'
    shutil.copy2(image,BLOG/'wavefunctions-student.png')
    portable=body.replace(meta['thumbnail'],'wavefunctions-student.png')
    portable=portable.replace('/book-review/doc/book/iterations/2026-10-08-wavefunctions-ghost-student/index.html','../../book/iterations/2026-10-08-wavefunctions-ghost-student/index.html').replace('/book-review/doc/book/course/randomness-revision/PLAN.md','../../book/course/randomness-revision/PLAN.md')
    (BLOG/'index.html').write_text(page(meta['title'],'# '+meta['title']+'\n\n'+meta['subtitle']+'\n\n'+portable,'<a href="post.md">Markdown</a><a href="../../book/iterations/2026-10-09-randomness-revision/index.html">Work plan</a>'),encoding='utf8')
    plan=(PLAN/'PLAN.md').read_text(encoding='utf8')
    status=json.loads(status_path.read_text(encoding='utf8'))
    progress='\n\n## Current progress\n\n| Hall | State | Code test | Museum |\n|---|---|---|---|\n'+''.join(f'|{r["map"]}|{r["status"]}|{r["tutorial_test"]}|{r["museum_test"]}|\n' for r in status['halls'])
    nav='<a href="../../../blog/2026-10-09-what-a-tutorial-must-keep/index.html">Retrospective</a><a href="../../course/randomness-revision/PLAN.md">Edit plan</a><a href="../../course/randomness-revision/STATUS.json">Status</a>'
    if (OUT/'Random_Definition/parallel.html').exists():nav+='<a href="Random_Definition/parallel.html">First revised lesson</a>'
    (OUT/'index.html').write_text(page('Randomness — plan and progress',plan+progress,nav),encoding='utf8')
    receipt={'blog_source':str(canonical),'copy_matches':canonical.read_bytes()==(BLOG/'post.md').read_bytes(),'image_sha256':hashlib.sha256(image.read_bytes()).hexdigest(),'snapshot_files':len(json.loads((OUT/'before-manifest.json').read_text())),'initial_inventory':inventory,'scope':'Initial text inventory, not runtime validation of fourteen halls.'}
    (OUT/'publication.json').write_text(json.dumps(receipt,indent=2),encoding='utf8')
    print(json.dumps({'blog':str(BLOG/'index.html'),'plan':str(OUT/'index.html'),'snapshot_files':receipt['snapshot_files']}))

if __name__=='__main__':main()
