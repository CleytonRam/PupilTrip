extends CharacterBody2D

# ---------- MOVIMENTO / PATRULHA ----------
@export var speed: float = 80.0
@export var stop_threshold: float = 6.0
@export var offset_a: Vector2 = Vector2(-64, 0)
@export var offset_b: Vector2 = Vector2( 64, 0)

@export var gravity: float = 1800.0
@export var max_fall_speed: float = 2400.0

# ---------- SISTEMA DE VIDA SIMPLES ----------
@export var max_health: int = 50
var current_health: int = 50

# i-frames locais
@export var hit_invincible_time: float = 0.15
var _inv_until: float = 0.0
var is_dead: bool = false

# Sinais para comunicação
signal health_changed(current_health, max_health)
signal died()

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var _point_a: Vector2 = Vector2.ZERO
var _point_b: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _going_to_b: bool = true

func _ready() -> void:
	# Pontos fixos por offset (ancorados no mundo)
	_point_a = global_position + offset_a
	_point_b = global_position + offset_b
	_target  = _point_b
	
	# Inicializa saúde
	current_health = max_health
	
	# Adiciona aos grupos
	add_to_group("enemies")
	add_to_group("pausable")

	if anim and anim.animation != "Walk":
		anim.play("Walk")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# i-frames locais
	if _inv_until > 0.0:
		_inv_until -= delta
		if _inv_until < 0.0:
			_inv_until = 0.0

	# Gravidade
	velocity.y += gravity * delta
	if velocity.y > max_fall_speed:
		velocity.y = max_fall_speed

	# Patrulha em X
	var dx: float = _target.x - global_position.x
	if absf(dx) <= stop_threshold:
		_swap_target()
		dx = _target.x - global_position.x

	var dir_x: float = (1.0 if dx > 0.0 else -1.0)
	velocity.x = dir_x * speed

	move_and_slide()

	# Flip
	if absf(velocity.x) > 0.5:
		anim.flip_h = (velocity.x < 0.0)

func _swap_target() -> void:
	_going_to_b = not _going_to_b
	_target = (_point_b if _going_to_b else _point_a)

# ========== SISTEMA DE DANO SIMPLES ==========
func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or _inv_until > 0.0:
		return

	# Reduz a vida
	current_health -= amount
	current_health = max(0, current_health)
	
	# Emite sinal de vida alterada
	health_changed.emit(current_health, max_health)
	
	print("Inimigo tomou dano: ", amount, ". Vida: ", current_health, "/", max_health)
	
	# Efeito visual de dano
	create_hit_effect()
	
	# Aplica knockback
	if knockback != Vector2.ZERO:
		velocity += knockback
	
	# Ativa i-frames
	_inv_until = hit_invincible_time
	
	# Verifica se morreu
	if current_health <= 0:
		die()

func create_hit_effect():
	# Efeito visual simples quando toma dano
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.RED, 0.1)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.1)

func die():
	if is_dead:
		return
		
	is_dead = true
	print("Inimigo morreu!")
	
	# Emite sinal de morte
	died.emit()
	
	# Toca animação de morte se existir
	if anim and anim.sprite_frames.has_animation("Dead"):
		anim.play("Dead")
		await anim.animation_finished
	elif anim and anim.sprite_frames.has_animation("dead"):
		anim.play("dead")
		await anim.animation_finished
	
	# Remove o inimigo
	queue_free()

# ========== MÉTODOS ÚTEIS ==========
func get_health() -> int:
	return current_health

func get_max_health() -> int:
	return max_health

func is_alive() -> bool:
	return not is_dead and current_health > 0

# Para compatibilidade com sistemas que esperam um HealthSystem
func get_health_system():
	# Retorna o próprio inimigo para compatibilidade
	return self
