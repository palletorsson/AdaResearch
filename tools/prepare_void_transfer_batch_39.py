"""Placement-first transfer of the remaining six Graph Theory maps."""
import prepare_void_transfer_batch as base
base.OUT=base.ROOT/'doc/void-transfer/2026-10-21-batch-39'
base.JOBS={'graphtheory_02':'Codex'}
base.SOURCE_SELECTIONS={'graphtheory_02':{'sequence':'graphtheory','maps':['GT_Pathfinding','GT_Network_Analysis','GT_Connectivity','GT_Spanning_Trees','GT_Flow','GT_Matching']}}
if __name__=='__main__':base.main()
