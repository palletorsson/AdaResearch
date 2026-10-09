"""Build the proposal from editable JSON; inspect source links without running Godot."""
from pathlib import Path
from collections import Counter
from urllib.parse import urlsplit, unquote
from html.parser import HTMLParser
import html
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
plan = json.loads((HERE / 'proposal.json').read_text(encoding='utf-8'))
ideas = plan['ideas']
halls = plan['halls']
by_id = {x['id']: x for x in ideas}
core_ids = {x['id'] for x in ideas if x['role'] == 'core'}
seq_path = ROOT / 'commons/maps/sequences/forces.json'
canonical = json.loads(seq_path.read_text(encoding='utf-8'))['sequences']['forces']['maps']
assert len(ideas) == 30 and sorted(by_id) == list(range(1, 31))
assert [h['map'] for h in halls] == canonical
assert Counter(x['role'] for x in ideas) == {'core': 13, 'practice': 12, 'extension': 5}
assert sorted(i for h in halls for i in h['ideas']) == list(range(1, 31))
assert sorted(i for a in plan['acts'] for i in a['ids']) == list(range(1, 31))
for hall in halls:
    assert sum(by_id[i]['role'] == 'core' for i in hall['ideas']) == 1
    assert all(by_id[i]['hall'] == hall['map'] for i in hall['ideas'])
for idea in ideas:
    assert all(dep in by_id and dep < idea['id'] for dep in idea['requires'])
    if idea['role'] == 'core':
        assert all(dep in core_ids for dep in idea['requires']), idea['id']
    assert all((ROOT / path).is_file() for path in idea['source_paths']), idea['id']

e = html.escape
def link_source(path):
    return '<a href="../../../../' + e(path) + '">' + e(path) + '</a>'
def idea_links(ids):
    return ' · '.join(f'<a href="#idea-{i}">{i:02d}</a>' for i in ids)

act_cards = ''.join('<article><p class="eyebrow">Halls ' + ', '.join(map(str, a['halls'])) +
    '</p><h3>' + e(a['title']) + '</h3><p>' + e(a['story']) + '</p><p>' +
    idea_links(a['ids']) + '</p></article>' for a in plan['acts'])
summaries = ''.join(f'<details id="hall-{h["order"]}"><summary>{h["order"]:02d}. {e(h["title"])} <small>{e(h["map"])}</small></summary>' +
    '<p>' + e(h['tutorial_summary']) + '</p><p class="reflection"><strong>Reflective question:</strong> ' +
    e(h['reflection_question']) + '</p><p>Ideas ' + idea_links(h['ideas']) + '</p><p class="sources">' +
    link_source('commons/maps/' + h['map'] + '/tutorial.md') + ' · ' +
    link_source('commons/maps/' + h['map'] + '/final.md') + '</p></details>' for h in halls)

cards = []
for x in ideas:
    cards.append(f'<article class="idea" id="idea-{x["id"]}" data-role="{x["role"]}" data-hall="{e(x["hall"])}">' +
        f'<div class="cardtop"><b class="number">{x["id"]:02d}</b><span class="badge {x["role"]}">{e(x["role"])}</span></div>' +
        '<p class="eyebrow">' + e(x['hall']) + '</p><h3>' + e(x['title']) + '</h3><p class="question">' +
        e(x['question']) + '</p><p>' + e(x['upgrade']) + '</p><p><strong>Learn:</strong> ' +
        e(' · '.join(x['learning_elements'])) + '</p><p><strong>Carry forward:</strong> ' + e(x['carried_forward']) +
        '</p><div class="outcomes"><p><strong>Precision</strong>' + e(x['precision']) +
        '</p><p><strong>Possible consequence</strong>' + e(x['possible_consequence']) + '</p></div>' +
        '<details><summary>Existing source, work and future checks</summary><p><strong>Now:</strong> ' + e(x['source_status']) +
        '</p><p><strong>Upgrade work:</strong> ' + e(x['implementation_work']) +
        '</p><p><strong>Future acceptance check:</strong> ' + e(x['acceptance_check']) +
        '</p><p>Builds on: ' + (idea_links(x['requires']) if x['requires'] else 'the earlier Point / Coordinates / Lines lessons') +
        '</p><ul class="sources">' + ''.join('<li>' + link_source(p) + '</li>' for p in x['source_paths']) + '</ul></details></article>')

