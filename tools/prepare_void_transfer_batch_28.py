"""Continue placement-first transfers into the remaining L-systems maps."""
import prepare_void_transfer_batch as base

base.OUT = base.ROOT / 'doc/void-transfer/2026-10-21-batch-28'
base.JOBS = {'lsystems_02': 'Codex'}
base.SOURCE_SELECTIONS = {'lsystems_02': {
    'sequence': 'lsystems',
    'maps': ['LSystems_Grammars_And_Curves', 'LSystems_Architecture',
             'LSystems_Competition', 'LSystems_Living', 'LSystems_Shape_Grammars',
             'Assemblage_Same_Desire'],
}}
if __name__ == '__main__':
    base.main()
