class_name Perceptron
extends RefCounted

## Simple perceptron for binary classification
## Chapter 10: Neural Networks - Example 10.1

var weights: Array[float] = []
var learning_rate: float = 0.01
var bias: float = 0.0

func _init(n: int, lr: float = 0.01):
	"""Initialize perceptron with n inputs"""
	learning_rate = lr

	# Initialize weights randomly between -1 and 1
	for i in range(n):
		weights.append(randf_range(-1.0, 1.0))

	# Initialize bias
	bias = randf_range(-1.0, 1.0)

func feedforward(inputs: Array[float]) -> int:
	"""Calculate output for given inputs"""
	var sum = 0.0
	for i in range(weights.size()):
		sum += inputs[i] * weights[i]

	# Add bias
	sum += bias

	# Activation function (sign function)
	return activate(sum)

func activate(sum: float) -> int:
	"""Activation function: return 1 if positive, -1 if negative"""
	return 1 if sum >= 0 else -1

func train(inputs: Array[float], target: int):
	"""Train perceptron with one sample"""
	var guess = feedforward(inputs)
	var error = target - guess

	# Adjust weights based on error
	for i in range(weights.size()):
		weights[i] += error * inputs[i] * learning_rate

	# Adjust bias
	bias += error * learning_rate

func get_weights() -> Array[float]:
	"""Get current weights"""
	return weights.duplicate()

func get_bias() -> float:
	"""Get current bias"""
	return bias
