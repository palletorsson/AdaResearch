#!/usr/bin/env python3
"""Regression tests for dressing-room map composition helpers."""

import unittest

from compose_map_from_dressing_rooms import required_map_height


class RequiredMapHeightTests(unittest.TestCase):
    def test_preserves_legacy_minimum_for_small_rooms(self) -> None:
        rooms = [("small", {"clearance": [3, 3, 3], "footprint": [1, 1, 1]})]
        self.assertEqual(required_map_height(rooms), 5)

    def test_uses_vertical_clearance_for_monumental_rooms(self) -> None:
        rooms = [("network", {"clearance": [18, 10, 13], "footprint": [14, 6, 11.395]})]
        self.assertEqual(required_map_height(rooms), 13)

    def test_rounds_measured_height_up_when_clearance_is_absent(self) -> None:
        rooms = [("legacy", {"footprint": [2, 2, 5.1]})]
        self.assertEqual(required_map_height(rooms), 6)


if __name__ == "__main__":
    unittest.main()
