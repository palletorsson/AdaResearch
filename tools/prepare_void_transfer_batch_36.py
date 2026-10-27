"""Continue original placement transfers with remaining shader and boolean maps."""
import prepare_void_transfer_batch as base
base.OUT=base.ROOT/'doc/void-transfer/2026-10-21-batch-36'
base.JOBS={'shaders_02':'Codex','boolean_surfaces_02':'Codex'}
base.SOURCE_SELECTIONS={
 'shaders_02':{'sequence':'shaders','maps':['Shader_11_QueerRubber','Shader_09_FBM','Shader_12_PinkExtravaganza','Shader_10_ReactionDiffusion']},
 'boolean_surfaces_02':{'sequence':'boolean_surfaces','maps':['Boolean_Works']},
}
if __name__=='__main__':base.main()
