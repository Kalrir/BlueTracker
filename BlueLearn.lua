--[[
* BlueLearn - centered "Action Learned!" splash with the spell name when YOU
* learn Blue Magic. Merged into Codex from Kalrir's standalone 'bluelearn'
* addon (v1.0); rendering uses the bundled gdifonts library (Thorny) in
* Codex/gdifonts. Settings live under cfg.bluelearn_* and are edited from the
* Blue Mage config tab.
*
* Robustness: gdifonts loads a native DLL. The require is wrapped in pcall so a
* missing/failed library degrades to a silent no-op instead of breaking Codex.
--]]

require('common')
local imgui = require('imgui')  -- used only to read the screen size

local ok_gdi, gdi = pcall(require, 'gdifonts.include')
if not ok_gdi then gdi = nil end

local M = {}

-- Bound in M.init:
local cfg      = nil
local settings = nil

-- Optional set of learnable Blue Magic spell names (lowercased) supplied by the
-- tracker via M.set_valid_spells; when set, only these trigger the splash.
local valid_spells = nil

-- Defaults used whenever a cfg.bluelearn_* field is nil. Colors are ARGB.
local DEF = {
    enabled       = true,
    pos_y         = 0.28,
    font_family   = 'Times New Roman',
    title_text    = 'Action Learned!',
    font_height   = 46,
    line_gap      = 4,
    outline_width = 3,
    duration      = 3.5,
    fade_in       = 0.35,
    fade_out      = 0.90,
    color_top     = 0xFFCDE6FF,
    color_bottom  = 0xFF2E60BE,
    outline_color = 0xFF06122B,
    show_rules    = true,
    line_rgb      = 0x96C7EF,
    play_sound    = true,
    sound_file    = 'blu_action_learned.wav',
    queue_gap     = 0.20,
    max_queue     = 12,
    trigger_on_you = true,
}
local function C(k)
    if cfg ~= nil then
        local v = cfg['bluelearn_' .. k]
        if v ~= nil then return v end
    end
    return DEF[k]
end

-- =========================
-- State
-- =========================
local splash      = { action = '', start = 0, active = false }
local queue       = {}
local next_ready  = 0

local title_obj, sub_obj, rule_top, rule_bottom = nil, nil, nil, nil
local last_rule_byte = -1

-- =========================
-- Helpers
-- =========================
local function get_self_name()
    local mm = AshitaCore and AshitaCore:GetMemoryManager()
    if mm == nil then return nil end
    local party = mm:GetParty()
    if party == nil then return nil end
    local ok, name = pcall(function() return party:GetMemberName(0) end)
    if not ok or name == nil or name == '' then return nil end
    return name
end

local function strip(str)
    if str == nil then return '' end
    str = str:gsub(string.char(0x1E) .. '.', '')
    str = str:gsub(string.char(0x1F) .. '.', '')
    str = str:gsub('%c', ' ')
    str = str:gsub('%s+', ' ')
    str = str:gsub('^%s+', ''):gsub('%s+$', '')
    return str
end

local function get_screen()
    local ok, vp = pcall(function() return imgui.GetMainViewport() end)
    if ok and vp ~= nil then return vp.Pos.x, vp.Pos.y, vp.Size.x, vp.Size.y end
    local ok2, io = pcall(function() return imgui.GetIO() end)
    if ok2 and io ~= nil then return 0, 0, io.DisplaySize.x, io.DisplaySize.y end
    return 0, 0, 1920, 1080
end

local function make_text()
    if gdi == nil then return nil end
    local ok, obj = pcall(function()
        return gdi:create_object(T{
            font_family    = C('font_family'),
            font_height    = C('font_height'),
            font_flags     = gdi.FontFlags.Bold,
            font_alignment = gdi.Alignment.Center,
            font_color     = C('color_top'),
            gradient_color = C('color_bottom'),
            gradient_style = gdi.Gradient.TopToBottom,
            outline_color  = C('outline_color'),
            outline_width  = C('outline_width'),
            opacity        = 0,
            visible        = false,
            text           = '',
            position_x     = 0,
            position_y     = 0,
            z_order        = 100,
        })
    end)
    if ok then return obj end
    return nil
