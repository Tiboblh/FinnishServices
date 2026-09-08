term.setGraphicsMode(1) -- go into 16 color mode

local th = { -- a bit of abstraction away from direct colors.color calls so theme can be easily changed later
    bg = colors.black, -- background color, use for blank space
    fg1 = colors.white, -- main color 1, used for things like text and borders
    highlight = colors.blue, -- highlight, used to surround text that is highlighted
    highlightItem = colors.white --this is just th.bg for now
}
local font = { -- all characters in 5x5px font, font copied from https://www.dafont.com/5x5-pixel.font
    -- format is char = {size={x=(width),y=(height)},image={array of pixels, use th.thing}}
    error = { --used if char is invalid or missing
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg
        }
    },
    A={
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1
        }
    },
    B={
        size={x=5,y=5},
        image={
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg
        }
    },
    C={
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg
        }
    },
    D = {
        size={x=5,y=5},
        image={
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg, 
        th.fg1, th.bg, th.bg, th.bg, th.fg1, 
        th.fg1, th.bg, th.bg, th.bg, th.fg1, 
        th.fg1, th.bg, th.bg, th.bg, th.fg1, 
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg, 
        }
    },
    E = {
        size={x=5,y=5},
        image={
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1, 
        th.fg1, th.bg, th.bg, th.bg, th.bg, 
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1, 
        th.fg1, th.bg, th.bg, th.bg, th.bg, 
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1, 
        }
    },
    F = {
        size={x=5,y=5},
        image={
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1, 
        th.fg1, th.bg, th.bg, th.bg, th.bg, 
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1, 
        th.fg1, th.bg, th.bg, th.bg, th.bg, 
        th.fg1, th.bg, th.bg, th.bg, th.bg, 
        }
    },
    G = {
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.bg, th.fg1, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.fg1,
        }
    },
    H = {
        size={x=5,y=5},
        image={
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        }
    },
    I = {
        size={x=3,y=5},
        image={
        th.fg1, th.fg1, th.fg1,
        th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg,
        th.fg1, th.fg1, th.fg1
        }
    },
    J = {
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.fg1, th.fg1, th.fg1,
        th.bg, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        }
    },
    K = {
        size={x=5,y=5},
        image={
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.fg1, th.bg,
        th.fg1, th.fg1, th.fg1, th.bg, th.bg,
        th.fg1, th.bg, th.bg, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        }
    },
    L = {
        size={x=5,y=5},
        image={
        th.fg1, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        }
    },
    M = {
        size={x=5,y=5},
        image={
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.bg, th.fg1, th.fg1,
        th.fg1, th.bg, th.fg1, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        }
    },
    N = {
        size={x=5,y=5},
        image={
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.fg1, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        }
    },
    O = {
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        }
    },
    P = {
        size={x=5,y=5},
        image={
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.bg,
        }
    },
    Q = {
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.fg1, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.fg1,
        }
    },
    R = {
        size={x=5,y=5},
        image={
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        }
    },
    S = {
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.bg, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg,
        }
    },
    T = {
        size={x=5,y=5},
        image={
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        }
    },
    U = {
        size={x=5,y=5},
        image={
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        }
    },
    V = {
        size={x=5,y=5},
        image={
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        }
    },
    W = {
        size={x=5,y=5},
        image={
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.fg1, th.bg, th.fg1,
        th.fg1, th.fg1, th.bg, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        }
    },
    X = {
        size={x=5,y=5},
        image={
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        }
    },
    Y = {
        size={x=5,y=5},
        image={
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        }
    },
    Z = {
        size={x=5,y=5},
        image={
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        th.bg, th.bg, th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.bg, th.bg,
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        }
    },
    ["("] = {
        size={x=3,y=5},
        image={
        th.bg, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg,
        th.fg1, th.bg, th.bg,
        th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.fg1
        }
    },
    [")"] = {
        size={x=3,y=5},
        image={
        th.fg1, th.fg1, th.bg,
        th.bg, th.bg, th.fg1,
        th.bg, th.bg, th.fg1,
        th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.bg,
        }
    },
    ["["] = {
        size={x=3,y=5},
        image={
        th.fg1, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg,
        th.fg1, th.bg, th.bg,
        th.fg1, th.bg, th.bg,
        th.fg1, th.fg1, th.fg1,
        }
    },
    ["]"] = {
        size={x=3,y=5},
        image={
        th.fg1, th.fg1, th.fg1,
        th.bg, th.bg, th.fg1,
        th.bg, th.bg, th.fg1,
        th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.fg1,
        }
    },
    ["{"] = {
        size={x=3,y=5},
        image={
        th.bg, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg,
        th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.fg1,
        }
    },
    ["}"] = {
        size={x=3,y=5},
        image={
        th.fg1, th.fg1, th.bg,
        th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1,
        th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.bg, 
        }
    },
    ["\"" ] = {
        size={x=3,y=5},
        image={
        th.fg1, th.bg, th.fg1,
        th.fg1, th.bg, th.fg1,
        th.bg, th.bg, th.bg,
        th.bg, th.bg, th.bg,
        th.bg, th.bg, th.bg
        }
    },
    [" "] = {
        size={x=1,y=5},
        image={
        th.bg,
        th.bg,
        th.bg,
        th.bg,
        th.bg,
        }
    },
    ["."] = {
        size={x=1,y=5},
        image={
        th.bg,
        th.bg,
        th.bg,
        th.bg,
        th.fg1
        }
    },
    [","] = {
        size={x=2,y=5},
        image={
        th.bg, th.bg,
        th.bg, th.bg,
        th.bg, th.bg,
        th.bg, th.fg1,
        th.fg1, th.bg
        }
    },
    ["!"] = {
        size={x=1,y=5},
        image={
        th.fg1,
        th.fg1,
        th.fg1,
        th.bg,
        th.fg1,
        }
    },
    ["?"] = {
        size={x=3,y=5},
        image={
        th.fg1, th.fg1, th.fg1,
        th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.bg,
        }
    },
    [":"] = {
        size={x=1,y=5},
        image={
        th.bg,
        th.fg1,
        th.bg,
        th.fg1,
        th.bg,
        }
    },
    [";"] = {
        size = {x=1,y=5},
        image={
        th.bg,
        th.fg1,
        th.bg,
        th.fg1,
        th.fg1,
        }
    },
    ["'" ] = {
        size={x=1,y=5},
        image={
        th.fg1,
        th.fg1,
        th.bg,
        th.bg,
        th.bg
        }
    },
    ["-"] = {
        size={x=3,y=5},
        image={
        th.bg, th.bg, th.bg,
        th.bg, th.bg, th.bg,
        th.fg1, th.fg1, th.fg1,
        th.bg, th.bg, th.bg,
        th.bg, th.bg, th.bg
        }
    },
    ["+"] = {
        size={x=3,y=5},
        image={
        th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.bg,
        th.fg1, th.fg1, th.fg1,
        th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.bg
        }
    },
    ["="] = {
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        th.bg, th.bg, th.bg, th.bg, th.bg,
        }
    },
    ["&"] = {
        size={x=4,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1
        }
    },
    ["0"] = {
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        }
    },
    ["1"] = {
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        }
    },
    ["2"] = {
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.bg, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        }
    },
    ["3"] = {
        size={x=5,y=5},
        image={
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg,
        th.bg, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.bg, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg,
        }
    },
    ["4"] = {
        size={x=5,y=5},
        image={
        th.fg1, th.bg, th.bg, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.fg1, th.bg,
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        th.bg, th.bg, th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.bg, th.fg1, th.bg,
        }
    },
    ["5"] = {
        size={x=5,y=5},
        image={
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg,
        th.bg, th.bg, th.bg, th.bg, th.fg1,
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg,
        }
    },
    ["6"] = {
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        }
    },
    ["7"] = {
        size={x=5,y=5},
        image={
        th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
        th.bg, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.bg, th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.bg, th.bg,
        }
    },
    ["8"] = {
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        }
    },
    ["9"] = {
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.fg1,
        th.bg, th.bg, th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        }
    },
    a = {
        size={x=3,y=5},
        image={
        th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.fg1,
        th.fg1, th.bg, th.fg1,
        th.fg1, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1
        }
    },
    b = {
        size={x=3,y=5},
        image={
        th.fg1, th.bg, th.bg,
        th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.fg1,
        th.fg1, th.bg, th.fg1,
        th.fg1, th.fg1, th.bg,
        }
    },
    c = {
        size={x=3,y=5},
        image={
        th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg,
        th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.fg1,
        }
    },
    d={
        size={x=3,y=5},
        image={
        th.bg, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1,
        th.fg1, th.bg, th.fg1,
        th.fg1, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1,
        }
    },
    e={
        size={x=3,y=5},
        image={
        th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.bg,
        th.fg1, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.fg1,
        }
    },
    f={
        size={x=3,y=5},
        image={
        th.bg, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg,
        th.fg1, th.fg1, th.fg1,
        th.fg1, th.bg, th.bg,
        th.fg1, th.bg, th.bg,
        }
    },
    g={
        size={x=3,y=6},
        image={
        th.bg, th.fg1, th.fg1,
        th.fg1, th.bg, th.fg1,
        th.fg1, th.bg, th.fg1,
        th.bg, th.fg1, th.fg1,
        th.bg, th.fg1, th.bg,
        th.fg1, th.fg1, th.bg,
        }
    },
    h={
        size={x=3,y=5},
        image={
        th.fg1, th.bg, th.bg,
        th.fg1, th.fg1, th.bg,
        th.fg1, th.fg1, th.fg1,
        th.fg1, th.bg, th.fg1,
        th.fg1, th.bg, th.fg1,
        }
    },
    i={
        size={x=1,y=5},
        image={
        th.fg1,
        th.bg,
        th.fg1,
        th.fg1,
        th.fg1,
        }
    },
    j={
        size={x=3,y=5},
        image={
        th.bg, th.bg, th.fg1,
        th.bg, th.bg, th.bg,
        th.bg, th.bg, th.fg1,
        th.fg1, th.bg, th.fg1,
        th.bg, th.fg1, th.bg,
        }
    },
    k={
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        }
    },
    l={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg
        }
    },
    m={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.fg1, th.fg1, th.fg1, th.bg,
        th.fg1, th.bg, th.fg1, th.bg, th.fg1,
        th.fg1, th.bg, th.fg1, th.bg, th.fg1,
        }
    },
    n={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        }
    },
    o={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        }
    },
    p={
        size={x=5,y=5},
        image={
        th.bg, th.fg1, th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.bg, th.bg,
        }
    },
    q={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.fg1, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.fg1, th.bg,
        th.bg, th.bg, th.bg, th.fg1, th.bg,
        }
    },
    r={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        }
    },
    s={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.fg1, th.bg,
        th.bg, th.fg1, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.fg1, th.bg, th.bg,
        }
    },
    t={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.bg, th.fg1, th.bg,
        }
    },
    u={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.fg1, th.bg,
        }
    },
    v={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        }
    },
    w={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.fg1, th.bg, th.fg1, th.bg, th.fg1,
        th.fg1, th.bg, th.fg1, th.bg, th.fg1,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        }
    },
    x={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        }
    },
    y={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.fg1, th.bg, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.bg, th.bg,
        }
    },
    z={
        size={x=5,y=5},
        image={
        th.bg, th.bg, th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        th.bg, th.bg, th.fg1, th.bg, th.bg,
        th.bg, th.fg1, th.bg, th.bg, th.bg,
        th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        }
    }
}
local tiles = {
    vertLine3 = {
        size = {x = 5, y = 5},
        image = {
            th.bg, th.fg1, th.fg1, th.fg1, th.bg,
            th.bg, th.fg1, th.fg1, th.fg1, th.bg,
            th.bg, th.fg1, th.fg1, th.fg1, th.bg,
            th.bg, th.fg1, th.fg1, th.fg1, th.bg,
            th.bg, th.fg1, th.fg1, th.fg1, th.bg,
        }
    },
    horiLine3 = {
        size = {x = 5, y = 5},
        image = {
            th.bg, th.bg, th.bg, th.bg, th.bg,
            th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
            th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
            th.fg1, th.fg1, th.fg1, th.fg1, th.fg1,
            th.bg, th.bg, th.bg, th.bg, th.bg,
        }
    }
}

