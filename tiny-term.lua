-- tiny-term 
-- terminal emulator-ish
-- v0.0.3
-- by @tapecanvas
-- e2: scroll
-- k2: clear
-- up arrow: command history 
-- dwn arrow: command history 

local my_string = ""
local old_string = ""
local command_history = {}
local history_index = 0
local output = ""
local current_dir = "/"
local scroll_pos = 1
local cursor_pos = 0
local blink_on = false

function keyboard.char(character)
    scroll_pos = 0
    my_string = my_string:sub(1, cursor_pos) .. character .. my_string:sub(cursor_pos + 1)
    cursor_pos = cursor_pos + 1
    local lines = textwrap(old_string .. output, 25)
    scroll_pos = #lines + 1
    redraw()
end

-- dictionary of disallowed commands
local disallowed_commands = {
    ["vi"] = true,
    ["nano"] = true,
    ["less"] = true,
    ["htop"] = true,
    ["more"] = true,
    ["vim"] = true,
    ["tmux"] = true,
    ["ssh"] = true,
    ["clear"] = true
}

function keyboard.code(code, value)
  if value == 1 or value == 2 then -- 1 is down, 2 is held, 0 is release
      if code == "BACKSPACE" then
          my_string = my_string:sub(1, cursor_pos - 1) .. my_string:sub(cursor_pos + 1)
          cursor_pos = math.max(0, cursor_pos - 1)
      elseif code == "UP" then
          if history_index > 1 then
              history_index = history_index - 1
              my_string = command_history[history_index]
              cursor_pos = #my_string
          end
      elseif code == "DOWN" then
          if history_index < #command_history then
              history_index = history_index + 1
              my_string = command_history[history_index]
              cursor_pos = #my_string
          end
      elseif code == "LEFT" then
          cursor_pos = math.max(0, cursor_pos - 1)
      elseif code == "RIGHT" then
          cursor_pos = math.min(#my_string, cursor_pos + 1)
      elseif code == "ENTER" then
          -- reset scroll position to top when a new command is run
          scroll_pos = 1
          -- disallow running certain commands that require a proper terminal interface
          local command = my_string:match("^%S+")
          if command and disallowed_commands[command] then
              output = "Error: " .. command .. " requires a proper terminal interface and cannot be run."
          elseif my_string:sub(1, 3) == "cd " then
              local new_dir = my_string:sub(4)
              local handle = io.popen("cd " .. current_dir .. " && cd " .. new_dir .. " && pwd")
              local result = handle:read("*a")
              handle:close()
              if result ~= "" then
                  current_dir = result:sub(1, -2) -- remove new line
                  output = ""
              else
                  output = "can't cd to " .. new_dir
              end
          elseif my_string == "clear" then
              output = ""
              old_string = ""
          else
              local handle = io.popen("cd " .. current_dir .. " && " .. my_string)
              output = handle:read("*a")
              handle:close()
          end
          table.insert(command_history, my_string)
          history_index = #command_history + 1
          old_string = my_string .. "-> "
          my_string = "" -- clear my_string after executing the command
          cursor_pos = 0
      else
          -- scroll to the cursor position when a printable key is pressed -- this stops arrow key scrolling from jumping to prompt
          if code:match("%a") or code:match("%d") or code == "SPACE" then
              local lines = textwrap(old_string .. output, 25)
              scroll_pos = #lines + 1
          end
      end
      redraw()
  end
end

function enc(n, delta)
    if n == 2 then
        scroll_pos = scroll_pos + delta
        redraw()
    end
end

-- handle key presses
function key(n, z)
    if n == 2 and z == 1 then
        output = ""
        old_string = ""
        my_string = ""
        cursor_pos = 0
        redraw()
    end
end

-- this is better
function textwrap(text, len)
    local lines = {}
    local line = ""
    for word in text:gmatch("%S+[^%s]*") do
        if #line + #word + 1 <= len then
            line = line .. (line == "" and "" or " ") .. word
        else
            table.insert(lines, line)
            line = word
        end
    end
    table.insert(lines, line)
    return lines
end

function blink()
    while true do
        blink_on = not blink_on
        redraw()
        clock.sleep(0.5) -- wait for half a second
    end
end

function redraw()
    screen.clear()
    local lines = textwrap(old_string .. output, 25) -- show the last run command, then the output of the command, split the output into lines of up to 20 characters
    local line_count = 0
    for i = scroll_pos, scroll_pos + 10 do -- display 10 lines at a time
        if lines[i] then
            screen.move(5, 10 + 8 * line_count) -- move to the start of the next line
            screen.text(lines[i]) -- display the line
            line_count = line_count + 1
        end
    end
    -- wrap the command being typed into multiple lines if it exceeds the width of the screen
    local command_lines = textwrap("$ " .. my_string, 25)
    for i, line in ipairs(command_lines) do
        screen.move(5, 10 + 8 * line_count) -- move to the line below the output text
                -- if the command is too long, only display the last 25 char
        if #line > 25 then
            line = line:sub(-25)
        end
        screen.text(line) -- display the line of the command being typed
        line_count = line_count + 1
    end
    if blink_on then
        screen.text("_") -- draw the blinking cursor
    end
    screen.update()
end

clock.run(blink) -- start the blink 
redraw()