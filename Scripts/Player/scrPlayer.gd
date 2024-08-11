extends CharacterBody2D


"""
---------- VARIABLE DECLARATIONS ---------- 
"""
var gravity: int = 1000
var v_speed: int = 470
var h_speed: int = 150
var s_jump_speed: int = 405
var d_jump_speed: int = 350
var jump_release_falloff: float = 0.45
var xscale: bool = true
var frozen: bool = false
#var d_jump: bool = true
var d_jump_aux: bool = false
var in_water: bool = false
var v_speed_modifier: float = 1.0
var can_walljump: bool = false
var is_walljumping: bool = false
var create_bullet := preload("res://Objects/Player/objBullet.tscn")
var jump_particle := preload("res://Objects/Player/objJumpParticle.tscn")
@onready var animated_sprite = $playerSprites

# Signals emitted by the player's actions
signal player_died
signal player_jumped
signal player_djumped
signal player_walljumped
signal player_shot

#region Original code
func _ready():
	
	# If a savefile exists (we've saved at least once), we move the player to
	# the saved position, and also set its sprite state (flipped or not).
	if !GLOBAL_SAVELOAD.variableGameData.first_time_saving:
		set_position_on_load()
		flip_sprites_on_creation()
	
	# Sets a very important global variable. Lets everything know that the
	# player does in fact exist and assigns it with its "id"
	GLOBAL_INSTANCES.objPlayerID = self
	
	# Turns hitbox visible if debug setting is enabled
	if GLOBAL_GAME.debug_hitbox:
		$playerMask/ColorRect.visible = GLOBAL_GAME.debug_hitbox
	
	set_initial_items(default_items)


"""
---------- MAIN LOGIC LOOP ----------
"""
func _physics_process(delta):
	
	# If we haven't saved before, it makes a special type of save which sets
	# things up for the rest of the game. 
	# NOTE: This function used to be executed in _ready(), but due to some of 
	# the timing related changes made in v4.2, this was moved here and works
	# again.
	if (GLOBAL_SAVELOAD.variableGameData.first_time_saving == true):
		set_first_time_saving()
	
	# More specific logic is handled inside of methods, which keeps the main
	# loop clean and easier to read.
	# These methods should only work if the player isn't in the middle of a
	# dialog sequence/cutscene
	if !frozen:
		
		# These movement modules should only work if the player is not
		# walljumping
		#if !is_walljumping:
		handle_movement()
		handle_walljumping(delta)
		handle_jumping()
		handle_shooting(delta)
		handle_water()
		
		# Walljumping is its own special case. If we are in a walljumping
		# state, it deactivates the previous methods/modules
		
		
	
	# These methods should be called before "move_and_slide()", and should
	# always work (even if the player is frozen)
	handle_masks()
	handle_gravity(delta)
	debug_mouse_teleport()
	handle_rnd_stuff(delta)
	
	
	# "move_and_slide()" handles all sorts of movement, using velocity values
	# which includes running, jumping and more.
	# Call it before "_handle_animations()". Doing so will properly check for
	# "is_on_floor()", which requires collision data. This prevents a 1 frame
	# animation bug when resetting.
	move_and_slide()
	handle_animations()


# Debug key inputs
func _unhandled_key_input(event: InputEvent):
	handle_debug_keys(event)


"""
---------- CUSTOM METHODS ----------
"""
# Moves the player if we're not warping from another room (to spawn at the
# correct initial position).
# If it is our first time saving, it calls a function to make a special type
# of save, preparing data for future use
func set_position_on_load():
		
	# If we're warping from another room, then we don't want this object
	# to read and teleport to our last saved position. However, as soon
	# as we load the room and finish teleporting, we want to be able to
	# read those positions again.
	if (GLOBAL_GAME.is_changing_rooms == false):
		position.x = GLOBAL_SAVELOAD.variableGameData.player_x
		position.y = GLOBAL_SAVELOAD.variableGameData.player_y
	else:
		
		# If the warp we teleported from changed warp_to_point, we teleport
		# to those coordinates and then set them to 0,0 again
		if GLOBAL_GAME.warp_to_point != Vector2.ZERO:
			position = GLOBAL_GAME.warp_to_point
		
		GLOBAL_GAME.warp_to_point = Vector2.ZERO
		GLOBAL_GAME.is_changing_rooms = false


