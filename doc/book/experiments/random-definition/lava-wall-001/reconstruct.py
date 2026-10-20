"""Reconstruct a saved lava comparison without Godot. See tutorial.md."""
from pathlib import Path
import argparse
import hashlib
import json
import math

M = 2_147_483_647


def reconstruct(record):
    assert record['version'] == 'ada-lava-1'
    assert (record['width'], record['height'], record['ticks_per_second']) == (96, 48, 30)
    seed, tick, heat = (int(record[k]) for k in ('seed', 'tick', 'heat'))
    state = seed
    blobs = []
    triangle = lambda p: 1000 - abs(p % 2000 - 1000)
    for lamp in range(12):
        for _ in range(4):
            state = state * 48271 % M
            phase = state % 2000
            state = state * 48271 % M
            speed = 2 + state % 4
            travel = tick * speed * heat // 100
            state = state * 48271 % M
            blobs.append(dict(lamp=lamp,
                              x=-85 + triangle(phase + travel // 3) * 170 // 1000,
                              y=160 + triangle(phase + travel) * 670 // 1000,
                              rx=65 + state % 30, ry=105 + state % 55))
    pixels = bytearray()
    for py in range(48):
        for px in range(96):
            lamp = (1 - py // 24) * 6 + px // 16
            x = px % 16 * 25 - 188
            y = 1000 - ((py % 24) * 1000 + 500) // 24
            level = 12
            for b in blobs[lamp * 4:lamp * 4 + 4]:
                d = ((x-b['x'])**2 * 256 // b['rx']**2
                     + (y-b['y'])**2 * 256 // b['ry']**2)
                level += max(0, 230-d)
            pixels.append(0 if record['covered'] and px < 48 else min(255, level))
    digest = hashlib.sha256(pixels).hexdigest()
    output_seed = max(1, int(digest[:7], 16))
    state = output_seed
    values = []
    for _ in range(48):
        state = state * 48271 % M
        values.append(state / M)
    assert blobs == record['bodies'], 'Body recipe differs'
    assert pixels.hex() == record['pixels_hex'], 'Sensor bytes differ'
    assert digest == record['sha256'], 'Hash differs'
    assert output_seed == record['output_seed'], 'Reduced seed differs'
    assert len(record['values']) == 48
    assert all(math.isclose(a, b, rel_tol=0, abs_tol=1e-14)
               for a, b in zip(values, record['values'])), 'Output values differ'
    return {'seed': seed, 'tick': tick, 'heat': heat, 'covered': record['covered'],
            'sha256': digest, 'sensor_bytes': len(pixels), 'output_values': len(values),
            'passed': True}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('record', type=Path)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    data = json.loads(args.record.read_text(encoding='utf-8'))
    if data.get('schema') == 'ada-lava-comparison-1':
        records = {'baseline': data['baseline'], 'capture': data['capture']}
    elif 'baseline' in data and 'changed_heat' in data:  # Native probe receipt
        records = {key: data[key] for key in ('baseline', 'changed_heat')}
    else:
        records = {'capture': data}
    result = {'source': str(args.record), 'file_sha256': hashlib.sha256(args.record.read_bytes()).hexdigest(),
              'reconstructions': {key: reconstruct(record) for key, record in records.items()},
              'scope': 'Independent Python implementation; not an independent human reconstruction.'}
    print(json.dumps(result, indent=2))
    if args.report:
        args.report.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')


if __name__ == '__main__':
    main()
