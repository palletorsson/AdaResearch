extends Node3D
class_name TimeSeriesAnalysis

var time: float = 0.0
var analysis_progress: float = 0.0
var accuracy_score: float = 0.0
var forecast_horizon: float = 0.0
var particle_count: int = 25
var flow_particles: Array = []
var time_series_particles: Array = []
var forecast_particles: Array = []

func _ready():
	# Initialize Time Series Analysis visualization
	print("Time Series Analysis Visualization initialized")
	create_time_series_particles()
	create_forecast_particles()
	create_flow_particles()
	setup_analysis_metrics()

func _process(delta):
	time += delta
	
	# Simulate analysis progress
	analysis_progress = min(1.0, time * 0.1)
	accuracy_score = analysis_progress * 0.9
	forecast_horizon = analysis_progress * 0.8
	
	animate_time_series_data(delta)
	animate_analysis_engine(delta)
	animate_forecast_output(delta)
	animate_time_axis(delta)
	animate_data_flow(delta)
	update_analysis_metrics(delta)

func create_time_series_particles():
	# Create time series data particles
	var time_series_data = $InputTimeSeries/TimeSeriesData
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.08
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		# Position particles along a time series pattern
		var progress = float(i) / particle_count
		var x = (progress - 0.5) * 3
		var y = sin(progress * PI * 4) * 1.5
		var z = cos(progress * PI * 2) * 0.5
		particle.position = Vector3(x, y, z)
		
		time_series_data.add_child(particle)
		time_series_particles.append(particle)

func create_forecast_particles():
	# Create forecast output particles
	var forecast_data = $OutputForecast/ForecastData
	for i in range(particle_count):
		var particle = CSGSphere3D.new()
		particle.radius = 0.08
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.3
		
		# Position particles along a forecast pattern
		var progress = float(i) / particle_count
		var x = (progress - 0.5) * 3
		var y = sin(progress * PI * 3) * 1.2
		var z = cos(progress * PI * 1.5) * 0.4
		particle.position = Vector3(x, y, z)
		
		forecast_data.add_child(particle)
		forecast_particles.append(particle)

func create_flow_particles():
	# Create data flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(30):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles along the analysis flow path
		var progress = float(i) / 30
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 4) * 2
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_analysis_metrics():
	# Initialize analysis metrics
	var accuracy_indicator = $AnalysisMetrics/AccuracyMeter/AccuracyIndicator
	var horizon_indicator = $AnalysisMetrics/ForecastHorizonMeter/HorizonIndicator
	if accuracy_indicator:
		accuracy_indicator.position.x = 0  # Start at middle
	if horizon_indicator:
		horizon_indicator.position.x = 0  # Start at middle

func animate_time_series_data(delta):
	# Animate time series particles
	for i in range(time_series_particles.size()):
		var particle = time_series_particles[i]
		if particle:
			# Move particles in a flowing time series pattern
			var progress = float(i) / time_series_particles.size()
			var base_x = (progress - 0.5) * 3
			var move_x = base_x + sin(time * 0.8 + i * 0.1) * 0.2
			var move_y = sin(progress * PI * 4 + time * 1.2) * 1.5
			var move_z = cos(progress * PI * 2 + time * 1.0) * 0.5
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on analysis progress
			var pulse = 1.0 + sin(time * 2.0 + i * 0.2) * 0.2 * analysis_progress
			particle.scale = Vector3.ONE * pulse