# We make a save with this player's current coordinates, sprite state, and room
# name (without taking a screenshot).
# This is done to prevent a common issue that happens when restarting with a 
# clean save (otherwise it would teleport the player to 0,0 and to an undefined
# room).
func set_first_time_saving():
	
	GLOBAL_SAVELOAD.variableGameData.player_x = position.x
	GLOBAL_SAVELOAD.variableGameData.player_y = position.y
	GLOBAL_SAVELOAD.variableGameData.player_sprite_flipped = xscale
	GLOBAL_SAVELOAD.variableGameData.room_name = get_tree().get_current_scene().get_scene_file_path()
	GLOBAL_SAVELOAD.variableGameData.first_time_saving = false
	
	# After changing the variable game data to the proper values, we save them.
	GLOBAL_SAVELOAD.save_data()
	
	# Then, after saving for the fist time in-game, a reload is needed.
	# What this does is replacing the old default values with the new ones
	# we just saved, reading them once through loading.
	GLOBAL_SAVELOAD.load_data()


# Handles gravity / falling
func handle_gravity(delta) -> void:
	
	# Adds the gravity when you're grounded or not on a platform
	if (is_on_floor() == false):
		velocity.y += gravity * delta
		
		# Clamps the falling value to v_speed, which is also modified by 
		# water physics. Check _handle_water()
		velocity.y = min(v_speed * v_speed_modifier, velocity.y)


# Main movement logic (walking/running)
func handle_movement() -> void:
	
	# Get the input direction and handle the movement
	var main_direction: float = Input.get_axis("button_left", "button_right")
	var extra_direction_keys: float = Input.get_axis("button_left_extra", "button_right_extra")
	
	# Lambda function, also called "anonymous function".
	# It's a method that only works inside of this event, declared inside
	# of a variable and executed by using "call()".
	# Useful for keeping code cleaner and less repetitive in certain cases,
	# but it's not mandatory.
	# Changes xscale using a direction argument, as long as the player is
	# moving
	var xscale_to_direction = func(h_direction):
		
		# Player needs to be moving in order to flip the xscale
		if velocity.x != 0:
			xscale = h_direction > 0
	
	# Extra keys off/on
	if !GLOBAL_SETTINGS.EXTRA_KEYS:
		velocity.x = main_direction * h_speed
		xscale_to_direction.call(main_direction)
	else:
		
		# If not pressing/activating extra keys, use normal direction vector
		if extra_direction_keys == 0:
			velocity.x = main_direction * h_speed
			xscale_to_direction.call(main_direction)
		else:
			
			# Controller stick deadzone correction (values go from -1.0 to 1.0)
			if extra_direction_keys > 0:
				extra_direction_keys = 1
			if extra_direction_keys < 0:
				extra_direction_keys = -1
			
			# Adds velocity from extra_direction_keys, the secondary direction 
			# vector
			velocity.x = extra_direction_keys * h_speed
			xscale_to_direction.call(extra_direction_keys)


