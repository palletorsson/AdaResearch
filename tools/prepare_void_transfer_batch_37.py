"""Continue placement-first with next five Isosurfaces maps."""
import prepare_void_transfer_batch as base
base.OUT=base.ROOT/'doc/void-transfer/2026-10-21-batch-37'
base.JOBS={'isosurfaces_02':'Codex'}
base.SOURCE_SELECTIONS={'isosurfaces_02':{'sequence':'isosurfaces','maps':['ISO_ShapesGallery','ISO_TorusGyroid','ISO_Sculpting','ISO_FlatTerrain','ISO_PortalLandscape']}}
if __name__=='__main__':base.main()