end

local function ensure_objects()
    if gdi == nil then return false end
    if title_obj ~= nil then return true end
    title_obj = make_text()
    sub_obj   = make_text()
    if title_obj == nil or sub_obj == nil then return false end

    if C('show_rules') and rule_top == nil then
        local rect = T{
            width = 10, height = 2, corner_rounding = 0,
            outline_width = 0, fill_color = 0x00000000,
            position_x = 0, position_y = 0, visible = false, z_order = 99,
        }
        local ok1, r1 = pcall(function() return gdi:create_rect(rect) end)
        local ok2, r2 = pcall(function() return gdi:create_rect(rect) end)
        if ok1 then rule_top = r1 end
        if ok2 then rule_bottom = r2 end
    end
    return true
end

-- Push the current cfg appearance onto the text objects (so live config edits
-- take effect on the next splash without recreating anything).
local function apply_text_config(obj)
    if obj == nil then return end
    pcall(function()
        obj:set_font_family(C('font_family'))
        obj:set_font_height(C('font_height'))
        obj:set_font_color(C('color_top'))
        obj:set_gradient_color(C('color_bottom'))
        obj:set_outline_color(C('outline_color'))
        obj:set_outline_width(C('outline_width'))
    end)
end

local function set_rule_alpha(a)
    if rule_top == nil then return end
    local byte = math.floor(a * 255 + 0.5)
    if byte == last_rule_byte then return end
    last_rule_byte = byte
    local col = (byte * 0x1000000) + C('line_rgb')
    pcall(function() rule_top:set_fill_color(col) end)
    pcall(function() rule_bottom:set_fill_color(col) end)
end

local function position_objects()
    if title_obj == nil or sub_obj == nil then return end
    local sx, sy, sw, sh = get_screen()
    local cx = sx + sw * 0.5
    local cy = sy + sh * C('pos_y')

    local ok1, tw1, th1 = pcall(function() return title_obj:get_text_size() end)
    local ok2, tw2, th2 = pcall(function() return sub_obj:get_text_size() end)
    if not ok1 then tw1, th1 = 0, 0 end
    if not ok2 then tw2, th2 = 0, 0 end
    tw1, th1, tw2, th2 = tw1 or 0, th1 or 0, tw2 or 0, th2 or 0

    local gap   = (th2 > 0) and C('line_gap') or 0
    local total = th1 + gap + th2
    local top   = cy - (total * 0.5)

    pcall(function()
        title_obj:set_position_x(cx); title_obj:set_position_y(top)
        sub_obj:set_position_x(cx);   sub_obj:set_position_y(top + th1 + gap)
    end)

    if C('show_rules') and rule_top ~= nil then
        local w = math.max(40, math.max(tw1, tw2) * 1.05)
        pcall(function()
            rule_top:set_width(w);    rule_bottom:set_width(w)
            rule_top:set_height(2);   rule_bottom:set_height(2)
            rule_top:set_position_x(cx - w * 0.5)
            rule_bottom:set_position_x(cx - w * 0.5)
            rule_top:set_position_y(top - 12)
            rule_bottom:set_position_y(top + total + 8)
        end)
    end
end

local function titlecase(s)
    return (s:gsub('%f[%a]%a', string.upper))
end

local function play_learn_sound()
    if not C('play_sound') then return end
    if ashita == nil or ashita.misc == nil or ashita.misc.play_sound == nil then return end
    local base = tostring(addon.path):gsub('[\\/]+$', '')
    local path = base .. '\\sounds\\' .. C('sound_file')
    pcall(ashita.misc.play_sound, path)
end

local function begin_splash(action)
    if not ensure_objects() then return end
    splash.action = titlecase(action or '')
    splash.start  = os.clock()
    splash.active = true
    last_rule_byte = -1

    apply_text_config(title_obj)
    apply_text_config(sub_obj)
    pcall(function()
        title_obj:set_text(C('title_text'))
        sub_obj:set_text(splash.action)
    end)
    position_objects()

    pcall(function()
        title_obj:set_opacity(0); title_obj:set_visible(true)
        sub_obj:set_opacity(0);   sub_obj:set_visible(true)
    end)
    if rule_top ~= nil and C('show_rules') then
        set_rule_alpha(0)
        pcall(function() rule_top:set_visible(true); rule_bottom:set_visible(true) end)
    end

    play_learn_sound()
