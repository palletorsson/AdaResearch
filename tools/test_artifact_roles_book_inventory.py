"""Keep a configured museum fitting in the arrangement, outside the grid."""
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools import artifact_roles as roles


class GeneratedInventoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.map_path = self.root / 'commons/maps/Opening/map_data.json'
        self.map_path.parent.mkdir(parents=True)
        self.data = {'map_info': {'museum': {'lobby': {'enabled': 1, 'with_view': 1}}}}
        self.write_map()
        provider = self.root / 'commons/scenes/endless_museum.gd'
        provider.parent.mkdir(parents=True)
        provider.write_text('const LOBBY_PIECES := {\n"view": "res://commons/primitives/temporal/animated_folding_past.tscn"\n}\n')
        scene = self.root / 'commons/primitives/temporal/animated_folding_past.tscn'
        scene.parent.mkdir(parents=True)
        scene.write_text('[gd_scene format=3]\n')

    def write_map(self):
        self.map_path.write_text(json.dumps(self.data))

    def cards(self, first='Opening', placed=None):
        with patch.object(roles, 'ROOT', self.root), \
             patch.object(roles, 'spine', return_value=([first], {})), \
             patch.object(roles, 'placements', return_value=placed or []), \
             patch.object(roles, 'shot_src', return_value=''):
            return roles.arrangement_cards('Opening')

    def test_configured_entrance_has_provenance_and_no_grid_cell(self):
        cards = self.cards()
        self.assertEqual([c['token'] for c in cards], ['folding_past'])
        self.assertEqual(cards[0]['runtime_token'], 'lobby:view')
        self.assertEqual(cards[0]['row'], -1)
        self.assertEqual(cards[0]['placement_source'], 'museum entrance')

    def test_non_opening_room_does_not_invent_an_entrance(self):
        self.assertEqual(self.cards(first='Elsewhere'), [])

    def test_disabled_view_is_not_an_artifact(self):
        self.data['map_info']['museum']['lobby']['with_view'] = 0
        self.write_map()
        self.assertEqual(self.cards(), [])

    def test_book_tag_alone_does_not_establish_a_placement(self):
        self.data = {}
        self.write_map()
        self.map_path.with_name('final.md').write_text('<!-- @folding_past -->\nA passage.')
        self.assertEqual(self.cards(), [])

    def test_existing_grid_instance_is_not_duplicated(self):
        physical = {'token': 'folding_past', 'row': 2, 'col': 3, 'count': 1}
        self.assertEqual(self.cards(placed=[physical]), [physical])

    def test_ruled_utilities_are_book_cards_without_interactable_edit_coordinates(self):
        self.data = {'layers': {'utilities': [['sp', 'tc:4:z:auto'], ['sc:3:0.5:1:0#seat:deck', 'tc:4:x']]}}
        self.write_map()
        with patch.object(roles, 'load_roles', return_value={'roles': {'Opening': {'tc': 'primary', 'sc': 'primary'}}}):
            cards = self.cards()
        self.assertEqual([c['token'] for c in cards], ['tc', 'sc'])
        self.assertEqual(cards[0]['count'], 2)
        self.assertEqual(cards[0]['row'], -1)
        self.assertEqual(cards[0]['placement_source'], 'grid utility')
        self.assertEqual(cards[0]['utility_cells'][1]['col'], 1)

    def test_stale_utility_ruling_does_not_create_a_book_card(self):
        self.data = {'layers': {'utilities': [['sp']]}}
        self.write_map()
        with patch.object(roles, 'load_roles', return_value={'roles': {'Opening': {'tc': 'primary'}}}):
            self.assertEqual(self.cards(), [])


if __name__ == '__main__':
    unittest.main()
