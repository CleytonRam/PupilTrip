extends CharacterBody2D


@export var speed: float = 200.0
@export var jumpForce: float = -400.0
@export var gravity: float = 1000.0

@onready var animatedSprite = $AnimatedSprite2D

var activePowers: Dictionary = {}
var baseSpeed: float = 200.0
var baseJumpForce: float = -400

var canDoubleJump: bool = false
var hasDoubleJumped: bool = false

var wasOnFloor: bool = false
var isJumping: bool = false

func _ready():
	animatedSprite.play("Idle")
	baseSpeed = speed
	baseJumpForce = jumpForce
	
func _physics_process(delta):

	wasOnFloor = is_on_floor()
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		hasDoubleJumped  = false
		isJumping = false
	updatePowerTimers(delta)

func collectPower(powerType: Enums.PowerType, duration: float):
	activePowers[powerType] = duration
	applyPowerEffect(powerType, true)

	print("Poder ativado: ", Enums.PowerType.keys()[powerType])

func updatePowerTimers(delta):
	#for 


	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jumpForce
			isJumping = true
			$AnimatedSprite2D.play("Jump")
		elif canDoubleJump and not hasDoubleJumped:         #faz o pulo
			velocity.y = jumpForce * 0.8
			hasDoubleJumped = true
	var direction = Input.get_axis("moveLeft", "moveRight")
	velocity.x = direction * speed
	

	move_and_slide()  

	UpdateAnimation(direction)

func UpdateAnimation(direction):
	var animationToPlay = ""
	if not is_on_floor():
		animationToPlay = "Jump"
	elif direction != 0:
		animationToPlay = "Run"
	else:
		animationToPlay = "Idle"
	
	if animatedSprite.animation != animationToPlay:
		animatedSprite.play(animationToPlay)
	
	if direction > 0:
		animatedSprite.flip_h = false
	elif direction < 0:
		animatedSprite.flip_h = true

		
