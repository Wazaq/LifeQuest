# LifeQuest Dialog System - User Guide

## Overview

The LifeQuest Dialog System provides a centralized, flexible way to handle in-game conversations and dialogs. It consists of two main components:

- **DialogManager** (Autoload): Manages dialog content, state, and UI lifecycle
- **DialogUI Scene**: The visual interface for displaying dialogs

## Key Features

- Single message dialogs
- Multi-message dialog sequences
- Choice-based dialogs with user selection
- Fantasy-themed text styling
- Automatic UI creation and cleanup
- Signal-based communication
- Mobile-friendly click/touch interaction

## Basic Usage

### 1. Single Message Dialog

For simple one-time messages:

```gdscript
# Basic usage
DialogManager.show_dialog("Character Name", "Dialog message text")

# Example
DialogManager.show_dialog("Narrator", "Welcome to the mystical realm of Questeria!")
```

### 2. Multi-Message Dialog Sequence

For conversations that require multiple clicks to progress:

```gdscript
# Create an array of messages
var keeper_dialog = [
	"Ah, a new face! Welcome to the Seeking Quill tavern, traveler.",
	"I'm Dorin, the keeper of this fine establishment and curator of adventures.",
	"This is where heroes like yourself can find quests to embark on.",
	"But first, I'll need to know what to call you. What name do you go by, adventurer?"
]

# Show the sequence
DialogManager.show_dialog_sequence("Dorin", keeper_dialog)
```

### 3. Choice-Based Dialog

For dialogs that present options to the user:

```gdscript
# Show dialog with choices
DialogManager.show_dialog_with_choices(
	"Dorin",
	"Would you like me to show you around the tavern?",
	["Yes, that would be helpful", "No thanks, I'll figure it out"]
)

# Connect to handle the user's choice
DialogManager.dialog_choice_selected.connect(_on_choice_selected, CONNECT_ONE_SHOT)

func _on_choice_selected(choice_index: int):
	if choice_index == 0:
		# User selected "Yes"
		print("Player wants the tutorial")
	else:
		# User selected "No"
		print("Player declined tutorial")
```

## Signal System

The DialogManager emits several signals you can connect to:

### Available Signals

```gdscript
# Emitted when a dialog starts
signal dialog_started(character_name)

# Emitted when showing a message in a sequence
signal dialog_message_shown(message_index, total_messages)

# Emitted when a dialog sequence completes
signal dialog_completed

# Emitted when user selects a choice
signal dialog_choice_selected(choice_index)
```

### Connecting to Signals

```gdscript
# Connect to know when dialog finishes
DialogManager.dialog_completed.connect(_on_dialog_finished, CONNECT_ONE_SHOT)

func _on_dialog_finished():
	print("Dialog is done, continue with game logic")
	# Move to next game state, show different UI, etc.
```

## Complete Implementation Example

Here's how the character introduction scene uses the dialog system:

```gdscript
extends Control

enum NarrativeState {
	WORLD_INTRO,
	TAVERN_EXTERIOR,
	TAVERN_INTERIOR,
	CHARACTER_CREATION
}

var current_state = NarrativeState.WORLD_INTRO

var narrative_text = {
	NarrativeState.WORLD_INTRO: "Welcome to the mystical realm of Questeria...",
	NarrativeState.TAVERN_EXTERIOR: "You find yourself at the entrance of the legendary 'Seeking Quill' tavern..."
}

var tavern_keeper_dialog = [
	"Ah, a new face! Welcome to the Seeking Quill tavern, traveler.",
	"I'm Dorin, the keeper of this fine establishment.",
	"This is where heroes like yourself can find quests to embark on."
]

func _ready():
	_update_state(NarrativeState.WORLD_INTRO)

func _update_state(new_state):
	current_state = new_state
	
	match current_state:
		NarrativeState.WORLD_INTRO:
			DialogManager.show_dialog("Narrator", narrative_text[current_state])
			DialogManager.dialog_completed.connect(_on_intro_completed, CONNECT_ONE_SHOT)
			
		NarrativeState.TAVERN_EXTERIOR:
			DialogManager.show_dialog("Narrator", narrative_text[current_state])
			DialogManager.dialog_completed.connect(_on_exterior_completed, CONNECT_ONE_SHOT)
			
		NarrativeState.TAVERN_INTERIOR:
			DialogManager.show_dialog_sequence("Dorin", tavern_keeper_dialog)
			DialogManager.dialog_completed.connect(_on_interior_completed, CONNECT_ONE_SHOT)

func _on_intro_completed():
	_update_state(NarrativeState.TAVERN_EXTERIOR)

func _on_exterior_completed():
	_update_state(NarrativeState.TAVERN_INTERIOR)

func _on_interior_completed():
	_update_state(NarrativeState.CHARACTER_CREATION)
```

