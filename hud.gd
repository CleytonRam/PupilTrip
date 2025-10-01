extends CanvasLayer



@onready var eye_sprite = $AnimatedSprite2D

func _ready():
	# Configura a camada do HUD
	layer = 1
	
	# INICIA A ANIMAÇÃO AUTOMATICAMENTE
	start_eye_animation()

func start_eye_animation():
	# Verifica se existe a animação
	if eye_sprite.sprite_frames.has_animation("default"):
		eye_sprite.play("default")
	else:
		# Se não tiver "default", toca a primeira animação disponível
		var animations = eye_sprite.sprite_frames.get_animation_names()
		if animations.size() > 0:
			eye_sprite.play(animations[0])
			print("Tocando animação: ", animations[0])

# 🎮 FUNÇÕES DE CONTROLE - use essas quando quiser!

func play_eye_animation(anim_name: String = "default"):
	"""Toca uma animação específica do olho"""
	if eye_sprite.sprite_frames.has_animation(anim_name):
		eye_sprite.play(anim_name)
	else:
		print("Animação não encontrada: ", anim_name)

func stop_eye_animation():
	"""Para a animação do olho"""
	eye_sprite.stop()

func pause_eye_animation():
	"""Pausa a animação do olho"""
	eye_sprite.pause()

func resume_eye_animation():
	"""Continua a animação do olho"""
	eye_sprite.play()

func set_eye_frame(frame: int):
	"""Vai para um frame específico"""
	eye_sprite.frame = frame

# 💡 EXEMPLOS PRÁTICOS:

func _input(event):
	# Exemplo: Controlar com teclas (para teste)
	if event.is_action_pressed("ui_accept"):  # Barra de espaço
		play_eye_animation("blink")
	
	if event.is_action_pressed("ui_cancel"):  # ESC
		stop_eye_animation()