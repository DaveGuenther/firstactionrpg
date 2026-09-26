extends CharacterBody2D

@onready var ray_cast_2d = $RayCast2D


const max_speed = 100
const accel = 500
const friction = 700

var input = Vector2.ZERO

var enemy_in_attack_range = false
var enemy_attack_cooldown = true
var player_alive = true

var attack_in_progress = false

var can_move = true
# Health lives in the PlayerStats autoload, coins/items in Inventory and
# quests in QuestManager, so they survive scene changes. The coin counter
# and quest tracker are in the HUD scene.

const speed = 100
var current_dir = "none"

func _ready():
	get_input()
	$AnimatedSprite2D.play("front_idle")

	# Signal connections
	PlayerStats.died.connect(_on_died)
	# Freeze movement while a dialog is open
	DialogManager.dialog_started.connect(func(_npc): can_move = false)
	DialogManager.dialog_ended.connect(func(_npc): can_move = true)

func _physics_process(delta):
	if can_move:
		player_movement(delta)
		enemy_attack()
		attack()
		hit_enemies()
	interact()

func _on_died():
	player_alive = false
	print("player has been killed")
	queue_free()


func get_input():
	input.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	input.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	
	return input.normalized()
	

	
func player_movement(delta):

	input = get_input()
	
	if input == Vector2.ZERO:
		if velocity.length() > (friction*delta):
			velocity -= velocity.normalized() * (friction*delta)
	
		else:
			velocity = Vector2.ZERO
		
	else:
		velocity += (input * accel * delta)
		velocity = velocity.limit_length(max_speed)
		
		# Turn raycast towward direction
		ray_cast_2d.target_position=input*25

	if input.y>0 && input.x==0:
		current_dir="down"
		play_anim(1) # play animation number 1 (side_walk)
	if input.y<0 && input.x==0:
		current_dir="up"
		play_anim(1) # play animation number 1 (side_walk)
	if input.x>0:
		current_dir="right"
		play_anim(1) # play animation number 1 (side_walk)
	if input.x<0:
		current_dir="left"
		play_anim(1) # play animation number 1 (side_walk)
	if input == Vector2.ZERO:
		play_anim(0) # play animation number 1 (side_walk)
	
	
	move_and_slide()
	
	
func play_anim(movement):
	var dir = current_dir
	var anim = $AnimatedSprite2D
	
	if dir=="right":
		anim.flip_h = false
		if movement == 1:
			anim.play("side_walk")
		elif movement == 0:
			if attack_in_progress == false:
				anim.play("side_idle")

			
	if dir=="left":
		anim.flip_h = true
		if movement == 1:
			anim.play("side_walk")
		elif movement == 0:
			if attack_in_progress == false:
				anim.play("side_idle")			

	if dir=="down":
		anim.flip_h = true
		if movement == 1:
			anim.play("front_walk")
		elif movement == 0:
			if attack_in_progress == false:
				anim.play("front_idle")			

	if dir=="up":
		anim.flip_h = true
		if movement == 1:
			anim.play("back_walk")
		elif movement == 0:
			if attack_in_progress == false:
				anim.play("back_idle")			


func _on_player_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		enemy_in_attack_range = true



func _on_player_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		enemy_in_attack_range = false


func enemy_attack():
	if enemy_in_attack_range and enemy_attack_cooldown:
		PlayerStats.take_damage(20)
		enemy_attack_cooldown=false
		$damage_cooldown.start()
		print(PlayerStats.health)
	

func set_camera_limits(left: int, top: int, right: int, bottom: int):
	$MainCamera.limit_left = left
	$MainCamera.limit_top = top
	$MainCamera.limit_right = right
	$MainCamera.limit_bottom = bottom


func _on_damage_cooldown_timeout() -> void:
	enemy_attack_cooldown = true


func attack():
	var dir = current_dir
	
	if Input.is_action_just_pressed("attack"):
		attack_in_progress = true
		
		if dir == "right":
			$AnimatedSprite2D.flip_h=false
			$AnimatedSprite2D.play("side_attack")
			$attack_cooldown.start()
			
		if dir == "left":
			$AnimatedSprite2D.flip_h=true
			$AnimatedSprite2D.play("side_attack")
			$attack_cooldown.start()

		if dir == "down":
			$AnimatedSprite2D.flip_h=false
			$AnimatedSprite2D.play("front_attack")
			$attack_cooldown.start()

		if dir == "up":
			$AnimatedSprite2D.flip_h=false
			$AnimatedSprite2D.play("back_attack")
			$attack_cooldown.start()
			

func _on_attack_cooldown_timeout() -> void:
	$attack_cooldown.stop()
	attack_in_progress = false

# While an attack is in progress, damage enemies inside the player's hitbox.
# Each enemy's own cooldown stops it being hit every frame.
func hit_enemies():
	if not attack_in_progress:
		return
	for body in $player_hitbox.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(20)
	

func interact():
	if can_move:
		if Input.is_action_just_pressed("ui_interact"):
			var target = ray_cast_2d.get_collider()
			if target != null: # If we are lookinhg at the Item and are close enough
				if target.is_in_group("NPC"):
					#print("I'm talking to an NPC!")
					# DialogManager.dialog_started freezes movement
					target.start_dialog()
					QuestManager.check_quest_objectives(target.npc_id, Objective.Type.TALK_TO)
					
				if target.is_in_group("Item"):
					print("Picked up ", target.item_quantity, " ", target.item_id)
					# QuestManager updates collection objectives from Inventory
					Inventory.add_item(target.item_id, target.item_quantity)
					WorldState.mark_item_collected(target.get_instance_key())
					target.queue_free()
	
	# Open/Close quest log
	if Input.is_action_just_pressed("ui_quest_menu"):
		QuestManager.show_hide_log()
