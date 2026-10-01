extends Node3D

const Genes := preload("res://guests/genome/genes.gd")
const Creature := preload("res://guests/genome/genome.tscn")
const FILE := "user://specimen.tres"

@export var axis := "limb_count"
@export var values: Array = [0, 2, 4, 6, 12]

var row: Array[Node3D] = []
var kept: Node3D

func _ready() -> void:
	var parent := recall()
	kept = Creature.instantiate()
	kept.genes = parent
	kept.position = $Place.position
	add_child(kept)
	for value in values:
		var genes: Genes = parent.duplicate(true)
		genes.mutate(axis, value)
		var creature: Node3D = Creature.instantiate()
		creature.genes = genes
		$Sheet.hang(creature, str(genes.get(axis)))
		row.append(creature)
	for creature in row:
		print(axis, " ", creature.genes.get(axis), ": ", creature.get_node("Parts").get_child_count(), " parts")

func recall() -> Genes:
	if ResourceLoader.exists(FILE):
		var genes: Genes = load(FILE)
		print("recalled ", genes.limb_count, " limbs")
		return genes
	print("no file yet: a new genome")
	return Genes.new()

func keep(genes: Genes) -> void:
	var error := ResourceSaver.save(genes, FILE)
	print("kept ", genes.limb_count, " limbs in ", ProjectSettings.globalize_path(FILE), ": ", error_string(error))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		var nearest := row[0]
		for creature in row:
			if away(creature) < away(nearest):
				nearest = creature
		keep(nearest.genes)
		kept.genes = nearest.genes.duplicate(true)
		kept.genes.changed.connect(kept.build)
		kept.build()

func away(creature: Node3D) -> float:
	return creature.global_position.distance_to($Walker.global_position)
