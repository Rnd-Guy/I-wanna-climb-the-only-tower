extends Node2D

@onready var player = GLOBAL_INSTANCES.objPlayerID;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_instance_valid(player):
		player.is_safe = true;


func _on_area_2d_body_exited(body: Node2D) -> void:
	if is_instance_valid(player):
		player.is_safe = false;
