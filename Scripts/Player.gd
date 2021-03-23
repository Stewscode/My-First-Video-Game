extends KinematicBody2D


# Declare member variables here:
var curHp : int = 10
var maxHp : int = 10
var curStamina : int = 100
var maxStamina: int = 100
var moveSpeed : int = 250
var dodgeSpeed : int = 500
var dodgeStaminaUse : int = 60
var damage : int = 1
var interactDist : int = 70

var gold : int = 0 
var curLevel : int = 1
var curXp : int = 0
var xpToNextLevel : int = 100
var xpToLevelIncreaseRate : float = 1.2 # the rate at which your xp bar grows upon reaching a higher level.

 
var vel = Vector2()
var facingDir = Vector2() # has to be initialised to a direction so that if the attack button is pressed without first moving the character, it has a direction to attack in.
							 # otherwise the game will break if you try to attack before trying to move.

onready var userInterface = get_node("/root/MainScene/CanvasLayer/UI") # references the ui in the canvas layer
onready var rayCast = $RayCast2D # variable to reference the raycast node
onready var animatedSprite = $AnimatedSprite # variable to reference the animated sprite node
onready var ghost = get_node("res://Scenes/GhostEffect")

# attack animation handling global variables
var attackAnimationFinished = true
var curAttackAnimation

# dodge animation handling global variables
var dodgeAnimationFinished = true
var curDodgeAnimation
var dodgeVelocity
var dodgeVel = Vector2(0,1)

# a fixed set of constants
# it can be named as well if I need to make another one and can call the new one by enumName.MOVE for example.
enum {
	MOVE,
	ATTACK,
	DODGE,
	BLOCK
}

# initialises our "state" to MOVE, this will make it so the default state of our player is MOVE and will be allowed to move when game starts.
var state = MOVE


# Called when the node enters the scene tree for the first time.
func _ready():
	userInterface.update_level(curLevel) # calles the function which updates the player's level with it's current level from the UI node
	userInterface.update_health(curHp, maxHp)
	userInterface.update_experience(curXp, xpToNextLevel)
	userInterface.update_gold(gold)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process (delta):
	# checks the "state" variable and sees whether it is currently equal to MOVE, ATTACK or DODGE.
	# It then goes to whichever "state" it matches and carries out the code in there. 
	match state: # similar to switch statements
		MOVE:
			move()
		
		ATTACK:
			attack()
			
		DODGE:
			dodge()
		
		BLOCK: # not yet implemented
			pass


func dodge():
	if !facingDir.x == 1 && !facingDir.x == -1 && !facingDir.y == 1 && !facingDir.y == -1:
		var velocity = Vector2(0, 1)
		move_and_slide(velocity * dodgeSpeed)
	
	dodgeVelocity = (facingDir * dodgeSpeed)
	move_and_slide(dodgeVelocity)
	manage_dodge_animations()
	

func manage_dodge_animations():
#	if dodgeAnimationFinished == true: # checks if the dodgeAnimationFinished variable is true, eg; there is no animations currently playing
		if !facingDir.x == 1 && !facingDir.x == -1 && !facingDir.y == 1 && !facingDir.y == -1:
			curDodgeAnimation = "DodgeDown"
			play_animation(curDodgeAnimation)
			
		if facingDir.x == 1:
			curDodgeAnimation = "DodgeRight" # set's current animation to the appropriate animation
			play_animation(curDodgeAnimation) # plays said animation
				
		elif facingDir.x == -1:
			curDodgeAnimation = "DodgeLeft"
			play_animation(curDodgeAnimation)
				
		elif facingDir.y == -1:
			curDodgeAnimation = "DodgeUp"
			play_animation(curDodgeAnimation)
				
		elif facingDir.y == 1:
			curDodgeAnimation = "DodgeDown"
			play_animation(curDodgeAnimation)


func dodge_finished():
	state = MOVE


