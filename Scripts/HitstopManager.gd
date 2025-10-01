extends Node

# Configuração do hitstop
@export var default_hitstop_duration := 0.1

var hitstop_timer: float = 0.0
var is_in_hitstop: bool = false
var nodes_to_pause: Array[Node] = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	if is_in_hitstop:
		hitstop_timer -= delta
		if hitstop_timer <= 0:
			end_hitstop()

# Função para ativar o hitstop
func activate_hitstop(duration: float = default_hitstop_duration, specific_nodes: Array[Node] = []):
	if is_in_hitstop:
		return
	
	is_in_hitstop = true
	hitstop_timer = duration
	
	# Decide quais nós pausar
	nodes_to_pause = specific_nodes
	if nodes_to_pause.is_empty():
		nodes_to_pause = get_tree().get_nodes_in_group("pausable")
	
	# Aplica a pausa
	for node in nodes_to_pause:
		if is_instance_valid(node):  # ⬅️ VERIFICA SE O NÓ AINDA É VÁLIDO
			if node is AnimationPlayer:
				node.pause()
			node.set_physics_process(false)
			node.set_process(false)

func end_hitstop():
	is_in_hitstop = false
	
	# Retoma todos os nós pausados que ainda são válidos
	for node in nodes_to_pause:
		if is_instance_valid(node):  # ⬅️ VERIFICA SE O NÓ AINDA É VÁLIDO
			if node is AnimationPlayer:
				node.play()
			node.set_physics_process(true)
			node.set_process(true)
	
	nodes_to_pause.clear()
