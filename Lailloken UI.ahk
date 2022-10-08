#NoEnv
#SingleInstance, Force
#InstallKeybdHook
#InstallMouseHook
#Hotstring NoMouse
#Hotstring EndChars `n
#MaxThreads 100
#MaxMem 1024
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
OnMessage(0x0204, "LLK_Rightclick")
OnMessage(0x0200, "LLK_MouseMove")
SetKeyDelay, 100
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
CoordMode, ToolTip, Screen
SendMode, Input
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1
OnExit, Exit
Menu, Tray, Tip, Lailloken UI
#Include data\Class_CustomFont.ahk
font1 := New CustomFont("data\Fontin-SmallCaps.ttf")
timeout := 1
Menu, Tray, Icon, img\GUI\tray.ico

IniRead, enable_caps_toggling, ini\config.ini, Settings, enable CapsLock-toggling, 1
SetStoreCapsLockMode, %enable_caps_toggling%

If !pToken := Gdip_Startup()
{
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}

SysGet, xborder, 32
SysGet, yborder, 33
SysGet, caption, 4

GroupAdd, poe_window, ahk_exe GeForceNOW.exe
GroupAdd, poe_window, ahk_class POEWindowClass
GroupAdd, poe_ahk_window, ahk_class POEWindowClass
GroupAdd, poe_ahk_window, ahk_class AutoHotkeyGUI

IniRead, clone_frames_failcheck, ini\clone frames.ini
Loop, Parse, clone_frames_failcheck, `n, `n
{
	If InStr(A_LoopField, " ")
		IniDelete, ini\clone frames.ini, %A_LoopField%
}
If FileExist("Resolutions.ini")
	FileDelete, Resolutions.ini
If FileExist("Class_CustomFont.ahk")
	FileDelete, Class_CustomFont.ahk
If FileExist("External Functions.ahk")
	FileDelete, External Functions.ahk
If FileExist("Fontin-SmallCaps.ttf")
	FileDelete, Fontin-SmallCaps.ttf
