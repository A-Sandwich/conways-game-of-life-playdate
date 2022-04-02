-- Name this file `main.lua`. Your game can use multiple source files if you wish
-- (use the `import "myFilename"` command), but the simplest games can be written
-- with just `main.lua`.

-- You'll want to import these in just about every project you'll work on.

import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- Declaring this "gfx" shorthand will make your life easier. Instead of having
-- to preface all graphics calls with "playdate.graphics", just use "gfx."
-- Performance will be slightly enhanced, too.
-- NOTE: Because it's local, you'll have to do it in every .lua source file.

local gfx <const> = playdate.graphics
local white <const> = gfx.kColorWhite
local black <const> = gfx.kColorBlack
local alive <const> = 1
local dead <const> = 0
local maxXIndex <const> = 23
local maxYIndex <const> = 39
local minIndex <const> = 0
local secondsBetweenStateUpdate <const> = .5 * 1000
-- Here's our player sprite declaration. We'll scope it to this file because
-- several functions need to access it.

local scale = 10
local current_state = {}

-- `playdate.update()` is the heart of every Playdate game.
-- This function is called right before every frame is drawn onscreen.
-- Use this function to poll input, run game logic, and move sprites.
function setupState()
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
    setupOscillator()
end

function setupOscillator()
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

setupState()

function playdate.update()
    for _, row in pairs(current_state) do 
        for _, cell in pairs(row) do
            gfx.setColor(cell.color)
            rect = playdate.geometry.rect.new(cell.x, cell.y, cell.size, cell.size)
            gfx.fillRect(rect)
        end
    end
    playdate.timer.updateTimers()
end

function update_state()
    local next_state = shallowcopy(current_state)
    for keyY, row in pairs(current_state) do
        for keyX, _ in pairs(row) do
            next_state[keyY][keyX] = get_cell_evoluation(keyX, keyY, current_state)
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

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        print("copying table")
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            --- This will handle a table of tables but you can't go deeper than that.
            if (type(orig_value) == 'table') then
                copy[orig_key] = shallowcopy(orig_value)
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

playdate.timer.keyRepeatTimerWithDelay(secondsBetweenStateUpdate, secondsBetweenStateUpdate, update_state)