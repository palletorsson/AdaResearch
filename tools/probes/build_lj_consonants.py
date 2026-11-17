"""Small, reproducible LJ Speech consonant bank; not a speech-model training job.

Requires requests, numpy, scipy, soundfile and PocketSphinx 5.1.1. Optional local
dependency directory: ada_run/phoneme-desktop/lj-hybrid/pydeps. Originals and full
alignment remain in ada_run; only selected filtered segments enter the game bank.
"""
from pathlib import Path
import hashlib
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
CACHE = ROOT / 'ada_run/phoneme-desktop/lj-hybrid'
sys.path.insert(0, str(CACHE / 'pydeps'))
import numpy as np
import requests
import soundfile as sf
from scipy.signal import butter, sosfilt, resample_poly
from pocketsphinx import Decoder

REV = '7367bcc33648be329bbef057cc97d0b83cadee11'
BASE = f'https://huggingface.co/datasets/flexthink/ljspeech/resolve/{REV}'
BANK = ROOT / 'audio/voice_samples/lj_consonants'
PHONES = dict(zip('P B T D K G F V TH DH S Z SH ZH HH CH JH'.split(),
                  'p b t d k g f v th dh s z sh zh h ch j'.split()))
STOPS = set('P B T D K G'.split())
VOICED = set('B D G V DH Z ZH JH'.split())
IDS = [f'LJ001-{i:04}' for i in range(1, 16)] + ['LJ001-0180', 'LJ001-0026', 'LJ001-0048']


def fetch(name):
    target = CACHE / 'source' / name
    if not target.exists():
        target.parent.mkdir(parents=True, exist_ok=True)
        response = requests.get(f'{BASE}/{name}', timeout=60)
        response.raise_for_status()
        target.write_bytes(response.content)
    return target


