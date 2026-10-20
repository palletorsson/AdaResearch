"""Build the offline-capable review deck and check its source references."""
import json
from html import escape
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
data = json.loads((HERE / 'cards.json').read_text(encoding='utf-8'))
sequence = json.loads((ROOT / 'commons/maps/sequences/primitives.json').read_text(encoding='utf-8-sig'))
expected = sequence['sequences']['primitives']['maps']
assert [card['id'] for card in data['cards']] == expected, 'Card order differs from the source spine'
rooms = json.loads((ROOT / 'commons/void/rooms.json').read_text(encoding='utf-8-sig'))['floors']
references = 0
for card in data['cards']:
    floor_map = rooms[card['floor']]['map']
    assert floor_map == ('Point_Trace' if card['id'] == 'Point_Line_Grid' else card['id'])
    for key in ['subjects', 'bring', 'act', 'hold', 'notice', 'check', 'carry', 'reflection', 'status', 'present', 'gap', 'short']:
        assert card.get(key), (card['id'], key)
    for ref in [card['image'], *([card['check_file']] if 'check_file' in card else [])]:
        assert (HERE / ref).is_file(), ref
        references += 1
    for ref in [*card['sources'], f"commons/maps/{card['id']}/tutorial.md", f"commons/maps/{card['id']}/final.md"]:
        assert (ROOT / ref).is_file(), ref
        references += 1
template = (HERE / 'template.html').read_text(encoding='utf-8')
cards = data['cards']
e = escape
fields = [('bring', 'Bring'), ('act', 'Act'), ('hold', 'Keep'), ('notice', 'Notice'), ('check', 'Check'), ('carry', 'Carry')]


def page_name(card):
    return card['id'] + '.html'


def floor_label(card):
    if card['floor'] == 0:
        return 'Rooftop'
    return f"Floor {card['floor']:02d}" + (' · with Trace' if card['id'] == 'Point_Line_Grid' else '')


def header(current=None, overview=False):
    nav = ''.join(
        f'<a href="{page_name(c)}"' + (' aria-current="step"' if i == current else '')
        + f'><span>{i+1:02d}</span>{e(c["hall"].replace("Point ", ""))}</a>'
        for i, c in enumerate(cards))
    return ('<header class="masthead"><div><div class="eyebrow">ADA RESEARCH / THE VOID / ENCOUNTER DRAFTS</div>'
            '<h1>Scientific and strange.</h1><p>15 short cards through Primitives. Change a relation. Notice what follows. Keep what you learned.</p></div>'
            '<div class="modes"><a class="button ' + ('' if overview else 'active') + '" href="index.html">One hall</a>'
            '<a class="button ' + ('active' if overview else '') + '" href="overview.html">Whole route</a>'
            '<a class="button" href="print.html">Print view</a></div></header>'
            '<nav class="route" aria-label="Primitives halls">' + nav + '</nav>')


def shared():
    return (f'<div class="shared"><div><strong>Cards first.</strong><p>{e(data["scope"])}</p><p>{e(data["status"])}</p>'
            '<p><a href="cards.json">Compact cards + shared instructions (JSON)</a></p></div>'
            f'<div><strong>Two texts, different work.</strong><p>{e(data["writing"])}</p><p>{e(data["continuity"])}</p></div></div>'
            f'<details class="details"><summary>Evidence and limits</summary><p>{e(data["evidence"])}</p>'
            '<p>Existing runtime tests do not demonstrate that a student has learned the principle. The Cube check record is linked separately.</p>'
            '<p>Old museum descriptions remain in final.md: the Point One sun/white sphere, and twenty Portals rings rather than the tower’s seven. Preserve the writing; adjust these concrete references when reviewing each hall.</p></details>'
            '<footer>19 October 2026 · Review draft · Game code, layouts, tutorial.md and final.md are unchanged by this deck.</footer>')


def write_page(name, title, content):
    output = template.replace('__TITLE__', e(title)).replace('__CONTENT__', content)
    assert '__CONTENT__' not in output and '<script' not in output
    (HERE / name).write_text(output, encoding='utf-8')