styles = '''
:root{--paper:#eeeae3;--white:#fcfbf7;--ink:#252827;--muted:#686e69;--line:#d3d2c8;--green:#305e50;--pink:#a54b68}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--paper);color:var(--ink);font:18px/1.55 Georgia,serif}a{color:var(--green);text-underline-offset:3px}nav,footer{padding:18px 4vw;font:13px/1.5 system-ui;border-bottom:1px solid var(--line);display:flex;gap:22px;flex-wrap:wrap}main{max-width:1300px;margin:auto;padding:40px 30px}h1{font-size:clamp(40px,6vw,76px);line-height:1.06;letter-spacing:-.035em;max-width:1050px;margin:20px 0}h2{font-size:34px;line-height:1.2;margin:48px 0 20px}h3{font-size:25px;line-height:1.18;margin:10px 0 18px}p{margin:0 0 16px}.lead{font-size:25px;max-width:950px}.eyebrow{font:11px/1.5 system-ui;text-transform:uppercase;letter-spacing:.06em;color:var(--muted)}.note{font:14px/1.65 system-ui;color:var(--muted);max-width:950px}.route{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}.route article{background:var(--white);padding:24px;border-top:4px solid var(--green)}.route p{font-size:16px}.route h3{font-size:22px}.facts{display:flex;gap:14px;flex-wrap:wrap;margin:28px 0}.facts span{background:var(--white);border:1px solid var(--line);padding:15px 20px;font:14px system-ui}.facts b{font:30px Georgia;margin-right:10px}.reading{max-width:850px}.reading li{margin-bottom:12px}details{background:var(--white);border:1px solid var(--line);padding:18px;margin:12px 0}summary{cursor:pointer;font:16px/1.6 system-ui}summary small{display:block;color:var(--muted);font:11px/1.5 system-ui}details>p:first-of-type{margin-top:18px}.reflection{border-left:3px solid var(--pink);padding-left:15px}input,select,button{font:14px system-ui;border:1px solid var(--line);background:var(--white);color:var(--ink);padding:12px;min-width:0}button{cursor:pointer}.filters{display:flex;gap:12px;flex-wrap:wrap;margin:20px 0}.filters input{flex:2;min-width:220px}.filters select{flex:1;min-width:180px}.cards{display:grid;grid-template-columns:1fr 1fr;gap:22px}.idea{background:var(--white);padding:25px;border:1px solid var(--line);scroll-margin-top:20px}.idea[hidden]{display:none}.cardtop{display:flex;justify-content:space-between;align-items:center;margin-bottom:18px}.number{font:36px Georgia;color:var(--muted)}.badge{font:11px system-ui;text-transform:uppercase;letter-spacing:.07em;padding:7px 10px;border-radius:3px}.core{background:#dce9df;color:#284f38}.practice{background:#e0e6ec;color:#354858}.extension{background:#eadfe4;color:#76435b}.question{font-style:italic;font-size:20px}.idea p{font-size:16px}.outcomes{display:grid;grid-template-columns:1fr 1fr;gap:15px;border-top:1px solid var(--line);padding-top:18px}.outcomes strong{display:block;font:11px system-ui;text-transform:uppercase;color:var(--green);margin-bottom:8px}.sources{font:11px/1.6 system-ui!important;overflow-wrap:anywhere}.idea details{padding:12px;background:var(--paper)}.idea details p{font-size:14px}.sourcecode{white-space:normal}.brief{padding:20px;border-left:4px solid var(--pink);background:var(--white);font:14px/1.7 system-ui}section{scroll-margin-top:20px}@media(max-width:850px){.route{grid-template-columns:1fr 1fr}.cards{grid-template-columns:1fr}}@media(max-width:530px){main{padding:25px 16px}.route{grid-template-columns:1fr}.outcomes{grid-template-columns:1fr}.filters>*{width:100%}}@media print{nav,.filters,#count{display:none}.cards{display:block}.idea{break-inside:avoid;margin-bottom:15px}.idea[hidden]{display:block}body{background:white;font-size:11pt}.idea p{font-size:10pt}h1{font-size:30pt}a{color:inherit}.route{grid-template-columns:1fr 1fr}}
'''
script = '''
const cards=[...document.querySelectorAll('.idea')];
const search=document.getElementById('search'),role=document.getElementById('role'),hall=document.getElementById('hall');
function filter(){const q=search.value.toLowerCase();let n=0;for(const c of cards){c.hidden=!!((role.value&&c.dataset.role!==role.value)||(hall.value&&c.dataset.hall!==hall.value)||(q&&!c.textContent.toLowerCase().includes(q)));if(!c.hidden)n++;}document.getElementById('count').textContent=n+' of 30 ideas';}
function clear(){search.value='';role.value='';hall.value='';filter();}
for(const f of [search,role,hall])f.addEventListener('input',filter);
document.getElementById('clear').addEventListener('click',clear);
function reveal(){if(location.hash.startsWith('#idea-')){const target=document.getElementById(location.hash.slice(1));if(target){if(target.hidden)clear();target.scrollIntoView();}}}
window.addEventListener('hashchange',reveal);filter();reveal();
'''
page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + e(plan['title']) + '</title><style>' + styles + '</style></head><body>'
page += '<nav><b>ENDLESS MUSEUM / VECTOR & FORCE PROPOSAL</b><a href="#story">Narrative</a><a href="#halls">13 halls</a><a href="#ideas">30 ideas</a><a href="#build">Build order</a><a href="REPORT.md">Full text</a><a href="proposal.json">Editable plan</a></nav><main>'
page += '<p class="eyebrow">7 October 2026 / source-grounded design proposal</p><h1>' + e(plan['title']) + '</h1><p class="lead">' + e(plan['premise']) + '</p><p class="note">' + e(plan['status']) + '</p>'
page += '<div class="facts"><span><b>30</b>upgrades</span><span><b>13</b>core lessons</span><span><b>12</b>practice encounters</span><span><b>5</b>optional extensions</span></div>'
page += '<section id="story"><h2>A continuing object, six changes in understanding</h2><div class="route">' + act_cards + '</div><p class="brief">' + e(plan['compression']) + '</p></section>'
page += '<section id="halls"><h2>The existing thirteen-hall order</h2><p class="note">One proposed tutorial paragraph and one reflective question per hall. Thirty encounters do not require thirty maps or thirty complete code chapters. Core lessons have no dependency on optional extensions.</p>' + summaries + '</section>'
page += '<section id="ideas"><h2>Thirty upgrades</h2><div class="filters"><input id="search" aria-label="Search ideas" placeholder="Search sphere, projection, spring, reset…"><select id="role" aria-label="Teaching role"><option value="">All roles</option><option value="core">Core lesson</option><option value="practice">Practice</option><option value="extension">Optional extension</option></select><select id="hall" aria-label="Hall"><option value="">All halls</option>' + ''.join('<option>' + e(h['map']) + '</option>' for h in halls) + '</select><button id="clear">Clear filters</button></div><p id="count" class="note" aria-live="polite">30 ideas</p><div class="cards">' + ''.join(cards) + '</div></section>'
page += '<section id="build" class="reading"><h2>Build in reviewable passes</h2>' + ''.join('<h3>' + e(x['phase']) + '</h3><p>' + e(x['detail']) + '</p><p>Ideas ' + idea_links(x['ids']) + '</p>' for x in plan['delivery']) + '<h2>What keeps the lineage exact</h2><ol>' + ''.join('<li>' + e(x) + '</li>' for x in plan['ground_rules']) + '</ol><h2>Verification and references</h2><p>' + e(plan['verification']) + '</p><p><a href="validation.json">Proposal validation and source hashes</a></p><ul>' + ''.join('<li><a href="' + e(x['url']) + '">' + e(x['title']) + '</a><p class="note">' + e(x['use']) + '</p></li>' for x in plan['references']) + '</ul></section></main><footer>Proposed upgrades. No new engine/headset test or implementation claim. <a href="proposal.json">Edit proposal.json</a> and rebuild with build.py.</footer><script>' + script + '</script></body></html>'
(HERE / 'index.html').write_text(page, encoding='utf-8')