# Jumping logic
func handle_jumping() -> void:
	
	# Always allow djump if you're grounded
	if (is_on_floor() == true):
		#d_jump = true
		if has_item(ITEMS.JUMP):
			can_jump = true;
		djumps = max_djumps;
	
	# Adds vertical velocity when jumping
	if Input.is_action_just_pressed("button_jump"):
		if (is_on_floor() == true && can_jump):
			velocity.y = -s_jump_speed
			GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndJump)
			
			# Emit the "player_jumped" signal
			player_jumped.emit()
			
		# If d_jump is available or you're inside a platform, the player now
		# jumps with d_jump_speed. Inside of platforms you can jump infinitely,
		# and they are the ones who set d_jump_aux to true or false.
		# Same logic applies to water
		#elif d_jump or d_jump_aux or in_water or GLOBAL_GAME.debug_inf_jump:
		elif !just_walljumped && (djumps > 0 or d_jump_aux or in_water or GLOBAL_GAME.debug_inf_jump):

			#velocity.y = -d_jump_speed
			#d_jump = false
			if d_jump_aux:
				djumps = max_djumps;
				velocity.y = -s_jump_speed
			else:
				djumps -= 1;
				velocity.y = -d_jump_speed
			
			
			GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndDJump)
			
			# Emit the "player_djumped" signal
			player_djumped.emit()
			
			# Jump particles on djump, as long as the player is not in water
			if (in_water == false):
				var jump_particle_id = jump_particle.instantiate()
				get_parent().add_child(jump_particle_id)
				jump_particle_id.global_position = Vector2(global_position.x, global_position.y + 12)
	
	# Adds some "gravity" if you release the jump button mid-jump
	if Input.is_action_just_released("button_jump") and (velocity.y < 0):
		velocity.y *= jump_release_falloff


# Method that handles the walljumping gimmick. It's divided into 2 parts:
# 1) Setting walljumping (whether it should be active or not)
# 2) The "walljumping" action

#func handle_walljumping():
	#
	## 1) Setting the walljump state:
	## If we collided with a vine
	#if can_walljump:
	#
		## Walljumping shouldn't activate if we're grounded. Otherwise,
		## it if wasn't active before, it now is. Also sets the vertical
		## velocity to 0, so we don't slide with inertia
		#if is_on_floor():
			#is_walljumping = false
		#else:
			#
			#if !is_walljumping:
				#velocity.y = 0
				#is_walljumping = true
	#else:
		#is_walljumping = false
	#
	#
	#
	## 2) "Walljumping" action:
	## If we are in a walljumping state, it slows our vertical speed down and
	## prepares us for walljumping or leaving it altogether
	#if is_walljumping:
		#v_speed_modifier = 0.2
		#var jump_direction = get_wall_normal()
		#
		## Lambda function, also called "anonymous function".
		## It's a method that only works inside of this event, declared inside
		## of a variable and executed by using "call()".
		## Useful for keeping code cleaner and less repetitive in certain cases,
		## but it's not mandatory
		#var walljumping_action = func():
			#velocity.x = jump_direction.x * h_speed
			#velocity.y = -s_jump_speed
			#is_walljumping = false
			#GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndJump)
			#
			## Emit the "player_walljumped" signal
			#player_walljumped.emit()
		#
		## Walljumping should only happen if we hold the jump button first
		#if Input.is_action_pressed("button_jump"):
			#
			## Extra keys off/on
			#if !GLOBAL_SETTINGS.EXTRA_KEYS:
				#
				## Walljump to the right
				#if (Input.is_action_pressed("button_right")) and (jump_direction == Vector2.RIGHT):
					#if !Input.is_action_pressed("button_left"):
						#walljumping_action.call()
				#
				## Walljump to the left
				#if Input.is_action_pressed("button_left") and (jump_direction == Vector2.LEFT):
					#if !Input.is_action_pressed("button_right"):
						#walljumping_action.call()
			#else:
				#
				## Walljump to the right
				#if (Input.is_action_pressed("button_right") or Input.is_action_pressed("button_right_extra")) and (jump_direction == Vector2.RIGHT):
					#if (!Input.is_action_pressed("button_left") or !Input.is_action_pressed("button_left_extra")):
						#walljumping_action.call()
				#
				## Walljump to the left
				#if (Input.is_action_pressed("button_left") or Input.is_action_pressed("button_left_extra")) and (jump_direction == Vector2.LEFT):
					#if (!Input.is_action_pressed("button_right") or !Input.is_action_pressed("button_right_extra")):
						#walljumping_action.call()
		#else:
			#
			## Extra keys off/on
			#if !GLOBAL_SETTINGS.EXTRA_KEYS:
				#
				## Not holding the jump button, but pressing left or right on the 
				## opposite direction to the vine, leaves it and stops the
				## walljumping state.
				## This won't work if both the left and right buttons are pressed 
				## at the same time. Feels cleaner this way
				#if Input.is_action_pressed("button_right") and (jump_direction == Vector2.RIGHT):
					#if !Input.is_action_pressed("button_left"):
						#is_walljumping = false
				#
				#if Input.is_action_pressed("button_left") and (jump_direction == Vector2.LEFT):
					#if !Input.is_action_pressed("button_right"):
						#is_walljumping = false
			#else:
				#if (Input.is_action_pressed("button_right") or Input.is_action_pressed("button_right_extra")) and (jump_direction == Vector2.RIGHT):
					#if (!Input.is_action_pressed("button_left") or !Input.is_action_pressed("button_left_extra")):
						#is_walljumping = false
				#
				#if (Input.is_action_pressed("button_left") or Input.is_action_pressed("button_left_extra")) and (jump_direction == Vector2.LEFT):
					#if (!Input.is_action_pressed("button_right") or !Input.is_action_pressed("button_right_extra")):
						#is_walljumping = false
	#else:
		#
		## Sets things back to normal (not walljumping anymore).
		## handle_water() sets the "v_speed_modifier" variable properly, so we
		## just call it here instead of re-setting things manually
		#handle_water()


