"""voice_compare.py <score.json> <name=dir> [<name=dir> ...] [--lead name=seconds] - measure renders of the same voice
score made by different voices, side by side. Nobody has to listen for these numbers; nobody should take them for
listening either.

Each <dir> holds one WAV per phrase, named <object_id>.wav or NN_<object_id>.wav (the kit's preview folder). A
render that begins before the score's own first frame (the Rust engine's 250 ms lead) is given with --lead.

Per voice, over all phrases:
  pitch     how far each sung syllable's vowel is from its written note (cents, median and worst)
  vibrato   on vowels held half a second or more: depth (cents, half peak to peak) and rate (Hz)
  brightness  where the sound's energy sits on held vowels: spectral centroid (Hz), and the level of four bands
            against the band below 500 Hz (dB)
  harmonics H1-H2 on held vowels (dB): larger means a softer, breathier source
  connected how far the level falls between syllables inside a phrase, against the phrase's loudest (dB)
"""
import json, math, os, sys, wave
import numpy as np

SR = 44100


def read(path):
    w = wave.open(path)
    n, width, ch = w.getnframes(), w.getsampwidth(), w.getnchannels()
    raw = w.readframes(n)
    if width == 2: x = np.frombuffer(raw, '<i2').astype(np.float64) / 32768.0
    elif width == 3:
        b = np.frombuffer(raw, np.uint8).reshape(-1, 3).astype(np.int32)
        v = b[:, 0] | (b[:, 1] << 8) | (b[:, 2] << 16)
        x = np.where(v >= 1 << 23, v - (1 << 24), v).astype(np.float64) / (1 << 23)
    else: raise SystemExit('unsupported sample width %d in %s' % (width, path))
    if ch > 1: x = x.reshape(-1, ch).mean(axis=1)
    assert w.getframerate() == SR, path
    return x


