extends CanvasLayer

@onready var eye_sprite = $AnimatedSprite2D
@onready var health_bar_sprite = $HealthBar

# Variável para acompanhar a vida atual
var current_health_frame: int = 0
var player: Node

func _ready():
	# Inicia as animações
	eye_sprite.play()
	health_bar_sprite.frame = 0  # Começa com vida cheia
	
	# Conecta ao player
	await get_tree().create_timer(0.5).timeout
	connect_to_player()

func connect_to_player():
	print("🎯 Tentando conectar HUD ao player...")
	
	# Tenta encontrar o player de várias formas
	player = find_player()
	
	if player:
		print("✅ Player encontrado: ", player.name)
		
		# Tenta conectar ao HealthSystem do player
		if connect_to_health_system():
			print("✅ Conectado ao HealthSystem do player")
		# Se não conseguir, tenta conectar ao sinal direto
		elif connect_to_player_signal():
			print("✅ Conectado ao sinal health_updated do player")
		# Se nada funcionar, usa polling
		else:
			print("⚠️ Usando polling para verificar vida")
			start_health_polling()
	else:
		print("❌ Player não encontrado. Tentando novamente em 1 segundo...")
		await get_tree().create_timer(1.0).timeout
		connect_to_player()

func find_player() -> Node:
	# Tenta várias maneiras de encontrar o player
	var found_player = null
	
	# Método 1: Por grupo
	found_player = get_tree().get_first_node_in_group("player")
	if found_player:
		return found_player
		
	# Método 2: Por nome
	found_player = get_tree().get_root().get_node_or_null("Player")
	if found_player:
		return found_player
		
	# Método 3: Busca por tipo em toda a cena
	var nodes = get_tree().get_root().get_children()
	for node in nodes:
		if node.is_in_group("player") or node.has_method("get_health"):
			return node
	
	return null

func connect_to_health_system() -> bool:
	if player and player.has_method("get_health_system"):
		var health_system = player.get_health_system()
		if health_system and health_system.has_signal("healthChanged"):
			if not health_system.healthChanged.is_connected(update_health_bar):
				health_system.healthChanged.connect(update_health_bar)
			return true
	return false

func connect_to_player_signal() -> bool:
	if player and player.has_signal("health_updated"):
		if not player.health_updated.is_connected(update_health_bar):
			player.health_updated.connect(update_health_bar)
		return true
	return false

func update_health_bar(current_health: int, max_health: int):
	print("🔄 HUD recebeu atualização: ", current_health, "/", max_health)
	
	# Calcula a porcentagem (0% a 100%)
	var health_percent = (float(current_health) / float(max_health)) * 100.0
	
	# Mapeia para os 6 frames (0-5)
	var target_frame = health_percent_to_frame(health_percent)
	
	# Aplica transição suave se mudou de frame
	if target_frame != current_health_frame:
		smooth_frame_change(target_frame)
		current_health_frame = target_frame
	
	print("❤️ Vida: ", current_health, "/", max_health, " (", health_percent, "%) → Frame: ", target_frame)

func health_percent_to_frame(percent: float) -> int:
	# Converte porcentagem para frame (0-5)
	if percent >= 84: return 0   # 84-100%
	if percent >= 68: return 1   # 68-83%
	if percent >= 52: return 2   # 52-67%
	if percent >= 36: return 3   # 36-51%
	if percent >= 20: return 4   # 20-35%
	if percent >= 1: return 5    # 1-19%
	return 6

func smooth_frame_change(target_frame: int):
	# Apenas muda o frame sem efeitos de escala
	health_bar_sprite.frame = target_frame
	
	# Se quiser um efeito mais sutil, use apenas modulação
	var tween = create_tween()
	tween.tween_property(health_bar_sprite, "modulate", Color(1.5, 1.5, 1.5), 0.1)
	tween.tween_property(health_bar_sprite, "modulate", Color.WHITE, 0.1)

func _change_frame(frame: int):
	health_bar_sprite.frame = frame

# Sistema de fallback - verifica a vida periodicamente
func start_health_polling():
	while true:
		await get_tree().create_timer(0.3).timeout  # Verifica a cada 0.3s
		
		if is_instance_valid(player) and player.has_method("get_health"):
			var current_health = player.get_health()
			var max_health = player.get_max_health()
			update_health_bar(current_health, max_health)