# function which manages the player when doing anything to do with attacking
func attack():
	print("Attacks")
	rayCast.cast_to = facingDir * interactDist # Sets the ray's destination point
	
	if rayCast.is_colliding(): # if raycast is colliding with something
		if rayCast.get_collider() is KinematicBody2D: # returns the first object that the ray intersects, or null if no object is intersecting the ray, and if that object is a KinematicBody2D then do stuff:
			rayCast.get_collider().take_damage(damage) # calls the KinematicBody's take_damage() function, causing it to take damage, eg you dealing damage.
			print("Dealt damage to a KinematicBody2D")
			
	# call the function
	manage_attack_animations()
	

# function to manage the seperate attack animations
func manage_attack_animations():
		if facingDir.x == 1:
			$AnimatedSprite.flip_h = false
			curAttackAnimation = "AttackRight" # set's current animation to the appropriate animation
			play_animation(curAttackAnimation) # plays said animation
	
		if facingDir.x == -1:
			$AnimatedSprite.flip_h = true
			curAttackAnimation = "AttackRight"
			play_animation(curAttackAnimation)
	
		if facingDir.y == -1:
			curAttackAnimation = "AttackUp"
			play_animation(curAttackAnimation)

		if facingDir.y == 1:
			curAttackAnimation = "AttackDown"
			play_animation(curAttackAnimation)
				
		if !facingDir.x == 1 && !facingDir.x == -1 && !facingDir.y == 1 && !facingDir.y == -1:
			curAttackAnimation = "AttackDown"
			play_animation(curAttackAnimation)




# function which is only called when an attack animation is finished playing
# simply sets the state back to MOVE so the player can begin moving again
func attack_finished():
	state = MOVE


func move():
	vel = Vector2() # reset velocity to 0 every frame.
	$AnimatedSprite.flip_h = false
	# check if an arrow key is being pressed and change velocity depending on that to move player.
	# will set direction to move in
	#will set the direction it is facing so we can have idle animations depending where the player is facing
	if Input.is_action_pressed("ui_up"):
		vel.y -= 1
		facingDir = Vector2(0, -1)
		
	if Input.is_action_pressed("ui_down"):
		vel.y += 1
		facingDir = Vector2(0, 1)
		
	if Input.is_action_pressed("ui_left"):
		vel.x -= 1
		facingDir = Vector2(-1, 0)
		
	if Input.is_action_pressed("ui_right"):
		vel.x += 1
		facingDir = Vector2(1, 0)
	
	# checks if the attack button is pressed and sets the state to ATTACK
	if Input.is_action_pressed("ui_attack"):
		state = ATTACK
		
	if Input.is_action_pressed("ui_dodge"):
		if curStamina >= dodgeStaminaUse:
			curStamina -= dodgeStaminaUse
			userInterface.update_stamina(curStamina, maxStamina)
			state = DODGE
		
	# normalize the velocity to prevent faster diagonal movement
	vel = vel.normalized()
	
	# move the player based on the velocity.
	move_and_slide(vel * moveSpeed, Vector2.ZERO)
	
	# call the manage animations function at the end of every frame to play the animations.
	manage_animations() 


# function called every frame
func _process (delta):
	if Input.is_action_just_pressed("ui_interact"): # checks if the interact button is pressed and does something
		interact() # calls interact function


# function check if any interactions are able to take place
func interact ():
	rayCast.cast_to = facingDir * interactDist # Sets the ray's destination point, 
											   # relative to the RayCast's position
	# checks if the raycast is colliding with anything and gets the object (and its methods) it is colliding with and does something with it:
	if rayCast.is_colliding():
		if rayCast.get_collider().has_method("on_interact"): # if not a KinematicBody then check if the object collided with has a method called "on_interact"
			rayCast.get_collider().on_interact(self) # returns the object that is collided with and calls its "on_interact" function on itself as a parameter.


# function to allow the player to take damage
# pass in amount of damage to take
func take_damage (dmgToTake):
	curHp -= dmgToTake # will take away damage from the current hp pool
	userInterface.update_health(curHp, maxHp) # call the updateHealthBar function every time player takes damage to show changes

	if curHp <= 0: # if hp reaches 0 then die
		die()
 

# funtion to handle what happens when our hp drops to 0
func die ():
	get_tree().reload_current_scene() # reloads the current scene to the beggining if we die.


