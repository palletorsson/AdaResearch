"""Render the Motion teaching pilot from current canonical texts and saved checks."""
from pathlib import Path
import json, html, re, shutil, hashlib
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-motion-build-and-investigate'
MAP=ROOT/'commons/maps/VFM_03_Motion'
CSS='''body{margin:0;background:#eae7df;color:#202026;font:18px/1.65 Georgia,serif}main{max-width:1480px;padding:34px;margin:auto}h1{font-size:2.7rem;line-height:1.12}h2{font-size:1.55rem;line-height:1.25;margin-top:1.7em}nav,.meta,table{font:14px/1.55 system-ui}nav{display:flex;flex-wrap:wrap;gap:18px}a{color:#733a56}article,.panel{background:#fffdf8;padding:28px;margin:22px 0}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px;align-items:start}.pair article{min-width:0}pre{background:#20232a;color:#f6f0e8;padding:18px;overflow:auto;font:13px/1.55 Consolas,monospace}code{font-family:Consolas,monospace}blockquote{border-left:3px solid #ad8194;margin-left:0;padding-left:20px}.badge{background:#e4d8df;padding:15px}img{width:100%;height:auto}table{border-collapse:collapse;width:100%}th,td{text-align:left;vertical-align:top;border-bottom:1px solid #ccc;padding:12px}summary{cursor:pointer} @media(max-width:1000px){.pair{grid-template-columns:1fr}main{padding:16px}} @media print{nav{display:none}pre{white-space:pre-wrap}.pair{display:block}}'''

def md(text, base=MAP):
    rendered=markdown.markdown(text,extensions=['fenced_code','tables','footnotes'])
    def link(m):
        u=html.unescape(m.group(1))
        if u=='final.md':return 'href="final.html"'
        if 'forces-shared-code.md' in u:return 'href="shared.html"'
        if not u.startswith(('http:','https:','file:','#','/')):
            p=(base/u).resolve()
            if p.exists():return 'href="'+p.as_uri()+'"'
        return m.group(0)
    return re.sub(r'href="([^"]+)"',link,rendered)

def page(title,body):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>'+html.escape(title)+'</title><style>'+CSS+'</style><main><nav><a href="index.html">Review</a><a href="parallel.html">Tutorial / reflection</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="before.html">Reflection before / after</a><a href="shared.html">Shared code</a></nav>'+body+'</main></html>'

