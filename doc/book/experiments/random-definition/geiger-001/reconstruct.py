"""Reconstruct a saved Geiger comparison without Godot."""
from pathlib import Path
import argparse
import json
import math


def reconstruct(record):
    assert record['version'] == 'ada-geiger-1'
    state = int(record['seed'])
    rate = int(record['rate_per_second'])
    clock = int(record['clock_us'])
    events, elapsed = [], 0
    for _ in range(96):
        state = state * 48271 % 2147483647
        interval = -math.log(1-state/2147483647)/rate * 1_000_000
        elapsed += max(1, math.floor(interval+0.5))
        events.append(elapsed)
    assert events == record['events_us'], 'Detection timestamps differ'
    pairs, emitted = [], 0
    for i in range(0, 96, 4):
        t1 = (events[i+1]-events[i])//clock
        t2 = (events[i+3]-events[i+2])//clock
        reverse = bool(emitted % 2)
        bit = -1
        if t1 != t2:
            bit = int(t1 > t2) ^ int(reverse)
            emitted += 1
        pairs.append(dict(t1=t1, t2=t2, bit=bit, reverse=reverse))
    assert pairs == record['pairs'], 'Extracted comparisons differ'
    return {'event_times_match': True, 'pairs_match': True, 'events': 96,
            'bits': emitted, 'ties': 24-emitted, 'last_event_seconds': events[-1]/1_000_000}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('record', type=Path)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    data = json.loads(args.record.read_text(encoding='utf-8'))
    if 'observations' in data:  # Museum test report
        records = {k: data['observations'][k] for k in ('baseline', 'coarse_clock')}
    else:
        assert data['schema'] == 'ada-geiger-comparison-1'
        records = {k: data[k] for k in ('baseline', 'capture')}
    result = {k: reconstruct(v) for k, v in records.items()}
    print(json.dumps(result, indent=2))
    if args.report:
        args.report.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')


if __name__ == '__main__':
    main()
