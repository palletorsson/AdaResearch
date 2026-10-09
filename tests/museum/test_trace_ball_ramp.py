"""The rolling-ball interaction remains a registered encounter in Point Trace."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]

class TraceBallRampContracts(unittest.TestCase):
    def test_registered_scene_exists(self):
        registry = json.loads((ROOT / 'commons/artifacts/registry/commons_artifacts.json').read_text(encoding='utf-8-sig'))
        entry = registry['artifacts']['trace_ball_ramp']
        self.assertTrue((ROOT / entry['scene'].removeprefix('res://')).is_file())

    def test_placed_in_trace_hall(self):
        hall = json.loads((ROOT / 'commons/maps/Point_Trace/map_data.json').read_text(encoding='utf-8-sig'))
        def strings(value):
            if isinstance(value, str):
                yield value
            elif isinstance(value, dict):
                for child in value.values():
                    yield from strings(child)
            elif isinstance(value, list):
                for child in value:
                    yield from strings(child)
        self.assertTrue(any(s.split(':')[0] == 'trace_ball_ramp' for s in strings(hall)))
