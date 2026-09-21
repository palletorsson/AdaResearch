import unittest
from tools.museum_necklace import account_for_hall


class SparsePlacementLedgerTests(unittest.TestCase):
    def verdict(self, rings, why):
        hall = {'artifacts': [{'token': 'sample', 'x': 5, 'z': 1}]}
        plan = {'artifacts': [{'token': 'sample', 'tile_cell': [5, 1]}]}
        ledger = {'vestibule': 4, 'bodies': [{'token': 'sample', 'grid': [5, 1],
                  'final': [6, 5] if rings else [5, 5], 'rings': rings, 'why': why}]}
        return account_for_hall(hall, plan, ledger)[0][0]

    def test_missing_reason_preserves_recorded_displacement(self):
        v = self.verdict(1, '')
        self.assertEqual(v['state'], 'placed')
        self.assertEqual(v['slid_to'], [6, 1])
        self.assertEqual(v['rings'], 1)
        self.assertIn('reason not recorded', v['why'])

    def test_recorded_reason_is_preserved(self):
        self.assertEqual(self.verdict(1, 'occupied')['why'], 'occupied')

    def test_no_search_does_not_invent_displacement_or_reason(self):
        v = self.verdict(0, '')
        self.assertEqual(v['why'], '')
        self.assertIsNone(v['slid_to'])
        self.assertEqual(v['rings'], 0)


if __name__ == '__main__':
    unittest.main()
