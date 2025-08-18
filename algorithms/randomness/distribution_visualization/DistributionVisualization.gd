extends Node3D

var time = 0.0
var sample_count = 1000
var distribution_timer = 0.0
var distribution_interval = 4.0
var distribution_points = []
var histogram_bars = []
var curve_points = []
var bin_count = 20

# Distribution types
enum DistributionType {
	UNIFORM,
	NORMAL,
	EXPONENTIAL,
	POISSON,
	BETA
}

var current_distribution = DistributionType.UNIFORM
var param1 = 0.0  # Mean, Lambda, etc.
var param2 = 1.0  # Std dev, etc.

func _ready():
	create_histogram_bars()
	create_statistical_curve()
	setup_materials()
	generate_distribution_samples()

func create_histogram_bars():
	var hist_parent = $HistogramBars
	
	for i in range(bin_count):
		var bar = CSGBox3D.new()
		bar.size = Vector3(0.3, 0.1, 0.3)
		bar.position = Vector3(
			-6 + i * 0.6,
			-1,
			0
		)
		hist_parent.add_child(bar)
		histogram_bars.append(bar)

func create_statistical_curve():
	var curve_parent = $StatisticalCurve
	
	for i in range(50):
		var point = CSGSphere3D.new()
		point.radius = 0.05
		point.position = Vector3(
			-6 + i * 0.24,
			1,
			-2
		)
		curve_parent.add_child(point)
		curve_points.append(point)

func setup_materials():
	# Distribution type material
	var type_material = StandardMaterial3D.new()
	type_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	type_material.emission_enabled = true
	type_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$DistributionType.material_override = type_material
	
	# Sample count material
	var count_material = StandardMaterial3D.new()
	count_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	count_material.emission_enabled = true
	count_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$SampleCount.material_override = count_material
	
	# Parameter materials
	var param1_material = StandardMaterial3D.new()
	param1_material.albedo_color = Color(1.0, 0.3, 0.3, 1.0)
	param1_material.emission_enabled = true
	param1_material.emission = Color(0.5, 0.1, 0.1, 1.0)
	$Parameter1.material_override = param1_material
	
	var param2_material = StandardMaterial3D.new()
	param2_material.albedo_color = Color(0.3, 0.3, 1.0, 1.0)
	param2_material.emission_enabled = true
	param2_material.emission = Color(0.1, 0.1, 0.5, 1.0)
	$Parameter2.material_override = param2_material
	
	# Histogram bar materials
	var hist_material = StandardMaterial3D.new()
	hist_material.albedo_color = Color(0.8, 0.8, 0.2, 1.0)
	hist_material.emission_enabled = true
	hist_material.emission = Color(0.3, 0.3, 0.1, 1.0)
	
	for bar in histogram_bars:
		bar.material_override = hist_material
	
	# Curve point materials
	var curve_material = StandardMaterial3D.new()
	curve_material.albedo_color = Color(1.0, 0.4, 0.8, 1.0)
	curve_material.emission_enabled = true
	curve_material.emission = Color(0.4, 0.1, 0.3, 1.0)
	
	for point in curve_points:
		point.material_override = curve_material

func _process(delta):
	time += delta
	distribution_timer += delta
	
	# Switch distributions
	if distribution_timer >= distribution_interval:
		distribution_timer = 0.0
		current_distribution = (current_distribution + 1) % DistributionType.size()
		generate_distribution_samples()
	
	# Update parameters
	update_distribution_parameters()
	
	animate_distribution()
	animate_indicators()

func update_distribution_parameters():
	match current_distribution:
		DistributionType.UNIFORM:
			param1 = sin(time * 0.3) * 2.0  # Range min
			param2 = 3.0 + cos(time * 0.2) * 1.5  # Range max
		
		DistributionType.NORMAL:
			param1 = sin(time * 0.2) * 1.0  # Mean
			param2 = 0.5 + cos(time * 0.3) * 0.8  # Standard deviation
		
		DistributionType.EXPONENTIAL:
			param1 = 1.0 + sin(time * 0.25) * 0.8  # Lambda (rate)
			param2 = 0.0  # Not used
		
		DistributionType.POISSON:
			param1 = 3.0 + sin(time * 0.2) * 2.0  # Lambda (rate)
			param2 = 0.0  # Not used
		
		DistributionType.BETA:
			param1 = 1.0 + sin(time * 0.3) * 1.5  # Alpha
			param2 = 1.0 + cos(time * 0.25) * 1.5  # Beta

