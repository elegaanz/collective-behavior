extends Node

@export var food_scene: PackedScene
@export var fish_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

const TANK_RADIUS = 2

const FOOD_SPAWN_AREA_SIZE = 1.0  #size of food distribution square
const FOOD_MASS_PERCENTAGE = 0.0186  # percentage of total fish mass
var totalFishMass = 0.0 # total fish mass

func _input(event):
	if event.is_action_released("spawn_food"):
		spawn_food()
	if event.is_action("spawn_fish"):
		var fish = fish_scene.instantiate()
		var rangle = randf_range(-PI, PI)
		fish.position = Vector3(
			cos(rangle) * randf_range(0, 1.8),
			randf_range(0, 1),
			sin(rangle) * randf_range(0, 1.8),
		)
		add_child(fish)
		totalFishMass += fish.body_mass
	if event.is_action_released("switch_camera"):
		var cam = get_node("Camera3D")
		var top_cam = get_node("TopCamera")
		if cam.current:
			top_cam.current = true
		else:
			cam.current = true
			

func spawn_food():
	var foodCount = int(totalFishMass * FOOD_MASS_PERCENTAGE / 0.065)
	if foodCount == 0:
		var food = food_scene.instantiate()
		food.position = Vector3(randf_range(-FOOD_SPAWN_AREA_SIZE / 2, FOOD_SPAWN_AREA_SIZE / 2), 0.5, randf_range(-FOOD_SPAWN_AREA_SIZE / 2, FOOD_SPAWN_AREA_SIZE / 2))
		add_child(food)
		totalFishMass += food.weight
	else :
		for _i in range(floor(foodCount)): 
			var food = food_scene.instantiate()
			food.position = Vector3(randf_range(-FOOD_SPAWN_AREA_SIZE / 2, FOOD_SPAWN_AREA_SIZE / 2), 0.5, randf_range(-FOOD_SPAWN_AREA_SIZE / 2, FOOD_SPAWN_AREA_SIZE / 2))
			add_child(food)
			totalFishMass += food.weight
