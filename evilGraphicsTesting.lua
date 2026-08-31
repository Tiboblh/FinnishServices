term.setGraphicsMode(1) -- go into 16 color mode

local th = { -- a bit of abstraction away from direct colors.color calls so theme can be easily changed later
    bg = colors.black, -- background color, use for blank space
    fg1 = colors.white, -- main color 1, used for things like text and borders
    highlight = colors.blue, -- highlight, used to surround text that is highlighted
    highlightItem = colors.white --this is just th.bg for now
}
local font = { -- all characters in 5x5px font, font copied from https://www.dafont.com/5x5-pixel.font
    -- format is 5 pixels per line, and should be 25 {color} in each one, for a 5x5 image
    error = { --used if char is invalid or missing
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
    },
    A={
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1
    },
    B={
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg
    },
    C={
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg
    },
    D = {
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg, 
        th.fg1, th.bg, th.bg, th.bg, th.fg1, 
        th.fg1, th.bg, th.bg, th.bg, th.fg1, 
        th.fg1, th.bg, th.bg, th.bg, th.fg1, 
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg, 
    },
    E = {
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1, 
        th.fg1, th.bg, th.bg, th.bg, th.bg, 
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1, 
        th.fg1, th.bg, th.bg, th.bg, th.bg, 
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1, 
    },
    F = {
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1, 
        th.fg1, th.bg, th.bg, th.bg, th.bg, 
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1, 
        th.fg1, th.bg, th.bg, th.bg, th.bg, 
        th.fg1, th.bg, th.bg, th.bg, th.bg, 
    }
}
function getTermPxDims()
    return term.getSize(term.getGraphicsMode() or 1)
end
function drawChar(character,offsetX,offsetY) -- draw a single character to the screen, used by printText()
    local charsizeX = 5
    local charsizeY = 5
    local curpx = 0
    for count, px in ipairs(character) do
        local line = 0
        if count >5 then 
            line = 1
         if count >10 then 
            line = 2
          if count >15 then 
            line = 3
           if count >20 then 
            line = 4     
            end
           end
         end
        end
        local printX = ((offsetX + count) - (line*5))
        local printY = (offsetY+line)
        term.setPixel(printX, printY, px)
            

    end
end
function printText(x,y,text,timeout) -- draw a string in non terminal mode, requires a defined font
    local spaceWidth = 1 -- space width in pixels
    local charWidth = 5
    local currentChar = 0 -- current char being printed

    for index, char in ipairs(text) do
        local curdrawX = x + (index*(charWidth + spaceWidth)- (charWidth+spaceWidth))
        drawChar(char or font.error, curdrawX, y)
        if timeout then
            sleep(timeout)
        end
    end
end
function str2table(text)
    local textinput = text
    local output = {}
    for i = 1, #text do
        local char = text:sub(i, i)
        local glyph = font[char]
        table.insert(output, glyph or font.error)
    end
    return output
end    
term.drawPixels(0,0, th.bg, 360, 180) --draw background
printText(1,1,{font.A,font.B,font.C,font.D,font.E,font.F},0.1)
sleep(5)
term.setGraphicsMode(0)