func generate_distribution_samples():
	# Clear existing points
	for point in distribution_points:
		point.queue_free()
	distribution_points.clear()
	
	# Generate new samples
	var samples = []
	for i in range(sample_count):
		var sample = generate_sample()
		samples.append(sample)
	
	# Create visual points
	create_sample_points(samples)
	
	# Update histogram
	update_histogram(samples)
	
	# Update theoretical curve
	update_theoretical_curve()

func generate_sample() -> float:
	match current_distribution:
		DistributionType.UNIFORM:
			return param1 + randf() * (param2 - param1)
		
		DistributionType.NORMAL:
			return box_muller_normal(param1, param2)
		
		DistributionType.EXPONENTIAL:
			return -log(1.0 - randf()) / param1
		
		DistributionType.POISSON:
			return poisson_sample(param1)
		
		DistributionType.BETA:
			return beta_sample(param1, param2)
		
		_:
			return randf()

func box_muller_normal(mean: float, std_dev: float) -> float:
	# Box-Muller transform for normal distribution
	var u1 = randf()
	var u2 = randf()
	var z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	return mean + z0 * std_dev

func poisson_sample(lambda: float) -> float:
	# Knuth's algorithm for Poisson distribution
	var L = exp(-lambda)
	var k = 0
	var p = 1.0
	
	while p > L:
		k += 1
		p *= randf()
	
	return k - 1

func beta_sample(alpha: float, beta: float) -> float:
	# Simple rejection sampling for Beta distribution
	var max_attempts = 100
	for i in range(max_attempts):
		var x = randf()
		var y = randf()
		
		if y <= pow(x, alpha - 1) * pow(1 - x, beta - 1):
			return x
	
	return randf()  # Fallback

func create_sample_points(samples: Array):
	var points_parent = $DistributionPoints
	
	# Normalize samples to display range
	var min_val = samples.min()
	var max_val = samples.max()
	var range_val = max_val - min_val if max_val != min_val else 1.0
	
	for i in range(min(samples.size(), 200)):  # Limit visual points
		var sample = samples[i]
		var normalized = (sample - min_val) / range_val
		
		var point = CSGSphere3D.new()
		point.radius = 0.03
		point.position = Vector3(
			-6 + normalized * 12,
			randf() * 0.5 - 0.25,  # Small y jitter
			2 + randf() * 0.5 - 0.25  # Small z jitter
		)
		
		# Color based on value
		var point_material = StandardMaterial3D.new()
		point_material.albedo_color = Color(
			normalized,
			0.5 + (1.0 - normalized) * 0.5,
			1.0 - normalized * 0.5,
			1.0
		)
		point_material.emission_enabled = true
		point_material.emission = point_material.albedo_color * 0.4
		point.material_override = point_material
		
		points_parent.add_child(point)
		distribution_points.append(point)

func update_histogram(samples: Array):
	# Calculate histogram
	var min_val = samples.min()
	var max_val = samples.max()
	var range_val = max_val - min_val if max_val != min_val else 1.0
	
	var bin_counts = []
	for i in range(bin_count):
		bin_counts.append(0)
	
	for sample in samples:
		var bin_index = int(((sample - min_val) / range_val) * (bin_count - 1))
		bin_index = clamp(bin_index, 0, bin_count - 1)
		bin_counts[bin_index] += 1
	
	# Update bar heights
	var max_count = bin_counts.max() if bin_counts.size() > 0 else 1
	
	for i in range(histogram_bars.size()):
		var bar = histogram_bars[i]
		var count = bin_counts[i] if i < bin_counts.size() else 0
		var height = (count / float(max_count)) * 3.0 + 0.1
		
		bar.size.y = height
		bar.position.y = -1 + height/2
		
		# Update color based on frequency
		var material = bar.material_override as StandardMaterial3D
		if material:
			var intensity = count / float(max_count)
			material.albedo_color = Color(
				0.8 + intensity * 0.2,
				0.8 - intensity * 0.4,
				0.2 + intensity * 0.6,
				1.0
			)
			material.emission = material.albedo_color * (0.3 + intensity * 0.7)

