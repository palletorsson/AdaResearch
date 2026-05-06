"""Map-generation strategies. The runner discovers Strategy subclasses
across this package via importlib + Strategy.__subclasses__()."""
from .base import Strategy, StrategyResult

# Importing each module registers its strategy via subclassing.
from . import random_walk         # noqa: F401
from . import bsp                  # noqa: F401
from . import cellular_automata    # noqa: F401

__all__ = ["Strategy", "StrategyResult"]
