@tool
extends Node2D

@export var item := RND.ITEMS.FILLER;

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
		if Input.is_action_just_pressed("button_up") && pickupable:
			GLOBAL_INSTANCES.objPlayerID.pickup_item(item);
			queue_free()
			

func _on_area_2d_body_entered(body: Node2D) -> void:
	$Arrow.visible = true;
	pickupable = true;


func _on_area_2d_body_exited(body: Node2D) -> void:
	$Arrow.visible = false;
	pickupable = false;
