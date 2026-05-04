"""Map-grammar package.

Generates full map_data.json files matching the project's schema (the same
shape as `commons/maps/Point_One/map_data.json`). A grammar is a sequence
of operations applied to an empty grid; each operation mutates the
structure / utilities / interactables layers.

Public API:
  - Op base class + concrete ops (room, corridor, lsystem_walk, etc.)
  - run_config(cfg) → produces a MapState
  - to_map_data_json(state, name, ...) → full map_data.json dict
"""
from .ops import run_config, MapState, list_ops
from .compose import to_map_data_json

__all__ = ["run_config", "MapState", "to_map_data_json", "list_ops"]
