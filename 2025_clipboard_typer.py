# NOTES
# Working on:
# Mac OS : Checked and working!
# Windows: hecked and working!
# Ubuntu : Needs to be checked

# Nate (Created Winter 2025)

"""
Step-by-step instructions:

1. Install dependencies:
   - Run: `pip install pyperclip pynput`

2. How it works:
   - Listens to keyboard inputs.
   - Typing '???' retrieves and types clipboard content.

3. Key features:
   - Ignores special keys (e.g., Shift, Alt, Cmd).
   - Simulates natural typing with delays.
   - Handles uppercase and special characters.

4. To run:
   - Save as `.py` (e.g., `keyboard_listener.py`).
   - Execute: `python keyboard_listener.py`.

5. Usage:
   - Copy text to the clipboard.
   - Type '???' in any text field to paste it.

6. Stop:
   - Press `Ctrl+C` or close the terminal.
"""


import pyperclip
from pynput.keyboard import Key, Listener, Controller
import time

keyboard = Controller()

# Global variables
key_strokes = ''
past_keys = ''
ignore_keys = {
    Key.shift, Key.alt, Key.cmd, Key.enter, Key.right, Key.left, Key.up, Key.down
}

# Mapping for special characters requiring Shift
shift_map = {
    ':': ';',
    '"': "'",
    '<': ',',
    '>': '.',
    '?': '/',
    '!': '1',
    '@': '2',
    '#': '3',
    '$': '4',
    '%': '5',
    '^': '6',
    '&': '7',
    '*': '8',
    '(': '9',
    ')': '0',
    '_': '-',
    '+': '=',
    '{': '[',
    '}': ']',
    '|': '\\',
    '~': '`',
    '*': '8',
}

def type_response(answer):
    """Type the response character-by-character."""
    for _ in range(3):  # Simulate 3 backspaces
        keyboard.press(Key.backspace)
        keyboard.release(Key.backspace)
        time.sleep(0.1)  # Add a slight delay to mimic natural typing

    for char in answer:
        if char == '\n':  # Handle newlines
            keyboard.press(Key.enter)
            keyboard.release(Key.enter)
        elif char.isupper() or char in shift_map:  # Handle Shift key for uppercase and special chars
            keyboard.press(Key.shift)
            if char in shift_map:
                keyboard.press(shift_map[char])  # Type corresponding shifted character
                keyboard.release(shift_map[char])
            else:
                keyboard.press(char.lower())
                keyboard.release(char.lower())
            keyboard.release(Key.shift)
        else:
            keyboard.press(char)
            keyboard.release(char)
        time.sleep(0.01)  # Add delay for natural typing

def on_press(key):
    global key_strokes, past_keys

    # Ignore shift, alt, cmd, arrow keys, etc.
    if key in ignore_keys:
        return

    # Handle space
    if key == Key.space:
        key_strokes += ' '
        past_keys += ' '
    # Handle backspace
    elif key == Key.backspace:
        key_strokes = key_strokes[:-1]
        past_keys = past_keys[:-1]
    else:
        # For letters, punctuation, etc.
        # key.char is None if it's a special key, so guard for that
        char = getattr(key, 'char', None)
        if char is not None:
            key_strokes += char
            past_keys += char

    # Trim past_keys to last 3 for sequence detection
    if len(past_keys) > 3:
        past_keys = past_keys[-3:]

    # Detect sequences
    if past_keys == '???':
        print('--- Retrieving from Clipboard ---')
        time.sleep(1)
        text = pyperclip.paste()
        type_response(text)
        past_keys = ''

def main():
    # Start the listener
    with Listener(on_press=on_press) as listener:
        listener.join()

if __name__ == "__main__":
    main()