md = ['# ' + plan['title'], plan['status'], plan['premise'], plan['compression'], '## Narrative']
for a in plan['acts']:
    md += ['### ' + a['title'], a['story'], 'Ideas: ' + ', '.join(map(str, a['ids']))]
md += ['## The existing halls']
for h in halls:
    md += [f'### {h["order"]}. {h["map"]} — {h["title"]}', h['tutorial_summary'], '**Reflective question:** ' + h['reflection_question']]
md += ['## Thirty upgrades']
for x in ideas:
    md += [f'### {x["id"]:02d}. {x["title"]}', f'**{x["role"].upper()} · {x["hall"]}**', '**Question:** ' + x['question'], x['upgrade'], '**Learning elements:** ' + ', '.join(x['learning_elements']), '**Carry forward:** ' + x['carried_forward'], '**Precision:** ' + x['precision'], '**Possible consequence:** ' + x['possible_consequence'], '**Existing source:** ' + x['source_status'], '**Implementation work:** ' + x['implementation_work'], '**Future acceptance check:** ' + x['acceptance_check'], '**Builds on ideas:** ' + (', '.join(map(str, x['requires'])) or 'earlier Point / Coordinates / Lines'), '\n'.join('- [' + p + '](../../../../' + p + ')' for p in x['source_paths'])]
