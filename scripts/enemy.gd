extends CharacterBody2D

var speed = 40
var player_chase = false
var player = null

var health = 100
var can_take_damage = true

func _physics_process(delta: float) -> void:
	
	if player_chase:
		var direction = (player.position - position).normalized()
		velocity = direction*speed
		if direction.x>=0:
			$AnimatedSprite2D.flip_h=false
		else:
			$AnimatedSprite2D.flip_h=true
			
		$AnimatedSprite2D.play("walk")
	else:
		velocity = Vector2(0,0)
		$AnimatedSprite2D.play("idle")
	move_and_slide()
	
		
# Only chase the player (not NPCs or other bodies)
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		player_chase = true


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		player_chase = false
	


# Called by whatever hits this enemy (e.g. the player's attack).
# damage_cooldown makes it briefly invulnerable after each hit.
func take_damage(amount: int) -> void:
	if not can_take_damage:
		return
	health -= amount
	$damage_cooldown.start()
	can_take_damage = false
	print("slime health = ", health)
	if health <= 0:
		queue_free()


func _on_damage_cooldown_timeout() -> void:
	can_take_damage=true
