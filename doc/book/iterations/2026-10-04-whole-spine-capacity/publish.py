"""Publish a source-linked, readable report; no museum or manuscript mutation."""
from pathlib import Path
import hashlib
import html
import json
import re
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
URL = 'http://localhost:3003/book-review/'
e = html.escape
inv = json.loads((OUT / 'inventory.json').read_text(encoding='utf-8'))
sequences = inv['sequences'][1:]

def source_url(path):
    source = ROOT / path
    target = OUT / 'sources' / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(source.read_bytes())
    return URL + target.relative_to(ROOT).as_posix()

# Coordinator's prioritisation. These are editorial proposals, never readiness scores.
focus = {
 'transformation': ('Preserve', 'Clarify supplied motion versus a learner-made update.'),
 'array_tutorial': ('Teaching', 'Write the missing Array lesson; reconcile Disco with its current clocks.'),
 'color': ('Preserve', 'Carry one editable colour mapping beyond the selected example.'),
 'tiling': ('Teaching', 'Select the motif/receiver lesson and supply the missing ribbon companions.'),
 'change': ('Teaching', 'Make the two-sample rate and retained-velocity boundary explicit.'),
 'forces': ('Pacing', 'Choose the small construction spine through the many motion comparisons.'),
 'formfinding': ('Correctness', 'Repair Forge: an authored target, a score and physical settling differ.'),
 'wavefunctions': ('Correctness', 'Align the propagation tutorial with the selected oscillator model.'),
 'randomness': ('Correctness', 'Repair the XYZ/clock-entropy tutorial; preserve the mature inquiry.'),
 'noise': ('Handoff', 'Name the reusable field operation; respect Lab_Path’s optional coda.'),
 'shaders': ('Teaching', 'Establish the missing small shader entry and the boundary with stored state.'),
 'cellularautomata': ('Correctness', 'Teach present/next state; reconcile Wireworld versus the actual Rule 90 encounter.'),
 'fractals': ('Teaching', 'Keep one finite recursive construction usable before widening the vocabulary.'),
 'lsystems': ('Handoff', 'Make sentence/interpreter reuse explicit; verify the Shape Grammars room.'),
 'proceduralgeneration': ('Handoff', 'Carry one recipe through scoring or connectivity without concealing prerequisites.'),
 'softbodies': ('Teaching', 'Retain one constraint experiment; keep the solver explicitly supplied.'),
 'isosurfaces': ('Handoff', 'Return to one field recipe in another representation; preserve the interior walk.'),
 'boolean_surfaces': ('Preserve', 'Add one matched operand study and repair the small transition contradiction.'),
 'swarmintelligence': ('Teaching', 'Use one event account to distinguish population change from replenishment.'),
 'machinelearning': ('Encounter', 'Make one tiny learner inspectable, restartable and correctly teachable.'),
 'graphtheory': ('Correctness', 'Replace false algorithm-completion claims with one explicit reversible allocation.'),
 'foundationscrisis': ('Correctness', 'Repair the Gödel tutorial before it undoes the main text’s distinction.'),
 'qfeplaboratory': ('Teaching', 'Give one receiver mapping a small writable construction and retained response.'),
 'postfoundationscrisis': ('Preserve', 'Bring old tutorials up to the existing assembly/record/return encounter.'),
}

def render(text):
    result = markdown.markdown(text, extensions=['tables', 'fenced_code', 'sane_lists'])
    # Turn source mentions into links. The resolved repository path is always explicit.
    def code_link(match):
        value = html.unescape(match.group(1))
        path = value if value.startswith(('commons/', 'doc/book/', 'algorithms/')) else 'commons/maps/' + value
        if '\n' not in value and (ROOT / path).is_file():
            return '<a href="' + e(source_url(path), quote=True) + '"><code>' + e(value) + '</code></a>'
        return match.group(0)
    return re.sub(r'<code>([^<]+)</code>', code_link, result)

