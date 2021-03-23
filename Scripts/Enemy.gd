extends KinematicBody2D


# Declare member variables here:
var curHp : int = 1
var maxHp : int = 1
 
var moveSpeed : int = 150
var xpToGive : int = 30
 
var damage : int = 1
var attackRate : float = 1.0
var attackDist : int = 80
var chaseDist : int = 400

var moveDirection = 110
var movingVel = Vector2()
var facingDir = Vector2()
 
onready var timer = $Timer
onready var target = get_node("/root/MainScene/Player")
onready var animatedSprite = $AnimatedSprite


# take an animation and play that animation.
func play_animation (anim_name):
	if animatedSprite.animation != anim_name: # if the same animation is not currently playing
		animatedSprite.play(anim_name) # plays animation


# function which checks the current velocity and plays an animation depending on that.
# if the velocity is 0, it will chack what direction the character is facing and play an
# animation depending on that.
func manage_animations ():
	if movingVel.x > 0:
		play_animation("MoveRight")
	elif movingVel.x < 0:
		play_animation("MoveLeft")
	elif movingVel.y < 0:
		play_animation("MoveUp")
	elif movingVel.y > 0:
		play_animation("MoveDown")
	elif facingDir.x == 1:
		play_animation("IdleRight")
	elif facingDir.x == -1:
		play_animation("IdleLeft")
	elif facingDir.y == -1:
		play_animation("IdleUp")
	elif facingDir.y == 1:
		play_animation("IdleDown")


# function which allows an enemy to take damage
# pass in amount of damage to be taken
func take_damage (dmgToTake): 
	curHp -= dmgToTake # takes away damage taken from hp pool
	if curHp <= 0: # if the enemy's hp drops to 0 then it will "die".
		die() # call die() function
 
# function to let enemy do things once it loses all its HP, eg die.
func die ():
	target.give_xp(xpToGive) # function to give XP to player .
	queue_free() # deletes the node - making it disappear and essentially die.


func _physics_process (delta):
	movingVel = Vector2()
	var distanceToTarget = position.distance_to(target.position)
	
	
	if distanceToTarget > attackDist and distanceToTarget < chaseDist:
		var vel = (target.position - position).normalized()
		move_and_slide(vel * moveSpeed) # let enemy move
	
	
	
	var player = target.position # gets the player's position as a vector
	moveDirection = rad2deg(get_angle_to(player)) # gets the angle from this current node to the player node in radians and convert it to degrees (godot work in 0 to 180 and 0 to -180, instead of 0 to 360, weird).
	#print(moveDirection) # print the angle between the player and the current node for testing puposes
	
	if moveDirection > -135 and moveDirection < -45:
		movingVel.y = -1
		facingDir = Vector2(0, -1)
	if moveDirection > 45 and moveDirection < 135:
		movingVel.y = 1
		facingDir = Vector2(0, 1)
	if moveDirection < -135 or moveDirection > 135:
		movingVel.x = -1
		facingDir = Vector2(-1, 0)
	if moveDirection > -45 and moveDirection < 45:
		movingVel.x = 1
		facingDir = Vector2(1, 0)
	if distanceToTarget > chaseDist: # if target is out of enemy's chase radius then stop playing the running animations by setting its moving velocity to 0 and leave the facing direction the same to make them face the direcion they were last facing.
		movingVel.x = 0
		movingVel.y = 0
		
	manage_animations()


# Called when the node enters the scene tree for the first time.
func _ready():
	timer.wait_time = attackRate # set timer time to same as attack rate of the enemy
	timer.start() # start the timer


func _on_Timer_timeout():
	if position.distance_to(target.position) <= attackDist: # if the target is within the attack range, deal damage.
		target.take_damage(damage) # take away hp from the "target", eg player.