## Best Practices

### 1. Use CONNECT_ONE_SHOT for State Changes

Always use `CONNECT_ONE_SHOT` when connecting to dialog completion signals to avoid duplicate connections:

```gdscript
DialogManager.dialog_completed.connect(_on_dialog_done, CONNECT_ONE_SHOT)
```

### 2. Organize Dialog Content

For complex scenes with lots of dialog, organize your content:

```gdscript
# Group related dialogs
var intro_dialogs = {
	"narrator_welcome": "Welcome to the mystical realm...",
	"narrator_tavern": "You find yourself at the entrance..."
}

var character_dialogs = {
	"dorin_greeting": ["Hello there!", "Welcome to my tavern!"],
	"shopkeeper_welcome": "What can I help you with today?"
}
```

### 3. Handle Long Dialog Sequences

For very long conversations, consider breaking them into smaller chunks:

```gdscript
# Instead of one massive array, break it up
var dorin_intro_part1 = [
	"Welcome to the Seeking Quill tavern!",
	"I'm Dorin, the keeper of this establishment."
]

var dorin_intro_part2 = [
	"We specialize in helping adventurers find quests.",
	"Are you here looking for adventure?"
]

func start_dorin_conversation():
	DialogManager.show_dialog_sequence("Dorin", dorin_intro_part1)
	DialogManager.dialog_completed.connect(_continue_dorin_conversation, CONNECT_ONE_SHOT)

func _continue_dorin_conversation():
	DialogManager.show_dialog_sequence("Dorin", dorin_intro_part2)
	DialogManager.dialog_completed.connect(_finish_dorin_conversation, CONNECT_ONE_SHOT)
```

### 4. Fantasy Text Styling

The system automatically applies fantasy-themed replacements:

- "days" becomes "sun cycles"
- "hours" becomes "hourglasses"
- Use `*text*` for emphasis (becomes italic)

```gdscript
# This text will be automatically styled
DialogManager.show_dialog("Keeper", "The quest must be completed within 3 days, brave adventurer!")
# Displays as: "The quest must be completed within 3 sun cycles, brave adventurer!"
```

## Technical Details

### Automatic UI Management

The DialogManager automatically:
- Creates dialog UI instances when needed
- Positions them at the scene root level
- Handles cleanup when dialogs complete
- Manages fade in/out animations

### No Container Required

You don't need to add any dialog UI to your scenes. The DialogManager handles everything:

```gdscript
# No need for dialog containers in your scene
# Just call the DialogManager methods directly
DialogManager.show_dialog("Character", "Message")
```

### Click/Touch Interaction

Users advance through dialogs by clicking anywhere on the dialog box. Choice dialogs disable click-to-advance and only respond to button presses.

## Troubleshooting

### Dialog Not Appearing
- Check that DialogManager is loaded as an autoload
- Verify there are no errors in the console
- Ensure the dialog UI scene path is correct in DialogManager

### Text Not Updating
- This usually indicates multiple dialog instances
- Check that you're not mixing static dialog UI with DialogManager
- Remove any existing dialog UI from your scene files

### Signals Not Working
- Use `CONNECT_ONE_SHOT` to avoid duplicate connections
- Disconnect old signals before connecting new ones if needed
- Check that signal names are spelled correctly

### Choice Buttons Not Appearing
- Verify the choices array is not empty
- Check console for any errors during choice creation
- Ensure the dialog UI scene has the proper choice container structure

## Future Enhancements

The dialog system is designed to be extensible. Potential future features:

- **Sound Integration**: Play voice clips or sound effects with dialogs
- **Portraits**: Show character images alongside dialog
- **Animations**: Animate character emotions or actions
- **Localization**: Support multiple languages
- **Save/Load**: Save dialog state for game saves
- **Conditional Dialogs**: Show different content based on player choices or game state
