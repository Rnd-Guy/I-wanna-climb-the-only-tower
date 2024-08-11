extends Node2D

@export var starting_items : Array[RND.ITEMS]
@export var day = 1
@export var day_name = ""

var retry = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("set_day_items")
	RND.world_name = day_name


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if retry:
		set_day_items()

func set_day_items():
	var player = GLOBAL_INSTANCES.objPlayerID;
	if !is_instance_valid(player):
		retry = true;
		return
	
	retry = false;
	if GLOBAL_SAVELOAD.variableGameData.day_setup < day:
		GLOBAL_SAVELOAD.variableGameData.day_setup = day;
		player.set_initial_items(starting_items)
	else:
		player.load_items()
