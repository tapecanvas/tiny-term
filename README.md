# tiny-term
 WIP - a super basic terminal emulator-ish script for norns
 
![screenshot of script running](screenshot.png)


## tiny-term is a simple terminal emulator-ish script for norns 
- the script opens with a prompt `>` and blinking cursor `_`
- input from keyboard displays after the prompt `> cd home/we/dust_`
- pressing `enter` will  execute the command.
- the display will show the executed command and the resulting output
    - `pwd -> /home/we/dust/audio`
- the display can be scrolled using k2 or keyboard arrow keys
	
- there is currently no error handling, command history, or special key support
- typical terminal applications will not be able to run ie: text editors, file managers, etc. 

## to-do:
- [ ] work on output formatting
- [ ] add command history (up and down keys) - need to rething movement keys (vim keys?)
- [ ] scroll to cursor when typing next command (if output is too long to show cursor on first page)

## archive:
- 2024-02-23
    - first draft
    - able to move around through directories, and execute basic commands
    - added prompt display and cursor
