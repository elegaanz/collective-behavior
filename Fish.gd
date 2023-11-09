extends Node3D

# W in the article
var body_mass = 1.0
# TL in the article
var total_length = 0.1
# S in the article
var feed_intake_weight = 0.0
const MAX_FEED_INTAKE = 10.0 # TODO: actual value

var swimming_force_vector = Vector3.RIGHT
var acceleration = Vector3.RIGHT
var speed = Vector3.ZERO

enum PHASE {
	FEEDING,
	GROWING,
}

var current_phase = PHASE.FEEDING
var mesh: MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh = get_node("MeshInstance3D")

var w = [0.6, 0.4, 0.4, 1.0, 0.0, 0.2] # w1 to w6 (the index are shifted in Godot and go from 0 to 5)
var max_speed_coeff = 1.5 # Cv in the article

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_phase == PHASE.FEEDING:
		# this algorithm is based on figure 2
		if feed_in_tank() && feed_intake_weight < MAX_FEED_INTAKE:
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
			var center_of_tank = Vector3(0, position.y, 0)
			position += (center_of_tank - position).normalized() * delta * delta

# The following variables are updated regularly in _physics_process
var closest_fish = null
var baricenter = Vector3.ZERO # computed with equation 5
var mean_velocity = Vector3.ZERO # computed with equation 7
var closest_food = null

func compute_swimming_force():
	# the equations here are described by Figure 4
	# and equations 2 to 10
	var closest_boundary = find_closest_boundary()

	var separation = Vector3.ZERO
	if closest_fish != null:
		separation = w[0] * (position - closest_fish.position).normalized()
	
	var cohesion = w[1] * (baricenter - position).normalized()
	
	var alignment = w[2] * (mean_velocity - speed).normalized()
	
	var tank_top = Vector3(position.x, TANK_HEIGHT, position.z)
	var tank_floor = Vector3(position.x, 0, position.z)
	var boundary_avoidance = Vector3.ZERO
	var boundaries = [closest_boundary, tank_top, tank_floor]
	for boundary in boundaries:
		var distance_to_boundary = (position - boundary).length()
		if distance_to_boundary < field_of_view():
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
	
func feed_in_tank():
	return get_tree().get_nodes_in_group("Food").size() > 0

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
		if distance <  field_of_view():
			visible_fishes += 1
			baricenter += fish.position
			mean_velocity += fish.speed
			if distance < smallest_distance:
				smallest_distance = distance
				closest_fish = fish
	
	if visible_fishes > 0:
		baricenter /= visible_fishes
		mean_velocity /= visible_fishes
	
	closest_food = null
	var foods = get_tree().get_nodes_in_group("Food")
	smallest_distance = INF
	for food in foods:
		var distance = (food.position - position).length()
		if distance < field_of_view() && distance < smallest_distance:
			smallest_distance = distance
			closest_food = food

# TODO: replace it with a function that takes a point
# to take into account the dead space at the back of the
# fish
func field_of_view():
	return 2 * total_length

func inside_of_tank(point):
	var radius = Vector2(point.x, point.z)
	return (radius.length() < TANK_RADIUS * 0.95 &&
		0.1 < point.y &&
		point.y < TANK_HEIGHT * 0.9)
