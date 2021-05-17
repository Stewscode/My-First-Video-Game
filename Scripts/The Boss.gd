extends KinematicBody2D


# Declare member variables here:
var curHp : int = 20
var maxHp : int = 20
 
var moveSpeed : int = 150
var xpToGive : int = 10
 
var damage : int = 1
var melee_attack_damage = 3
var attackRate : float = 1.0
var attack_range : int = 0
var chase_range : int = 1000

var moveDirection = 110
var velocity = Vector2()
var movingVel = Vector2()
var facingDir = Vector2()

var animation_name
var curAttackAnimation
var current_animation
var last_animation = ""
var is_melee_right = false
var is_melee_left = false
var is_melee_up = false
var is_melee_down = false
 
onready var target = get_node("/root/MainScene/Player")

var time
onready var timer = $Timer
onready var timer2 = $"Rest Timer"
onready var melee_attack_timer = $"Melee Attack Timer"
onready var charge_attack_timer = $"Charge Attack Timer"
onready var buffer_timer = $"Buffer Timer"

onready var animatedSprite = $AnimatedSprite
onready var random_position_generator = $"Random Position Generator"

onready var right_melee_area = $"Node2D/Melee Right"
onready var left_melee_area = $"Node2D/Melee Left"
onready var up_melee_area = $"Node2D/Melee Up"
onready var down_melee_area = $"Node2D/Melee Down"

onready var right_melee_collision = $"Node2D/Melee Right/CollisionPolygon2D"

var attack_charged = false
var melee_attack = false

var state = WANDER

enum {
	MOVE,
	ATTACK,
	BLOCK,
	IDLE,
	WANDER,
	MELEE,
	REST
}


func _physics_process (delta):
	#when hp drops below a certain point begin the next phase
	if curHp < 15:
		pass
	
	check_if_melee_state()
		
	# checks the "state" variable and sees whether it is currently equal to MOVE, ATTACK or DODGE.
	# It then goes to whichever "state" it matches and carries out the code in there. 
	match state: # similar to switch statements
		MOVE:
			move()
		
		ATTACK:
			attack()
		
		BLOCK: # not yet implemented
			pass
		
		IDLE:
			idle()
			
		WANDER:
			var direction = global_position.direction_to(random_position_generator.random_position)
			velocity = velocity.move_toward(direction * moveSpeed, 210 * delta)
			wander(direction)



# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = attackRate # set timer time to same as attack rate of the enemy
	timer.start() # start the timer



func wander(a_vector : Vector2):
	var target_position = random_position_generator.random_position # gets the player's position as a vector
	moveDirection = rad2deg(get_angle_to(target_position)) # gets the angle from this current node to the target node in radians, and then converts it to degrees (godot works in 0 to 180 and 0 to -180, instead of 0 to 360, weird).
	
	if  get_distance_to(target) > attack_range and get_distance_to(target) < chase_range:
		state = MOVE
	if random_position_generator.get_time_left() == 0:
		state = randomize_states([IDLE, WANDER])
		random_position_generator.set_timer(rand_range(1, 3))
		
		
	if a_vector.x > 0:
		movingVel.x = 1
		facingDir = Vector2(1, 0)
			
	if a_vector.x < 0:
		movingVel.x = -1
		facingDir = Vector2(-1, 0)

	if a_vector.y < 0:
		movingVel.y = -1
		facingDir = Vector2(0, -1)

	if a_vector.y > 1:
		movingVel.y = 1
		facingDir = Vector2(0, 1)
	
	if global_position.distance_to(random_position_generator.random_position) <= 5:

		state = randomize_states([IDLE, WANDER])
		random_position_generator.set_timer(rand_range(1, 3))
		
	move_and_slide(velocity)
	manage_animations()

# function which allows an enemy to take damage
# pass in amount of damage to be taken
func take_damage(dmg): 
	curHp -= dmg # takes away damage taken from hp pool
	if curHp <= 0: # if the enemy's hp drops to 0 then it will "die".
		die() # call die() function
 
# function to let enemy do things once it loses all its HP, eg die.
func die ():
	target.give_xp(xpToGive) # function to give XP to player .
	queue_free() # deletes the node - making it disappear and essentially die.

func idle():
	movingVel.x = 0
	movingVel.y = 0
	
	# if target is outside attack range and inside chase range:
	if  get_distance_to(target) > attack_range and get_distance_to(target) < chase_range:
		state = MOVE
	
	if random_position_generator.get_time_left() == 0:
		state = randomize_states([IDLE, WANDER])
		random_position_generator.set_timer(rand_range(1, 3))
		
	manage_animations()