reviews = []
sections = []
for part in ['early', 'middle', 'late']:
    text = (OUT / f'review-{part}.md').read_text(encoding='utf-8')
    reviews.append(text)
    matches = list(re.finditer(r'^## (.+)$', text, re.M))
    assert len(matches) >= 8, (part, len(matches))
    for ix, match in enumerate(matches[:8]):
        stop = matches[ix + 1].start() if ix + 1 < len(matches) else len(text)
        sections.append((match.group(1), text[match.end():stop].strip()))
assert len(sections) == len(sequences) == 24

overview = (OUT / 'OVERVIEW.md').read_text(encoding='utf-8')
matrix = ['## Sequence priorities', '', '| Sequence | First attention | Proposed next move |', '| --- | --- | --- |']
cards, nav = [], []
for seq, (title, body) in zip(sequences, sections):
    key = seq['sequence']
    tag, move = focus[key]
    name = seq['title']
    matrix.append(f'| {name} | {tag} | {move} |')
    n = len(seq['maps'])
    nt = sum(m['files']['tutorial.md']['exists'] for m in seq['maps'])
    source_links = ''.join('<a href="' + e(source_url(m['files']['final.md']['path'])) + '">' + e(m['map'].replace('_', ' ')) + '</a>' for m in seq['maps'])
    cards.append(f'''<details class="sequence" id="{key}" data-focus="{tag.lower()}" data-search="{e((key+' '+name+' '+title+' '+body).lower(), quote=True)}">
<summary><span class="number">{seq['order']:02}</span><span><strong>{e(title)}</strong><small>{n} halls · {nt}/{n} tutorial files · {e(move)}</small></span><span class="tag">{e(tag)}</span></summary>
<article>{render(body)}<div class="sources"><b>Main texts captured for this report · 4 October 2026</b>{source_links}</div><p><a href="http://localhost:3003/project-memory?scope=sequence%3A{key}&amp;outline=sequence%3A{key}&amp;detail=0">Open this sequence in Project Memory →</a></p></article></details>''')
    nav.append(f'<a href="#{key}">{e(key.replace("_", " "))}</a>')

priority_text = '''## Where I would work next

1. **Repair contradictions in the teaching material first.** Gödel, Matching, Forge, the rotation/randomness and CA companions contain stronger problems than wording. These need a bounded, correct lesson or an honest declaration of supplied machinery.
2. **Secure the early reusable tools.** Array is a major dependency without its own tutorial. Finish one small addressed construction, then decide which later palette, motif and field operations deliberately reuse it. Do this one storyboard/lesson at a time.
3. **Make the Shader → CA step teachable.** The manuscript has a valuable distinction between repeatedly evaluating a surface and updating retained state. Missing shader lessons and stale CA companions weaken its usable counterpart.
4. **Strengthen one Machine Learning encounter.** A tiny restartable learner, a visible update and a case it has not trained on will do more for agency than a broader list of model names.
5. **Check the Shape Grammars route.** Resolve its saved-plan omission against the actual museum loader; Procedural Generation explicitly recalls its forms. Lab_Path is an optional coda, so its omission need not be a defect. Neither omission alone establishes runtime unreachability.
6. **Preserve and reuse the strongest returns.** Trace → Grid and Assembly → the final returned body show what cumulative work can feel like. Build a few intermediate returns deliberately; do not turn every hall into mandatory file transport.

These are proposed priorities, not changes to the authored sequence or automatic permission to rewrite all its lessons.
'''

full_report = overview + '\n\n' + priority_text + '\n\n' + '\n'.join(matrix) + '\n\n' + '\n\n'.join(reviews)
(OUT / 'REPORT.md').write_text(full_report, encoding='utf-8')

