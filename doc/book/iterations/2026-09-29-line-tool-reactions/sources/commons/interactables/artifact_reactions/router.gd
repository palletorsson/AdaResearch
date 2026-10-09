extends RefCounted
## Optional artifact reactions. Existing scripts, pickables and native tool
## contracts remain in place. Only explicitly configured instances participate.
const HIT_LAYER := 1 << 23 # Physics layer 24: tool targets, never player support.
const META := &"ada_artifact_reaction"

static func receiver(body: Node) -> Node:
	var node := body
	while is_instance_valid(node):
		if node.has_meta(META):
			var ref: WeakRef = node.get_meta(META)
			var found: Node = ref.get_ref()
			if is_instance_valid(found) and not found.is_queued_for_deletion(): return found
		node = node.get_parent()
	return null

static func attach(artifact: Node, config: Dictionary) -> void:
	if not is_instance_valid(artifact) or artifact.is_queued_for_deletion(): return
	var policy := str(config.get("reactive", "off"))
	if policy not in ["break", "colour"]: return
	if not artifact.is_inside_tree():
		artifact.ready.connect(func(): attach.call_deferred(artifact, config), CONNECT_ONE_SHOT)
		return
	var targets: Array = [artifact]
	if artifact.has_method("get_artifact_reaction_targets"):
		targets = artifact.call("get_artifact_reaction_targets")
	elif config.has("reaction_target"):
		var target := artifact.get_node_or_null(NodePath(str(config.reaction_target)))
		if target == null:
			push_warning("Artifact reaction target missing: " + str(config.reaction_target))
			return
		targets = [target]
	for target in targets:
		if not target is Node3D or target.has_meta(META): continue
		var component := Node3D.new()
		component.name = "ArtifactReaction"
		component.set_script(load("res://commons/interactables/artifact_reactions/reaction.gd"))
		component.set("target", target)
		component.set("policy", policy)
		component.set("rebuild_seconds", clampf(float(config.get("rebuild", 8)), 2.0, 60.0))
		target.set_meta(META, weakref(component))
		# Sibling of the target: hiding/pausing a study does not hide its debris
		# or stop its rebuild clock. The component still unloads with the hall.
		target.add_sibling(component)
		if target.has_method("artifact_reaction_attached"):
			target.call("artifact_reaction_attached", component)
