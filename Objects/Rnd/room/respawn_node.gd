extends Node2D

var retry = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_warp_node()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if retry:
		set_warp_node()

func set_warp_node():
	if is_instance_valid(GLOBAL_INSTANCES.objPlayerID):
		GLOBAL_INSTANCES.objPlayerID.warp_node = self;
		retry = false
	else:
		retry = true;