end

local function hide_splash()
    splash.active = false
    if title_obj ~= nil then pcall(function() title_obj:set_visible(false) end) end
    if sub_obj ~= nil then pcall(function() sub_obj:set_visible(false) end) end
    if rule_top ~= nil then pcall(function() rule_top:set_visible(false); rule_bottom:set_visible(false) end) end
end

local function start_next()
    if #queue == 0 then return end
    local action = table.remove(queue, 1)
    begin_splash(action)
end

local function enqueue(action)
    if action == nil or action == '' then return end
    if #queue >= C('max_queue') then return end
    queue[#queue + 1] = action
end

local function try_learn(who, spell)
    local self_name = get_self_name()
    if self_name == nil then return false end
    local is_self = (who == self_name)
        or (C('trigger_on_you') and (who == 'You' or who == 'you'))
    if not is_self then return false end
    -- Only fire for actual Blue Magic. Other jobs' spell learns ("You learn
    -- Cure III") share the same chat wording, so without this filter the splash
    -- would trigger on e.g. RDM scribing. The set is supplied by the tracker.
    if valid_spells ~= nil then
        local key = spell:lower():gsub('%s+$', '')
        if not valid_spells[key] then return false end
    end
    enqueue(spell)
    return true
end

-- =========================
-- Module API (wired into Codex dispatch)
-- =========================
function M.init(host)
    cfg      = host.cfg
    settings = host.settings
    -- gdi objects are created lazily on the first splash.
end

-- Restrict the splash to a set of spell names (name -> true, lowercased).
-- Pass nil to disable filtering (fire on any learn).
function M.set_valid_spells(set)
    valid_spells = set
end

-- Chat watcher: fires the splash when YOU learn a Blue Magic spell.
function M.text_in(e)
    if gdi == nil then return end
    if not C('enabled') then return end
    local msg = strip(e.message)
    local who, rest = msg:match('^(%a+) learns? (.+)$')
    if who == nil or rest == nil then return end
    local spell = rest:gsub('[^%a]+$', '')
    if spell == '' then return end
    try_learn(who, spell)
end

-- Fade driver + queue pump (called every frame from Codex's present dispatch).
function M.render()
    if gdi == nil then return end
    if not splash.active then
        if #queue > 0 and os.clock() >= next_ready then start_next() end
        return
    end
    local dur = C('duration')
    local elapsed = os.clock() - splash.start
    if elapsed >= dur then
        hide_splash()
        next_ready = os.clock() + C('queue_gap')
        return
    end
    local fi, fo = C('fade_in'), C('fade_out')
    local a = 1.0
    if elapsed < fi then a = elapsed / fi
    elseif elapsed > dur - fo then a = (dur - elapsed) / fo end
    a = math.max(0.0, math.min(1.0, a))
    pcall(function() title_obj:set_opacity(a); sub_obj:set_opacity(a) end)
    if C('show_rules') then set_rule_alpha(a) end
end

-- Handles only the "/blutracker test*" (or "/blut test*") splash subcommands,
-- dispatched before the tracker's own command so the plain toggle is unaffected.
function M.command(e)
    local args = e.command:args()
    if #args == 0 then return false end
    local root = args[1]:lower()
    if root ~= '/blutracker' and root ~= '/blut' then return false end
    local sub = (#args >= 2) and args[2]:lower() or ''
    if sub == 'test' then
        e.blocked = true
        enqueue((#args >= 3) and table.concat(args, ' ', 3) or 'Pollen')
        return true
    elseif sub == 'testmulti' then
        e.blocked = true
        for _, s in ipairs({ 'Pollen', 'Cursed Sphere', 'Sheep Song' }) do enqueue(s) end
        return true
    end
    return false
end

-- Preview from the config tab's Test button.
function M.preview(spell)
    if gdi == nil then return end
    enqueue(spell or 'Pollen')
end

function M.unload()
    queue = {}
    hide_splash()
    if gdi ~= nil then pcall(function() gdi:destroy_interface() end) end
end

return M
