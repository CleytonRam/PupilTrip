extends CharacterBody2D

@export var speed: float = 200.0
@export var jumpForce: float = -400.0
@export var gravity: float = 1000.0

@onready var animatedSprite = $AnimatedSprite2D

var canDoubleJump: bool = false
var hasDoubleJumped: bool = false

var wasOnFloor: bool = false
var isJumping: bool = false

func _ready():
    animatedSprite.play("Idle")
    
func _physics_process(delta):

    wasOnFloor = is_on_floor()
    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        hasDoubleJumped  = false
        isJumping = false



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

    UpdateAnimation()

func UpdateAnimation(direction):
    if not is_on_floor():
        if velocity.y < 0:
            animatedSprite.play("Jump")
        else:
            animatedSprite.play("Land")
