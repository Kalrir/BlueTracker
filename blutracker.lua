--[[
* BluTracker - Blue Magic spell-learning tracker for Ashita v4 (HorizonXI)
*
* Standalone addon extracted from the Codex toolkit. This file is the addon
* host: it owns the settings, builds the shared imgui view-table (vt) and the
* helpers table, wires up the Ashita events, and drives the tracker module
* (tracker.lua) plus its "Action Learned!" splash (BlueLearn.lua).
*
* Install:  <Ashita>/addons/blutracker/
* Load:     /addon load blutracker
*
* Commands (/blut is a short alias for /blutracker):
*   /blutracker                toggle the Blue Magic window
*   /blutracker config         open the window on its Settings tab (or: settings)
*   /blutracker test [spell]   preview the "Action Learned!" splash
*
* Per-character state (learned spells, tracked spells, window options) is
* saved by Ashita's settings library, so each character keeps its own data.
--]]

addon.name    = 'BluTracker';
addon.author  = 'Kalrir';
addon.version = '1.0';
addon.desc    = 'Blue Magic spell-learning tracker with a where-to-learn guide.';

require('common');
local imgui    = require('imgui');
local settings = require('settings');

-- The tracker module. Requires its data/ files and (optionally) BlueLearn +
-- gdifonts at load; all of those live under this addon's folder.
local BlueMage = require('tracker');

------------------------------------------------------------
-- DEFAULT CONFIG (only the keys this addon owns)
------------------------------------------------------------
local default_config = T{
    -- Tracker window
    bluemage_open          = false,
    bluemage_win_x         = 340,
    bluemage_win_y         = 200,
    bluemage_font_scale    = 1.0,
    bluemage_lock_ui       = false,
    bluemage_hide_on_menu  = false,
    bluemage_auto_learn    = true,   -- chat fallback when the spellbook read is unavailable
    bluemage_hide_learned  = false,  -- filter: hide already-learned spells
    bluemage_only_my_level = false,  -- filter: only spells at/below your BLU level
    bluemage_bg_color_r    = 0.06,
    bluemage_bg_color_g    = 0.07,
    bluemage_bg_color_b    = 0.10,
    bluemage_bg_color_a    = 0.96,
    bluemage_data          = BlueMage.default_data,   -- per-char learned state
    -- Separate "tracker" mini-window
    bluemage_track_mode    = 'off',   -- 'off' | 'specific' | 'zone'
    bluemage_track_win_x   = 910,
    bluemage_track_win_y   = 200,
    bluemage_track_data    = BlueMage.default_track,

    -- "Action Learned!" splash (BlueLearn). Colors are ARGB (0xAARRGGBB).
    bluelearn_enabled       = true,
    bluelearn_play_sound    = true,
    bluelearn_duration      = 3.5,
    bluelearn_fade_in       = 0.35,
    bluelearn_fade_out      = 0.90,
    bluelearn_pos_y         = 0.28,
    bluelearn_font_height   = 46,
    bluelearn_show_rules    = true,
    bluelearn_title_text    = 'Action Learned!',
    bluelearn_font_family   = 'Times New Roman',
    bluelearn_color_top     = 0xFFCDE6FF,
    bluelearn_color_bottom  = 0xFF2E60BE,
    bluelearn_outline_color = 0xFF06122B,
    bluelearn_line_rgb      = 0x96C7EF,
    bluelearn_sound_file    = 'blu_action_learned.wav',
};

local cfg = settings.load(default_config);

------------------------------------------------------------
-- VIEW TABLE (vt): imgui {value} tables + transient UI state.
-- The tracker module reads/writes these via host.vt.
------------------------------------------------------------
local vt = {
    cfg_bluemage_open           = { cfg.bluemage_open },
    cfg_bluemage_font_scale     = { cfg.bluemage_font_scale },
    cfg_bluemage_lock_ui        = { cfg.bluemage_lock_ui },
    cfg_bluemage_hide_on_menu   = { cfg.bluemage_hide_on_menu },
    cfg_bluemage_auto_learn     = { cfg.bluemage_auto_learn ~= false },
    cfg_bluemage_hide_learned   = { cfg.bluemage_hide_learned or false },
    cfg_bluemage_only_my_level  = { cfg.bluemage_only_my_level or false },
    cfg_bluemage_bg_color       = { cfg.bluemage_bg_color_r, cfg.bluemage_bg_color_g,
                                    cfg.bluemage_bg_color_b, cfg.bluemage_bg_color_a },
    _want_settings_tab          = false,  -- set by the gear / "/blutracker config"
};

-- Push the current cfg values back into the vt {value} tables. Called on load
-- and after a settings reload so the widgets reflect saved state.
local function sync_config_vars()
    vt.cfg_bluemage_open[1]          = cfg.bluemage_open;
    vt.cfg_bluemage_font_scale[1]    = cfg.bluemage_font_scale;
    vt.cfg_bluemage_lock_ui[1]       = cfg.bluemage_lock_ui;
    vt.cfg_bluemage_hide_on_menu[1]  = cfg.bluemage_hide_on_menu;
    vt.cfg_bluemage_auto_learn[1]    = cfg.bluemage_auto_learn ~= false;
    vt.cfg_bluemage_hide_learned[1]  = cfg.bluemage_hide_learned or false;
    vt.cfg_bluemage_only_my_level[1] = cfg.bluemage_only_my_level or false;
    vt.cfg_bluemage_bg_color[1]      = cfg.bluemage_bg_color_r;
    vt.cfg_bluemage_bg_color[2]      = cfg.bluemage_bg_color_g;
    vt.cfg_bluemage_bg_color[3]      = cfg.bluemage_bg_color_b;
    vt.cfg_bluemage_bg_color[4]      = cfg.bluemage_bg_color_a;
