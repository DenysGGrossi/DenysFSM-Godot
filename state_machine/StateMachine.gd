## the base for a State Machine
@icon("uid://bng5cd8wwxupp")
class_name StateMachine extends Node

#region Props
## if true, the state machine is running
var state_machine_enabled : bool:
	set(value) :
		if value == state_machine_enabled:
			return
		if value:
			if state_list.is_empty():
				printerr("no state existant in State Machine (" + name + "), Disabling!")
				state_machine_enabled = false
				return
			var start_state : State = get_state_by_name(default_state_name)
			if start_state == null:
				state_machine_enabled = false
				return
			enter_state(start_state, "")
			on_state_machine_enabled.emit()
		else :
			exit_state("")
			on_state_machine_disabled.emit()
		state_machine_enabled = value

## the currently active state
var currently_active_state : State

## a list of all states existant in this state machine
var state_list : Dictionary[String, State]

## the name of the state which will become active once the state machine 
@export var default_state_name : String

## if true, the state machine will be automatically enabled once the [method Node._ready] is finished in this state machine 
@export var enable_on_awake : bool = true

#endregion
#region Signals
## This signal emitted when the currently active state changes. [br][br]
## The [param previous_state_name] stores the name of the previously active [State] node or an empty string if this is the first active state on this state machine [br][br]
## The [param next_state_name] stores the name of the [State] node which has currently become active or an empty string if the state machine is going to be disabled
signal on_state_change(previous_state_name : String, next_state_name : String)

## This signal is emitted once this state machine is enabled
signal on_state_machine_enabled

## This signal is emitted once this state machine is disabled
signal on_state_machine_disabled

#endregion
#region Default methods
func _ready() -> void:
	# Get all children which is a state, set it up with the state_setup() method and add it to the state_list
	for node : Node in get_children():
		if node is State:
			node.parent_state_machine = self
			node.state_setup()
			node.on_state_setup.emit()
			state_list[node.name] = node
	# after setup, if this state machine should enable_on_awake, try to enable the state machine
	if enable_on_awake:
		state_machine_enabled = true

func _process(_delta: float) -> void:
	if state_machine_enabled and currently_active_state != null:
		currently_active_state.state_update(_delta)

func _physics_process(_delta: float) -> void:
	if state_machine_enabled and currently_active_state != null:
		currently_active_state.state_physics_update(_delta)

func _input(_event: InputEvent) -> void:
	if state_machine_enabled and currently_active_state != null:
		currently_active_state.state_input(_event)

#endregion
#region State Machine Management
## Method called for changing the currently active state for another one
func change_state(next_state_name : String) -> void:
	# prevent state changes if this state machine is disabled, has no active state or no state in the state_list
	if (not state_machine_enabled) or currently_active_state == null or (state_list.is_empty()):
		return
	# try get the state with the right name or the first available state if not possible
	var next_state : State = get_state_by_name(next_state_name)
	# store the name of the current state for use as parameter
	var previous_state_name : String = currently_active_state.name
	# if no available state is found, cancel transition
	if next_state == null:
		return
	# exit current state
	exit_state(next_state.name)
	# Enter next state
	enter_state(next_state, previous_state_name)
	# emit on_state_change signal
	on_state_change.emit(next_state.name, previous_state_name)

## Used for calling the state exit logic on the currently active [State]
func exit_state(next_state_name : String) -> void:
	if currently_active_state != null:
		return
	currently_active_state.state_exit(next_state_name)
	currently_active_state.on_state_exit.emit(next_state_name)

## Used to set the currently active state and run the state enter logic on the state
func enter_state(state : State, previous_state_name : String) -> void:
	currently_active_state = state
	currently_active_state.state_enter(previous_state_name)
	currently_active_state.on_state_enter.emit(previous_state_name)


#endregion
#region Utilities

## returns the state in the list with the key equal to the [param state_name] if that state is enabled. If there is no enabled state with the selected name, the method will return the first enabled state or null if there is no enabled state in this state machine. [br]
## if [param strict_selection] is set to true, the method will return null if there is no enabled state with the name matching the [param state_name] parameter
func get_state_by_name(state_name : String, strict_selection : bool = false) -> State:
	# return null if no registered state
	if state_list.is_empty():
		return null
	# if the state exists and is enabled, return it
	if state_list.has(state_name) and state_list[state_name].state_enabled:
		return state_list[state_name]
	else:
		# if it is a strict selection, return null if not found
		if strict_selection:
			return null
		# otherwise, run through the state machine to find an enabled state and returns it
		for state : State in state_list.values():
			if state.state_enabled:
				return state
		#if it reached this point, there is no enabled state. returning null
		return null
	
	
	return state_list[state_name] if state_list.has(state_name) else state_list.values()[0]
	
#endregion
