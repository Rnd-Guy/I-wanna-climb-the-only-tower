extends Node2D

@export var invisible_in_game: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if invisible_in_game:
		visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
