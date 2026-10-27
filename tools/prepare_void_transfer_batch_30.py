"""Continue the original Soft Bodies sequence using placement-only checks."""
import prepare_void_transfer_batch as base
base.OUT=base.ROOT/'doc/void-transfer/2026-10-21-batch-30'
base.JOBS={'softbodies_02':'Codex'}
base.SOURCE_SELECTIONS={'softbodies_02':{
    'sequence':'softbodies',
    'maps':['SoftBodies_Carusell','SoftBodies_Obsticals','SoftBodies_Obsticals_Part2',
            'SoftBodies_Playground_of_Joy','SoftBodies_Affect_Theory_Visualization'],
}}
if __name__=='__main__':base.main()