## Shooting logic
#func handle_shooting():
	#if Input.is_action_just_pressed("button_shoot"):
		#
		## An equivalent to gamemaker's "instance_number() < 4"
		## It checks how many nodes belonging to the "Bullet" group
		## exist in the current scene
		#if get_tree().get_nodes_in_group("Bullet").size() < 4:
			#
			## Loads the bullet scene, instances it, assigns the shooting direction
			## and global position, makes a sound and then adds it to the main scene 
			## (the actual game)
			#var create_bullet_id: AnimatableBody2D = create_bullet.instantiate()
			#if xscale:
				#create_bullet_id.looking_at = 1
			#else:
				#create_bullet_id.looking_at = -1
			#
			## Bullet's x coordinate:
			##	-Takes into account the global x
			##	-The bullet spacing, relative to where we are looking at 
			#create_bullet_id.global_position = Vector2(global_position.x, global_position.y + 5)
			#GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndShoot)
			#
			## After everything is set and done, creates the bullet
			#get_parent().add_child(create_bullet_id)


# Method to handle sprite animations
func handle_animations() -> void:
	
	# We assign each sprite animation, unless we are slidding/walljumping
	if !is_walljumping:
		
		# If on the air, checks Y velocity for the jumping or falling animations
		if (is_on_floor() == false):
			if (velocity.y < 0):
				animated_sprite.play("jump")
			else:
				animated_sprite.play("fall")
		else:
			# If grounded or on a platform, checks X velocity for the idle or 
			# running animations
			if (velocity.x == 0):
				animated_sprite.play("idle")
			else:
				animated_sprite.play("running")
	else:
		
		# If we are slidding/walljumping, we set the proper animation
		animated_sprite.play("slidding")
		
	# Flips the player sprite using the "xscale" variable
	animated_sprite.flip_h = !xscale


# Checks the scrGlobalSaveload autoload in order to know if the sprite should
# be flipped horizontally on creation
func flip_sprites_on_creation() -> void:
	
	animated_sprite.flip_h = !GLOBAL_SAVELOAD.variableGameData.player_sprite_flipped
	xscale = GLOBAL_SAVELOAD.variableGameData.player_sprite_flipped
	
	# Also rotates masks
	handle_masks()


