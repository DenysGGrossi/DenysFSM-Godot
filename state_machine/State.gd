## The base for a State
@icon("uid://cbxsiwg5hkbla")
@abstract class_name State extends Node

#region Props
## a refference to the parent state machine
var parent_state_machine : StateMachine

## if true the state is enabled. [br]
## disabled states cannot become the active state and it is not allowed to transition to a disabled state. if the current active state is disabled it will try to transition to the default state (as set in the [member StateMachine.default_state_name]), or to the first enabled state available. If no available enabled state is found as substitute the state machine will be disabled
@export var state_enabled : bool = true : 
	set(value) :
		state_enabled = value
		(on_state_enable if value else on_state_disable).emit()
		if value == false and parent_state_machine.currently_active_state == self:
			if not state_transition(parent_state_machine.default_state_name):
				parent_state_machine.state_machine_enabled = false

#endregion
#region Signals
## signal emited before this state becomes the active state for setup purposes. The [param previous_state_name] contains the name of the state which was active before this state becomes active or an empty string if this is the first state to become active
signal on_state_enter(previous_state_name : String)

## method run before this state stops being the active state for cleanup purposes. The [param previous_state_name] contains the name of the state which will become active after this state is no longer active or an empty string if this is the last state to be active before the state machine gets disabled
signal on_state_exit(next_state_name : String)

## method run when the state machine is started for initialization purposes
signal on_state_setup

## Signal emitted when this state is enabled
signal on_state_enable

## Signal emitted when this state is disabled
signal on_state_disable

#endregion
#region State Management Methods

## method run before this state becomes the active state for setup purposes. The [param previous_state_name] contains the name of the state which was active before this state becomes active or an empty string if this is the first state to become active
@abstract func state_enter(previous_state_name : String) -> void

## method run before this state stops being the active state for cleanup purposes. The [param previous_state_name] contains the name of the state which will become active after this state is no longer active or an empty string if this is the last state to be active before the state machine gets disabled
@abstract func state_exit(next_state_name : String) -> void

## method run when the state machine is started for initialization purposes
@abstract func state_setup() -> void

#endregion
#region Methods used by active state
## Runs every frame if this State is the currently active state
@abstract func state_update(_delta : float) -> void

## Runs every physics frame if this State is the currently active state
@abstract func state_physics_update(_delta : float) -> void

## Runs every time an input is made if this State is the currently active state
@abstract func state_input(_event : InputEvent) -> void

#endregion
#region Utilities
## When called, tryes to transition to the state with the name equals to the [param next_state_name] parameter. If there is a valid transition this method executes the transition and returns true, otherwise the method won't transition and return false
func state_transition(next_state_name : String, strict_transition : bool = false) -> bool:
	var next_state : State = parent_state_machine.get_state_by_name(next_state_name, strict_transition)
	if next_state == null:
		return false
	parent_state_machine.change_state(next_state.name)
	return true
#endregion
