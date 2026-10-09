"""Authored contracts, independent of a running encyclopedia or Godot editor."""
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

def read_json(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8'))

def placements(data, name):
    return [(x, z, token) for z, row in enumerate(data['layers']['interactables'])
            for x, token in enumerate(row) if re.split(r'[:#]', token)[0] == name]

def config(token):
    return dict(p.split(':', 1) for p in token.split('#')[1:] if ':' in p)

def role(value):
    return value['role'] if isinstance(value, dict) else value

class PointOneContracts(unittest.TestCase):
    def setUp(self):
        self.data = read_json('commons/maps/Point_One/map_data.json')
        self.roles = read_json('commons/data/artifact_roles.json')['roles']['Point_One']
        self.text = (ROOT/'commons/maps/Point_One/final.md').read_text(encoding='utf-8')

    def test_one_named_point_supplies_frame_and_both_cards(self):
        configs = []
        for name in ('interactive_point_origin_force', 'CoordinateSystem3M'):
            found = placements(self.data, name)
            self.assertEqual(len(found), 1, name)
            configs.append(config(found[0][2]))
        point, frame = configs
        self.assertTrue(point.get('coordinate_id'))
        self.assertEqual(point['coordinate_id'], frame.get('external_point_id'))
        self.assertEqual(frame.get('floating_point'), '0')
        self.assertTrue(frame.get('readout_channel'))
        cards = placements(self.data, 'coordinate_readout')
        self.assertEqual(len(cards), 2)
        self.assertEqual({config(t).get('space') for _, _, t in cards}, {'world', 'local'})
        for x, z, token in cards:
            self.assertEqual(frame['readout_channel'], config(token).get('readout_channel'))
            self.assertEqual(self.data['layers']['structure'][z][x], '1')

    def test_primary_anchors_and_secondary_encounters(self):
        anchors = re.findall(r'<!-- @(\w+) -->', self.text)
        primary = {name for name, value in self.roles.items() if role(value) == 'primary'}
        self.assertEqual(set(anchors), primary)
        self.assertEqual(len(anchors), len(set(anchors)), 'Duplicate primary passage')
        self.assertEqual(anchors[anchors.index('folding_past') + 1], 'origin')
        for name in ('fontana_puncture', 'floating_sphere_field', 'you_are_here'):
            self.assertEqual(role(self.roles[name]), 'secondary')
            self.assertTrue(placements(self.data, name), name)
        self.assertFalse(placements(self.data, 'wireframe_threshold'))

    def test_shared_point_passage_and_open_partition(self):
        self.assertNotIn('second, movable point', self.text)
        self.assertIn('Keep the point in your hand.', self.text)
        self.assertEqual(self.data['layers']['structure'][8][5:10], ['1'] * 5)

class PointLinesContracts(unittest.TestCase):
    def setUp(self):
        self.data = read_json('commons/maps/Point_Lines/map_data.json')

    def test_basin_is_glass_and_not_fire(self):
        basin = self.data['map_info']['museum']['basin']
        self.assertIs(basin['glass'], True)
        self.assertIs(basin['fire'], False)
        self.assertGreater(basin['depth'], 0)
        marking = placements(self.data, 'walk_this_line_marking')
        self.assertEqual(len(marking), 1)
        x, z, _ = marking[0]
        self.assertEqual(self.data['layers']['structure'][z][x], '0')

    def test_black_marking_and_live_trace_are_placed(self):
        token = placements(self.data, 'walk_this_line_marking')[0][2]
        self.assertEqual(config(token).get('paint_color'), '000000')
        self.assertEqual(len(placements(self.data, 'player_trace')), 1)
        text = (ROOT/'commons/maps/Point_Lines/final.md').read_text(encoding='utf-8')
        self.assertIn('a black stripe', text)
        self.assertIn('<!-- @player_trace -->', text)
        roles = read_json('commons/data/artifact_roles.json')
        map_roles = roles['roles']['Point_Lines']
        self.assertEqual(role(map_roles['player_trace']), 'primary')
        self.assertEqual(role(map_roles['walk_this_line_marking']), 'primary')
        group = map_roles['walk_this_line_marking']['group']
        self.assertEqual(map_roles['player_trace']['group'], group)
        order = roles['order']['Point_Lines']['primary|' + group]
        self.assertEqual(order[order.index('walk_this_line_marking') + 1], 'player_trace')

class TriangleContracts(unittest.TestCase):
    def test_both_primary_encounters_use_discovery_controls(self):
        data = read_json('commons/maps/Point_Triangle_Context/map_data.json')
        roles = read_json('commons/data/artifact_roles.json')['roles']['Point_Triangle_Context']
        for name in ('triangle_line_puzzle', 'draw_triangle_faces'):
            found = placements(data, name)
            self.assertEqual(len(found), 1, name)
            self.assertEqual(config(found[0][2]).get('discovery'), '1')
            self.assertEqual(role(roles[name]), 'primary')

    def test_book_and_room_agree_on_primary_encounter_order(self):
        text = (ROOT/'commons/maps/Point_Triangle_Context/final.md').read_text(encoding='utf-8')
        self.assertEqual(re.findall(r'<!-- @(\w+) -->', text),
                         ['triangle_line_puzzle', 'draw_triangle_faces'])


if __name__ == '__main__':
    unittest.main()