# Handles masks specifically. Looks cleaner if put into its own method rather
# than placing it inside the animations one.
# Keep in mind, masks inside $extraCollisions might have different shapes,
# intended for different purposes
func handle_masks() -> void:
	if xscale:
		$playerMask.position.x = 1
	else:
		$playerMask.position.x = -1
	
	# We rotate the scale for the collision containers, so we don't have to
	# reference each one of them
	$extraCollisions.scale.x = $playerMask.position.x


# Interaction with water
func handle_water() -> void:
	
	# Changes the player's falling speed when on water, and returns it to 
	# normal when outside of it. Values can get changed here, for convenience
	if in_water:
		v_speed_modifier = 0.4
	else:
		v_speed_modifier = 1.0


# Teleports the player to the mouse position when "button_debug_teleport"
# is pressed (only on debug mode)
func debug_mouse_teleport() -> void:
	if GLOBAL_GAME.debug_mode:
		if Input.is_action_pressed("button_debug_teleport"):
			position = get_global_mouse_position()
			velocity.y = 0


# Handles all debug key toggles. Keys are hardcoded.
func handle_debug_keys(event: InputEvent) -> void:
	
	# Debug keys are activated only in debug mode
	if GLOBAL_GAME.debug_mode:
		if event is InputEventKey and event.is_pressed() and not event.is_echo():
			
			# Toggle godmode
			if event.keycode == KEY_1:
				GLOBAL_GAME.debug_godmode = !GLOBAL_GAME.debug_godmode
			
			# Toggle infjump
			if event.keycode == KEY_2:
				GLOBAL_GAME.debug_inf_jump = !GLOBAL_GAME.debug_inf_jump
			
			# Toggle hitbox view
			if event.keycode == KEY_3:
				GLOBAL_GAME.debug_hitbox = !GLOBAL_GAME.debug_hitbox
				$playerMask/ColorRect.visible = GLOBAL_GAME.debug_hitbox
			
			# Debug save
			if event.keycode == KEY_4:
				GLOBAL_SAVELOAD.save_game(true)
				GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndCoin)


# Everything that should happen after the player dies
func on_death():
	
	# Death should only happen if we're out of godmode
	if !GLOBAL_GAME.debug_godmode:
		
		# We load a particle emitter, which does the visual stuff we want
		var blood_emitter = load("res://Objects/Player/objBloodEmitter.tscn")
		var blood_emitter_id = blood_emitter.instantiate()
		blood_emitter_id.position = Vector2(position.x, position.y)
		if xscale:
			blood_emitter_id.side = 1
		else:
			blood_emitter_id.side = -1
		
		# We add a sibling node to the player, not a child node, since the
		# player object gets freed!
		add_sibling(blood_emitter_id)
		GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndDeath)
		
		# Adds an extra death to the global death counter
		GLOBAL_GAME.deaths += 1
		
		# Emit "player_died"
		player_died.emit()
		
		# Destroys the player
		queue_free()



"""
---------- EXTRA COLLISIONS ----------
"""
# Platforms: 
# -> Gives infinite djump while touching them
func _on_platforms_body_entered(_body):
	d_jump_aux = true
func _on_platforms_body_exited(_body):
	d_jump_aux = false


# Killers
# -> Calls "on_death"
func _on_killers_body_entered(_body):
	on_death()


# Water
# -> Indicates whether the player is inside of water
func _on_water_area_entered(_area):
	in_water = true
func _on_water_area_exited(_area):
	in_water = false


# IsCrushed
# -> Checks if the player is inside of walls, calling "on_death" if true.
#    It has a smaller collision shape
func _on_is_crushed_body_entered(_body):
	on_death()


# Vines
# -> Indicates whether the player is touching a vine, for walljumping
func _on_vines_body_entered(_body):
	if !can_walljump:
		can_walljump = true
