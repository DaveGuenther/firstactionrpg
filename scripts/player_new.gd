extends CharacterBody2D

@export var yes=1
@onready var ray_cast_2d = $RayCast2D
@onready var amount: Label = $HUD/Coins/Amount
@onready var quest_tracker: ColorRect = $HUD/QuestTracker
@onready var title: Label = $HUD/QuestTracker/Details/Title
@onready var objectives: VBoxContainer = $HUD/QuestTracker/Details/Objectives
@onready var quest_manager: Node2D = QuestManager


const max_speed = 100
const accel = 500
const friction = 700

var input = Vector2.ZERO

var enemy_in_attack_range = false
var enemy_attack_cooldown = true
var health = 160
var player_alive = true

var attack_in_progress = false

var can_move = true
#Dialog & Quest vars
# Backed by global so the selected quest and tracker visibility survive
# scene changes, which destroy and recreate this player node.
var selected_quest: Quest:
	get: return global.selected_quest
	set(value): global.selected_quest = value
var quest_tracker_hidden: bool:
	get: return global.quest_tracker_hidden
	set(value): global.quest_tracker_hidden = value
var coin_amount = 0

const speed = 100
var current_dir = "none"

func _ready():
	get_input()
	global.player = self
	$AnimatedSprite2D.play("front_idle")
	update_quest_tracker(selected_quest)
	update_coins()
	
	# Siognal connections
	quest_manager.quest_updated.connect(_on_quest_updated)
	quest_manager.objective_updated.connect(_on_objective_updated)

func _physics_process(delta):
	if can_move:
		player_movement(delta)
		enemy_attack()
		attack()
	interact()
	
	if health <=0:
		player_alive = false
		health=0
		print("player has been killed")
		self.queue_free()


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
		health = health-20
		enemy_attack_cooldown=false
		$damage_cooldown.start()
		print(health)
	

func set_camera_limits(limits: Dictionary):
	$MainCamera.limit_left = limits["left"]
	$MainCamera.limit_top = limits["top"]
	$MainCamera.limit_right = limits["right"]
	$MainCamera.limit_bottom = limits["bottom"]	


func _on_damage_cooldown_timeout() -> void:
	enemy_attack_cooldown = true


func attack():
	var dir = current_dir
	
	if Input.is_action_just_pressed("attack"):
		global.player_current_attack = true
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
	global.player_current_attack=false
	attack_in_progress = false
	

func interact():
	if can_move:
		if Input.is_action_just_pressed("ui_interact"):
			var target = ray_cast_2d.get_collider()
			if target != null: # If we are lookinhg at the Item and are close enough
				if target.is_in_group("NPC"):
					#print("I'm talking to an NPC!")
					can_move=false
					target.start_dialog()
					check_quest_objectives(target.npc_id, "talk_to")
					
				if target.is_in_group("Item"):
					print("I'm interacting with an item!")
					if is_item_needed(target.item_id):
						check_quest_objectives(target.item_id, "collection", target.item_quantity)
						global.mark_item_collected(target.get_instance_key())
						target.queue_free()
					else:
						print("Item not needed for any active quest")
	
	# Open/Close quest log
	if Input.is_action_just_pressed("ui_quest_menu"):
		quest_manager.show_hide_log()

	# Bring back a manually-closed quest tracker
	if Input.is_action_just_pressed("quest_tracker_toggle"):
		quest_tracker_hidden = false
		update_quest_tracker(selected_quest)


func _on_quest_tracker_close_pressed():
	quest_tracker_hidden = true
	quest_tracker.visible = false


# Check if quest item is needed
func is_item_needed(item_id: String) -> bool:
	if selected_quest != null:
		for objective in selected_quest.objectives:
			if objective.target_id == item_id and objective.target_type == "collection" and not objective.is_completed:
				return true
	return false
	
func check_quest_objectives(target_id: String, target_type: String, quantity: int=1):
	if selected_quest == null:
		return
	var objective_updated = false
	for objective in selected_quest.objectives:
		if objective.target_id == target_id and objective.target_type == target_type and not objective.is_completed:
			print("Completing objective for quest: ", selected_quest.quest_name)
			selected_quest.complete_objective(objective.id, quantity)
			objective_updated = true
			break
			
	# Provide Rewards
	if objective_updated:
		if selected_quest.is_completed():
			handle_quest_completion(selected_quest)
	
		# Update UI
		update_quest_tracker(selected_quest)

# coin reqards
func handle_quest_completion(quest: Quest):
	for reward in quest.rewards:
		if reward.reward_type == "coins":
			coin_amount += reward.reward_amount
			update_coins()
	update_quest_tracker(quest)
	quest_manager.update_quest(quest.quest_id, "completed")
	
# Update coin UI
func update_coins():
	amount.text = str(coin_amount)

# Update trascker UI
func update_quest_tracker(quest: Quest):
	# If we have an active quest, populate the quest_tracker with quest details
	if quest:
		quest_tracker.visible = not quest_tracker_hidden
		title.text = quest.quest_name
		
		for child in objectives.get_children():
			child.queue_free()
			#objectives.remove_child(child)
			
		for objective in quest.objectives:
			var label = Label.new()
			label.text = objective.description
			
			if objective.is_completed:
				label.add_theme_color_override("font_color", Color(0,1,0))
			else:
				label.add_theme_color_override("font_color", Color(1,0,0))
				
			objectives.add_child(label)
	# no active quest, hide tracker
	else:
		quest_tracker.visible=false
		
			
# update tracker if quest is complete
func _on_quest_updated(quest_id: String):
	var quest = quest_manager.get_quest(quest_id)
	if quest == selected_quest:
		update_quest_tracker(quest)
	
#Update tracker if objective is complete
func _on_objective_updated(quest_id: String, objective_id: String):
	if selected_quest and selected_quest.quest_id == quest_id:
		update_quest_tracker(selected_quest)
