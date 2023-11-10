extends Node3D

# in grams (see 
# "Definition of feed intake during the feeding simulation"
# in the article)
var weight = 0.065

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if position.y <= 0.095:
		return 
	const SINKING_SPEED = 0.025
	position.y -= SINKING_SPEED * delta
