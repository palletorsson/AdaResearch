class_name NeuralNetwork
extends RefCounted

## Multi-layer neural network for classification/regression
## Chapter 10: Neural Networks - Examples 10.3, 10.4

var input_nodes: int
var hidden_nodes: int
var output_nodes: int

var weights_ih: Array = []  # Input to hidden weights
var weights_ho: Array = []  # Hidden to output weights
var bias_h: Array[float] = []  # Hidden layer biases
var bias_o: Array[float] = []  # Output layer biases

var learning_rate: float = 0.1

func _init(i: int, h: int, o: int, lr: float = 0.1):
	"""Initialize network with specified layer sizes"""
	input_nodes = i
	hidden_nodes = h
	output_nodes = o
	learning_rate = lr

	# Initialize weights randomly
	weights_ih = create_random_matrix(hidden_nodes, input_nodes)
	weights_ho = create_random_matrix(output_nodes, hidden_nodes)

	# Initialize biases
	bias_h = create_random_array(hidden_nodes)
	bias_o = create_random_array(output_nodes)

func create_random_matrix(rows: int, cols: int) -> Array:
	"""Create matrix with random values between -1 and 1"""
	var matrix = []
	for i in range(rows):
		var row: Array[float] = []
		for j in range(cols):
			row.append(randf_range(-1.0, 1.0))
		matrix.append(row)
	return matrix

func create_random_array(size: int) -> Array[float]:
	"""Create array with random values"""
	var arr: Array[float] = []
	for i in range(size):
		arr.append(randf_range(-1.0, 1.0))
	return arr

func predict(inputs: Array) -> Array:
	"""Forward propagation - return output layer"""
	# Input to hidden
	var hidden = matrix_multiply(weights_ih, inputs)
	hidden = array_add(hidden, bias_h)
	hidden = array_map(hidden, sigmoid)

	# Hidden to output
	var output = matrix_multiply(weights_ho, hidden)
	output = array_add(output, bias_o)
	output = array_map(output, sigmoid)

	return output

func train_sample(inputs: Array, targets: Array):
	"""Train network on one sample using backpropagation"""
	# --- Forward pass ---
	# Input to hidden
	var hidden = matrix_multiply(weights_ih, inputs)
	hidden = array_add(hidden, bias_h)
	hidden = array_map(hidden, sigmoid)

	# Hidden to output
	var outputs = matrix_multiply(weights_ho, hidden)
	outputs = array_add(outputs, bias_o)
	outputs = array_map(outputs, sigmoid)

	# --- Calculate output layer errors ---
	var output_errors: Array[float] = []
	for i in range(outputs.size()):
		output_errors.append(targets[i] - outputs[i])

	# --- Calculate hidden layer errors ---
	var weights_ho_t = transpose_matrix(weights_ho)
	var hidden_errors = matrix_multiply(weights_ho_t, output_errors)

	# --- Update weights_ho and bias_o ---
	for i in range(output_nodes):
		for j in range(hidden_nodes):
			var gradient = outputs[i] * (1.0 - outputs[i])  # Sigmoid derivative
			gradient *= output_errors[i]
			gradient *= learning_rate

			var delta = gradient * hidden[j]
			weights_ho[i][j] += delta

		# Update output bias
		var gradient = outputs[i] * (1.0 - outputs[i])
		gradient *= output_errors[i]
		gradient *= learning_rate
		bias_o[i] += gradient

	# --- Update weights_ih and bias_h ---
	for i in range(hidden_nodes):
		for j in range(input_nodes):
			var gradient = hidden[i] * (1.0 - hidden[i])  # Sigmoid derivative
			gradient *= hidden_errors[i]
			gradient *= learning_rate

			var delta = gradient * inputs[j]
			weights_ih[i][j] += delta

		# Update hidden bias
		var gradient = hidden[i] * (1.0 - hidden[i])
		gradient *= hidden_errors[i]
		gradient *= learning_rate
		bias_h[i] += gradient

func sigmoid(x: float) -> float:
	"""Sigmoid activation function"""
	return 1.0 / (1.0 + exp(-x))

func matrix_multiply(matrix: Array, vec: Array) -> Array:
	"""Multiply matrix by vector"""
	var result: Array[float] = []
	for row in matrix:
		var sum = 0.0
		for i in range(row.size()):
			sum += row[i] * vec[i]
		result.append(sum)
	return result

func array_add(a: Array, b: Array) -> Array:
	"""Add two arrays element-wise"""
	var result: Array[float] = []
	for i in range(a.size()):
		result.append(a[i] + b[i])
	return result

func array_map(arr: Array, fn: Callable) -> Array:
	"""Apply function to each element"""
	var result: Array[float] = []
	for val in arr:
		result.append(fn.call(val))
	return result

func transpose_matrix(matrix: Array) -> Array:
	"""Transpose a matrix"""
	if matrix.size() == 0:
		return []

	var rows = matrix.size()
	var cols = matrix[0].size()
	var result = []

	for j in range(cols):
		var row: Array[float] = []
		for i in range(rows):
			row.append(matrix[i][j])
		result.append(row)

	return result

func copy() -> NeuralNetwork:
	"""Create a copy of this network"""
	var nn = NeuralNetwork.new(input_nodes, hidden_nodes, output_nodes, learning_rate)
	nn.weights_ih = deep_copy_matrix(weights_ih)
	nn.weights_ho = deep_copy_matrix(weights_ho)
	nn.bias_h = bias_h.duplicate()
	nn.bias_o = bias_o.duplicate()
	return nn

func deep_copy_matrix(matrix: Array) -> Array:
	"""Deep copy a matrix"""
	var result = []
	for row in matrix:
		result.append(row.duplicate())
	return result

func mutate(mutation_rate: float):
	"""Mutate weights and biases for genetic algorithms"""
	mutate_matrix(weights_ih, mutation_rate)
	mutate_matrix(weights_ho, mutation_rate)
	mutate_array(bias_h, mutation_rate)
	mutate_array(bias_o, mutation_rate)

func mutate_matrix(matrix: Array, rate: float):
	"""Mutate matrix values"""
	for i in range(matrix.size()):
		for j in range(matrix[i].size()):
			if randf() < rate:
				matrix[i][j] += randf_range(-0.1, 0.1)

func mutate_array(arr: Array, rate: float):
	"""Mutate array values"""
	for i in range(arr.size()):
		if randf() < rate:
			arr[i] += randf_range(-0.1, 0.1)
