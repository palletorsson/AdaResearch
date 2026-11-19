"""The opera as one journey: check commons/data/opera/journey.json against the trajectory outline, and render it.

Palle, 19 November 2026: "The songs should be read as one coherent journey, the story of discovering what
forms are possible, what topologies, what spaces, bodies, organizational structures and their edges."

journey.json holds one stop per floor of the tower, in spine order: what the stop takes from the stop before,
what it discovers, which of Palle's six words it is about, and the two or more outline entries it touches.

    python tools/opera_journey.py              check; exit code = number of findings
    python tools/opera_journey.py --write      check, then write doc/book/course/OPERA_JOURNEY.md
    python tools/opera_journey.py --map Array  print one stop

Checked: every map of the outline has a stop, in the outline's order; every sequence holds the maps
trajectory_sequences.json gives it; a stop touches at least two entries, each one present in that map's
outline and in the outline's order. A floor whose outline holds a single entry may carry one in from the
floor before ("carried": true); no other floor may.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JOURNEY = ROOT / 'commons/data/opera/journey.json'
OUTLINE = ROOT / 'commons/data/encounters/trajectory_outline.json'
SEQUENCES = ROOT / 'commons/data/encounters/trajectory_sequences.json'
ROOMS = ROOT / 'commons/void/rooms.json'
PAGE = ROOT / 'doc/book/course/OPERA_JOURNEY.md'
SIX = ['form', 'topology', 'space', 'body', 'organization', 'edge']


def load(path):
    return json.loads(path.read_text(encoding='utf-8')) if path.exists() else None


def label(entry):
    title, song = entry.get('title') or '', entry.get('songTitle') or ''
    return title if not song or song.lower() == title.lower() else '%s / %s' % (title, song)


def stops(journey):
    for act in journey['acts']:
        for seq in act['sequences']:
            for stop in seq['stops']:
                yield act, seq, stop


def check(journey, outline, sequences):
    found = []
    order = [stop['map'] for _, _, stop in stops(journey)]
    for word in set(k for _, _, s in stops(journey) for k in s['finds']) - set(SIX):
        found.append('finds: "%s" is not one of the six words' % word)
    for _, _, stop in stops(journey):
        if not stop.get('carries') or not stop.get('discovers'):
            found.append('%s: a stop says what it carries and what it discovers' % stop['map'])
        if not stop['finds']:
            found.append('%s: no word of the six' % stop['map'])
        if len(stop['touches']) < 2:
            found.append('%s: touches %d, needs two' % (stop['map'], len(stop['touches'])))
    if sequences is not None:
        given = {s['id']: s['maps'] for s in sequences}
        told = [seq['id'] for act in journey['acts'] for seq in act['sequences']]
        if told != [s['id'] for s in sequences]:
            found.append('sequences: the journey does not follow trajectory_sequences.json in order')
        for act in journey['acts']:
            for seq in act['sequences']:
                if [s['map'] for s in seq['stops']] != given.get(seq['id']):
                    found.append('%s: its stops are not the maps trajectory_sequences.json gives it' % seq['id'])
    if outline is None:
        print('trajectory_outline.json is absent: touches not checked')
        return found
    maps = outline['maps']
    if order != [m['map'] for m in maps]:
        found.append('order: the stops are not the outline\'s %d maps in its order' % len(maps))
        return found
    index = {m['map']: {e['id']: k for k, e in enumerate(m['entries'])} for m in maps}
    for at, (_, _, stop) in enumerate(stops(journey)):
        here, last = index[stop['map']], -1
        for touch in stop['touches']:
            if touch.get('carried'):
                if len(here) >= 2:
                    found.append('%s: carries an entry in although its own outline holds %d' % (stop['map'], len(here)))
                if at == 0 or touch['id'] not in index[order[at - 1]] or touch.get('from') != order[at - 1]:
                    found.append('%s: carried entry %s is not on the floor before' % (stop['map'], touch['id']))
                continue
            if touch['id'] not in here:
                found.append('%s: no outline entry %s' % (stop['map'], touch['id']))
            elif here[touch['id']] <= last:
                found.append('%s: %s is touched out of the outline\'s order' % (stop['map'], touch['id']))
            else:
                last = here[touch['id']]
    for word in journey.get('words', []):
        for stop in word['stops']:
            if stop['id'] not in index.get(stop['map'], {}):
                found.append('word "%s": no entry %s on %s' % (word['word'], stop['id'], stop['map']))
    return found


def render(journey, outline):
    rooms = load(ROOMS)
    floor = {f['map']: k for k, f in enumerate(rooms['floors'])} if rooms else {}
    titles = {m['map']: {e['id']: label(e) for e in m['entries']} for m in outline['maps']} if outline else {}

    def name(map_name, touch):
        return titles.get(map_name, {}).get(touch['id']) or touch.get('title') or touch['id']

    out = ['# The opera as one journey', '',
           '> Rendered from `commons/data/opera/journey.json` by `python tools/opera_journey.py --write`. Edit the JSON, then render.', '',
           '**%s, %s:** %s' % (journey['premise']['by'], journey['premise']['date'], journey['premise']['text']), '',
           journey['about'], '']
    out += ['## The six words', '']
    out += ['| | ' + ' | '.join(act['id'] for act in journey['acts']) + ' | all |', '|---|' + '---|' * (len(journey['acts']) + 1)]
    for word in SIX:
        counts = [sum(1 for seq in act['sequences'] for s in seq['stops'] if word in s['finds']) for act in journey['acts']]
        out.append('| **%s**: %s | %s | %d |' % (word, journey['six'][word], ' | '.join(str(c) for c in counts), sum(counts)))
    out += ['', 'Stops per act that are about each word. A stop may be about two.', '']
    out += ['## Words that come back', '']
    for word in journey.get('words', []):
        out.append('**%s.** %s' % (word['word'], word['line']))
        out.append('')
        for stop in word['stops']:
            out.append('- %s%s: %s' % ('floor %d, ' % floor[stop['map']] if stop['map'] in floor else '', stop['map'], name(stop['map'], stop)))
        out.append('')
    for act in journey['acts']:
        out += ['## Act %s. %s' % (act['id'], act['title']), '', act['line'], '']
        for seq in act['sequences']:
            first, final = seq['stops'][0]['map'], seq['stops'][-1]['map']
            span = ' (floors %d to %d)' % (floor[first], floor[final]) if first in floor and first != final else (' (floor %d)' % floor[first] if first in floor else '')
            out += ['### %s%s' % (seq['title'], span), '', '*%s*' % seq['movement'], '']
            for stop in seq['stops']:
                touched = ' · '.join(('from %s: ' % t['from'] if t.get('carried') else '') + name(t.get('from') or stop['map'], t) for t in stop['touches'])
                out += ['**%s%s** (%s)' % ('%d · ' % floor[stop['map']] if stop['map'] in floor else '', stop['map'], ', '.join(stop['finds'])),
                        '- Takes: %s' % stop['carries'], '- Discovers: %s' % stop['discovers'], '- Touches: %s' % touched, '']
    return '\n'.join(out).rstrip() + '\n'


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    journey, outline, sequences = load(JOURNEY), load(OUTLINE), load(SEQUENCES)
    for arg in sys.argv[1:]:
        if arg.startswith('--map'):
            wanted = arg.split('=', 1)[1] if '=' in arg else sys.argv[sys.argv.index(arg) + 1]
            for act, seq, stop in stops(journey):
                if stop['map'].lower() == wanted.lower():
                    print('Act %s. %s / %s' % (act['id'], act['title'], seq['title']))
                    print(json.dumps(stop, indent=1, ensure_ascii=False))
            return 0
    found = check(journey, outline, sequences)
    for line in found:
        print('FINDING', line)
    count = sum(1 for _ in stops(journey))
    touched = sum(len(s['touches']) for _, _, s in stops(journey))
    carried = [s['map'] for _, _, s in stops(journey) if any(t.get('carried') for t in s['touches'])]
    print('%d acts, %d movements, %d stops, %d touches; %d floors carry one in: %s; %d findings'
          % (len(journey['acts']), sum(len(a['sequences']) for a in journey['acts']), count, touched, len(carried), ', '.join(carried), len(found)))
    if '--write' in sys.argv and not found:
        PAGE.write_text(render(journey, outline), encoding='utf-8', newline='\n')
        print('wrote', PAGE.relative_to(ROOT).as_posix())
    return len(found)


if __name__ == '__main__':
    sys.exit(main())
