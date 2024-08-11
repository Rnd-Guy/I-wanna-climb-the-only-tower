extends Node2D

@export_file("*.tscn") var warp_to: String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$goal.warp_to = warp_to
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
