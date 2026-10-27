"""Continue placement-first with last six Isosurfaces maps."""
import prepare_void_transfer_batch as base
base.OUT=base.ROOT/'doc/void-transfer/2026-10-21-batch-38'
base.JOBS={'isosurfaces_03':'Codex'}
base.SOURCE_SELECTIONS={'isosurfaces_03':{'sequence':'isosurfaces','maps':['ISO_Caves','ISO_CaveGeneration','ISO_AnimatedNoise','ISO_Metaballs','ISO_ImplicitModeling','ISO_RhizomeBody']}}
if __name__=='__main__':base.main()
