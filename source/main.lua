-- Name this file `main.lua`. Your game can use multiple source files if you wish
-- (use the `import "myFilename"` command), but the simplest games can be written
-- with just `main.lua`.

-- You'll want to import these in just about every project you'll work on.

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"

-- Declaring this "gfx" shorthand will make your life easier. Instead of having
-- to preface all graphics calls with "playdate.graphics", just use "gfx."
-- Performance will be slightly enhanced, too.
-- NOTE: Because it's local, you'll have to do it in every .lua source file.

local gfx <const> = playdate.graphics
local white <const> = gfx.kColorWhite
local black <const> = gfx.kColorBlack
local alive <const> = 1
local dead <const> = 0
local max_x_index <const> = 39
local max_y_index <const> = 23
local min_index <const> = 0
local seconds_between_state_update <const> = .5 * 1000
local animated_cursor = nil
local is_auto_evolving = false
local crank_degrees = 0
-- Here's our player sprite declaration. We'll scope it to this file because
-- several functions need to access it.

local scale = 10
local current_state = {}

-- `playdate.update()` is the heart of every Playdate game.
-- This function is called right before every frame is drawn onscreen.
-- Use this function to poll input, run game logic, and move sprites.
function setup_state()
    for h=0, 230, scale do
        current_state[h//scale] = {}
        for i=0,390, scale do
            current_state[h//scale][i//scale] = {
                color=white,
                status=dead,
                x=i,
                y=h,
                size=scale,
            }
        end
    end 
    setup_oscillator()
end

function setup_cursor()
    animated_cursor = {
        x_index=0,
        y_index=0
    }
end

function setup_oscillator()
    local temp = current_state[19][12]
    temp.color = black
    temp.status = alive
    current_state[19][12] = temp
    temp = current_state[20][12]
    temp.color = black
    temp.status = alive
    current_state[20][12] = temp
    temp = current_state[21][12]
    temp.color = black
    temp.status = alive
    current_state[21][12] = temp
end

setup_state()
setup_cursor()

function playdate.update()
    gfx.sprite.update()
    for _, row in pairs(current_state) do 
        for _, cell in pairs(row) do
            draw_rect(cell)
        end
    end
    input()
    update_cursor()
    playdate.timer.updateTimers()
end

function draw_rect(cell)
    gfx.setColor(cell.color)
    rect = playdate.geometry.rect.new(cell.x, cell.y, cell.size, cell.size)
    gfx.fillRect(rect)
end

function wrap_y_input(y_index)
    if y_index < min_index then
        y_index = max_y_index
    elseif y_index > max_y_index then
        y_index = 0
    end
    return y_index
end

function playdate.cranked(change, acceleratedChange)
    is_auto_evolving = false
    crank_degrees = change + crank_degrees
    if crank_degrees > 90 then
        update_state()
        crank_degrees = crank_degrees - 90
    elseif crank_degrees < -90 then
        crank_degrees = crank_degrees + 90
        update_state()
    end
end

function playdate.crankDocked()
    crank_degrees = 0
end

function wrap_x_input(x_index)
    if x_index < min_index then
        x_index = max_x_index
    elseif x_index > max_x_index then
        x_index = min_index
    end
    return x_index
end

function input()
    if playdate.buttonJustPressed(playdate.kButtonUp) then
        animated_cursor.y_index = wrap_y_input(animated_cursor.y_index - 1)
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        animated_cursor.y_index = wrap_y_input(animated_cursor.y_index + 1)
    elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
        animated_cursor.x_index = wrap_x_input(animated_cursor.x_index - 1)
    elseif playdate.buttonJustPressed(playdate.kButtonRight) then
        animated_cursor.x_index = wrap_x_input(animated_cursor.x_index + 1)
    end

    if playdate.buttonJustPressed(playdate.kButtonA) then
        invert_cell_state(animated_cursor.x_index, animated_cursor.y_index)
    end

    if playdate.buttonJustPressed(playdate.kButtonB) then
        is_auto_evolving = not is_auto_evolving
    end
end

function invert_cell_state(x_index, y_index)
    local current_cell = current_state[y_index][x_index]
    current_cell.color = get_inverted_color(current_cell.color)
    current_cell.status = convert_color_to_cell_status(current_cell.color)
    draw_rect(current_cell)
end

function auto_update_state()
    if not is_auto_evolving then return end
    update_state()
end

function update_state()
    local next_state = shallow_copy(current_state)
    for key_y, row in pairs(current_state) do
        for key_x, _ in pairs(row) do
            next_state[key_y][key_x] = get_cell_evoluation(key_x, key_y, current_state)
        end
    end
    current_state = next_state
end

function get_cell_evoluation(x, y, current_state)
    local adjacent_living_cells = get_adjacent_living_cells(x, y, current_state)
    return evolve_cell(x, y, current_state, adjacent_living_cells)
end

function evolve_cell(x, y, current_state, adjacent_living_cells)
    local current_cell = current_state[y][x]
    local cell = {
        color=current_cell.color,
        status=current_cell.status,
        x=current_cell.x,
        y=current_cell.y,
        size=current_cell.size,
    }
    cell.status = get_conways_result(cell.status, adjacent_living_cells)
    cell.color = convert_cell_status_to_color(cell.status)
    return cell
end

function get_adjacent_living_cells(x, y, current_state)
    local adjacent_living_cells = 0

    adjacent_living_cells = adjacent_living_cells + get_cell_state(x - 1, y - 1, current_state)
    adjacent_living_cells = adjacent_living_cells + get_cell_state(x, y - 1, current_state)
    adjacent_living_cells = adjacent_living_cells + get_cell_state(x + 1, y - 1, current_state)
    adjacent_living_cells = adjacent_living_cells + get_cell_state(x - 1, y, current_state)
    adjacent_living_cells = adjacent_living_cells + get_cell_state(x + 1, y, current_state)
    adjacent_living_cells = adjacent_living_cells + get_cell_state(x - 1, y + 1, current_state)
    adjacent_living_cells = adjacent_living_cells + get_cell_state(x, y + 1, current_state)
    adjacent_living_cells = adjacent_living_cells + get_cell_state(x + 1, y + 1, current_state)
    return adjacent_living_cells
end

function convert_color_to_cell_status(color)
    if (color == black) then
        return alive
    end
    return dead
end

function convert_cell_status_to_color(cell_status)
    if (cell_status == alive)then
        return black
    end
    return white
end

function get_conways_result(cell_status, adjacent_living_cells)
    if (cell_status == alive)then
        return evaluate_living_cell(adjacent_living_cells)
    else
        return evaluate_dead_cell(adjacent_living_cells)
    end
end

function evaluate_living_cell(adjacent_living_cells)
    print("living cells", adjacent_living_cells)
    if (adjacent_living_cells > 1 and adjacent_living_cells < 4) then
        return alive
    end
    return dead
end

function evaluate_dead_cell(adjacent_living_cells)
    if (adjacent_living_cells == 3) then
        return alive
    end
    return dead
end

function get_cell_state(x, y, current_state)
    if (current_state[y] ~= nil and current_state[y][x] ~= nil) then
        return current_state[y][x].status
    end
    return dead
end

function shallow_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            --- This will handle a table of tables but you can't go deeper than that.
            if (type(orig_value) == 'table') then
                copy[orig_key] = shallow_copy(orig_value)
            else
                copy[orig_key] = orig_value
            end
        end
    else -- number, string, boolean, etc
        print("copying primitive")
        copy = orig
    end
    return copy
end

function get_inverted_color(color)
    if (color == black) then
        return white
    end
    return black
end

function update_cursor()
    local current_cell = current_state[animated_cursor.y_index][animated_cursor.x_index]
    gfx.setColor(get_inverted_color(current_cell.color))
    rect = playdate.geometry.rect.new(current_cell.x, current_cell.y, current_cell.size, current_cell.size)
    gfx.drawRoundRect(rect, 1)
end

playdate.timer.keyRepeatTimerWithDelay(seconds_between_state_update, seconds_between_state_update, auto_update_state)