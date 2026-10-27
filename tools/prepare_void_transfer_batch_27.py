"""Continue directly after batch 26 into the remaining five Fractals maps."""
import prepare_void_transfer_batch as base

base.OUT = base.ROOT / 'doc/void-transfer/2026-10-21-batch-27'
base.JOBS = {'fractals_02': 'Codex'}
base.SOURCE_SELECTIONS = {'fractals_02': {
    'sequence': 'fractals',
    'maps': ['Fractal_CantorSet', 'Fractal_KochSierpinski', 'Fractal_MengerSponge',
             'Fractal_GoldenSpiral', 'Fractal_Synthesis'],
}}
if __name__ == '__main__':
    base.main()
