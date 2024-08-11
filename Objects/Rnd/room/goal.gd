extends Node2D

@export_file("*.tscn") var warp_to: String = ""

var goaled = false;
var anim_finished = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("button_shoot") && goaled && !anim_finished:
		if $AnimationPlayer.current_animation_position < 1:
			$AnimationPlayer.seek(1);
		elif $AnimationPlayer.current_animation_position < 3:
			$AnimationPlayer.seek(3);
		elif $AnimationPlayer.current_animation_position < 4:
			$AnimationPlayer.seek(4);
			on_anim_finished("")
	elif Input.is_action_just_pressed("button_shoot") && anim_finished:
		warp_to_next_room()

func _on_area_2d_body_entered(body: Node2D) -> void:
	body.goaled = true
	goaled = true;
	$AnimationPlayer.play("goal")
	$AnimationPlayer.animation_finished.connect(on_anim_finished);

func on_anim_finished(_ignore):
	anim_finished = true;

func warp_to_next_room():
	if warp_to != "":
		GLOBAL_GAME.is_changing_rooms = true
		await objWarpTransition.fade_to_black()
		get_tree().call_deferred("change_scene_to_file", warp_to)
	else:
		print("oh no")
		
