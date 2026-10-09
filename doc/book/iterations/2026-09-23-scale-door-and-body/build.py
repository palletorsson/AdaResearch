from pathlib import Path
import html,re,difflib,json
import markdown
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
def render(s,prefix):
    s=re.sub(r'<!--\s*@[^>]*-->','',s)
    return markdown.markdown(s,extensions=['extra','sane_lists']).replace('id="fn','id="'+prefix+'-fn').replace('href="#fn','href="#'+prefix+'-fn')
def photo(name,caption):
    return '<figure><a href="'+name+'.png"><img src="'+name+'.png" alt="'+html.escape(caption,quote=True)+'"></a><figcaption>'+caption+'</figcaption></figure>'
before=(OUT/'Trans_Scale.before.md').read_text(encoding='utf-8');after=(OUT/'Trans_Scale.after.md').read_text(encoding='utf-8')
assert after==(ROOT/'commons/maps/Trans_Scale/final.md').read_text(encoding='utf-8')
a,b=before.split('\n\n'),after.split('\n\n');pairs=[]
for i,(tag,x,y,u,v) in enumerate(difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes()):
    if tag=='equal':continue
    left=render('\n\n'.join(a[x:y]),'old-'+str(i)) or '<p>New illustration.</p>'
    right=render('\n\n'.join(b[u:v]),'new-'+str(i)) or '<p>Passage removed.</p>'
    pairs.append('<div class="pair"><div><h4>Before</h4>'+left+'</div><div><h4>Now</h4>'+right+'</div></div>')
css=re.search(r'<style>(.*?)</style>',(OUT.parent/'2026-09-23-transformation-encounters/index.html').read_text(encoding='utf-8'),re.S)[1]
css+=' .pair img{max-width:100%} .reading{margin-top:25px} figure img{height:auto} .note{max-width:760px}'
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Scale — an opening for whom?</title><style>'+css+'</style></head><body><main>'
page+='''<div class="eyebrow">Ada Research / Trans Scale / 23 September 2026</div><h1>An opening for whom?</h1><div class="intro"><p>You can see the opening. You can point to the space beyond. Your body will not follow.</p><p>The bottle changes the room. The body that returns to the doorway keeps its size.</p></div><p class="status">A small pass, applied to <strong>Trans_Scale/final.md</strong>: one clearer sentence, one question and a paired museum illustration. The existing encounter and most of the chapter are preserved.</p><nav><a href="#encounter">Working illustration</a><a href="#comparison">Text differences</a><a href="#reading">Read the hall</a><a href="SUMMARY.md">Scope and evidence</a><a href="/compose/sources?map=Trans_Scale&amp;doc=final">Comment on final.md</a></nav>'''
page+='<section id="encounter"><h2>The opening changes; the measure stays</h2>'+photo('door-and-body','Both cameras stand 1.65 m above the room floor and 2.5 m from the opening, with the same aim and field of view. The distant gold frame on the right never changed size.')+'<p class="note">The same 0.44 m wide, 1.6 m high test capsule is stopped by the tiny doorway and passes through the enlarged one. A hypothetical fourfold capsule remains too tall. That last comparison is a test of the question in the text; the museum bottle still enlarges only the room.</p><details><summary>The room and the arrival on the plate</summary><div class="photos">'+photo('room-before','Before taking the bottle, the figure stands behind the food tower and its porcelain serving plates.')+photo('on-the-plate','After the actual desktop pickup: eye height remains 1.65 m above the relocated body. This view combines room scaling with arrival on the high plate.')+'</div></details></section>'
page+='''<section id="comparison"><h2>Keep what already works</h2><p>The crystal figure, flowering food, sudden cut, two code excerpts, descent and ordinary museum beyond the room remain. One sentence explains that scaling only the sculptures’ dimensions would leave their distance unchanged. The doorway passage adds a question about including the body in the same multiplication.</p><details open><summary>Original and revised passages</summary>'''+''.join(pairs)+'''</details><p><a href="Trans_Scale.diff">Exact manuscript diff</a> · <a href="source-changes.diff">All prose and supporting-record changes</a></p></section>'''
page+='<section id="reading"><h2>Trans Scale</h2><article class="reading">'+render(after,'reading')+'</article></section>'
page+='''<footer><p>17 focused checks pass in the isolated production museum. The views are native captures; the page also preserves the before/after manuscript. No map, runtime behavior or controls changed. Desktop pickup and selected doorway sweeps do not establish headset feel or learner understanding; the descent was not rewalked in this pass.</p><p>Next: Trans_Body, where the body’s passage begins to change the material around it.</p><p><a href="report.json">Runtime checks</a> · <a href="verification.json">Publication checks</a> · <a href="SUMMARY.md">Full scope</a></p></footer></main></body></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
print(OUT/'index.html')
