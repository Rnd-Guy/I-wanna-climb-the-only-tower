extends Control

var ITEMS := RND.ITEMS

var retry = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_instance_valid(GLOBAL_INSTANCES.objPlayerID):
		GLOBAL_INSTANCES.objPlayerID.connect("player_item_change", handle_item_change)
		handle_item_change()
	else:
		retry = true
		
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if retry:
		if is_instance_valid(GLOBAL_INSTANCES.objPlayerID):
			GLOBAL_INSTANCES.objPlayerID.connect("player_item_change", handle_item_change)
			handle_item_change()
			retry = false

func set_weapons(items):
	if items.has(ITEMS.GUN):
		$HBoxContainer/Gun.visible = true;
	else:
		$HBoxContainer/Gun.visible = false;
	if items.has(ITEMS.SWORD):
		$HBoxContainer/Sword.visible = true;
	else:
		$HBoxContainer/Sword.visible = false;

func set_weapon(weapon):
	match weapon:
		null:
			$Selector.visible = false
		ITEMS.GUN:
			$Selector.visible = true;
			$Selector.position = $HBoxContainer/Gun.position;
		ITEMS.SWORD:
			$Selector.visible = true;
			$Selector.position = $HBoxContainer/Sword.position;

func handle_item_change():
	set_weapons(GLOBAL_INSTANCES.objPlayerID.get_all_items())
	
	# give time for the hboxcontainer to shift positions first
	call_deferred("set_weapon", GLOBAL_INSTANCES.objPlayerID.weapon)