func get_distance_to(target):
	var distance_to_target = position.distance_to(target.position)
	return distance_to_target

func move():
	movingVel = Vector2()
	var distanceToTarget = position.distance_to(target.position)
	
	# if target is outside attack range and inside chase range:
	if distanceToTarget > attack_range and distanceToTarget < chase_range:
		var vel = (target.position - position).normalized()
		move_and_slide(vel * moveSpeed) # let enemy move
	
	var player = target.position # gets the player's position as a vector
	moveDirection = rad2deg(get_angle_to(player)) # gets the angle from this current node to the player node in radians and convert it to degrees (godot work in 0 to 180 and 0 to -180, instead of 0 to 360, weird).
	
	# up
	if moveDirection > -135 and moveDirection < -45:
		movingVel.y = -1
		facingDir = Vector2(0, -1)
	# down
	if moveDirection > 45 and moveDirection < 135:
		movingVel.y = 1
		facingDir = Vector2(0, 1)
	# left
	if moveDirection < -135 or moveDirection > 135:
		movingVel.x = -1
		facingDir = Vector2(-1, 0)
	# right
	if moveDirection > -45 and moveDirection < 45:
		movingVel.x = 1
		facingDir = Vector2(1, 0)
	# if target is out of enemy's chase radius then stop	
	if distanceToTarget > chase_range:
		state = randomize_states([IDLE, WANDER])

	if position.distance_to(target.position) <= attack_range: # if the target is within the attack range :
		state = ATTACK
		stop_moving()
		attack()
	
	manage_animations()

func stop_moving():
	#animatedSprite.stop()
	movingVel.x = 0
	movingVel.y = 0

func attack():
	if position.distance_to(target.position) <= attack_range: # if the target is within the attack range :
		state = ATTACK
	else:
		state = MOVE

func randomize_states(list_of_states):
	list_of_states.shuffle()
	return list_of_states.pop_front()
	

# function to manage the seperate attack animations
func manage_attack_animations():
	if facingDir.x == 1:
		curAttackAnimation = "AttackRight" # set's current animation to the appropriate animation
		play_animation(curAttackAnimation) # plays said animation
		last_animation = curAttackAnimation
		animation_name = curAttackAnimation

	if facingDir.x == -1:
		curAttackAnimation = "AttackLeft"
		play_animation(curAttackAnimation)
		last_animation = curAttackAnimation
		animation_name = curAttackAnimation

	if facingDir.y == -1:
		curAttackAnimation = "AttackUp"
		play_animation(curAttackAnimation)
		last_animation = curAttackAnimation
		animation_name = curAttackAnimation

	if facingDir.y == 1:
		curAttackAnimation = "AttackDown"
		play_animation(curAttackAnimation)
		last_animation = curAttackAnimation
		animation_name = curAttackAnimation
			
	if !facingDir.x == 1 && !facingDir.x == -1 && !facingDir.y == 1 && !facingDir.y == -1:
		curAttackAnimation = "AttackDown"
		play_animation(curAttackAnimation)
		last_animation = curAttackAnimation
		animation_name = curAttackAnimation


# function which checks the current velocity and plays an animation depending on that.
# if the velocity is 0, it will chack what direction the character is facing and play an
# animation depending on that.
func manage_animations ():
	if movingVel.x > 0:
		play_animation("MoveRight")
		animation_name = "MoveRight"
	elif movingVel.x < 0:
		play_animation("MoveLeft")
		animation_name = "MoveLeft"
	elif movingVel.y < 0:
		play_animation("MoveUp")
		animation_name = "MoveUp"
	elif movingVel.y > 0:
		play_animation("MoveDown")
		animation_name = "MoveDown"
		
	elif facingDir.x == 1:
		play_animation("IdleRight")
		animation_name = "IdleRight"
		
	elif facingDir.x == -1:
		play_animation("IdleLeft")
		animation_name = "IdleLeft"
		
	elif facingDir.y == -1:
		play_animation("IdleUp")
		animation_name = "IdleUp"
		
	elif facingDir.y == 1:
		play_animation("IdleDown")
		animation_name = "IdleDown"
		
	#elif movingVel.x == 0:
		#manage_idle_animations()