local images = {
    blankBg = {
        
    }
}


function getTermPxDims()
    return term.getSize(term.getGraphicsMode() or 1)
end
function drawChar(character,offsetX,offsetY) -- draw a single character to the screen, used by printText()
    -- support both legacy glyph arrays and new glyph objects {size={x,y},image={...}}
    local image, sizeX, sizeY
    if type(character) == "table" and character.image then
        image = character.image
        sizeX = character.size and character.size.x or 5
        sizeY = character.size and character.size.y or 5
    else
        image = character
        sizeX = 5
        sizeY = 5
    end
    for idx, px in ipairs(image) do
        local line = math.floor((idx-1) / sizeX)
        local col = ((idx-1) % sizeX)
        local printX = offsetX + col
        local printY = offsetY + line
        term.setPixel(printX, printY, px)
    end
end
function printText(x,y,text,timeout) -- draw a string in non terminal mode, requires a defined font
    local spaceWidth = 1 -- space width in pixels
    local curx = x

    for index, item in ipairs(text) do
        local glyph = item.glyph or item -- support legacy glyph-only items
        drawChar(glyph or font.error, curx, y)
        local w = item.width or (item.char and fontWidths and fontWidths[item.char]) or (glyph.size and glyph.size.x) or 5
        if item.width then w = item.width end
        if timeout then
            sleep(timeout)
        end
        curx = curx + (item.width or w) + spaceWidth
    end
