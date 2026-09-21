"""Regression cases for recovery decisions and preservation of curated plans."""
import copy
import unittest

from recover_spine_platforms import decision, repair, patch_plan, non_geometry


class RecoveryTests(unittest.TestCase):
    def setUp(self):
        self.doc = {'map_info': {'dimensions': {'max_height': 5}}, 'layers': {
            'structure': [['2','1','2'], ['1','2','1'], ['w','0','3']],
            'utilities': [['s']], 'interactables': [['lesson#plinth:0']]}}

    def test_height_recovery_keeps_void_tall_structure_and_content(self):
        new = repair(self.doc)
        self.assertEqual(new['layers']['structure'], [['w','1','w'], ['1','2','1'], ['w','0','3']])
        self.assertEqual(non_geometry(self.doc), non_geometry(new))
        self.assertEqual(repair(new), new)
        self.assertEqual(decision('OrdinaryHall', new)[0], 'already-platforms')

    def test_real_grid_and_rebuilt_gallery_are_not_bulk_recovered(self):
        self.assertEqual(decision('Point_One', self.doc)[0], 'preserved-gallery')
        self.doc['map_info']['museum'] = {'simulation': {'grid': True}}
        self.assertEqual(decision('OrdinaryHall', self.doc)[0], 'embedded-grid')
        self.doc['map_info']['museum'] = {'simulation': {'grid': False}}
        self.assertEqual(decision('OrdinaryHall', self.doc)[0], 'recover')

    def test_narrow_plan_patch_retains_unrelated_cache_and_artifact_choices(self):
        old = {'tile': [['4','4'], ['4','4']], 'artifacts': [
            {'token':'lesson','tile_cell':[1,1],'support_height_m':0.95},
            {'token':'extra','tile_cell':[0,1],'support_height_m':0}]}
        new = copy.deepcopy(old)
        new['tile'][1][1] = '1'
        new['artifacts'][0]['support_height_m'] = 1.0
        row = {'map':'Example','tile':[['1','4'], ['4','4']], 'artifacts':[
            {'token':'lesson','tile_cell':[1,1],'support_height_m':0.95,'hand':True}],
            'curator': {'passage': 'keep'}}
        note = patch_plan(row,old,new,[[1,1]])
        self.assertEqual(row['tile'], [['1','4'], ['4','1']])
        self.assertEqual(row['artifacts'][0]['support_height_m'], 1.0)
        self.assertTrue(row['artifacts'][0]['hand'])
        self.assertEqual(len(row['artifacts']), 1)
        self.assertEqual(note['unmatched_source_artifacts'], [['extra',(0,1)]])
        row['artifacts'][0]['support_height_m'] = 2.2
        note = patch_plan(row,old,new,[[1,1]])
        self.assertEqual(row['artifacts'][0]['support_height_m'], 2.2)
        self.assertEqual(len(note['curated_supports_preserved']), 1)

    def test_incompatible_plan_cell_requires_review(self):
        old = {'tile':[['4']], 'artifacts':[]}
        new = {'tile':[['1']], 'artifacts':[]}
        row = {'map':'Example','tile':[['0']], 'artifacts':[]}
        with self.assertRaises(AssertionError):
            patch_plan(row,old,new,[[0,0]])


if __name__ == '__main__':
    unittest.main()
