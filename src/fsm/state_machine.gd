extends Node

export (Array) var states
var current

func _ready():
	for s in states:
		s.player = $ninja
		s.rig = $CameraRig
		s.init()

	current = State.new()
	_enter_next_state()


func _physics_process(delta):
	if current.check():
		current.physics_process(delta)
	# this is the only place where states should switch
	else:
		for state in states:
			if state.check():
				switch_state(state)


func _process(delta):
	current.process(delta)


func _input(event):
	current.input(event)


func get_state(state_name):
	for state in states:
		if state.resource_name == state_name:
			return state
	return null


func switch_state(next_state):
	if next_state != current and next_state != null:
		current.exit()
		current = next_state
		_enter_next_state()


func _enter_next_state():
	current.enter()
