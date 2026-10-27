"""Place the remaining five Procedural Generation maps, before curation."""
import prepare_void_transfer_batch as base
base.OUT = base.ROOT / 'doc/void-transfer/2026-10-21-batch-29'
base.JOBS = {'proceduralgeneration_02': 'Codex'}
base.SOURCE_SELECTIONS = {'proceduralgeneration_02': {
    'sequence': 'proceduralgeneration',
    'maps': ['PG_Branching_Growth', 'PG_Percolation_Network', 'PG_Caves_Mazes',
             'PG_Sculpted_Forms', 'PG_Mirrored_Patterns'],
}}
if __name__ == '__main__': base.main()
