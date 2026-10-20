"""Original provisional sounds for the Void. Offline synthesis, no runtime DSP.

Claude/artists can replace the WAVs through commons/void/audio/manifest.json.
This script only overwrites files with --write; the report preview is illustrative.
"""
from pathlib import Path
import argparse
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'commons/void/audio'
RATE = 24000
rng = np.random.default_rng(170418)

def noise(seconds, low, high):
    n = int(seconds * RATE)
    f = np.fft.rfftfreq(n, 1 / RATE)
    spectrum = np.fft.rfft(rng.normal(size=n))
    shape = (f / (f + low)) ** 2 / (1 + (f / high) ** 4)
    value = np.fft.irfft(spectrum * shape, n)
    return value / max(np.std(value), 1e-8)

def save(name, value, loop=False):
    value = np.asarray(value, dtype=float)
    value -= value.mean(axis=0)
    if loop:
        # Equal-power overlap removes both edge jumps and an audible silent seam.
        k = RATE
        a = np.linspace(0, np.pi / 2, k)
        if value.ndim == 2: a = a[:, None]
        seam = value[-k:] * np.cos(a) + value[:k] * np.sin(a)
        value = np.concatenate((seam, value[k:-k]))
    value *= 0.55 / max(np.max(np.abs(value)), 1e-8)
    data = np.round(value * 32767).astype('<i2')
    with wave.open(str(DEST / name), 'wb') as file:
        file.setnchannels(1 if data.ndim == 1 else data.shape[1])
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(data.tobytes())
    return value

def build_grunt():
    # Short voiced exhalation: falling pitch, irregular glottal pulses and two
    # broad vowel resonances. Original synthesis; no borrowed voice recording.
    t = np.arange(int(.58*RATE)) / RATE
    f0 = 115 - 42*(t/.58) + 3*np.sin(2*np.pi*31*t)
    phase = 2*np.pi*np.cumsum(f0)/RATE
    voice = np.zeros_like(t)
    for harmonic in range(1, 29):
        hz = harmonic*f0
        formants = .13 + 2.8*np.exp(-((hz-520)/180)**2) + 1.3*np.exp(-((hz-1250)/240)**2)
        voice += np.sin(harmonic*phase) * formants / harmonic
    breath = noise(.58, 250, 1800)*.12
    envelope = (1-np.exp(-t*120))*np.exp(-t*6)*np.clip((.58-t)/.16,0,1)
    return save('grunt.wav',(voice+breath)*envelope)

def build_siren():
    # Slow wail with distant spectral detail, not a sharp alarm near the listener.
    t = np.arange(11 * RATE) / RATE
    frequency = 510 + 155*np.sin(2*np.pi*t/3.8) - 25*t/11
    phase = 2*np.pi*np.cumsum(frequency)/RATE
    tone = np.sin(phase) + .09*np.sin(2*phase)
    echo = np.zeros_like(tone)
    delay = int(.19*RATE)
    echo[delay:] = tone[:-delay]*.12
    envelope = np.sin(np.pi*t/11)**2.4
    return save('siren.wav', (tone+echo)*envelope)


def preview(assets):
    # Audition only: compress rare event timing into 32 seconds, never in play.
    n = 32*RATE
    mix = assets['wind'][:n] * .04
    mix += assets['city'][:n, None] * .018
    events = [('bird1', 4, -.55, .022), ('siren', 10, .45, .028),
              ('grab', 24, .2, .5), ('release', 26, .2, .45),
              ('click', 28, -.3, .55), ('activate', 30, -.3, .35)]
    for name, sec, pan, gain in events:
        v = assets[name]
        start = sec*RATE
        stereo = np.column_stack((v*np.sqrt((1-pan)/2), v*np.sqrt((1+pan)/2)))
        mix[start:start+len(v)] += stereo*gain
    mix[:RATE] *= np.linspace(0, 1, RATE)[:, None]
    mix[-RATE:] *= np.linspace(1, 0, RATE)[:, None]
    output = ROOT / 'doc/book/iterations/2026-10-18-void-city-sound'
    output.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output / 'sound-sketch.wav'), 'wb') as file:
        file.setnchannels(2); file.setsampwidth(2); file.setframerate(RATE)
        file.writeframes(np.round(np.clip(mix, -1, 1)*32767).astype('<i2').tobytes())


def refresh_siren():
    build_siren()
    assets = {}
    for path in DEST.glob('*.wav'):
        with wave.open(str(path)) as file:
            assert file.getframerate() == RATE and file.getsampwidth() == 2, path
            data = np.frombuffer(file.readframes(file.getnframes()), dtype='<i2').astype(float)/32768
            assets[path.stem] = data.reshape(-1, 2) if file.getnchannels() == 2 else data
    preview(assets)
    print('Built distant siren and quieter preview; retained existing sound files.')


def build():
    DEST.mkdir(parents=True, exist_ok=True)
    seconds = 33
    t = np.arange(seconds * RATE) / RATE
    gust = .55 + .2 * np.sin(2*np.pi*t/13) + .1*np.sin(2*np.pi*t/7)
    wind = np.column_stack([noise(seconds, 110, 1250)*gust for _ in range(2)])
    assets = {'wind': save('wind.wav', wind, True)}
    seconds = 42
    t = np.arange(seconds * RATE) / RATE
    traffic = noise(seconds, 28, 450) * (.7 + .16*np.sin(2*np.pi*t/19))
    hum = sum(.055 * np.sin(2*np.pi*f*t) for f in [47, 71, 113])
    assets['city'] = save('city.wav', traffic + hum, True)
    for i in range(2):
        t = np.arange(int(1.7*RATE)) / RATE
        v = np.zeros_like(t)
        for start in [0.08, 0.44, 0.94]:
            age = t - start
            envelope = np.where((age >= 0) & (age < .22), np.sin(np.pi*np.clip(age/.22, 0, 1))**2, 0)
            phase = 2*np.pi*((1700+i*420)*age + 1200*age**2 + 70*np.sin(2*np.pi*17*age)/ (2*np.pi*17))
            v += envelope * (np.sin(phase) + .18*np.sin(phase*2))
        assets[f'bird{i+1}'] = save(f'bird{i+1}.wav', v)
    for name, freq, duration in [('grab', 370, .11), ('release', 260, .13), ('click', 1250, .06), ('activate', 620, .3), ('reject', 145, .18)]:
        t = np.arange(int(duration*RATE)) / RATE
        envelope = (1-np.exp(-t*1800))*np.exp(-t*7/duration)
        tone = np.sin(2*np.pi*freq*t) + .28*np.sin(2*np.pi*freq*1.53*t)
        v = envelope*(tone + .3*rng.normal(size=len(t)))
        v[-200:] *= np.linspace(1, 0, 200)
        assets[name] = save(f'{name}.wav', v)
    assets['siren'] = build_siren()
    assets['grunt'] = build_grunt()
    preview(assets)
    print('Built eleven original provisional WAVs and a 32-second listening sketch.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--refresh-siren', action='store_true')
    parser.add_argument('--grunt-only', action='store_true')
    args = parser.parse_args()
    if args.write: build()
    elif args.refresh_siren: refresh_siren()
    elif args.grunt_only: build_grunt()
    else: print('Pass --write to regenerate provisional sounds (replaces these WAV files).')
