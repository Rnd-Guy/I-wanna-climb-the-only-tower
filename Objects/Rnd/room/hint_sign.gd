extends Node2D

@export var order : Array[Node] = []

var text = [
	"Hello I'm the hint sign! We couldn't hire someone so this is the best you got.
	Press UP to progress text",
	
	"The basics are: find the key, then reach the top to win!",
	
	"If you get stuck and don't know where to go, ask me!",
	
	"Talk to me one more time for a hint",
	
	
	"That's it! I think you're ready to brave the tower!"
]
var text_index = 0;

var progressable = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$objSignProximity.sign_text = text[text_index]
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if progressable && Input.is_action_just_pressed("button_up"):
		if text_index < 3:
			text_index += 1
			set_text(text[text_index])
		elif text_index == 3:
			var found_hint = false
			for node in order:
				if is_instance_valid(node):
					set_text(node.hint + "\n Talk to me again afterwards if you need another!")
					found_hint = true
					break
			if !found_hint:
				text_index += 1
				set_text(text[text_index])
					
		
func set_text(new_text):
	$objSignProximity.sign_text = new_text

func _on_area_2d_body_entered(body: Node2D) -> void:
	$Arrow.visible = true;
	progressable = true;


func _on_area_2d_body_exited(body: Node2D) -> void:
	$Arrow.visible = false;
	progressable = false;
