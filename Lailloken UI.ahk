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
Else poe_log_file := 0

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
GoSub, Init_leveling_guide
GoSub, Init_map_tracker
GoSub, Init_conversions

SetTimer, Loop, 1000
SetTimer, Log_loop, 1000

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
LLK_GameScreenCheck()
SetTimer, MainLoop, 100
If (update_available = 1)
	ToolTip, % "New version available: " version_online "`nCurrent version:  " version_installed "`nPress TAB to open the release page.`nPress ESC to dismiss this notification.", % xScreenOffSet + poe_width/2*0.9, % yScreenOffSet
Return

#If WinActive("ahk_group poe_window") && (enable_itemchecker_ID = 1) && (shift_down = "wisdom")

+RButton::LLK_ItemCheckVendor()

#If WinActive("ahk_group poe_window") && (enable_itemchecker_ID = 1) && (gamescreen = 0) && (hwnd_win_hover != hwnd_itemchecker)
	
~+RButton::
Clipboard := ""
SendInput, ^{c}
ClipWait, 0.05
If InStr(Clipboard, "scroll of wisdom")
	shift_down := "wisdom"
KeyWait, Shift
shift_down := ""
If WinExist("ahk_id " hwnd_itemchecker)
	LLK_ItemCheckClose()
Return

~+LButton::
Clipboard := ""
sleep, 250
SendInput, ^!{c}
ClipWait, 0.05
If (shift_down = "wisdom")
	LLK_ItemCheck()
Return

#If WinActive("ahk_group poe_window") && (enable_loottracker = 1) && (map_tracker_map != "") && !map_tracker_paused

