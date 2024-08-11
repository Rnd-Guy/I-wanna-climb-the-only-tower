extends Node2D

var text = ""

func _ready() -> void:
	# not sure if needed to defer but should be pretty safe
	text = RND.world_name;
	$Label.set_deferred("text", text);
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if text == "":
		visible = false
	else:
		visible = true
