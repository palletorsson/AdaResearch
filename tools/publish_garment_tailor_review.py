"""Current museum evidence and book passages for the robot cutting table."""
from pathlib import Path
import hashlib,html,json,re,shutil
import publish_tiling_cards_and_cloth as render
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-cutting-a-suit'
STYLE='''*{box-sizing:border-box}body{margin:0;background:#f1eee5;color:#272b2a;font:17px/1.65 system-ui,sans-serif}main{max-width:1480px;padding:40px 5vw;margin:auto}h1,h2{font-family:Georgia,serif;font-weight:400;line-height:1.1}h1{font-size:clamp(40px,6vw,84px);max-width:1000px;margin:38px 0 22px}h2{font-size:34px}p{max-width:850px}a{color:inherit;text-underline-offset:4px}nav{display:flex;gap:18px;flex-wrap:wrap;font-size:14px}.intro{font-size:23px;max-width:860px}figure{margin:25px 0 40px}img{width:100%;display:block}figcaption{color:#666b64;font-size:14px;padding:12px 0}.grid,.pair{display:grid;grid-template-columns:1fr 1fr;gap:28px}.pair article{background:#faf8f1;padding:28px;min-width:0}.steps{display:grid;grid-template-columns:repeat(4,1fr);gap:22px;border-block:1px solid #cdc8bc;padding:20px 0;margin:30px 0}.steps p{font-size:15px}.eyebrow{font-size:13px;letter-spacing:.15em;color:#657169;text-transform:uppercase}.evidence{background:#deded0;padding:24px;margin:40px 0}pre{font-size:13px;overflow:auto;padding:16px;background:#e7e4da}table{border-collapse:collapse;width:100%;font-size:14px}td,th{padding:10px;border:1px solid #c9c5b8;text-align:left}section{margin-block:55px;scroll-margin-top:24px}.reading{max-width:940px;margin:auto}.reading img{max-width:900px}.nav-map{display:flex;flex-wrap:wrap;gap:14px;margin:25px 0}@media(max-width:800px){.grid,.pair,.steps{grid-template-columns:1fr}main{padding:20px}.pair article{padding:18px}}'''
def page(title,body):
    # Source-note links are relative to the map directory, not this review folder.
    body=body.replace('../../../doc/book/iterations/2026-10-10-optical-woven-checks/index.html','../2026-10-10-optical-woven-checks/index.html')
    nav='<nav><a href="index.html">Museum station</a><a href="passages.html">Updated book passages</a><a href="tutorials.html">All tutorials</a><a href="final.html">All reflections</a><a href="tests.json">Code checks</a><a href="museum-tests.json">Museum checks</a></nav>'
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+STYLE+'</style><main>'+nav+body+'</main></html>'
def write(name,text):(OUT/name).write_text(text,encoding='utf-8')
def figure(name,caption):return f'<figure><a href="{name}.png"><img src="{name}.png" alt="{html.escape(caption)}"></a><figcaption>{caption}</figcaption></figure>'
def main():
    render.OUT=OUT;(OUT/'images').mkdir(exist_ok=True)
    records=[json.loads((OUT/name).read_text()) for name in ['tests.json','museum-tests.json']]
    assert all(r['passed'] and all(c['passed'] for c in r['checks']) for r in records)
    count=sum(len(r['checks']) for r in records)
    body='<p class="eyebrow">Endless Museum · Tiling · Ribbon Patterns 03</p><h1>The cloth becomes<br>a suit you can wear.</h1><p class="intro">Keep a sample from the loom. Lay out its jacket, sleeves and trousers. Watch the robot lift the pieces onto a fitting figure, then put the suit on your museum avatar.</p>'
    body+=figure('assembly','Native Godot capture: the arm carries the next piece from the cutting table to the fitting.')
    body+='<div class="steps"><div><strong>1 / Keep the cloth</strong><p>At the Jacquard loom, SAVE CLOTH stores the woven picks and yarn colours. LOAD LOOM brings that record to this table.</p></div><div><strong>2 / Cut ten pieces</strong><p>Fronts, backs, sleeves and trouser panels stay labelled. CUT follows the outlines; the surrounding cloth clears.</p></div><div><strong>3 / Assemble</strong><p>The articulated arm transfers the panels one at a time. Their pattern addresses stay attached as they curve. PAUSE and RESET stay within reach.</p></div><div><strong>4 / Wear</strong><p>WEAR dresses your actual museum avatar and saves the cloth with the suit. TAKE OFF returns to the previous outfit. Use the existing mirror to see yourself.</p></div></div>'
    body+='<div class="grid">'+figure('cutting-layout','The ten pieces occupy separate regions of the saved cloth.')+figure('cutting','The cutting wheel traces the next outline.')+'</div>'
    body+=figure('fitted-museum','The completed station inside Ribbon Patterns 03, beside the existing fabric studio and mirror.')
    body+='<div class="grid">'+figure('fitted-suit','The fitting figure wearing the supplied houndstooth sample.')+figure('worn-suit','The same suit on the museum walker: actual wardrobe geometry, viewed from another camera.')+'</div>'
    body+='<h2>A record can travel.</h2><p>The table also supplies tartan, houndstooth and optical checks through CLOTH. Loading or changing the table does not recolour the suit already worn. The independent shader studio and its skirt experiment remain beside it.</p><p>This is a ten-panel geometric tailoring model. The weave record determines the surface texture; folding is prescribed. It does not simulate yarn cutting, sewing, fabric drape or fitting arbitrary body measurements. Sleeves follow tracked hands; the torso and legs use the existing inferred avatar.</p>'
    body+=f'<div class="evidence"><h2>{count} native checks passed.</h2><p>Real loom-to-table save/load, an edited crossing retained, cut/assembly gates, pause/reset, ten panels preserving their UVs, wearable application, a freshly restored wardrobe, independent subsequent edits and four clear standing approaches in the installed hall.</p><p>Test saves belong to an isolated review snapshot. No physical-headset comfort test has been performed. Existing unrelated startup warnings remain in the logs; neither probe reports a script error.</p><a href="source-hashes.json">Tested source snapshot</a> · <a href="source/commons/artifacts/garment_cutting_table/README.md">Station guide</a></div>'
    write('index.html',page('Cutting a suit · Endless Museum',body))
    paired='<h1>A sample travels into clothing.</h1>'
    for name in ['Symmetry_Seventeen','Ribbon_Patterns_03']:
        tutorial=(ROOT/f'commons/maps/{name}/tutorial.md').read_text(encoding='utf-8')
        start='### Optional: follow a card into cloth' if name=='Symmetry_Seventeen' else '## Optional: cut the cloth you kept'
        excerpt=tutorial.split(start)[1].split('## Complete carried files')[0]
        if name=='Ribbon_Patterns_03':excerpt=excerpt.split('## What travels')[0]
        final=(ROOT/f'commons/maps/{name}/final.md').read_text(encoding='utf-8')
        paired+=f'<section><h2>{name.replace("_"," ")}</h2><div class="pair"><article><p class="eyebrow">Tutorial · supplied encounter</p>'+render.render(start+excerpt)+'</article><article><p class="eyebrow">Reflection</p>'+render.render(final)+'</article></div></section>'
        old=(OUT/f'before/commons/maps/{name}/tutorial.md').read_text(encoding='utf-8')
        assert re.findall(r'```.*?```',old,re.S)==re.findall(r'```.*?```',tutorial,re.S)
    write('passages.html',page('The loom and garment passages',paired))
    maps=json.loads((ROOT/'commons/maps/sequences/tiling.json').read_text(encoding='utf-8'))['sequences']['tiling']['maps']
    for kind,target in [('tutorial','tutorials'),('final','final')]:
        content=f'<h1>Tiling · {target}</h1><div class="nav-map">'+''.join(f'<a href="#{m}">{m.replace("_"," ")}</a>' for m in maps)+'</div><div class="reading">'
        complete=[]
        for m in maps:
            source=(ROOT/f'commons/maps/{m}/{kind}.md').read_text(encoding='utf-8-sig')
            content+=f'<section id="{m}">'+render.render(source)+'</section>';complete.append(f'<!-- hall: {m} -->\n\n'+source)
        write(target+'.html',page('Tiling · '+target,content+'</div>'));write('tiling-'+target+'.md','\n\n---\n\n'.join(complete))
    for src,target in [('commons/maps/Symmetry_Seventeen/textile-note.md','textile-note'),('commons/maps/Pattern_Foundry/further-encounters.md','foundry-further')]:
        write(target+'.html',page(target,render.render((ROOT/src).read_text(encoding='utf-8'))))
    files=list((ROOT/'commons/artifacts/garment_cutting_table').glob('*'))+[ROOT/p for p in ['commons/player/tailored_suit.gd','commons/player/queer_costume.gd','commons/player/costume_wardrobe.gd','commons/artifacts/jacquard_weaver/jacquard_studio.gd','commons/artifacts/registry/garment_cutting_table.json','commons/maps/Ribbon_Patterns_03/map_data.json','tools/probes/garment_tailor_test.gd','tools/probes/garment_tailor_museum.gd','tools/run_garment_tailor_review.py']]
    hashes={}
    for p in files:
        if not p.is_file() or p.suffix not in ['.gd','.tscn','.md','.json','.py']:continue
        rel=p.relative_to(ROOT);dest=OUT/'source'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest);hashes[rel.as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
    write('source-hashes.json',json.dumps(hashes,indent=2)+'\n')
    write('REPORT.md',f'# Cloth becomes a suit\n\nInstalled table at Ribbon_Patterns_03 (6,12); all existing placements preserved. The Jacquard loom now exports committed cloth to this station. Ten cut panels retain UV addresses, animate onto a fitting and equip the real persistent wardrobe. Three supplied samples. {count} native Godot checks passed, including live hall approaches and outfit application. No headset test. Cosmetic panel model, no cloth mechanics or bespoke sizing.\n\nSix canonical manuscript/intent/source-note files updated, core printed programs unchanged. Full current nine-hall readers and paired loom/garment passages included.\n')
    print('Published',OUT/'index.html',count,'checks')
if __name__=='__main__':main()