func _on_vines_body_exited(_body):
	can_walljump = false


func _on_sheep_blocks_body_entered(body):
	if !body.activated:
		GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndSheepBlock)
		body.animation_player.play("animSheepBlock")
		body.activated = true
#endregion

#######################################################
## GAMEJAM SHENANIGANS
########################################################

var ITEMS := RND.ITEMS;
var DIR := RND.DIR;

var permanent_items = []
var temporary_items = []

var max_djumps = 0;
var djumps = 0;
var can_jump = true;
var can_shoot = true;

var dash_speed: int = 400
var dash_duration: float = 0.25
var current_dash_duration: float = 0;
var dash_cooldown: float = 0.5
var current_dash_cooldown: float = 0;
var can_dash = false;
var dash_direction := DIR.LEFT;

var wall_jump_duration: float = 0.1;
var current_wall_jump_duration : float = 0;
var wall_jump_direction := DIR.LEFT;
var just_walljumped = false;

var weapon = null;
var weapons = [ITEMS.GUN]

@onready var sword_node = $Sword/Right;
var sword_duration = 0.2;
var current_sword_duration = 0;
var sword_cooldown = 0.3;
var current_sword_cooldown = 0;
var side_bounce_duration = 0.1;
var current_side_bounce_duration = 0;
var side_bounce_speed = 400;
var side_bounce_direction = DIR.LEFT;

var gun_recoil_direction = DIR.LEFT;
var gun_recoil_speed = 400;
var gun_recoil_duration = 0.1;
var current_gun_recoil_duration = 0;
var bullets = 4;
var current_bullets = 4;
var autofire_timer = 0.1;
var current_autofire_timer = 0;

# proper
#var default_items = [ITEMS.JUMP, ITEMS.DOUBLE_JUMP, ITEMS.GUN]

# testing
var default_items = [ITEMS.JUMP, ITEMS.DOUBLE_JUMP]

signal player_item_change

func pickup_item(item):
	match item:
		ITEMS.JUMP:
			can_jump = true
		ITEMS.DOUBLE_JUMP:
			if max_djumps < 1:
				max_djumps = 1;
		ITEMS.TRIPLE_JUMP:
			if max_djumps < 2:
				max_djumps = 2;
		ITEMS.INFINITE_JUMP:
			max_djumps = 9999999
		ITEMS.GUN:
			weapons.append(item)
			if weapon == null:
				weapon = item
		ITEMS.SWORD:
			weapons.append(item)
			if weapon == null:
				weapon = item
		ITEMS.GUN_INFINITE_AMMO:
			bullets = 99999999
	
	temporary_items.append(item);
	player_item_change.emit()

func has_item(item):
	return permanent_items.has(item) || temporary_items.has(item);

func store_items():
	permanent_items.append_array(temporary_items);
	temporary_items.clear()

func reset_items():
	temporary_items.clear()
	player_item_change.emit()

func set_initial_items(items):
	permanent_items.clear()
	temporary_items.clear()
	set_initial_state()
	for item in items:
		pickup_item(item);
	store_items();

func get_all_items():
	var items = [];
	items.append_array(permanent_items)
	items.append_array(temporary_items)
	return items;

func set_initial_state():
	can_jump = false;
	max_djumps = 0;
	djumps = 0;
	can_dash = false
	weapons = []
	weapon = null;
	$Sword/Right.modulate.a = 0
	$Sword/Left.modulate.a = 0
	$Sword/Up.modulate.a = 0
	$Sword/Down.modulate.a = 0
	$Sword/Right.visible = true
	$Sword/Left.visible = true
	$Sword/Up.visible = true
	$Sword/Down.visible = true
	bullets = 4;

func handle_rnd_stuff(delta):
	handle_dash(delta)
	handle_weapon_switching()

