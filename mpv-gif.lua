-- mpv gif generator for Windows
-- Requires ffmpeg in PATH
-- Original by Ruin0x11, optimized by me, Nick.
local msg = require 'mp.msg'
local options = {
    dir = os.getenv("USERPROFILE") .. "\\Pictures\\mpv-gifs",
    rez = 600,
    fps = 15,
}
local read_options = require 'mp.options'.read_options
read_options(options)

local fps = (options.fps >= 1 and options.fps < 30) and options.fps or 15
local filters = string.format("fps=%s,scale='trunc(ih*dar/2)*2:trunc(ih/2)*2':flags=lanczos,setsar=1", fps)

local start_time, end_time = -1, -1
local palette = os.getenv("TEMP") .. "\\mpv_palette.png"

function get_full_path()
    local p = mp.get_property("path") or ""
    if string.match(p, "^%a:[/\\]") then
        return p
    end
    return mp.get_property("working-directory") .. "\\" .. p
end

function make_gif_internal(burn)
    if start_time < 0 or end_time < 0 or start_time >= end_time then
        mp.osd_message("Invalid gif range")
        return
    end
    mp.osd_message("Rendering GIF...")

    local path = get_full_path()
    local dur = end_time - start_time
    local vf = filters

    if burn then
        vf = vf .. ",ass=" .. string.gsub(path, "\\", "/")
    end

    local palette_cmd = string.format(
        'ffmpeg -ss %f -t %f -i "%s" -vf "%s,palettegen=stats_mode=diff" -y "%s"',
        start_time, dur, path, vf, palette
    )
    os.execute(palette_cmd)

    local base = path:match("([^\\]+)%.%w+$") or "mpv"
    local out = string.format('%s\\%s_%03d.gif', options.dir, base, os.time())
    local gif_cmd = string.format(
        'ffmpeg -ss %f -t %f -i "%s" -i "%s" -lavfi "%s [x]; [x][1:v] paletteuse" -y "%s"',
        start_time, dur, path, palette, vf, out
    )
    os.execute(gif_cmd)

    mp.osd_message("GIF saved: " .. out)
end

function set_start() start_time = mp.get_property_number("time-pos") mp.osd_message(("Gif start: %.2f"):format(start_time)) end
function set_end() end_time = mp.get_property_number("time-pos") mp.osd_message(("Gif end: %.2f"):format(end_time)) end

mp.add_key_binding("g", "set_start", set_start)
mp.add_key_binding("'", "set_end", set_end)
mp.add_key_binding("Ctrl+g", "make_gif", function() make_gif_internal(false) end)
mp.add_key_binding("Ctrl+G", "make_gif_subs", function() make_gif_internal(true) end)