^+LButton::
^LButton::
MouseGetPos, mouseX
If (map_tracker_map != "") && (mouseX > poe_width//2) && LLK_ImageSearch("stash")
	LLK_MapTrack("add")
Else	SendInput, % GetKeyState("LShift", "P") ? "{LControl Down}{LShift Down}{LButton}{LControl Up}{LShift Up}" : "{LControl Down}{LButton}{LControl Up}"
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

::r.llk::
SendInput, {ESC}
Reload
ExitApp
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
	LLK_ItemCheckClose()
	Return
}
If WinExist("ahk_id " hwnd_itemchecker_vendor1)
{
	Loop
	{
		If (hwnd_itemchecker_vendor%A_Index% != "")
		{
			Gui, itemchecker_vendor%A_Index%: Destroy
			hwnd_itemchecker_vendor%A_Index% := ""
		}
		Else Break
	}
	itemchecker_vendor_count := 0
	Return
}
If WinExist("ahk_id " hwnd_map_tracker_log)
{
	LLK_MapTrackGUI()
	Return
}
If WinExist("ahk_id " hwnd_context_menu)
{
	Gui, context_menu: Destroy
	hwnd_context_menu := ""
	Return
}
If WinExist("ahk_id " hwnd_map_tracker) && (map_tracker_display_loot = 1)
{
	map_tracker_display_loot := 0
	LLK_MapTrack()
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

Apply_settings_general:
Gui, settings_menu: Submit, NoHide
If (A_GuiControl = "custom_resolution_apply")
{
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
}

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
If (map_tracker_map != "")
	LLK_MapTrackSave()
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

If (ini_version < 12808)
{
	itemchecker_highlight := StrReplace(itemchecker_highlight, "added small passive skills also grant: ")
	itemchecker_highlight := StrReplace(itemchecker_highlight, "added Passive Skill is ")
	itemchecker_blacklist := StrReplace(itemchecker_blacklist, "added small passive skills also grant: ")
	itemchecker_blacklist := StrReplace(itemchecker_blacklist, "added Passive Skill is ")
	
	IniWrite, % itemchecker_highlight, ini\item-checker.ini, settings, highlighted mods
	IniWrite, % itemchecker_blacklist, ini\item-checker.ini, settings, blacklisted mods
}
IniWrite, 12808, ini\config.ini, Versions, ini-version ;1.24.1 = 12401, 1.24.10 = 12410, 1.24.1-hotfixX = 12401.X

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
IniRead, enable_map_tracker, ini\config.ini, Features, enable map tracker, 0

IniRead, game_version, ini\config.ini, Versions, game-version, 31800 ;3.17.4 = 31704, 3.17.10 = 31710
IniRead, fSize_offset, ini\config.ini, UI, font-offset, 0
fSize0 := fSize_config0 + fSize_offset
fSize1 := fSize_config1 + fSize_offset
Return

Init_variables:
click := 1
trans := 220
hwnd_win_hover := 0
hwnd_control_hover := 0
blocked_hotkeys := "!,^,+"
pixelchecks_enabled := "gamescreen,"
gamescreen := 0
imagesearch_variation := 25
pixelsearch_variation := 0
stash_search_usecases := "stash,vendor"
Sort, stash_search_usecases, D`,
pixelchecks_list := "gamescreen"
imagechecks_list := "betrayal,bestiary,gwennen,stash,vendor"
guilist := "LLK_panel|notepad_edit|notepad|notepad_sample|settings_menu|alarm|alarm_sample|map_mods_window|map_mods_toggle|betrayal_info|betrayal_info_overview|lab_layout|lab_marker|"
guilist .= "betrayal_search|gwennen_setup|betrayal_info_members|legion_window|legion_list|legion_treemap|legion_treemap2|notepad_drag|itemchecker|map_tracker|map_tracker_log|"
buggy_resolutions := "768,1024,1050"
allowed_recomb_classes := "shield,sword,quiver,bow,claw,dagger,mace,ring,amulet,helmet,glove,boot,belt,wand,staves,axe,sceptre,body,sentinel"
delve_directions := "u,d,l,r,"
gear_tracker_limit := 6
gear_tracker_filter := 1
imagechecks_coords_bestiary := "0,0," poe_width//2 "," poe_height//2
imagechecks_coords_betrayal := "0," poe_height//2 "," poe_width//2 ",0"
imagechecks_coords_gwennen := "0,0," poe_width//2 "," poe_height//2
imagechecks_coords_stash := "0,0," poe_width//2 "," poe_height//2
imagechecks_coords_vendor := "0,0," poe_width//2 "," poe_height//2
global lake_entrance, lake_distances := [], delve_hidden_node, delve_distances := [], loottracker_loot := ""
Loop 20
	hwnd_itemchecker_panel%A_Index% := ""
hwnd_itemchecker_panel_cluster := ""
Return

#Include modules\item-checker.ahk

#Include modules\lab-info.ahk

#Include modules\overlayke.ahk

#Include modules\seed-explorer.ahk

#Include modules\leveling tracker.ahk

Log_loop:
;function quick-jump: LLK_MapTrack(), LLK_MapTrackSave()
If !WinActive("ahk_group poe_ahk_window") || (poe_log_file = 0)
{
	map_entered += 1000
	Return
}
If !map_tracker_paused && (map_tracker_map != "")
{
	If InStr(map_tracker_map, current_location) || ((map_tracker_enable_side_areas = 1) && (InStr(current_location, "abyssleague") || InStr(current_location, "labyrinth_trials") || InStr(current_location, "mapsidearea"))) ;advance map-timer only while in specific map (or side area within it)
		map_tracker_ticks := A_TickCount - map_entered

	If (InStr(map_tracker_map, current_location) || ((map_tracker_enable_side_areas = 1) && (InStr(current_location, "abyssleague") || InStr(current_location, "labyrinth_trials") || InStr(current_location, "mapsidearea")))) && WinExist("ahk_id " hwnd_map_tracker) ;update timer UI
	{
		map_tracker_time := Format("{:0.0f}", map_tracker_ticks//1000)
		map_tracker_time := (Mod(map_tracker_time, 60) >= 10) ? map_tracker_time//60 ":" Mod(map_tracker_time, 60) : map_tracker_time//60 ":0" Mod(map_tracker_time, 60)
		map_tracker_time := (StrLen(map_tracker_time) < 5) ? 0 map_tracker_time : map_tracker_time
		GuiControl, map_tracker: text, map_tracker_label_time, % map_tracker_time
	}
}

If map_tracker_paused
	map_entered += 1000

poe_log_content := poe_log.Read() ;read newest lines from client.txt
StringLower, poe_log_content, poe_log_content
Loop, Parse, poe_log_content, `n, `r ;parse client.txt data
{
	If InStr(A_Loopfield, "generating level")
	{
		portal_modifier := InStr(current_location, "hideout") ? 1 : 0 ;only count portals when entering from hideout, not side-area (lab trial, abyss, etc.)
		
		current_location := SubStr(A_Loopfield, InStr(A_Loopfield, "area """) + 6)
		current_location := SubStr(current_location, 1, InStr(current_location, """") -1) ;save PoE-internal location name in var
		
		current_area_tier := SubStr(A_LoopField, InStr(A_LoopField, "level ") + 6, InStr(A_LoopField, " area """) - InStr(A_LoopField, "level ") - 6) - 67
		current_area_tier := (current_area_tier < 10) ? 0 current_area_tier : current_area_tier ;save map-tier in var
		
		current_seed := SubStr(A_LoopField, InStr(A_LoopField, "seed ") + 5)
		current_seed := StrReplace(current_seed, "`n") ;save map seed in var
		
		If !map_tracker_paused && enable_map_tracker
		{
			date_time := SubStr(A_LoopField, 1, InStr(A_LoopField, " ",,, 2) - 1) ;save date & time from client.txt
			
			If (InStr(current_location, "abyssleague") || InStr(current_location, "labyrinth_trials") || InStr(current_location, "mapsidearea")) && (map_tracker_side_area = "" || map_tracker_side_area != current_location "|" current_area_tier "|" current_seed)
			{
				map_tracker_side_area := current_location "|" current_area_tier "|" current_seed
				map_tracker_verbose_side_area := 0
			}
			
			If LLK_MapTrackInstance(A_LoopField)
			{
				If (map_tracker_map = "") || (map_tracker_map != current_location "|" current_area_tier "|" current_seed) ;current area is the first since launch, or current area is different from previous one
				{
					map_tracker_map := (map_tracker_map = "") ? current_location "|" current_area_tier "|" current_seed : map_tracker_map
					If (map_tracker_map != current_location "|" current_area_tier "|" current_seed) ;current area is different from previous -> reset tracker, and save log for previous map
					{
						LLK_MapTrackSave()
						map_tracker_map := current_location "|" current_area_tier "|" current_seed
					}
					map_tracker_content := "|"
					current_location_verbose := ""
					map_tracker_ticks := 0
					portals := 0
					map_tracker_deaths := 0
					map_entered_date_time := date_time
				}
				portals += portal_modifier ;portal counter
				map_entered := A_TickCount - map_tracker_ticks
			}
		}
	}
	If !map_tracker_paused && enable_map_tracker
	{
		If InStr(A_LoopField, "has been slain") && InStr(map_tracker_map, current_location) && !map_tracker_paused ;count deaths
			map_tracker_deaths += 1
		If InStr(A_LoopField, "you have entered ") && (map_tracker_verbose_side_area = 0)
		{
			map_tracker_verbose_side_area := SubStr(A_LoopField, InStr(A_LoopField, "you have entered ") + 17)
			map_tracker_verbose_side_area := StrReplace(map_tracker_verbose_side_area, ".")
			If InStr(current_location, "abyssleagueboss")
				map_tracker_verbose_side_area .= " (boss)"
			If InStr(current_location, "mapsidearea")
				map_tracker_verbose_side_area .= " (vaal area)"
			map_tracker_content .= map_tracker_verbose_side_area "|"
		}
		If InStr(A_LoopField, "you have entered ") && (current_location_verbose = "") && (map_tracker_map != "") ;parse verbose area name
		{
			current_location_verbose := SubStr(A_LoopField, InStr(A_LoopField, "you have entered ") + 17)
			current_location_verbose := StrReplace(current_location_verbose, ".")
			current_location_verbose := (SubStr(current_location_verbose, 1, 4) = "the ") ? SubStr(current_location_verbose, 5) : current_location_verbose
			current_location_verbose := InStr(map_tracker_map, "heist") ? "heist: " current_location_verbose : current_location_verbose
			current_location_verbose := InStr(map_tracker_map, "expedition") ? "logbook: " current_location_verbose : current_location_verbose
			current_map_tier := current_area_tier
			LLK_MapTrack()
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
If !WinActive("ahk_group poe_ahk_window")
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
If WinActive("ahk_id " hwnd_itemchecker)
	WinActivate, ahk_group poe_window
If WinActive("ahk_group poe_ahk_window") && (poe_window_closed != 1)
{
	If (last_hover <= A_TickCount - 100) && (last_hover != 0) && (mousemove = 0)
	{
		MouseGetPos,,, hwnd_win_hover, hwnd_control_hover, 2
		last_hover := 0
		hwnd_win_hover := (hwnd_win_hover = "") ? 0 : hwnd_win_hover
		hwnd_control_hover := (hwnd_control_hover = "") ? 0 : hwnd_control_hover
	}
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
	If ((clone_frames_enabled != "") && (clone_frames_pixelcheck_enable = 0) && !WinExist("ahk_id " hwnd_map_tracker_log)) || ((clone_frames_enabled != "") && (clone_frames_pixelcheck_enable = 1) && (gamescreen = 1) && !WinExist("ahk_id " hwnd_map_tracker_log))
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

#Include modules\map tracker.ahk

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

LLK_GameScreenCheck()
{
	global
	If (clone_frames_pixelcheck_enable + map_info_pixelcheck_enable = 0)
	{
		pixelchecks_enabled := StrReplace(pixelchecks_enabled, "gamescreen,")
		gamescreen := 0
	}
	Else pixelchecks_enabled := InStr(pixelchecks_enabled, "gamescreen") ? pixelchecks_enabled : pixelchecks_enabled "gamescreen,"
}

LLK_HotstringClip(hotstring, mode := 0)
{
	global
	hotstring := StrReplace(hotstring, ":")
	hotstring := StrReplace(hotstring, "?")
	hotstring := StrReplace(hotstring, ".")
	hotstring := StrReplace(hotstring, "*")
	clipboard := ""
	SendInput, ^{a}
	sleep, 100
	SendInput, ^{c}
	ClipWait, 1

	If (mode = 1)
		SendInput, {ESC}
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

LLK_ItemInfoCheck()
{
	If !InStr(Clipboard, "prefix modifier") && !InStr(Clipboard, "suffix modifier") && !InStr(Clipboard, "unique modifier")
	{
		LLK_ToolTip("failed to copy advanced item-info.`nconfigure the omni-key in the settings menu.", 3)
		Return 0
	}
	Else Return 1
}

LLK_MouseMove()
{
	global
	mousemove := 1
	If (A_TickCount < last_hover + 25) (&& last_hover != "") ;only execute function in intervals (script is running full-speed due to batchlines -1)
		Return
	last_hover := A_TickCount
	MouseGetPos,,, hwnd_win_hover, hwnd_control_hover, 2
	hwnd_win_hover := (hwnd_win_hover = "") ? 0 : hwnd_win_hover
	hwnd_control_hover := (hwnd_control_hover = "") ? 0 : hwnd_control_hover
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
	mousemove := 0
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

LLK_ProgressBar(gui, control_id)
{
	progress := 0
	start := A_TickCount
	While GetKeyState("LButton", "P") || GetKeyState("RButton", "P")
	{
		If (progress >= 700)
			Return 1
		If (A_TickCount >= start + 10)
		{
			progress += 10
			start := A_TickCount
			GuiControl, %gui%:, %control_id%, % progress
		}
	}
	GuiControl, %gui%:, %control_id%, 0
	Return 0
}

LLK_Rightclick()
{
	global
	click := 2
	SendInput, {LButton}
	KeyWait, RButton
	click := 1
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

SetTextAndResize(controlHwnd, newText, fontOptions := "", fontName := "")
{
	Gui 9: New, -DPIscale
	Gui 9: Font, %fontOptions%, %fontName%
	Gui 9: Add, Text, R1, %newText%
	GuiControlGet T, 9: Pos, Static1
	Gui 9: Destroy
	GuiControl,, %controlHwnd%, %newText%
	GuiControl, Move, %controlHwnd%, % "h" TH " w" TW
}

#include data\External Functions.ahk
#include data\JSON.ahk