func handle_dash(delta):
	if current_dash_duration > 0:
		current_dash_duration = max(0, current_dash_duration - delta)
		velocity.y = 0
	if current_dash_cooldown > 0:
		current_dash_cooldown = max(0, current_dash_cooldown - delta)
	
	if is_on_floor() && has_item(ITEMS.DASH):
		can_dash = true
	
	if has_item(ITEMS.DASH) && Input.is_action_just_pressed("button_dash") && can_dash && current_dash_cooldown == 0:
		current_dash_duration = dash_duration;
		current_dash_cooldown = dash_cooldown;
		can_dash = false
		if Input.is_action_pressed("button_left"):
			dash_direction = DIR.LEFT
		elif Input.is_action_pressed("button_right"):
			dash_direction = DIR.RIGHT
		else:
			dash_direction = DIR.RIGHT if xscale else DIR.LEFT

	if current_dash_duration > 0:
		if dash_direction == DIR.LEFT:
			velocity.x = -dash_speed
		elif dash_direction == DIR.RIGHT:
			velocity.x = dash_speed
	
func handle_walljumping(delta):
	just_walljumped = false
	if current_wall_jump_duration > 0:
		current_wall_jump_duration = max(0, current_wall_jump_duration - delta)
	
	if is_on_wall_only() && has_item(ITEMS.WALL_JUMP):
		is_walljumping = true
		djumps = max_djumps
		if velocity.y > 0:
			v_speed_modifier = 0.5
	else:
		is_walljumping = false
	
	if is_walljumping:
		#v_speed_modifier = 0.2
		var jump_direction = get_wall_normal()
		
		var walljumping_action = func():
			velocity.x = jump_direction.x * h_speed
			velocity.y = -s_jump_speed
			is_walljumping = false
			GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndJump)
			wall_jump_direction = DIR.RIGHT if jump_direction.x > 0 else DIR.LEFT;
			current_wall_jump_duration = wall_jump_duration;
			just_walljumped = true;
			
			# Emit the "player_walljumped" signal
			player_walljumped.emit()
		
		# Walljumping should only happen if we hold the jump button first
		if Input.is_action_just_pressed("button_jump"):
			walljumping_action.call()
	
	if current_wall_jump_duration > 0:
		if wall_jump_direction == DIR.RIGHT:
			velocity.x = h_speed
		else:
			velocity.x = -h_speed
		
func handle_weapon_switching():
	var current_weapons = weapons.size()
	if current_weapons > 1 && Input.is_action_just_pressed("button_switch_weapon"):
		var index = weapons.find(weapon)
		weapon = weapons[(index + 1) % current_weapons]
		player_item_change.emit()
		
# Shooting logic
func handle_shooting(delta):
	if weapon == ITEMS.GUN:
		handle_gun(delta)
	elif weapon == ITEMS.SWORD:
		handle_sword(delta)

