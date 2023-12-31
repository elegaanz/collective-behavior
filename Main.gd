extends Node

@export var food_scene: PackedScene
@export var fish_scene: PackedScene

var fish_data = {}
const AUTOSTART = false
var started = AUTOSTART

# Called when the node enters the scene tree for the first time.
func _ready():
	var popup: PopupMenu = get_node("PanelContainer/HFlowContainer/ShapeMenu").get_popup()
	popup.connect("id_pressed", _on_shape_menu)
	
	popup = get_node("PanelContainer/HFlowContainer/SizeMenu").get_popup()
	popup.connect("id_pressed", _on_size_menu)
	
	if AUTOSTART:
		_on_start_button_pressed()

const FEEDING_PHASE_DURATION = 10.0
var timer = 0.0
var day = 1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !started:
		return
	timer += delta
	var percentage = timer / FEEDING_PHASE_DURATION * 100
	get_node("PanelContainer/HFlowContainer/DayLabel").text = "Day %s (%d%%)" % [day, percentage]

	if timer > FEEDING_PHASE_DURATION:
		var school = get_tree().get_nodes_in_group("School")
		for fish in school:
			if not fish_data.has(fish.id):
				fish_data[fish.id] = []
			fish_data[fish.id].append(fish.total_length)
		day += 1
		timer -= FEEDING_PHASE_DURATION
		spawn_food()
	if day == 91:
		started = false

const TANK_RADIUS = 2

var feed_area_size = 1.0  #size of food distribution square
var feeding_shape = 0
# 0 for square
# 1 for line
# 2 for cross
# 3 for circle around

const FOOD_MASS_PERCENTAGE = 0.0186  # percentage of total fish mass
var totalFishMass = 0.0 # total fish mass

func _input(event):
	if event.is_action_released("spawn_food"):
		spawn_food()
	if event.is_action("spawn_fish"):
		spawn_fish()
	if event.is_action_released("switch_camera"):
		var cam = get_node("Camera3D")
		var top_cam = get_node("TopCamera")
		if cam.current:
			top_cam.current = true
		else:
			cam.current = true
	if event.is_action_released("save_fish"):
		save_fish_data_to_csv()


func spawn_food():
	var gen_pos = func(): Vector3.ZERO
	match feeding_shape :
		0: # for a squared distribution
			gen_pos = func(): return Vector3(randf_range(-feed_area_size / 2, feed_area_size / 2), 0.5, randf_range(-feed_area_size / 2, feed_area_size / 2))
		1: # for a line
			gen_pos = func(): return Vector3(randf_range(-feed_area_size / 2, feed_area_size / 2), 0.5, 0.0)
		2: # for a cross
			#generate two lines
			var start_horizontal = Vector3(-feed_area_size / 2, 0.5, 0.0)
			var end_horizontal = Vector3(feed_area_size / 2, 0.5, 0.0)
			var start_vertical = Vector3(0.0, 0.5, -feed_area_size / 2)
			var end_vertical = Vector3(0.0, 0.5, feed_area_size / 2)
			
			gen_pos = func():
				if randf() < 0.5:
					return Vector3(randf_range(start_horizontal.x, end_horizontal.x), start_horizontal.y, 0.0)
				else:
					return Vector3(0.0, start_vertical.y, randf_range(start_vertical.z, end_vertical.z))
		3: # around the tank
			gen_pos = func():
				var angle = randf_range(0, 2 * PI)
				return Vector3(feed_area_size * cos(angle), 0.5, feed_area_size * sin(angle))
	
	var foodCount = int(ceil(0.001 + totalFishMass * FOOD_MASS_PERCENTAGE / 0.065))
	for _i in range(floor(foodCount)):
		var food = food_scene.instantiate()
		food.position = gen_pos.call()
		add_child(food)
		totalFishMass += food.weight

func save_fish_data_to_csv():
	var file = FileAccess.open("res://fish_data.txt", FileAccess.WRITE)
	var days = range(1, day).map(func(x): return "size_at_end_of_day_" + str(x))
	file.store_line("fish_id," + ",".join(days))
	
	for fish in fish_data:
		var line = str(fish) + "," + ",".join(range(1, day).map(func(x): return str(fish_data[fish][x - 1])))
		file.store_line(line)
	file.close()

var next_id = 0
func spawn_fish():
	var fish = fish_scene.instantiate()
	var rangle = randf_range(-PI, PI)
	fish.position = Vector3(
		cos(rangle) * randf_range(0, 1.8),
		randf_range(0, 1),
		sin(rangle) * randf_range(0, 1.8),
	)
	fish.id = next_id
	next_id += 1
	add_child(fish)
	totalFishMass += fish.body_mass
	

func _on_shape_menu(id):
	name = "square"
	if id == 1:
		name = "line"
	elif id == 2:
		name = "cross"
	elif id == 3:
		name = "circle"
	
	get_node("PanelContainer/HFlowContainer/ShapeMenu").text = "Feeding shape: " + name
	feeding_shape = id

func _on_size_menu(id):
	feed_area_size = 1.0 + (0.5 * id)	
	get_node("PanelContainer/HFlowContainer/SizeMenu").text = "Feeding area size: " + str(feed_area_size)

func _on_spawn_button_pressed():
	spawn_food()

func _on_camera_button_pressed():
	var evt = InputEventAction.new()
	evt.action = "switch_camera"
	Input.parse_input_event(evt)

func _on_save_button_pressed():
	var evt = InputEventAction.new()
	evt.action = "save_fish"
	Input.parse_input_event(evt)

func _on_start_button_pressed():
	started = true
	get_node("PanelContainer/HFlowContainer/StartButton").disabled = true
	for _i in range(100):
		spawn_fish()
