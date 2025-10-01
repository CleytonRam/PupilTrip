extends Camera2D

@export var target: Node2D
@export var smoothSpeed: float = 5.0

# 🔥 NOVO: Sistema de Screen Shake
@export var max_shake_offset: Vector2 = Vector2(10, 10)
@export var shake_decay: float = 3.0

var trauma: float = 0.0  # 0 a 1
var shake_intensity: float = 0.0
var noise = FastNoiseLite.new()
var noise_y = 0

func _ready():
	# Configura o noise para shake mais orgânico
	noise.seed = randi()
	noise.frequency = 0.5

func _process(delta):
	if target:
		global_position = global_position.lerp(target.global_position, smoothSpeed * delta)
	
	#  NOVO: Processa o screen shake
	if trauma > 0:
		process_shake(delta)

func process_shake(delta):
	# Aplica o shake ao offset da câmera
	shake_intensity = trauma * trauma  # Quadrático para feel melhor
	
	# Gera offsets baseados em noise
	noise_y += 1
	var shake_x = noise.get_noise_2d(noise.seed, noise_y) * max_shake_offset.x * shake_intensity
	var shake_y = noise.get_noise_2d(noise.seed * 2, noise_y) * max_shake_offset.y * shake_intensity
	
	offset = Vector2(shake_x, shake_y)
	
	# Decai o trauma
	trauma = max(trauma - shake_decay * delta, 0.0)
	
	# Reseta o offset quando o trauma acabar
	if trauma <= 0:
		offset = Vector2.ZERO

#  NOVO: Função para adicionar trauma (shake)
func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0)

#  NOVO: Função alternativa para shake direto
func shake_camera(intensity: float, duration: float):
	var original_trauma = trauma
	trauma = intensity
	
	# Cria um timer para voltar ao trauma original
	if duration > 0:
		get_tree().create_timer(duration).timeout.connect(
			func(): trauma = original_trauma
		)
		