func handle_gun(delta):
	if current_gun_recoil_duration > 0:
		current_gun_recoil_duration = max(0, current_gun_recoil_duration - delta)
	if current_autofire_timer > 0:
		current_autofire_timer = max(0, current_autofire_timer - delta);
	
	if is_on_floor() || (is_on_wall_only() && has_item(ITEMS.WALL_JUMP)):
		current_bullets = bullets
	
	if Input.is_action_just_pressed("button_shoot") || (Input.is_action_pressed("button_shoot") && current_autofire_timer == 0):
		
			# An equivalent to gamemaker's "instance_number() < 4"
		# It checks how many nodes belonging to the "Bullet" group
		# exist in the current scene
		#if get_tree().get_nodes_in_group("Bullet").size() < 4:
		if current_bullets > 0:
			current_bullets -= 1;
			current_autofire_timer = autofire_timer;
			# Loads the bullet scene, instances it, assigns the shooting direction
			# and global position, makes a sound and then adds it to the main scene 
			# (the actual game)
			var create_bullet_id: AnimatableBody2D = create_bullet.instantiate()
			
			# Bullet's x coordinate:
			#	-Takes into account the global x
			#	-The bullet spacing, relative to where we are looking at 
			if Input.is_action_pressed("button_up"):
				create_bullet_id.global_position = Vector2(global_position.x, global_position.y + 5)
				create_bullet_id.looking_at = DIR.UP
				gun_recoil_direction = DIR.DOWN
			elif Input.is_action_pressed("button_down"):
				create_bullet_id.global_position = Vector2(global_position.x, global_position.y + 5)
				create_bullet_id.looking_at = DIR.DOWN
				gun_recoil_direction = DIR.UP
			else:
				create_bullet_id.global_position = Vector2(global_position.x, global_position.y + 5)
				if xscale:
					create_bullet_id.looking_at = DIR.RIGHT
					gun_recoil_direction = DIR.LEFT
				else:
					create_bullet_id.looking_at = DIR.LEFT
					gun_recoil_direction = DIR.RIGHT
				
			if has_item(ITEMS.GUN_RECOIL):
				match gun_recoil_direction:
					DIR.UP:
						velocity.y = -200
					DIR.DOWN:
						if velocity.y < 100:
							velocity.y = 100
					DIR.LEFT, DIR.RIGHT:
						current_gun_recoil_duration = gun_recoil_duration;
			GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndShoot)
			
			# After everything is set and done, creates the bullet
			get_parent().add_child(create_bullet_id)
	
	if current_gun_recoil_duration > 0:
		velocity.x = gun_recoil_speed if gun_recoil_direction == DIR.RIGHT else -gun_recoil_speed

func handle_sword(delta):
	if current_sword_duration > 0:
		current_sword_duration = max(0, current_sword_duration - delta)
	if current_sword_cooldown > 0:
		current_sword_cooldown = max(0, current_sword_cooldown - delta)
	if current_side_bounce_duration > 0:
		current_side_bounce_duration = max(0, current_side_bounce_duration - delta)
		velocity.x = side_bounce_speed if side_bounce_direction == DIR.RIGHT else -side_bounce_speed
	
	if Input.is_action_just_pressed("button_shoot") && current_sword_cooldown == 0:
		current_sword_duration = sword_duration;
		current_sword_cooldown = sword_cooldown;
		if Input.is_action_pressed("button_down"):
			sword_node = $Sword/Down
		elif Input.is_action_pressed("button_up"):
			sword_node = $Sword/Up
		elif Input.is_action_pressed("button_left"):
			sword_node = $Sword/Left
		elif Input.is_action_pressed("button_right"):
			sword_node = $Sword/Right
		else:
			sword_node = $Sword/Right if xscale else $Sword/Left;
		
		if has_item(ITEMS.SWORD_BOUNCE):
			sword_node.get_node("Area2D/CollisionShape2D").set_deferred("disabled", false);
	
	if current_sword_duration > 0:
		sword_node.modulate.a = current_sword_duration / sword_duration;
	else:
		sword_node.modulate.a = 0;
		sword_node.get_node("Area2D/CollisionShape2D").set_deferred("disabled", true);

func _on_bounce():
	# don't bounce twice in 1 swing
	sword_node.get_node("Area2D/CollisionShape2D").set_deferred("disabled", true);
	

func _on_right_sword_bounce(body: Node2D) -> void:
	side_bounce_direction = DIR.LEFT
	current_side_bounce_duration = side_bounce_duration
	_on_bounce()


func _on_left_sword_bounce(body: Node2D) -> void:
	side_bounce_direction = DIR.RIGHT
	current_side_bounce_duration = side_bounce_duration
	_on_bounce()


func _on_down_sword_bounce(body: Node2D) -> void:
	velocity.y = -300
	djumps = max_djumps
	_on_bounce()


func _on_up_sword_bounce(body: Node2D) -> void:
	if velocity.y < 200:
		velocity.y = 200;
	_on_bounce()