capacity = [
 ('Receive and distinguish', 'Primitives', 'Position, appearance, collision and record can be considered separately.'),
 ('Compose a rule', 'Transformation → Tiling', 'Change a relation, give copies addresses, map attributes and vary a source.'),
 ('Keep a consequence', 'Change → Waves', 'Measure a change, retain motion, compare criteria and distinguish kinds of recurrence.'),
 ('Control uncertainty', 'Randomness → Shaders', 'Retain a procedure, sample a field and say what a surface evaluation receives.'),
 ('Give rules memory and structure', 'CA → Procedural Generation', 'Update a state, stop a recursion, interpret a sentence and judge a generated result.'),
 ('Make relations inhabitable', 'Soft Bodies → Boolean', 'Change constraints, construct boundaries and test an opening at the scale of a body.'),
 ('Locate learning and coordination', 'Swarm → Graph Theory', 'Find where information is kept, what an update changes and which connections matter.'),
 ('Question and revise', 'Foundations → Post-crisis', 'Separate a check from a claim, expose a model’s choices and encounter a retained revision.'),
]
chain = ''.join(f'<li><span>{i:02}</span><div><strong>{e(t)}</strong><small>{e(where)}</small><p>{e(what)}</p></div></li>' for i,(t,where,what) in enumerate(capacity,1))

