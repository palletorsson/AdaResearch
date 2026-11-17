"""Build editable chapter thoughts and exact named-part bindings.

The syllable/timing planner follows the Model B Inner Opera handover's
make_thought.py. Pronunciations are a small CMUdict vocabulary subset (see
commons/data/opera/CMUDICT-LICENSE.txt). No services or audio files are fetched.
Run ship_voice.gd after this to prepare changed phrases for Quest.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'commons/data/opera'
SR = 44100
VOWELS = {'AA':['a'],'AE':['ae'],'AH':['ah'],'AO':['aw'],'AW':['a','u'],
          'AY':['a','ih'],'EH':['e'],'ER':['er'],'EY':['e','ih'],'IH':['ih'],
          'IY':['i'],'OW':['o','u'],'OY':['aw','ih'],'UH':['u'],'UW':['u']}
CONSONANTS = {p:p.lower() for p in 'B D F G K L M N NG P R S SH T TH V W Y Z DH CH'.split()}
CONSONANTS.update(HH='h',JH='j',ZH='zh')
CLUSTERS = set('P R|B R|T R|D R|K R|G R|F R|TH R|P L|B L|K L|G L|F L|S L|S P|S T|S K|S M|S N|S W|T W|K W|S T R|S P R|S K R|S K W'.split('|'))

def syllables(phones):
    nuclei = [i for i,p in enumerate(phones) if p[-1:].isdigit()]
    if not nuclei: raise ValueError('No dictionary vowel')
    boundaries = [0]
    for left,right in zip(nuclei,nuclei[1:]):
        start = right
        for size in (3,2,1):
            if right-size>left and (size==1 or ' '.join(phones[right-size:right]) in CLUSTERS):
                start=right-size;break
        boundaries.append(start)
    boundaries.append(len(phones))
    result=[]
    for i,nucleus in enumerate(nuclei):
        raw=phones[nucleus];stress=int(raw[-1]);symbol=raw[:-1]
        result.append({'onset':[CONSONANTS[p] for p in phones[boundaries[i]:nucleus]],
                       'vowels':['uh'] if symbol=='AH' and stress==0 else VOWELS[symbol],
                       'coda':[CONSONANTS[p] for p in phones[nucleus+1:boundaries[i+1]]],
                       'stress':stress})
    return result

def make_phrase(entry, dictionary, options):
    text=entry['text']
    words=re.findall(r"[a-z]+(?:'[a-z]+)?",text.lower())
    missing=set(words)-dictionary.keys()
    if missing: raise ValueError('Missing pronunciation: '+str(missing))
    flat=[(wi,w,si,s) for wi,w in enumerate(words) for si,s in enumerate(syllables(dictionary[w]))]
    # Four explicitly authored E-minor gestures, selected by chapter floor.
    motifs=[[52,55,54,52],[55,59,57,55,54,52],[52,54,55,54,52],[59,57,55,54,52]]
    motif=motifs[entry['floor']%len(motifs)]
    notes=[motif[i%len(motif)] for i in range(len(flat))]
    notes[-1]=52
    beats=[.65 if s['stress'] else .5 for _,_,_,s in flat]
    beats[-1]=1.1
    beat=60/84
    anchors=[];cursor=.25
    for duration in beats: anchors.append(cursor);cursor+=duration*beat
    preps=[min(.082,.028*len(s['onset'])) for _,_,_,s in flat]
    offset=round((anchors[0]-preps[0])*SR);end_frame=round((cursor-.11)*SR)
    if end_frame-offset+round(.75*SR)>8*SR:
        raise ValueError('Phrase exceeds 8-second base plan: '+text)
    phones=[];sung=[];groups=[]
    for i,(wi,w,si,syl) in enumerate(flat):
        start=round((anchors[i]-preps[i])*SR)-offset
        vowel=round(anchors[i]*SR)-offset
        end=round((anchors[i+1]-preps[i+1]-(.010 if flat[i+1][0]==wi else .040))*SR)-offset if i+1<len(flat) else end_frame-offset
        if end-vowel<round(.078*SR):
            raise ValueError('Syllables too crowded: '+text)
        coda_frames=min(round(.035*SR)*len(syl['coda']),round((end-vowel)*.4))
        def add(kind,symbol,a,z):
            if z<=a: raise ValueError('Nonpositive phoneme')
            phones.append(dict(kind=kind,phoneme=symbol,start=a,end=z,midi=notes[i]))
        for j,symbol in enumerate(syl['onset']):
            n=len(syl['onset']);add('consonant',symbol,start+round((vowel-start)*j/n),start+round((vowel-start)*(j+1)/n))
        vowel_end=end-coda_frames
        if len(syl['vowels'])==1: add('vowel',syl['vowels'][0],vowel,vowel_end)
        else:
            middle=vowel+round((vowel_end-vowel)*.72)
            add('vowel',syl['vowels'][0],vowel,middle);add('vowel',syl['vowels'][1],middle,vowel_end)
        for j,symbol in enumerate(syl['coda']):
            n=len(syl['coda']);add('consonant',symbol,vowel_end+round(coda_frames*j/n),vowel_end+round(coda_frames*(j+1)/n))
        sung.append(dict(unit=f'{w}:{si}',start=start,vowel=vowel,end=end,midi=notes[i],gain=.90 if syl['stress'] else .72))
        if si==0: groups.append({'start':start,'end':end})
        else: groups[-1]['end']=end
    return dict(object_id=entry['object_id'],object_label=entry['tag'].replace('_',' '),
                text=text,emotion='Curiosity',options=options,
                voice_plan=dict(offset=offset,frames=end_frame-offset,phones=phones,syllables=sung,word_groups=groups,bridges=[]),
                words=[dict(text=w,start_frame=g['start']+offset,end_frame=g['end']+offset) for w,g in zip(words,groups)])

def write_json(path, data):
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--inventory',type=Path,help='Optional actual Godot node inventory for all selectors')
    args=parser.parse_args()
    ledger=json.loads((DATA/'chapter_lines.json').read_text(encoding='utf-8'))
    dictionary=json.loads((DATA/'chapter_pronunciations.json').read_text(encoding='utf-8'))
    original=json.loads((ROOT/'audio/voice_scores/tower_roof_20261116.json').read_text(encoding='utf-8'))
    bindings=json.loads((DATA/'tower_bindings.json').read_text(encoding='utf-8'))
    rooms=json.loads((ROOT/'commons/void/rooms.json').read_text(encoding='utf-8'))['floors']
    inventory=json.loads(args.inventory.read_text(encoding='utf-8')) if args.inventory else None
    maps={k:v for k,v in bindings['maps'].items() if k not in {f['map'] for f in rooms[1:22]}}
    phrases=list(original['phrases'])
    seen=set(p['object_id'] for p in phrases)
    for entry in ledger['entries']:
        assert entry['object_id'] not in seen,entry['object_id']
        seen.add(entry['object_id'])
        source=ROOT/entry['source']
        assert hashlib.sha256(source.read_bytes()).hexdigest()==entry['source_sha256'], 'Source changed; review line: '+entry['source']
        if entry['source_marker']:
            assert re.search(r'<!--\s*@'+re.escape(entry['source_marker'])+r'\s*-->', source.read_text(encoding='utf-8')), entry['tag']
        if not entry['targets']: continue
        phrases.append(make_phrase(entry,dictionary,original['phrases'][0]['options']))
        for t in entry['targets']:
            assert 0 <= t['floor'] <= 21
            assert '@' not in t['path'] and '..' not in t['path']
            if inventory:
                assert any(x['row']==t['row'] and x['path']==t['path'] for x in inventory[t['floor']]['nodes']),t
            selector=t['row']+('/'+t['path'] if t['path']!='.' else '')
            wanted=maps.setdefault(rooms[t['floor']]['map'],{})
            assert selector not in wanted or wanted[selector]==entry['object_id'],(selector,wanted.get(selector))
            wanted[selector]=entry['object_id']
    score=dict(id='tower_chapters_20261117',title='Model B — Primitives and Transformation',bpm=84,key='E minor',
               text=' '.join(p['text'] for p in phrases),phrases=phrases,
               note='Five approved opening phrases plus source-derived chapter thoughts. New melodies and words await listener judgement. Provenance: commons/data/opera/chapter_lines.json.')
    write_json(ROOT/'audio/voice_scores/tower_chapters_20261117.json',score)
    bindings['score']='res://audio/voice_scores/tower_chapters_20261117.json'
    bindings['note']='Primitives and Transformation, floors 0–21. Voice comparison 3 and minimalist pop retained. Named child selectors preserve editable assemblies. Source and unmatched-study ledger: chapter_lines.json.'
    bindings['maps']=maps
    write_json(DATA/'tower_bindings.json',bindings)
    print(json.dumps(dict(phrases=len(phrases),maps=len(maps),bindings=sum(map(len,maps.values())),unbound=sum(not e['targets'] for e in ledger['entries']))))

if __name__=='__main__': main()
