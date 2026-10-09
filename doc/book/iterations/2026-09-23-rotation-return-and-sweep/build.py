from pathlib import Path
import html,re,difflib
import markdown
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
def render(s,prefix):
    s=re.sub(r'<!--\s*@[^>]*-->','',s)
    return markdown.markdown(s,extensions=['extra','sane_lists']).replace('id="fn','id="'+prefix+'-fn').replace('href="#fn','href="#'+prefix+'-fn')
def photo(name,caption):
    return '<figure><a href="'+name+'.png"><img src="'+name+'.png" alt="'+html.escape(caption,quote=True)+'"></a><figcaption>'+caption+'</figcaption></figure>'
before=(OUT/'Trans_Rotation.before.md').read_text(encoding='utf-8')
after=(OUT/'Trans_Rotation.after.md').read_text(encoding='utf-8')
assert after==(ROOT/'commons/maps/Trans_Rotation/final.md').read_text(encoding='utf-8')
a,b=before.split('\n\n'),after.split('\n\n');pairs=[]
for i,(tag,x,y,u,v) in enumerate(difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes()):
    if tag=='equal':continue
    left=render('\n\n'.join(a[x:y]),'old-'+str(i)) or '<p>New illustration.</p>'
    right=render('\n\n'.join(b[u:v]),'new-'+str(i)) or '<p>Recap removed.</p>'
    pairs.append('<div class="pair"><div><h4>Before</h4>'+left+'</div><div><h4>Now</h4>'+right+'</div></div>')
css=re.search(r'<style>(.*?)</style>',(OUT.parent/'2026-09-23-transformation-encounters/index.html').read_text(encoding='utf-8'),re.S)[1]
css+=' .pair img{max-width:100%} .reading{margin-top:25px} figure img{height:auto} .note{max-width:760px}'
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Rotation — what returned?</title><style>'+css+'</style></head><body><main>'
page+='''<div class="eyebrow">Ada Research / Trans Rotation / 23 September 2026</div><h1>What returned?</h1><div class="intro"><p>After a quarter-turn, the cube fits the space it occupied before. The marked face has gone around the corner.</p><p>What returned depends on what you were following.</p></div><p class="status">Applied to the canonical <strong>Trans_Rotation/final.md</strong>. Two illustrations come from the existing working museum study. The hall, artifacts and controls are unchanged.</p><nav><a href="#encounter">Working illustrations</a><a href="#comparison">Text differences</a><a href="#reading">Read the hall</a><a href="SUMMARY.md">Scope and evidence</a><a href="/compose/sources?map=Trans_Rotation&amp;doc=final">Comment on final.md</a></nav>'''
page+='<section id="encounter"><h2>A returning outline, a moved mark</h2>'+photo('marked-return','The same cube, frozen at zero and ninety degrees. One camera; the L moves from the left-hand face to the right.')+'<h2>The room a turn requires</h2>'+photo('spaces-of-a-turn','The cube and triangular profile each paused at forty-five degrees. Their cyan contours describe the outer boundaries of a whole turn. The contours add no solid wall.')+'<p class="note">Both figures also appear in the chapter. The museum provides SHAPE, PLAY/PAUSE and BOUNDARY. These book images select moments from that working study; they do not show optical motion blur.</p></section>'
page+='''<section id="comparison"><h2>More room to notice</h2><p>The crossings, four array bands, order comparison, tunnel and turning stacks keep their places in the chapter. A few details about controls and implementation move out of the reader’s way. All six code excerpts remain. The spindle passage follows the mark, then the corner, then the space left empty when the body pauses.</p><details open><summary>Original and revised passages</summary>'''+''.join(pairs)+'''</details><p><a href="Trans_Rotation.diff">Exact manuscript diff</a> · <a href="source-changes.diff">All prose and supporting-record changes</a></p></section>'''
page+='<section id="reading"><h2>Trans Rotation</h2><article class="reading">'+render(after,'reading')+'</article></section>'
page+='''<footer><p>Nineteen focused checks pass in the isolated production museum. All four native captures were inspected. The probe exercised pointer buttons and selected frozen poses; headset experience and learner understanding remain untested. The source geometry and map have not changed.</p><p>Next: Scale, where the same shape returns at a size that changes what your body can do.</p><p><a href="report.json">Capture and interaction checks</a> · <a href="verification.json">Publication checks</a> · <a href="SUMMARY.md">Scope and evidence</a></p></footer></main></body></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
print(OUT/'index.html')