for i, c in enumerate(cards):
    badge = 'gap' if c['status'] == 'Focus gap' or c['status'].startswith('Missing') else ('tested' if c.get('recorded_check') else '')
    prev = (f'<a class="button" rel="prev" href="{page_name(cards[i-1])}">← Previous</a>' if i else '<span class="button disabled">← Previous</span>')
    nxt = (f'<a class="button" rel="next" href="{page_name(cards[i+1])}">Next →</a>' if i < len(cards)-1 else '<span class="button disabled">Next →</span>')
    steps = ''.join(f'<div class="{"notice" if key == "notice" else ""}"><dt>{label}</dt><dd>{e(c[key])}</dd></div>' for key, label in fields)
    tags = ''.join(f'<span class="subject">{e(s)}</span>' for s in c['subjects'])
    check_link = f'<a href="{c["check_file"]}">Native check record</a>' if c.get('check_file') else ''
    sources = ''.join(f'<li><code>{e(p)}</code></li>' for p in c['sources'])
    content = (header(i) + f'<nav class="nav" aria-label="Card navigation">{prev}<span class="hall-name">{e(c["hall"])} · {floor_label(c)}</span><span class="count">{i+1} / {len(cards)}</span>{nxt}</nav>'
               f'<article><div class="card"><div class="visual"><a href="{c["image"]}" aria-label="Open full image of {e(c["hall"])}"><img src="{c["image"]}" alt="{e(c["caption"])}"></a>'
               f'<p class="caption">NATIVE GODOT CAPTURE · {e(c["caption"])}</p><div class="visual-copy"><div class="eyebrow">Reflection seed</div><blockquote>{e(c["reflection"])}</blockquote>'
               f'<span class="status {badge}">{e(c["status"])}</span><p class="present">{e(c["present"])}</p></div></div>'
               f'<div class="facts"><div class="eyebrow">{i+1:02d} / {e(c["hall"])} / {floor_label(c)}</div><h2>{e(c["title"])}</h2><div class="subjects">{tags}</div><dl class="steps">{steps}</dl></div></div>'
               f'<div class="lower"><div><h3>To resolve in this hall</h3><p>{e(c["gap"])}</p></div><div><h3>{"Recorded evidence" if c.get("recorded_check") else "How to read the check"}</h3>'
               f'<p>{e(c.get("recorded_check", "An acceptance criterion for the proposed encounter and lesson. It is not a claim of a newly passed runtime test."))}</p><div class="links">'
               f'<a href="http://localhost:3003/lab-editor?mode=void&amp;floor={c["floor"]}" target="_blank" rel="noopener">Lab editor ↗</a>'
               f'<a href="../../../../commons/maps/{c["id"]}/tutorial.md">tutorial.md</a>'
               f'<a href="../../../../commons/maps/{c["id"]}/final.md">final.md</a>{check_link}</div></div></div>'
               f'<details class="details"><summary>Short form for AI context</summary><pre class="short">{e(c["short"])}</pre>'
               '<p>Read with the shared core in <a href="cards.json">cards.json</a>. Inspect these repository sources before expanding into code:</p>'
               f'<ul class="source-list">{sources}</ul></details></article>' + shared())
    write_page(page_name(c), c['hall'] + ' · Primitives encounter cards', '<main>' + content + '</main>')
    if i == 0:
        write_page('index.html', 'Primitives · Encounter cards', '<main>' + content + '</main>')

rows = ''.join(f'<tr><td><a href="{page_name(c)}">{e(c["hall"])}</a><small>{floor_label(c)}<br>{e(c["status"])}</small></td><td>{e(" · ".join(c["subjects"]))}</td><td>{e(c["notice"])}</td><td>{e(c["carry"])}</td></tr>' for c in cards)
gaps = ''.join(f'<article class="gap-item"><h3><a href="{page_name(c)}">{e(c["hall"])}</a></h3><p>{e(c["gap"])}</p></article>' for c in cards if c['status'] == 'Focus gap' or c['status'].startswith('Missing'))
overview = (header(overview=True) + '<h2 class="summary-title">A relation becomes the next material.</h2>'
            '<p class="overview-note">Point → endpoint → record → address → face → enclosure → connection recipe → generator → parameter → profile → path → stopping rule → composition.</p>'
            '<p class="overview-note">Keep this order for the first pass. Strengthen the handoffs and make the main experiment legible. Grid stays beside Trace on floor 04. Further artifacts remain available without becoming compulsory lessons.</p>'
            f'<table class="overview-table"><thead><tr><th>Hall / floor</th><th>Learn</th><th>Surprise to investigate</th><th>Carry onward</th></tr></thead><tbody>{rows}</tbody></table>'
            '<h2 class="summary-title">Where the room needs to catch up.</h2><p class="overview-note">These proposals preserve the tutorial focus instead of replacing it with whatever happens to be on display.</p>'
            f'<div class="gap-list">{gaps}</div>' + shared())
write_page('overview.html', 'Whole route · Primitives encounter cards', '<main>' + overview + '</main>')
print_cards = ''.join(
    f'<article class="print-card"><div class="eyebrow">REVIEW DRAFT / {i+1} OF {len(cards)} / {floor_label(c)}</div><h2>{e(c["hall"])}<br>{e(c["title"])}</h2>'
    f'<img src="{c["image"]}" alt="{e(c["caption"])}"><p>{e(" · ".join(c["subjects"]))}</p><dl>'
    + ''.join(f'<div><dt>{label}</dt><dd>{e(c[key])}</dd></div>' for key, label in fields)
    + f'</dl><p><b>Reflection:</b> {e(c["reflection"])}</p><p class="print-note"><b>{e(c["status"])}.</b> {e(c["gap"])}</p>'
    + f'<p class="print-note">{e(c.get("recorded_check", "Check = proposed acceptance criterion, not a new test result."))}</p></article>'
    for i, c in enumerate(cards))
write_page('print.html', 'Print · Primitives encounter cards', '<main class="print-page"><div class="print-instruction"><a href="index.html">← Back to cards</a><p>Print with the browser’s Print command (Ctrl+P). One card per page.</p></div><div class="print-cards">' + print_cards + '</div></main>')
print(f"Built 15 static cards, overview and print view across {len(rooms)} floors; {references} references exist; order matches Primitives. No browser scripts required.")