end
function str2table(text)
    local output = {}
    for i = 1, #text do
        local ch = text:sub(i, i)
        local glyph = font[ch] or font.error
        local width = (glyph.size and glyph.size.x) or 5
        table.insert(output, {glyph = glyph, width = width, char = ch})
    end
    return output
end    

function drawScreen(imageData,width,height)
    for y = 0, height-1 do
        for x = 0, width-1 do
            local idx = y * width + x + 1
            local px = imageData[idx]
            term.setPixel(x,y,px)
        end
    end

end

term.drawPixels(0,0, th.bg, 360, 180) --draw background
printText(1,1,str2table("TEST:"))
printText(1,7,str2table("abcdefghijklmnopqrstuvwxyz"))
printText(1,13,str2table("ABCDEFGHIJKLMNOPQRSTUVWXYZ"))
printText(1,19,str2table(", . ! ? \" [ ] ( ) { }"))
printText(1,25,str2table("0123456789"))
printText(1,31,str2table("+ - = &"))
printText(1,37,str2table("The quick brown fox jumps over the lazy dog."))
printText(1,43,str2table("A, B. C?"))
printText(1,49,str2table("D!"))
printText(1,55,str2table("also evil nonexistent characters: @ # $ % ^ _ ~ | \\ /"))
printText(1,61,str2table("and some more: ` ; : '"))
-- res is 360x180
debug.debug()
term.setGraphicsMode(0)