# function to switch to different idle animations
func manage_idle_animations():
	if facingDir.x == 1:
		play_animation("IdleRight")
	elif facingDir.x == -1:
		play_animation("IdleLeft")
	elif facingDir.y == -1:
		play_animation("IdleUp")
	elif facingDir.y == 1:
		play_animation("IdleDown")


# take an animation and play that animation.
func play_animation (anim_name):
	if animatedSprite.animation != anim_name: # if the same animation is not currently playing
		animatedSprite.play(anim_name) # plays animation


# function which plays various charging animations depending on the direction the player is in
func charge_attack():
	if facingDir.x == 1:
		current_animation = "ChargeMeleeRight" # set's current animation to the appropriate animation
		play_animation(current_animation) # plays said animation
		last_animation = current_animation
		animation_name = current_animation

	if facingDir.x == -1:
		current_animation = "ChargeMeleeLeft"
		play_animation(current_animation)
		last_animation = current_animation
		animation_name = current_animation
		
	if facingDir.y == -1:
		current_animation = "ChargeMeleeUp"
		play_animation(current_animation)
		last_animation = current_animation
		animation_name = current_animation

	if facingDir.y == 1:
		current_animation = "ChargeMeleeDown"
		play_animation(current_animation)
		last_animation = current_animation
		animation_name = current_animation
			
	if !facingDir.x == 1 && !facingDir.x == -1 && !facingDir.y == 1 && !facingDir.y == -1:
		current_animation = "ChargeMeleeDown"
		play_animation(current_animation)
		last_animation = current_animation
		animation_name = current_animation
	
	
func _on_Timer_timeout():
	
	if state == MELEE:
		if last_animation == "":
			charge_attack()
			charge_attack_timer.start(1)
			
		elif last_animation == "ChargeMeleeRight" and attack_charged == true || "ChargeMeleeLeft" and attack_charged == true || "ChargeMeleeUp" and attack_charged == true || "ChargeMeleeDown" and attack_charged == true:
			melee_attack_timer.start(1)
			attack_charged = false
			manage_attack_animations()
			target.take_damage(melee_attack_damage) # take away hp from the "target", eg player.

		elif last_animation == "AttackRight" and melee_attack == true and attack_charged == false || "AttackLeft" and melee_attack == true and attack_charged == false || "AttackUp" and melee_attack == true and attack_charged == false || "AttackDown" and melee_attack == true and attack_charged == false:
			charge_attack_timer.start(1)
			melee_attack = false 
			charge_attack()


func stop_timers():
	melee_attack_timer.stop()
	charge_attack_timer.stop()


func _on_Melee_Attack_Timer_timeout():
	melee_attack = true
	attack_charged = false
	melee_attack_timer.stop()


func _on_Charge_Attack_Timer_timeout():
	attack_charged = true
	charge_attack_timer.stop()


func _on_AnimatedSprite_animation_finished():
	if animation_name == "AttackRight":
		animatedSprite.stop()
		#curAttackAnimation = null
	elif animation_name == "AttackLeft":
		animatedSprite.stop()
		#curAttackAnimation = null
	elif animation_name == "AttackUp":
		animatedSprite.stop()
		#curAttackAnimation = null
	elif animation_name == "AttackDown":
		animatedSprite.stop()
		#curAttackAnimation = null


func _on_Melee_Right_body_entered(body):
	if body == target:
		is_melee_right = true
		facingDir = Vector2(1, 0)
		state = MELEE

func _on_Melee_Right_body_exited(body):
	if body == target:
		is_melee_right = false


func _on_Melee_Left_body_entered(body):
	if body == target:
		is_melee_left = true
		facingDir = Vector2(-1, 0)
		state = MELEE

func _on_Melee_Left_body_exited(body):
	if body == target:
		is_melee_left = false


func _on_Melee_Up_body_entered(body):
	if body == target:
		is_melee_up = true
		facingDir = Vector2(0, -1)
		state = MELEE

func _on_Melee_Up_body_exited(body):
	if body == target:
		is_melee_up = false


func _on_Melee_Down_body_entered(body):
	if body == target:
		is_melee_down = true
		facingDir = Vector2(0, 1)
		state = MELEE

func _on_Melee_Down_body_exited(body):
	if body == target:
		is_melee_down = false


# checks if if lpayer is any of the melee ranges and if they aren't in any then switches the state back to "MOVE"
func check_if_melee_state():
	if is_melee_left == false and is_melee_right == false and is_melee_up == false and is_melee_down == false:
		state = MOVE
