-- tiny-term 
-- terminal emulator-ish
-- v0.0.1
-- by @tapecanvas

my_string = ""
old_string = ""
output = ""
current_dir = "/"
scroll_pos = 1
blink_on = false

function keyboard.char(character)
  my_string = my_string..character
  redraw()
end

function keyboard.code(code,value)
  if value == 1 or value == 2 then -- 1 is down, 2 is held, 0 is release
    if code == "BACKSPACE" then
      my_string = my_string:sub(1, -2) -- erase chars from my_string
    elseif code == "UP" then
      scroll_pos = math.max(1, scroll_pos - 1) -- up
    elseif code == "DOWN" then
      scroll_pos = scroll_pos + 1 -- down
    elseif code == "ENTER" then
      if my_string:sub(1, 3) == "cd " then
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
      else
        local handle = io.popen("cd " .. current_dir .. " && " .. my_string)
        output = handle:read("*a")
        handle:close()
      end
      old_string = my_string ..  " -> " -- copy content of my_string to old_string
      my_string = "" -- clear my_string after executing the command
    end
    redraw()
  end
end

function enc(n, delta)
  if n == 2 then
    scroll_pos = scroll_pos - delta -- scroll up or down
    redraw()
  end
end

function textwrap(text, len)
  local lines = {}
  local line = ""
  for word in text:gmatch("%S+") do
    if #line + #word <= len then
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
    local lines = textwrap(old_string .. output, 20) -- show the last run command, then the output of the command, split the output into lines of up to 20 characters
    local line_count = 0
    for i = scroll_pos, scroll_pos + 10 do -- display 10 lines at a time
      if lines[i] then
        screen.move(10, 10 + 10 * line_count) -- move to the start of the next line
        screen.text(lines[i]) -- display the line
        line_count = line_count + 1
      end
    end
    screen.move(10, 10 + 10 * line_count) -- move to the line just below the output text
    screen.text("$ " .. my_string) -- display the current command being typed with a $ prompt
    if blink_on then
      screen.text("_") -- draw a blinking cursor
    end
    screen.update()
  end

  clock.run(blink) -- start the blink 
  redraw()