end

------------------------------------------------------------
-- SHARED HELPERS (host.helpers)
-- Draws a clickable gear in the native title bar, just left of the X.
-- Must be called between imgui.Begin and imgui.End for that window.
------------------------------------------------------------
local function draw_titlebar_gear(id_suffix, scale, on_click)
    local gs        = math.floor(15 * scale);
    local sp        = math.floor(4 * scale);
    local x_btn_w   = math.floor(17 * scale);
    local right_pad = math.floor(8 * scale);
    local title_h   = imgui.GetFrameHeight();
    local wx, wy    = imgui.GetWindowPos();
    local ww, _     = imgui.GetWindowSize();

    local gcx = wx + ww - right_pad - x_btn_w - sp - gs * 0.5;
    local gcy = wy + title_h * 0.5;

    local mx, my = imgui.GetMousePos();
    local hov = mx >= gcx-gs*0.5 and mx <= gcx+gs*0.5
            and my >= gcy-gs*0.5 and my <= gcy+gs*0.5;

    if hov and imgui.IsMouseClicked(0) and on_click then
        on_click();
    end

    local dl = imgui.GetWindowDrawList();
    local gear_col = hov and imgui.GetColorU32({1.0,1.0,1.0,1.0})
                         or  imgui.GetColorU32({0.60,0.63,0.78,0.85});
    local gr = gs * 0.42;
    local gi = gs * 0.22;
    local teeth = 6;

    -- Expand clip rect to cover the title bar so the gear isn't clipped.
    local pushed_clip = false;
    if dl.PushClipRectFullScreen then
        pcall(dl.PushClipRectFullScreen, dl);
        pushed_clip = true;
    elseif dl.PushClipRect then
        local ok = pcall(dl.PushClipRect, dl,
            {wx, wy}, {wx + ww, wy + title_h + 2}, false);
        if ok then pushed_clip = true; end
    end

    for t = 0, teeth-1 do
        local a0=(t/teeth)*math.pi*2;       local a1=a0+(0.25/teeth)*math.pi*2;
        local a2=a0+(0.50/teeth)*math.pi*2; local a3=a0+(0.75/teeth)*math.pi*2;
        dl:AddQuadFilled(
            {gcx+math.cos(a0)*gi, gcy+math.sin(a0)*gi},
            {gcx+math.cos(a1)*gr, gcy+math.sin(a1)*gr},
            {gcx+math.cos(a2)*gr, gcy+math.sin(a2)*gr},
            {gcx+math.cos(a3)*gi, gcy+math.sin(a3)*gi},
            gear_col);
    end
    dl:AddCircleFilled({gcx, gcy}, gs*0.16, imgui.GetColorU32({0.08,0.09,0.12,1.0}));

    if pushed_clip and dl.PopClipRect then
        pcall(dl.PopClipRect, dl);
    end
end

local helpers = {
    draw_titlebar_gear = draw_titlebar_gear,
};

-- Build the host object handed to the module's init.
local function make_host()
    return {
        cfg            = cfg,
        vt             = vt,
        settings       = settings,
        helpers        = helpers,
        default_config = default_config,
    };
end

------------------------------------------------------------
-- EVENTS
------------------------------------------------------------
ashita.events.register('load', 'load_cb', function()
    sync_config_vars();
    BlueMage.init(make_host());
    vt._load_msg_frames = 90;
end);

ashita.events.register('unload', 'unload_cb', function()
    pcall(BlueMage.unload);
    settings.save();
end);

ashita.events.register('command', 'command_cb', function(e)
    -- The module claims /blutracker (and /blutracker test via BlueLearn),
    -- setting e.blocked when it handles the command.
    if pcall(function() return BlueMage.command(e) end) and e.blocked then return; end
end);

ashita.events.register('text_in', 'text_in_cb', function(e)
    pcall(BlueMage.text_in, e);
end);

ashita.events.register('packet_in', 'packet_in_cb', function(e)
    -- 0x00A = zone-in / character login: settings are per-character, so reload
    -- them and re-bind the module to the fresh cfg. 0x00B = zone-out: persist.
    if e.id == 0x00A then
        cfg = settings.load(default_config);
        sync_config_vars();
        BlueMage.init(make_host());
    elseif e.id == 0x00B then
        settings.save();
    end
end);

ashita.events.register('d3d_present', 'present_cb', function()
    -- One-time load hint.
    if vt._load_msg_frames and vt._load_msg_frames > 0 then
        vt._load_msg_frames = vt._load_msg_frames - 1;
        if vt._load_msg_frames == 0 then
            print('[BluTracker] loaded. /blutracker (or /blut) to open, /blutracker config for settings.');
            vt._load_msg_frames = nil;
        end
    end

    pcall(BlueMage.render);
end);

-- Persist whenever Ashita signals a settings write (e.g. profile changes).
settings.register('settings', 'settings_update', function(s)
    if s ~= nil then
        cfg = s;
        sync_config_vars();
        BlueMage.init(make_host());
    end
    settings.save();
end);
