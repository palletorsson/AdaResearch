"""Build the illustrated review only from a successful current Godot receipt."""
from pathlib import Path
import hashlib,html,json,re,shutil
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/research/possible-bodies';E=R/'doc/space/recursive-trees-2026-09-14';RUN=R/'ada_run/trees-review-2026-09-14';M='Fractal_RecursiveTrees'
def dump(p,d):p.write_bytes((json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode())
r=json.loads((RUN/'run.json').read_text())
assert r['exit']==0 and not r['failures'] and r['sources_unchanged'] and r['original_hand_unchanged']
assert all(hashlib.sha256((R/p).read_bytes()).hexdigest()==h for p,h in r['source_sha256'].items())
assets=[]
for n in ['entrance','standing-interface','binary-tree','wide-tree','three-forks','branch-strata','collection']:
 dest=O/f'trees-{n}.png';shutil.copyfile(RUN/M/f'{n}.png',dest);assets.append(dest.name)
for kind in ['final','technical','critical','tutorial']:
 dest=O/f'trees-{kind}.md'
 text=(R/f'commons/maps/{M}/{kind}.md').read_text()
 text=text.replace(f'../../../doc/space/recursive-trees-2026-09-14/before/commons/maps/{M}/{kind}.md',f'trees-previous-{kind}.md')
 dest.write_bytes(text.encode());assets.append(dest.name)
 previous=E/f'before/commons/maps/{M}/{kind}.md'
 if previous.exists():
  old=O/f'trees-previous-{kind}.md';shutil.copyfile(previous,old);assets.append(old.name)
dump(O/'trees-verification.json',r);assets.append('trees-verification.json')
css=re.search(r'<style>(.*?)</style>',(O/'recursion-encounter.html').read_text(),re.S).group(1)
book=markdown.markdown((R/f'commons/maps/{M}/final.md').read_text(),extensions=['fenced_code'])
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Where will the next branch go? · Ada Research</title><style>__CSS__</style></head><body><main>
<nav><a href="fractal-learning-arc.html#Fractal_RecursiveTrees">← The fractal walk</a><a href="/necklace/thread?map=Fractal_RecursiveTrees&role=primary">Two primary artifacts / book</a><a href="/museum-progress?sequence=fractals&room=Fractal_RecursiveTrees">Museum progress</a></nav>
<p class="eyebrow">ADA RESEARCH · RECURSIVE TREES · 14 SEPTEMBER 2026</p><h1>Where will the<br>next branch go?</h1><p class="lead">A trunk waits. Give it another generation, turn its descendants, or change what they inherit. Which change moves a body, and which changes its connections?</p>
<div class="facts"><div><strong>12</strong><span>existing placements retained</span></div><div><strong>2</strong><span>primary encounters and book passages</span></div><div><strong>31 → 121</strong><span>segments at four generations</span></div><div><strong>__CHECKS__</strong><span>rendered Godot checks</span></div></div>
<figure><img src="trees-entrance.png" alt="The museum approach with a growing tree and a red geometric tree on either side"><figcaption>Actual Godot capture. Two compact desks precede the retained historical enclosure. The first trunk waits for input.</figcaption></figure>
<section><p class="step">01 / RECURSIVE_TREE_2</p><h2>Inherit a length. Choose a direction.</h2><p>GROW adds a whole generation. ANGLE and LENGTH rebuild to the same generation, so their effects can be compared separately. FORKS switches between two and three descendants. RESET restores the trunk; RULE gives a short account of the operation after the visitor has tried it.</p>
<figure><img loading="lazy" src="trees-standing-interface.png" alt="Six compact controls below a small transparent screen, with connected branches visible behind it"><figcaption>Full-sized touch targets in a 3 × 2 arrangement. The same standing position reaches all six controls in the desktop input test. Headset reach remains to check.</figcaption></figure>
<div class="pair"><figure><img loading="lazy" src="trees-binary-tree.png" alt="Binary tree with a 35-degree turn and 0.70 length inheritance"><figcaption>31 segments: two descendants per fork, 35° turn, length × 0.70.</figcaption></figure><figure><img loading="lazy" src="trees-wide-tree.png" alt="The same number of segments spreading at 65 degrees with greater length inheritance"><figcaption>Still 31 segments. This recorded state follows separate changes to 65° and × 0.85.</figcaption></figure></div>
<figure><img loading="lazy" src="trees-three-forks.png" alt="A three-dimensional tree with three descendants per fork"><figcaption>Three descendants, the same four generations: 121 connected segments. Direction and length are held from the preceding state.</figcaption></figure>
<blockquote>A visible crossing is not yet a connection. A branch is not yet a support.</blockquote><p>Changing an edge’s direction changes its embedding. Giving each tip another descendant changes the branching graph. These meshes have no branch colliders: turning the shape into shelter would require another decision about what the player’s body can touch.</p></section>
<section><p class="step">02 / RECURSIVE_TREE</p><h2>The tree that has already spent its calls.</h2><p>Choose a fork before pressing STRATA. Colour separates the recursion levels. REACH draws accumulated bounds; ENDS adds handover and terminal marks. FORM restores the original colours. These controls reveal the same fixed-seed geometry without regrowing it.</p><figure><img loading="lazy" src="trees-branch-strata.png" alt="The geometric block tree coloured by recursion depth beside its transparent control desk"><figcaption>Seed 12345; three recursive branching levels after the trunk. This is a variable-branching construction, not a binary tree.</figcaption></figure></section>
<details><summary>Read the book passage</summary><article>__BOOK__</article><p><a href="trees-final.md">Manuscript</a> · <a href="trees-technical.md">Implementation</a> · <a href="trees-critical.md">Critical questions</a></p></details>
<section><h2>The collection keeps its detours.</h2><p>Both downward trees, both small subdivision cubes, the desk, living paper, mesh fractal, L-system example, sphere and Möbius specimen remain. The approach adds room for the main experiment; it preserves the old enclosure. The two downward trees now stand apart, and the Möbius world is reduced to a specimen that fits this hall.</p><figure><img loading="lazy" src="trees-collection.png" alt="The retained enclosure, downward branching sculptures and secondary collection"><figcaption>The enclosure was checked against two historical grid layouts before restaging. Earlier prose and map data are archived with the review.</figcaption></figure></section>
<section><h2>What was checked?</h2><p>__CHECKS__ checks passed in Godot 4.6 using the actual museum scene: twelve placements, both six-button desks through the desktop pointer, the 31/121 comparison, branch joints, one-time length inheritance, exact reset replay, bounded rebuilds, a second instance and the walking route around the enclosure.</p><p class="note">The test uses synthetic input through the project’s standalone DesktopPlayer rig inside the museum. It does not certify the native museum walker’s interaction lane. The duplicate native walker is parked outside the test room. Headset comfort, physical reach and Quest performance remain untested. These are actual engine captures; the user’s open session and saved museum hand were preserved.</p></section>
<section class="next"><h2>Next: what does removal leave?</h2><p>Cantor carries the generation into a new operation: decide which part of each interval remains. More pieces can coexist with less retained length.</p><a href="/necklace/thread?map=Fractal_CantorSet&role=primary">Continue to Fractal_CantorSet →</a></section>
<footer><a href="trees-verification.json">Runtime receipt</a> · <a href="fractal-learning-arc.html">Seven-hall learning arc</a> · <a href="recursion-encounter.html">Previous hall: Recursion</a></footer></main></body></html>'''.replace('__CSS__',css).replace('__CHECKS__',str(r['checks'])).replace('__BOOK__',book)
(O/'recursive-trees.html').write_bytes(page.encode());assets.append('recursive-trees.html')
assets+=['fractal-learning-arc.html','fractal-learning-arc.json','fractal-learning-arc.md']
for n,src in [('receipt.json',RUN/'run.json'),('report.json',RUN/M/'probe_ca_edge_live.json'),('engine.log',RUN/M/'engine.log')]:shutil.copyfile(src,E/n)
targets=['possible-bodies/'+a for a in assets]
dump(E/'publish-targets.json',targets);dump(E/'publish-hashes.json',{a:hashlib.sha256((R/'doc/research'/a).read_bytes()).hexdigest() for a in targets})
print(f'Built tree review: {len(targets)} files; {r["checks"]} checks.')
