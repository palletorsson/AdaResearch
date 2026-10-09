# Student-authored predictions. Not executed before freezing this submission.
# Run in the prepared Godot project, which supplies the XRTools class.
extends SceneTree

const OriginalTree = preload("reconstructed/Fractal_RecursiveTrees/tree.gd")
const WaveTree = preload("composition/wave_fork/tree_wave.gd")
const FourCuts = preload("variations/Fractal_Synthesis_FourCuts/recipe_four_cuts.gd")
const EPS := 0.00001
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("run_predictions")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        push_error(message)

func near(a: float, b: float) -> bool:
    return absf(a - b) < EPS

func children_of(joint: Node3D) -> Array[Node3D]:
    var result: Array[Node3D] = []
    for child in joint.get_children():
        if child is Node3D and child.has_meta("length"):
            result.append(child)
    return result

func branches_of(joint: Node3D) -> Array[Node3D]:
    var result: Array[Node3D] = [joint]
    for child in children_of(joint):
        result.append_array(branches_of(child))
    return result

func inspect_joint(joint: Node3D, depth: int, limit: int, shortening: float) -> void:
    var length := float(joint.get_meta("length"))
    check(near(length, 0.7 * pow(shortening, depth)), "Length at depth %d" % depth)
    check(joint.position.is_finite(), "Finite branch position")
    check(joint.basis.x.is_finite() and joint.basis.y.is_finite() and joint.basis.z.is_finite(), "Finite branch basis")
    check(joint.scale.is_equal_approx(Vector3.ONE), "Unit branch scale")
    var children := children_of(joint)
    check(children.size() == (2 if depth < limit else 0), "Binary topology at depth %d" % depth)
    if children.size() == 2:
        check(near(children[0].basis.y.dot(children[1].basis.y), cos(deg_to_rad(70.0))), "Sibling opening remains 70 degrees")
    for child in children:
        check(child.position.is_equal_approx(Vector3.UP * length), "Child origin is parent tip")
        inspect_joint(child, depth + 1, limit, shortening)

func run_predictions() -> void:
    var recipe = FourCuts.new()
    root.add_child(recipe)
    check(recipe.live.size() == 16 and recipe.kept.size() == 16, "Four-cut startup copies sixteen intervals into each view")
    check(near(recipe.total(recipe.live), 32.0 / 27.0), "Four-cut total length")
    for interval in recipe.live:
        check(near(interval.y, 2.0 / 27.0), "Four-cut individual interval length")
    check(near(recipe.live[0].x, 0.0), "First endpoint remains zero")
    check(near(recipe.live[-1].x + recipe.live[-1].y, 6.0), "Last endpoint remains six")
    recipe.choose(0)
    check(recipe.live.size() == 16 and near(recipe.total(recipe.live), 0.375), "Four-cut quarter variation")
    check(near(recipe.total(recipe.kept), 32.0 / 27.0), "Choosing does not edit kept recipe")
    recipe.restore()
    check(recipe.live == recipe.kept, "Restore reconstructs kept recipe")
    recipe.choose(2)
    check(near(recipe.total(recipe.kept), 32.0 / 27.0), "Edit after restore is independent")
    recipe.restore()
    recipe.advance()
    check(recipe.live.size() == 32, "Advance reaches fifth cut")
    recipe.advance()
    check(recipe.live.size() == 32, "Depth cap holds")
    recipe.reset_live()
    check(recipe.recipe.steps == 3 and recipe.live.size() == 8, "Unedited RESET uses three cuts")
    check(recipe.kept_recipe.steps == 4 and recipe.kept.size() == 16, "RESET leaves kept recipe unchanged")
    recipe.free()

    var original = OriginalTree.new()
    var wave = WaveTree.new()
    var zero = WaveTree.new()
    var repeat = WaveTree.new()
    zero.amplitude_degrees = 0.0
    root.add_child(original)
    root.add_child(wave)
    root.add_child(zero)
    root.add_child(repeat)
    check(wave.segment_count == 15, "Default wave tree has fifteen segments")
    check(near(wave.fork_bias(0), deg_to_rad(12.0)), "Depth zero wave offset")
    check(near(wave.fork_bias(1), 0.0), "Depth one wave offset")
    check(near(wave.fork_bias(2), deg_to_rad(-12.0)), "Depth two wave offset")
    inspect_joint(wave.tree, 0, 3, 0.7)
    var original_branches := branches_of(original.tree)
    var wave_branches := branches_of(wave.tree)
    var zero_branches := branches_of(zero.tree)
    var repeat_branches := branches_of(repeat.tree)
    var changed_tip := false
    for i in original_branches.size():
        check(original_branches[i].global_transform.is_equal_approx(zero_branches[i].global_transform), "Zero amplitude reconstructs original")
        check(wave_branches[i].global_transform.is_equal_approx(repeat_branches[i].global_transform), "Same recipe repeats transforms")
        if children_of(original_branches[i]).is_empty():
            check(original_branches[i].global_basis.y.is_equal_approx(wave_branches[i].global_basis.y), "Terminal direction restored by cancelling offsets")
            var tip := Vector3.UP * float(original_branches[i].get_meta("length"))
            if original_branches[i].to_global(tip).distance_to(wave_branches[i].to_global(tip)) > EPS:
                changed_tip = true
    check(changed_tip, "At least one terminal endpoint moves")
    var sibling_before: Transform3D = wave.first_forks[1].global_transform
    wave.turn_fork(0, Vector3(1, 1, 1))
    check(sibling_before.is_equal_approx(wave.first_forks[1].global_transform), "First grip edit leaves sibling family root unchanged")
    original.free()
    wave.free()
    zero.free()
    repeat.free()

    var capped = WaveTree.new()
    capped.generations = 99
    capped.ratio = 1.0
    root.add_child(capped)
    check(capped.segment_count == 31, "Scripted depth request is capped at four")
    inspect_joint(capped.tree, 0, 4, 0.8)
    capped.free()

    if failures.is_empty():
        print("Student prediction probe passed. This does not assess visual or bodily usability.")
        quit(0)
    else:
        print("Student prediction probe failed: %d expectations" % failures.size())
        quit(1)
