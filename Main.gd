extends Node

@export var food_scene: PackedScene
@export var fish_scene: PackedScene

const SAVE_KEY = KEY_S

var fish_data = []  # List to store fish data

# Called when the node enters the scene tree for the first time.
func _ready():
	var popup: PopupMenu = get_node("HFlowContainer/ShapeMenu").get_popup()
	popup.connect("id_pressed", _on_shape_menu)
	
	popup = get_node("HFlowContainer/SizeMenu").get_popup()
	popup.connect("id_pressed", _on_size_menu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

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
	if event.is_action_released("spawn_fish"):
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
	if event.is_action_released("save_fish"):
		var school = get_tree().get_nodes_in_group("School")
		var last_assigned_id = 0
		for fish in school:
			last_assigned_id += 1
			var fish_info = {
				"ID": last_assigned_id,
				"Final_Size": fish.total_length  # Store the final size
				}
			fish_data.append(fish_info)
		save_fish_data_to_csv()
		print("Fish data saved.")


func spawn_food():
	
	match feeding_shape :
	# for a squared distribution
		0: 
			var foodCount = int(totalFishMass * FOOD_MASS_PERCENTAGE / 0.065)
			if foodCount == 0:
				var food = food_scene.instantiate()
				food.position = Vector3(randf_range(-feed_area_size / 2, feed_area_size / 2), 0.5, randf_range(-feed_area_size / 2, feed_area_size / 2))
				add_child(food)
				totalFishMass += food.weight
			else :
				for _i in range(floor(foodCount)): 
					var food = food_scene.instantiate()
					food.position = Vector3(randf_range(-feed_area_size / 2, feed_area_size / 2), 0.5, randf_range(-feed_area_size / 2, feed_area_size / 2))
					add_child(food)
					totalFishMass += food.weight
	
	# for a line
		1:
			var foodCount = int(totalFishMass * FOOD_MASS_PERCENTAGE / 0.065)
			if foodCount == 0:
				var food = food_scene.instantiate()
				food.position = Vector3(randf_range(-feed_area_size / 2, feed_area_size / 2), 0.5, 0.0)
				add_child(food)
				totalFishMass += food.weight
			else :
				for _i in range(floor(foodCount)): 
					var food = food_scene.instantiate()
					food.position = Vector3(randf_range(-feed_area_size / 2, feed_area_size / 2), 0.5, 0.0)
					add_child(food)
					totalFishMass += food.weight
			
	# for a cross
		2:
			var foodCount = int(totalFishMass * FOOD_MASS_PERCENTAGE / 0.065)
			#generate two lines
			var start_horizontal = Vector3(-feed_area_size / 2, 0.5, 0.0)
			var end_horizontal = Vector3(feed_area_size / 2, 0.5, 0.0)

			var start_vertical = Vector3(0.0, 0.5, -feed_area_size / 2)
			var end_vertical = Vector3(0.0, 0.5, feed_area_size / 2)
			
			if foodCount == 0:
				var food = food_scene.instantiate()
				if randf() < 0.5:
					food.position = Vector3(randf_range(start_horizontal.x, end_horizontal.x), start_horizontal.y, 0.0)
				else:
					food.position = Vector3(0.0, start_vertical.y, randf_range(start_vertical.z, end_vertical.z))
				add_child(food)
				totalFishMass += food.weight
			else :
				for _i in range(floor(foodCount)): 
					var food = food_scene.instantiate()
					if randf() < 0.5:
						food.position = Vector3(randf_range(start_horizontal.x, end_horizontal.x), start_horizontal.y, 0.0)
					else:
						food.position = Vector3(0.0, start_vertical.y, randf_range(start_vertical.z, end_vertical.z))
					add_child(food)
					totalFishMass += food.weight
			
	# around the tank
		3:			
			var foodCount = int(totalFishMass * FOOD_MASS_PERCENTAGE / 0.065)
			if foodCount == 0:
				var food = food_scene.instantiate()
				var angle = randf_range(0, 2 * PI)
				food.position = Vector3(feed_area_size * cos(angle), 0.5, feed_area_size * sin(angle))
				add_child(food)
				totalFishMass += food.weight
			else :
				for _i in range(floor(foodCount)): 
					var food = food_scene.instantiate()
					var angle = randf_range(0, 2 * PI)
					food.position = Vector3(feed_area_size * cos(angle), 0.5, feed_area_size * sin(angle))
					add_child(food)
					totalFishMass += food.weight

func save_fish_data_to_csv():
	if fish_data.size() == 0:
		print("No fish data to save.")
		return
		
	var file = FileAccess.open("res://fish_data.txt",FileAccess.WRITE)
	file.store_line("Fish_Index,Final_Size")

	# Write data for each fish
	for fish_info in fish_data:
		var line = str((str(fish_info["ID"]) + "," + str(fish_info["Final_Size"])))
		file.store_line(line)    
	file.close()
	print("Fish data saved successfully.")

func _on_shape_menu(id):
	name = "square"
	if id == 1:
		name = "line"
	elif id == 2:
		name = "cross"
	elif id == 3:
		name = "circle"
	
	get_node("HFlowContainer/ShapeMenu").text = "Feeding shape: " + name
	feeding_shape = id

func _on_size_menu(id):
	feed_area_size = 1.0 + (0.5 * id)	
	get_node("HFlowContainer/SizeMenu").text = "Feeding area size: " + str(feed_area_size)

func _on_spawn_button_pressed():
	spawn_food()

func _on_camera_button_pressed():
	var evt = InputEventAction.new()
	evt.action = "switch_camera"
	Input.parse_input_event(evt)