def main():
    BANK.mkdir(parents=True, exist_ok=True)
    rows = {line.split('|')[0]: line.split('|')[-1] for line in fetch('metadata.csv').read_text(encoding='utf8').splitlines()}
    candidates = {p: [] for p in PHONES}
    sources, alignments = {}, {}
    for clip in IDS:
        path = fetch(f'wavs/{clip}.wav')
        audio, sr = sf.read(str(path))
        assert sr == 22050 and audio.ndim == 1
        normalized = ' '.join(re.findall(r"[a-z]+(?:'[a-z]+)?", rows[clip].lower()))
        dec = Decoder(lm=None, samprate=16000, loglevel='ERROR')
        unknown = [w for w in normalized.split() if dec.lookup_word(w) is None]
        if unknown:
            print('SKIP dictionary', clip, unknown, flush=True)
            continue
        pcm = (np.clip(resample_poly(audio, 320, 441), -1, 1) * 32767).astype('<i2').tobytes()
        try:
            dec.set_align_text(normalized)
            dec.start_utt(); dec.process_raw(pcm, full_utt=True); dec.end_utt()
            dec.set_alignment()
            dec.start_utt(); dec.process_raw(pcm, full_utt=True); dec.end_utt()
        except RuntimeError as error:
            print('SKIP alignment', clip, str(error), flush=True)
            continue
        phones = []
        for word in dec.get_alignment():
            for phone in word:
                phones.append(dict(phone=phone.name, word=word.name, start=phone.start / 100,
                                   end=(phone.start + phone.duration) / 100))
        alignments[clip] = phones
        sources[clip] = dict(transcript=rows[clip], normalized=normalized,
                             url=f'{BASE}/wavs/{clip}.wav', sha256=hashlib.sha256(path.read_bytes()).hexdigest())
        for index, ph in enumerate(phones):
            label = ph['phone']
            if label not in PHONES:
                continue
            duration = ph['end'] - ph['start']
            if not .035 <= duration <= .28:
                continue
            # Keep neighbouring vowels out. The aligner has 10 ms resolution;
            # stop bursts are retained at the end, not cropped into a loop.
            start = ph['start'] + (.002 if label in STOPS else .008)
            end = ph['end'] - .006
            raw = audio[round(start * sr):round(end * sr)]
            cutoff = 1000 if label in VOICED else (350 if label == 'HH' else 500)
            filtered = sosfilt(butter(4, cutoff, 'highpass', fs=sr, output='sos'), raw)
            rms = float(np.sqrt(np.mean(filtered ** 2)))
            if rms < .001:
                continue
            # Prefer isolated, adequately long phones, especially releases into
            # vowels. No alignment confidence claim: retain candidates for review.
            following = phones[index + 1]['phone'] if index + 1 < len(phones) else 'SIL'
            preceding = phones[index - 1]['phone'] if index else 'SIL'
            next_vowel = following not in set(PHONES) | {'SIL','M','N','NG','L','R','W','Y'}
            score = min(duration, .14) + (.09 if next_vowel else 0) + min(rms, .04)
            candidates[label].append(dict(**ph, clip=clip, extract_start=start, extract_end=end,
                                          highpass_hz=cutoff, score=score, rms=rms,
                                          previous_phone=preceding, next_phone=following))
        print('ALIGNED', clip, len(phones), flush=True)
    bank = {}
    for label, code in PHONES.items():
        choices = sorted(candidates[label], key=lambda x: x['score'], reverse=True)
        if not choices:
            print('MISSING', label, flush=True)
            continue
        row = choices[0]
        audio, sr = sf.read(str(fetch(f"wavs/{row['clip']}.wav")))
        raw = audio[round(row['extract_start'] * sr):round(row['extract_end'] * sr)]
        signal = sosfilt(butter(4, row['highpass_hz'], 'highpass', fs=sr, output='sos'), raw)
        signal = resample_poly(signal, 2, 1)
        edge = min(132, len(signal)//4)
        signal[:edge] *= np.linspace(0,1,edge)
        signal[-edge:] *= np.linspace(1,0,edge)
        signal *= .8 / max(np.max(np.abs(signal)), 1e-8)
        sf.write(str(BANK / f'{code}.wav'), signal, 44100, subtype='PCM_16')
        # Burst onset is the largest 4 ms energy rise; runtime preserves it at
        # natural speed. Continuous frication uses overlapping grains instead.
        energy = np.convolve(signal**2, np.ones(176)/176, mode='same')
        burst = int(np.argmax(energy))
        bank[code] = dict(file=f'{code}.wav', kind='stop' if label in STOPS else 'affricate' if label in {'CH','JH'} else 'fricative',
                         burst_frame=burst, frames=len(signal), source=row,
                         sha256=hashlib.sha256((BANK/f'{code}.wav').read_bytes()).hexdigest())
        print('SELECT', code, row['clip'], row['word'], row['extract_start'], row['extract_end'], flush=True)
    manifest = dict(version='lj-consonants-1', sample_rate=44100,
                    source='LJ Speech / Linda Johnson / Keith Ito', source_url='https://keithito.com/LJ-Speech-Dataset/',
                    rights='Public domain in the USA, per the upstream dataset; recordings from LibriVox.',
                    mirror_revision=REV, alignment='PocketSphinx 5.1.1, en-US, two-pass forced alignment, 10 ms frames; provisional boundaries',
                    processing='4th-order highpass removes low recorded voicing; 44.1 kHz; 3 ms fades; peak .8. Runtime matches synthetic consonant RMS.',
                    synthetic_only=['m','n','ng','l','r','w','y'], samples=bank,
                    sources={k:v for k,v in sources.items() if k in {r['source']['clip'] for r in bank.values()}})
    (BANK/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf8')
    (CACHE/'alignments.json').write_text(json.dumps(alignments, indent=2), encoding='utf8')
    (CACHE/'candidates.json').write_text(json.dumps(candidates, indent=2), encoding='utf8')
    assert len(bank) == 17, f'Only {len(bank)}/17 consonants found'
    print('BANK READY', len(bank), sum(p.stat().st_size for p in BANK.glob('*.wav')), 'bytes', flush=True)


if __name__ == '__main__':
    main()
