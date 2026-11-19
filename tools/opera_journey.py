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

A stop may hold a song: one line at each touched entry, in the stop's order, written without a personal
pronoun (commons/data/opera/editorial_revisions.json). "keeps" is a word the song shares with the song of
the stop before, so the songs compound; "hands_on" is the sentence the stop leaves for a unit that has
not been there. An act that has begun its songs has one for every stop.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JOURNEY = ROOT / 'commons/data/opera/journey.json'
OUTLINE = ROOT / 'commons/data/encounters/trajectory_outline.json'
SEQUENCES = ROOT / 'commons/data/encounters/trajectory_sequences.json'
ROOMS = ROOT / 'commons/void/rooms.json'
PAGE = ROOT / 'doc/book/course/OPERA_JOURNEY.md'
MANUSCRIPT = ROOT / 'doc/book/course/OPERA_MANUSCRIPT.txt'
SIX = ['form', 'topology', 'space', 'body', 'organization', 'edge']
PRONOUNS = {'i', 'me', 'my', 'mine', 'we', 'us', 'our', 'ours', 'you', 'your', 'yours'}


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
    for act in journey['acts']:
        row = [s for seq in act['sequences'] for s in seq['stops']]
        sung = [s for s in row if s.get('song')]
        if sung and len(sung) != len(row):
            found.append('act %s: %d of %d stops have a song' % (act['id'], len(sung), len(row)))
        for at, stop in enumerate(row):
            song = stop.get('song')
            if not song:
                continue
            words = ' '.join(line['text'] for line in song['lines'])
            if [line['at'] for line in song['lines']] != [t['id'] for t in stop['touches']]:
                found.append('%s: the song does not give one line to each touched entry, in order' % stop['map'])
            said = PRONOUNS & set(re.findall(r"[a-z']+", words.lower()))
            if said:
                found.append('%s: a discovery song without a personal pronoun; it says %s' % (stop['map'], ', '.join(sorted(said))))
            if not song.get('hands_on'):
                found.append('%s: the song hands nothing on' % stop['map'])
            if at and row[at - 1].get('song'):
                before = ' '.join(line['text'] for line in row[at - 1]['song']['lines'])
                keeps = song.get('keeps') or ''
                if not keeps or not all(re.search(r'\b' + re.escape(keeps), t, re.I) for t in (words, before)):
                    found.append('%s: keeps "%s", which is not in both this song and the one before' % (stop['map'], keeps))
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
        carry = act.get('carry')
        if carry:
            out += ['### What act %s hands on' % act['id'], '', carry['about'], '',
                    'Asked on %s: *%s* (%s)' % (carry['asked_at']['map'], carry['asked_at']['line'], carry['asked_at']['status']), '']
            out += ['> %s  ' % line['text'] for line in carry['lines']] + ['']
        for seq in act['sequences']:
            first, final = seq['stops'][0]['map'], seq['stops'][-1]['map']
            span = ' (floors %d to %d)' % (floor[first], floor[final]) if first in floor and first != final else (' (floor %d)' % floor[first] if first in floor else '')
            out += ['### %s%s' % (seq['title'], span), '', '*%s*' % seq['movement'], '']
            for stop in seq['stops']:
                touched = ' · '.join(('from %s: ' % t['from'] if t.get('carried') else '') + name(t.get('from') or stop['map'], t) for t in stop['touches'])
                out += ['**%s%s** (%s)' % ('%d · ' % floor[stop['map']] if stop['map'] in floor else '', stop['map'], ', '.join(stop['finds'])),
                        '- Takes: %s' % stop['carries'], '- Discovers: %s' % stop['discovers'], '- Touches: %s' % touched]
                song = stop.get('song')
                if song:
                    out += [''] + ['> %s  ' % line['text'] for line in song['lines']] + ['']
                    notes = ['%s: %s' % (name(stop['map'], {'id': line['at']}).split(' / ')[0],
                                         'accepted on the desk, card %s' % line['card'] if line['status'] == 'reviewed'
                                         else 'the line already there, kept' if line['status'] == 'kept'
                                         else 'new' + ('; there now: "%s"' % line['there_now'] if line.get('there_now') else ''))
                             for line in song['lines']]
                    out += ['- Lines: ' + ' · '.join(notes)]
                    if song.get('keeps'):
                        out += ['- Keeps from the song before: **%s**' % song['keeps']]
                    out += ['- Hands on: %s' % song['hands_on']]
                    if song.get('echo'):
                        out += ['- Later, in Service (%s): %s' % (song['echo']['where'], song['echo']['text'])]
                out += ['']
    return '\n'.join(out).rstrip() + '\n'


def manuscript(journey):
    """The songs alone, as one raw text: an act, its floors in order, and after each movement the lines the act has
    gathered so far, one more each time."""
    out = []
    for act in journey['acts']:
        if not any(s.get('song') for seq in act['sequences'] for s in seq['stops']):
            continue
        carry, gathered = act.get('carry'), []
        out += ['ACT %s' % act['id'], act['title'].upper(), '']
        number = sum(1 for _ in stops(journey))
        floor = {s['map']: k for k, (_, _, s) in enumerate(stops(journey))}
        for seq in act['sequences']:
            out += ['', seq['title'].upper(), '']
            for stop in seq['stops']:
                out += ['%d. %s' % (floor[stop['map']], stop['map'].replace('_', ' '))]
                out += [line['text'] for line in stop['song']['lines']] + ['']
                if carry and stop['map'] == carry['asked_at']['map']:
                    out += ['        ' + carry['asked_at']['line'], '']
            if carry:
                gathered += [line['text'] for line in carry['lines'] if line['from'] == seq['id']]
                out += ['        ' + text for text in gathered] + ['']
        out += ['']
    return '\n'.join(out).rstrip() + '\n'


def write(path, text):
    # Opening a page for writing fails with EINVAL while a viewer holds it; writing over it in place does not.
    with open(path, 'r+' if path.exists() else 'w', encoding='utf-8', newline='\n') as page:
        page.write(text)
        page.truncate()


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
    songs = sum(1 for _, _, s in stops(journey) if s.get('song'))
    print('%d acts, %d movements, %d stops, %d touches, %d songs; %d floors carry one in: %s; %d findings'
          % (len(journey['acts']), sum(len(a['sequences']) for a in journey['acts']), count, touched, songs, len(carried), ', '.join(carried), len(found)))
    if '--write' in sys.argv and not found:
        write(PAGE, render(journey, outline))
        write(MANUSCRIPT, manuscript(journey))
        print('wrote', MANUSCRIPT.relative_to(ROOT).as_posix())
        print('wrote', PAGE.relative_to(ROOT).as_posix())
    return len(found)


if __name__ == '__main__':
    sys.exit(main())
