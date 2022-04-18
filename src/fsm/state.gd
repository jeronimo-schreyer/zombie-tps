extends Resource
class_name State

var player
var rig

signal entered
signal exited

# warning-ignore:unused_signal
signal finished

func init():
	pass

func enter():
	emit_signal("entered")

func exit():
	emit_signal("exited")

func process(_delta):
	pass

func check() -> bool:
	return false
