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
func _input(event):
	if event.is_action("spawn_food"):
		var food = food_scene.instantiate()
		var camera = get_node("TopCamera")
		if camera.current:
			var mouse_pos = get_viewport().get_mouse_position()
			food.position = camera.project_position(mouse_pos, camera.position.y - 0.5)
			if (food.position - Vector3(0, 0.5, 0)).length() > TANK_RADIUS:
				return
		else:
			food.position = Vector3(0, 0.5, 0)
		add_child(food)
	if event.is_action("spawn_fish"):
		var fish = fish_scene.instantiate()
		var rangle = randf_range(-PI, PI)
		fish.position = Vector3(
			cos(rangle) * randf_range(0, 1.8),
			randf_range(0, 1),
			sin(rangle) * randf_range(0, 1.8),
		)
		add_child(fish)
	if event.is_action_released("switch_camera"):
		var cam = get_node("Camera3D")
		var top_cam = get_node("TopCamera")
		if cam.current:
			top_cam.current = true
		else:
			cam.current = true
