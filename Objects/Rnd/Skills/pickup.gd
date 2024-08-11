@tool
extends Node2D

@export var item := RND.ITEMS.FILLER;
@export var hint := "Someone forgot to code a hint :c  Looks like you still need something though!"

var pickupable = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		$EditorNode/Label.text = RND.ITEMS.find_key(item)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		$EditorNode/Label.text = RND.ITEMS.find_key(item)
	#pass

func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		var player = GLOBAL_INSTANCES.objPlayerID
		
		if is_instance_valid(player):
			if player.has_item(item):
				queue_free()
			
			elif Input.is_action_just_pressed("button_up") && pickupable:
				GLOBAL_INSTANCES.objPlayerID.pickup_item(item);
				RND.item_pickup.emit(item);
				GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndPickup)
				GLOBAL_SAVELOAD.save_game(true)
				queue_free()
		
			

func _on_area_2d_body_entered(body: Node2D) -> void:
	$Arrow.visible = true;
	pickupable = true;


func _on_area_2d_body_exited(body: Node2D) -> void:
	$Arrow.visible = false;
	pickupable = false;