If !FileExist("data\Resolutions.ini") || !FileExist("data\Class_CustomFont.ahk") || !FileExist("data\Fontin-SmallCaps.ttf") || !FileExist("data\JSON.ahk") || !FileExist("data\External Functions.ahk") || !FileExist("data\Map mods.ini") || !FileExist("data\Map search.ini") || !FileExist("data\Betrayal.ini") || !FileExist("data\Atlas.ini") || !FileExist("data\timeless jewels\") || !FileExist("data\leveling tracker\")
	LLK_Error("Critical files are missing. Make sure you have installed the script correctly.")
If !FileExist("ini\")
	FileCreateDir, ini\

IniRead, kill_timeout, ini\config.ini, Settings, kill-timeout, 1
IniRead, kill_script, ini\config.ini, Settings, kill script, 1

startup := A_TickCount
While !WinExist("ahk_group poe_window")
{
	If (A_TickCount >= startup + kill_timeout*60000) && (kill_script = 1)
		ExitApp
	win_not_exist := 1
	sleep, 100
}

If WinExist("ahk_group poe_window") && (win_not_exist = 1) ;band-aid fix for situations in which the script detected an unsupported resolution because the PoE-client window was being resized while launching
	client_start := A_TickCount

While (A_TickCount < client_start + 4000)
	sleep, 100

If !WinExist("ahk_exe GeForceNOW.exe")
{
	IniRead, poe_config_file, ini\config.ini, Settings, PoE config-file, %A_MyDocuments%\My Games\Path of Exile\production_Config.ini
	If !FileExist(poe_config_file)
	{
		FileSelectFile, poe_config_file, 3, %A_MyDocuments%\My Games\\production_Config.ini, Please locate the 'production_Config.ini' file which is stored in the same folder as loot-filters, config files (*.ini)
		If (ErrorLevel = 1) || !InStr(poe_config_file, "production_Config")
		{
			Reload
			ExitApp
		}
		IniRead, check_ini, % poe_config_file
		If !InStr(check_ini, "Display")
		{
			Reload
			ExitApp
		}
		IniWrite, "%poe_config_file%", ini\config.ini, Settings, PoE config-file
	}

	IniRead, exclusive_fullscreen, % poe_config_file, DISPLAY, fullscreen
	If (exclusive_fullscreen = "ERROR" || exclusive_fullscreen = "")
		LLK_Error("Cannot read the PoE config-file")
	Else If (exclusive_fullscreen = "true")
		LLK_Error("The game-client is set to exclusive fullscreen.`nPlease set it to windowed fullscreen.")
	IniRead, fullscreen, % poe_config_file, DISPLAY, borderless_windowed_fullscreen,
	If (fullscreen = "ERROR" || fullscreen = "")
		LLK_Error("Cannot read the PoE config-file")
	IniRead, fullscreen_last, ini\config.ini, Settings, fullscreen, % A_Space
	If (fullscreen_last != fullscreen)
	{
		IniWrite, % fullscreen, ini\config.ini, Settings, fullscreen
		IniWrite, 0, ini\config.ini, Settings, enable custom-resolution
	}
}
Else IniWrite, 0, ini\config.ini, Settings, enable custom-resolution
	
hwnd_poe_client := WinExist("ahk_group poe_window")
last_check := A_TickCount
WinGetPos, xScreenOffset, yScreenOffset, poe_width, poe_height, ahk_group poe_window

;determine native resolution of the active monitor
Gui, Test: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow -Caption
WinSet, Trans, 0
Gui, Test: Show, NA x%xScreenOffset% y%yScreenOffset% Maximize
WinGetPos, xScreenOffset_monitor, yScreenOffSet_monitor, width_native, height_native
Gui, Test: Destroy

IniRead, supported_resolutions, data\Resolutions.ini
supported_resolutions := "," StrReplace(supported_resolutions, "`n", ",")

WinGet, poe_log_file, ProcessPath, ahk_group poe_window
poe_log_file := SubStr(poe_log_file, 1, InStr(poe_log_file, "\",,,LLK_InStrCount(poe_log_file, "\"))) "logs\client.txt"
If FileExist(poe_log_file)
{
	poe_log := FileOpen(poe_log_file, "r")
	poe_log_content := poe_log.Read()
}

If (fullscreen = "false")
{
	poe_width -= xborder*2
	poe_height := poe_height - caption - yborder*2
	xScreenOffSet += xborder
	yScreenOffSet += caption + yborder
}

IniRead, fSize_config0, data\Resolutions.ini, %poe_height%p, font-size0, 16
IniRead, fSize_config1, data\Resolutions.ini, %poe_height%p, font-size1, 14
fSize0 := fSize_config0
fSize1 := fSize_config1

IniRead, window_docking, ini\config.ini, Settings, top-docking, 1
IniRead, custom_resolution_setting, ini\config.ini, Settings, enable custom-resolution
If (custom_resolution_setting != 0) && (custom_resolution_setting != 1)
{
	IniWrite, 0, ini\config.ini, Settings, enable custom-resolution
	custom_resolution_setting := 0
}

If (custom_resolution_setting = 1)
{
	IniRead, custom_resolution, ini\config.ini, Settings, custom-resolution
	IniRead, custom_width, ini\config.ini, Settings, custom-width
	If !IsNumber(custom_resolution) || !IsNumber(custom_width)
	{
		MsgBox, Incorrect config.ini settings detected: custom resolution enabled but none selected.`nThe setting will be reset and the script restarted.
		IniWrite, 0, ini\config.ini, Settings, enable custom-resolution
		Reload
		ExitApp
	}

	If (custom_resolution > height_native) || (custom_width > width_native) ;check resolution in case of manual .ini edit
	{
		MsgBox, Incorrect config.ini settings detected.`nThe script will now exit.
		IniWrite, 0, ini\config.ini, Settings, enable custom-resolution
		IniWrite, %height_native%, ini\config.ini, Settings, custom-resolution
		IniWrite, %width_native%, ini\config.ini, Settings, custom-width
		ExitApp
	}
	If (fullscreen = "true")
		WinMove, ahk_group poe_window,, % xScreenOffset_monitor, % yScreenOffset_monitor, % poe_width, %custom_resolution%
	Else
	{
		WinMove, ahk_group poe_window,,, % (window_docking = 0) ? "" : yScreenOffset_monitor, % custom_width + xborder*2, % custom_resolution + caption + yborder*2
		WinGetPos, xScreenOffSet, yScreenOffSet,,, ahk_group poe_window
		xScreenOffSet += xborder
		yScreenOffSet += caption + yborder
		poe_width := custom_width
	}
	poe_height := custom_resolution
	IniRead, fSize_config0, data\Resolutions.ini, %poe_height%p, font-size0, 16
	IniRead, fSize_config1, data\Resolutions.ini, %poe_height%p, font-size1, 14
	fSize0 := fSize_config0
	fSize1 := fSize_config1
}

If !FileExist("img\Recognition (" poe_height "p\GUI\")
	FileCreateDir, img\Recognition (%poe_height%p)\GUI\
If !FileExist("img\Recognition (" poe_height "p\Betrayal\")
	FileCreateDir, img\Recognition (%poe_height%p)\Betrayal\

GoSub, Init_variables
GoSub, Init_screenchecks
GoSub, Init_general
GoSub, Init_alarm
GoSub, Init_betrayal
GoSub, Init_cloneframes
GoSub, Init_delve
If WinExist("ahk_exe GeForceNOW.exe")
	GoSub, Init_geforce
GoSub, Init_gwennen
GoSub, Init_itemchecker
GoSub, Init_lake_helper
GoSub, Init_legion
GoSub, Init_maps
GoSub, Init_notepad
GoSub, Init_omnikey
GoSub, Init_searchstrings
GoSub, Init_conversions
GoSub, Init_leveling_guide

SetTimer, Loop, 1000
SetTimer, Log_loop, 1500

timeout := 0
If (custom_resolution_setting = 1)
	WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window

GoSub, Resolution_check

SoundBeep, 100
GoSub, GUI
GoSub, Recombinators

If (clone_frames_enabled != "")
	GoSub, GUI_clone_frames
GoSub, Screenchecks_gamescreen
SetTimer, MainLoop, 100
If (update_available = 1)
	ToolTip, % "New version available: " version_online "`nCurrent version:  " version_installed "`nPress TAB to open the release page.`nPress ESC to dismiss this notification.", % xScreenOffSet + poe_width/2*0.9, % yScreenOffSet
Return

#If (stash_search_scroll_mode = 1) && (scroll_in_progress != 1)
	
WheelUp::
scroll_in_progress := 1
parsed_number := ""
If (scrollboard1 = "")
{
	Loop, Parse, clipboard
	{
		If IsNumber(A_Loopfield)
			parsed_number := (parsed_number = "") ? A_Loopfield : parsed_number A_Loopfield
	}
	clipboard := StrReplace(clipboard, parsed_number, parsed_number + 1)
}
Else
{
	scrollboard_active -= (scrollboard_active > 1) ? 1 : 0
	clipboard := scrollboard%scrollboard_active%
	ClipWait, 0.05
}
SendInput, ^{f}
sleep, 25
SendInput, ^{v}
sleep, 200
scroll_in_progress := 0
Return

WheelDown::
scroll_in_progress := 1
parsed_number := ""
If (scrollboard1 = "")
{
	Loop, Parse, clipboard
	{
		If IsNumber(A_Loopfield)
			parsed_number := (parsed_number = "") ? A_Loopfield : parsed_number A_Loopfield
	}
	clipboard := StrReplace(clipboard, parsed_number, parsed_number - 1)
}
Else
{
	scrollboard_active += (scrollboard_active < scrollboards) ? 1 : 0
	clipboard := scrollboard%scrollboard_active%
	ClipWait, 0.05
}
SendInput, ^{f}
sleep, 25
SendInput, ^{v}
sleep, 200
scroll_in_progress := 0
Return

#IfWinActive ahk_group poe_ahk_window

#Include *i modules\hotkeys.ahk

::.lab::
LLK_HotstringClip(A_ThisHotkey, 1)
Return

:?:.llk::
LLK_HotstringClip(A_ThisHotkey, 1)
Return

:?:.wiki::
LLK_HotstringClip(A_ThisHotkey, 1)
Return

::.legion::
SendInput, {ESC}
GoSub, Legion_seeds
GoSub, Legion_seeds2
Return

Tab::
If WinExist("ahk_id " hwnd_lakeboard)
{
	Loop 25
	{
		lake_tile%A_Index%_toggle := "img\GUI\square_blank.png"
		GuiControl, lakeboard:, lake_tile%A_Index%, img\GUI\square_blank.png
		GuiControl, lakeboard:, lake_tile%A_Index%_text1, % ""
		lake_entrance := ""
		lake_distances[A_Index] := ""
	}
	Return
}
If WinExist("ahk_id " hwnd_delve_grid)
{
	Loop 49
	{
		delve_hidden_nodes := ""
		delve_node%A_Index%_toggle := "img\GUI\square_blank.png"
		GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
		If (delve_node_%A_Index% = "")
			continue
		delve_node_%A_Index% := ""	
		delve_node_u%A_Index%_toggle := "img\GUI\square_blank.png"
		GuiControl, delve_grid:, delve_node_u%A_Index%, % delve_node_u%A_Index%_toggle
		delve_node_r%A_Index%_toggle := "img\GUI\square_blank.png"
		GuiControl, delve_grid:, delve_node_r%A_Index%, % delve_node_r%A_Index%_toggle
		delve_node_d%A_Index%_toggle := "img\GUI\square_blank.png"
		GuiControl, delve_grid:, delve_node_d%A_Index%, % delve_node_d%A_Index%_toggle
		delve_node_l%A_Index%_toggle := "img\GUI\square_blank.png"
		GuiControl, delve_grid:, delve_node_l%A_Index%, % delve_node_l%A_Index%_toggle
	}
	Return
}
If (lab_mode = 1)
{
	start := A_TickCount
	While GetKeyState("Tab", "P")
	{
		If (A_TickCount >= start + 200)
		{
			GoSub, Lab_info
			KeyWait, Tab
			Return
		}
	}
}
If (update_available = 1)
{
	Run, https://github.com/Lailloken/Lailloken-UI/releases
	ExitApp
	Return
}
SendInput, {Tab}
Return

ESC::
If (stash_search_scroll_mode = 1)
	Return
If (update_available = 1)
{
	ToolTip
	update_available := 0
	Return
}
If WinExist("ahk_id " hwnd_itemchecker)
{
	Gui, itemchecker: Destroy
	hwnd_itemchecker := ""
	Return
}
If WinExist("ahk_id " hwnd_context_menu)
{
	Gui, context_menu: Destroy
	hwnd_context_menu := ""
	Return
}
If WinExist("ahk_id " hwnd_lakeboard)
{
	LLK_Overlay("lakeboard", "hide")
	Return
}
If WinExist("ahk_id " hwnd_gear_tracker)
{
	LLK_GearTrackerGUI(1)
	GoSub, Log_loop
	Gui, gear_tracker: Destroy
	hwnd_gear_tracker := ""
	gear_tracker_limit := 6
	gear_tracker_filter := 1
	WinActivate, ahk_group poe_window
	Return
}
If WinExist("ahk_id " hwnd_delve_grid)
{
	LLK_Overlay("delve_grid", "hide")
	LLK_Overlay("delve_grid2", "hide")
	WinActivate, ahk_group poe_window
	Return
}
If WinActive("ahk_id " hwnd_notepad_edit)
{
	Gui, notepad_edit: Submit, NoHide
	WinGetPos,,, notepad_width, notepad_height, ahk_id %hwnd_notepad_edit%
	notepad_width -= xborder*2
	notepad_height -= caption + yborder*2
	notepad_text := StrReplace(notepad_text, "[", "(")
	notepad_text := StrReplace(notepad_text, "]", ")")
	LLK_Overlay("notepad_edit", "hide")
	Return
}
If WinActive("ahk_id " hwnd_recombinator_window)
{
	Gosub, Recombinator_windowGuiClose
	Return
}
If WinExist("ahk_id " hwnd_legion_treemap) || WinExist("ahk_id " hwnd_legion_window)
{
	Gui, legion_treemap: Destroy
	hwnd_legion_treemap := ""
	Gui, legion_treemap2: Destroy
	hwnd_legion_treemap2 := ""
	Gui, legion_window: Destroy
	hwnd_legion_window := ""
	Gui, legion_list: Destroy
	hwnd_legion_list := ""
	Gui, legion_help: Destroy
	Return
}
If WinExist("ahk_id " hwnd_betrayal_info) || WinExist("ahk_id " hwnd_betrayal_info_members)
{
	WinActivate, ahk_group poe_window
	LLK_Overlay("betrayal_info", "hide")
	If WinExist("ahk_id " hwnd_betrayal_info_overview)
		LLK_Overlay("betrayal_info_overview")
	If WinExist("ahk_id " hwnd_betrayal_info_members)
		LLK_Overlay("betrayal_info_members", "hide")
	If LLK_ImageSearch("betrayal")
		SendInput, {ESC}
	WinActivate, ahk_group poe_window
	Return
}
Else If WinExist("ahk_id " hwnd_gwennen_setup)
{
	Gui, gwennen_setup: Destroy
	hwnd_gwennen_setup := ""
	WinActivate, ahk_group poe_window
	Return
}
Else If WinExist("ahk_id " hwnd_map_info_menu)
{
	Gui, map_info_menu: Destroy
	hwnd_map_info_menu := ""
	WinActivate, ahk_group poe_window
	Return
}
Else SendInput, {ESC}
Return

#If WinExist("ahk_id " hwnd_clone_frames_menu)

F1::
MouseGetPos, mouseXpos, mouseYpos
clone_frame_new_topleft_x := mouseXpos - xScreenOffSet
clone_frame_new_topleft_y := mouseYpos - yScreenOffSet
GuiControl, clone_frames_menu: Text, clone_frame_new_topleft_x, % clone_frame_new_topleft_x
GuiControl, clone_frames_menu: Text, clone_frame_new_topleft_y, % clone_frame_new_topleft_y
GoSub, Clone_frames_dimensions
Return

F2::
MouseGetPos, mouseXpos, mouseYpos
clone_frame_new_width := mouseXpos - clone_frame_new_topleft_x - xScreenOffSet
clone_frame_new_height := mouseYpos - clone_frame_new_topleft_y - yScreenOffSet
GuiControl, clone_frames_menu: Text, clone_frame_new_width, % clone_frame_new_width
GuiControl, clone_frames_menu: Text, clone_frame_new_height, % clone_frame_new_height
GoSub, Clone_frames_dimensions
Return

F3::
MouseGetPos, mouseXpos, mouseYpos
clone_frame_new_target_x := (mouseXpos + clone_frame_new_width * clone_frame_new_scale_x//100 > xScreenOffset + poe_width) ? poe_width - clone_frame_new_width * clone_frame_new_scale_x//100 : mouseXpos - xScreenOffSet
clone_frame_new_target_y := (mouseYpos + clone_frame_new_height * clone_frame_new_scale_y//100 > yScreenOffset + poe_height) ? poe_height - clone_frame_new_height * clone_frame_new_scale_y//100 : mouseYpos - yScreenOffSet
GuiControl, clone_frames_menu: Text, clone_frame_new_target_x, % clone_frame_new_target_x
GuiControl, clone_frames_menu: Text, clone_frame_new_target_y, % clone_frame_new_target_y
GoSub, Clone_frames_dimensions
Return

#If (horizon_toggle = 1)
	
a::
b::
c::
d::
e::
f::
g::
h::
i::
j::
k::
l::
m::
n::
o::
p::
q::
r::
s::
t::
u::
v::
w::
x::
y::
z::LLK_Omnikey_ToolTip(maps_%A_ThisHotkey%)

#If WinExist("ahk_id " hwnd_lakeboard)
	
Left::
If (SubStr(lake_tiles, 1, 1) = 3)
	Return
lake_tiles := (SubStr(lake_tiles, 1, 1) > 3) ? SubStr(lake_tiles, 1, 1) - 1 . SubStr(lake_tiles, 2, 1) : lake_tiles
hwnd_lakeboard := ""
IniWrite, % lake_tiles, ini\lake helper.ini, UI, board size
GoSub, Lake_helper
Return

Right::
If (SubStr(lake_tiles, 1, 1) = 5)
	Return
lake_tiles := (SubStr(lake_tiles, 1, 1) < 5) ? SubStr(lake_tiles, 1, 1) + 1 . SubStr(lake_tiles, 2, 1) : lake_tiles
hwnd_lakeboard := ""
IniWrite, % lake_tiles, ini\lake helper.ini, UI, board size
GoSub, Lake_helper
Return

Down::
If (SubStr(lake_tiles, 2, 1) = 3)
	Return
lake_tiles := (SubStr(lake_tiles, 2, 1) > 3) ? SubStr(lake_tiles, 1, 1) . SubStr(lake_tiles, 2, 1) - 1 : lake_tiles
hwnd_lakeboard := ""
IniWrite, % lake_tiles, ini\lake helper.ini, UI, board size
GoSub, Lake_helper
Return

Up::
If (SubStr(lake_tiles, 2, 1) = 5)
	Return
lake_tiles := (SubStr(lake_tiles, 2, 1) < 5) ? SubStr(lake_tiles, 1, 1) . SubStr(lake_tiles, 2, 1) + 1 : lake_tiles
hwnd_lakeboard := ""
IniWrite, % lake_tiles, ini\lake helper.ini, UI, board size
GoSub, Lake_helper
Return

#If

#Include modules\alarm-timer.ahk

Apply_resolution:
Gui, settings_menu: Submit, NoHide
If (A_GuiControl = "custom_resolution_setting")
{
	IniWrite, % %A_GuiControl%, ini\config.ini, Settings, enable custom-resolution
	Return
}
If (A_GuiControl = "window_docking")
{
	IniWrite, % %A_GuiControl%, ini\config.ini, Settings, top-docking
	Return
}
custom_width := (custom_width > width_native) ? width_native : custom_width
poe_width := (fullscreen = "true") ? width_native : custom_width
If (fullscreen = "false")
{
	custom_resolution += caption + yborder*2
	poe_width += (poe_width > width_native) ? 0 : xborder*2
}
WinMove, ahk_group poe_window,, % (fullscreen = "false") ? xScreenOffset_monitor - xborder : xScreenOffset_monitor, %yScreenOffset_monitor%, %poe_width%, %custom_resolution%
WinGetPos,,, poe_width, custom_resolution, ahk_group poe_window
If (fullscreen = "false")
{
	xScreenOffSet := (poe_width < width_native) ? xScreenOffset_monitor + (width_native - poe_width)/2 : xScreenOffset_monitor - xborder
	yScreenOffSet := (custom_resolution < height_native) ? yScreenOffset_monitor + (height_native - custom_resolution)/2 : yScreenOffset_monitor - yborder - caption
	WinMove, ahk_group poe_window,, %xScreenOffSet%, % (window_docking = 1) ? yScreenOffset_monitor : yScreenOffSet_monitor + (height_native - custom_resolution)/2, %poe_width%, %custom_resolution%
}
IniWrite, %custom_resolution_setting%, ini\config.ini, Settings, enable custom-resolution
IniWrite, % (fullscreen = "false") ? custom_resolution - caption - yborder*2 : custom_resolution, ini\config.ini, Settings, custom-resolution
IniWrite, % (fullscreen = "false") ? custom_width : width_native, ini\config.ini, Settings, custom-width
Reload
ExitApp
Return

Apply_settings_general:
If (A_GuiControl = "interface_size_minus")
{
	fSize_offset -= 1
	IniWrite, %fSize_offset%, ini\config.ini, UI, font-offset
}
If (A_GuiControl = "interface_size_plus")
{
	fSize_offset += 1
	IniWrite, %fSize_offset%, ini\config.ini, UI, font-offset
}
If (A_GuiControl = "interface_size_reset")
{
	fSize_offset := 0
	IniWrite, %fSize_offset%, ini\config.ini, UI, font-offset
}
fSize0 := fSize_config0 + fSize_offset
fSize1 := fSize_config1 + fSize_offset
Gui, settings_menu: Submit, NoHide
If (A_GuiControl = "kill_script")
	IniWrite, %kill_script%, ini\config.ini, Settings, kill script
If (A_GuiControl = "kill_timeout")
{
	kill_timeout := (kill_timeout = "") ? 0 : kill_timeout
	IniWrite, %kill_timeout%, ini\config.ini, Settings, kill-timeout
}
If (A_GuiControl = "panel_position0")
	IniWrite, %panel_position0%, ini\config.ini, UI, panel-position0
If (A_GuiControl = "panel_position1")
	IniWrite, %panel_position1%, ini\config.ini, UI, panel-position1
If (A_GuiControl = "hide_panel")
	IniWrite, %hide_panel%, ini\config.ini, UI, hide panel
If (A_GuiControl = "enable_browser_features")
	IniWrite, %enable_browser_features%, ini\config.ini, Settings, enable browser features
If (A_GuiControl = "enable_caps_toggling")
{
	IniWrite, %enable_caps_toggling%, ini\config.ini, Settings, enable CapsLock-toggling
	Reload
	ExitApp
}
SetTimer, Settings_menu, 10
GoSub, GUI
WinActivate, ahk_group poe_window
Return

#Include modules\bestiary search.ahk

#Include modules\betrayal-info.ahk

#Include modules\clone-frames.ahk

#Include modules\delve-helper.ahk

Exit:
Gdip_Shutdown(pToken)
poe_log.Close()
If (timeout != 1)
{
	If !(alarm_timestamp < A_Now) && (alarm_loop != 1)
		IniWrite, %alarm_timestamp%, ini\alarm.ini, Settings, alarm-timestamp
	
	IniWrite, %notepad_width%, ini\notepad.ini, UI, width
	IniWrite, %notepad_height%, ini\notepad.ini, UI, height
	notepad_text := StrReplace(notepad_text, "`n", ",,")
	IniWrite, %notepad_text%, ini\notepad.ini, Text, text
	
	Loop, Parse, clone_frames_list, `n, `n
	{
		If (A_LoopField = "Settings")
			continue
		IniWrite, % clone_frame_%A_LoopField%_enable, ini\clone frames.ini, %A_LoopField%, enable
	}
	
	IniRead, guide_progress_ini, ini\leveling guide.ini, Progress,, % A_Space
	If (guide_progress != "") && (guide_progress != guide_progress_ini)
	{
		IniDelete, ini\leveling guide.ini, Progress
		IniWrite, % guide_progress, ini\leveling guide.ini, Progress
	}
}
ExitApp
Return

Geforce_now_apply:
Gui, settings_menu: Submit, NoHide
pixelsearch_variation := (pixelsearch_variation = "") ? 0 : pixelsearch_variation
pixelsearch_variation := (pixelsearch_variation > 255) ? 255 : pixelsearch_variation
imagesearch_variation := (imagesearch_variation = "") ? 0 : imagesearch_variation
imagesearch_variation := (imagesearch_variation > 255) ? 255 : imagesearch_variation
If (A_GuiControl = "pixelsearch_variation")
	IniWrite, % pixelsearch_variation, ini\geforce now.ini, Settings, pixel-check variation
If (A_GuiControl = "imagesearch_variation")
	IniWrite, % imagesearch_variation, ini\geforce now.ini, Settings, image-check variation
Return

#Include modules\GUI.ahk

#Include modules\Gwennen regex.ahk

Init_conversions:
IniRead, ini_version, ini\config.ini, Versions, ini-version, 0
If (ini_version < 12406) && FileExist("ini\pixel checks (" poe_height "p).ini") ;migrate pixel-check settings to screen-checks ini
{
	IniRead, pixel_gamescreen_color1, ini\pixel checks (%poe_height%p).ini, gamescreen, color 1
	IniRead, convert_pixelchecks, ini\pixel checks (%poe_height%p).ini, gamescreen
	IniWrite, % convert_pixelchecks, ini\screen checks (%poe_height%p).ini, gamescreen
	FileDelete, ini\pixel checks*.ini
}
IniWrite, 12406, ini\config.ini, Versions, ini-version ;1.24.1 = 12401, 1.24.10 = 12410, 1.24.1-hotfixX = 12401.X

FileReadLine, version_installed, version.txt, 1
version_installed := StrReplace(version_installed, "`n")
whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
whr.Open("GET", "https://raw.githubusercontent.com/Lailloken/Lailloken-UI/main/version.txt", true)
whr.Send()
whr.WaitForResponse()
version_online := StrReplace(whr.ResponseText, "`n")
update_available := IsNumber(version_online) && (version_online > version_installed) ? 1 : 0
Loop, 2
{
	Loop, Parse, % (A_Index = 1) ? version_installed : version_online
	{
		If (A_Index = 1)
			parse := "v"
		If (A_Index = 1 || A_Index = 3)
			parse .= A_Loopfield "."
		Else If (A_Index = 4 && A_Loopfield = 0)
			continue
		Else If (A_Loopfield = ".")
			parse .= "-hotfix"
		Else parse .= A_Loopfield
	}
	If (A_Index = 1)
		version_installed := parse
	Else version_online := parse
}
Return

Init_geforce:
IniRead, pixelsearch_variation, ini\geforce now.ini, Settings, pixel-check variation, 0
IniRead, imagesearch_variation, ini\geforce now.ini, Settings, image-check variation, 25
Return

Init_general:
IniRead, panel_xpos, ini\config.ini, UI, button xcoord, 0
IniRead, panel_ypos, ini\config.ini, UI, button ycoord, 0
IniRead, hide_panel, ini\config.ini, UI, hide panel, 0

IniRead, enable_notepad, ini\config.ini, Features, enable notepad, 0
IniRead, enable_alarm, ini\config.ini, Features, enable alarm, 0
IniRead, enable_pixelchecks, ini\config.ini, Settings, background pixel-checks, 1
IniRead, enable_browser_features, ini\config.ini, Settings, enable browser features, 1

IniRead, game_version, ini\config.ini, Versions, game-version, 31800 ;3.17.4 = 31704, 3.17.10 = 31710
IniRead, fSize_offset, ini\config.ini, UI, font-offset, 0
fSize0 := fSize_config0 + fSize_offset
fSize1 := fSize_config1 + fSize_offset
Return

Init_variables:
click := 1
trans := 220
blocked_hotkeys := "!,^,+"
pixelchecks_enabled := "gamescreen,"
imagesearch_variation := 25
pixelsearch_variation := 0
stash_search_usecases := "stash,vendor"
Sort, stash_search_usecases, D`,
pixelchecks_list := "gamescreen"
imagechecks_list := "betrayal,bestiary,gwennen,stash,vendor"
guilist := "notepad_edit|notepad|notepad_sample|settings_menu|alarm|alarm_sample|map_mods_window|map_mods_toggle|betrayal_info|betrayal_info_overview|lab_layout|lab_marker|"
guilist .= "betrayal_search|gwennen_setup|betrayal_info_members|legion_window|legion_list|legion_treemap|legion_treemap2|notepad_drag|itemchecker|"
buggy_resolutions := "768,1024,1050"
allowed_recomb_classes := "shield,sword,quiver,bow,claw,dagger,mace,ring,amulet,helmet,glove,boot,belt,wand,staves,axe,sceptre,body,sentinel"
delve_directions := "u,d,l,r,"
gear_tracker_limit := 6
gear_tracker_filter := 1
global lake_entrance, lake_distances := [], delve_hidden_node, delve_distances := []
Return

#Include modules\item-checker.ahk

#Include modules\lab-info.ahk

#Include modules\overlayke.ahk

#Include modules\seed-explorer.ahk

#Include modules\leveling tracker.ahk

Log_loop:
If !WinActive("ahk_group poe_ahk_window")
	Return
test_start := A_TickCount
poe_log_content := poe_log.Read()
StringLower, poe_log_content, poe_log_content
Loop, Parse, poe_log_content, `r`n, `r`n
{
	If InStr(A_Loopfield, "generating level")
	{
		current_location := SubStr(A_Loopfield, InStr(A_Loopfield, "area """) + 6)
		Loop, Parse, current_location
		{
			If (A_Index = 1)
				current_location := ""
			If (A_Loopfield = """")
				break
			current_location .= A_Loopfield
		}
	}
	If (gear_tracker_char != "")
	{
		If InStr(A_Loopfield, "is now level") && InStr(A_Loopfield, gear_tracker_char)
			gear_tracker_characters[gear_tracker_char] := SubStr(A_Loopfield, InStr(A_Loopfield, "is now level ") + 13)
	}
}

If (gear_tracker_parse != "`n") && WinExist("ahk_id " hwnd_gear_tracker_indicator)
{
	gear_tracker_count := 0
	Loop, Parse, gear_tracker_parse, `n, `n
	{
		If (A_Loopfield = "")
			continue
		If (SubStr(A_Loopfield, 2, 2) <= gear_tracker_characters[gear_tracker_char])
			gear_tracker_count += 1
	}
	GuiControl, gear_tracker_indicator:, gear_tracker_upgrades, % (gear_tracker_count = 0) ? "" : gear_tracker_count
}

If WinExist("ahk_id " hwnd_leveling_guide2)
{
	target_location := InStr(guide_panel2_text, "`n") ? SubStr(guide_panel2_text, InStr(guide_panel2_text, "`n",,, LLK_InStrCount(guide_panel2_text, "`n"))) : guide_panel2_text
	target_location := SubStr(target_location, -1*StrLen(current_location) + 1)
	If (target_location = current_location)
	{
		guide_progress .= (guide_progress = "") ? guide_panel2_text : "`n" guide_panel2_text
		guide_text := StrReplace(guide_text, guide_panel2_text "`n",,, 1)
		GoSub, Leveling_guide_progress
	}
}

If InStr(text2, "ctrl-f-v") && WinExist("ahk_id " hwnd_leveling_guide2)
{
	search := ""
	If (all_gems = "")
		FileRead, all_gems, data\leveling tracker\gems.txt
	Loop, Parse, guide_panel2_text, `n, `n
	{
		If InStr(A_Loopfield, "buy")
		{
			parse := SubStr(A_Loopfield, InStr(A_Loopfield, "buy") + 4)
			parsed_gem := ""
			Loop, Parse, parse
			{
				parsed_gem .= A_Loopfield
				If (LLK_SubStrCount(all_gems, parsed_gem, "`n", 1) = 1) && (StrLen(parsed_gem) > 2)
				{
					parse := parsed_gem
					break
				}
			}
			If (StrLen(search parse) >= 47)
				break
			search .= parse "|"
		}
	}
	search := "^(" SubStr(StrReplace(search, " ", "."), 1, -1) ")"
	clipboard := search
}

If (enable_delvelog = 1)
{
	If (current_location = "delve_main" && !WinExist("ahk_id " hwnd_delve_panel))
		LLK_Overlay("delve_panel", "show")
	If (current_location != "delve_main" && WinExist("ahk_id " hwnd_delve_panel))
		LLK_Overlay("delve_panel", "hide")
}
poe_log_content := ""
Return

Loop:
If !WinExist("ahk_group poe_window")
{
	poe_window_closed := 1
	hwnd_poe_client := ""
	ToolTip
	update_available := 0
}
If !WinExist("ahk_group poe_window") && (A_TickCount >= last_check + kill_timeout*60000) && (kill_script = 1) && ((alarm_timestamp = "") || (alarm_loop = 1))
	ExitApp
If WinExist("ahk_group poe_window")
{
	
	last_check := A_TickCount
	If (hwnd_poe_client = "")
		hwnd_poe_client := WinExist("ahk_group poe_window")
	If (poe_window_closed = 1) && (custom_resolution_setting = 1)
	{
		Sleep, 4000
		If (fullscreen = "true")
			WinMove, ahk_group poe_window,, %xScreenOffset%, %yScreenOffset%, %poe_width%, %custom_resolution%
		Else WinMove, ahk_group poe_window,, % xScreenOffset - xborder, % (window_docking = 0) ? yScreenOffset - caption - yborder : yScreenOffset_monitor, % custom_width + xborder*2, % custom_resolution + caption + yborder*2
		poe_height := custom_resolution
	}
	If (poe_window_closed = 1) && (custom_resolution_setting = 0) && (fullscreen != "true")
	{
		Sleep, 4000
		WinMove, ahk_group poe_window,, % xScreenOffSet - xborder, % yScreenOffSet - caption - yborder
	}
	poe_window_closed := 0
}

If (enable_alarm != 0) && (alarm_timestamp != "")
{
	alarm_timestamp0 := alarm_timestamp
	EnvSub, alarm_timestamp0, %A_Now%, S
	If (alarm_timestamp0 > 0)
	{
		countdown_min := (StrLen(Floor(alarm_timestamp0//60)) = 1) ? 0 Floor(alarm_timestamp0//60) : Floor(alarm_timestamp0//60)
		countdown_sec := (StrLen(Mod(alarm_timestamp0, 60)) = 1) ? 0 Mod(alarm_timestamp0, 60) : Mod(alarm_timestamp0, 60)
		GuiControl, alarm: Text, alarm_countdown, % countdown_min ":" countdown_sec
	}
	Else
	{
		If (alarm_loop = 1) && (alarm_minutes > 0)
		{
			SoundBeep, 500, 100
			EnvAdd, alarm_timestamp, % alarm_minutes, S
			Return
		}
		alarm_fontcolor0 := (alarm_fontcolor0 = "Blue") ? alarm_fontcolor : "Blue"
		Gui, alarm: Font, c%alarm_fontcolor0%
		GuiControl, alarm: Font, alarm_countdown
		countdown_min := (StrLen(Floor(alarm_timestamp0//-60)) = 1) ? 0 Floor(alarm_timestamp0//-60) : Floor(alarm_timestamp0//-60)
		countdown_sec := (StrLen(Mod(alarm_timestamp0, -60)) < 3) ? 0 Mod(alarm_timestamp0, -60) * -1 : Mod(alarm_timestamp0, -60) * -1
		GuiControl, alarm: Text, alarm_countdown, % countdown_min ":" countdown_sec
		If !WinActive("ahk_group poe_window")
		{
			WinSet, Style, +0xC00000, ahk_id %hwnd_alarm%
			WinSet, ExStyle, -0x20, ahk_id %hwnd_alarm%
			Gui, alarm: Show, % "NA AutoSize"
			Gui, alarm_drag: Destroy
			hwnd_alarm_drag := ""
		}
		If !WinExist("ahk_id " hwnd_alarm) && WinExist("ahk_group poe_window")
			LLK_Overlay("alarm", "show")
	}
}
Return

MainLoop:
If !WinActive("ahk_group poe_window") && !WinActive("ahk_class AutoHotkeyGUI")
{
	inactive_counter += 1
	If (inactive_counter = 3)
	{
		;Gui, notepad_contextmenu: Destroy
		Gui, context_menu: Destroy
		Gui, stash_search_context_menu: Destroy
		Gui, bestiary_menu: Destroy
		Gui, map_info_menu: Destroy
		hwnd_map_info_menu := ""
		Gui, legion_help: Destroy
		LLK_Overlay("hide")
	}
}
If (WinActive("ahk_group poe_window") || WinActive("ahk_class AutoHotkeyGUI")) && (poe_window_closed != 1)
{
	If !WinActive("ahk_class AutoHotkeyGUI") && WinExist("ahk_id " hwnd_bestiary_menu)
		Gui, bestiary_menu: Destroy
	If (inactive_counter != 0)
	{
		inactive_counter := 0
		LLK_Overlay("show")
	}
	If (pixelchecks_enabled != "") && (enable_pixelchecks = 1)
	{
		Loop, Parse, pixelchecks_enabled, `,, `,
		{
			If (A_LoopField = "")
				break
			LLK_PixelSearch(A_LoopField)
		}
		If (map_info_pixelcheck_enable = 1)
		{
			If (gamescreen = 1)
			{
				If !WinExist("ahk_id " hwnd_map_mods_window) && (toggle_map_mods_panel = 1) && (hwnd_map_mods_window != "") || (map_mods_panel_fresh = 1)
				{
					LLK_Overlay("map_mods_window", "show")
					map_mods_panel_fresh := 0
				}
				If !WinExist("ahk_id " hwnd_map_mods_toggle) && (hwnd_map_mods_toggle != "") || (map_mods_panel_fresh = 1)
				{
					LLK_Overlay("map_mods_toggle", "show")
					map_mods_panel_fresh := 0
				}
			}
			Else
			{
				If WinExist("ahk_id " hwnd_map_mods_window) && (map_mods_panel_fresh != 1) && (hwnd_map_mods_window != "")
					LLK_Overlay("map_mods_window", "hide")
				If WinExist("ahk_id " hwnd_map_mods_toggle) && (map_mods_panel_fresh != 1) && (hwnd_map_mods_window != "")
					LLK_Overlay("map_mods_toggle", "hide")
			}
		}
	}
	If ((clone_frames_enabled != "") && (clone_frames_pixelcheck_enable = 0)) || ((clone_frames_enabled != "") && (clone_frames_pixelcheck_enable = 1) && (gamescreen = 1))
	{
		Loop, Parse, clone_frames_enabled, `,, `,
		{
			If (A_LoopField = "")
				Break
			If !WinExist("ahk_id " hwnd_%A_Loopfield%)
				Gui, clone_frames_%A_Loopfield%: Show, NA
			p%A_LoopField% := Gdip_BitmapFromScreen(xScreenOffset + clone_frame_%A_LoopField%_topleft_x "|" yScreenOffset + clone_frame_%A_LoopField%_topleft_y "|" clone_frame_%A_LoopField%_width "|" clone_frame_%A_LoopField%_height)
			w%A_LoopField% := clone_frame_%A_LoopField%_width
			h%A_LoopField% := clone_frame_%A_LoopField%_height
			w%A_LoopField%_dest := clone_frame_%A_LoopField%_width * clone_frame_%A_LoopField%_scale_x//100
			h%A_LoopField%_dest := clone_frame_%A_LoopField%_height * clone_frame_%A_LoopField%_scale_y//100
			hbm%A_LoopField% := CreateDIBSection(w%A_LoopField%_dest, h%A_LoopField%_dest)
			hdc%A_LoopField% := CreateCompatibleDC()
			omb%A_LoopField% := SelectObject(hdc%A_LoopField%, hbm%A_LoopField%)
			g%A_LoopField% := Gdip_GraphicsFromHDC(hdc%A_LoopField%)
			Gdip_SetInterpolationMode(g%A_LoopField%, 0)
			Gdip_DrawImage(g%A_LoopField%, p%A_LoopField%, 0, 0, w%A_LoopField%_dest, h%A_LoopField%_dest, 0, 0, w%A_LoopField%, h%A_LoopField%, 0.2 + 0.16 * clone_frame_%A_LoopField%_opacity)
			Gdip_DisposeImage(p%A_LoopField%)
			UpdateLayeredWindow(hwnd_%A_LoopField%, hdc%A_LoopField%, xScreenOffset + clone_frame_%A_LoopField%_target_x, yScreenOffset + clone_frame_%A_LoopField%_target_y, w%A_LoopField%_dest, h%A_LoopField%_dest)
			SelectObject(hdc%A_Loopfield%, obm%A_Loopfield%)
			DeleteObject(hbm%A_Loopfield%)
			DeleteDC(hdc%A_Loopfield%)
			Gdip_DeleteGraphics(g%A_Loopfield%)
		}
	}
	Else
	{
		Loop, Parse, clone_frames_enabled, `,, `,
		{
			If WinExist("ahk_id " hwnd_%A_Loopfield%)
				Gui, clone_frames_%A_Loopfield%: Hide
		}
	}
}
Return

#Include modules\map-info.ahk

#Include modules\notepad.ahk

#Include modules\omni-key.ahk

Panel_drag:
MouseGetPos, panelXpos, panelYpos
panelXpos := (panelXpos >= xScreenOffSet + poe_width*0.998) ? xScreenOffSet + poe_width : panelXpos ;snap panel to edge when close (MouseGetPos coords are off by one pixel when on the edge)
panelXpos := (panelXpos < xScreenOffSet) ? xScreenOffSet : panelXpos
panelXpos := (panelXpos >= xScreenOffSet + poe_width/2) ? panelXpos - wGui : panelXpos
panelYpos := (panelYpos >= yScreenOffset + poe_height*0.998) ? yScreenOffSet + poe_height : panelYpos ;snap panel to edge when close (MouseGetPos coords are off by one pixel when on the edge)
panelYpos := (panelYpos < yScreenOffset) ? yScreenOffset : panelYpos
panelYpos := (panelYpos >= yScreenOffSet + poe_height/2) ? panelYpos - hGui : panelYpos
panelXpos -= xScreenOffSet
panelYpos -= yScreenOffSet
If (panelXpos + wGui >= poe_width - pixel_gamescreen_x1 - 1) && (panelYpos <= pixel_gamescreen_y1 + 1) ;protect pixel-check area
	panelYpos := pixel_gamescreen_y1 + 2
Gui, %A_Gui%: Show, % "NA x"xScreenOffSet + panelXpos " y"yScreenOffSet + panelYpos
If InStr(A_Gui, "map_mods")
{
	panelYpos2 := (panelYpos >= poe_height/2) ? panelYpos - hGui2 + 1 : panelYpos + hGui - 1
	Gui, map_mods_window: Show, % "NA x"xScreenOffSet + panelXpos " y"yScreenOffSet + panelYpos2
}
If InStr(A_Gui, "notepad_drag")
{
	notepad_gui := "notepad" StrReplace(A_Gui, "notepad_drag")
	panelXpos2 := (panelXpos >= poe_width/2) ? panelXpos - wGui2 + wGui : panelXpos
	panelYpos2 := (panelYpos >= poe_height/2) ? panelYpos - hGui2 + hGui : panelYpos
	Gui, %notepad_gui%: Show, % "NA x"xScreenOffSet + panelXpos2 " y"yScreenOffSet + panelYpos2
}
If (A_Gui = "alarm_drag")
{
	panelXpos2 := (panelXpos >= poe_width/2) ? panelXpos - wGui2 + wGui : panelXpos
	panelYpos2 := (panelYpos >= poe_height/2) ? panelYpos - hGui2 + hGui : panelYpos
	Gui, alarm: Show, % "NA x"xScreenOffSet + panelXpos2 " y"yScreenOffSet + panelYpos2
}
Return

#Include modules\recombinators.ahk

Resolution_check:
If InStr(buggy_resolutions, poe_height) || !InStr(supported_resolutions, "," poe_height "p")
{
	If InStr(buggy_resolutions, poe_height)
	{
text =
(
Unsupported resolution detected!

The script has detected a vertical screen-resolution of %poe_height% pixels which has caused issues with the game-client and the script in the past.

I have decided to end support for this resolution.
You have to run the client with a custom resolution, which you can do in the following window, to use this script.

You also have to enable "confine mouse to window" in the game's UI options.
)
	}
	Else If !InStr(supported_resolutions, "," poe_height "p")
	{
	
text =
(
Unsupported resolution detected!

The script has detected a vertical screen-resolution of %poe_height% pixels which is not supported.

You have to run the client with a custom resolution, which you can do in the following window, to use this script.

You also have to enable "confine mouse to window" in the game's UI options.
)
	}
	MsgBox, % text
	safe_mode := 1
	GoSub, settings_menu
	sleep, 2000
	Loop
	{
		If !WinExist("ahk_id " hwnd_settings_menu)
		{
			MsgBox, The script will now shut down.
			ExitApp
		}
		Sleep, 100
	}
	Return
}
Return

#Include modules\screen-checks.ahk

#Include modules\settings menu.ahk

#Include modules\search-strings.ahk

Timeout_chromatics:
KeyWait, v, D T0.5
If !ErrorLevel
{
	KeyWait, v
	SendInput, %strength%{tab}%dexterity%{tab}%intelligence%
}
If WinActive("ahk_group poe_window") || !ErrorLevel
{
	SetTimer, Timeout_chromatics, delete
	ToolTip,,,, 15
}
Return

Timeout_cluster_jewels:
KeyWait, F3, D T0.5
If !ErrorLevel
{
	KeyWait, F3
	SendInput, %wiki_cluster%
}
If WinActive("ahk_group poe_window") || !ErrorLevel
{
	SetTimer, Timeout_cluster_jewels, delete
	ToolTip,,,, 15
}
Return

ToolTip_clear:
SetTimer, ToolTip_clear, delete
ToolTip,,,, 17
Return

LLK_ItemCheck()
{
	global ThisHotkey_copy, fSize0, xScreenOffSet, yScreenOffset, poe_height, poe_width, hwnd_itemchecker
	global itemchecker_panel1, itemchecker_panel2, itemchecker_panel3, itemchecker_panel4, itemchecker_panel5, itemchecker_panel6, itemchecker_panel7, itemchecker_panel8, itemchecker_panel9, itemchecker_panel10, itemchecker_panel11, itemchecker_panel12, itemchecker_panel13, itemchecker_panel14, itemchecker_panel15
	If InStr(Clipboard, "`nUnidentified", 1) || (!InStr(Clipboard, "unique modifier") && !InStr(Clipboard, "prefix modifier") && !InStr(Clipboard, "suffix modifier"))
	{
		LLK_ToolTip("item cannot be checked")
		Return
	}
	
	If InStr(Clipboard, "attacks per second: ")
	{
		phys_dmg := 0
		pdps := 0
		ele_dmg := 0
		ele_dmg3 := 0
		ele_dmg4 := 0
		ele_dmg5 := 0
		edps0 := 0
		chaos_dmg := 0
		cdps := 0
		speed := 0
		Loop, Parse, clipboard, `r`n, `r`n
		{
			If InStr(A_LoopField,"Physical Damage: ")
			{
				phys_dmg := A_LoopField
				Loop, Parse, phys_dmg, " "
					If (A_Index=3)
						phys_dmg := A_LoopField
			}
			If InStr(A_LoopField,"Elemental Damage: ")
			{
				ele_dmg := StrReplace(A_LoopField, "`r`n")
				ele_dmg := StrReplace(ele_dmg, " (augmented)")
				ele_dmg := StrReplace(ele_dmg, ",")
				Loop, Parse, ele_dmg, " "
					If A_Index between 3 and 5
						ele_dmg%A_Index% := A_LoopField
			}
			If InStr(A_LoopField, "Chaos Damage: ")
			{
				chaos_dmg := StrReplace(A_LoopField, "`r`n")
				chaos_dmg := StrReplace(chaos_dmg, " (augmented)")
				Loop, Parse, chaos_dmg, " "
					If (A_Index=3)
						chaos_dmg := A_LoopField
			}
			If InStr(A_LoopField, "Attacks per Second: ")
			{
				speed := A_LoopField
				Loop, Parse, speed, " "
					If (A_Index=4)
						speed := SubStr(A_LoopField,1,4)
				break
			}
		}
		If (phys_dmg!=0)
		{
			Loop, Parse, phys_dmg, "-"
				phys%A_Index% := A_LoopField
			pdps := ((phys1+phys2)/2)*speed
			pdps := Format("{:0.2f}", pdps)
		}
		If (ele_dmg!=0)
		{
			edps2 := 0
			edps3 := 0
			Loop, Parse, ele_dmg3, "-"
				ele_dmg3_%A_Index% := A_LoopField
			edps1 := ((ele_dmg3_1+ele_dmg3_2)/2)*speed
			If (ele_dmg4!=0)
			{
				Loop, Parse, ele_dmg4, "-"
					ele_dmg4_%A_Index% := A_LoopField
				edps2 := ((ele_dmg4_1+ele_dmg4_2)/2)*speed
			}
			If (ele_dmg5!=0)
			{
				Loop, Parse, ele_dmg5, "-"
					ele_dmg5_%A_Index% := A_LoopField
				edps3 := ((ele_dmg5_1+ele_dmg5_2)/2)*speed
			}
			edps0 := edps1+edps2+edps3
			edps0 := Format("{:0.2f}", edps0)
		}
		If (chaos_dmg!=0)
		{
			Loop, Parse, chaos_dmg, "-"
				chaos_dmg%A_Index% := A_LoopField
			cdps := ((chaos_dmg1+chaos_dmg2)/2)*speed
			cdps := Format("{:0.2f}", cdps)
		}
		tdps := pdps+edps0+cdps
		tdps := Format("{:0.2f}", tdps)
	}
	
	;wanted to calculate the roll of the defense stat, but you can't copy it from item-info
	/*
	Loop, Parse, Clipboard, `n, `r
	{
		If InStr(A_LoopField, "armour:") || InStr(A_LoopField, "evasion rating:") || InStr(A_LoopField, "energy shield:")
		{
			defense := StrReplace(A_LoopField, "armour: ")
			defense := StrReplace(defense, "evasion rating: ")
			defense := StrReplace(defense, "energy shield: ")
			MsgBox, % defense
		}
	}
	*/
	
	itemcheck_affixes := " affixes: " LLK_SubStrCount(Clipboard, "prefix modifier", "`n") " + " LLK_SubStrCount(Clipboard, "suffix modifier", "`n")
	itemcheck_clip := SubStr(Clipboard, InStr(Clipboard, "item level:"))
	item_lvl := SubStr(itemcheck_clip, 1, InStr(itemcheck_clip, "`r`n",,, 1) - 1)
	item_lvl := StrReplace(item_lvl, "item level:")
	itemcheck_clip := StrReplace(itemcheck_clip, "`r`n", "|")
	StringLower, itemcheck_clip, itemcheck_clip
	;MsgBox, % itemcheck_clip
	itemcheck_parse := "(-.)|"
	loop := 0
	unique := InStr(Clipboard, "rarity: unique") ? 1 : 0
	mirrored := InStr(Clipboard, "`nMirrored", 1) ? 1 : 0
	affixes := []
	Loop, Parse, itemcheck_clip, | ;remove unnecessary item-info: implicits, crafted mods, etc.
	{
		If (A_Index = 1)
			itemcheck_clip := ""
		If (SubStr(A_LoopField, 1, 1) != "{") || InStr(A_LoopField, "implicit") || InStr(A_LoopField, "crafted")
			continue
		itemcheck_clip .= A_LoopField "`n"
	}
	
	Loop, Parse, itemcheck_clip, `n ;remove tooltips from item-info
	{
		If (A_Index = 1)
			itemcheck_clip := ""
		If (SubStr(A_LoopField, 1, 1) = "(")
			continue
		itemcheck_clip .= A_LoopField "`n"
	}
	
	;itemcheck_clip := StrReplace(itemcheck_clip, " (fractured)")
	itemcheck_clip := StrReplace(itemcheck_clip, " — Unscalable Value")
	
	While (SubStr(itemcheck_clip, 0) = "`n") ;remove white-space at the end
		itemcheck_clip := SubStr(itemcheck_clip, 1, -1)
	
	;combine hybrid mods into a single line, and put lines into affix-groups
	itemcheck_clip := StrReplace(itemcheck_clip, "}`n", "};;")
	itemcheck_clip := StrReplace(itemcheck_clip, "`n{", "|{")
	itemcheck_clip := StrReplace(itemcheck_clip, "`n", "(hybrid)`n(hybrid)")
	itemcheck_clip := StrReplace(itemcheck_clip, "};;", "}`n")
	
	Loop, Parse, itemcheck_clip, |
	{
		If (unique = 1) && !InStr(A_LoopField, "(") ;skip unscalable unique affix
			continue
		loop += 1
		tier := (unique = 1) ? "u" : InStr(A_LoopField, "tier:") ? SubStr(A_LoopField, InStr(A_LoopField, "tier: ") + 6, InStr(A_LoopField, ")") - InStr(A_LoopField, "tier: ") - 6) : 0
		Loop, Parse, A_LoopField, `n
		{
			If InStr(A_LoopField, "'s veiled")
				betrayal := SubStr(A_LoopField, InStr(A_LoopField, """") + 1, InStr(A_LoopField, "s v") - InStr(A_LoopField, """") + 1)
			If InStr(A_LoopField, "s' veiled")
				betrayal := SubStr(A_LoopField, InStr(A_LoopField, """") + 1, InStr(A_LoopField, "s' v") - InStr(A_LoopField, """") + 2)
			If (A_Index = 1)
				Continue
			tier .= (tier != "u") && InStr(A_LoopField, "(hybrid)") && !InStr(tier, "h") ? "h" : ""
			mod := betrayal StrReplace(A_LoopField, "(hybrid)")
			mod1 := InStr(mod, "adds") && InStr(mod, "to") ? StrReplace(mod, "to", "|",, 1) : mod
			mods.Push(A_LoopField ";;" tier)
			roll := ""
			Loop, Parse, % StrReplace(mod1, " (fractured)")
			{
				If IsNumber(A_LoopField) || InStr(itemcheck_parse, A_LoopField)
					roll .= A_LoopField ;(A_LoopField = ")") ? A_LoopField "," : A_LoopField
			}
			
			If InStr(roll, "(")
			{
				Loop, Parse, roll, `|
				{
					If (A_Index = 1)
						roll_count := 0
					If (A_LoopField = "")
						continue
					roll_count += 1
					roll_trigger := 0
					trigger_index := 0
					Loop, Parse, % InStr(A_LoopField, "(") ? A_LoopField : A_LoopField "(" A_LoopField "-" A_LoopField ")"
					{
						If (A_Index = 1)
						{
							roll%roll_count% := InStr(mod, "reduced") && (InStr(mod, "(-") || InStr(mod, "--")) ? "-" : ""
							roll%roll_count%_1 := ""
							roll%roll_count%_2 := ""
						}
						If IsNumber(A_LoopField) || (A_LoopField = ".") || (A_LoopField = "-" && A_Index = trigger_index + 1)
						{
							If (roll_trigger = 0)
								roll%roll_count% .= A_LoopField
							If (roll_trigger = 1)
								roll%roll_count%_1 .= A_LoopField
							If (roll_trigger = 2)
								roll%roll_count%_2 .= A_LoopField
						}
						If (A_LoopField = "(") || (A_LoopField = "-" && A_Index != trigger_index + 1)
						{
							roll_trigger += 1
							trigger_index := A_Index
						}
					}
				}
				;MsgBox, % roll1 " " roll1_1 " " roll1_2 "`n" roll2 " " roll2_1 " " roll2_2
				roll_qual := (roll_count = 1) ? Min(roll1_1, roll1_2) "," roll1 "," Max(roll1_1, roll1_2) : Min(roll1_1, roll1_2) + Min(roll2_1, roll2_2) "," roll1 + roll2 "," Max(roll1_1, roll1_2) + Max(roll2_1, roll2_2)
				/*
				Loop, % roll_count
				{
					range := Max(roll%A_Index%_1, roll%A_Index%_2) - Min(roll%A_Index%_1, roll%A_Index%_2) + 1
					roll_qual += (roll%A_Index% - Min(roll%A_Index%_1, roll%A_Index%_2) + 1)/range
				}
				roll_qual := Format("{:0.2f}", (roll_qual/roll_count)*100)
				*/
			}
			Else roll_qual := "0," roll "," roll
			affixes.Push(mod ";" tier ";" roll_qual)
		}
	}
	
	If (loop = 0)
	{
		LLK_ToolTip("item is not scalable")
		Return
	}
	
	Gui, itemchecker: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_itemchecker
	Gui, itemchecker: Margin, 0, 0
	Gui, itemchecker: Color, Black
	;WinSet, Transparent, %trans%
	Gui, itemchecker: Font, % "cWhite s"fSize0, Fontin SmallCaps
	loop := A_Index
	;total_quality := 0
	;total_affixes := 0
	
	If InStr(Clipboard, "attacks per second: ")
	{
		Gui, itemchecker: Add, Text, % "Section xs Border w"poe_width/12, % " p-dps: " pdps
		Gui, itemchecker: Add, Text, % "ys Border w"poe_width/12, % " c-dps: " cdps
		Gui, itemchecker: Add, Text, % "Section xs Border w"poe_width/12, % " e-dps: " edps0
		Gui, itemchecker: Add, Text, % "ys Border w"poe_width/12, % " total: " tdps
	}
	
	color := (item_lvl >= 86) ? "Green" : "505050"
	;Gui, itemchecker: Add, Progress, ys hp Border wp range0-100 BackgroundBlack cRed, 80
	If !unique
	{
		Gui, itemchecker: Add, Text, % "xs Hidden Border w"poe_width/12, placeholder
		Gui, itemchecker: Add, Progress, xp yp Border Section hp wp range66-86 BackgroundBlack c%color%, % item_lvl
		Gui, itemchecker: Add, Text, % "yp xp Border BackgroundTrans w"poe_width/12, % " ilvl: " item_lvl
		color := (LLK_SubStrCount(Clipboard, "prefix modifier", "`n") + LLK_SubStrCount(Clipboard, "suffix modifier", "`n") < 6) ? "Green" : "505050"
		Gui, itemchecker: Add, Progress, % "ys wp hp Border BackgroundTrans range0-6 BackgroundBlack c"color, % LLK_SubStrCount(Clipboard, "prefix modifier", "`n") + LLK_SubStrCount(Clipboard, "suffix modifier", "`n")
		Gui, itemchecker: Add, Text, % "yp xp Border BackgroundTrans wp", % itemcheck_affixes
	}
	;Else Gui, itemchecker: Add, Text, % "ys Border BackgroundTrans w"poe_width/12, % " "
	
	Loop, % affixes.Count()
	{
		style := !unique ? "w"poe_width*(18/120) : "w"poe_width*(20/120)
		;MsgBox, % affixes[A_Index]
		
		Loop, Parse, % affixes[A_Index], % ";"
		{
			Switch A_Index
			{
				Case 1:
					mod := A_LoopField
				Case 2:
					tier := A_LoopField
				Case 3:
					quality := A_LoopField
			}
		}
		;total_quality += InStr(mod, "fractured") ? 0 : quality
		;total_affixes += InStr(mod, "fractured") ? 0 : 1
		
		Loop, Parse, quality, `,
		{
			Switch A_Index
			{
				Case 1:
					lower_bound := A_LoopField ;(A_LoopField < 0) ? A_LoopField * 1.01 : A_LoopField * 0.99
				Case 2:
					value := A_LoopField
				Case 3:
					upper_bound := A_LoopField
			}
		}
		
		color := (unique = 0) ? "505050" : "994C00"
		
		If InStr(mod, "fractured")
			Gui, itemchecker: Font, bold, Fontin SmallCaps
		Gui, itemchecker: Add, Text, % "Section xs Border hidden "style, % mod
		If InStr(mod, "fractured")
			Gui, itemchecker: Font, norm, Fontin SmallCaps
		Gui, itemchecker: Add, Progress, % (A_Index = 1) ? "xp yp Section Disabled Border hp wp range" lower_bound "-" upper_bound " BackgroundBlack c"color : "xp yp hp wp Disabled Border range" lower_bound "-" upper_bound " BackgroundBlack c"color, % value
		If InStr(mod, "fractured")
			Gui, itemchecker: Font, bold, Fontin SmallCaps
		
		If !unique
		{
			If (LLK_ItemCheckHighlight(StrReplace(mod, " (fractured)")) = 0)
				color := "White"
			Else color := (LLK_ItemCheckHighlight(StrReplace(mod, " (fractured)")) = 1) ? "Aqua" : "Red"
		}
		Else color := "White"
		
		If !unique
			Gui, itemchecker: Add, Text, Center c%color% vitemchecker_panel%A_Index% gItemchecker %style% Border BackgroundTrans xp yp, % mod ;(StrLen(mod) > 36) ? " " SubStr(mod, 1, 36) " [...] " : " " mod " "
		Else Gui, itemchecker: Add, Text, Center c%color% vitemchecker_panel%A_Index% %style% Border BackgroundTrans xp yp, % mod ;(StrLen(mod) > 36) ? " " SubStr(mod, 1, 36) " [...] " : " " mod " "
		If InStr(mod, "fractured")
			Gui, itemchecker: Font, norm, Fontin SmallCaps
		
		Switch StrReplace(tier, "h")
		{
			Case 0:
				color := "Teal" ;"A6829F"
			Case "u":
				color := "994C00"
			Case 1:
				color := "Lime" ;"8FB98C"
			Case 2:
				color := "Green"
			Case 3:
				color := "Yellow"
			Case 4:
				color := "FF8C00"
			Case 5:
				color := "DC143C"
			Default:
				color := "Maroon" ;"CE8179"
		}
		
		If !unique
		{
			Gui, itemchecker: Add, Progress, % "ys hp w"poe_width*(2/120) " BackgroundBlack Border C"color, 100
			Gui, itemchecker: Add, Text, yp xp Border Center cBlack hp wp BackgroundTrans, % (tier = "u") ? " " : tier
		}
	}
	;Gui, itemchecker: Add, Text, Section xs Border hidden, placeholder
	;Gui, itemchecker: Add, Progress, % "xp yp hp range0-100 " style " BackgroundBlack c00CCCC", % total_quality/total_affixes
	;Gui, itemchecker: Add, Text, Center %style% Border BackgroundTrans xp yp HWNDmain_text, % " average rolls: " Format("{:0.2f}", total_quality/total_affixes) "%"
	Gui, itemchecker: Show, NA x10000 y10000
	WinGetPos,,, width, height, ahk_id %hwnd_itemchecker%
	MouseGetPos, mouseXpos, mouseYpos
	winXpos := (mouseXpos - 15 - width < xScreenOffSet) ? xScreenOffSet : mouseXpos - width - 15
	winYpos := (mouseypos - 15 - height < yScreenOffSet) ? yScreenOffSet : mouseYpos - height - 15
	Gui, itemchecker: Show, % "NA x"winXpos " y"winYpos
	LLK_Overlay("itemchecker", "show")
}

LLK_ItemCheckHighlight(string, mode := 0)
{
	global itemchecker_highlight, itemchecker_blacklist
	itemchecker_highlight_parse := "+-()%"
	Loop, Parse, string
	{
		If (A_Index = 1)
			string := ""
		If !IsNumber(A_LoopField) && !InStr(itemchecker_highlight_parse, A_LoopField)
			string .= A_LoopField
	}
	Loop, Parse, string, %A_Space%, %A_Space%
	{
		If (A_Index = 1)
			string := ""
		string .= (string = "") ? A_LoopField : " " A_LoopField
	}
	If (mode = 0)
	{
		If !InStr(itemchecker_highlight, "|" string "|") && !InStr(itemchecker_blacklist, "|" string "|")
			Return 0
		Else If InStr(itemchecker_highlight, "|" string "|")
			Return 1
		Else If InStr(itemchecker_blacklist, "|" string "|")
			Return -1
	}
	If (mode = 1)
	{
		If InStr(itemchecker_blacklist, "|" string "|")
		{
			LLK_ToolTip("set to neutral first")
			Return -1
		}
		If !InStr(itemchecker_highlight, "|" string "|")
		{
			itemchecker_highlight .= "|" string "|"
			IniWrite, % itemchecker_highlight, ini\item-checker.ini, settings, highlighted mods
			Return 1
		}
		Else
		{
			itemchecker_highlight := StrReplace(itemchecker_highlight, "|" string "|")
			IniWrite, % itemchecker_highlight, ini\item-checker.ini, settings, highlighted mods
			Return 0
		}
	}
	If (mode = 2)
	{
		If InStr(itemchecker_highlight, "|" string "|")
		{
			LLK_ToolTip("set to neutral first")
			Return -1
		}
		If !InStr(itemchecker_blacklist, "|" string "|")
		{
			itemchecker_blacklist .= "|" string "|"
			IniWrite, % itemchecker_blacklist, ini\item-checker.ini, settings, blacklisted mods
			Return 1
		}
		Else
		{
			itemchecker_blacklist := StrReplace(itemchecker_blacklist, "|" string "|")
			IniWrite, % itemchecker_blacklist, ini\item-checker.ini, settings, blacklisted mods
			Return 0
		}
	}
}

LLK_ImageSearch(name := "")
{
	global
	Loop, Parse, imagechecks_list, `,, `,
		%A_Loopfield% := 0
	pHaystack_ImageSearch := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
	If (name = "")
	{
		Loop, Parse, imagechecks_list, `,, `,
		{
			imagesearch_x1 := 0
			imagesearch_y1 := 0
			imagesearch_x2 := 0
			imagesearch_y2 := 0
			If !FileExist("img\Recognition (" poe_height "p)\GUI\" A_Loopfield ".bmp")
				continue
			If (A_Loopfield = "bestiary" || A_Loopfield = "gwennen" || A_Loopfield = "stash" || A_Loopfield = "vendor")
			{
				imagesearch_x2 := poe_width//2
				imagesearch_y2 := poe_height//2
			}
			Else If (A_Loopfield = "betrayal")
			{
				imagesearch_y1 := poe_height//2
				imagesearch_x2 := poe_width//2
			}
			pNeedle_ImageSearch := Gdip_CreateBitmapFromFile("img\Recognition (" poe_height "p)\GUI\" A_Loopfield ".bmp")
			If (Gdip_ImageSearch(pHaystack_ImageSearch, pNeedle_ImageSearch, LIST, imagesearch_x1, imagesearch_y1, imagesearch_x2, imagesearch_y2, imagesearch_variation,, 1, 1) > 0)
			{
				%A_Loopfield% := 1
				Gdip_DisposeImage(pNeedle_ImageSearch)
				break
			}
			Else Gdip_DisposeImage(pNeedle_ImageSearch)
		}
	}
	Else
	{
		imagesearch_x1 := 0
		imagesearch_y1 := 0
		imagesearch_x2 := 0
		imagesearch_y2 := 0
		If (name = "bestiary" || name = "gwennen" || name = "stash" || name = "vendor")
		{
			imagesearch_x2 := poe_width//2
			imagesearch_y2 := poe_height//2
		}
		Else If (name = "betrayal")
		{
			imagesearch_y1 := poe_height//2
			imagesearch_x2 := poe_width//2
		}
		pNeedle_ImageSearch := Gdip_CreateBitmapFromFile("img\Recognition (" poe_height "p)\GUI\" name ".bmp")
		If (Gdip_ImageSearch(pHaystack_ImageSearch, pNeedle_ImageSearch,, imagesearch_x1,imagesearch_y1, imagesearch_x2, imagesearch_y2, imagesearch_variation,, 1, 1) > 0)
		{
			Gdip_DisposeImage(pNeedle_ImageSearch)
			Gdip_DisposeImage(pHaystack_ImageSearch)
			Return 1
		}
		Else
		{
			Gdip_DisposeImage(pNeedle_ImageSearch)
			Gdip_DisposeImage(pHaystack_ImageSearch)
			Return 0
		}
	}
	Gdip_DisposeImage(pHaystack_ImageSearch)
}

LLK_SubStrCount(string, substring, delimiter := "", strict := 0)
{
	count := 0
	Loop, Parse, string, % delimiter, % delimiter
	{
		If (A_Loopfield = "")
			continue
		If (strict = 0) && InStr(A_Loopfield, substring)
			count += 1
		If (strict = 1) && (SubStr(A_Loopfield, 1, StrLen(substring)) = substring)
			count += 1
	}
	Return count
}

LLK_LakePath(entrance)
{
	global
	lake_entrance := entrance
	lake_distances[entrance] := 0 ;set distance to entrance to 0
	Loop 25 ;arbitrary number (needs to repeat often enough to assign a distance to each tile)
	{
		Loop, % lake_tile_pos.Length() ;go through all tiles
		{
			If (A_Index = entrance)
				continue
			LLK_LakeAdjacent(A_Index) ;check surrounding tiles
		}
	}
	Loop, % lake_distances.Length() ;check all distance values and clear them if 0 or tile is a water tile
	{
		If InStr(lake_tile%A_Index%_toggle, "red") || (lake_distances[A_Index] = 0)
			lake_distances[A_Index] := ""
	}
}

LLK_LakeAdjacent(tile)
{
	global
	Loop 4
	{
		lake_parse_adjacent := ""
		lake_parse_adjacent%A_Index% := ""
	}
	Loop, Parse, delve_directions, `,, `, ;up, down, left, right
	{
		If (A_Loopfield = "") || IsNumber(lake_distances[tile]) ;skip if tile already has a distance value
			continue
		If (A_Loopfield = "u") && (SubStr(LLK_LakeGrid(tile), 3, 1) > 1) ;check if 'up' is inside the tablet
		{
			lake_parse_adjacent := tile - SubStr(lake_tiles, 1, 1) ;declare var for the 'up' tile
			If !InStr(lake_tile%lake_parse_adjacent%_toggle, "red") && IsNumber(lake_distances[lake_parse_adjacent]) ;check whether 'up' tile is water and whether it has a distance value
				lake_parse_adjacent1 := lake_distances[lake_parse_adjacent] + 1 ;add 1 to 'up' tile's distance and save it as one of four possible distances
			Else lake_parse_adjacent1 := ""
		}
		If (A_Loopfield = "d") && (SubStr(LLK_LakeGrid(tile), 3, 1) < SubStr(lake_tiles, 2, 1))
		{
			lake_parse_adjacent := tile + SubStr(lake_tiles, 1, 1)
			If !InStr(lake_tile%lake_parse_adjacent%_toggle, "red") && IsNumber(lake_distances[lake_parse_adjacent])
				lake_parse_adjacent2 := lake_distances[lake_parse_adjacent] + 1
			Else lake_parse_adjacent2 := ""
		}
		If (A_Loopfield = "l") && (SubStr(LLK_LakeGrid(tile), 1, 1) > 1)
		{
			lake_parse_adjacent := tile - 1
			If !InStr(lake_tile%lake_parse_adjacent%_toggle, "red") && IsNumber(lake_distances[lake_parse_adjacent])
				lake_parse_adjacent3 := lake_distances[lake_parse_adjacent] + 1
			Else lake_parse_adjacent3 := ""
		}
		If (A_Loopfield = "r") && (SubStr(LLK_LakeGrid(tile), 1, 1) < SubStr(lake_tiles, 1, 1))
		{
			lake_parse_adjacent := tile + 1
			If !InStr(lake_tile%lake_parse_adjacent%_toggle, "red") && IsNumber(lake_distances[lake_parse_adjacent])
				lake_parse_adjacent4 := lake_distances[lake_parse_adjacent] + 1
			Else lake_parse_adjacent4 := ""
		}
	}
	lake_parse_adjacent := lake_parse_adjacent1 "," lake_parse_adjacent2 "," lake_parse_adjacent3 "," lake_parse_adjacent4 ;collect the four possible distances in a string
	Loop, Parse, lake_parse_adjacent, `,, `,
	{
		If (A_Index = 1)
			lake_parse_adjacent_array := []
		If (A_Loopfield != "")
			lake_parse_adjacent_array.Push(A_Loopfield) ;collect valid distances in an array
	}
	/*
	If InStr(lake_tile%tile%_toggle, "red")
	{
		lake_distances[tile] := 0
		GuiControl, lakeboard:, lake_tile%tile%_text1, % lake_distances[tile]
	}
	Else
	*/
	If (lake_parse_adjacent_array.Length() != 0) ;array is not empty
		lake_distances[tile] := Min(lake_parse_adjacent_array*) ;the shortest of four possible distances is the correct distance to the entrance
}

LLK_LakeGrid(tile) ;convert tile number into coordinates
{
	global lake_tiles
	loop := 1
	While (tile > SubStr(lake_tiles, 1, 1))
	{
		tile -= SubStr(lake_tiles, 1, 1)
		loop += 1
	}
	Return tile "," loop
}

LLK_DelveGrid(node)
{
	loop := 1
	While (node > 7)
	{
		node -= 7
		loop += 1
	}
	Return node "," loop
}

LLK_DelveDir(hidden_node, node)
{
	direction := ""
	Loop 2
	{
		parse := ""
		loop := 1
		Loop, Parse, % (A_Index = 1) ? hidden_node : node
		{
			If !IsNumber(A_Loopfield)
				continue
			parse .= A_Loopfield
		}
		While (parse > 7)
		{
			parse -= 7
			loop += 1
		}
		If (A_Index = 1)
		{
			xcoord1 := parse
			ycoord1 := loop
		}
		Else
		{
			xcoord2 := parse
			ycoord2 := loop
		}
	}
	If (ycoord1 = ycoord2)
		direction .= ""
	Else direction .= (ycoord1 < ycoord2) ? "d," : "u,"
	If (xcoord1 = xcoord2)
		direction .= ""
	Else direction .= (xcoord1 < xcoord2) ? "r," : "l,"
	Return direction
}

LLK_InStrCount(string, character, delimiter := "")
{
	count := 0
	Loop, Parse, string, %delimiter%, %delimiter%
	{
		If (A_Loopfield = character)
			count += 1
	}
	Return count
}

LLK_ArrayHasVal(array, value, allresults := 0)
{
	hits := ""
	Loop, % array.Length()
	{
		If (array[A_Index] = value) && (allresults = 0)
			Return %A_Index%
		Else If (array[A_Index] = value) && (allresults = 1)
			hits .= A_Index ","
	}
	If (allresults = 0)
		Return 0
	Else
	{
		hits := (hits = "") ? 0 : hits
		Return hits
	}
}

LLK_Error(ErrorMessage)
{
	global
	MsgBox, % ErrorMessage
	ExitApp
}

LLK_HotstringClip(hotstring, mode := 0)
{
	global
	hotstring := StrReplace(hotstring, ":")
	hotstring := StrReplace(hotstring, "?")
	hotstring := StrReplace(hotstring, ".")
	hotstring := StrReplace(hotstring, "*")
	clipboard := ""
	SendInput, ^{a}^{c}
	If (mode = 1)
		SendInput, {ESC}
	ClipWait, 0.1
	hotstringboard := InStr(clipboard, "@") ? SubStr(clipboard, InStr(clipboard, " ") + 1) : clipboard
	hotstringboard := (SubStr(hotstringboard, 0) = " ") ? SubStr(hotstringboard, 1, -1) : hotstringboard
	If (hotstring = "best")
		GoSub, Bestiary_search
	If (hotstring = "gwen")
		GoSub, Gwennen_search
	If (hotstring = "synd")
		GoSub, Betrayal_search
	If (hotstring = "llk")
	{
		If (hotstringboard = "r")
		{
			Reload
			ExitApp
		}
		GoSub, Settings_menu
	}
	If (hotstring = "lab")
	{
		If (lab_mode != 1)
			GoSub, Lab_info
		Else
		{
			lab_mode := 0
			Gui, lab_layout: Destroy
			Gui, lab_marker: Destroy
			DllCall("DeleteObject", "ptr", hbmLab_source)
			hwnd_lab_layout := ""
			hwnd_lab_marker := ""
		}
	}
	If (hotstring = "wiki")
	{
		hotstringboard := StrReplace(hotstringboard, A_Space, "+")
		hotstringboard := StrReplace(hotstringboard, "'", "%27")
		Run, https://www.poewiki.net/index.php?search=%hotstringboard%
	}
	hotstringboard := ""
}

LLK_Omnikey_ToolTip(text:=0)
{
	global
	If (text = 0)
	{
		Gui, omnikey_tooltip: Destroy
		Return
	}
	If (text = "")
	{
		SoundBeep
		Return
	}
	Gui, omnikey_tooltip: New, -DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_omnikey_tooltip,
	Gui, omnikey_tooltip: Color, Black
	Gui, omnikey_tooltip: Margin, 12, 4
	WinSet, Transparent, %trans%
	Gui, omnikey_tooltip: Font, s%fSize0% cWhite, Fontin SmallCaps
	If InStr(text, "horizons:")
	{
		text := StrReplace(text, "horizons:")
		Gui, omnikey_tooltip: Font, underline
		Gui, omnikey_tooltip: Add, Text, Section BackgroundTrans, % "horizons:"
		Gui, omnikey_tooltip: Font, norm
		Gui, omnikey_tooltip: Add, Text, xs BackgroundTrans, % text
	}
	Else Gui, omnikey_tooltip: Add, Text, BackgroundTrans, % text
	Gui, omnikey_tooltip: Show, Hide AutoSize
	MouseGetPos, mouseXpos, mouseYpos
	WinGetPos, winX, winY, winW, winH
	tooltip_posX := (mouseXpos - winW < xScreenOffSet) ? xScreenOffSet : mouseXpos - winW
	tooltip_posy := (mouseYpos - winH < yScreenOffSet) ? yScreenOffSet : mouseYpos - winH
	Gui, omnikey_tooltip: Show, % "NA AutoSize x"tooltip_posX " y"tooltip_posy
}

LLK_WinExist(hwnd)
{
	global
	Loop, 100
	{
		check := hwnd A_Index
		If WinExist("ahk_id " %hwnd%) || WinExist("ahk_id " %check%)
			Return 1
	}
	Return 0
}

LLK_hwnd(hwnd)
{
	global
	Loop, 100
	{
		check := hwnd A_Index
		If (%hwnd% != "") || (%check% != "")
			Return 1
	}
	Return 0
}

LLK_GearTrackerGUI(mode:=0)
{
	global
	guilist .= InStr(guilist, "gear_tracker_indicator|") ? "" : "gear_tracker_indicator|"
	If (mode = 0)
		Gui, gear_tracker_indicator: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_gear_tracker_indicator
	Else Gui, gear_tracker_indicator: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_gear_tracker_indicator
	Gui, gear_tracker_indicator: Margin, 0, 0
	Gui, gear_tracker_indicator: Color, Black
	If (mode = 0)
		WinSet, Transparent, %leveling_guide_trans%
	Else WinSet, TransColor, Black
	Gui, gear_tracker_indicator: Font, % "cLime s"fSize_leveling_guide, Fontin SmallCaps
	Gui, gear_tracker_indicator: Add, Text, % "BackgroundTrans Center vgear_tracker_upgrades gLeveling_guide_gear", % "    "
	Gui, gear_tracker_indicator: Show, NA x10000 y10000
	WinGetPos,,, width, height, ahk_id %hwnd_gear_tracker_indicator%
	gear_tracker_indicator_xpos_target := (gear_tracker_indicator_xpos + width + 2 > poe_width) ? poe_width - width - 1 : gear_tracker_indicator_xpos ;correct coordinates if panel would end up out of client-bounds
	gear_tracker_indicator_ypos_target := (gear_tracker_indicator_ypos + height + 2 > poe_height) ? poe_height - height - 1 : gear_tracker_indicator_ypos ;correct coordinates if panel would end up out of client-bounds
	If (gear_tracker_indicator_xpos_target + width + 2 >= poe_width - pixel_gamescreen_x1 - 1) && (gear_tracker_indicator_ypos_target <= pixel_gamescreen_y1 + 1) ;protect pixel-check area in case panel gets resized
		gear_tracker_indicator_ypos_target := pixel_gamescreen_y1 + 2
	Gui, gear_tracker_indicator: Show, % "NA x"xScreenOffset + gear_tracker_indicator_xpos_target " y"yScreenoffset + gear_tracker_indicator_ypos_target
	LLK_Overlay("gear_tracker_indicator", "show")
}

LLK_Overlay(gui, toggleshowhide:="toggle", NA:=1)
{
	global
	If (gui="hide")
	{
		Loop, Parse, guilist, |, |
		{
			If (A_Loopfield = "")
				Break
			Gui, %A_LoopField%: Hide
		}
		Return
	}
	If (gui="show")
	{
		Loop, Parse, guilist, |, |
		{
			If (A_Loopfield = "")
				Break
			If (state_%A_LoopField%=1) && (hwnd_%A_LoopField% != "")
				Gui, %A_LoopField%: Show, NA
		}
		Return
	}
	If (toggleshowhide="toggle")
	{
		If !WinExist("ahk_id " hwnd_%gui%) && (hwnd_%gui% != "")
		{
			Gui, %gui%: Show, NA
			state_%gui% := 1
			Return
		}
		If WinExist("ahk_id " hwnd_%gui%)
		{
			Gui, %gui%: Hide
			state_%gui% := 0
			Return
		}
	}
	If (toggleshowhide="show") && (hwnd_%gui% != "")
	{
		If (NA = 1)
			Gui, %gui%: Show, NA
		Else Gui, %gui%: Show
		state_%gui% := 1
	}
	If (toggleshowhide="hide")
	{
		Gui, %gui%: Hide
		state_%gui% := 0
	}
}

LLK_PixelRecalibrate(name) ;needs (re)work in case more pixelchecks get integrated
{
	global
	loopcount := InStr(name, "gamescreen") ? 1 : 2
	Loop %loopcount%
	{
		If InStr(name, "gamescreen")
			PixelGetColor, pixel_%name%_color%A_Index%, % xScreenOffset + poe_width - pixel_%name%_x%A_Index%, % yScreenOffset + pixel_%name%_y%A_Index%, RGB
		Else PixelGetColor, pixel_%name%_color%A_Index%, % xScreenOffset + pixel_%name%_x%A_Index%, % yScreenoffset + pixel_%name%_y%A_Index%, RGB
		IniWrite, % pixel_%name%_color%A_Index%, ini\screen checks (%poe_height%p).ini, %name%, color %A_Index%
	}
}

LLK_PixelSearch(name)
{
	global
	If InStr(name, "gamescreen")
		PixelSearch, OutputVarX, OutputVarY, xScreenOffSet + poe_width - pixel_%name%_x1, yScreenOffSet + pixel_%name%_y1, xScreenOffSet + poe_width - pixel_%name%_x1, yScreenOffSet + pixel_%name%_y1, pixel_%name%_color1, %pixelsearch_variation%, Fast RGB
	Else PixelSearch, OutputVarX, OutputVarY, xScreenOffSet + pixel_%name%_x1, yScreenOffSet + pixel_%name%_y1, xScreenOffSet + pixel_%name%_x1, yScreenOffSet + pixel_%name%_y1, pixel_%name%_color1, %pixelsearch_variation%, Fast RGB
	If (ErrorLevel = 0) && !InStr(name, "gamescreen")
		PixelSearch, OutputVarX, OutputVarY, xScreenOffSet + pixel_%name%_x2, yScreenOffSet + pixel_%name%_y2, xScreenOffSet + pixel_%name%_x2, yScreenOffSet + pixel_%name%_y2, pixel_%name%_color2, %pixelsearch_variation%, Fast RGB
	%name% := (ErrorLevel=0) ? 1 : 0
	value := %name%
	Return value
}

LLK_Rightclick()
{
	global
	click := 2
	SendInput, {LButton}
	KeyWait, RButton
	click := 1
}

LLK_MouseMove()
{
	global
	If (A_TickCount < last_hover + 25) && (last_hover != "") ;only execute function in intervals (script is running full-speed due to batchlines -1)
		Return
	last_hover := A_TickCount
	MouseGetPos,,, hwnd_win_hover, hwnd_control_hover, 2
	If (hwnd_win_hover = hwnd_legion_help)
		Gui, legion_help: Destroy
	
	If (hwnd_win_hover = hwnd_legion_treemap2) && !WinExist("ahk_id " hwnd_legion_treemap) ;magnify passive tree on hover
	{
		LLK_Overlay("legion_treemap", "show")
		SetTimer, Legion_seeds_hover_check, 250
	}
	Else If (hwnd_win_hover != hwnd_legion_treemap) && WinExist("ahk_id " hwnd_legion_treemap)
		LLK_Overlay("legion_treemap", "hide")
	
	If (hwnd_control_hover != last_control_hover) ;only update hover-tooltip when hovered control is different from previous update
	{
		last_control_hover := hwnd_control_hover
		If (hwnd_win_hover = hwnd_legion_window || hwnd_win_hover = hwnd_legion_list)
			GoSub, Legion_seeds_hover
	}
}

LLK_ToolTip(message, duration := 1, x := "", y := "")
{
	global
	mouseYpos := ""
	MouseGetPos,, mouseYpos
	mouseYpos -= fSize0
	If (y = "")
		ToolTip, % message, %x%, %mouseYpos%, 17
	Else ToolTip, % message, %x%, %y%, 17
	SetTimer, ToolTip_clear, % 1000 * duration
}

LLK_ReplaceAreaID(string)
{
	global areas
	Loop, Parse, string, % A_Space, % A_Space
	{
		If !InStr(A_Loopfield, "areaid")
			continue
		areaID := StrReplace(A_Loopfield, "areaid")
		string := StrReplace(string, A_Loopfield, areas[areaID].name,, 1)
	}
	StringLower, string, string
	Return string
}

#include data\External Functions.ahk
#include data\JSON.ahk