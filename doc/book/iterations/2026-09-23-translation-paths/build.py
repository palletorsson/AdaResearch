from pathlib import Path
import html,re,difflib
import markdown
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
def render(s,prefix):
    s=re.sub(r"<!--\s*@[^>]*-->","",s)
    s=re.sub(r"~~([^~\n]+)~~",r"<del>\1</del>",s)
    result=markdown.markdown(s,extensions=["extra","sane_lists"])
    return result.replace('id="fn','id="'+prefix+'-fn').replace('href="#fn','href="#'+prefix+'-fn')
def photo(name,caption):
    return '<figure><a href="'+name+'.png"><img src="'+name+'.png" alt="'+html.escape(caption,quote=True)+'"></a><figcaption>'+caption+'</figcaption></figure>'
before=(OUT/'Trans_Translation.before.md').read_text(encoding='utf-8')
after=(OUT/'Trans_Translation.after.md').read_text(encoding='utf-8')
assert after==(ROOT/'commons/maps/Trans_Translation/final.md').read_text(encoding='utf-8')
a,b=before.split('\n\n'),after.split('\n\n');pairs=[]
for i,(tag,x,y,u,v) in enumerate(difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes()):
    if tag=='equal':continue
    left=render('\n\n'.join(a[x:y]),'old-'+str(i)) or '<p>New passage.</p>'
    right=render('\n\n'.join(b[u:v]),'new-'+str(i)) or '<p>Recap removed.</p>'
    pairs.append('<div class="pair"><div><h4>Before</h4>'+left+'</div><div><h4>Now</h4>'+right+'</div></div>')
css=re.search(r'<style>(.*?)</style>',(OUT.parent/'2026-09-23-transformation-encounters/index.html').read_text(encoding='utf-8'),re.S)[1]
css+=' .pair img{max-width:100%} .reading{margin-top:25px} .hero{margin-top:30px}'
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Translation — which movement leaves the line?</title><style>'+css+'</style></head><body><main>'
page+='<div class="eyebrow">Ada Research / Trans Translation / 23 September 2026</div><h1>Which movement leaves the line?</h1><div class="intro"><p>You offer the handle a diagonal. Its record rises vertically. The line follows the part of your movement that the mechanism allowed.</p><p>A small addition to two existing door studies makes the last encounter in Translation a return to Point_Trace. The free mechanism admits more than one route; the destination alone cannot tell us which one was taken.</p></div><p class="status">Applied to the museum and canonical <strong>Trans_Translation/final.md</strong>. The seven rides and thirteen pickups retain their existing geometry and behaviour. The figure below also appears in the book.</p><nav><a href="#encounter">Working illustration</a><a href="#comparison">Text differences</a><a href="#reading">Read the hall</a><a href="SUMMARY.md">Scope and evidence</a><a href="/compose/sources?map=Trans_Translation&amp;doc=final">Comment on final.md</a></nav>'
page+='<section id="encounter"><h2>One destination, several paths</h2>'+photo('translation-paths','Three separate supplied gestures, rendered by the live museum artifacts: a guided bend, a diagonal, and a curve. The pale trails record accepted handle positions.')+'<details><summary>The first gesture and the actual terrace</summary><div class="photos">'+photo('lift_lateral-first-gesture','The guided mechanism retains the upward part of the proposed diagonal.')+photo('free-first-gesture','The other mechanism retains both components within its bounds.')+'</div>'+photo('translation-exit-terrace','The existing two studies on the final terrace. No extra controller panel.')+'</details></section>'
page+='<section id="comparison"><h2>Small changes to the writing</h2><p>The chapter keeps its course and code. The pickup passage follows a return to an empty place; the ending follows a line back to the mechanism that selected its positions.</p><details open><summary>Original and revised passages</summary>'+''.join(pairs)+'</details><p><a href="Trans_Translation.diff">Exact manuscript diff</a> · <a href="source-changes.diff">Source and documentation changes</a></p></section>'
page+='<section id="reading"><h2>Trans Translation</h2><article class="reading">'+render(after,'reading')+'</article></section>'
page+='<footer><p>53 focused checks pass in an isolated production museum; native images inspected. Tests supplied knob movement and pickup/drop signals. They do not establish headset feel or learner understanding. Trails retain a bounded recent history and sit slightly forward of their sampled positions so the panels do not hide them.</p><p><a href="report.json">Runtime checks</a> · <a href="verification.json">Content and HTTP checks</a> · <a href="SUMMARY.md">Full scope</a>. Reload an already open hall to see the change.</p></footer></main></body></html>'
(OUT/'index.html').write_text(page,encoding='utf-8')
print(OUT/'index.html')