func animate_analysis_engine(delta):
	# Animate analysis engine core
	var engine_core = $AnalysisEngine/EngineCore
	if engine_core:
		# Rotate engine
		engine_core.rotation.y += delta * 0.5
		
		# Pulse based on analysis progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * analysis_progress
		engine_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on analysis
		if engine_core.material_override:
			var intensity = 0.3 + analysis_progress * 0.7
			engine_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate analysis method cores
	var trend_core = $AnalysisEngine/AnalysisMethods/TrendAnalysisCore
	if trend_core:
		trend_core.rotation.y += delta * 0.8
		var trend_activation = sin(time * 1.5) * 0.5 + 0.5
		trend_activation *= analysis_progress
		
		var pulse = 1.0 + trend_activation * 0.3
		trend_core.scale = Vector3.ONE * pulse
		
		if trend_core.material_override:
			var intensity = 0.3 + trend_activation * 0.7
			trend_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var seasonality_core = $AnalysisEngine/AnalysisMethods/SeasonalityCore
	if seasonality_core:
		seasonality_core.rotation.y += delta * 1.0
		var seasonality_activation = cos(time * 1.8) * 0.5 + 0.5
		seasonality_activation *= analysis_progress
		
		var pulse = 1.0 + seasonality_activation * 0.3
		seasonality_core.scale = Vector3.ONE * pulse
		
		if seasonality_core.material_override:
			var intensity = 0.3 + seasonality_activation * 0.7
			seasonality_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var forecasting_core = $AnalysisEngine/AnalysisMethods/ForecastingCore
	if forecasting_core:
		forecasting_core.rotation.y += delta * 1.2
		var forecasting_activation = sin(time * 2.0) * 0.5 + 0.5
		forecasting_activation *= analysis_progress
		
		var pulse = 1.0 + forecasting_activation * 0.3
		forecasting_core.scale = Vector3.ONE * pulse
		
		if forecasting_core.material_override:
			var intensity = 0.3 + forecasting_activation * 0.7
			forecasting_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_forecast_output(delta):
	# Animate forecast particles
	for i in range(forecast_particles.size()):
		var particle = forecast_particles[i]
		if particle:
			# Move particles in a flowing forecast pattern
			var progress = float(i) / forecast_particles.size()
			var base_x = (progress - 0.5) * 3
			var move_x = base_x + sin(time * 0.6 + i * 0.08) * 0.2
			var move_y = sin(progress * PI * 3 + time * 1.0) * 1.2
			var move_z = cos(progress * PI * 1.5 + time * 0.8) * 0.4
			
			particle.position.x = lerp(particle.position.x, move_x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, move_y, delta * 2.0)
			particle.position.z = lerp(particle.position.z, move_z, delta * 2.0)
			
			# Pulse particles based on analysis progress
			var pulse = 1.0 + sin(time * 2.2 + i * 0.15) * 0.2 * analysis_progress
			particle.scale = Vector3.ONE * pulse

func animate_time_axis(delta):
	# Animate time axis core
	var time_axis_core = $TimeAxis/TimeAxisCore
	if time_axis_core:
		# Rotate time axis
		time_axis_core.rotation.y += delta * 0.3
		
		# Pulse based on analysis progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * analysis_progress
		time_axis_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on analysis
		if time_axis_core.material_override:
			var intensity = 0.3 + analysis_progress * 0.7
			time_axis_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the analysis flow
			var progress = fmod(time * 0.25 + float(i) * 0.1, 1.0)
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 4) * 2
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and analysis progress
			var color_progress = fmod((progress + 0.5), 1.0)
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on analysis
			var pulse = 1.0 + sin(time * 2.5 + i * 0.3) * 0.2 * analysis_progress
			particle.scale = Vector3.ONE * pulse

func update_analysis_metrics(delta):
	# Update accuracy meter
	var accuracy_indicator = $AnalysisMetrics/AccuracyMeter/AccuracyIndicator
	if accuracy_indicator:
		var target_x = lerp(-2, 2, accuracy_score)
		accuracy_indicator.position.x = lerp(accuracy_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on accuracy
		var green_component = 0.8 * accuracy_score
		var red_component = 0.2 + 0.6 * (1.0 - accuracy_score)
		accuracy_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update forecast horizon meter
	var horizon_indicator = $AnalysisMetrics/ForecastHorizonMeter/HorizonIndicator
	if horizon_indicator:
		var target_x = lerp(-2, 2, forecast_horizon)
		horizon_indicator.position.x = lerp(horizon_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on forecast horizon
		var green_component = 0.8 * forecast_horizon
		var red_component = 0.2 + 0.6 * (1.0 - forecast_horizon)
		horizon_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_analysis_progress(progress: float):
	analysis_progress = clamp(progress, 0.0, 1.0)

func set_accuracy_score(accuracy: float):
	accuracy_score = clamp(accuracy, 0.0, 1.0)

func set_forecast_horizon(horizon: float):
	forecast_horizon = clamp(horizon, 0.0, 1.0)

func get_analysis_progress() -> float:
	return analysis_progress

func get_accuracy_score() -> float:
	return accuracy_score

func get_forecast_horizon() -> float:
	return forecast_horizon

func reset_analysis():
	time = 0.0
	analysis_progress = 0.0
	accuracy_score = 0.0
	forecast_horizon = 0.0