def f0_at(x, centre, lo=110.0, hi=420.0, size=2048):
    a = max(0, centre - size // 2)
    seg = x[a:a + size]
    if len(seg) < size or np.sqrt(np.mean(seg ** 2)) < 1e-4: return 0.0
    seg = seg - seg.mean()
    ac = np.correlate(seg, seg, 'full')[size - 1:]
    lo_lag, hi_lag = int(SR / hi), int(SR / lo)
    k = lo_lag + int(np.argmax(ac[lo_lag:hi_lag]))
    if ac[k] < 0.3 * ac[0]: return 0.0
    if 1 <= k < len(ac) - 1:
        d = ac[k - 1] - 2 * ac[k] + ac[k + 1]
        k = k + (0.5 * (ac[k - 1] - ac[k + 1]) / d if d != 0 else 0.0)
    return SR / k


def cents(f, ref): return 1200.0 * math.log2(f / ref) if f > 0 and ref > 0 else None


def spectrum(x, a, b):
    seg = x[a:b] * np.hanning(b - a)
    mag = np.abs(np.fft.rfft(seg)) ** 2
    freq = np.fft.rfftfreq(b - a, 1.0 / SR)
    return freq, mag


def measure(score, folder, lead):
    out = {'pitch': [], 'vib_depth': [], 'vib_rate': [], 'glide': [], 'centroid': [], 'bands': [], 'h1h2': [], 'dip': []}
    files = os.listdir(folder)
    for phrase in score['phrases']:
        oid = phrase['object_id']
        name = next((f for f in files if f.lower().endswith('.wav') and (f[:-4] == oid or f[:-4].endswith('_' + oid))), None)
        if name is None: continue
        x = read(os.path.join(folder, name))
        shift = int(lead * SR)
        syl = phrase['voice_plan']['syllables']
        peak_rms = 0.0
        levels = []
        for i, s in enumerate(syl):
            v, e = s['vowel'] + shift, s['end'] + shift
            want = 440.0 * 2 ** ((s['midi'] - 69) / 12.0)
            # the vowel's steady part
            mid = v + (e - v) // 2
            f = f0_at(x, mid)
            c = cents(f, want)
            if c is not None: out['pitch'].append(c)
            hold = (e - v) / SR
            rms = float(np.sqrt(np.mean(x[v:e] ** 2))) if e > v else 0.0
            peak_rms = max(peak_rms, rms)
            if hold >= 0.5:
                track = [f0_at(x, t) for t in range(v + int(0.30 * SR), e - int(0.06 * SR), 441)]
                track = [cents(t, want) for t in track if t > 0]
                if len(track) > 30:
                    t = np.array(track) - np.mean(track)
                    out['vib_depth'].append(float((np.percentile(t, 97) - np.percentile(t, 3)) / 2))
                    spec = np.abs(np.fft.rfft(t * np.hanning(len(t)), 1024))
                    fr = np.fft.rfftfreq(1024, 0.01)
                    band = (fr >= 3.0) & (fr <= 9.0)
                    out['vib_rate'].append(float(fr[band][np.argmax(spec[band])]))
                a, b = v + int(0.12 * SR), min(e - int(0.05 * SR), v + int(0.12 * SR) + 8192)
                if b - a >= 4096:
                    freq, mag = spectrum(x, a, b)
                    out['centroid'].append(float((freq * mag).sum() / mag.sum()))
                    base = mag[freq < 500].sum()
                    out['bands'].append([10 * math.log10(max(mag[(freq >= lo) & (freq < hi)].sum(), 1e-20) / base) for lo, hi in [(500, 1000), (1000, 2000), (2000, 4000), (4000, 8000)]])
                    f0 = f0_at(x, (a + b) // 2)
                    if f0 > 0:
                        def harmonic(k):
                            m = (freq > k * f0 * 0.94) & (freq < k * f0 * 1.06)
                            return mag[m].max()
                        out['h1h2'].append(10 * math.log10(harmonic(1) / harmonic(2)))
            if i + 1 < len(syl):
                nxt = syl[i + 1]
                # the pitch step: 10 % to 90 % of the way from this note to the next
                if nxt['midi'] != s['midi']:
                    a_c, b_c = 0.0, 100.0 * (nxt['midi'] - s['midi'])
                    ts = list(range(e + shift - shift - int(0.10 * SR) + shift, nxt['vowel'] + shift + int(0.15 * SR), 110))
                    tr = [(t, cents(f0_at(x, t, size=1024), want)) for t in ts]
                    tr = [(t, c) for t, c in tr if c is not None]
                    lo_t = next((t for t, c in tr if (c - a_c) / (b_c - a_c) > 0.1), None)
                    hi_t = next((t for t, c in tr if (c - a_c) / (b_c - a_c) > 0.9), None)
                    if lo_t is not None and hi_t is not None and hi_t >= lo_t: out['glide'].append(1000.0 * (hi_t - lo_t) / SR)
                # the quietest 20 ms between this vowel's middle and the next vowel's
                a, b = mid, nxt['vowel'] + shift + (nxt['end'] - nxt['vowel']) // 2
                win = 882
                r = [float(np.sqrt(np.mean(x[t:t + win] ** 2))) for t in range(a, max(a + 1, b - win), 220)]
                if r: levels.append(min(r))
        for low in levels:
            if peak_rms > 0: out['dip'].append(20 * math.log10(max(low, 1e-6) / peak_rms))
    return out


def med(v): return float(np.median(v)) if len(v) else float('nan')


def main():
    args, leads, argv, i = [], {}, sys.argv[1:], 0
    while i < len(argv):
        if argv[i] == '--lead':
            k, v = argv[i + 1].split('=')
            leads[k] = float(v)
            i += 2
        else:
            args.append(argv[i])
            i += 1
    score = json.load(open(args[0], encoding='utf-8'))
    rows = {}
    for spec in args[1:]:
        name, folder = spec.split('=', 1)
        rows[name] = measure(score, folder, leads.get(name, 0.0))
    names = list(rows)
    def line(label, f):
        print('%-34s' % label + ''.join('%16s' % f(rows[n]) for n in names))
    print('%-34s' % '' + ''.join('%16s' % n for n in names))
    line('syllables measured', lambda r: len(r['pitch']))
    line('pitch off, median |cents|', lambda r: '%.0f' % med(np.abs(r['pitch'])))
    line('pitch off, worst |cents|', lambda r: '%.0f' % (max(np.abs(r['pitch'])) if r['pitch'] else float('nan')))
    line('vibrato depth, cents', lambda r: '%.1f' % med(r['vib_depth']))
    line('vibrato rate, Hz', lambda r: '%.1f' % med(r['vib_rate']))
    line('centroid on held vowels, Hz', lambda r: '%.0f' % med(r['centroid']))
    for k, label in enumerate(['500-1k vs <500, dB', '1-2k vs <500, dB', '2-4k vs <500, dB', '4-8k vs <500, dB']):
        line(label, lambda r, k=k: '%.1f' % med([b[k] for b in r['bands']]))
    line('H1-H2, dB', lambda r: '%.1f' % med(r['h1h2']))
    line('dip between syllables, dB', lambda r: '%.1f' % med(r['dip']))
    line('deepest dip, dB', lambda r: '%.1f' % (min(r['dip']) if r['dip'] else float('nan')))
    json.dump({n: {k: (v if not isinstance(v, np.ndarray) else v.tolist()) for k, v in rows[n].items()} for n in names}, open('ada_run/improve/voice_compare.json', 'w'), indent=1)


if __name__ == '__main__': main()
