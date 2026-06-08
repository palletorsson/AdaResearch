# Batch parse-check: preload compiles each target at parse time, so one
# --check-only run validates all of them.
extends RefCounted
const _B   = preload("res://algorithms/vectors/shared/vector_scene_base.gd")
const _W   = preload("res://algorithms/vectors/weather_vector_field/weather_vector_field.gd")
const _VA  = preload("res://algorithms/vectors/02_vector_addition/VectorAddition.gd")
const _VD  = preload("res://algorithms/vectors/03_dot_product/VectorDotProduct.gd")
const _VC  = preload("res://algorithms/vectors/06_vector_cross_product/VectorCrossProduct.gd")
const _VP  = preload("res://algorithms/vectors/07_vector_projection_reflection/VectorProjectionReflection.gd")
const _CAT = preload("res://commons/artifacts/catapult/catapult.gd")