page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ada — Does the spine carry us?</title>
<style>
:root{--ink:#28262b;--paper:#f5f2ec;--muted:#68646a;--line:#d7d1c9;--accent:#903958}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.65 system-ui,sans-serif}main{max-width:1130px;margin:auto;padding:48px 28px 90px}a{color:var(--accent);text-underline-offset:3px}h1{font:clamp(38px,6vw,68px)/1.1 Georgia,serif;max-width:850px;margin:16px 0 28px}h2{font:30px/1.2 Georgia,serif;margin-top:46px}h3{font-size:20px}p{max-width:83ch}header .kicker{letter-spacing:.12em;text-transform:uppercase;font-size:12px;color:var(--muted)}header .lede{font-size:22px;max-width:760px}.stats{display:flex;gap:28px;padding:24px 0;border-block:1px solid var(--line);flex-wrap:wrap}.stats b{font-size:29px;display:block}.stats small{color:var(--muted)}.scope{font-size:14px;color:var(--muted)}.chain{list-style:none;padding:0;display:grid;grid-template-columns:1fr 1fr;gap:18px}.chain li{display:flex;gap:16px;padding:22px;border:1px solid var(--line);background:#fcfaf7}.chain li>span{color:var(--accent);font:26px Georgia,serif}.chain strong,.chain small{display:block}.chain small{color:var(--muted)}.chain p{margin:10px 0 0;font-size:15px}.controls{display:flex;gap:12px;flex-wrap:wrap;align-items:center;margin:24px 0}input,select,button{font:inherit;padding:10px 13px;border:1px solid #bcb4ad;border-radius:4px;background:#fff;color:var(--ink)}input{flex:1;min-width:210px}button{cursor:pointer}nav{display:flex;gap:7px 15px;flex-wrap:wrap;font-size:13px;margin-bottom:25px}nav a{white-space:nowrap}.sequence{border-top:1px solid var(--line)}.sequence:last-child{border-bottom:1px solid var(--line)}summary{cursor:pointer;display:flex;gap:20px;align-items:flex-start;padding:23px 0;list-style:none}summary::before{content:'+';color:var(--accent);font-size:23px}details[open]>summary::before{content:'−'}summary strong{font-size:20px;line-height:1.4;display:block}summary small{display:block;color:var(--muted);font-size:14px;max-width:78ch;margin-top:6px}.number{font:25px Georgia,serif;color:var(--muted)}.tag{margin-left:auto;font-size:11px;text-transform:uppercase;letter-spacing:.05em;border:1px solid var(--line);padding:4px 9px;white-space:nowrap}article{padding:0 22px 26px 68px}article p{font-size:16px}.sources{display:flex;gap:8px 15px;flex-wrap:wrap;font-size:13px;border-top:1px solid var(--line);padding-top:20px}.sources b{width:100%}table{border-collapse:collapse;display:block;overflow:auto;font-size:14px}th,td{text-align:left;vertical-align:top;border-bottom:1px solid var(--line);padding:12px;min-width:145px}th{background:#e9e3db}code{font-size:.87em;background:#eae5df;padding:1px 4px;overflow-wrap:anywhere}pre{overflow:auto;background:#eae5df;padding:15px}.evidence{padding:20px;background:#eae5df;font-size:14px}details.evidence>summary{padding:0}#count{font-size:14px;color:var(--muted)}.overview{max-width:100%}.overview>h1{display:none}footer{font-size:13px;border-top:1px solid var(--line);padding-top:20px;margin-top:50px}button:focus-visible,a:focus-visible,summary:focus-visible{outline:3px solid #a75876;outline-offset:4px}[hidden]{display:none!important}
@media(max-width:720px){main{padding:25px 18px}.chain{grid-template-columns:1fr}summary{gap:10px;flex-wrap:wrap}.tag{margin-left:37px}article{padding:0 8px 20px 30px}.number{display:none}}
@media print{body{background:white;font-size:11pt}main{max-width:none;padding:0}.controls,nav,button{display:none}.chain{grid-template-columns:1fr 1fr}a{color:inherit}article{padding-left:0}summary{break-after:avoid}.sequence{break-inside:auto}h2{break-after:avoid}.evidence{background:white}}
</style></head><body><main>
<header><div class="kicker">Ada / Whole-spine reading / 4 October 2026</div><h1>Does the spine carry us?</h1><p class="lede">The museum’s questions accumulate. The next work is to make its teaching just as dependable—and keep the learner’s growing freedom visible.</p>
<div class="stats"><div><b>24</b><small>sequences reviewed after Primitives</small></div><div><b>192</b><small>current main texts read by the review team</small></div><div><b>3</b><small>capacities: notice, make, question</small></div></div>
<p class="scope">Editorial review + selected tutorial/source inspection. No new runtime or learner testing. Proposed priorities; no manuscript or museum edits.</p><p><a href="#sequences">Sequence-by-sequence findings</a> · <a href="REPORT.md">Full Markdown report</a> · <a href="http://localhost:3003/project-memory">Project Memory</a></p></header>
<section><h2>The capacity we are trying to build</h2><p>This is the intended progression supported to different degrees by the current writing and teaching. It is not a certificate of student mastery.</p><ol class="chain">CHAIN</ol></section>
<section class="overview">OVERVIEW</section>
<section>PRIORITIES</section>
<section id="sequences"><h2>Where each sequence stands</h2><p>“Preserve” means protect the main achievement and make the named local improvement. The other labels identify the first kind of attention needed, not a score for artistic quality.</p>
<div class="controls"><input id="search" type="search" aria-label="Search sequence findings" placeholder="Find a sequence, hall or concept…"><select id="focus" aria-label="Filter by first attention"><option value="all">All kinds of attention</option><option value="correctness">Correctness</option><option value="teaching">Teaching</option><option value="handoff">Handoff</option><option value="encounter">Encounter</option><option value="pacing">Pacing</option><option value="preserve">Preserve</option></select><button id="expand">Expand shown</button><button id="collapse">Close all</button><button id="print">Print report</button></div><p id="count" role="status">24 sequences</p><nav aria-label="Sequences">NAV</nav>CARDS</section>
<details class="evidence"><summary>What was checked, and what remains unknown</summary><p>All 192 main texts after Primitives and their storyboards were reviewed in three scopes. Tutorials were selected for close reading; not every code block was audited. The inventory counts files across all 207 book halls, including Primitives. It does not infer quality from file presence. Two matching saved plans were compared with canonical sequence membership. Runtime fallbacks and VR passage were not exercised.</p><p><a href="review-early.md">Early review</a> · <a href="review-middle.md">Middle review</a> · <a href="review-late.md">Late review</a> · <a href="inventory.json">Source hashes and inventory</a> · <a href="route-check.json">Saved-plan comparison</a></p><p>Detailed coverage: <a href="review-early.json">Early sources</a> · <a href="review-middle.json">Middle sources</a> · <a href="review-late.json">Late sources</a>.</p></details>
<footer>The museum, tutorial and reflective text are overlapping sets. A room may matter without teaching new syntax. Source accuracy, teaching usefulness and artistic force need separate judgments.</footer>
</main><script>
const cards=[...document.querySelectorAll('.sequence')], search=document.querySelector('#search'), focus=document.querySelector('#focus');
function filter(){const q=search.value.trim().toLowerCase();for(const c of cards)c.hidden=!(c.dataset.search.includes(q)&&(focus.value==='all'||c.dataset.focus===focus.value));document.querySelector('#count').textContent=cards.filter(c=>!c.hidden).length+' of 24 sequences';}
search.addEventListener('input',filter);focus.addEventListener('change',filter);document.querySelector('#expand').onclick=()=>cards.filter(c=>!c.hidden).forEach(c=>c.open=true);document.querySelector('#collapse').onclick=()=>cards.forEach(c=>c.open=false);document.querySelector('#print').onclick=()=>{search.value='';focus.value='all';filter();cards.forEach(c=>c.open=true);window.print();};
function reveal(){const id=decodeURIComponent(location.hash.slice(1)),target=document.getElementById(id);if(target?.classList.contains('sequence')){search.value='';focus.value='all';filter();target.open=true;target.scrollIntoView({block:'start'});}}
window.addEventListener('hashchange',reveal);reveal();
</script></body></html>'''
for token, value in [('CHAIN', chain), ('OVERVIEW', render(overview)), ('PRIORITIES', render(priority_text)), ('NAV', ''.join(nav)), ('CARDS', ''.join(cards))]:
    page = page.replace(token, value)
# The book-review server deliberately disables scripts. Use native disclosure and
# CSS filters instead of changing its security policy for this document.
page = re.sub(r'<script>.*?</script>', '', page, flags=re.S)
native_controls = '<fieldset class="controls"><legend>First kind of attention</legend>'
for kind in ['all', 'correctness', 'teaching', 'handoff', 'encounter', 'pacing', 'preserve']:
    checked = ' checked' if kind == 'all' else ''
    native_controls += f'<label><input type="radio" name="attention" id="filter-{kind}"{checked}> {kind.title()}</label>'
native_controls += '</fieldset><p class="scope">24 sequence reviews. Open a heading to read it. Use your browser’s Find command to search, or open the <a href="print.html">continuous / print view</a>.</p>'
page = re.sub(r'<div class="controls">.*?<p id="count".*?</p>', native_controls, page, flags=re.S)
native_css = '.controls{border:0;padding:0}.controls label{font-size:14px;cursor:pointer}.controls input{min-width:0;padding:0;accent-color:var(--accent)}.controls legend{font-size:14px;color:var(--muted);margin-bottom:8px}'
for kind in ['correctness', 'teaching', 'handoff', 'encounter', 'pacing', 'preserve']:
    native_css += f'#sequences:has(#filter-{kind}:checked) .sequence:not([data-focus="{kind}"]){{display:none}}'
page = page.replace('</style>', native_css + '</style>')
(OUT / 'index.html').write_text(page, encoding='utf-8')
print_page = page.replace('<details class="sequence"', '<details open class="sequence"')
print_page = re.sub(r'<fieldset class="controls">.*?</fieldset>', '', print_page, flags=re.S)
(OUT / 'print.html').write_text(print_page, encoding='utf-8')

changed = []
for seq in inv['sequences']:
    for row in seq['maps']:
        for info in row['files'].values():
            path = ROOT / info['path']
            if info['exists'] and (not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest() != info['sha256']):
                changed.append(info['path'])
reviewed_paths = {f['path'] for s in sequences for m in s['maps'] for f in m['files'].values()}
(OUT / 'source-freshness.json').write_text(json.dumps({'scope':'Inventory sources at publication; unchanged hashes do not certify correctness. Primitives is baseline context, not one of the 24 reviewed sequences.', 'changed_since_inventory':changed, 'changed_in_reviewed_sequences':[p for p in changed if p in reviewed_paths]}, indent=2)+'\n', encoding='utf-8')
print(json.dumps({'sequences':len(cards),'main_texts_reviewed':sum(len(s['maps']) for s in sequences),'changed_sources':changed,'html_bytes':len(page.encode('utf-8'))}))
