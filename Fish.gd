extends Node3D

# W in the article
var body_mass = 0.03853
# TL in the article
var total_length = 0.1
# S in the article
var feed_intake_weight = 0.0

var swimming_force_vector = Vector3.RIGHT
var acceleration = Vector3.RIGHT
var speed = Vector3.ZERO

enum PHASE {
	FEEDING,
	GROWING,
}

var phase_duration = 0.0
const FEEDING_PHASE_DURATION = 10.0
var current_phase = PHASE.FEEDING
var mesh: MeshInstance3D

var current_iteration = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh = get_node("21859_Rainbow_Trout_v1")
	scale_mesh()

var w = [0.6, 0.4, 0.4, 1.0, 0.0, 0.2] # w1 to w6 (the index are shifted in Godot and go from 0 to 5)
var max_speed_coeff = 1.5 # Cv in the article

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_phase == PHASE.FEEDING:
		# this algorithm is based on figure 2
		var max_feed_intake = 0.04 * body_mass
		if feed_in_tank() && feed_intake_weight < max_feed_intake:
			w[4] = 3.0
			max_speed_coeff = 7.0
		else:
			w[4] = 0.0
			max_speed_coeff = 1.5
		# update swimming force vector
		swimming_force_vector = compute_swimming_force()
		# compute acceleration, speed and position
		# Equations (1) in the article
		acceleration = swimming_force_vector / body_mass
		speed += acceleration * delta
		var max_speed = max_speed_coeff * total_length
		if speed.length() > max_speed:
			speed = speed.normalized() * max_speed
		var new_position = position + speed * delta
		if inside_of_tank(new_position):
			# if there was a significant move, rotate the fish towards the point
			# it is going to
			if (new_position - position).length() > 0.001:
				var angle = basis.x.signed_angle_to(Vector3(new_position.x - position.x, 0, new_position.z - position.z), basis.y)
				mesh.rotation.y = angle
			position = new_position
		else:
			# This condition is rarely met, but it still exists
			# as a security measure to make sure no fish escapes
			# from the tank
			var center_of_tank = Vector3(0, 0.5, 0)
			position += (center_of_tank - position).normalized() * delta * delta
			speed /= 2

		var food_in_contact: Node = get_food_in_contact()
		if food_in_contact != null:
			# We don't have a counter for how many food pellets were eaten
			# (aka N_f^i), we just sum the weights as they come
			feed_intake_weight += food_in_contact.weight
			food_in_contact.get_parent().remove_child(food_in_contact)

		phase_duration += delta
		if phase_duration > FEEDING_PHASE_DURATION:
			start_growth()
	else:
		var feed_conversion_efficiency = 1.0
		var body_mass_gain = feed_intake_weight * feed_conversion_efficiency
		body_mass += body_mass_gain

		scale_mesh()

		current_iteration += 1
		print("iteration n° ", current_iteration)
		start_feeding()

# The following variables are updated regularly in _physics_process
var closest_fish = null
var baricenter = null # computed with equation 5
var mean_velocity = null # computed with equation 7
var closest_food = null

func compute_swimming_force():
	# the equations here are described by Figure 4
	# and equations 2 to 10
	var closest_boundary = find_closest_boundary()

	var separation = Vector3.ZERO
	if closest_fish != null:
		separation = w[0] * (position - closest_fish.position).normalized()
	
	var cohesion = Vector3.ZERO
	if baricenter != null:
		cohesion = w[1] * (baricenter - position).normalized()
	
	var alignment = Vector3.ZERO
	if mean_velocity != null:
		alignment = w[2] * (mean_velocity - speed).normalized()
	
	var tank_top = Vector3(position.x, TANK_HEIGHT, position.z)
	var tank_floor = Vector3(position.x, 0, position.z)
	var boundary_avoidance = Vector3.ZERO
	var boundaries = [closest_boundary, tank_top, tank_floor]
	for boundary in boundaries:
		var distance_to_boundary = (position - boundary).length()
		if distance_to_boundary < field_of_view(boundary):
			boundary_avoidance += w[3] * (position - boundary).normalized()

	var food_attraction = Vector3.ZERO
	if closest_food != null:
		food_attraction = w[4] * (closest_food.position - position).normalized()
		
	var random_vector = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
	var random_movement = w[5] * random_vector.normalized()
	
	return (
		separation +
		cohesion +
		alignment +
		boundary_avoidance +
		food_attraction +
		random_movement
	)

const TANK_RADIUS = 2.0
const TANK_HEIGHT = 1.0

func find_closest_boundary():
	var tank_center = Vector3(0, position.y, 0)
	var vector_to_center = position - tank_center
	var prolongation_to_boundary = vector_to_center.normalized() * TANK_RADIUS
	return tank_center + prolongation_to_boundary

func start_feeding():
	current_phase = PHASE.FEEDING
	feed_intake_weight = 0.0
	phase_duration = 0.0

func start_growth():
	current_phase = PHASE.GROWING

func feed_in_tank():
	return get_tree().get_nodes_in_group("Food").size() > 0
	
func get_food_in_contact():
	var all_food = get_tree().get_nodes_in_group("Food")
	for food in all_food:
		var distance = (food.position - position).length()
		if distance < speed.length() / 8:
			return food
	return null

func _physics_process(_delta):
	var school = get_tree().get_nodes_in_group("School")
	var smallest_distance = INF
	var visible_fishes = 0

	closest_fish = null
	baricenter = Vector3.ZERO
	mean_velocity = Vector3.ZERO

	for fish in school:
		if fish == self:
			continue
		var distance = (fish.position - position).length()
		if distance <  field_of_view(position):
			visible_fishes += 1
			baricenter += fish.position
			mean_velocity += fish.speed
			if distance < smallest_distance:
				smallest_distance = distance
				closest_fish = fish

	if visible_fishes > 0:
		baricenter /= visible_fishes
		mean_velocity /= visible_fishes
	else:
		baricenter = null
		mean_velocity = null

	closest_food = null
	var foods = get_tree().get_nodes_in_group("Food")
	smallest_distance = INF
	
	
	for food in foods:
		var distance = (food.position - position).length()
		#We assumed that an individual can detect the feed regardless of the field of view.
		if  distance < smallest_distance:
			smallest_distance = distance
			closest_food = food

# TODO: replace it with a function that takes a point
# to take into account the dead space at the back of the fish 
# fig 3 in the paper  1
func field_of_view(point): #point: Vector3	
	# Assuming that swimming_force_vector represents the forward direction of the fish
	var direction_to_point = (point - position).normalized()
	var angle_to_point = swimming_force_vector.angle_to(direction_to_point)
	# Assuming a dead zone angle of 30 degrees (you can adjust this value as needed)
	var dead_zone_angle = 2*deg_to_rad(30)  # Convert degrees to radian
	# Check if the angle to the point is within the dead zone
	if angle_to_point < dead_zone_angle:
		# Point is within the dead zone, consider it outside the field of view
		return 0.0
	else:
		# Point is outside the dead zone, consider it within the field of view
		return 0.1 * total_length  # Adjust this value based on your requirements
	

func inside_of_tank(point):
	var radius = Vector2(point.x, point.z)
	return (radius.length() < TANK_RADIUS * 0.95 &&
		0.1 < point.y &&
		point.y < TANK_HEIGHT * 0.9)

func scale_mesh():
	const A = 0.0209
	const B = 2.483
	total_length = (body_mass / A)**(1 / B)
	mesh.scale = 0.02 * total_length**1.2 * Vector3.ONE