def main():
    tutorial=(MAP/'tutorial.md').read_text(encoding='utf8')
    reflection=(MAP/'final.md').read_text(encoding='utf8')
    before=(OUT/'before/commons/maps/VFM_03_Motion/final.md').read_text(encoding='utf8')
    for name,text in [('tutorial',tutorial),('final',reflection)]:
        (OUT/(name+'.md')).write_text(text,encoding='utf8')
        (OUT/(name+'.html')).write_text(page(name,md(text)),encoding='utf8')
    pair='<div class="pair"><article><p class="meta">LEFT · BUILD AND INVESTIGATE</p>'+md(tutorial)+'</article><article><p class="meta">RIGHT · REFLECTION</p>'+md(reflection)+'</article></div>'
    (OUT/'parallel.html').write_text(page('Motion — build and investigate',pair),encoding='utf8')
    (OUT/'before.html').write_text(page('Motion — reflection before and after','<h1>Keep the argument; meet the current spheres</h1><p>The earlier cube, console and ramp account is preserved here. The new text follows the current mass comparison and its bounded trail.</p><div class="pair"><article><p class="meta">BEFORE · ARCHIVED ENCOUNTER</p>'+md(before)+'</article><article><p class="meta">AFTER · CURRENT MOTION HALL</p>'+md(reflection)+'</article></div>'),encoding='utf8')
    common=ROOT/'doc/book/course/forces-shared-code.md'
    (OUT/'shared.html').write_text(page('Motion — shared code',md(common.read_text(encoding='utf8'),common.parent)),encoding='utf8')
    runtime=json.loads((OUT/'motion_learning_pilot.json').read_text(encoding='utf8'))
    museum=json.loads((OUT/'museum/report.json').read_text(encoding='utf8'))
    count=len(runtime['checks'])+len(museum['checks'])
    results=all(c.get('passed',False) for c in runtime['checks']) and museum['passed']
    learner=(OUT/'ghost-attempt/review.md').read_text(encoding='utf8')
    follow=(OUT/'ghost-attempt/followup-review.md')
    verdict='<p class="badge">'+str(count)+' native checks '+('passed' if results else 'have failures')+'. Printed-code reconstruction, an independent AI-authored variation, current mass artifact and placement in the actual museum. Physical headset comfort and human comprehension remain untested.</p>'
    audit='''<table><thead><tr><th>Carried from earlier halls</th><th>New in Motion</th><th>Student responsibility</th></tr></thead><tbody>
    <tr><td>Point class and instances: Lines. Pickup and coordinates: Coordinates.</td><td>A physical point receives a continuing force.</td><td>Create the instances and choose their masses.</td></tr>
    <tr><td>Arrays, indices, loops and if: Trace. Timed change: Transformation.</td><td>Physics updates and force × duration ÷ mass. Writing an existing numeric array entry is explained here.</td><td>Build two independent push clocks.</td></tr>
    <tr><td>Displacement: Lines. Initial velocity and timed position: Launch.</td><td>Velocity persists after a push; equal final speeds need not mean equal travel.</td><td>Predict, measure both quantities, then choose another mass/duration pair.</td></tr></tbody></table>'''
    body='<h1>When the push ends</h1><p>Motion pilot · 8 October 2026 · one tutorial and its reflective companion.</p><p>The tested example remains complete. The lesson now names its inherited skills, teaches the new physics callback, and asks the student to construct another comparison. The reflection follows the three current spheres and keeps the passages about a command’s continuing consequence and incomplete history.</p>'+verdict
    body+='<p><a href="parallel.html">Read tutorial left / reflection right</a> · <a href="before.html">Compare the reflective revision</a></p>'+audit
    body+='<article><h2>The actual museum</h2><img src="museum/primary.png" alt="The three weighted black spheres and nearby push controls in the Motion hall"><p class="meta">Current mass artifact, rendered inside Endless Museum during this check.</p><img src="museum/student.png" alt="The independently reconstructed two-sphere comparison running in the right-hand museum bay"><p class="meta">Temporary student study at hall-local (23, 0, 18). It is not an additional permanent museum artifact.</p></article>'
    body+='<article><h2>What the ghost student exposed</h2><p>A separate AI received only the lesson, supplied helpers and declared earlier readings. Its first construction ran successfully, but it identified missing explanations for indexed assignment, the mass–duration relationship and distance measurement. Those explanations were added, the student revised its readout, and the submitted code was checked again.</p><p>This is evidence of one AI reconstruction attempt. It does not show that a human learner already understands the lesson.</p><details><summary>First student review</summary>'+md(learner,OUT/'ghost-attempt')+'</details>'
    if follow.exists():body+='<details><summary>Review after the clarification</summary>'+md(follow.read_text(encoding='utf8'),follow.parent)+'</details>'
    body+='<details><summary>Student predictions, written before execution</summary>'+md((OUT/'ghost-attempt/predictions.md').read_text(encoding='utf8'),OUT/'ghost-attempt')+'</details>'
    body+='<details><summary>Independent construction — inspect after attempting the exercise</summary><pre><code>'+html.escape((OUT/'ghost-attempt/comparison.gd').read_text(encoding='utf8'))+'</code></pre></details></article>'
    body+='<p><a href="motion_learning_pilot.json">Native reconstruction and artifact assertions</a> · <a href="museum/report.json">Actual museum checks</a> · <a href="student-packet/README.md">Student reading packet</a> · <a href="prerequisite-audit.json">Earlier knowledge audit</a> · <a href="verification.json">Execution and source record</a> · <a href="publication-checks.json">Publication checks</a> · <a href="SUMMARY.md">Compact instruction for the next pass</a></p>'
    (OUT/'index.html').write_text(page('Motion — build and investigate',body),encoding='utf8')
    files=[MAP/'tutorial.md',MAP/'final.md',ROOT/'doc/book/course/forces-lesson-prose.json',ROOT/'tools/probes/motion_learning_pilot.gd',ROOT/'tools/probes/motion_learning_museum.gd']+list((OUT/'ghost-attempt').glob('*.gd'))
    evidence={'passed':results,'native_checks':count,'runtime_checks':len(runtime['checks']),'museum_checks':len(museum['checks']),'scope':runtime['scope'],'sources':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files},'images':{p.relative_to(OUT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in (OUT/'museum').glob('*.png')}}
    (OUT/'verification.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print('Published Motion pilot:',count,'native checks;',results)

if __name__=='__main__':main()