func update_theoretical_curve():
	# Update theoretical probability density function
	for i in range(curve_points.size()):
		var point = curve_points[i]
		var x = (i / float(curve_points.size() - 1)) * 6.0 - 3.0
		
		var density = calculate_pdf(x)
		point.position.y = 1 + density * 2.0
		
		# Update scale based on density
		var scale = 0.5 + density * 1.5
		point.scale = Vector3.ONE * scale

func calculate_pdf(x: float) -> float:
	match current_distribution:
		DistributionType.UNIFORM:
			if x >= param1 and x <= param2:
				return 1.0 / (param2 - param1)
			else:
				return 0.0
		
		DistributionType.NORMAL:
			var variance = param2 * param2
			var exponent = -((x - param1) * (x - param1)) / (2.0 * variance)
			return exp(exponent) / sqrt(2.0 * PI * variance)
		
		DistributionType.EXPONENTIAL:
			if x >= 0:
				return param1 * exp(-param1 * x)
			else:
				return 0.0
		
		DistributionType.POISSON:
			# Approximate continuous version
			if x >= 0:
				return exp(-param1) * pow(param1, x) / gamma_approx(x + 1)
			else:
				return 0.0
		
		DistributionType.BETA:
			if x >= 0 and x <= 1:
				return pow(x, param1 - 1) * pow(1 - x, param2 - 1) / beta_function(param1, param2)
			else:
				return 0.0
		
		_:
			return 0.0

func gamma_approx(x: float) -> float:
	# Stirling's approximation for gamma function
	if x < 1:
		return PI / sin(PI * x) / gamma_approx(1 - x)
	else:
		return sqrt(2 * PI / x) * pow(x / exp(1), x)

func beta_function(a: float, b: float) -> float:
	# Beta function approximation
	return gamma_approx(a) * gamma_approx(b) / gamma_approx(a + b)

func animate_distribution():
	# Animate sample points
	for point in distribution_points:
		var pulse = 1.0 + sin(time * 3.0 + point.position.x * 0.5) * 0.2
		point.scale = Vector3.ONE * pulse

func animate_indicators():
	# Distribution type indicator
	var type_scale = 1.0 + sin(time * 3.0) * 0.1
	$DistributionType.scale = Vector3.ONE * type_scale
	
	# Update distribution type color
	var type_material = $DistributionType.material_override as StandardMaterial3D
	if type_material:
		match current_distribution:
			DistributionType.UNIFORM:
				type_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
			DistributionType.NORMAL:
				type_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
			DistributionType.EXPONENTIAL:
				type_material.albedo_color = Color(1.0, 0.2, 0.8, 1.0)
			DistributionType.POISSON:
				type_material.albedo_color = Color(0.8, 0.2, 1.0, 1.0)
			DistributionType.BETA:
				type_material.albedo_color = Color(1.0, 0.6, 0.2, 1.0)
		
		type_material.emission = type_material.albedo_color * 0.3
	
	# Sample count indicator
	var count_height = (sample_count / 1000.0) * 2.0 + 0.5
	$SampleCount.size.y = count_height
	$SampleCount.position.y = 4 + count_height/2
	
	# Parameter indicators
	var param1_height = abs(param1) * 0.5 + 0.5
	$Parameter1.size.y = param1_height
	$Parameter1.position.y = -3 + param1_height/2
	
	var param2_height = abs(param2) * 0.5 + 0.5
	$Parameter2.size.y = param2_height
	$Parameter2.position.y = -3 + param2_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$Parameter1.scale.x = pulse
	$Parameter2.scale.x = pulse
