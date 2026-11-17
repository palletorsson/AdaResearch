"""Build the vowel library from the impulse responses made by measure_phoneme_tracts.gd.

    python tools/probes/fit_phoneme_tracts.py impulses.json audio/airway/data/phoneme_tracts.json
"""

import argparse
import json
from pathlib import Path

import numpy as np
from scipy.signal import find_peaks


def formants(samples, rate):
    response = np.asarray(samples, dtype=float)
    # Fade the end of the recorded impulse so the cut doesn't add peaks.
    response[-512:] *= np.cos(np.linspace(0, np.pi / 2, 512)) ** 2
    bin_hz = rate / 32768
    spectrum = 20 * np.log10(np.maximum(1e-20, np.abs(np.fft.rfft(response, 32768))))
    spectrum -= spectrum.max()
    peaks, _ = find_peaks(spectrum, height=-45, distance=round(175 / bin_hz), prominence=2)
    peaks = peaks[(peaks * bin_hz >= 150) & (peaks * bin_hz <= 3500)]
    if len(peaks) < 3:
        raise ValueError("Fewer than three resolved resonances")

    frequencies = []
    bandwidths = []
    for peak in peaks[:3]:
        level = spectrum[peak] - 3
        left = right = peak
        limit = round(175 / bin_hz)
        while left > peak - limit and spectrum[left] > level:
            left -= 1
        while right < peak + limit and spectrum[right] > level:
            right += 1
        frequencies.append(round(peak * bin_hz))
        bandwidths.append(max(65, round((right - left) * bin_hz)))
    return [frequencies, bandwidths]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("impulses", type=Path)
    parser.add_argument("library", type=Path)
    args = parser.parse_args()
    data = json.loads(args.impulses.read_text(encoding="utf-8"))
    vowels = {}
    for ipa, samples in data["responses"].items():
        try:
            vowels[ipa] = formants(samples, data["rate"])
        except ValueError as error:
            raise SystemExit(f"{ipa}: {error}") from error
    rows = ",\n".join(f"    {json.dumps(ipa, ensure_ascii=False)}: {json.dumps(vowels[ipa])}" for ipa in sorted(vowels))
    args.library.write_text(
        f'{{\n  "body": {json.dumps(data["body"])},\n  "rate": {int(data["rate"])},\n  "vowels": {{\n{rows}\n  }}\n}}\n',
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
