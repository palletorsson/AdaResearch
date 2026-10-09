from pathlib import Path
import difflib, html, json, re
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
MAPS = ["Trans_Introduction", "Trans_Rotation", "Trans_Body"]

def render(text, prefix):
    count = [0]
    def anchor(match):
        count[0] += 1
        return '<a id="' + prefix + '-encounter-' + str(count[0]) + '"></a>'
    text = re.sub(r"<!--\s*@[^>]*-->", anchor, text)
    text = re.sub(r"~~([^~\n]+)~~", r"<del>\1</del>", text)
    result = markdown.markdown(text, extensions=["extra", "sane_lists"])
    return result.replace('id="fn', 'id="' + prefix + '-fn').replace('href="#fn', 'href="#' + prefix + '-fn')

def figure(name, caption):
    return '<figure><a href="' + name + '.png"><img loading="lazy" src="' + name + '.png" alt="' + html.escape(caption, quote=True) + '"></a><figcaption>' + caption + '</figcaption></figure>'

css = re.search(r"<style>(.*?)</style>", (OUT.parent / "2026-09-23-primitives-pacing/index.html").read_text(encoding="utf-8"), re.S)[1]
css += "figure{margin:20px 0}figure img{width:100%;display:block;border-radius:3px}figcaption{font:14px/1.6 system-ui,sans-serif;margin-top:12px}.photos{display:grid;grid-template-columns:1fr 1fr;gap:24px}.decision{max-width:900px}.decision table{font:15px/1.6 system-ui,sans-serif;border-collapse:collapse}.decision td,.decision th{padding:14px;text-align:left;vertical-align:top;border-bottom:1px solid #d4ccbe}.decision th:first-child,.decision td:first-child{width:25%}.diff{font:13px/1.6 ui-monospace,monospace}.muted{color:#756a65}@media(max-width:700px){.photos{grid-template-columns:1fr}}"
parts = ['<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Transformation: let the encounter answer</title><style>' + css + '</style></head><body><main>']
parts += ['<div class="eyebrow">Ada Research / Transformation / 23 September 2026</div><h1>Let the encounter answer.</h1><div class="intro"><p>Claude identified a useful gap: the reader was told that reversing two turns could change the result, but the principal route offered no comparison. An existing workbench now supplies it. Marks let us follow a cube’s orientation; a bank control brings the receiving space into the experiment.</p><p>The sequence keeps its voice and its arc. Three short recaps are reduced, while the new encounter gives the writing something particular to follow.</p></div><p class="status">Applied to the current museum sources and three <strong>final.md</strong> files. Native checks: <strong>97/97 passed</strong>; images inspected. Headset experience remains to be tried. An already open hall needs reloading to pick up these changes.</p>']
parts += ['<nav><a href="#bank">Move the bank</a><a href="#turns">Reverse the turns</a><a href="#marks">Follow the mark</a><a href="#reading">Text comparisons</a><a href="#decisions">Decisions</a><a href="SUMMARY.md">Scope and evidence</a></nav>']
parts += ['<section id="bank"><h2>The destination gets a handle</h2><div class="intro"><p>MOVE THE BANK now stands beside the approach to the third crossing. The landing and the plank keep their earlier geometry. These pictures hold the plank at the same aligned pose while the bank moves one metre.</p></div><div class="photos">', figure('bank-at-crossing', 'Initial position: the aligned plank overlaps the landing.'), figure('bank-gap', 'Bank moved one metre: a gap opens while the plank stays in the same pose.'), '</div><details><summary>See the reachable control</summary>', figure('bank-control-close', 'The slider sits about 1.13 m above the floor; RESET returns the landing. Side aisles remain open.'), '</details></section>']
parts += ['<section id="turns"><h2>The same two turns, exchanged</h2><div class="intro"><p>The existing composition workbench is now a primary encounter beyond the combined array. It starts with X30° and Y45°, showing both orders and their intermediate forms. Move its slider to pair two to compare a rotation and a uniform enlargement.</p></div><div class="photos">', figure('order-comparison', 'Pair four: the blue and pink finned forms receive the same turns in opposite orders and end differently.'), figure('commuting-comparison', 'Pair two: rotation and uniform scale share a final form, despite their different intermediate states.'), '</div><p class="muted">The columns separate the display drawings. Both calculations use the same origin.</p></section>']
parts += ['<section id="marks"><h2>A shape returns. A mark remembers.</h2><div class="photos">', figure('array-mark-zero', 'The Y array begins with the mark in its first orientation.'), figure('array-mark-ninety', 'At ninety degrees the cube’s occupied outline returns, while the L points another way.'), '</div><div class="photos">', figure('marked-sweep', 'The same asymmetric mark follows the small cube on its spindle.'), figure('array-and-comparison', 'The restored workbench beside the array studies, in the actual museum.'), '</div></section>']
parts += ['<section id="reading"><h2>The text changes</h2><p>Compare the changed passages, or read each revised hall below. These are the canonical texts, not proposals waiting to be applied.</p></section>']
for name in MAPS:
    before = (OUT / (name + '.before.md')).read_text(encoding='utf-8')
    after = (OUT / (name + '.after.md')).read_text(encoding='utf-8')
    assert after == (ROOT/'commons/maps'/name/'final.md').read_text(encoding='utf-8'), name + ' snapshot is stale'
    old, new = before.split('\n\n'), after.split('\n\n')
    pairs=[]
    for i,(tag,a,b,c,d) in enumerate(difflib.SequenceMatcher(None,old,new,autojunk=False).get_opcodes()):
        if tag == 'equal': continue
        left = render('\n\n'.join(old[a:b]), name+'-old-'+str(i)) or '<p class="muted">New encounter.</p>'
        right = render('\n\n'.join(new[c:d]), name+'-new-'+str(i)) or '<p class="muted">Recap removed; the surrounding encounter continues.</p>'
        pairs.append('<div class="pair"><div><h4>Before</h4>'+left+'</div><div><h4>Now</h4>'+right+'</div></div>')
    parts += ['<section id="'+name+'"><h2>'+name.replace('_',' ')+'</h2><p><a href="/compose/sources?map='+name+'&amp;doc=final">Read and comment on final.md</a> · <a href="'+name+'.diff">Exact diff</a></p><details open><summary>Changed passages</summary>'+''.join(pairs)+'</details><details><summary>Read the whole revised hall</summary><article class="reading">'+render(after,name+'-reading')+'</article></details></section>']
parts += ['<section id="decisions" class="decision">'+render((OUT/'DECISIONS.md').read_text(encoding='utf-8'),'decisions')+'</section><footer><p><a href="claude-feedback.md">Original feedback</a> · <a href="Trans_Rotation-report.json">Rotation checks</a> · <a href="Trans_Introduction-report.json">Bank checks</a> · <a href="source-changes.diff">Source changes for this pass</a></p><p>Next: return to Translation’s journeys and operate its existing handles. Carry forward the distinction between varying a relation and merely watching a movement.</p></footer></main></body></html>']
(OUT/'index.html').write_text(''.join(parts),encoding='utf-8')
print(OUT/'index.html')