# funtion to give XP to the player so that they can eventually level up
# pass in amount of xp to give
func give_xp (amount):
	curXp += amount # adds "amount" to the current xp pool.
	userInterface.update_experience(curXp, xpToNextLevel) # update experience bar
 
	if curXp >= xpToNextLevel: # checks if the current xp pool is greater or equal to the amount needed to level up.
		level_up() # if current xp is enough to level up then go to level_up().

# function to handle leveling once the current xp has met the conditions to level up
func level_up ():
	var overflowXp = curXp - xpToNextLevel # variable to store the xp which has overflowed
 
	xpToNextLevel *= xpToLevelIncreaseRate # multiplies the xp required for the next level by a fixed rate
	curXp = overflowXp # sets currrent xp to the amount overflowed (if any).
	curLevel += 1 # adds 1 to the current level to show progress, eg level 1 then 2 then 3 etc.
	userInterface.update_level(curLevel) # update player level 
	


# function to give gold to player
# pass in amount of gold to give player.
# can be used when passing over coins  or defeating enemies.
func give_gold (amount):
	gold += amount # just add "x" amount to gold amount
	userInterface.update_gold(gold) # update gold

# take an animation and play that animation.
func play_animation (anim_name):
	if animatedSprite.animation != anim_name: # if the same animation is not currently playing
		animatedSprite.play(anim_name) # plays animation

	
# function which checks the current velocity and plays an animation depending on that.
# if the velocity is 0, it will chack what direction the character is facing and play an
# animation depending on that.
func manage_animations ():
	if vel.x > 0:
		play_animation("MoveRight")
	elif vel.x < 0:
		play_animation("MoveLeft")
	elif vel.y < 0:
		play_animation("MoveUp")
	elif vel.y > 0:
		play_animation("MoveDown")
	elif facingDir.x == 1:
		play_animation("IdleRight")
	elif facingDir.x == -1:
		play_animation("IdleLeft")
	elif facingDir.y == -1:
		play_animation("IdleUp")
	elif facingDir.y == 1:
		play_animation("IdleDown")

func _on_StaminaRechargeTimer_timeout():
	if curStamina < maxStamina:
		curStamina += 1
		userInterface.update_stamina(curStamina, maxStamina)


func _on_AnimatedSprite_animation_finished():
	
	if state == ATTACK:
		
		if curAttackAnimation == "AttackDown": # if the current animation is set to the following attack animation...
			play_animation("IdleDown")
			attack_finished() # call this function
			
		if curAttackAnimation == "AttackUp":
			play_animation("IdleUp")
			attack_finished() # call this function
			
#		if curAttackAnimation == "AtackRight" && $AnimatedSprite.flip_h == true:
#			print("attack left finished")
#			play_animation("IdleLeft")
#			attack_finished() # call this function
			
		if curAttackAnimation == "AttackRight":
			print("attack right finished")
			play_animation("IdleRight")
			attack_finished() # call this function
			
	if state == DODGE:
		if curDodgeAnimation == "DodgeUp": # if the current animation is set to any of the following dodging animations...
			play_animation("IdleUp")
			dodge_finished() # call this function
		if curDodgeAnimation == "DodgeDown": 
			play_animation("IdleDown")
			dodge_finished() # call this function
		if curDodgeAnimation == "DodgeLeft": 
			play_animation("IdleLeft")
			dodge_finished() # call this function
		if curDodgeAnimation == "DodgeRight": 
			play_animation("IdleRight")
			dodge_finished() # call this function


func _on_GhostEffectTimer_timeout():

	if state == DODGE:
#		# copy of ghost object
		var ghost = preload("res://Scenes/FadingTrailEffect.tscn").instance()
		# add a child to the main game
		get_parent().add_child(ghost)
		ghost.position = position
		# the texture of the ghost is equal to the player's animated sprite. Get the animations from the player,
		# and get the frames from it too. Tell it that the frames come from the current animation from the current frame.
		ghost.scale.x = 4
		ghost.scale.y = 4
		ghost.texture = $AnimatedSprite.frames.get_frame($AnimatedSprite.animation, $AnimatedSprite.frame)
		# make sure the orientation stays the same
		ghost.flip_h = $AnimatedSprite.flip_h