md += ['## Delivery passes']
for d in plan['delivery']:
    md += ['### ' + d['phase'], d['detail'], 'Ideas: ' + ', '.join(map(str, d['ids']))]
md += ['## Ground rules', '\n'.join(f'{i}. {rule}' for i, rule in enumerate(plan['ground_rules'], 1)), '## Verification', plan['verification'], '## References', '\n'.join('- [' + x['title'] + '](' + x['url'] + '): ' + x['use'] for x in plan['references'])]
(HERE / 'REPORT.md').write_text('\n\n'.join(md) + '\n', encoding='utf-8')

class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.ids=set(); self.hrefs=[]
    def handle_starttag(self, tag, attrs):
        d=dict(attrs)
        if 'id' in d:
            assert d['id'] not in self.ids, d['id']
            self.ids.add(d['id'])
        if 'href' in d:self.hrefs.append(d['href'])
parser=Links();parser.feed(page)
source_paths = sorted(set(p for x in ideas for p in x['source_paths']))
result={'ideas':30,'roles':dict(Counter(x['role'] for x in ideas)),'halls':13,'canonical_order_matches':True,'core_has_only_core_prerequisites':True,'all_dependencies_precede_use':True,'runtime_tests':'not run; proposal only','source_sha256':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in source_paths},'sequence_sha256':hashlib.sha256(seq_path.read_bytes()).hexdigest()}
(HERE / 'validation.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
local_count=0
for href in parser.hrefs:
    u=urlsplit(href)
    if u.scheme or u.netloc:continue
    if u.path:assert (HERE/unquote(u.path)).is_file(), href
    elif u.fragment:assert u.fragment in parser.ids, href
    local_count+=1
result['local_links_and_anchors']=local_count
(HERE / 'validation.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k not in ('source_sha256','sequence_sha256')}, indent=2))
