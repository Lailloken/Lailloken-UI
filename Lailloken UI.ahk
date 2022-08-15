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
GoSub, Init_legion
GoSub, Init_maps
GoSub, Init_notepad
GoSub, Init_omnikey
GoSub, Init_searchstrings
GoSub, Init_conversions
GoSub, Init_leveling_guide

SetTimer, Loop, 1000
If FileExist(poe_log_file)
{
	;If (enable_leveling_guide = 1)
	{
		FileRead, poe_log_content, % poe_log_file
		gear_tracker_characters := []
		Loop
		{
			poe_log_content_short := SubStr(poe_log_content, -0.1*A_Index*StrLen(poe_log_content))
			Loop, Parse, poe_log_content_short, `r`n, `r`n
			{
				If InStr(A_Loopfield, "is now level ")
				{
					parsed_level := SubStr(A_Loopfield, InStr(A_Loopfield, "is now level "))
					parsed_level := StrReplace(parsed_level, "is now level ")
					parsed_character := SubStr(A_Loopfield, InStr(A_Loopfield, " : ") + 3, InStr(A_Loopfield, ")"))
					parsed_character := SubStr(parsed_character, 1, InStr(parsed_character, "(") - 2)
					gear_tracker_characters[parsed_character] := parsed_level
				}
			}
			If (gear_tracker_characters.Count() > 0)
				break
		}
		poe_log_content := ""
		poe_log_content_short := ""
	}
	GoSub, Log_loop
	SetTimer, Log_loop, 2500
}

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
If WinExist("ahk_id " hwnd_gear_tracker)
{
	LLK_GearTrackerGUI(1)
	GoSub, Log_loop
	Gui, gear_tracker: Destroy
	hwnd_gear_tracker := ""
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

#If

Alarm:
start := A_TickCount
While GetKeyState("LButton", "P") && (A_Gui = "alarm_panel")
{
	If (A_TickCount >= start + 300)
	{
		WinGetPos,,, wGui, hGui, % "ahk_id " hwnd_%A_Gui%
		If InStr(A_Gui, "alarm_drag")
			WinGetPos,,, wGui2, hGui2, % "ahk_id " hwnd_alarm
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		If (A_Gui = "alarm_drag")
		{
			LLK_Overlay("alarm", "show")
			LLK_Overlay(A_Gui, "show")
		}
		Else
		{
			alarm_panel_xpos := panelXpos
			alarm_panel_ypos := panelYpos
			IniWrite, % alarm_panel_xpos, ini\alarm.ini, UI, button xcoord
			IniWrite, % alarm_panel_ypos, ini\alarm.ini, UI, button ycoord
		}
		WinActivate, ahk_group poe_window
		Return
	}
}
If (A_Gui = "alarm_drag") && (click = 1)
	Return
alarm_fontcolor := (alarm_fontcolor = "") ? "White" : alarm_fontcolor
fSize_alarm := fSize0 + fSize_offset_alarm
If (alarm_timestamp != "") && (alarm_timestamp < A_Now)
{
	Gui, alarm: Destroy
	hwnd_alarm := ""
	Gui, alarm_drag: Destroy
	hwnd_alarm_drag := ""
	alarm_timestamp := ""
	WinActivate, ahk_group poe_window
	Return
}
If (A_Gui = "settings_menu")
{
	LLK_Overlay("alarm", "hide")
	Gui, alarm_sample: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_alarm_sample, Preview: timer
	Gui, alarm_sample: Margin, 12, 4
	Gui, alarm_sample: Color, Black
	WinSet, Transparent, %alarm_trans%
	Gui, alarm_sample: Font, c%alarm_fontcolor% s%fSize_alarm%, Fontin SmallCaps
	Gui, alarm_sample: Add, Text, BackgroundTrans, % "  00:00  "
	Gui, alarm_sample: Show, Hide AutoSize
	WinGetPos,,, win_width, win_height
	Gui, alarm_sample: Show, % "Hide AutoSize x"xScreenOffSet + poe_width//2 - win_width//2 " y"yScreenOffSet
	LLK_Overlay("alarm_sample", "show", 0)
	Return
}

If (A_GuiControl = "alarm_start") || (continue_alarm = 1)
{
	If (continue_alarm != 1)
	{
		Gui, alarm: Submit, NoHide
		alarm_minutes := (alarm_minutes > 60) ? 60 : alarm_minutes
		alarm_minutes *= 60
		WinGetPos, alarm_xpos, alarm_ypos,,, ahk_id %hwnd_alarm%
		alarm_xpos := (alarm_xpos <= xScreenOffSet) ? 0 : alarm_xpos - xScreenOffSet
		alarm_ypos := (alarm_ypos <= yScreenOffSet) ? 0 : alarm_ypos - yScreenOffSet
		alarm_timestamp := A_Now
		EnvAdd, alarm_timestamp, %alarm_minutes%, S
	}
	Gui, alarm_drag: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_alarm_drag
	Gui, alarm_drag: Margin, 0, 0
	Gui, alarm_drag: Color, Black
	WinSet, Transparent, % alarm_trans
	Gui, alarm_drag: Font, % "s"fSize_alarm//3, Fontin SmallCaps
	Gui, alarm_drag: Add, Text, x0 y0 BackgroundTrans Center valarm_drag gAlarm HWNDhwnd_alarm_dragbutton, % "    "
	ControlGetPos,,, wDrag,,, ahk_id %hwnd_alarm_dragbutton%
	guilist .= InStr(guilist, "alarm_drag|") ? "" : "alarm_drag|"
	
	Gui, alarm: New, -DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_alarm,
	Gui, alarm: Color, Black
	Gui, alarm: Margin, % wDrag + 2, 4
	WinSet, Transparent, %alarm_trans%
	Gui, alarm: Font, s%fSize_alarm% c%alarm_fontcolor%, Fontin SmallCaps
	Gui, alarm: Add, Text, xp BackgroundTrans Center valarm_countdown, XX:XX
	GuiControl, Text, alarm_countdown,
	Gui, alarm: Show, % "NA Autosize"
	WinGetPos,,, width, height, ahk_id %hwnd_alarm%
	Gui, alarm: Show, % "Hide AutoSize x"xScreenOffSet + poe_width/2 - width/2 " y"yScreenOffSet
	Gui, alarm_drag: Show, % "Hide AutoSize x"xScreenOffSet + poe_width/2 - width/2 " y"yScreenOffSet
	LLK_Overlay("alarm", "show")
	LLK_Overlay("alarm_drag", "show")
	WinActivate, ahk_group poe_window
	continue_alarm := 0
	Return
}

If (click = 2) || (hwnd_alarm = "")
{
	If !WinExist("ahk_id " hwnd_alarm) && (click = 2)
	{
		WinActivate, ahk_group poe_window
		Return
	}
	If WinExist("ahk_id " hwnd_alarm) || (hwnd_alarm = "")
	{
		alarm_timestamp := ""
		If (hwnd_alarm != "")
		{
			Gui, alarm_drag: Destroy
			hwnd_alarm_drag := ""
			Gui, alarm: Destroy
			hwnd_alarm := ""
			IniWrite, % "", ini\alarm.ini, Settings, alarm-timestamp
			WinActivate, ahk_group poe_window
			Return
		}
		Gui, alarm: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_alarm, Lailloken UI: alarm-timer
		Gui, alarm: Color, Black
		Gui, alarm: Margin, 12, 4
		WinSet, Transparent, %trans%
		Gui, alarm: Font, s%fSize0% cWhite, Fontin SmallCaps
		Gui, alarm: Add, Text, Section BackgroundTrans Center, set timer to
		Gui, alarm: Font, % "s"fSize0-4
		Gui, alarm: Add, Edit, % "ys hp x+6 cBlack BackgroundTrans Center valarm_minutes Limit2 Number w"fSize0*1.8, 0
		Gui, alarm: Font, s%fSize0%
		Gui, alarm: Add, Text, ys x+6 BackgroundTrans Center, minute(s)
		Gui, alarm: Add, Button, xp hp BackgroundTrans Hidden Default valarm_start gAlarm, OK
		Gui, alarm: Show, % "NA"
		Gui, alarm: Show, % "Hide Center"
		LLK_Overlay("alarm", "show", 0)
		Return
	}
}

If !WinExist("ahk_id " hwnd_alarm)
{
	LLK_Overlay("alarm", "show", 1)
	LLK_Overlay("alarm_drag", "show", 1)
}
Else
{
	LLK_Overlay("alarm", "hide")
	LLK_Overlay("alarm_drag", "hide")
	WinActivate, ahk_group poe_window
}
Return

AlarmGuiClose:
If !WinExist("ahk_group poe_window") || (alarm_timestamp < A_Now)
{
	alarm_timestamp := ""
	hwnd_alarm := ""
}
LLK_Overlay("alarm", "hide")
Return

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

Apply_settings_alarm:
If (A_GuiControl = "enable_alarm")
{
	Gui, settings_menu: Submit, NoHide
	If WinExist("ahk_id " hwnd_alarm_sample) && (enable_alarm = 0)
	{
		Gui, alarm_sample: Destroy
		hwnd_alarm_sample := ""
	}
	If WinExist("ahk_id " hwnd_alarm) && (enable_alarm = 0)
	{
		Gui, alarm: Destroy
		hwnd_alarm := ""
	}
	IniWrite, %enable_alarm%, ini\config.ini, Features, enable alarm
	GoSub, GUI
	GoSub, Settings_menu
	Return
}
If InStr(A_GuiControl, "button_alarm")
{
	If (A_GuiControl = "button_alarm_minus")
		alarm_panel_offset -= (alarm_panel_offset > 0.4) ? 0.1 : 0
	If (A_GuiControl = "button_alarm_reset")
		alarm_panel_offset := 1
	If (A_GuiControl = "button_alarm_plus")
		alarm_panel_offset += (alarm_panel_offset < 1) ? 0.1 : 0
	IniWrite, % alarm_panel_offset, ini\alarm.ini, Settings, button-offset
	alarm_panel_dimensions := poe_width*0.03*alarm_panel_offset
	GoSub, GUI
	Return
}
If (A_GuiControl = "fSize_alarm_minus")
{
	fSize_offset_alarm -= 1
	IniWrite, %fSize_offset_alarm%, ini\alarm.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_alarm_plus")
{
	fSize_offset_alarm += 1
	IniWrite, %fSize_offset_alarm%, ini\alarm.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_alarm_reset")
{
	fSize_offset_alarm := 0
	IniWrite, %fSize_offset_alarm%, ini\alarm.ini, Settings, font-offset
}
If (A_GuiControl = "alarm_opac_minus")
{
	alarm_trans -= (alarm_trans > 100) ? 30 : 0
	IniWrite, %alarm_trans%, ini\alarm.ini, Settings, transparency
}
If (A_GuiControl = "alarm_opac_plus")
{
	alarm_trans += (alarm_trans < 250) ? 30 : 0
	IniWrite, %alarm_trans%, ini\alarm.ini, Settings, transparency
}
If InStr(A_GuiControl, "fontcolor_")
{
	alarm_fontcolor := StrReplace(A_GuiControl, "fontcolor_", "")
	IniWrite, %alarm_fontcolor%, ini\alarm.ini, Settings, font-color
}
GoSub, Alarm
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

Apply_settings_notepad:
If (A_GuiControl = "enable_notepad")
{
	Gui, settings_menu: Submit, NoHide
	
	If (enable_notepad = 0)
	{
		Gui, notepad_sample: Destroy
		hwnd_notepad_sample := ""
		Gui, notepad_edit: Submit, NoHide
		notepad_text := StrReplace(notepad_text, "[", "(")
		notepad_text := StrReplace(notepad_text, "]", ")")
		Gui, notepad_edit: Destroy
		hwnd_notepad_edit := ""
		Gui, notepad: Destroy
		hwnd_notepad := ""
		Loop 100
		{
			Gui, notepad%A_Index%: Destroy
			hwnd_notepad%A_Index% := ""
			Gui, notepad_drag%A_Index%: Destroy
			hwnd_notepad_drag%A_Index% := ""
		}
	}
	IniWrite, %enable_notepad%, ini\config.ini, Features, enable notepad
	GoSub, GUI
	GoSub, Settings_menu
	Return
}
If InStr(A_GuiControl, "button_notepad")
{
	If (A_GuiControl = "button_notepad_minus")
		notepad_panel_offset -= (notepad_panel_offset > 0.4) ? 0.1 : 0
	If (A_GuiControl = "button_notepad_reset")
		notepad_panel_offset := 1
	If (A_GuiControl = "button_notepad_plus")
		notepad_panel_offset += (notepad_panel_offset < 1) ? 0.1 : 0
	IniWrite, % notepad_panel_offset, ini\notepad.ini, Settings, button-offset
	notepad_panel_dimensions := poe_width*0.03*notepad_panel_offset
	GoSub, GUI
	Return
}
If (A_GuiControl = "fSize_notepad_minus")
{
	fSize_offset_notepad -= 1
	IniWrite, %fSize_offset_notepad%, ini\notepad.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_notepad_plus")
{
	fSize_offset_notepad += 1
	IniWrite, %fSize_offset_notepad%, ini\notepad.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_notepad_reset")
{
	fSize_offset_notepad := 0
	IniWrite, %fSize_offset_notepad%, ini\notepad.ini, Settings, font-offset
}
If (A_GuiControl = "notepad_opac_minus")
{
	notepad_trans -= (notepad_trans > 100) ? 30 : 0
	IniWrite, %notepad_trans%, ini\notepad.ini, Settings, transparency
}
If (A_GuiControl = "notepad_opac_plus")
{
	notepad_trans += (notepad_trans < 250) ? 30 : 0
	IniWrite, %notepad_trans%, ini\notepad.ini, Settings, transparency
}
If InStr(A_GuiControl, "fontcolor_")
{
	notepad_fontcolor := StrReplace(A_GuiControl, "fontcolor_", "")
	IniWrite, %notepad_fontcolor%, ini\notepad.ini, Settings, font-color
}
GoSub, Notepad
Return

Apply_settings_omnikey:
Gui, settings_menu: Submit, NoHide
Loop, Parse, blocked_hotkeys, `,, `,
{
	If (SubStr(omnikey_hotkey, 1, 1) = A_Loopfield)
	{
		LLK_ToolTip("Chosen omni-hotkey not supported")
		GuiControl, settings_menu: text, omnikey_hotkey,
		omnikey_hotkey := ""
		IniWrite, %omnikey_hotkey%, ini\config.ini, Settings, omni-hotkey
		KeyWait, Alt
		KeyWait, Control
		KeyWait, Shift
		Return
	}
}
If (A_GuiControl = "omnikey_hotkey") && (omnikey_hotkey != "")
{
	If (omnikey_hotkey_old != omnikey_hotkey) && (omnikey_hotkey_old != "")
	{
		Hotkey, IfWinActive, ahk_group poe_ahk_window
		Hotkey, *~%omnikey_hotkey_old%,, Off
	}
	omnikey_hotkey_old := omnikey_hotkey
	Hotkey, IfWinActive, ahk_group poe_ahk_window
	If (omnikey_conflict_c != 1)
	{
		Hotkey, *~%omnikey_hotkey%, Omnikey, On
		IniWrite, %omnikey_hotkey%, ini\config.ini, Settings, omni-hotkey
	}
	Else
	{
		Hotkey, *~%omnikey_hotkey%, Omnikey2, On
		IniWrite, %omnikey_hotkey%, ini\config.ini, Settings, omni-hotkey
	}
}
Return

Bestiary_search:
If (A_Gui = "")
{
	Gui, bestiary_menu: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_bestiary_menu
	Gui, bestiary_menu: Margin, 4, 2
	Gui, bestiary_menu: Color, Black
	WinSet, Transparent, %trans%
	Gui, bestiary_menu: Font, s%fSize0% cWhite, Fontin SmallCaps
	Gui, bestiary_menu: Add, Text, gBestiary_search BackgroundTrans Center, bleed
	Gui, bestiary_menu: Add, Text, gBestiary_search BackgroundTrans Center, curse
	Gui, bestiary_menu: Add, Text, gBestiary_search BackgroundTrans Center, freeze
	Gui, bestiary_menu: Add, Text, gBestiary_search BackgroundTrans Center, ignite
	Gui, bestiary_menu: Add, Text, gBestiary_search BackgroundTrans Center, poison
	Gui, bestiary_menu: Add, Text, gBestiary_search BackgroundTrans Center, shock
	MouseGetPos, mouseXpos, mouseYpos
	Gui, bestiary_menu: Show, x%mouseXpos% y%mouseYpos%
	Return
}
If (A_GuiControl = "curse")
	clipboard := "warding"
Else If (A_GuiControl = "bleed")
	clipboard := "sealing|lizard"
Else If (A_GuiControl = "shock")
	clipboard := "earthing|conger"
Else If (A_GuiControl = "freeze")
	clipboard := "convection|deer"
Else If (A_GuiControl = "ignite")
	clipboard := "damping|urchin"
Else If (A_GuiControl = "poison")
	clipboard := "antitoxin|skunk"
Else clipboard := ""
WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
SendInput, ^{f}^{v}
Gui, bestiary_menu: Destroy
Return

Betrayal_apply:
Gui, settings_menu: Submit, NoHide
If (A_GuiControl = "image_folder")
{
	Run, explore img\Recognition (%poe_height%p)\Betrayal\
	Return
}
If (A_GuiControl = "betrayal_perma_table")
{
	IniWrite, % %A_GuiControl%, ini\betrayal info.ini, Settings, permanent table
	Return
}
If (A_GuiControl = "betrayal_info_table_pos")
{
	IniWrite, % %A_GuiControl%, ini\betrayal info.ini, Settings, table-position
	GoSub, Betrayal_info
	Return
}
If (A_GuiControl = "betrayal_info_prio_apply")
{
	IniWrite, % betrayal_info_prio_dimensions, ini\betrayal info.ini, Settings, prioview-dimensions
	GoSub, Settings_menu
	Return
}
If (A_GuiControl = "betrayal_info_prio_dimensions")
{
	%A_GuiControl% := (%A_GuiControl% < 100) ? 100 : %A_GuiControl%
	GoSub, GUI_betrayal_prioview
	Return
}
If (A_GuiControl = "fSize_betrayal_minus")
{
	fSize_offset_betrayal -= 1
	betrayal_list_width := ""
	IniWrite, %fSize_offset_betrayal%, ini\betrayal info.ini, Settings, font-offset
	GoSub, Betrayal_info
	Return
}
If (A_GuiControl = "fSize_betrayal_plus")
{
	fSize_offset_betrayal += 1
	betrayal_list_width := ""
	IniWrite, %fSize_offset_betrayal%, ini\betrayal info.ini, Settings, font-offset
	GoSub, Betrayal_info
	Return
}
If (A_GuiControl = "fSize_betrayal_reset")
{
	fSize_offset_betrayal := 0
	betrayal_list_width := ""
	IniWrite, %fSize_offset_betrayal%, ini\betrayal info.ini, Settings, font-offset
	GoSub, Betrayal_info
	Return
}
If (A_GuiControl = "betrayal_opac_minus")
{
	betrayal_trans -= (betrayal_trans > 100) ? 30 : 0
	IniWrite, %betrayal_trans%, ini\betrayal info.ini, Settings, transparency
	GoSub, Betrayal_info
	Return
}
If (A_GuiControl = "betrayal_opac_plus")
{
	betrayal_trans += (betrayal_trans < 250) ? 30 : 0
	IniWrite, %betrayal_trans%, ini\betrayal info.ini, Settings, transparency
	GoSub, Betrayal_info
	Return
}
If (A_GuiControl = "betrayal_enable_recognition")
{
	IniWrite, %betrayal_enable_recognition%, ini\betrayal info.ini, Settings, enable image recognition
	If (%A_GuiControl% = 1)
	{
		Gui, betrayal_info_members: Destroy
		hwnd_betrayal_info_members := ""
	}
	GoSub, Betrayal_info
	Return
}
If (A_GuiControl = "betrayal_ddl")
{
	Gui, betrayal_setup: Submit
	If (betrayal_ddl != "abort screen-cap")
		test := Gdip_SaveBitmapToFile(pBetrayal_screencap, "img\Recognition (" poe_height "p)\Betrayal\" betrayal_ddl ".bmp", 100)
	Gdip_DisposeImage(test)
	Return
}
If InStr(A_GuiControl, "betrayal_info_combo_")
{
	betrayal_clicks := (betrayal_clicks = "") ? 0 : betrayal_clicks
	betrayal_info_click_member := ""
	betrayal_info_click_member2 := ""
	WinGetPos,,, wMembers,, ahk_id %hwnd_betrayal_info_members%
	If InStr(A_GuiControl, parse_member1) && (parse_member1 != "") && (betrayal_clicks != 0)
	{
		LLK_ToolTip("same member selected twice")
		Return
	}
	If InStr(A_GuiControl, parse_division2) && (parse_division2 != "")
	{
		LLK_ToolTip("same division selected twice")
		Return
	}
	If (betrayal_clicks = 0)
	{
		parse_member1 := StrReplace(A_GuiControl, "betrayal_info_combo_")
		parse_division2 := SubStr(parse_member1, InStr(parse_member1, "_") + 1)
		parse_member1 := SubStr(parse_member1, 1, InStr(parse_member1, "_") - 1)
	}
	Else
	{
		parse_member2 := StrReplace(A_GuiControl, "betrayal_info_combo_")
		parse_division1 := SubStr(parse_member2, InStr(parse_member2, "_") + 1)
		parse_member2 := SubStr(parse_member2, 1, InStr(parse_member2, "_") - 1)
	}
	ToolTip, % parse_member1 " moves to " parse_division2, % wMembers + xScreenOffSet,
	betrayal_clicks += 1
	If (betrayal_clicks = 2)
	{
		ToolTip,,,,
		GoSub, Betrayal_search
		betrayal_clicks := 0
		parse_member1 := ""
		parse_member2 := ""
		parse_division1 := ""
		parse_division2 := ""
		betrayal_layout1 := ""
	}
	Return
}
If InStr(A_GuiControl, "betrayal_info_member_")
{
	ToolTip,,,,
	betrayal_clicks := 0
	parse_division1 := ""
	betrayal_info_click_member := StrReplace(A_GuiControl, "betrayal_info_member_")
	betrayal_info_click_member2 := ""
	parse_member2 := ""
	GoSub, Betrayal_search
	Return
}

check := 0
Loop, Parse, betrayal_list, `n, `n
	check += InStr(A_GuiControl, A_Loopfield) ? 1 : 0
If (check = 0)
	Return

parse_member := SubStr(A_GuiControl, InStr(A_GuiControl, "_",,, 3) + 1)
parse_member := SubStr(parse_member, 1, InStr(parse_member, "_",,, 1) - 1)
parse_division := SubStr(A_GuiControl, InStr(A_GuiControl, "_",,, 4) + 1)
parse_gui := SubStr(A_GuiControl, 1, InStr(A_GuiControl, "_",,, 3) - 3)
betrayal_%parse_member%_%parse_division% := (betrayal_%parse_member%_%parse_division% = "") ? 1 : betrayal_%parse_member%_%parse_division%
If (click != 2)
	betrayal_%parse_member%_%parse_division% -= (betrayal_%parse_member%_%parse_division% < 4) ? -1 : 2
Else betrayal_%parse_member%_%parse_division% := (betrayal_%parse_member%_%parse_division% = 1) ? 5 : 1
color := betrayal_color[betrayal_%parse_member%_%parse_division%]
IniWrite, % betrayal_%parse_member%_%parse_division%, ini\betrayal info.ini, %parse_member%, %parse_division%
GuiControl, +c%color%, %A_GuiControl%
WinSet, Redraw,, % "ahk_id " hwnd_%parse_gui%
WinActivate, ahk_group poe_window
Return

Betrayal_info:
If (betrayal_list_width = "")
{
	Gui, betrayal_info_members: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_betrayal_info_members
	Gui, betrayal_info_members: Margin, 0, 0
	Gui, betrayal_info_members: Color, Black
	WinSet, Transparent, %betrayal_trans%
	Gui, betrayal_info_members: Font, % "cWhite s"fSize0 + fSize_offset_betrayal, Fontin SmallCaps
	Gui, betrayal_info_members: Add, Text, BackgroundTrans Center Border HWNDgravicius, % " gravicius "
	Gui, betrayal_info_members: Add, Text, BackgroundTrans Center Border HWNDgravicius_t, % " t"
	Gui, betrayal_info_members: Show, Hide
	ControlGetPos,,, betrayal_list_width, betrayal_list_height,, ahk_id %gravicius%
	ControlGetPos,,, tWidth,,, ahk_id %gravicius_t%
	While (Mod(betrayal_list_width, 4) != 0)
		betrayal_list_width += 1
}

If (betrayal_perma_table = 1) || (betrayal_scan_failed = 1) || (betrayal_enable_recognition = 0) || (Gui_copy != "")
{	
	Gui, betrayal_info_members: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_betrayal_info_members
	Gui, betrayal_info_members: Margin, 0, 0
	Gui, betrayal_info_members: Color, Black
	WinSet, Transparent, %betrayal_trans%
	Gui, betrayal_info_members: Font, % "cWhite s"fSize0 + fSize_offset_betrayal, Fontin SmallCaps
	Loop, Parse, betrayal_divisions, `,, `,
		%A_Loopfield%_t0 := 0
	Loop, Parse, betrayal_list, `n, `n
	{
		color := (A_Loopfield = betrayal_info_click_member) || (A_Loopfield = betrayal_info_click_member2) || (A_Loopfield = parse_member1) || (A_LoopField = parse_member2) ? "Fuchsia" : "White"
		style := (A_Index != 1) ? "y+-1" : ""
		Gui, betrayal_info_members: Add, Text, % "xs " style " Section BackgroundTrans Left Border vbetrayal_info_member_" A_Loopfield " gBetrayal_apply w"betrayal_list_width " c"color, % " " A_Loopfield " "
		check := A_Loopfield
		Loop, Parse, betrayal_divisions, `,, `,
		{
			IniRead, rank, ini\betrayal info.ini, % check, % A_Loopfield, 1
			color := (rank = 1) ? "Black" : betrayal_color[rank]
			Gui, betrayal_info_members: Add, Progress, % "ys x+-1 Disabled Background"color " w"tWidth " hp"
			color := (color = "Black") ? "White" : "Black"
			%A_Loopfield%_t0 += (rank = 5) ? 1 : 0
			If (check = "Vorici")
			{
				Gui, betrayal_info_members: Add, Text, % "Section xp yp wp hp BackgroundTrans vbetrayal_info_combo_" check "_" A_Loopfield " Border gBetrayal_apply Center c"color, % SubStr(A_Loopfield, 1, 1)
				Gui, betrayal_info_members: Add, Text, % "xs y+-1 wp hp BackgroundTrans Border Center cAqua", % %A_Loopfield%_t0
			}
			Else Gui, betrayal_info_members: Add, Text, % "xp yp wp hp BackgroundTrans vbetrayal_info_combo_" check "_" A_Loopfield " Border gBetrayal_apply Center c"color, % SubStr(A_Loopfield, 1, 1)
			Gui, betrayal_info_members: Font, % "s"fSize0 + fSize_offset_betrayal " norm"
		}
	}
	Gui, betrayal_info_members: Show, Hide
	WinGetPos,,, width, height
	If (betrayal_info_table_pos = "left")
		Gui, betrayal_info_members: Show, % "NA x"xScreenOffSet " y"yScreenOffSet + (poe_height - height)/2
	Else Gui, betrayal_info_members: Show, % "NA x"xScreenOffSet + poe_width - width " y"yScreenOffSet + (poe_height - height)/2
	LLK_Overlay("betrayal_info_members", "show")
}

If WinExist("ahk_id " hwnd_betrayal_info_members) && (betrayal_perma_table = 0) && (betrayal_scan_failed = 0) && (betrayal_enable_recognition = 1) && (Gui_copy = "")
	LLK_Overlay("betrayal_info_members", "hide")

Gui, betrayal_info: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_betrayal_info
Gui, betrayal_info: Margin, 0, 0
Gui, betrayal_info: Color, Black
WinSet, Transparent, %betrayal_trans%
Gui, betrayal_info: Font, % "cWhite s"fSize0 + fSize_offset_betrayal, Fontin SmallCaps

Gui, betrayal_info_overview: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_betrayal_info_overview
Gui, betrayal_info_overview: Margin, 0, 0
Gui, betrayal_info_overview: Color, Black
WinSet, Transparent, %betrayal_trans%
Gui, betrayal_info_overview: Font, % "cWhite s"fSize0 + fSize_offset_betrayal, Fontin SmallCaps

Loop, Parse, betrayal_divisions, `,, `,
{
	If (betrayal_layout = 1)
	{
		IniRead, betrayal_%betrayal_member%_%A_Loopfield%, ini\betrayal info.ini, % betrayal_member, % A_Loopfield, 1
		color := betrayal_color[betrayal_%betrayal_member%_%A_Loopfield%]
		If (parse_division1 = A_Loopfield)
		{
			Gui, betrayal_info: Add, Progress, % "ys Disabled Background303030 Center w"poe_width/4 " h"betrayal_list_height*2 - 2
			Gui, betrayal_info: Add, Text, % "xp yp Section BackgroundTrans Center Border vbetrayal_info_" A_Index "_" betrayal_member "_" A_Loopfield " gBetrayal_apply w"poe_width/4 " c"color, % %A_Loopfield%_text
		}
		Else Gui, betrayal_info: Add, Text, % "ys Section BackgroundTrans Center Border vbetrayal_info_" A_Index "_" betrayal_member "_" A_Loopfield " gBetrayal_apply w"poe_width/4 " c"color, % %A_Loopfield%_text
	}
	Else
	{
		ToolTip,,,,
		If (A_Index < 3)
		{
			betrayal_member := parse_member1
			betrayal_division := (A_Index = 1) ? parse_division1 : parse_division2
		}
		Else
		{
			betrayal_member := parse_member2
			betrayal_division := (A_Index = 3) ? parse_division2 : parse_division1
		}
		If (A_Index = 3)
		{
			Loop, Parse, betrayal_divisions, `,, `,
			{
				IniRead, rank, ini\betrayal info.ini, % betrayal_member, % A_LoopField, 1
				Gui, betrayal_info_overview: Add, Progress, % "ys Section w"poe_width//8 " h" betrayal_list_height//3 " disabled background"betrayal_color[rank]
				Gui, betrayal_info_overview: Add, Text, % "hp wp xp yp border BackgroundTrans", % A_Space
			}
		}
		If (A_Index = 1)
		{
			Loop, Parse, betrayal_divisions, `,, `,
			{
				IniRead, rank, ini\betrayal info.ini, % betrayal_member, % A_LoopField, 1
				Gui, betrayal_info_overview: Add, Progress, % "ys Section w"poe_width//8 " h" betrayal_list_height//3 " disabled background"betrayal_color[rank]
				Gui, betrayal_info_overview: Add, Text, % "hp wp xp yp border BackgroundTrans", % A_Space
			}
		}
		IniRead, betrayal_%betrayal_member%_%betrayal_division%, ini\betrayal info.ini, %betrayal_member%, %betrayal_division%, 1
		color := betrayal_color[betrayal_%betrayal_member%_%betrayal_division%]
		Gui, betrayal_info: Add, Text, % "ys Section BackgroundTrans Border Center vbetrayal_info_" A_Index "_" betrayal_member "_" betrayal_division " gBetrayal_apply w"poe_width/4 " c"color, % panel%A_Index%_text
	}
}

Gui, betrayal_info: Show, % "NA y" yScreenOffSet " x" xScreenOffSet
WinGetPos,,,, height, ahk_id %hwnd_betrayal_info%
LLK_Overlay("betrayal_info", "show")

If (betrayal_layout = 2)
{
	Gui, betrayal_info_overview: Show, % "NA x" xScreenOffSet " y"yScreenOffset + height
	LLK_Overlay("betrayal_info_overview", "show")
}
Return

Betrayal_prio_drag:
While GetKeyState("LButton", "P")
{
	MouseGetPos, mouseXpos, mouseYpos
	style := StrReplace(A_GuiControl, "prio_")
	Gui, betrayal_prioview_%style%: Show, NA x%mouseXpos% y%mouseYpos%
}
%style%_xcoord := mouseXpos - xScreenOffSet
%style%_ycoord := mouseYpos - yScreenOffSet
betrayal_info_%A_GuiControl% := %style%_xcoord "," %style%_ycoord
IniWrite, % betrayal_info_%A_GuiControl%, ini\betrayal info.ini, Settings, %style% coords
Return

Betrayal_search:
start := A_TickCount
Gui_copy := A_Gui

While GetKeyState(ThisHotkey_copy, "P")
{
	LLK_Overlay("betrayal_info_members", "hide")
	If (A_TickCount >= start + 200)
	{
		If (betrayal_info_prio_transportation = "0,0") || (betrayal_info_prio_fortification = "0,0") || (betrayal_info_prio_research = "0,0") || (betrayal_info_prio_intervention = "0,0") || (betrayal_info_prio_dimensions = 0)
		{
			LLK_ToolTip("betrayal prio-view not set up", 2)
			KeyWait, % ThisHotkey_copy
			LLK_Overlay("betrayal_info_members", "show")
			Return
		}
		Gui, betrayal_prioview: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_betrayal_prioview
		Gui, betrayal_prioview: Margin, 0, 0
		Gui, betrayal_prioview: Color, Black
		WinSet, TransColor, Black
		Loop, Parse, betrayal_divisions, `,, `,
		{
			check := A_Loopfield
			pics_added := 0
			Loop, Parse, betrayal_list, `n, `n
			{
				IniRead, rank, ini\betrayal info.ini, % A_LoopField, % check, 1
				If (rank = 5)
				{
					If (pics_added = 6)
						break
					If (pics_added = 0)
						Gui, betrayal_prioview: Add, Picture, % "Section BackgroundTrans x" %check%_xcoord - betrayal_info_prio_dimensions/4 " y"%check%_ycoord - betrayal_info_prio_dimensions/2 " w"betrayal_info_prio_dimensions/2 " h-1", img\Betrayal\%A_Loopfield%.png
					Else If (pics_added = 3)
						Gui, betrayal_prioview: Add, Picture, % "Section BackgroundTrans x" %check%_xcoord - betrayal_info_prio_dimensions/4 " y"%check%_ycoord + betrayal_info_prio_dimensions " w"betrayal_info_prio_dimensions/2 " h-1", img\Betrayal\%A_Loopfield%.png
					Else Gui, betrayal_prioview: Add, Picture, % "ys BackgroundTrans  w"betrayal_info_prio_dimensions/2 " h-1", img\Betrayal\%A_Loopfield%.png
					pics_added += 1
				}
			}
		}
		Gui, betrayal_prioview: Show, NA x%xScreenOffSet% y%yScreenOffSet% w%poe_width%
		KeyWait, % ThisHotkey_copy
		LLK_Overlay("betrayal_info_members", "show")
		Gui, betrayal_prioview: Destroy
		Return
	}
	
}

If GetKeyState("LAlt", "P") && (betrayal_enable_recognition = 1)
{
	Clipboard := ""
	SendInput, +#{s}
	Sleep, 1000
	WinWaitActive, ahk_group poe_window
	If (Gdip_CreateBitmapFromClipboard() < 0)
	{
		LLK_ToolTip("screen-cap failed")
		Return
	}
	Else
	{
		pBetrayal_screencap := Gdip_CreateBitmapFromClipboard()
		Gdip_GetImageDimensions(pBetrayal_screencap, wBetrayal_screencap, hBetrayal_screencap)
		hbmBetrayal_screencap := CreateDIBSection(wBetrayal_screencap, hBetrayal_screencap)
		hdcBetrayal_screencap := CreateCompatibleDC()
		obmBetrayal_screencap := SelectObject(hdcBetrayal_screencap, hbmBetrayal_screencap)
		gBetrayal_screencap := Gdip_GraphicsFromHDC(hdcBetrayal_screencap)
		Gdip_SetInterpolationMode(gBetrayal_screencap, 0)
		Gdip_DrawImage(gBetrayal_screencap, pBetrayal_screencap, 0, 0, wBetrayal_screencap, hBetrayal_screencap, 0, 0, wBetrayal_screencap, hBetrayal_screencap, 1)
	}
	Gui, betrayal_setup: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_betrayal_setup, Lailloken UI: Betrayal screen-cap
	Gui, betrayal_setup: Margin, 12, 4
	Gui, betrayal_setup: Color, Black
	WinSet, Transparent, %trans%
	Gui, betrayal_setup: Font, % "s"fSize0 " cWhite", Fontin SmallCaps
	Gui, betrayal_setup: Add, Picture, % "Section BackgroundTrans", HBitmap:*%hbmBetrayal_screencap%
	Gui, betrayal_setup: Add, DDL, ys BackgroundTrans cBlack vBetrayal_ddl Choose1 gBetrayal_apply HWNDmain_text, % "abort screen-cap||transportation|fortification|research|intervention|" StrReplace(betrayal_list, "`n", "|")
	LLK_Overlay("betrayal_setup", "show", 0)
	WinWaitActive, ahk_group poe_window
	SelectObject(hdcBetrayal_screencap, obmBetrayal_screencap)
	DeleteObject(hbmBetrayal_screencap)
	DeleteDC(hdcBetrayal_screencap)
	Gdip_DeleteGraphics(gBetrayal_screencap)
	Gdip_DisposeImage(pBetrayal_screencap)
	DllCall("DeleteObject", "ptr", hbmBetrayal_screencap)
	hbmBetrayal_screencap := ""
	Gui, betrayal_setup: Destroy
	Return
}

If (betrayal_clicks != 2)
{
	If (A_Gui = "betrayal_info_members") && !InStr(A_GuiControl, "combo")
		parse_member1 := betrayal_info_click_member
	Else
	{
		betrayal_member := ""
		If GetKeyState("LShift", "P")
		{
			parse_member2 := (parse_member1 = "") ? "" : parse_member1
			parse_division2 := (parse_member1 = "") ? "" : parse_division1
		}
		Else
		{
			parse_member2 := ""
			parse_division2 := ""
		}
		parse_member1 := ""
		parse_division1 := ""
	}
}

If (A_Gui = "settings_menu")
	parse_member1 := "aisling"

If (A_Gui = "") && (betrayal_enable_recognition = 0)
{
	ToolTip,,,,
	betrayal_member := ""
	parse_member1 := ""
	betrayal_info_click_member := ""
	betrayal_info_click_member2 := ""
	betrayal_shift_clicks := 0
	Loop, Parse, betrayal_divisions, `,, `,
	{
		panel%A_Index%_text := A_Loopfield ":"
		%A_Loopfield%_text := A_Loopfield ":"
	}
	GoSub, Betrayal_info
	Return
}

If (betrayal_enable_recognition = 1) && (A_Gui = "")
{
	If FileExist("img\Recognition (" poe_height "p)\Betrayal\.bmp")
		FileDelete, img\Recognition (%poe_height%p)\Betrayal\.bmp
	pHaystack_betrayal := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
	Loop, Files, img\Recognition (%poe_height%p)\Betrayal\*.bmp
	{
		If InStr(A_LoopFilePath, "transportation") || InStr(A_LoopFilePath, "fortification") || InStr(A_LoopFilePath, "research") || InStr(A_LoopFilePath, "intervention")
			continue
		pNeedle_betrayal := Gdip_CreateBitmapFromFile(A_LoopFilePath)
		pSearch_betrayal := Gdip_ImageSearch(pHaystack_betrayal, pNeedle_betrayal,, 0, 0, poe_width, poe_height, imagesearch_variation,, 1, 1)
		Gdip_DisposeImage(pNeedle_betrayal)
		Gdip_DisposeImage(pSearch_betrayal)
		If (pSearch_betrayal > 0)
		{
			parse_member1 := StrReplace(A_LoopFileName, ".bmp")
			parse_member1 := StrReplace(parse_member1, "1")
			Break
		}
	}
	Gdip_DisposeImage(pHaystack_betrayal)
	If (parse_member1 = parse_member2) && (parse_member1 != "")
		Return
	If (parse_member1 != "")
	{
		pHaystack_betrayal := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
		Loop, Parse, betrayal_divisions, `,, `,
		{
			pNeedle_betrayal := Gdip_CreateBitmapFromFile("img\Recognition (" poe_height "p)\Betrayal\" A_Loopfield ".bmp")
			pSearch_betrayal := Gdip_ImageSearch(pHaystack_betrayal, pNeedle_betrayal,, 0, 0, poe_width, poe_height, imagesearch_variation,, 1, 1)
			Gdip_DisposeImage(pNeedle_betrayal)
			Gdip_DisposeImage(pSearch_betrayal)
			If (pSearch_betrayal > 0)
			{
				parse_division1 := A_Loopfield
				parse_member1 := StrReplace(parse_member1, "1")
				Break
			}
		}
		LLK_ToolTip("match found", 0.5)
		Gdip_DisposeImage(pHaystack_betrayal)
	}
	Else LLK_ToolTip("no match", 0.5)
}

If (parse_member1 = "")
{
	betrayal_info_click_member := ""
	betrayal_info_click_member2 := ""
	betrayal_scan_failed := 1
	betrayal_layout := 1
	parse_member1 := ""
	parse_division1 := ""
	parse_member2 := ""
	parse_division2 := ""
	LLK_Overlay("betrayal_info", "hide")
	LLK_Overlay("betrayal_info_overview", "hide")
	Loop, Parse, betrayal_divisions, `,, `,
	{
		panel%A_Index%_text := A_Loopfield ":"
		%A_Loopfield%_text := A_Loopfield ":"
	}
	GoSub, Betrayal_info
	Return
}
Else betrayal_scan_failed := 0

If ((parse_member1 != "") && (parse_member2 = "")) || (parse_division1 = "") || (parse_division2 = "") || (parse_division1 = parse_division2)
{
	betrayal_layout := 1
	parse_member2 := ""
	parse_division2 := ""
}
Else betrayal_layout := 2

If (betrayal_layout = 1)
{
	betrayal_member := parse_member1
	IniRead, transportation_text, data\Betrayal.ini, %betrayal_member%, transportation
	transportation_text := betrayal_member " transportation:`n" transportation_text
	IniRead, fortification_text, data\Betrayal.ini, %betrayal_member%, fortification
	fortification_text := betrayal_member " fortification:`n" fortification_text
	IniRead, research_text, data\Betrayal.ini, %betrayal_member%, research
	research_text := betrayal_member " research:`n" research_text
	IniRead, intervention_text, data\Betrayal.ini, %betrayal_member%, intervention
	intervention_text := betrayal_member " intervention:`n" intervention_text
	GoSub, Betrayal_info
}
Else
{
	IniRead, panel1_text, data\Betrayal.ini, %parse_member1%, %parse_division1%
	IniRead, panel2_text, data\Betrayal.ini, %parse_member1%, %parse_division2%
	IniRead, panel3_text, data\Betrayal.ini, %parse_member2%, %parse_division2%
	IniRead, panel4_text, data\Betrayal.ini, %parse_member2%, %parse_division1%
	If (panel1_text = "ERROR") || (panel2_text = "ERROR") || (panel3_text = "ERROR") || (panel4_text = "ERROR")
	{
		SoundBeep
		Return
	}
	panel1_text := parse_member1 " " parse_division1 " (current):`n" panel1_text
	panel2_text := parse_member1 " " parse_division2 " (target):`n" panel2_text
	panel3_text := parse_member2 " " parse_division2 " (current):`n" panel3_text
	panel4_text := parse_member2 " " parse_division1 " (target):`n" panel4_text
	GoSub, Betrayal_info
}
Return

Betrayal_searchGuiClose:
LLK_Overlay("betrayal_search", "hide")
Return

Clone_frames_apply:
Gui, Settings_menu: Submit, NoHide
If InStr(A_GuiControl, "pixel")
{
	If (pixel_gamescreen_color1 = "ERROR") || (pixel_gamescreen_color1 = "")
	{
		LLK_ToolTip("pixel-check setup required")
		clone_frames_pixelcheck_enable := 0
		GuiControl, settings_menu: , clone_frames_pixelcheck_enable, 0
		Return
	}
	If (clone_frames_pixelcheck_enable = 0)
		IniWrite, 0, ini\clone frames.ini, Settings, enable pixel-check
	Else IniWrite, 1, ini\clone frames.ini, Settings, enable pixel-check
	GoSub, Screenchecks_gamescreen
	Return
}
clone_frames_enabled := ""
Loop, Parse, clone_frames_list, `n, `n
{
	Gui, clone_frames_%A_Loopfield%: Hide
	If (clone_frame_%A_LoopField%_enable = 1)
		clone_frames_enabled := (clone_frames_enabled = "") ? A_LoopField "," : A_LoopField "," clone_frames_enabled
	Else guilist := StrReplace(guilist, "clone_frames_" A_Loopfield "|")
}
GoSub, GUI_clone_frames
Return

Clone_frames_dimensions:
Gui, clone_frames_menu: Submit, NoHide
GuiControl, clone_frames_menu: Text, clone_frame_new_dimensions, % clone_frame_new_width " x " clone_frame_new_height " pixels"
Gui, clone_frame_preview: New, -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_clone_frame_preview
Gui, clone_frame_preview: Show, NA
Gui, clone_frame_preview_frame: New, -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +Border +OwnDialogs HWNDhwnd_clone_frame_preview_frame
Gui, clone_frame_preview_frame: Color, Black
WinSet, TransColor, Black
If ((clone_frame_new_width > 1) && (clone_frame_new_height > 1))
	Gui, clone_frame_preview_frame: Show, % "NA x"xScreenOffset + clone_frame_new_topleft_x - 1 " y"yScreenOffset + clone_frame_new_topleft_y - 1 " w"clone_frame_new_width " h"clone_frame_new_height
Else Gui, clone_frame_preview_frame: Hide
SetTimer, Clone_frames_preview, 100
Return

Clone_frames_delete:
delete_string := StrReplace(A_GuiControl, "delete_", "")
IniDelete, ini\clone frames.ini, %delete_string%
Gui, clone_frames_%delete_string%: Destroy
guilist := StrReplace(guilist, "clone_frames_" delete_string "|")
new_clone_menu_closed := 1
GoSub, Settings_menu
Return

Clone_frames_new:
Gui, settings_menu: Submit
LLK_Overlay("settings_menu", "hide")
If (clone_frames_edit_mode = 1)
{
	edit_string := StrReplace(A_GuiControl, "edit_", "")
	clone_frames_enabled := StrReplace(clone_frames_enabled, edit_string ",")
	Gui, clone_frames_%edit_string%: Hide
	IniRead, clone_frame_edit_topleft_x, ini\clone frames.ini, %edit_string%, source x-coordinate
	IniRead, clone_frame_edit_topleft_y, ini\clone frames.ini, %edit_string%, source y-coordinate
	IniRead, clone_frame_edit_width, ini\clone frames.ini, %edit_string%, frame-width
	IniRead, clone_frame_edit_height, ini\clone frames.ini, %edit_string%, frame-height
	IniRead, clone_frame_edit_target_x, ini\clone frames.ini, %edit_string%, target x-coordinate
	IniRead, clone_frame_edit_target_y, ini\clone frames.ini, %edit_string%, target y-coordinate
	IniRead, clone_frame_edit_scale_x, ini\clone frames.ini, %edit_string%, scaling x-axis, 100
	IniRead, clone_frame_edit_scale_y, ini\clone frames.ini, %edit_string%, scaling y-axis, 100
	IniRead, clone_frame_edit_opacity, ini\clone frames.ini, %edit_string%, opacity, 5
	clone_frames_edit_mode := 0
}
Else
{
	edit_string := ""
	clone_frame_edit_topleft_x := 0
	clone_frame_edit_topleft_y := 0
	clone_frame_edit_width := 0
	clone_frame_edit_height := 0
	clone_frame_edit_target_x := 0
	clone_frame_edit_target_y := 0
	clone_frame_edit_scale_x := 100
	clone_frame_edit_scale_y := 100
	clone_frame_edit_opacity := 5
}
Gui, clone_frames_menu: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_clone_frames_menu, Lailloken UI: clone-frame configuration
Gui, clone_frames_menu: Color, Black
Gui, clone_frames_menu: Margin, 12, 4
WinSet, Transparent, %trans%
Gui, clone_frames_menu: Font, s%fSize0% cWhite, Fontin SmallCaps

Gui, clone_frames_menu: Add, Text, Section BackgroundTrans HWNDmain_text, % "unique frame name: "
ControlGetPos,,, width,,, ahk_id %main_text%

Gui, clone_frames_menu: Font, % "s"fSize0-4 "norm"
Gui, clone_frames_menu: Add, Edit, % "ys x+0 hp BackgroundTrans cBlack limit lowercase vClone_frame_new_name w"width, % edit_string
Gui, clone_frames_menu: Add, Edit, % "xs Section BackgroundTrans cWhite Number ReadOnly right Limit4 vClone_frame_new_topleft_x gClone_frames_dimensions y+"fSize0*1.2, % xScreenOffSet + poe_width
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-"xScreenOffSet + poe_width, % xScreenOffSet + poe_width
Gui, clone_frames_menu: Add, Edit, % "ys BackgroundTrans cWhite Number ReadOnly right Limit4 gClone_frames_dimensions vClone_frame_new_topleft_y x+"fSize0//3, % yScreenOffSet + poe_height
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-"yScreenOffSet + poe_height, % yScreenOffSet + poe_height
Gui, clone_frames_menu: Font, % "s"fSize0
Gui, clone_frames_menu: Add, Text, ys x+0 BackgroundTrans, % " source top-left corner (f1: snap to cursor)"

Gui, clone_frames_menu: Font, % "s"fSize0-4 "norm"
Gui, clone_frames_menu: Add, Edit, % "xs Section BackgroundTrans cWhite Number ReadOnly Limit4 gClone_frames_dimensions right vClone_frame_new_width", % xScreenOffSet + poe_width
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-"xScreenOffSet + poe_width, 0
Gui, clone_frames_menu: Add, Edit, % "ys hp BackgroundTrans cWhite Number ReadOnly Limit4 gClone_frames_dimensions right vClone_frame_new_height x+"fSize0//3, % yScreenOffSet + poe_height
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-"yScreenOffSet + poe_height, 0
Gui, clone_frames_menu: Font, % "s"fSize0
Gui, clone_frames_menu: Add, Text, % "ys x+0 BackgroundTrans", % " frame width && height (f2: snap to cursor)"

Gui, clone_frames_menu: Font, % "s"fSize0-4 "norm"
Gui, clone_frames_menu: Add, Edit, % "xs Section BackgroundTrans cWhite Number ReadOnly right Limit4 vClone_frame_new_target_x gClone_frames_dimensions", % xScreenOffSet + poe_width
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-"xScreenOffSet + poe_width, % xScreenOffSet + poe_width
Gui, clone_frames_menu: Add, Edit, % "ys BackgroundTrans cWhite Number ReadOnly right Limit4 vClone_frame_new_target_y gClone_frames_dimensions x+"fSize0//3, % yScreenOffSet + poe_height
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-"yScreenOffSet + poe_height, % yScreenOffSet + poe_height
Gui, clone_frames_menu: Font, % "s"fSize0
Gui, clone_frames_menu: Add, Text, % "ys x+0 BackgroundTrans", % " target top-left corner (f3: snap to cursor)"

GuiControl, clone_frames_menu: Text, clone_frame_new_topleft_x, % clone_frame_edit_topleft_x
GuiControl, clone_frames_menu: Text, clone_frame_new_topleft_y, % clone_frame_edit_topleft_y
GuiControl, clone_frames_menu: Text, clone_frame_new_width, % clone_frame_edit_width
GuiControl, clone_frames_menu: Text, clone_frame_new_height, % clone_frame_edit_height
GuiControl, clone_frames_menu: Text, clone_frame_new_target_x, % clone_frame_edit_target_x
GuiControl, clone_frames_menu: Text, clone_frame_new_target_y, % clone_frame_edit_target_y

Gui, clone_frames_menu: Font, % "s"fSize0-4 "norm"
Gui, clone_frames_menu: Add, Edit, % "xs Section BackgroundTrans cBlack Number Limit4 gClone_frames_dimensions right vClone_frame_new_scale_x", 1000
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range10-1000", % clone_frame_edit_scale_x
Gui, clone_frames_menu: Add, Edit, % "ys hp BackgroundTrans cBlack Number Limit4 gClone_frames_dimensions right vClone_frame_new_scale_y x+"fSize0//3, 1000
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range10-1000", % clone_frame_edit_scale_y
Gui, clone_frames_menu: Font, % "s"fSize0
Gui, clone_frames_menu: Add, Text, % "ys x+0 BackgroundTrans", % " x/y-axis scaling (%)"

Gui, clone_frames_menu: Font, % "s"fSize0-4 "norm"
Gui, clone_frames_menu: Add, Edit, % "ys BackgroundTrans cWhite Number ReadOnly Limit3 ReadOnly gClone_frames_dimensions right vClone_frame_new_opacity", 10
Gui, clone_frames_menu: Add, UpDown, % "ys BackgroundTrans cBlack 0x80 gClone_frames_dimensions range0-5", % clone_frame_edit_opacity
Gui, clone_frames_menu: Font, % "s"fSize0
Gui, clone_frames_menu: Add, Text, % "ys x+0 BackgroundTrans", % " opacity (0-5)"

Gui, clone_frames_menu: Add, Text, % "xs BackgroundTrans HWNDmain_text Border vSave_clone_frame gClone_frames_save y+"fSize0*1.2, % " save && close "
Gui, clone_frames_menu: Show, % "Hide"
WinGetPos,,, win_width, win_height
Gui, clone_frames_menu: Show, % "Hide x"xScreenOffSet + poe_width//2 - win_width//2 " y"yScreenOffSet + poe_height//2 - win_height//2
edit_string := ""
LLK_Overlay("clone_frames_menu", "show", 0)
Gui, clone_frames_menu: Submit, NoHide
Return

Clone_frames_menuGuiClose:
SetTimer, Clone_frames_preview, Delete
new_clone_menu_closed := 1
GoSub, Settings_menu
Gui, clone_frame_preview: Destroy
Gui, clone_frame_preview_frame: Destroy
Gui, clone_frames_menu: Destroy
Return

Clone_frames_preview:
pPreview := Gdip_BitmapFromScreen(xScreenOffset + clone_frame_new_topleft_x "|" yScreenOffset + clone_frame_new_topleft_y "|" clone_frame_new_width "|" clone_frame_new_height)
wPreview := clone_frame_new_width
hPreview := clone_frame_new_height
wPreview_dest := clone_frame_new_width * clone_frame_new_scale_x//100
hPreview_dest := clone_frame_new_height * clone_frame_new_scale_y//100
hbmPreview := CreateDIBSection(wPreview_dest, hPreview_dest)
hdcPreview := CreateCompatibleDC()
obmPreview := SelectObject(hdcPreview, hbmPreview)
gPreview := Gdip_GraphicsFromHDC(hdcPreview)
Gdip_SetInterpolationMode(gPreview, 0)
Gdip_DrawImage(gPreview, pPreview, 0, 0, wPreview_dest, hPreview_dest, 0, 0, wPreview, hPreview, 0.2 + 0.16 * clone_frame_new_opacity)
UpdateLayeredWindow(hwnd_clone_frame_preview, hdcPreview, xScreenOffset + clone_frame_new_target_x, yScreenOffset + clone_frame_new_target_y, wPreview_dest, hPreview_dest)
SelectObject(hdcPreview, obmPreview)
DeleteObject(hbmPreview)
DeleteDC(hdcPreview)
Gdip_DeleteGraphics(gPreview)
Gdip_DisposeImage(pPreview)
Return

Clone_frames_preview_list:
MouseGetPos, mouseXpos, mouseYpos
mouseXpos += fSize0
If (click = 2)
{
	Gui, clone_frame_context_menu: New, -Caption +Border +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_clone_frame_context_menu
	Gui, clone_frame_context_menu: Margin, % fSize0//2, fSize0//2
	Gui, clone_frame_context_menu: Color, Black
	WinSet, Transparent, %trans%
	Gui, clone_frame_context_menu: Font, cWhite s%fSize0%, Fontin SmallCaps
	clone_frames_edit_mode := 1
	Gui, clone_frame_context_menu: Add, Text, Section BackgroundTrans vEdit_%A_GuiControl% gClone_frames_new, edit
	Gui, clone_frame_context_menu: Add, Text, % "xs BackgroundTrans vDelete_" A_GuiControl " gClone_frames_delete y+"fSize0//2, delete
	Gui, clone_frame_context_menu: Show, % "AutoSize x"mouseXpos + fSize0 " y"mouseYpos + fSize0
	WinWaitNotActive, ahk_id %hwnd_clone_frame_context_menu%
	clone_frames_edit_mode := 0
	Gui, clone_frame_context_menu: Destroy
	Return
}
Gui, clone_frame_preview_list: New, -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_clone_frame_preview_list
Gui, clone_frame_preview_list: Show, NA
Gui, clone_frame_preview_list_frame: New, -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_clone_frame_preview_list_frame
Gui, clone_frame_preview_list_frame: Color, Red
bmpPreview_list := Gdip_BitmapFromScreen(xScreenOffset + clone_frame_%A_GuiControl%_topleft_x "|" yScreenoffset + clone_frame_%A_GuiControl%_topleft_y "|" clone_frame_%A_GuiControl%_width "|" clone_frame_%A_GuiControl%_height)
Gdip_GetImageDimensions(bmpPreview_list, WidthPreview_list, HeightPreview_list)
hbmPreview_list := CreateDIBSection(WidthPreview_list, HeightPreview_list)
hdcPreview_list := CreateCompatibleDC()
obmPreview_list := SelectObject(hdcPreview_list, hbmPreview_list)
GPreview_list := Gdip_GraphicsFromHDC(hdcPreview_list)
Gdip_SetInterpolationMode(GPreview_list, 0)
Gdip_DrawImage(GPreview_list, bmpPreview_list, 0, 0, WidthPreview_list, HeightPreview_list, 0, 0, WidthPreview_list, HeightPreview_list, 1)
UpdateLayeredWindow(hwnd_clone_frame_Preview_list, hdcPreview_list, mouseXpos, mouseYpos, WidthPreview_list, HeightPreview_list)
Gui, clone_frame_preview_list_frame: Show, % "NA x"mouseXpos - fSize0//6 " y"mouseYpos - fSize0//6 " w"WidthPreview_list + 2*(fSize0//6) " h"HeightPreview_list + 2*(fSize0//6)
Gui, clone_frame_preview_list: Show, NA
KeyWait, LButton
Gui, clone_frame_preview_list: Destroy
Gui, clone_frame_preview_list_frame: Destroy
SelectObject(hdcPreview_list, obmPreview_list)
DeleteObject(hbmPreview_list)
DeleteDC(hdcPreview_list)
Gdip_DeleteGraphics(GPreview_list)
Gdip_DisposeImage(bmpPreview_list)
Return

Clone_frames_save:
Gui, clone_frames_menu: Submit, NoHide
clone_frame_new_name_first_letter := SubStr(clone_frame_new_name, 1, 1)
If (clone_frame_new_name = "")
{
	LLK_ToolTip("enter name")
	Return
}
If (clone_frame_new_name = "settings")
{
	LLK_ToolTip("The selected name is not allowed.`nPlease choose a different name.", 3)
	GuiControl, clone_frames_menu: Text, clone_frame_new_name,
	Return
}
If clone_frame_new_name_first_letter is not alnum
{
	LLK_ToolTip("Unsupported first character in frame-name detected.`nPlease choose a different name.", 3)
	GuiControl, clone_frames_menu: Text, clone_frame_new_name,
	Return
}
If (clone_frame_new_width < 1) || (clone_frame_new_height < 1)
{
	LLK_ToolTip("Incorrect dimensions detected.`nPlease make sure to set the source corners properly.", 3)
	Return
}
clone_frame_new_name_save := ""
Loop, Parse, clone_frame_new_name
{
	If (A_LoopField = A_Space)
		add_character := "_"
	Else If A_LoopField is not alnum
		add_character := "_"
	Else add_character := A_LoopField
	clone_frame_new_name_save := (clone_frame_new_name_save = "") ? add_character : clone_frame_new_name_save add_character
}
IniWrite, %clone_frame_new_topleft_x%, ini\clone frames.ini, %clone_frame_new_name_save%, source x-coordinate
IniWrite, %clone_frame_new_topleft_y%, ini\clone frames.ini, %clone_frame_new_name_save%, source y-coordinate
IniWrite, %clone_frame_new_target_x%, ini\clone frames.ini, %clone_frame_new_name_save%, target x-coordinate
IniWrite, %clone_frame_new_target_y%, ini\clone frames.ini, %clone_frame_new_name_save%, target y-coordinate
IniWrite, %clone_frame_new_width%, ini\clone frames.ini, %clone_frame_new_name_save%, frame-width
IniWrite, %clone_frame_new_height%, ini\clone frames.ini, %clone_frame_new_name_save%, frame-height
IniWrite, %clone_frame_new_scale_x%, ini\clone frames.ini, %clone_frame_new_name_save%, scaling x-axis
IniWrite, %clone_frame_new_scale_y%, ini\clone frames.ini, %clone_frame_new_name_save%, scaling y-axis
IniWrite, %clone_frame_new_opacity%, ini\clone frames.ini, %clone_frame_new_name_save%, opacity
clone_frame_%clone_frame_new_name_save%_topleft_x := clone_frame_new_topleft_x
clone_frame_%clone_frame_new_name_save%_topleft_y := clone_frame_new_topleft_y
clone_frame_%clone_frame_new_name_save%_target_x := clone_frame_new_target_x
clone_frame_%clone_frame_new_name_save%_target_y := clone_frame_new_target_y
clone_frame_%clone_frame_new_name_save%_width := clone_frame_new_width
clone_frame_%clone_frame_new_name_save%_height := clone_frame_new_height
clone_frame_%clone_frame_new_name_save%_scale_x := clone_frame_new_scale_x
clone_frame_%clone_frame_new_name_save%_scale_y := clone_frame_new_scale_y
clone_frame_%clone_frame_new_name_save%_opacity := clone_frame_new_opacity
guilist := InStr(guilist, clone_frame_new_name_save) ? guilist : guilist "clone_frames_" clone_frame_new_name_save "|"
GoSub, Clone_frames_menuGuiClose
Return

Delve:
If InStr(A_GuiControl, "button_delve_")
{
	If (A_GuiControl = "button_delve_minus")
		delve_panel_offset -= (delve_panel_offset > 0.4) ? 0.1 : 0
	If (A_GuiControl = "button_delve_reset")
		delve_panel_offset := 1
	If (A_GuiControl = "button_delve_plus")
		delve_panel_offset += (delve_panel_offset < 1) ? 0.1 : 0
	IniWrite, % delve_panel_offset, ini\delve.ini, Settings, button-offset
	delve_panel_dimensions := poe_width*0.03*delve_panel_offset
	GoSub, GUI
	Return
}
If (A_GuiControl = "delve_enable_recognition")
{
	Gui, settings_menu: Submit, NoHide
	IniWrite, % delve_enable_recognition, ini\delve.ini, Settings, enable image-recognition
	Return
}
If (A_GuiControl = "enable_delve")
{
	Gui, settings_menu: Submit, NoHide
	If (enable_delve = 0)
	{
		LLK_Overlay("delve_panel", "hide")
		Gui, delve_grid: Destroy
		hwnd_delve_grid := ""
	}
	If (enable_delve = 1) && FileExist(poe_log_file) && (enable_delvelog = 1)
	{
		WinActivate, ahk_group poe_window
		GoSub, Log_loop
	}
	If (enable_delve = 1) && !FileExist(poe_log_file)
		LLK_Overlay("delve_panel", "show")
	IniWrite, % enable_delve, ini\config.ini, Features, enable delve
	GoSub, Settings_menu
	Return
}
If (A_GuiControl = "enable_delvelog")
{
	Gui, settings_menu: Submit, NoHide
	If (enable_delvelog = 1) && (enable_delve = 1) && FileExist(poe_log_file)
	{
		WinActivate, ahk_group poe_window
		GoSub, Log_loop
	}
	If (enable_delvelog = 0)
		LLK_Overlay("delve_panel", "show")
	IniWrite, % enable_delvelog, ini\delve.ini, Settings, enable log-scanning
	Return
}

If InStr(A_GuiControl, "delvegrid_")
{
	If (A_GuiControl = "delvegrid_minus")
		delve_gridwidth -= 1
	If (A_GuiControl = "delvegrid_reset")
		delve_gridwidth := Floor(poe_height*0.73/8)
	If (A_GuiControl = "delvegrid_plus")
		delve_gridwidth += 1
	IniWrite, % delve_gridwidth, ini\delve.ini, UI, grid dimensions
}
start := A_TickCount
While GetKeyState("LButton", "P") && (A_Gui = "delve_panel") ;dragging the delve-button
{
	If (A_TickCount >= start + 300)
	{
		WinGetPos,,, wGui, hGui, % "ahk_id " hwnd_%A_Gui%
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		delve_panel_xpos := panelXpos
		delve_panel_ypos := panelYpos
		IniWrite, % delve_panel_xpos, ini\delve.ini, UI, button xcoord
		IniWrite, % delve_panel_ypos, ini\delve.ini, UI, button ycoord
		WinActivate, ahk_group poe_window
		Return
	}
}

If WinExist("ahk_id " hwnd_delve_grid) && (A_Gui != "settings_menu")
{
	LLK_Overlay("delve_grid", "hide")
	LLK_Overlay("delve_grid2", "hide")
}
Else If !WinExist("ahk_id " hwnd_delve_grid) && (hwnd_delve_grid != "") && (A_Gui != "settings_menu")
{
	LLK_Overlay("delve_grid", "show")
	LLK_Overlay("delve_grid2", "show")
}

If (hwnd_delve_grid = "") || (A_Gui = "settings_menu")
{
	Gui, delve_grid: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_delve_grid
	Gui, delve_grid: Margin, 0, 0
	Gui, delve_grid: Color, White
	WinSet, Transparent, 75
	Gui, delve_grid: Font, % "s"fSize1 " cRed", Fontin SmallCaps
	loop := 0
	delve_hidden_nodes := ""
	Loop 49
	{
		delve_node_%A_Index% := ""
		delve_node%A_Index%_toggle := ""
		delve_node_u%A_Index%_toggle := ""
		delve_node_d%A_Index%_toggle := ""
		delve_node_l%A_Index%_toggle := ""
		delve_node_r%A_Index%_toggle := ""
	}

	Loop, 7 ;% (Floor((poe_height*0.73)/(delve_gridwidth)) < 9) ? Floor((poe_height*0.73)/(delve_gridwidth)) : 8
	{
		Loop 7
		{
			loop += 1
			If (A_Index = 1)
				Gui, delve_grid: Add, Text, % "xs Section BackgroundTrans Center HWNDhwnd_delvenode" loop " Border w"delve_gridwidth " h"delve_gridwidth, % (A_Gui = "settings_menu") ? "sample" : ""
			Else Gui, delve_grid: Add, Text, % "ys BackgroundTrans Center HWNDhwnd_delvenode" loop " Border w"delve_gridwidth " h"delve_gridwidth, % (A_Gui = "settings_menu") ? "sample" : ""
			If (A_Gui != "settings_menu")
			{
				ControlGetPos, delve_nodeXpos, delve_nodeYpos,,,, % "ahk_id " hwnd_delvenode%loop%
				wDpad := delve_gridwidth//3
				xDpad := delve_nodeXpos + delve_gridwidth//3 - 1
				yDpad := delve_nodeYpos + delve_gridwidth//3 - 1
				Gui, delve_grid: Add, Picture, % "x"xDpad " y"yDpad " BackgroundTrans Border vdelve_node" loop "  gDelve_calc w"wDpad " h"wDpad, % "img\GUI\square_blank.png"
				Gui, delve_grid: Add, Picture, % "x" delve_nodeXpos + delve_gridwidth/3 " y" delve_nodeYpos " BackgroundTrans vdelve_node_u" loop " gDelve_calc w"wDpad " h"wDpad, % "img\GUI\square_blank.png"
				Gui, delve_grid: Add, Picture, % "x" delve_nodeXpos " y"delve_nodeYpos + delve_gridwidth/3 " BackgroundTrans vdelve_node_l" loop "  gDelve_calc w"wDpad " h"wDpad, % "img\GUI\square_blank.png"
				Gui, delve_grid: Add, Picture, % "x" delve_nodeXpos + delve_gridwidth*2/3 - 1 " y" delve_nodeYpos + delve_gridwidth/3 " BackgroundTrans vdelve_node_r" loop "  gDelve_calc w"wDpad " h"wDpad, % "img\GUI\square_blank.png"
				Gui, delve_grid: Add, Picture, % "x" delve_nodeXpos + delve_gridwidth/3 " y" delve_nodeYpos + delve_gridwidth*2/3 - 1 " BackgroundTrans vdelve_node_d" loop "  gDelve_calc w"wDpad " h"wDpad, % "img\GUI\square_blank.png"
			}
		}
	}
	Gui, delve_grid: Show, % "NA"
	WinGetPos,,, width, height, ahk_id %hwnd_delve_grid%
	Gui, delve_grid: Show, % "NA y"yScreenOffSet + poe_height*0.09 " x"xScreenOffSet + poe_width/2 - width/2
	LLK_Overlay("delve_grid", "show")
	
	Gui, delve_grid2: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_delve_grid2
	Gui, delve_grid2: Margin, 0, 4
	Gui, delve_grid2: Color, Black
	WinSet, Transparent, %trans%
	Gui, delve_grid2: Font, % "s"fSize0 " cWhite", Fontin SmallCaps
	Gui, delve_grid2: Font, % "underline s"fSize_config0 + 2
	If (delve_enable_recognition = 0)
		Gui, delve_grid2: Add, Text, % "Section BackgroundTrans cRed Center w"7 * delve_gridwidth, hidden passage can only lead through empty squares
	Else Gui, delve_grid2: Add, Text, % "Section BackgroundTrans cRed Center w"7 * delve_gridwidth, hidden passage can only start at checkpoints
	Gui, delve_grid2: Font, % "norm s"fSize0
	If (delve_enable_recognition = 1) && (A_Gui != "settings_menu")
	{
		IniRead, delve_pixelcolors, ini\delve calibration.ini, pixelcolors,, % A_Space
		style := (delve_pixelcolors = "") ? "cRed" : "cLime"
		Gui, delve_grid2: Add, Text, % "xs Section BackgroundTrans Center", % " mode: recognition "
		Gui, delve_grid2: Add, Text, % style " ys BackgroundTrans Center", % "(" LLK_InStrCount(delve_pixelcolors, "`n") " pixel values saved) "
		Gui, delve_grid2: Add, Text, % "ys Border vdelve_calibration gDelve_scan BackgroundTrans Center", % " calibrate "
		Gui, delve_grid2: Add, Text, % "ys x+4 Border vdelve_delete gDelve_scan BackgroundTrans Center", % " delete data "
	}
	Gui, delve_grid2: Show, % "NA x"xScreenOffSet + poe_width/2 - width/2 " y"yScreenOffSet + poe_height*0.09 + height - 2
	LLK_Overlay("delve_grid2", "show")
	
	guilist .= InStr(guilist, "delve_grid|") ? "" : "delve_grid|"
	guilist .= InStr(guilist, "delve_grid2|") ? "" : "delve_grid2|"
}
Return

Delve_calc:
If (delve_enable_recognition = 1)
{
	If InStr(A_GuiControl, "delve_node_")
		Return
	If InStr(A_GuiControl, "delve_node") && !InStr(A_GuiControl, "delve_node_") && (click = 1) ;left-clicking a node
	{
		parse := StrReplace(A_GuiControl, "delve_node")
		If (delve_hidden_nodes = "")
		{
			;LLK_ToolTip("mark hidden node first")
			Return
		}
		If !InStr(delve_node%parse%_toggle, "green") ;return if clicked node is not highlighted green
			Return
		Else
		{
			delve_node%parse%_toggle := "img\GUI\square_red_opaque.png"
			GuiControl, delve_grid:, delve_node%parse%, % delve_node%parse%_toggle
			red_nodes .= parse ","
		}
	}
	If InStr(A_GuiControl, "delve_node") && !InStr(A_GuiControl, "delve_node_") && (click = 2) ;right-clicking hidden node
	{
		If (delve_hidden_nodes != "")
		{
			red_nodes := ","
			Loop 49
			{
				If !InStr(delve_node%A_Index%_toggle, "blank") || !InStr(delve_node%A_Index%_toggle, "black") || (delve_node%A_Index% != "") ;remove highlighting
				{
					delve_node%A_Index%_toggle := "img\GUI\square_blank.png"
					GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
				}
			}
			If (StrReplace(A_GuiControl, "delve_node") = delve_hidden_nodes) ;return if old hidden node was un-marked
			{
				delve_hidden_nodes := ""
				Return
			}
			Else delve_hidden_nodes := ""
		}
		check := 0
		Loop 49
		{
			If (delve_node_%A_Index% != "") ;check if grid is blank or not
			{
				check := 1
				break
			}
		}
		If (check = 0) && !InStr(%A_GuiControl%_toggle, "fuchsia") ;display message if grid is blank (hasn't been scanned)
		{
			LLK_ToolTip("scan first")
			Return
		}
		parse := StrReplace(A_GuiControl, "delve_node", "delve_node_")
		If (%parse% != "")
			Return
		GuiControlGet, test, delve_grid:, % A_GuiControl
		%A_GuiControl%_toggle := (%A_GuiControl%_toggle = "") ? test : %A_GuiControl%_toggle
		%A_GuiControl%_toggle := InStr(%A_GuiControl%_toggle, "blank") ? "img\GUI\square_fuchsia_opaque.png" : "img\Gui\square_blank.png"
		GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		delve_hidden_nodes .= StrReplace(A_GuiControl, "delve_node")
		red_nodes := ","
		Loop 49 ;mark impossible nodes red
		{
			check := A_Index
			If (delve_node_%A_Index% = "")
				continue
			If (StrLen(delve_node_%A_Index%) = 8) ;mark four-way nodes red immediately
			{
				delve_node%A_Index%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
				red_nodes .= InStr(red_nodes, "," A_Index ",") ? "" : A_Index ","
				continue
			}
			If (A_Index = delve_hidden_nodes - 7 || A_Index = delve_hidden_nodes + 1 || A_Index = delve_hidden_nodes + 7 || A_Index = delve_hidden_nodes - 1) && (delve_node_%A_Index% != "") ;check if node is adjacent to hidden one
			{
				delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
				red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
				continue
			}
			blocked := 0
			Loop, Parse, % LLK_DelveDir(check, StrReplace(A_GuiControl, "delve_node")) ;check if direction(s) to the hidden node are blocked
			{
				If ((StrLen(delve_node_%check%) < 6) && (delve_node_%check% = "u,d," || delve_node_%check% = "r,l,"))
					break
				parse := 0
				If InStr(delve_node_%check%, A_Loopfield)
					blocked += 1
				Else If (A_LoopField = "u")
					parse := check - 7
				Else If (A_LoopField = "r")
					parse := check + 1
				Else If (A_LoopField = "d")
					parse := check + 7
				Else If (A_LoopField = "l")
					parse := check - 1
				blocked += (delve_node_%parse% != "") ? 1 : 0
				If (blocked >= StrLen(LLK_DelveDir(check, StrReplace(A_GuiControl, "delve_node"))))
				{
					delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
					GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
					red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
					continue 2
				}
			}
			dead_ends := ","
			check2 := check
			success := 0
			Loop ;trace all paths to the hidden node and check if connection is possible
			{
				If (StrLen(LLK_DelveDir(check2, StrReplace(A_GuiControl, "delve_node"))) = 1) ;prevent path from going into the opposite direction
				{
					If (LLK_DelveDir(check2, StrReplace(A_GuiControl, "delve_node")) = "u")
						general_direction := StrReplace(delve_directions, "d,")
					If (LLK_DelveDir(check2, StrReplace(A_GuiControl, "delve_node")) = "r")
						general_direction := StrReplace(delve_directions, "l,")
					If (LLK_DelveDir(check2, StrReplace(A_GuiControl, "delve_node")) = "d")
						general_direction := StrReplace(delve_directions, "u,")
					If (LLK_DelveDir(check2, StrReplace(A_GuiControl, "delve_node")) = "l")
						general_direction := StrReplace(delve_directions, "r,")
				}
				Else general_direction := LLK_DelveDir(check2, StrReplace(A_GuiControl, "delve_node")) ;only let path go towards the hidden node
				If (check2 = delve_hidden_nodes) ;break loop if hidden node has been reached
					break
				Loop, Parse, general_direction, `,, `, ;try to move from square to square without colliding
				{
					If (A_Loopfield = "") ;mark node red if connection to hidden one is impossible
					{
						dead_ends .= check2
						delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
						GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
						red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
						break 2
					}
					If (A_Loopfield = "u")
						parse := check2 - 7
					Else If (A_Loopfield = "r")
						parse := check2 + 1
					Else If (A_Loopfield = "d")
						parse := check2 + 7
					Else If (A_Loopfield = "l")
						parse := check2 - 1
					If InStr(dead_ends, parse)
						continue
					If (delve_node_%parse% != "") ;mark 'occupied' squares as dead ends
					{
						dead_ends .= parse ","
						check2 := check
						break
					}
					Else ;advance to square if empty
					{
						check2 := parse
						break
					}
				}
			}
		}
	}
	threeway_nodes := 0
	twoway_nodes := 0
	oneway_nodes := 0
	Loop 49 ;check all two-way nodes that aren't red
	{
		If (StrLen(delve_node_%A_Index%) = 4) && !InStr(red_nodes, "," A_Index ",") ;mark two-way nodes green
		{
			delve_node%A_Index%_toggle := "img\GUI\square_green_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
			twoway_nodes += 1
		}
	}
	Loop 49 ;check all three-way nodes that aren't red
	{
		If (StrLen(delve_node_%A_Index%) = 6) && !InStr(red_nodes, "," A_Index ",") && (twoway_nodes = 0) ;mark three-way nodes green if there are no two-way nodes
		{
			delve_node%A_Index%_toggle := "img\GUI\square_green_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
			threeway_nodes += 1
		}
		If (StrLen(delve_node_%A_Index%) = 6) && !InStr(red_nodes, "," A_Index ",") && (twoway_nodes != 0) ;mark three-way nodes yellow if there are two-way nodes
		{
			delve_node%A_Index%_toggle := "img\GUI\square_yellow_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
			threeway_nodes += 1
		}
	}
	Loop 49 ;check all one-way nodes that aren't red
	{
		If (StrLen(delve_node_%A_Index%) = 2) && !InStr(red_nodes, "," A_Index ",") && (twoway_nodes = 0) && (threeway_nodes = 0) ;mark one-way nodes green if there are no two-way or three-way nodes
		{
			delve_node%A_Index%_toggle := "img\GUI\square_green_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
			oneway_nodes += 1
		}
		If (StrLen(delve_node_%A_Index%) = 2) && !InStr(red_nodes, "," A_Index ",") && ((twoway_nodes = 0 && threeway_nodes != 0) || (twoway_nodes != 0 && threeway_nodes = 0)) ;mark one-way nodes yellow if there are three-way nodes but no two-way nodes
		{
			delve_node%A_Index%_toggle := "img\GUI\square_yellow_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
			oneway_nodes += 1
		}
		If (StrLen(delve_node_%A_Index%) = 2) && !InStr(red_nodes, "," A_Index ",") && (twoway_nodes != 0) && (threeway_nodes != 0) ;mark one-way nodes red if there are two-way and three-way nodes
		{
			delve_node%A_Index%_toggle := "img\GUI\square_red_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
		}
	}
	solvable := 0
	Loop 49 ;check if current grid is unsolvable
	{
		If InStr(delve_node%A_Index%_toggle, "green")
		{
			solvable := 1
			break
		}
	}
	If (solvable = 0)
		LLK_ToolTip("current grid setup is not solvable.`ncheck for scanning errors.", 2)
	Return
}

If (delve_enable_recognition = 1)
	Return

If InStr(A_GuiControl, "delve_node_") && (click = 1) ;clicking paths
{
	If (delve_hidden_nodes != "")
	{
		LLK_ToolTip("uncheck the hidden node(s) before`nchanging surrounding paths")
		Return
	}
	parse := A_GuiControl
	While !IsNumber(SubStr(parse, 1, 1))
		parse := SubStr(parse, 2)
	If (parse = delve_hidden_nodes)
		Return
	
	GuiControlGet, test, delve_grid:, % A_GuiControl
	%A_GuiControl%_toggle := (%A_GuiControl%_toggle = "") ? test : %A_GuiControl%_toggle
	%A_GuiControl%_toggle := InStr(%A_GuiControl%_toggle, "blank") ? "img\GUI\square_black_opaque.png" : "img\GUI\square_blank.png"
	GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
	
	delve_node_%parse% := InStr(delve_node_%parse%, SubStr(StrReplace(A_GuiControl, "delve_node_"), 1, 1) ",") ? StrReplace(delve_node_%parse%, SubStr(StrReplace(A_GuiControl, "delve_node_"), 1, 1) ",") : delve_node_%parse% SubStr(StrReplace(A_GuiControl, "delve_node_"), 1, 1) ","
	If (delve_node_%parse% != "")
		GuiControl, delve_grid:, delve_node%parse%, % "img\GUI\square_black_opaque.png"
	Else GuiControl, delve_grid:, delve_node%parse%, % "img\GUI\square_blank.png"
	Return
}

If InStr(A_GuiControl, "delve_node") && !InStr(A_GuiControl, "delve_node_") && (delve_hidden_nodes != "") && (click = 1) ;override green highlighting
{
	If InStr(%A_GuiControl%_toggle, "green")
	{
		%A_GuiControl%_toggle := "img\GUI\square_red_opaque.png"
		GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		red_nodes .= StrReplace(A_GuiControl, "delve_node") ","
		parse := StrReplace(A_GuiControl, "delve_node")
		;If (StrLen(delve_node_%parse%) = 4)
		;	twoway_nodes -= 1
		;If (StrLen(delve_node_%parse%) = 6)
		;	threeway_nodes -= 1
	}
	Else Return
}

If InStr(A_GuiControl, "delve_node") && !InStr(A_GuiControl, "delve_node_") && (click = 1) && (delve_hidden_nodes = "") ;QoL: toggle between four and zero connections when left-clicking nodes
{
	If (delve_hidden_nodes != "")
	{
		LLK_ToolTip("uncheck the hidden node(s) before`nchanging surrounding paths")
		Return
	}
	If (%A_GuiControl%_toggle = "") || InStr(%A_GuiControl%_toggle, "blank")
	{
		parse := StrReplace(A_GuiControl, "delve_node", "delve_node_")
		%parse% := "u,d,l,r,"
		%A_GuiControl%_toggle := "img\GUI\square_black_opaque.png"
		GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		Loop, parse, delve_directions, `,, `,
		{
			If (A_Loopfield = "")
				break
			parse := StrReplace(A_GuiControl, "delve_node", "delve_node_" A_Loopfield)
			%parse%_toggle := "img\GUI\square_black_opaque.png"
			GuiControl, delve_grid:, % parse, % %parse%_toggle
		}
	}
	Else
	{
		parse := StrReplace(A_GuiControl, "delve_node", "delve_node_")
		%parse% := ""
		%A_GuiControl%_toggle := "img\GUI\square_blank.png"
		GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		Loop, parse, delve_directions, `,, `,
		{
			If (A_Loopfield = "")
				break
			parse := StrReplace(A_GuiControl, "delve_node", "delve_node_" A_Loopfield)
			%parse%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, % parse, % %parse%_toggle
		}
	}
	Return
}

If InStr(A_GuiControl, "delve_node") && !InStr(A_GuiControl, "delve_node_") ;right-clicking nodes
{
	If (click = 2)
	{
		check := 0
		Loop 49
		{
			If (delve_node_%A_Index% != "")
			{
				check := 1
				break
			}
		}
		If (check = 0) && !InStr(%A_GuiControl%_toggle, "fuchsia")
		{
			LLK_ToolTip("mark surrounding nodes first")
			Return
		}
		parse := StrReplace(A_GuiControl, "delve_node", "delve_node_")
		If (%parse% != "")
			Return
		If (delve_hidden_nodes != "")
		{
			delve_node%delve_hidden_nodes%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node%delve_hidden_nodes%, % delve_node%delve_hidden_nodes%_toggle
		}
		/*
		Else
		{
			%A_GuiControl%_toggle := (InStr(%A_GuiControl%_toggle, "blank") || (%A_GuiControl%_toggle = "")) ? "img\GUI\square_fuchsia_opaque.png" : "img\Gui\square_blank.png"
			GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		}
		*/
		/*
		If (delve_hidden_nodes = StrReplace(A_GuiControl, "delve_node"))
		{
			%A_GuiControl%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		}
		Else
		{
			GuiControlGet, test, delve_grid:, % A_GuiControl
			%A_GuiControl%_toggle := (%A_GuiControl%_toggle = "") ? test : %A_GuiControl%_toggle
			%A_GuiControl%_toggle := InStr(%A_GuiControl%_toggle, "blank") ? "img\GUI\square_fuchsia_opaque.png" : "img\Gui\square_blank.png"
			GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
		}
		*/
		If (delve_hidden_nodes = StrReplace(A_GuiControl, "delve_node"))
			delve_hidden_nodes := ""
		Else
		{
			%A_GuiControl%_toggle := (InStr(%A_GuiControl%_toggle, "blank") || (%A_GuiControl%_toggle = "")) ? "img\GUI\square_fuchsia_opaque.png" : "img\Gui\square_blank.png"
			GuiControl, delve_grid:, % A_GuiControl, % %A_GuiControl%_toggle
			delve_hidden_nodes := StrReplace(A_GuiControl, "delve_node")
		}
		
		
		If (delve_hidden_nodes = "") ;reset all node markings if no hidden node is marked
		{
			Loop 49
			{
				If InStr(delve_node%A_Index%_toggle, "red") || InStr(delve_node%A_Index%_toggle, "yellow") || InStr(delve_node%A_Index%_toggle, "green")
				{
					delve_node%A_Index%_toggle := "img\GUI\square_black_opaque.png"
					GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
				}
			}
			Return
		}
		red_nodes := ","
	}
	twoway_nodes := 0
	threeway_nodes := 0
	
	Loop 49 ;immediately mark nodes with four connections red
	{
		If (StrLen(delve_node_%A_Index%) = 8)
		{
			delve_node%A_Index%_toggle := "img\GUI\square_red_opaque.png"
			GuiControl, delve_grid:, delve_node%A_Index%, % delve_node%A_Index%_toggle
			red_nodes .= InStr(red_nodes, "," A_Index ",") ? "" : A_Index ","
		}
	}
	
	Loop 49 ;check nodes with two connections first as they are most likely to have the hidden passage
	{
		check := A_Index
		If (StrLen(delve_node_%A_Index%) = 4) && !InStr(red_nodes, "," A_Index ",")
		{
			twoway_nodes += 1
			If !InStr(red_nodes, "," check ",") && ((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) ;check for adjacency to hidden node
			{
				delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
				red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
				twoway_nodes -= 1
			}
			Else If !InStr(red_nodes, "," check ",") && !((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) ;check for adjacency to hidden node
			{
				delve_node%check%_toggle := "img\GUI\square_green_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
			}
			blocked_directions := 0
			If (StrLen(LLK_DelveDir(A_Index, delve_hidden_nodes)) = 4)
			{
				Loop, Parse, % LLK_DelveDir(A_Index, delve_hidden_nodes), `,, `, ;check if hidden node is in unreachable direction
				{
					If (A_Loopfield = "")
						break
					If InStr(delve_node_%check%, A_Loopfield)
						blocked_directions += 1
				}
					
				If (StrLen(LLK_DelveDir(A_Index, delve_hidden_nodes))/2 = blocked_directions) ;mark red if unreachable
				{
					delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
					GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
					red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
					threeway_nodes -= 1
				}
			}
		}
	}
	
	Loop 49 ;check nodes with three connections
	{
		check := A_Index
		blocked := 0
		If (StrLen(delve_node_%A_Index%) = 6) && !InStr(red_nodes, "," A_Index ",")
		{
			threeway_nodes += 1
			Loop, Parse, delve_directions, `,, `, ;check if open passage is blocked by something else
			{
				If (A_Loopfield = "")
					break
				If InStr(delve_node_%check%, A_Loopfield)
					continue
				If (A_LoopField = "u")
					parse := check - 7
				If (A_LoopField = "d")
					parse := check + 7
				If (A_LoopField = "l")
					parse := check - 1
				If (A_LoopField = "r")
					parse := check + 1
				If (delve_node_%parse% != "")
					blocked := 1
				If (blocked = 1) ;mark red if blocked
				{
					delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
					GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
					red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
					threeway_nodes -= 1
					break
				}
			}
			
			blocked_directions := 0
			If (StrLen(LLK_DelveDir(A_Index, delve_hidden_nodes)) = 4)
			{
				Loop, Parse, % LLK_DelveDir(A_Index, delve_hidden_nodes), `,, `, ;check if hidden node is in unreachable direction
				{
					If (A_Loopfield = "")
						break
					If InStr(delve_node_%check%, A_Loopfield)
						blocked_directions += 1
				}
					
				If (StrLen(LLK_DelveDir(A_Index, delve_hidden_nodes))/2 = blocked_directions) ;mark red if unreachable
				{
					delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
					GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
					red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
					threeway_nodes -= 1
				}
			}
			Else
			{
				If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "u,") && !InStr(delve_node_%check%, "d") ;check if hidden node is opposite the only open passage
					blocked_directions := 1
				If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "d,") && !InStr(delve_node_%check%, "u")
					blocked_directions := 1
				If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "l,") && !InStr(delve_node_%check%, "r")
					blocked_directions := 1
				If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "r,") && !InStr(delve_node_%check%, "l")
					blocked_directions := 1
				If (blocked_directions = 1) ;mark red if opposite
				{
					delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
					GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
					red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
					threeway_nodes -= 1
				}
			}
			
			If !InStr(red_nodes, "," check ",") && ((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) ;check for adjacency to hidden node, and mark red
			{
				delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
				red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
				threeway_nodes -= 1
			}
			Else If !InStr(red_nodes, "," check ",") && !((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) && (twoway_nodes = 0) ;mark node green in case no two-way node exists
			{
				delve_node%check%_toggle := "img\GUI\square_green_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
			}
			Else If !InStr(red_nodes, "," check ",") && !((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) && (twoway_nodes != 0) ;mark node yellow in case two-way node(s) exist(s)
			{
				delve_node%check%_toggle := "img\GUI\square_yellow_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
			}
		}
	}
	
	Loop 49 ;check nodes with one connection
	{
		check := A_Index
		If (StrLen(delve_node_%A_Index%) = 2) && !InStr(red_nodes, "," A_Index ",")
		{
			blocked_directions := 0
			If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "u,") && !InStr(delve_node_%check%, "d") ;check if hidden node is opposite the only open passage
				blocked_directions := 1
			If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "d,") && !InStr(delve_node_%check%, "u")
				blocked_directions := 1
			If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "l,") && !InStr(delve_node_%check%, "r")
				blocked_directions := 1
			If (LLK_DelveDir(A_Index, delve_hidden_nodes) = "r,") && !InStr(delve_node_%check%, "l")
				blocked_directions := 1
			If (blocked_directions = 1) ;mark red if opposite
			{
				delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
				red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
			}
			If !InStr(red_nodes, "," check ",") && ((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) ;check for adjacency to hidden node, and mark red if there are two-/three-way nodes
			{
				delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
				red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
			}
			Else If (twoway_nodes != 0 && threeway_nodes != 0)
			{
				delve_node%check%_toggle := "img\GUI\square_red_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
				;red_nodes .= InStr(red_nodes, "," check ",") ? "" : check ","
			}
			Else If !InStr(red_nodes, "," check ",") && !((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) && (twoway_nodes = 0) && (threeway_nodes = 0) ;mark node green if it's possible it branches into two hidden paths
			{
				delve_node%check%_toggle := "img\GUI\square_green_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
			}
			Else If !InStr(red_nodes, "," check ",") && !((check = delve_hidden_nodes - 1) || (check = delve_hidden_nodes - 7) || (check = delve_hidden_nodes + 1) || (check = delve_hidden_nodes + 7)) ;&& ((twoway_nodes != 0) || (threeway_nodes != 0))
			{
				delve_node%check%_toggle := "img\GUI\square_yellow_opaque.png"
				GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
			}
		}
	}
}
Return

Delve_scan:
If (A_GuiControl = "delve_delete")
{
	IniDelete, ini\delve calibration.ini, pixelcolors
	Gui, delve_grid: Destroy
	hwnd_delve_grid := ""
	Gui, delve_grid2: Destroy
	hwnd_delve_grid2 := ""
	GoSub, Delve
	Return
}
If (A_GuiControl = "delve_calibration")
{
	clipboard := ""
	SetTimer, MainLoop, Off
	sleep, 500
	LLK_Overlay("hide")
	KeyWait, LButton
	SendInput, #+{s}
	Sleep, 2000
	WinWaitActive, ahk_group poe_window
	SetTimer, MainLoop, On
	LLK_Overlay("show")
	If (Gdip_CreateBitmapFromClipboard() < 0)
	{
		LLK_ToolTip("screen-cap failed")
		Return
	}
	Else
	{
		ToolTip, calibrating...,,, 17
		delve_pixelcolors2 := ""
		IniRead, delve_pixelcolors, ini\delve calibration.ini, pixelcolors,, % A_Space
		delve_pixelcolors .= (delve_pixelcolors != "") ? "`n" : ""
		pDelve_section := Gdip_CreateBitmapFromClipboard()
		Loop, % Gdip_GetImageHeight(pDelve_section)
		{
			check := A_Index - 1
			Loop, % Gdip_GetImageWidth(pDelve_section)
				delve_pixelcolors2 .= Gdip_GetPixelColor(pDelve_section, A_Index - 1, check, 3) "`n"
		}
		Gdip_DisposeImage(pDelve_section)
		Loop, Parse, delve_pixelcolors2, `n, `n
			delve_pixelcolors .= !InStr(delve_pixelcolors, A_Loopfield) && (LLK_InStrCount(delve_pixelcolors2, A_Loopfield, "`n") >= 2) ? A_Loopfield "`n" : ""
		delve_pixelcolors := (SubStr(delve_pixelcolors, 0, 1) = "`n") ? SubStr(delve_pixelcolors, 1, -1) : delve_pixelcolors
		IniDelete, ini\delve calibration.ini, pixelcolors
		IniWrite, % delve_pixelcolors, ini\delve calibration.ini, pixelcolors
		delve_pixelcolors := ""
		delve_pixelcolors2 := ""
		LLK_ToolTip("calibration finished")
		Gui, delve_grid: Destroy
		hwnd_delve_grid := ""
		Gui, delve_grid2: Destroy
		hwnd_delve_grid2 := ""
		GoSub, Delve
	}
	Return
}
Else
{
	WinGetPos, xzero0, yzero0,,, ahk_id %hwnd_delve_grid%
	IniRead, delve_pixelcolors, ini\delve calibration.ini, pixelcolors
	If (delve_pixelcolors = "")
	{
		LLK_ToolTip("no calibration data")
		Return
	}
	xzero0 -= xScreenOffSet
	yzero0 -= yScreenOffSet
	pDelve := Gdip_BitmapFromHWND(hwnd_poe_client, 1)
	Loop 49
	{
		check := A_Index
		xgrid := SubStr(LLK_DelveGrid(A_Index), 1, 1)
		ygrid := SubStr(LLK_DelveGrid(A_Index), 3, 1)
		xzero := xzero0 + 1 + (xgrid - 1) * delve_gridwidth
		yzero := yzero0 + 1 + (ygrid - 1) * delve_gridwidth
		hits := 0
		delve_hidden_nodes := ""
		delve_node_%check% := ""
		delve_node%check%_toggle := "img\GUI\square_blank.png"
		GuiControl, delve_grid:, delve_node%check%, % delve_node%check%_toggle
		Loop, % delve_gridwidth ;scan top edge of square
		{
			pixelcolor := Gdip_GetPixelColor(pDelve, xzero + A_Index - 1, yzero, 3)
			If InStr(delve_pixelcolors, pixelcolor)
				hits := 1
			If (hits = 1)
			{
				delve_node_%check% .= "u,"
				delve_node_u%check%_toggle := "img\GUI\square_black_opaque.png"
				GuiControl, delve_grid:, delve_node_u%check%, % delve_node_u%check%_toggle
				break
			}
		}
		If ((hits = 0) && !InStr(delve_node_u%check%_toggle, "blank"))
		{
			delve_node_%check% := StrReplace(delve_node_%check%, "u,")
			delve_node_u%check%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node_u%check%, % delve_node_u%check%_toggle
		}
		Else hits := 0
		Loop, % delve_gridwidth ;scan right edge of square
		{
			pixelcolor := Gdip_GetPixelColor(pDelve, xzero + delve_gridwidth - 1, yzero + A_Index - 1, 3)
			If InStr(delve_pixelcolors, pixelcolor)
				hits := 1
			If (hits = 1)
			{
				delve_node_%check% .= "r,"
				delve_node_r%check%_toggle := "img\GUI\square_black_opaque.png"
				GuiControl, delve_grid:, delve_node_r%check%, % delve_node_r%check%_toggle
				break
			}
		}
		If ((hits = 0) && !InStr(delve_node_r%check%_toggle, "blank"))
		{
			delve_node_%check% := StrReplace(delve_node_%check%, "r,")
			delve_node_r%check%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node_r%check%, % delve_node_r%check%_toggle
		}
		Else hits := 0
		Loop, % delve_gridwidth ;scan bottom edge of square
		{
			pixelcolor := Gdip_GetPixelColor(pDelve, xzero + A_Index - 1, yzero + delve_gridwidth -1, 3)
			If InStr(delve_pixelcolors, pixelcolor)
				hits := 1
			If (hits = 1)
			{
				delve_node_%check% .= "d,"
				delve_node_d%check%_toggle := "img\GUI\square_black_opaque.png"
				GuiControl, delve_grid:, delve_node_d%check%, % delve_node_d%check%_toggle
				break
			}
		}
		If ((hits = 0) && !InStr(delve_node_d%check%_toggle, "blank"))
		{
			delve_node_%check% := StrReplace(delve_node_%check%, "d,")
			delve_node_d%check%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node_d%check%, % delve_node_d%check%_toggle
		}
		Else hits := 0
		Loop, % delve_gridwidth ;scan left edge of square
		{
			pixelcolor := Gdip_GetPixelColor(pDelve, xzero, yzero + A_Index - 1, 3)
			If InStr(delve_pixelcolors, pixelcolor)
				hits := 1
			If (hits = 1)
			{
				delve_node_%check% .= "l,"
				delve_node_l%check%_toggle := "img\GUI\square_black_opaque.png"
				GuiControl, delve_grid:, delve_node_l%check%, % delve_node_l%check%_toggle
				break
			}
		}
		If ((hits = 0) && !InStr(delve_node_l%check%_toggle, "blank"))
		{
			delve_node_%check% := StrReplace(delve_node_%check%, "l,")
			delve_node_l%check%_toggle := "img\GUI\square_blank.png"
			GuiControl, delve_grid:, delve_node_l%check%, % delve_node_l%check%_toggle
		}
	}
	Gdip_DisposeImage(pDelve)
	Return
}
Return

Exit:
Gdip_Shutdown(pToken)
If (timeout != 1)
{
	If !(alarm_timestamp < A_Now)
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

GUI:
guilist .= InStr(guilist, "LLK_panel|") ? "" : "LLK_panel|"
Gui, LLK_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_LLK_panel
Gui, LLK_panel: Margin, 2, 2
Gui, LLK_panel: Color, Black
WinSet, Transparent, %trans%
Gui, LLK_panel: Font, % "s"fSize1 " cWhite underline", Fontin SmallCaps
Gui, LLK_panel: Add, Text, Section Center BackgroundTrans vLLK_panel HWNDmain_text gSettings_menu, % " LLK-UI "
Gui, LLK_panel: Show, % "NA"
WinGetPos,,, wPanel, hPanel, ahk_id %hwnd_LLK_panel%
panel_xpos_target := (panel_xpos + wPanel > poe_width) ? poe_width - wPanel : panel_xpos ;correct coordinates if panel would end up out of client-bounds
panel_ypos_target := (panel_ypos + hPanel > poe_height) ? poe_height - hPanel : panel_ypos ;correct coordinates if panel would end up out of client-bounds
If (panel_xpos_target + wPanel >= poe_width - pixel_gamescreen_x1 - 1) && (panel_ypos_target <= pixel_gamescreen_y1 + 1) ;protect pixel-check area in case panel gets resized
	panel_ypos_target := pixel_gamescreen_y1 + 2
Gui, LLK_panel: Show, % "Hide x"xScreenOffset + panel_xpos_target " y"yScreenOffset + panel_ypos_target
LLK_Overlay("LLK_panel", (hide_panel = 1) ? "hide" : "show")

If (enable_alarm = 1)
{
	guilist .= InStr(guilist, "alarm_panel|") ? "" : "alarm_panel|"
	Gui, alarm_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_alarm_panel
	Gui, alarm_panel: Margin, 0, 0
	Gui, alarm_panel: Color, Black
	;WinSet, TransColor, Black
	;WinSet, Transparent, %trans%
	Gui, alarm_panel: Font, % "s"fSize1 " cWhite underline", Fontin SmallCaps
	Gui, alarm_panel: Add, Picture, % "Center BackgroundTrans Border gAlarm w" alarm_panel_dimensions " h-1", img\GUI\alarm.jpg
	alarm_panel_xpos_target := (alarm_panel_xpos + alarm_panel_dimensions + 2 > poe_width) ? poe_width - alarm_panel_dimensions - 1 : alarm_panel_xpos ;correct coordinates if panel would end up out of client-bounds
	alarm_panel_ypos_target := (alarm_panel_ypos + alarm_panel_dimensions + 2 > poe_height) ? poe_height - alarm_panel_dimensions - 1 : alarm_panel_ypos ;correct coordinates if panel would end up out of client-bounds
	If (alarm_panel_xpos_target + alarm_panel_dimensions + 2 >= poe_width - pixel_gamescreen_x1 - 1) && (alarm_panel_ypos_target <= pixel_gamescreen_y1 + 1) ;protect pixel-check area in case panel gets resized
		alarm_panel_ypos_target := pixel_gamescreen_y1 + 2
	Gui, alarm_panel: Show, % "NA x"xScreenOffset + alarm_panel_xpos_target  " y"yScreenoffset + alarm_panel_ypos_target
	LLK_Overlay("alarm_panel", "show")
}
Else
{
	guilist := StrReplace(guilist, "alarm_panel|")
	Gui, alarm_panel: Destroy
	hwnd_alarm_panel := ""
}

If (enable_delve = 1)
{
	guilist .= InStr(guilist, "delve_panel|") ? "" : "delve_panel|"
	Gui, delve_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_delve_panel
	Gui, delve_panel: Margin, 0, 0
	Gui, delve_panel: Color, Black
	;WinSet, TransColor, Black
	;WinSet, Transparent, %trans%
	Gui, delve_panel: Font, % "s"fSize1 " cWhite underline", Fontin SmallCaps
	Gui, delve_panel: Add, Picture, % "Center BackgroundTrans Border gdelve w" delve_panel_dimensions " h-1", img\GUI\delve.jpg
	delve_panel_xpos_target := (delve_panel_xpos + delve_panel_dimensions + 2 > poe_width) ? poe_width - delve_panel_dimensions - 1 : delve_panel_xpos ;correct coordinates if panel would end up out of client-bounds
	delve_panel_ypos_target := (delve_panel_ypos + delve_panel_dimensions + 2 > poe_height) ? poe_height - delve_panel_dimensions - 1 : delve_panel_ypos ;correct coordinates if panel would end up out of client-bounds
	If (delve_panel_xpos_target + delve_panel_dimensions + 2 >= poe_width - pixel_gamescreen_x1 - 1) && (delve_panel_ypos_target <= pixel_gamescreen_y1 + 1) ;protect pixel-check area in case panel gets resized
		delve_panel_ypos_target := pixel_gamescreen_y1 + 2
	Gui, delve_panel: Show, % "NA x"xScreenOffset + delve_panel_xpos_target " y"yScreenoffset + delve_panel_ypos_target
	If (enable_delvelog = 1)
		LLK_Overlay("delve_panel", "hide")
	Else LLK_Overlay("delve_panel", "show")
}
Else
{
	guilist := StrReplace(guilist, "delve_panel|")
	Gui, delve_panel: Destroy
	hwnd_delve_panel := ""
}

If (enable_notepad = 1)
{
	guilist .= InStr(guilist, "notepad_panel|") ? "" : "notepad_panel|"
	Gui, notepad_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_notepad_panel
	Gui, notepad_panel: Margin, 0, 0
	Gui, notepad_panel: Color, Black
	;WinSet, TransColor, Black
	;WinSet, Transparent, %trans%
	Gui, notepad_panel: Font, % "s"fSize1 " cWhite underline", Fontin SmallCaps
	Gui, notepad_panel: Add, Picture, % "Center BackgroundTrans Border gNotepad w" notepad_panel_dimensions " h-1", img\GUI\notepad.jpg
	notepad_panel_xpos_target := (notepad_panel_xpos + notepad_panel_dimensions + 2 > poe_width) ? poe_width - notepad_panel_dimensions - 1 : notepad_panel_xpos ;correct coordinates if panel would end up out of client-bounds
	notepad_panel_ypos_target := (notepad_panel_ypos + notepad_panel_dimensions + 2 > poe_height) ? poe_height - notepad_panel_dimensions - 1 : notepad_panel_ypos ;correct coordinates if panel would end up out of client-bounds
	If (notepad_panel_xpos_target + notepad_panel_dimensions + 2 >= poe_width - pixel_gamescreen_x1 - 1) && (notepad_panel_ypos_target <= pixel_gamescreen_y1 + 1) ;protect pixel-check area in case panel gets resized
		notepad_panel_ypos_target := pixel_gamescreen_y1 + 2
	Gui, notepad_panel: Show, % "NA x"xScreenOffset + notepad_panel_xpos_target " y"yScreenoffset + notepad_panel_ypos_target
	LLK_Overlay("notepad_panel", "show")
}
Else
{
	guilist := StrReplace(guilist, "notepad_panel|")
	Gui, notepad_panel: Destroy
	hwnd_notepad_panel := ""
}

If (enable_leveling_guide = 1)
{
	guilist .= InStr(guilist, "leveling_guide_panel|") ? "" : "leveling_guide_panel|"
	Gui, leveling_guide_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_leveling_guide_panel
	Gui, leveling_guide_panel: Margin, 0, 0
	Gui, leveling_guide_panel: Color, Black
	;WinSet, TransColor, Black
	;WinSet, Transparent, %trans%
	Gui, leveling_guide_panel: Font, % "s"fSize1 " cWhite underline", Fontin SmallCaps
	Gui, leveling_guide_panel: Add, Picture, % "Center BackgroundTrans Border gleveling_guide w" leveling_guide_panel_dimensions " h-1", img\GUI\leveling_guide.jpg
	leveling_guide_panel_xpos_target := (leveling_guide_panel_xpos + leveling_guide_panel_dimensions + 2 > poe_width) ? poe_width - leveling_guide_panel_dimensions - 1 : leveling_guide_panel_xpos ;correct coordinates if panel would end up out of client-bounds
	leveling_guide_panel_ypos_target := (leveling_guide_panel_ypos + leveling_guide_panel_dimensions + 2 > poe_height) ? poe_height - leveling_guide_panel_dimensions - 1 : leveling_guide_panel_ypos ;correct coordinates if panel would end up out of client-bounds
	If (leveling_guide_panel_xpos_target + leveling_guide_panel_dimensions + 2 >= poe_width - pixel_gamescreen_x1 - 1) && (leveling_guide_panel_ypos_target <= pixel_gamescreen_y1 + 1) ;protect pixel-check area in case panel gets resized
		leveling_guide_panel_ypos_target := pixel_gamescreen_y1 + 2
	Gui, leveling_guide_panel: Show, % "NA x"xScreenOffset + leveling_guide_panel_xpos_target " y"yScreenoffset + leveling_guide_panel_ypos_target
	LLK_Overlay("leveling_guide_panel", "show")
	
	If (gear_tracker_char != "")
	{
		IniRead, gear_tracker_items, ini\leveling tracker.ini, gear,, % A_Space
		IniRead, gear_tracker_gems, ini\leveling tracker.ini, gems,, % A_Space
		
		gear_tracker_parse := gear_tracker_items "`n" gear_tracker_gems
		Sort, gear_tracker_parse, P2 D`n N
		StringLower, gear_tracker_parse, gear_tracker_parse
		LLK_GearTrackerGUI(1)
	}
}
Else
{
	guilist := StrReplace(guilist, "leveling_guide_panel|")
	Gui, leveling_guide_panel: Destroy
	hwnd_leveling_guide_panel := ""
}

If (continue_alarm = 1)
	GoSub, Alarm
Return

GUI_betrayal_prioview:
Loop, Parse, betrayal_divisions, `,, `,
{
	Gui, betrayal_prioview_%A_Loopfield%: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_betrayal_prioview_%A_Loopfield%
	Gui, betrayal_prioview_%A_Loopfield%: Margin, 0, 0
	Gui, betrayal_prioview_%A_Loopfield%: Color, White
	WinSet, Transparent, 150
	Gui, betrayal_prioview_%A_Loopfield%: Font, % "s"fSize0 * 2 " cBlack", Fontin SmallCaps
	dimensions := (betrayal_info_prio_dimensions = 0) ? 100 : betrayal_info_prio_dimensions
	IniRead, betrayal_info_prio_%A_Loopfield%, ini\betrayal info.ini, Settings, %A_Loopfield% coords, 0`,0
	Loop, Parse, betrayal_info_prio_%A_Loopfield%, `,, `,
	{
		If (A_Index = 1)
			x_coord := A_LoopField
		Else y_coord := A_LoopField
	}
	Gui, betrayal_prioview_%A_Loopfield%: Add, Text, % " Center BackgroundTrans gBetrayal_prio_drag vprio_" A_Loopfield " w"dimensions " h"dimensions, % SubStr(A_Loopfield, 1, 1)
	If (betrayal_info_prio_%A_Loopfield% = "0,0") || !IsNumber(x_coord) || !IsNumber(y_coord)
		Gui, Show, % "NA x"xScreenOffSet + A_Index * poe_width/5 " y" yScreenOffSet + poe_height/4
	Else Gui, Show, % "NA x"xScreenOffSet + x_coord " y" yScreenOffset + y_coord
}
Return

GUI_clone_frames:
Loop, Parse, clone_frames_enabled, `,, `,
{
	If (A_Loopfield = "")
		Break
	Gui, clone_frames_%A_Loopfield%: New, -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_%A_Loopfield%
	guilist := InStr(guilist, A_Loopfield) ? guilist : guilist "clone_frames_" A_Loopfield "|"
}
Return

Gwennen_search:
If (A_GuiControl = "gwennen_regex_edit")
{
	Gui, gwennen_setup: Submit
	IniWrite, %gwennen_regex_edit%, ini\gwennen.ini, regex, regex
	Gui, gwennen_setup: Destroy
	hwnd_gwennen_setup := ""
	Return
}
start := A_TickCount
While GetKeyState(ThisHotkey_copy, "P")
{
	If (A_TickCount >= start + 300)
	{
		Gui, gwennen_setup: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_gwennen_setup
		Gui, gwennen_setup: Margin, 12, 4
		Gui, gwennen_setup: Color, Black
		WinSet, Transparent, %trans%
		Gui, gwennen_setup: Font, % "s"fSize0 " cWhite", Fontin SmallCaps
		Gui, gwennen_setup: Add, Link, % "Section HWNDlink_text", <a href="https://xanthics.github.io/poe_gen_gwennen/">regex-string generator by xanthics</a>
		Gui, gwennen_setup: Font, % "s"fSize0 - 4
		Gui, gwennen_setup: Add, Edit, xs wp Section vgwennen_regex_edit gGwennen_search HWNDmain_text BackgroundTrans center cBlack,
		Gui, gwennen_setup: Font, % "s"fSize0
		Gui, gwennen_setup: Show
		LLK_Overlay("gwennen_setup", "show", 0)
		ControlFocus,, ahk_id %link_text%
		KeyWait, %ThisHotkey_copy%
		Return
	}
}
IniRead, gwennen_check, ini\gwennen.ini, regex, regex
If (hotstringboard = "") && (gwennen_check = "ERROR" || gwennen_check = "")
{
	LLK_ToolTip("no regex string saved")
	Return
}
IniRead, gwennen_regex, ini\gwennen.ini, regex, regex
gwennen_regex = "%gwennen_regex%"
If (hotstringboard = "") && (gwennen_regex != "ERROR" && gwennen_regex != "")
{
	Clipboard := gwennen_regex
	ClipWait
	SendInput, ^{f}^{v}
}
Return

Init_alarm:
IniRead, alarm_xpos, ini\alarm.ini, UI, xcoord, % poe_width/2
IniRead, alarm_ypos, ini\alarm.ini, UI, ycoord, % poe_height/2
IniRead, fSize_offset_alarm, ini\alarm.ini, Settings, font-offset
If fSize_offset_alarm is not number
	fSize_offset_alarm := 0
IniRead, alarm_fontcolor, ini\alarm.ini, Settings, font-color, %A_Space%
alarm_fontcolor := (alarm_fontcolor = "") ? "White" : alarm_fontcolor
IniRead, alarm_trans, ini\alarm.ini, Settings, transparency
If alarm_trans is not number
	alarm_trans := 255
IniRead, alarm_timestamp, ini\alarm.ini, Settings, alarm-timestamp, %A_Space%
alarm_timestamp := (alarm_timestamp < A_Now) ? "" : alarm_timestamp
If (alarm_timestamp != "")
	continue_alarm := 1
IniRead, alarm_panel_offset, ini\alarm.ini, Settings, button-offset, 1
alarm_panel_dimensions := poe_width*0.03*alarm_panel_offset
IniRead, alarm_panel_xpos, ini\alarm.ini, UI, button xcoord, % poe_width/2 - (alarm_panel_dimensions + 2)/2
IniRead, alarm_panel_ypos, ini\alarm.ini, UI, button ycoord, % poe_height - (alarm_panel_dimensions + 2)
Return

Init_betrayal:
betrayal_divisions := "transportation,fortification,research,intervention"
betrayal_color := ["White", "00D000", "Yellow", "E90000", "Aqua"]
betrayal_shift_clicks := 0
IniRead, betrayal_list, data\Betrayal.ini
betrayal_list := StrReplace(betrayal_list, "version`n")
Sort, betrayal_list, D`n
IniRead, betrayal_ini_version_data, data\Betrayal.ini, Version, version, 1
IniRead, betrayal_ini_version_user, ini\betrayal info.ini, Version, version, 0
If !FileExist("ini\betrayal info.ini") || (betrayal_ini_version_user < betrayal_ini_version_data)
{
	betrayal_info_exists := FileExist("ini\betrayal info.ini") ? 1 : 0
	IniWrite, %betrayal_ini_version_data%, ini\betrayal info.ini, Version, version
	If (betrayal_info_exists = 0)
	{
		IniWrite, 0, ini\betrayal info.ini, Settings, font-offset
		IniWrite, 220, ini\betrayal info.ini, Settings, transparency
	}
	Loop, Parse, betrayal_list, `n, `n
	{
		check := A_Loopfield
		If (A_LoopField = "settings") || (A_Loopfield = "version")
			continue
		If (betrayal_info_exists = 0)
			IniWrite, transportation=1`nfortification=1`nresearch=1`nintervention=1, ini\betrayal info.ini, %check%
	}
}
IniRead, fSize_offset_betrayal, ini\betrayal info.ini, Settings, font-offset, 0
IniRead, betrayal_trans, ini\betrayal info.ini, Settings, transparency, 220
IniRead, betrayal_enable_recognition, ini\betrayal info.ini, Settings, enable image recognition, 0
IniRead, betrayal_perma_table, ini\betrayal info.ini, Settings, permanent table, 0
IniRead, betrayal_info_table_pos, ini\betrayal info.ini, Settings, table-position, left
IniRead, betrayal_info_prio_dimensions, ini\betrayal info.ini, Settings, prioview-dimensions, 0
IniRead, betrayal_info_prio_transportation, ini\betrayal info.ini, Settings, transportation coords, 0`,0
IniRead, betrayal_info_prio_fortification, ini\betrayal info.ini, Settings, fortification coords, 0`,0
IniRead, betrayal_info_prio_research, ini\betrayal info.ini, Settings, research coords, 0`,0
IniRead, betrayal_info_prio_intervention, ini\betrayal info.ini, Settings, intervention coords, 0`,0
Loop, Parse, betrayal_divisions, `,, `,
{
	%A_LoopField%_xcoord := (betrayal_info_prio_%A_LoopField% != "0,0") ? SubStr(betrayal_info_prio_%A_LoopField%, 1, InStr(betrayal_info_prio_%A_LoopField%, ",") - 1) : ""
	%A_LoopField%_ycoord := (betrayal_info_prio_%A_LoopField% != "0,0") ? SubStr(betrayal_info_prio_%A_LoopField%, InStr(betrayal_info_prio_%A_LoopField%, ",") + 1) : ""
}
Return

Init_cloneframes:
If !FileExist("ini\clone frames.ini")
	IniWrite, 0, ini\clone frames.ini, Settings, enable pixel-check
IniRead, clone_frames_list, ini\clone frames.ini
IniRead, clone_frames_pixelcheck_enable, ini\clone frames.ini, Settings, enable pixel-check, 1
Loop, Parse, clone_frames_list, `n, `n
{
	If (A_LoopField = "Settings")
		continue
	IniRead, clone_frame_%A_LoopField%_enable, ini\clone frames.ini, %A_LoopField%, enable, 0
	If (clone_frame_%A_LoopField%_enable = 1)
		clone_frames_enabled := (clone_frames_enabled = "") ? A_LoopField "," : A_LoopField "," clone_frames_enabled
	IniRead, clone_frame_%A_LoopField%_topleft_x, ini\clone frames.ini, %A_LoopField%, source x-coordinate, 0
	IniRead, clone_frame_%A_LoopField%_topleft_y, ini\clone frames.ini, %A_LoopField%, source y-coordinate, 0
	IniRead, clone_frame_%A_LoopField%_width, ini\clone frames.ini, %A_LoopField%, frame-width, 200
	IniRead, clone_frame_%A_LoopField%_height, ini\clone frames.ini, %A_LoopField%, frame-height, 200
	IniRead, clone_frame_%A_LoopField%_target_x, ini\clone frames.ini, %A_LoopField%, target x-coordinate, % xScreenOffset + poe_width//2
	IniRead, clone_frame_%A_LoopField%_target_y, ini\clone frames.ini, %A_LoopField%, target y-coordinate, % yScreenOffset + poe_height//2
	IniRead, clone_frame_%A_LoopField%_scale_x, ini\clone frames.ini, %A_LoopField%, scaling x-axis, 100
	IniRead, clone_frame_%A_LoopField%_scale_y, ini\clone frames.ini, %A_LoopField%, scaling y-axis, 100
	IniRead, clone_frame_%A_LoopField%_opacity, ini\clone frames.ini, %A_LoopField%, opacity, 5
}
Return

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

Init_delve:
IniRead, enable_delve, ini\config.ini, Features, enable delve, 0
IniRead, delve_panel_offset, ini\delve.ini, Settings, button-offset, 1
delve_panel_dimensions := poe_width*0.03*delve_panel_offset
IniRead, delve_panel_xpos, ini\delve.ini, UI, button xcoord, % poe_width/2 - (delve_panel_dimensions + 2)/2
IniRead, delve_panel_ypos, ini\delve.ini, UI, button ycoord, % poe_height - (delve_panel_dimensions + 2)
IniRead, delve_gridwidth, ini\delve.ini, UI, grid dimensions, % Floor(poe_height*0.73/8)
IniRead, enable_delvelog, ini\delve.ini, Settings, enable log-scanning, 0
enable_delvelog := !FileExist(poe_log_file) ? 0 : enable_delvelog
IniRead, delve_enable_recognition, ini\delve.ini, Settings, enable image-recognition, 0
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

Init_gwennen:
IniRead, gwennen_regex, ini\gwennen.ini, regex, regex
Return

Init_legion:
IniRead, fSize_offset_legion, ini\timeless jewels.ini, Settings, font-offset, 0
Return

Init_leveling_guide:
IniRead, enable_leveling_guide, ini\config.ini, Features, enable leveling guide, 0
IniRead, fSize_offset_leveling_guide, ini\leveling tracker.ini, Settings, font-offset, 0
fSize_leveling_guide := fSize0 + fSize_offset_leveling_guide
IniRead, leveling_guide_fontcolor, ini\leveling tracker.ini, Settings, font-color, White
IniRead, leveling_guide_trans, ini\leveling tracker.ini, Settings, transparency, 250
IniRead, leveling_guide_panel_offset, ini\leveling tracker.ini, Settings, button-offset, 1
IniRead, leveling_guide_position, ini\leveling tracker.ini, Settings, overlay-position, bottom
leveling_guide_panel_dimensions := poe_width*0.03*leveling_guide_panel_offset
IniRead, leveling_guide_panel_xpos, ini\leveling tracker.ini, UI, button xcoord, % poe_width/2 - (leveling_guide_panel_dimensions + 2)/2
IniRead, leveling_guide_panel_ypos, ini\leveling tracker.ini, UI, button ycoord, % poe_height - (leveling_guide_panel_dimensions + 2)
IniRead, gear_tracker_char, ini\leveling tracker.ini, Settings, character, % A_Space
IniRead, gear_tracker_indicator_xpos, ini\leveling tracker.ini, UI, indicator xcoord, % 0.3*poe_width
IniRead, gear_tracker_indicator_ypos, ini\leveling tracker.ini, UI, indicator ycoord, % 0.91*poe_height
Return

Init_maps:
Loop 16
{
	IniRead, maps_tier%A_Index%, data\Atlas.ini, Maps, tier%A_Index%
	maps_list := (maps_list = "") ? StrReplace(maps_tier%A_Index%, ",", " (" A_Index "),") : maps_list StrReplace(maps_tier%A_Index%, ",", " (" A_Index "),")
	Sort, maps_tier%A_Index%, D`,
	maps_tier%A_Index% := SubStr(maps_tier%A_Index%, 1, -1)
	maps_tier%A_Index% := StrReplace(maps_tier%A_Index%, ",", "`n")
}
Sort, maps_list, D`,
Loop, Parse, maps_list, `,, `,
{
	If (A_Loopfield = "")
		break
	letter := SubStr(A_Loopfield, 1, 1)
	maps_%letter% := (maps_%letter% = "") ? A_Loopfield : maps_%letter% "`n" A_Loopfield
}

IniRead, map_info_pixelcheck_enable, ini\map info.ini, Settings, enable pixel-check, 1
If (map_info_pixelcheck_enable = 1)
	pixelchecks_enabled := InStr(pixelchecks_enabled, "gamescreen") ? pixelchecks_enabled : pixelchecks_enabled "gamescreen,"
IniRead, fSize_offset_map_info, ini\map info.ini, Settings, font-offset, 0
IniRead, map_info_trans, ini\map info.ini, Settings, transparency, 220
If fSize_offset_map_info is not number
	fSize_offset_map_info := 0
IniRead, map_info_short, ini\map info.ini, Settings, short descriptions, 1
IniRead, map_info_xPos, ini\map info.ini, Settings, x-coordinate, 0
map_info_side := (map_info_xPos >= poe_width//2) ? "right" : "left"
IniRead, map_info_yPos, ini\map info.ini, Settings, y-coordinate, 0
IniRead, map_mod_ini_version_data, data\Map mods.ini, Version, version, 1
IniRead, map_mod_ini_version_user, ini\map info.ini, Version, version, 0
If !FileExist("ini\map info.ini") || (map_mod_ini_version_data > map_mod_ini_version_user)
{
	map_info_exists := FileExist("ini\map info.ini") ? 1 : 0
	IniWrite, %map_mod_ini_version_data%, ini\map info.ini, Version, version
	If (map_info_exists = 0)
	{
		IniWrite, 0, ini\map info.ini, Settings, enable pixel-check
		IniWrite, 0, ini\map info.ini, Settings, font-offset
		IniWrite, 220, ini\map info.ini, Settings, transparency
	}
	IniRead, map_info_parse, data\Map mods.ini
	Loop, Parse, map_info_parse, `n, `n
	{
		If (A_LoopField = "sample map") || (A_LoopField = "version")
			continue
		IniRead, parse_ID, data\Map mods.ini, %A_LoopField%, ID
		If (map_info_short = 1)
			IniRead, parse_text, data\Map mods.ini, %A_LoopField%, text
		Else IniRead, parse_text, data\Map mods.ini, %A_LoopField%, text1
		IniRead, parse_type, data\Map mods.ini, %A_LoopField%, type
		IniRead, parse_rank, ini\map info.ini, %parse_ID%, rank
		IniWrite, %parse_text%, ini\map info.ini, %parse_ID%, text
		IniWrite, %parse_type%, ini\map info.ini, %parse_ID%, type
		If (map_info_exists = 0) || (parse_rank = "") || (parse_rank = "ERROR")
			IniWrite, 1, ini\map info.ini, %parse_ID%, rank
	}
}
Return

Init_notepad:
IniRead, notepad_width, ini\notepad.ini, UI, width, 400
IniRead, notepad_height, ini\notepad.ini, UI, height, 400
IniRead, notepad_text, ini\notepad.ini, Text, text, %A_Space%
If (notepad_text != "")
	notepad_text := StrReplace(notepad_text, ",,", "`n")
IniRead, fSize_offset_notepad, ini\notepad.ini, Settings, font-offset, 0
IniRead, notepad_fontcolor, ini\notepad.ini, Settings, font-color, White
IniRead, notepad_trans, ini\notepad.ini, Settings, transparency, 250
IniRead, notepad_panel_offset, ini\notepad.ini, Settings, button-offset, 1
notepad_panel_dimensions := poe_width*0.03*notepad_panel_offset
IniRead, notepad_panel_xpos, ini\notepad.ini, UI, button xcoord, % poe_width/2 - (notepad_panel_dimensions + 2)/2
IniRead, notepad_panel_ypos, ini\notepad.ini, UI, button ycoord, % poe_height - (notepad_panel_dimensions + 2)
Return

Init_omnikey:
If (poe_config_file != "")
{
	FileRead, all_hotkeys, % poe_config_file
	If InStr(all_hotkeys, "=67`n") && !InStr(all_hotkeys, "open_character_panel=67")
		omnikey_conflict_c := 1
	omnikey_conflict_alt := !InStr(all_hotkeys, "highlight=18") ? 1 : ""
	IniRead, alt_modifier, ini\config.ini, Settings, highlight-key, % A_Space
	all_hotkeys := ""
}
IniRead, omnikey_hotkey, ini\config.ini, Settings, omni-hotkey, %A_Space%
Loop, Parse, blocked_hotkeys, `,, `,
	omnikey_hotkey := InStr(omnikey_hotkey, A_Loopfield) ? "" : omnikey_hotkey

If (omnikey_hotkey != "") ;custom omni-key
{
	Hotkey, IfWinActive, ahk_group poe_ahk_window
	If (omnikey_conflict_c != 1)
	{
		Hotkey, *~%omnikey_hotkey%, Omnikey, On
		Hotkey, *~MButton, Omnikey, Off
		omnikey_hotkey_old := omnikey_hotkey
	}
	Else
	{
		IniRead, omnikey_hotkey2, ini\config.ini, Settings, omni-hotkey2, % A_Space
		Hotkey, *~%omnikey_hotkey%, Omnikey2, On
		Hotkey, *~MButton, Omnikey2, Off
		If (omnikey_hotkey2 != "")
			Hotkey, *~%omnikey_hotkey2%, Omnikey, On
	}
}
Else ;standard omni-key
{
	Hotkey, IfWinActive, ahk_group poe_ahk_window
	If (omnikey_conflict_c != 1)
	{
		Hotkey, *~MButton, Omnikey, On
		omnikey_hotkey_old := "MButton"
	}
	Else
	{
		IniRead, omnikey_hotkey2, ini\config.ini, Settings, omni-hotkey2, % A_Space
		Hotkey, *~MButton, Omnikey2, On
		omnikey_hotkey_old := "MButton"
		If (omnikey_hotkey2 != "")
			Hotkey, *~%omnikey_hotkey2%, Omnikey, On
	}
}
Return

Init_screenchecks:
Sort, pixelchecks_list, D`,
Loop, Parse, pixelchecks_list, `,, `,
	IniRead, disable_pixelcheck_%A_Loopfield%, ini\screen checks (%poe_height%p).ini, %A_Loopfield%, disable, 0


Sort, imagechecks_list, D`,
Loop, Parse, imagechecks_list, `,, `,
	IniRead, disable_imagecheck_%A_Loopfield%, ini\screen checks (%poe_height%p).ini, %A_Loopfield%, disable, 0

IniRead, pixel_gamescreen_x1, data\Resolutions.ini, %poe_height%p, gamescreen x-coordinate 1
IniRead, pixel_gamescreen_y1, data\Resolutions.ini, %poe_height%p, gamescreen y-coordinate 1
IniRead, pixel_gamescreen_color1, ini\screen checks (%poe_height%p).ini, gamescreen, color 1

If (pixel_gamescreen_color1 = "ERROR") || (pixel_gamescreen_color1 = "")
{
	clone_frames_pixelcheck_enable := 0
	map_info_pixelcheck_enable := 0
	pixelchecks_enabled := StrReplace(pixelchecks_enabled, "gamescreen,")
}
Return

Init_searchstrings:
If !FileExist("ini\stash search.ini")
	IniWrite, stash=`nvendor=, ini\stash search.ini, Settings
IniRead, stash_search_check, ini\stash search.ini, Settings
Loop, Parse, stash_search_usecases, `,, `,
{
	If !InStr(stash_search_check, A_Loopfield "=")
		IniWrite, % A_Space, ini\stash search.ini, Settings, % A_Loopfield
}
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
guilist .= "betrayal_search|gwennen_setup|betrayal_info_members|legion_window|legion_list|legion_treemap|legion_treemap2|notepad_drag|"
buggy_resolutions := "768,1024,1050"
allowed_recomb_classes := "shield,sword,quiver,bow,claw,dagger,mace,ring,amulet,helmet,glove,boot,belt,wand,staves,axe,sceptre,body,sentinel"
delve_directions := "u,d,l,r,"
Return

Lab_info:
If (A_Gui = "context_menu") || InStr(A_ThisHotkey, ":")
{
	lab_mode := 1
	Run, https://www.poelab.com
	Return
}
If (A_GuiControl = "Lab_marker")
{
	Gui, lab_marker: New, -DPIScale -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_lab_marker
	Gui, lab_marker: Color, White
	WinSet, Transparent, 100
	MouseGetPos, mouseXpos, mouseYpos
	Gui, lab_marker: Show, % "NA w"poe_width * 3/160 * 212/235 " h"poe_width * 3/160 * 212/235 " x"mouseXpos - (poe_width * 3/160 * 212/235)/2 " y"mouseYpos - (poe_width * 3/160 * 212/235)/2
	LLK_Overlay("lab_marker", "show")
	WinActivate, ahk_group poe_window
	Return
}
If (A_ThisHotkey = "Tab")
{
	If (hwnd_lab_layout = "")
	{
		If (Gdip_CreateBitmapFromClipboard() < 0)
		{
			LLK_ToolTip("no image-data in clipboard", 1.5, xScreenOffSet + poe_width/2, yScreenOffSet + poe_height/2)
			KeyWait, Tab
			Return
		}
		pLab_source := Gdip_CloneBitmapArea(Gdip_CreateBitmapFromClipboard(), 257, 42, 1175, 521)
		wLab_source := 1175
		hLab_source := 521
		hbmLab_source := CreateDIBSection(wLab_source, hLab_source)
		hdcLab_source := CreateCompatibleDC()
		obmLab_source := SelectObject(hdcLab_source, hbmLab_source)
		gLab_source := Gdip_GraphicsFromHDC(hdcLab_source)
		Gdip_SetInterpolationMode(gLab_source, 0)
		Gdip_DrawImage(gLab_source, pLab_source, 0, 0, wLab_source, hLab_source, 0, 0, wLab_source, hLab_source, 1)
		Gui, lab_layout: New, -DPIScale -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_lab_layout, Lailloken UI: lab-info
		Gui, lab_layout: Color, Black
		Gui, lab_layout: Margin, 0, 0
		Gui, lab_layout: Font, s%fSize0% cWhite, Fontin SmallCaps
		Gui, lab_layout: Add, Picture, % "BackgroundTrans vLab_marker gLab_info w" poe_width * 53/128 " h-1", HBitmap:*%hbmLab_source%
		Gui, lab_layout: Show, Hide
		WinGetPos,,,, hWin
		Gui, lab_layout: Show, % "NA x"xScreenOffSet + poe_width * 75/256 " y"yScreenOffSet + poe_height - hWin
		LLK_Overlay("lab_layout", "show")
		SelectObject(hdcLab_source, obmLab_source)
		DeleteObject(hbmLab_source)
		DeleteDC(hdcLab_source)
		Gdip_DeleteGraphics(gLab_source)
		Gdip_DisposeImage(pLab_source)
	}
	Else
	{
		LLK_Overlay("lab_layout", "toggle")
		LLK_Overlay("lab_marker", "toggle")
	}
	KeyWait, Tab
}
Return

Legion_seeds:
If (legion_profile = "")
	IniRead, legion_profile, ini\timeless jewels.ini, Settings, profile, %A_Space%

;create array with all socket-relevant notables
legion_notables_array := []
legion_tooltips_array := []
IniRead, parse, data\timeless jewels\mod descriptions.ini, descriptions
Loop, Parse, parse, `n, `n
	legion_tooltips_array.Push(SubStr(A_Loopfield, 1, InStr(A_Loopfield, "=")-1))
FileReadLine, legion_csv_parse, data\timeless jewels\brutal restraint.csv, 1
Loop, Parse, legion_csv_parse, CSV
	legion_notables_array.Push(StrReplace(A_LoopField, """"))
legion_csv_parse := ""

Loop, Files, data\timeless jewels\*.csv
{
	parse := StrReplace(A_LoopFileName, ".csv")
	parse := StrReplace(parse, " ", "_")
	IniRead, legion_%parse%_favs, ini\timeless jewels.ini, favorites%legion_profile%, % StrReplace(parse, "_", " "), % A_Space
}
	
IniRead, legion_treemap_notables, data\timeless jewels\Treemap.ini, all notables

If !WinExist("ahk_id " hwnd_legion_window) ;create GUI with blank text labels
{
	Gui, legion_window: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_legion_window
	Gui, legion_window: Margin, 12, 0
	Gui, legion_window: Color, Black
	WinSet, Transparent, %trans%
	Gui, legion_window: Font, % "s"fSize0 + fSize_offset_legion " cWhite", Fontin SmallCaps
	
	Gui, legion_window: Add, Text, Section y4 BackgroundTrans Center, % "profile: "
	Loop 5
	{
		If (A_Index = 1)
			Gui, legion_window: Add, Text, ys x+4 Border BackgroundTrans Center vlegion_profile gLegion_seeds_apply, % " " A_Index " "
		Else Gui, legion_window: Add, Text, ys x+4 Border BackgroundTrans Center vlegion_profile%A_Index% gLegion_seeds_apply, % " " A_Index " "
	}
	
	GuiControl, legion_window: +cFuchsia, % "legion_profile" StrReplace(legion_profile, "_")
	
	Gui, legion_window: Add, Text, % "xs Section BackgroundTrans Left vlegion_type y+8", % "type: brutal restraint"
	Gui, legion_window: Add, Text, % "xs BackgroundTrans Left vlegion_seed wp", % "seed:"
	Gui, legion_window: Add, Text, % "xs BackgroundTrans Left vlegion_name wp", % "name:"
	Gui, legion_window: Add, Text, xs Section Border BackgroundTrans Center vlegion_paste gLegion_seeds_parse y+8, % " import | trade-check "
	Gui, legion_window: Add, Text, ys Border BackgroundTrans Center vlegion_minus gLegion_seeds_apply, % " – "
	Gui, legion_window: Add, Text, ys x+4 Border wp BackgroundTrans Center vlegion_zero gLegion_seeds_apply, % "0"
	Gui, legion_window: Add, Text, ys x+4 Border wp BackgroundTrans Center vlegion_plus gLegion_seeds_apply, % "+"
	
	Gui, legion_window: Font, underline
	Gui, legion_window: Add, Text, % "xs Section BackgroundTrans Left y+8", % "keystones:"
	Gui, legion_window: Font, norm
	Loop 3
		Gui, legion_window: Add, Text, % "xs BackgroundTrans vlegion_keystonetext" A_Index " gLegion_seeds_help", supreme grandstanding
	
	
	Gui, legion_window: Font, underline
	Gui, legion_window: Add, Text, % "xs Section x12 BackgroundTrans y+8", resulting modifications:
	Gui, legion_window: Font, norm
	
	Loop 22
		Gui, legion_window: Add, Text, % "xs Section vlegion_modtext" A_Index " gLegion_seeds_help BackgroundTrans", night of a thousand ribbons (11x)
}

If (legion_type_parse = "") ;placeholder values in case UI is accessed via .legion
{
	legion_type_parse := "lethal pride"
	legion_seed_parse := 18000
	legion_name_parse := "kaom"
}

GuiControl, legion_window: text, legion_type, % "type: " legion_type_parse
GuiControl, legion_window: text, legion_seed, % "seed: " legion_seed_parse
GuiControl, legion_window: text, legion_name, % "name: " legion_name_parse

legion_encode_array := []
Iniread, legion_decode_keys, data\timeless jewels\jewels.ini, % legion_type_parse
legion_type_parse2 := StrReplace(legion_type_parse, " ", "_")

Loop, Parse, legion_decode_keys, `n, `n
{
	IniRead, legion_%legion_type_parse2%_mod%A_Index%, data\timeless jewels\jewels.ini, % legion_type_parse, % A_Index
	legion_encode_array.Push(legion_%legion_type_parse2%_mod%A_Index%)
}

IniRead, legion_keystones, data\timeless jewels\Jewels.ini, types, % legion_type_parse, 0
IniRead, legion_keystone, data\timeless jewels\Jewels.ini, names, % legion_name_parse, 0
IniRead, legion_keystone2, data\timeless jewels\Jewels.ini, names

Loop, Parse, legion_keystones, CSV ;highlight applicable keystone
{
	check := A_LoopField
	loop := A_Index
	Loop, Parse, legion_keystone2, `n, `n
		If InStr(A_LoopField, check)
			legion_name%loop% := SubStr(A_LoopField, 1, InStr(A_LoopField, "=")-1)
	GuiControl, legion_window: text, legion_keystonetext%A_Index%, % A_LoopField
	If (legion_keystone = A_LoopField)
		GuiControl, legion_window: +cLime, legion_keystonetext%A_Index%
	Else GuiControl, legion_window: +cWhite, legion_keystonetext%A_Index%
}

Loop, Read, data\timeless jewels\%legion_type_parse%.csv ;create array with all modifications of the current seed
{
	If (SubStr(A_LoopReadLine, 1, InStr(A_LoopReadLine, ",",,, 1) - 1) = legion_seed_parse)
	{
		legion_csvline_array := []
		Loop, Parse, A_LoopReadLine, CSV
			legion_csvline_array.Push(A_Loopfield)
		break
	}
}

If (A_Gui != "legion_treemap") ;calculate desired mod numbers for the overview
{
	IniRead, legion_sockets, data\timeless jewels\sockets.ini
	Loop, Parse, legion_sockets, `n, `n
	{
		IniRead, legion_socket_notables, data\timeless jewels\sockets.ini, socket%A_Index%
		
		legion_socket_notables_array := []
		Loop, Parse, legion_socket_notables, `n, `n
			legion_socket_notables_array.Push(A_Loopfield)
		
		modpool := ""
		modpool_unique := ""
		
		Loop, % legion_socket_notables_array.Length()
		{
			target_key := legion_csvline_array[LLK_ArrayHasVal(legion_notables_array, legion_socket_notables_array[A_Index])]
			modpool .= legion_%legion_type_parse2%_mod%target_key% ","
			modpool_unique .= InStr(modpool_unique, legion_%legion_type_parse2%_mod%target_key%) ? "" : legion_%legion_type_parse2%_mod%target_key% ","
		}
		
		Sort, modpool_unique, D`,
		modpool_unique_array := []
		modpool_unique_array2 := []
		Loop, Parse, modpool_unique, `,, `,
		{
			If (A_Loopfield = "")
				break
			count := (LLK_InStrCount(modpool, A_Loopfield, ",") > 1) ? " (" LLK_InStrCount(modpool, A_Loopfield, ",") "x)" : ""
			modpool_unique_array.Push(A_Loopfield count)
			modpool_unique_array2.Push(A_Loopfield)
		}
		
		count := 0
		count_overlaps := 0
		IniRead, legion_socket%A_Index%_favs, ini\timeless jewels.ini, favorites%legion_profile%, socket%A_Index%, % A_Space
		Loop, Parse, legion_socket%A_Index%_favs, CSV
		{
			If (A_Loopfield = "")
				break
			target_column := LLK_ArrayHasVal(legion_notables_array, A_Loopfield)
			target_key := legion_csvline_array[target_column]
			count_overlaps += InStr(legion_%legion_type_parse2%_favs, legion_%legion_type_parse2%_mod%target_key% ",") ? 1 : 0
		}
		Loop 22
		{
			If InStr(legion_%legion_type_parse2%_favs, modpool_unique_array2[A_Index]) && (modpool_unique_array2[A_Index] != "")
			{
				If InStr(modpool_unique_array[A_Index], "x)")
				{
					multiplier := SubStr(modpool_unique_array[A_Index], -2, 1)
					count += 1*multiplier
				}
				Else count += 1
			}
		}
		GuiControl, legion_treemap: text, legion_socket_text%A_Index%, % (count = 0) ? "" : count
		GuiControl, legion_treemap: text, legion_socket_text%A_Index%overlap, % (count_overlaps = 0) ? "" : count_overlaps
		legion_socket%A_Index%_notables := count
	}
}
Else GoSub, Legion_seeds3

If (legion_socket != "") ;calculate data for top left panel and apply text to labels
{
	IniRead, legion_socket_notables, data\timeless jewels\sockets.ini, % legion_socket
	
	legion_socket_notables_array := []
	Loop, Parse, legion_socket_notables, `n, `n
		legion_socket_notables_array.Push(A_Loopfield)
	
	modpool := ""
	modpool_unique := ""
	
	Loop, % legion_socket_notables_array.Length()
	{
		target_key := legion_csvline_array[LLK_ArrayHasVal(legion_notables_array, legion_socket_notables_array[A_Index])]
		modpool .= legion_%legion_type_parse2%_mod%target_key% ","
		modpool_unique .= InStr(modpool_unique, legion_%legion_type_parse2%_mod%target_key%) ? "" : legion_%legion_type_parse2%_mod%target_key% ","
	}
	
	Sort, modpool_unique, D`,
	modpool_unique_array := []
	modpool_unique_array2 := []
	Loop, Parse, modpool_unique, `,, `,
	{
		If (A_Loopfield = "")
			break
		count := (LLK_InStrCount(modpool, A_Loopfield, ",") > 1) ? " (" LLK_InStrCount(modpool, A_Loopfield, ",") "x)" : ""
		modpool_unique_array.Push(A_Loopfield count)
		modpool_unique_array2.Push(A_Loopfield)
	}
	
	Loop 22
	{
		GuiControl, legion_window: , legion_modtext%A_Index%, % modpool_unique_array[A_Index]
		If InStr(legion_%legion_type_parse2%_favs, modpool_unique_array2[A_Index]) && (modpool_unique_array2[A_Index] != "")
			GuiControl, legion_window: +cAqua, legion_modtext%A_Index%
		Else If !InStr(legion_%legion_type_parse2%_favs, modpool_unique_array2[A_Index]) || (modpool_unique_array2[A_Index] = "")
			GuiControl, legion_window: +cWhite, legion_modtext%A_Index%
	}
	WinSet, Redraw,, ahk_id %hwnd_legion_window%
}
Else
{
	Loop 22
		GuiControl, legion_window: text, legion_modtext%A_Index%, % ""
}


If (A_Gui = "legion_treemap") && (legion_socket != "") ;auto-highlight notables affected by desired modifications
{
	legion_highlight := ""
	Loop, Parse, legion_%legion_type_parse2%_favs, `,, `,
	{
		If (A_Loopfield = "")
			break
		target_code := LLK_ArrayHasVal(legion_encode_array, A_Loopfield)
		Loop, Parse, % LLK_ArrayHasVal(legion_csvline_array, target_code, 1), `,, `,
		{
			If (A_Loopfield = "")
				break
			If InStr(legion_socket_notables, legion_notables_array[A_Loopfield] "`n") || (SubStr(legion_socket_notables, -StrLen(legion_notables_array[A_Loopfield])+1) = legion_notables_array[A_Loopfield])
			{
				legion_highlight .= SubStr(legion_notables_array[A_Loopfield], 1, Floor((100-3-legion_%legion_socket%_notables+1)/(legion_%legion_socket%_notables))) "|"
				If (LLK_SubStrCount(legion_treemap_notables, SubStr(legion_notables_array[A_Loopfield], 1, Floor((100-3-legion_%legion_socket%_notables+1)/(legion_%legion_socket%_notables))), "`n", 1) > 1) && (SubStr(legion_notables_array[A_Loopfield], 1, Floor((100-3-legion_%legion_socket%_notables+1)/(legion_%legion_socket%_notables))) != legion_notables_array[A_Loopfield])
				{
					LLK_ToolTip("auto-highlight unavailable:`ntoo many desired mods around this socket", 1)
					WinActivate, ahk_group poe_window
					WinWaitActive, ahk_group poe_window
					sleep, 50
					SendInput, ^{f}{ESC}
					Return
				}
			}
		}
	}

	If (legion_highlight != "")
	{
		legion_highlight := SubStr(legion_highlight, 1, -1)
		legion_highlight := StrReplace(legion_highlight, " ", ".")
		legion_highlight = ^(%legion_highlight%)
		WinActivate, ahk_group poe_window
		WinWaitActive, ahk_group poe_window
		sleep, 50
		clipboard := legion_highlight
		ClipWait, 0.05
		SendInput, ^{f}^{v}{Enter}
	}
}

If !WinExist("ahk_id " hwnd_legion_window)
{
	Gui, legion_window: Show, % "NA x" xScreenOffSet " y" yScreenOffSet
	WinGetPos,,, legion_window_width,, ahk_id %hwnd_legion_window%
	Gui, legion_window: Show, % "NA x" xScreenOffSet " y" yScreenOffSet " h"poe_height - legion_window_width - 1
	LLK_Overlay("legion_window", "show")
}
WinGetPos,,, legion_window_width,, ahk_id %hwnd_legion_window%
GoSub, Legion_seeds3
Return

Legion_seeds_apply:
If (A_GuiControl = "legion_minus")
{
	fSize_offset_legion -= 1
	IniWrite, % fSize_offset_legion, ini\timeless jewels.ini, Settings, font-offset
}
If (A_GuiControl = "legion_zero")
{
	fSize_offset_legion := 0
	IniWrite, % fSize_offset_legion, ini\timeless jewels.ini, Settings, font-offset
}
If (A_GuiControl = "legion_plus")
{
	fSize_offset_legion += 1
	IniWrite, % fSize_offset_legion, ini\timeless jewels.ini, Settings, font-offset
}
If (A_GuiControl = "legion_minus" || A_GuiControl = "legion_zero" || A_GuiControl = "legion_plus")
{
	Gui, legion_window: Destroy
	Gui, legion_treemap: Destroy
	Gui, legion_treemap2: Destroy
	Gui, legion_list: Destroy
	hwnd_legion_window := ""
	hwnd_legion_treemap := ""
	hwnd_legion_treemap2 := ""
	hwnd_legion_list := ""
	GoSub, Legion_seeds
	GoSub, Legion_seeds2
	Return
}
If InStr(A_GuiControl, "legion_profile")
{
	If (click = 2)
	{
		If (legion_profile = StrReplace(A_GuiControl, "legion_profile") || legion_profile = "_" StrReplace(A_GuiControl, "legion_profile"))
			IniDelete, ini\timeless jewels.ini, favorites%legion_profile%
		Else
		{
			IniRead, ini_copy, ini\timeless jewels.ini, favorites%legion_profile%
			IniWrite, % ini_copy, ini\timeless jewels.ini, % (StrReplace(A_GuiControl, "legion_profile") = "") ? "favorites" : "favorites_" StrReplace(A_GuiControl, "legion_profile")
		}
		GoSub, Legion_seeds
		Return
	}
	legion_profile := (StrReplace(A_GuiControl, "legion_profile") = "") ? "" : "_" StrReplace(A_GuiControl, "legion_profile")
	Loop 5
	{
		If (A_Index = 1)
			GuiControl, legion_window: +cWhite, legion_profile
		Else GuiControl, legion_window: +cWhite, legion_profile%A_Index%
	}
	GuiControl, legion_window: +cFuchsia, % "legion_profile" StrReplace(legion_profile, "_")
	WinSet, Redraw,, ahk_id %hwnd_legion_window%
	IniWrite, % legion_profile, ini\timeless jewels.ini, Settings, profile
	GoSub, Legion_seeds
	Return
}
Return

Legion_seeds2:
If (hwnd_legion_treemap != "") ;create passive tree GUI & place squares and number labels
	Return
Else
{
	Gui, legion_treemap2: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_legion_treemap2
	Gui, legion_treemap2: Margin, 0, 0
	Gui, legion_treemap2: Color, Black
	Gui, legion_treemap2: Font, % "s"fSize0 + fSize_offset_legion " cAqua bold", Fontin SmallCaps
	Gui, legion_treemap2: Add, Picture, % "BackgroundTrans h" legion_window_width - 2 " w-1", img\GUI\legion_treemap.jpg
	
	Gui, legion_treemap: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_legion_treemap
	Gui, legion_treemap: Margin, 0, 0
	Gui, legion_treemap: Color, Black
	Gui, legion_treemap: Font, % "s"fSize0 + fSize_offset_legion " cAqua bold", Fontin SmallCaps
	Gui, legion_treemap: Add, Picture, % "BackgroundTrans h" legion_window_width + legion_list_width - 3 " w-1", img\GUI\legion_treemap.jpg
	IniRead, squarecount, data\timeless jewels\Treemap.ini, squares
	Loop, Parse, squarecount, `n, `n
	{
		If (StrLen(A_Loopfield) < 4)
			break
		IniRead, coords, data\timeless jewels\Treemap.ini, squares, % A_Index, 0
		square_coords := StrSplit(coords, ",", ",")
		style := (StrReplace(previous_socket, "legion_socket") = A_Index) ? "img\GUI\square_red.png" : ""
		Gui, legion_treemap: Add, Text, % "BackgroundTrans Left vlegion_socket_text" A_Index " x" (legion_window_width + legion_list_width - 3)*square_coords[1] " y" (legion_window_width + legion_list_width - 3)*square_coords[2] " h" (legion_window_width + legion_list_width - 3)/18 " w" (legion_window_width + legion_list_width - 3)/18, % A_Space
		Gui, legion_treemap: Add, Text, % "BackgroundTrans Right cYellow vlegion_socket_text" A_Index "overlap x" (legion_window_width + legion_list_width - 3)*square_coords[1] " y" (legion_window_width + legion_list_width - 3)*square_coords[2] " h" (legion_window_width + legion_list_width - 3)/18 " w" (legion_window_width + legion_list_width - 3)/18, % A_Space
		Gui, legion_treemap: Add, Picture, % "BackgroundTrans gLegion_seeds_sockets vlegion_socket" A_Index " x" (legion_window_width + legion_list_width - 3)*square_coords[1] " y" (legion_window_width + legion_list_width - 3)*square_coords[2] " h" (legion_window_width + legion_list_width - 3)/18 " w" (legion_window_width + legion_list_width - 3)/18, % style
	}
	GoSub, Legion_seeds
	Gui, legion_treemap: Show, % "Hide x"xScreenOffset " y"yScreenOffSet + poe_height - (legion_window_width + legion_list_width) + 1
	Gui, legion_treemap2: Show, % "NA x"xScreenOffset " y"yScreenOffSet + poe_height - legion_window_width
	LLK_Overlay("legion_treemap2", "show")
}
Return

Legion_seeds3: ;create list of all modifications or notables
If !WinExist("ahk_id " hwnd_legion_list)
{
	GuiControl, legion_window: text, legion_toggle, % " < "
	Gui, legion_list: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_legion_list
	Gui, legion_list: Margin, 12, 0
	Gui, legion_list: Color, Black
	WinSet, Transparent, %trans%
	Gui, legion_list: Font, % "s"fSize0 + fSize_offset_legion " cWhite underline", Fontin SmallCaps
	Gui, legion_list: Add, Text, % "Section BackgroundTrans y4 vlegion_list_header", notables around socket:
	Gui, legion_list: Font, norm

	Loop, 45
	{
		If (A_Index = 1)
			Gui, legion_list: Add, Text, % "xs BackgroundTrans gLegion_seeds_help vlegion_list_text" A_Index " y+4", night of a thousand ribbons
		Else Gui, legion_list: Add, Text, % "xs BackgroundTrans gLegion_seeds_help wp vlegion_list_text" A_Index, % ""
	}
}

If (legion_socket = "")
{
	GuiControl, legion_list: text, legion_list_header, notable modifications:
	
	IniRead, legion_notables, data\timeless jewels\jewels.ini, % legion_type_parse
	legion_notables_list := ""
	loops := 0
	Loop, Parse, legion_notables, `n, `n
	{
		IniRead, legion_notable%A_Index%, data\timeless jewels\jewels.ini, % legion_type_parse, % A_Index
		legion_notables_list .= (legion_notables_list = "") ? legion_notable%A_Index% : "," legion_notable%A_Index%
	}

	Sort, legion_notables_list, D`,
	Loop, Parse, legion_notables_list, CSV
	{
		loops += 1
		GuiControl, legion_list: text, legion_list_text%A_Index%, % A_Loopfield
		If InStr(legion_%legion_type_parse2%_favs, A_Loopfield ",")
			GuiControl, legion_list: +cAqua, legion_list_text%A_Index%
		Else GuiControl, legion_list: +cWhite, legion_list_text%A_Index%
	}
	Loop 45
	{
		If (A_Index <= loops)
			continue
		GuiControl, legion_list: text, legion_list_text%A_Index%, % ""
	}
}
Else
{
	IniRead, legion_%legion_socket%_favs, ini\timeless jewels.ini, favorites%legion_profile%, % legion_socket, % A_Space
	GuiControl, legion_list: text, legion_list_header, notables around socket:
	legion_notables_socket_array := []
	loops := 0
	IniRead, legion_notables_socket, data\timeless jewels\sockets.ini, % legion_socket
	Loop, Parse, legion_notables_socket, `n, `n
	{
		loops += 1
		legion_notables_socket_array.Push(A_Loopfield)
		target_column := LLK_ArrayHasVal(legion_notables_array, A_LoopField)
		target_key := legion_csvline_array[target_column]
		GuiControl, legion_list: text, legion_list_text%A_Index%, % A_Loopfield
		If InStr(legion_%legion_type_parse2%_favs, legion_%legion_type_parse2%_mod%target_key% ",") && InStr(legion_%legion_socket%_favs, A_Loopfield ",")
			GuiControl, legion_list: +cYellow, legion_list_text%A_Index%
		Else If InStr(legion_%legion_socket%_favs, A_Loopfield ",")
			GuiControl, legion_list: +cAqua, legion_list_text%A_Index%
		Else GuiControl, legion_list: +cWhite, legion_list_text%A_Index%
	}
	Loop 45
	{
		If (A_Index <= loops)
			continue
		GuiControl, legion_list: text, legion_list_text%A_Index%, % ""
	}
}

If !WinExist("ahk_id " hwnd_legion_list)
{
	Gui, legion_list: Show, % "NA x" xScreenOffSet + legion_window_width - 1 " y" yScreenOffSet " h"poe_height - 2
	LLK_Overlay("legion_list", "show")
}
WinGetPos,,, legion_list_width,, ahk_id %hwnd_legion_list%
Return

Legion_seeds_help:
Gui, legion_help: Destroy
GuiControlGet, modtext, %A_Gui%:, % A_GuiControl
If (modtext = "" || modtext = " ") || InStr(modtext, "+5 devotion")
	Return
If (click = 2) ;right-click notable labels to mark as desired
{
	If InStr(A_GuiControl, "keystone")
		Return
	GuiControlGet, modtext, %A_Gui%:, % A_GuiControl
	modtext := InStr(modtext, "x)") ? SubStr(modtext, 1, -5) : modtext
	If LLK_ArrayHasVal(legion_notables_socket_array, modtext)
	{
		If InStr(legion_%legion_socket%_favs, modtext)
			GuiControl, %A_Gui%: +cWhite, % A_GuiControl
		Else
			GuiControl, %A_Gui%: +cAqua, % A_GuiControl
		legion_%legion_socket%_favs := InStr(legion_%legion_socket%_favs, modtext) ? StrReplace(legion_%legion_socket%_favs, modtext ",") : (legion_%legion_socket%_favs = "") ? modtext "," : legion_%legion_socket%_favs modtext ","
		IniWrite, % legion_%legion_socket%_favs, ini\timeless jewels.ini, favorites%legion_profile%, % legion_socket
	}
	Else
	{
		If InStr(legion_%legion_type_parse2%_favs, modtext)
		{
			GuiControl, legion_window: +cWhite, % A_GuiControl
			GuiControl, %A_Gui%: +cWhite, % A_GuiControl
		}
		Else
		{
			GuiControl, legion_window: +cAqua, % A_GuiControl
			GuiControl, %A_Gui%: +cAqua, % A_GuiControl
		}
		legion_%legion_type_parse2%_favs := InStr(legion_%legion_type_parse2%_favs, modtext) ? StrReplace(legion_%legion_type_parse2%_favs, modtext ",") : (legion_%legion_type_parse2%_favs = "") ? modtext "," : legion_%legion_type_parse2%_favs modtext ","
		IniWrite, % legion_%legion_type_parse2%_favs, ini\timeless jewels.ini, favorites%legion_profile%, % legion_type_parse
	}
	GoSub, Legion_seeds
	Return
}

GuiControlGet, modtext, %A_Gui%:, % A_GuiControl
If (InStr(A_GuiControl, "legion_modtext") || LLK_ArrayHasVal(legion_notables_socket_array, modtext)) && (modtext != "") && !InStr(modtext, "+5 devotion") ;click mod labels to highlight affected notables on the in-game passive tree
{
	If !InStr(A_GuiControl, "legion_modtext") && !LLK_ArrayHasVal(legion_notables_socket_array, modtext)
		Return
	
	modtext := InStr(modtext, "x)") ? SubStr(modtext, 1, -5) : modtext

	legion_highlight := ""
	target_code := LLK_ArrayHasVal(legion_encode_array, modtext)
	Loop, Parse, % LLK_ArrayHasVal(legion_csvline_array, target_code, 1), `,, `,
	{
		If (A_Loopfield = "")
			break
		If InStr(legion_socket_notables, legion_notables_array[A_Loopfield] "`n") || (SubStr(legion_socket_notables, -StrLen(legion_notables_array[A_Loopfield])+1) = legion_notables_array[A_Loopfield])
			legion_highlight .= legion_notables_array[A_Loopfield] "|"
	}
	
	legion_highlight := LLK_ArrayHasVal(legion_notables_socket_array, modtext) ? modtext : legion_highlight
	If (legion_highlight != "")
	{
		legion_highlight := LLK_ArrayHasVal(legion_notables_socket_array, modtext) ? legion_highlight : SubStr(legion_highlight, 1, -1)
		legion_highlight := StrReplace(legion_highlight, " ", ".")
		legion_highlight = notable ^(%legion_highlight%)
		WinActivate, ahk_group poe_window
		WinWaitActive, ahk_group poe_window
		sleep, 50
		clipboard := legion_highlight
		ClipWait, 0.05
		SendInput, ^{f}^{v}{Enter}
	}
}
If InStr(modtext, "+5 devotion")
	LLK_ToolTip("cannot highlight devotion nodes", 2)
Return

Legion_seeds_hover:
MouseGetPos, mouseXpos, mouseYpos,
Gui, legion_help: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_legion_help
Gui, legion_help: Color, Black
Gui, legion_help: Margin, 0, 0
Gui, legion_help: Font, % "s"fSize1 + fSize_offset_legion " cWhite", Fontin SmallCaps

GuiControlGet, modtext,, % hwnd_control_hover
modtext := InStr(modtext, "x)") ? SubStr(modtext, 1, -5) : modtext
If (modtext = "") || (!LLK_ArrayHasVal(legion_tooltips_array, modtext) && !LLK_ArrayHasVal(legion_notables_socket_array, modtext))
{
	Gui, legion_help: Destroy
	Return
}

width_hover := (fSize0 + fSize_offset_legion)*25

If !LLK_ArrayHasVal(legion_notables_socket_array, modtext)
{
	IniRead, text, data\timeless jewels\mod descriptions.ini, descriptions, % modtext, 0
	Loop, Parse, text, ?, ?
	{
		If (A_Loopfield = "")
			continue
		If (A_Index = 1)
			Gui, legion_help: Add, Text, % "BackgroundTrans Center Border w"width_hover, % (text = 0) ? "n/a" : A_Loopfield
		Else Gui, legion_help: Add, Text, % "BackgroundTrans Center Border y+-1 w"width_hover, % (text = 0) ? "n/a" : A_Loopfield
	}
}
Else
{
	target_column := LLK_ArrayHasVal(legion_notables_array, modtext)
	target_key := legion_csvline_array[target_column]
	Gui, legion_help: Add, Text, % "BackgroundTrans Center Border w"width_hover, % legion_%legion_type_parse2%_mod%target_key%
	IniRead, text, data\timeless jewels\mod descriptions.ini, descriptions, % legion_%legion_type_parse2%_mod%target_key%, 0
	If (text != 0)
	{
		Loop, Parse, text, ??, ??
		{
			If (A_Loopfield = "")
				continue
			Gui, legion_help: Add, Text, % "BackgroundTrans Center Border y+-1 w"width_hover, % A_Loopfield
		}
	}
}
mouseYpos := (mouseYpos < yScreenOffSet + poe_height/2) ? mouseYpos : (mouseYpos - yScreenOffSet)*0.95
Gui, legion_help: Show, % "NA x"mouseXpos + fSize0*2 " y"mouseYpos " AutoSize"

If (hwnd_win_hover != hwnd_legion_window)
	SetTimer, Legion_seeds_hover_check
Return

Legion_seeds_hover_check:
MouseGetPos,,, hwnd_win_hover2,, 2
If (hwnd_win_hover2 != hwnd_legion_treemap) && (hwnd_win_hover2 != hwnd_legion_list)
{
	Gui, legion_help: Destroy
	hwnd_legion_help := ""
	LLK_Overlay("legion_treemap", "hide")
	SetTimer, Legion_seeds_hover_check, Delete
}
Return

Legion_seeds_parse:
If (click = 2) ;right-click button to open trade site with currently loaded jewel
{
	legion_trade := "{%22query%22:{%22status%22:{%22option%22:%22any%22},%22stats%22:[{%22type%22:%22count%22,%22filters%22:[{%22id%22:%22explicit.pseudo_timeless_jewel_" legion_name1 "%22,%22value%22:{%22min%22:" legion_seed_parse ",%22max%22:" legion_seed_parse
	legion_trade .= "},%22disabled%22:false},{%22id%22:%22explicit.pseudo_timeless_jewel_" legion_name2 "%22,%22value%22:{%22min%22:" legion_seed_parse ",%22max%22:" legion_seed_parse
	legion_trade .= "},%22disabled%22:false},{%22id%22:%22explicit.pseudo_timeless_jewel_" legion_name3 "%22,%22value%22:{%22min%22:" legion_seed_parse ",%22max%22:" legion_seed_parse "},%22disabled%22:false}],%22value%22:{%22min%22:1}}]},%22sort%22:{%22price%22:%22asc%22}}"
	Run, https://www.pathofexile.com/trade/search/Sentinel?q=%legion_trade%
	Return
}
If !InStr(clipboard, "limited to: 1 historic")
{
	LLK_ToolTip("no timeless jewel in clipboard", 2)
	Return
}

parse_mode := InStr(clipboard, "{ unique modifier }") ? 0 : 1
	
unique_mod_line := ""
IniRead, legion_leaders_ini, data\timeless jewels\jewels.ini, names
legion_leaders := ""
Loop, Parse, legion_leaders_ini, `n, `n
	legion_leaders .= SubStr(A_Loopfield, 1, InStr(A_Loopfield, "=") -1) ","

If (parse_mode = 0) ;parsing the clipboard data when retrieved via context-menu
{
	Loop, Parse, clipboard, `n, `r`n
	{
		If (A_Index = 3)
			legion_type_parse := A_Loopfield
		If (A_Loopfield = "{ unique modifier }")
			unique_mod_line := A_Index
		If (unique_mod_line = A_Index - 1)
		{
			parse_line := A_Loopfield
			break
		}
	}
}
Else ;parsing the clipboard data when retrieved via ctrl-c or from the trade site
{
	Loop, Parse, clipboard, `n, `r`n
	{
		If (A_Index = 3)
			legion_type_parse := A_Loopfield
		If InStr(A_Loopfield, "item level:") || InStr(A_Loopfield, "(implicit)")
			unique_mod_line := A_Index
		If (unique_mod_line = A_Index - 2)
		{
			parse_line := A_Loopfield
			break
		}
	}	
}

StringLower, legion_type_parse, legion_type_parse
legion_seed_parse := ""
Loop, Parse, parse_line ;parse seed from the relevant line
{
	If IsNumber(A_Loopfield)
		legion_seed_parse .= A_Loopfield
	If !IsNumber(A_Loopfield) && (legion_seed_parse != "")
		break
}

Loop, Parse, legion_leaders, `,, `, ;parse name from clipboard data
{
	If ((parse_mode = 0) && InStr(clipboard, A_Loopfield "(")) || ((parse_mode = 1) && InStr(clipboard, A_Loopfield))
	{
		legion_name_parse := A_Loopfield
		break
	}
}

GoSub, Legion_seeds
GoSub, Legion_seeds2
If WinExist("ahk_id " hwnd_legion_list)
	GoSub, Legion_seeds3
If (A_Gui = "")
	LLK_ToolTip("success", 0.5)
Return

Legion_seeds_sockets:
legion_socket := StrReplace(A_GuiControl, "legion_")
If (previous_socket != "")
	GuiControl,, % previous_socket, img\GUI\square_blank.png
If (A_GuiControl = previous_socket)
{
	GuiControl,, % A_GuiControl, img\GUI\square_blank.png
	legion_socket := ""
	previous_socket := ""
	WinActivate, ahk_group poe_window
	WinWaitActive, ahk_group poe_window
	SendInput, ^{f}{ESC}
	GoSub, Legion_seeds
	Return
}
Else GuiControl,, % A_GuiControl, img\GUI\square_red.png
previous_socket := A_GuiControl
GoSub, Legion_seeds
Return

Leveling_guide:
start := A_TickCount
While GetKeyState("LButton", "P") && (A_Gui = "leveling_guide_panel") ;dragging the button
{
	If (A_TickCount >= start + 300)
	{
		WinGetPos,,, wGui, hGui, % "ahk_id " hwnd_%A_Gui%
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		leveling_guide_panel_xpos := panelXpos
		leveling_guide_panel_ypos := panelYpos
		IniWrite, % leveling_guide_panel_xpos, ini\leveling tracker.ini, UI, button xcoord
		IniWrite, % leveling_guide_panel_ypos, ini\leveling tracker.ini, UI, button ycoord
		WinActivate, ahk_group poe_window
		Return
	}
}
If (A_Gui = "leveling_guide_panel") && (click = 1) ;left-clicking the button
{
	If WinExist("ahk_id " hwnd_leveling_guide2)
	{
		;LLK_Overlay("leveling_guide1", "hide")
		LLK_Overlay("leveling_guide2", "hide")
		LLK_Overlay("leveling_guide3", "hide")
		WinActivate, ahk_group poe_window
		Return
	}
	If !WinExist("ahk_id " hwnd_leveling_guide2) || (A_Gui = "settings_menu")
	{
		If (hwnd_leveling_guide2 = "")
			GoSub, Leveling_guide_progress
		Else
		{
			;LLK_Overlay("leveling_guide1", "show")
			LLK_Overlay("leveling_guide2", "show")
			LLK_Overlay("leveling_guide3", "show")
		}
		WinActivate, ahk_group poe_window
	}
	Return
}

If (A_Gui = "leveling_guide_panel") && (click = 2) ;right-clicking the button
{
	GoSub, Leveling_guide_gear
	Return
}

If (A_GuiControl = "enable_leveling_guide") ;checking the enable-checkbox in the settings menu
{
	Gui, settings_menu: Submit, NoHide
	GoSub, GUI
	IniWrite, % enable_leveling_guide, ini\config.ini, Features, enable leveling guide
	If (enable_leveling_guide = 0)
	{
		Gui, leveling_guide2: Destroy
		Gui, leveling_guide3: Destroy
		hwnd_leveling_guide2 := ""
		hwnd_leveling_guide3 := ""
		Gui, gear_tracker: Destroy
		hwnd_gear_tracker := ""
		Gui, gear_tracker_indicator: Destroy
		hwnd_gear_tracker_indicator := ""
		gear_tracker_char := ""
		IniWrite, % "", ini\leveling tracker.ini, Settings, character
	}
	GoSub, Settings_menu
	Return
}
If (A_GuiControl = "leveling_guide_generate") ;generate-button in the settings menu
{
	Run, https://heartofphos.github.io/exile-leveling/
	Return
}
If (A_GuiControl = "leveling_guide_import") ;import-button in the settings menu
{
	Gui, leveling_guide1: Destroy
	Gui, leveling_guide2: Destroy
	Gui, leveling_guide3: Destroy
	hwnd_leveling_guide1 := ""
	hwnd_leveling_guide2 := ""
	hwnd_leveling_guide3 := ""
	build_gems_skill_str := ""
	build_gems_supp_str := ""
	build_gems_skill_dex := ""
	build_gems_supp_dex := ""
	build_gems_skill_int := ""
	build_gems_supp_int := ""
	FileRead, json_areas, data\leveling tracker\areas.json
	FileRead, json_gems, data\leveling tracker\gems.json
	FileRead, json_quests, data\leveling tracker\quests.json
	json_import := (SubStr(clipboard, 1, 2) = "[[") ? clipboard : ""
	If (json_import = "")
	{
		LLK_ToolTip("invalid import data")
		json_areas := ""
		json_gems := ""
		json_quests := ""
		Return
	}

	parsed := Json.Load(json_import)
	areas := Json.Load(json_areas)
	gems := Json.Load(json_gems)
	quests := Json.Load(json_quests)
	guide_text := ""

	Loop, % parsed.Length() ;parse all acts
	{
		loop := A_Index
		Loop, % parsed[loop].Length() ;parse steps in individual acts
		{
			step := parsed[loop][A_Index]
			step_text := ""
			If (step.type = "fragment_step")
			{
				parts := step.parts
				Loop, % parts.Length()
				{
					If !IsObject(parts[A_Index])
					{
						If (SubStr(parts[A_Index], -3) = "get ")
							text := StrReplace(parts[A_Index], "get ", "activate the ")
						Else If (InStr(parts[A_Index], "take") && InStr(step_text, "kill")) ;omit quest-items related to killing bosses
							text := ""
						Else text := InStr(parts[A_Index], " ➞ ") ? StrReplace(parts[A_Index], " ➞", ", enter") : StrReplace(parts[A_Index], "➞", "enter")
						step_text .= text
					}
					Else
					{
						type := parts[A_Index].type
						value := parts[A_Index].value
						areaID := parts[A_Index].areaId
						target_areaID := parts[A_Index].targetAreaId
						questID := parts[A_Index].questId
						version := parts[A_Index].version
						direction := StrReplace(parts[A_Index].dirIndex, 0, "north,")
						direction := StrReplace(direction, 1, "north-east,")
						direction := StrReplace(direction, 2, "east,")
						direction := StrReplace(direction, 3, "south-east,")
						direction := StrReplace(direction, 4, "south,")
						direction := StrReplace(direction, 5, "south-west,")
						direction := !InStr(step_text, "follow") && !InStr(step_text, "search") ? StrReplace(direction, 6, "west,") : StrReplace(direction, 6, "west")
						direction := StrReplace(direction, 7, "north-west,")
						Switch type  ;thing I never knew existed but really wanted
						{
							Case "enter":
								step_text .= "areaID" areaID
							Case "kill":
								step_text .= InStr(value, ",") ? SubStr(parts[A_Index].value, 1, InStr(parts[A_Index].value, ",") - 1) : StrReplace(value, "alira darktongue", "alira") ;shorten boss names
							Case "quest":
								step_text .= quests[questID].name
							Case "quest_text":
								step_text .= !InStr(step_text, "kill") ? value : "" ;omit quest-items related to killing bosses
							Case "get_waypoint":
								step_text .= "waypoint"
							Case "waypoint":
								step_text .= (areaID != "") ? "waypoint-travel to areaID" areaID : InStr(step_text, "for the broken") ? "waypoint" : "the waypoint"
							Case "logout":
								step_text .= "relog, enter areaID" areaID
							Case "portal":
								If (target_areaID = "")
									step_text .= "portal"
								Else step_text .= "portal to areaID" target_areaID
							Case "trial":
								step_text .= "the lab-trial"
							Case "arena":
								step_text .= value
							Case "area":
								step_text .= areas[areaID].name
							Case "dir":
								step_text .= direction
							Case "crafting":
								step_text .= "crafting recipe"
							Case "generic":
								step_text .= value
							Case "ascend":
								step_text .= "enter and complete the " version " lab"
						}
					}
				}
			}
			If (step.type = "gem_step")
			{
				rewardType := step.rewardType
				gemID := step.requiredGem.id
				step_text .= (rewardType = "vendor") ? "buy " : "take reward: "
				step_text .= gems[gemID].name
				Switch gems[gemID].primary_attribute ;group gems into strings for search-strings feature
				{
					Case "strength":
						If !InStr(gems[gemID].name, "support")
							build_gems_skill_str .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
						If InStr(gems[gemID].name, "support")
							build_gems_supp_str .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
					Case "dexterity":
						If !InStr(gems[gemID].name, "support")
							build_gems_skill_dex .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
						If InStr(gems[gemID].name, "support")
							build_gems_supp_dex .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
					Case "intelligence":
						If !InStr(gems[gemID].name, "support")
							build_gems_skill_int .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
						If InStr(gems[gemID].name, "support") || InStr(gems[gemID].name, "arcanist brand")
							build_gems_supp_int .= (gems[gemID].required_level < 10) ? "(0" gems[gemID].required_level ")" gems[gemID].name "," : "(" gems[gemID].required_level ")" gems[gemID].name ","
				}
			}
			guide_text .= StrReplace(step_text, ",,", ",") "`n"
		}
	}
	
	build_gems_all := build_gems_skill_str build_gems_supp_str build_gems_skill_dex build_gems_supp_dex build_gems_skill_int build_gems_supp_int ;create single gem-string for gear tracker feature
	
	IniDelete, ini\leveling tracker.ini, Gems
	IniDelete, ini\stash search.ini, tracker_gems
	IniRead, placeholder, ini\stash search.ini, Settings, vendor, % A_Space
	If InStr(placeholder, "(tracker_gems)")
		IniWrite, % StrReplace(placeholder, "(tracker_gems),"), ini\stash search.ini, Settings, vendor
	If (build_gems_all != "")
	{
		Sort, build_gems_all, D`, P2 N
		Sort, build_gems_skill_str, D`, P2 N
		Sort, build_gems_supp_str, D`, P2 N
		Sort, build_gems_skill_dex, D`, P2 N
		Sort, build_gems_supp_dex, D`, P2 N
		Sort, build_gems_skill_int, D`, P2 N
		Sort, build_gems_supp_int, D`, P2 N
		
		build_gems_all := StrReplace(build_gems_all, ")", ") ")	
		build_gems_all := StrReplace(build_gems_all, " support", "")	
		IniWrite, % SubStr(StrReplace(build_gems_all, ",", "`n"), 1, -1), ini\leveling tracker.ini, Gems ;save gems for gear tracker feature
	}
	
	parse := "skill_str,supp_str,skill_dex,supp_dex,skill_int,supp_int"
	
	search_string_skill_str := ""
	search_string_supp_str := ""
	search_string_skill_dex := ""
	search_string_supp_dex := ""
	search_string_skill_int := ""
	search_string_supp_int := ""
	search_string_all := ""
	
	If (all_gems = "")
		FileRead, all_gems, data\leveling tracker\gems.txt
	
	Loop, Parse, parse, `,, `, ;create advanced search-string
	{
		loop := A_Loopfield
		parse_string := ""
		If (build_gems_%A_Loopfield% = "")
			continue
		Loop, Parse, build_gems_%A_Loopfield%, `,, `,
		{
			If (A_Loopfield = "")
				break
			parse_gem := SubStr(A_Loopfield, 5)
			Loop, Parse, parse_gem
			{
				If (parse_gem = "arc") && (A_Index = 1)
				{
					parse_gem := "arc$"
					break
				}
				If (A_Index = 1)
					parse_gem := ""
				parse_gem .= A_Loopfield
				If (LLK_SubStrCount(all_gems, parse_gem, "`n", 1) = 1) && (StrLen(parse_gem) >= 3)
					break
			}
			If (StrLen(parse_string parse_gem) <= 47)
				parse_string .= parse_gem "|"
			Else
			{
				search_string_%loop% .= "^(" StrReplace(SubStr(parse_string, 1, -1), " ", ".") ");"
				parse_string := parse_gem "|"
			}
		}
		search_string_%loop% .= "^(" StrReplace(SubStr(parse_string, 1, -1), " ", ".") ")"
	}
	
	Loop, Parse, parse, `,, `,
	{
		If (search_string_%A_Loopfield% != "")
			search_string_all .= search_string_%A_Loopfield% ";"
	}
	
	If (search_string_all != "")
	{
		search_string_all := SubStr(search_string_all, 1, -1)
		IniRead, placeholder, ini\stash search.ini, Settings, vendor, % A_Space
		If !InStr(placeholder, "(tracker_gems)")
			IniWrite, % placeholder "(tracker_gems),", ini\stash search.ini, Settings, vendor
		IniWrite, 1, ini\stash search.ini, tracker_gems, enable
		IniWrite, "%search_string_all%", ini\stash search.ini, tracker_gems, string 1
		IniWrite, 1, ini\stash search.ini, tracker_gems, string 1 enable scrolling
		IniWrite, "", ini\stash search.ini, tracker_gems, string 2
		IniWrite, 0, ini\stash search.ini, tracker_gems, string 2 enable scrolling
	}
	
	guide_text := StrReplace(guide_text, "&", "&&")
	StringLower, guide_text, guide_text
	IniDelete, ini\leveling guide.ini, Steps
	IniWrite, % guide_text, ini\leveling guide.ini, Steps
	
	If (guide_progress = "")
		IniRead, guide_progress, ini\leveling guide.ini, Progress,, % A_Space
	IniRead, guide_text_original, ini\leveling guide.ini, Steps,, % A_Space
	guide_progress_percent := (guide_progress != "" & guide_text_original != "") ? Format("{:0.2f}", (LLK_InStrCount(guide_progress, "`n")/LLK_InStrCount(guide_text_original, "`n"))*100) : 0
	guide_progress_percent := (guide_progress_percent >= 99) ? 100 : guide_progress_percent
	GuiControl, settings_menu:, leveling_guide_progress, % "current progress: " guide_progress_percent "%"
	
	guide_text := ""
	parsed := ""
	areas := ""
	gems := ""
	quests := ""
	json_areas := ""
	json_gems := ""
	json_quests := ""
	clipboard := ""
	LLK_ToolTip("success")
	Return
}
If (A_GuiControl = "leveling_guide_reset") ;reset-button in the settings menu
{
	IniDelete, ini\leveling guide.ini, Progress
	guide_progress := ""
	GuiControl, settings_menu:, leveling_guide_progress, % "current progress: 0%"
	hwnd_leveling_guide2 := ""
	guide_panel1_text := "n/a"
	GoSub, Leveling_guide_progress
	Return
}
If InStr(A_GuiControl, "button_leveling_guide") ;button-settings in the settings menu
{
	If (A_GuiControl = "button_leveling_guide_minus")
		leveling_guide_panel_offset -= (leveling_guide_panel_offset > 0.4) ? 0.1 : 0
	If (A_GuiControl = "button_leveling_guide_reset")
		leveling_guide_panel_offset := 1
	If (A_GuiControl = "button_leveling_guide_plus")
		leveling_guide_panel_offset += (leveling_guide_panel_offset < 1) ? 0.1 : 0
	IniWrite, % leveling_guide_panel_offset, ini\leveling tracker.ini, Settings, button-offset
	leveling_guide_panel_dimensions := poe_width*0.03*leveling_guide_panel_offset
	GoSub, GUI
	Return
}
;UI-settings in the settings menu
If (A_GuiControl = "fSize_leveling_guide_minus")
{
	fSize_offset_leveling_guide -= 1
	IniWrite, %fSize_offset_leveling_guide%, ini\leveling tracker.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_leveling_guide_plus")
{
	fSize_offset_leveling_guide += 1
	IniWrite, %fSize_offset_leveling_guide%, ini\leveling tracker.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_leveling_guide_reset")
{
	fSize_offset_leveling_guide := 0
	IniWrite, %fSize_offset_leveling_guide%, ini\leveling tracker.ini, Settings, font-offset
}
If (A_GuiControl = "leveling_guide_opac_minus")
{
	leveling_guide_trans -= (leveling_guide_trans > 100) ? 30 : 0
	IniWrite, %leveling_guide_trans%, ini\leveling tracker.ini, Settings, transparency
}
If (A_GuiControl = "leveling_guide_opac_plus")
{
	leveling_guide_trans += (leveling_guide_trans < 250) ? 30 : 0
	IniWrite, %leveling_guide_trans%, ini\leveling tracker.ini, Settings, transparency
}
If InStr(A_GuiControl, "fontcolor_")
{
	leveling_guide_fontcolor := StrReplace(A_GuiControl, "fontcolor_", "")
	IniWrite, %leveling_guide_fontcolor%, ini\leveling tracker.ini, Settings, font-color
}
If InStr(A_GuiControl, "leveling_guide_position_")
{
	leveling_guide_position := StrReplace(A_GuiControl, "leveling_guide_position_")
	IniWrite, % leveling_guide_position, ini\leveling tracker.ini, Settings, overlay-position
}
fSize_leveling_guide := fSize0 + fSize_offset_leveling_guide
If (hwnd_leveling_guide2 != "")
{
	hwnd_leveling_guide2 := ""
	GoSub, Leveling_guide_progress
}
If (hwnd_gear_tracker != "")
{
	hwnd_gear_tracker := ""
	GoSub, Leveling_guide_gear
}
Return

Leveling_guide_gear:
start := A_TickCount
While GetKeyState("LButton", "P") && (A_Gui = "gear_tracker_indicator") ;dragging the gear tracker indicator
{
	If (A_TickCount >= start + 300)
	{
		WinGetPos,,, wGui, hGui, % "ahk_id " hwnd_%A_Gui%
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		gear_tracker_indicator_xpos := panelXpos
		gear_tracker_indicator_ypos := panelYpos
		IniWrite, % gear_tracker_indicator_xpos, ini\leveling tracker.ini, UI, indicator xcoord
		IniWrite, % gear_tracker_indicator_ypos, ini\leveling tracker.ini, UI, indicator ycoord
		WinActivate, ahk_group poe_window
		Return
	}
}

If (A_Gui = "gear_tracker_indicator")
	Return

If InStr(A_GuiControl, "select character") ;clicking the 'select character' label to highlight all gear upgrades
{
	If (gear_tracker_parse = "`n")
		Return
	regex_length := Floor((47 - gear_tracker_count)/gear_tracker_count)
	regex_string := "^("
	Loop, Parse, gear_tracker_parse, `n, `n
	{
		If (A_Loopfield = "")
			continue
		
		If (SubStr(A_Loopfield, 2, 2) <= gear_tracker_characters[gear_tracker_char])
		{
			If (SubStr(A_Loopfield, 6) = "arc")
			{
				regex_string .= "arc$|"
				continue
			}
			regex_string .= InStr(A_Loopfield, ":") ? SubStr(A_Loopfield, InStr(A_Loopfield, ":") + 2, regex_length) "|" : SubStr(A_Loopfield, 6, regex_length) "|"
		}
	}
	regex_string := StrReplace(SubStr(regex_string, 1, -1), " ", ".") ")"
	If (StrLen(regex_string) <= 3)
	{
		LLK_ToolTip("nothing to highlight")
		Return
	}
	clipboard := regex_string
	KeyWait, LButton
	WinActivate, ahk_group poe_window
	WinWaitActive, ahk_group poe_window
	SendInput, ^{f}^{v}
	Return
}

If (A_Gui = "gear_tracker") && (A_GuiControl != "gear_tracker_char") ;clicking anything but the drop-down list
{
	If (click = 1)
	{
		clipboard := (SubStr(A_GuiControl, 6) = "arc") ? "arc$" : InStr(A_GuiControl, ":") ? SubStr(A_GuiControl, InStr(A_GuiControl, ":") + 2, 47) : SubStr(A_GuiControl, 6, 47)
		KeyWait, LButton
		WinActivate, ahk_group poe_window
		WinWaitActive, ahk_group poe_window
		SendInput, ^{f}^{v}
		Return
	}
	Else
	{
		IniRead, gear_tracker_items, ini\leveling tracker.ini, gear,, % A_Space
		IniRead, gear_tracker_gems, ini\leveling tracker.ini, gems,, % A_Space
		If InStr(gear_tracker_items, A_GuiControl)
		{
			gear_tracker_items := InStr(gear_tracker_items, A_GuiControl "`n") ? StrReplace(gear_tracker_items, A_GuiControl "`n") : StrReplace(gear_tracker_items, A_GuiControl)
			IniDelete, ini\leveling tracker.ini, gear
			IniWrite, % gear_tracker_items, ini\leveling tracker.ini, gear
		}
		If InStr(gear_tracker_gems, A_GuiControl)
		{
			gear_tracker_gems := InStr(gear_tracker_gems, A_GuiControl "`n") ? StrReplace(gear_tracker_gems, A_GuiControl "`n") : StrReplace(gear_tracker_gems, A_GuiControl)
			IniDelete, ini\leveling tracker.ini, gems
			IniWrite, % gear_tracker_gems, ini\leveling tracker.ini, gems
		}
		GoSub, Log_loop
	}
}

If (A_GuiControl = "gear_tracker_char") ;clicking the drop-down list
{
	Gui, gear_tracker: Submit, NoHide
	gear_tracker_char := SubStr(gear_tracker_char, 1, InStr(gear_tracker_char, "(") - 2)
	IniWrite, % gear_tracker_char, ini\leveling tracker.ini, Settings, character
}

If (WinExist("ahk_id " hwnd_gear_tracker) && (A_Gui != "gear_tracker") && (update_gear_tracker != 1))
{
	LLK_GearTrackerGUI(1)
	GoSub, Log_loop
	Gui, gear_tracker: Destroy
	hwnd_gear_tracker := ""
	WinActivate, ahk_group poe_window
	Return
}
Else
{
	LLK_GearTrackerGUI()
	update_gear_tracker := 0
	GoSub, Log_loop
	Gui, gear_tracker: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_gear_tracker
	Gui, gear_tracker: Margin, 12, 4
	Gui, gear_tracker: Color, Black
	WinSet, Transparent, %leveling_guide_trans%
	Gui, gear_tracker: Font, % "cWhite s"fSize_leveling_guide, Fontin SmallCaps
	gear_tracker_DDL := ""
	For a, b in gear_tracker_characters
		gear_tracker_DDL .= (a = gear_tracker_char) ? a " (" b ")||" : a " (" b ")|"
	;gear_tracker_DDL := (SubStr(gear_tracker_DDL, -2) = "||") ? SubStr(gear_tracker_DDL, 1, -2) : SubStr(gear_tracker_DDL, 1, -1)
	Gui, gear_tracker: Add, Text, % "Section BackgroundTrans gLeveling_guide_gear", % "select character: "
	Gui, gear_tracker: Font, % "s"fSize_leveling_guide - 4
	Gui, gear_tracker: Add, DDL, % "ys x+0 BackgroundTrans cBlack vgear_tracker_char gLeveling_guide_gear wp hp r"gear_tracker_characters.Count(), % gear_tracker_DDL
	Gui, gear_tracker: Add, Picture, ys BackgroundTrans vMap_info vgear_tracker_help gSettings_menu_help hp w-1, img\GUI\help.png
	Gui, gear_tracker: Font, % "s"fSize_leveling_guide
	
	IniRead, gear_tracker_items, ini\leveling tracker.ini, gear,, % A_Space
	IniRead, gear_tracker_gems, ini\leveling tracker.ini, gems,, % A_Space
	
	gear_tracker_parse := gear_tracker_items "`n" gear_tracker_gems
	Sort, gear_tracker_parse, P2 D`n N
	StringLower, gear_tracker_parse, gear_tracker_parse
	Loop, Parse, gear_tracker_parse, `n, `n
	{
		If (A_Loopfield = "")
			continue
		If (SubStr(A_Loopfield, 2, 2) < gear_tracker_characters[gear_tracker_char] + 6)
			Gui, gear_tracker: Add, Text, % (SubStr(A_Loopfield, 2, 2) <= gear_tracker_characters[gear_tracker_char]) ? "xs cLime gLeveling_guide_gear BackgroundTrans" : "xs gLeveling_guide_gear BackgroundTrans", % A_Loopfield
	}
	
	If (gear_tracker_parse = "`n")
		Gui, gear_tracker: Add, Text, % "xs BackgroundTrans", % "no items added"
	Gui, gear_tracker: Show, NA x10000 y10000
	WinGetPos,,, width, height, ahk_id %hwnd_gear_tracker%
	Gui, gear_tracker: Show, % "NA xCenter y"yScreenOffSet + poe_height - height

	guilist .= InStr(guilist, "|gear_tracker|") ? "" : "gear_tracker|"
	LLK_Overlay("gear_tracker", "show")
	WinActivate, ahk_group poe_window
}
Return

Leveling_guide_progress:
If (areas = "")
{
	FileRead, json_areas, data\leveling tracker\areas.json
	areas := Json.Load(json_areas)
}
If (A_Gui = "leveling_guide_panel" && hwnd_leveling_guide2 = "") || (A_GuiControl = "leveling_guide_reset") || InStr(A_GuiControl, "jump")
{
	If InStr(A_GuiControl, "jump")
	{
		If (A_GuiControl = "leveling_guide_jump_forward")
		{
			If InStr(guide_panel2_text, "an end to hunger")
				Return
			guide_progress .= (guide_progress = "") ? guide_panel2_text : "`n" guide_panel2_text
		}
		Else
		{
			guide_text := guide_text_original
			guide_progress := StrReplace(guide_progress, "`n" guide_panel1_text)
		}
	}
	IniRead, guide_text_original, ini\leveling guide.ini, Steps,, % A_Space
	;IniRead, guide_text, ini\leveling guide.ini, Steps,, % A_Space
	If (guide_progress = "")
		IniRead, guide_progress, ini\leveling guide.ini, Progress,, % A_Space

	If (guide_text_original = "")
	{
		LLK_ToolTip("no imported guide")
		Return
	}
	guide_text := guide_text_original
	Loop, Parse, guide_progress, `n, `n
	{
		If (A_Loopfield = "")
			break
		guide_text := StrReplace(guide_text, A_LoopField "`n",,, 1)
	}
}
/*
Else
{
	IniRead, guide_text, ini\leveling guide.ini, Steps,, % A_Space
	Loop, Parse, guide_progress, `n, `n
		guide_text := StrReplace(guide_text, A_LoopField "`n",,, 1)
}
*/

If (guide_progress = "")
	guide_panel1_text := "n/a"

Loop, Parse, guide_progress, `n, `n
{
	If (A_LoopField = "")
		break
	If (InStr(A_Loopfield, "enter") || InStr(A_Loopfield, "waypoint-travel") || (InStr(A_Loopfield, "sail to ") && !InStr(A_Loopfield, "wraeclast")) || InStr(A_Loopfield, "portal to")) && !InStr(A_Loopfield, "the warden's chambers") && !InStr(A_Loopfield, "sewer outlet") && !InStr(A_Loopfield, "resurrection site") && !InStr(A_Loopfield, "the black core") && !(InStr(A_Loopfield, "enter") < InStr(A_Loopfield, "kill")) && !(InStr(A_Loopfield, "enter") < InStr(A_Loopfield, "activate")) && !InStr(A_Loopfield, "enter and complete the")
	{
		parsed_step1 .= (parsed_step1 = "") ? A_Loopfield : "`n" A_Loopfield
		guide_section1 := 1
	}
	Else
	{
		parsed_step1 := (guide_section1 = 1) ? A_Loopfield : parsed_step1 "`n" A_Loopfield
		guide_section1 := 0
	}
	
	If (guide_section1 = 1)
	{
		parsed_step1 := (SubStr(parsed_step1, 1, 1) = "`n") ? SubStr(parsed_step1, 2) : parsed_step1
		guide_panel1_text := parsed_step1
		guide_section1 := 0
		parsed_step1 := ""
	}
}

Loop, Parse, guide_text, `n, `n ;check progression and create texts for panels
{
	If (A_Loopfield = "") 
		break
	If (InStr(A_Loopfield, "enter") || InStr(A_Loopfield, "waypoint-travel") || (InStr(A_Loopfield, "sail to ") && !InStr(A_Loopfield, "wraeclast")) || InStr(A_Loopfield, "portal to")) && !InStr(A_Loopfield, "the warden's chambers") && !InStr(A_Loopfield, "sewer outlet") && !InStr(A_Loopfield, "resurrection site") && !InStr(A_Loopfield, "the black core") && !(InStr(A_Loopfield, "enter") < InStr(A_Loopfield, "kill")) && !(InStr(A_Loopfield, "enter") < InStr(A_Loopfield, "activate")) && !InStr(A_Loopfield, "enter and complete the")
	{
		parsed_step .= (parsed_step = "") ? A_Loopfield : "`n" A_Loopfield
		guide_section := 1
	}
	Else
	{
		parsed_step := (guide_section = 1) ? A_Loopfield : parsed_step "`n" A_Loopfield
		guide_section := 0
	}
	
	If (guide_section = 1 || InStr(A_Loopfield, "an end to hunger"))
	{
		parsed_step := (SubStr(parsed_step, 1, 1) = "`n") ? SubStr(parsed_step, 2) : parsed_step
		guide_panel2_text := parsed_step
		guide_section := 0
		parsed_step := ""
		break
	}
}

;text1 := StrReplace(guide_panel1_text, ", kill", "`nkill")
;text1 := ((InStr(text1, ",") > 20) && (StrLen(text1) > 30)) ? StrReplace(text1, ", ", "`n",, 1) : text1
;text1 := "- " StrReplace(text1, "`n", "`n- ")
text1 := "- " StrReplace(guide_panel1_text, "`n", "`n- ")
If InStr(text1, "areaID")
	text1 := LLK_ReplaceAreaID(text1)

;text2 := StrReplace(guide_panel2_text, ", kill", "`nkill")
;text2 := ((InStr(text2, ",") > 20) && (StrLen(text2) > 30)) ? StrReplace(text2, ", ", "`n",, 1) : text2
;text2 := "- " StrReplace(text2, "`n", "`n- ")
text2 := InStr(guide_panel2_text, "`n") ? "- " StrReplace(guide_panel2_text, "`n", "`n- ") : guide_panel2_text
If InStr(text2, "areaID")
	text2 := LLK_ReplaceAreaID(text2)

If LLK_SubStrCount(text2, "buy", "`n") ;check if there are steps for buying gems
{
	search2 := ""
	If (all_gems = "")
		FileRead, all_gems, data\leveling tracker\gems.txt
	loop := 0
	required_gems := LLK_SubStrCount(guide_panel2_text, "buy ", "`n")
	Loop, Parse, guide_panel2_text, `n, `n ;check how many gems fit into the search-string
	{
		If InStr(A_Loopfield, "buy")
		{
			loop += 1
			parse := SubStr(A_Loopfield, InStr(A_Loopfield, "buy") + 4)
			parsed_gem := ""
			Loop, Parse, parse
			{
				If (parse = "arc")
				{
					parse := "arc$"
					break
				}
				parsed_gem .= A_Loopfield
				If (LLK_SubStrCount(all_gems, parsed_gem, "`n", 1) = 1) && (StrLen(parsed_gem) > 2)
				{
					parse := parsed_gem
					break
				}
			}
			If (StrLen(search2 parse) >= 47)
				break
			search2 .= parse "|"
		}
	}
	parsed_gems := LLK_InStrCount(search2, "|")
	skipped_gems := 0
	Loop, Parse, text2, `n, `n ;merge gem-buy bullet-points into a collective one
	{
		If (A_Index = 1)
			text2 := ""
		If InStr(A_Loopfield, "buy")
		{
			If !InStr(text2, "buy gems")
				text2 .= (text2 = "") ? "- buy gems (highlight: ctrl-f-v)" : "`n- buy gems (highlight: ctrl-f-v)"
			skipped_gems += 1
			If (skipped_gems <= parsed_gems) ;only merge gems that fit into search-string
				continue
		}
		text2 .= (text2 = "") ? A_Loopfield : "`n" A_Loopfield
	}
}

If (InStr(text2, "kill doedre") && InStr(text2, "kill maligaro") && InStr(text2, "kill shavronne")) ;merge multi-boss kills into a single line
{
	Loop, Parse, text2, `n, `n
	{
		If (A_Index = 1)
			text2 := ""
		If InStr(A_Loopfield, "find and kill")
		{
			If !InStr(text2, "find and kill")
				text2 .= (text2 = "") ? "- find and kill doedre, maligaro, and shavronne" : "`n- find and kill doedre, maligaro, and shavronne"
			continue
		}
		Else If InStr(A_Loopfield, "kill") && !InStr(A_Loopfield, "depraved trinity")
		{
			If !InStr(text2, "kill")
				text2 .= (text2 = "") ? "- kill doedre, maligaro, and shavronne" : "`n- kill doedre, maligaro, and shavronne"
			continue
		}
		text2 .= (text2 = "") ? A_Loopfield : "`n" A_Loopfield
	}
}

text2 := StrReplace(text2, "shavronne the returned && reassembled brutus", "shavronne && brutus")

/*
Loop, Parse, text2, `n, `n
{
	If (A_Index = 1)
		text2 := ""
	If ((InStr(A_Loopfield, ",") > 20) && (StrLen(A_Loopfield) > 30))
		text2 := (text2 = "") ? StrReplace(A_Loopfield, ", ", ",`n",, 1) : text2 "`n" StrReplace(A_Loopfield, ", ", ",`n",, 1)
	Else text2 := (text2 = "") ? A_Loopfield : text2 "`n" A_Loopfield
}
*/

If (hwnd_leveling_guide2 = "")
{
	Gui, leveling_guide1: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_leveling_guide1
	Gui, leveling_guide1: Margin, 12, 0
	Gui, leveling_guide1: Color, Black
	WinSet, Transparent, %leveling_guide_trans%
	Gui, leveling_guide1: Font, % "cLime s"fSize_leveling_guide, Fontin SmallCaps
	Gui, leveling_guide1: Add, Text, % "BackgroundTrans HWNDhwnd_levelingguidetext1", % (guide_panel1_text = "") ? "n/a" : text1

	Gui, leveling_guide2: New, -DPIScale +E0x20 -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_leveling_guide2
	Gui, leveling_guide2: Margin, 12, 0
	Gui, leveling_guide2: Color, Black
	WinSet, Transparent, %leveling_guide_trans%
	Gui, leveling_guide2: Font, c%leveling_guide_fontcolor% s%fSize_leveling_guide%, Fontin SmallCaps
	Gui, leveling_guide2: Add, Text, % "BackgroundTrans HWNDhwnd_levelingguidetext2", % text2

	;Gui, leveling_guide1: Show, NA x10000 y10000
	Gui, leveling_guide2: Show, NA x10000 y10000
	guilist .= InStr(guilist, "|leveling_guide2|leveling_guide3|") ? "" : "leveling_guide2|leveling_guide3|"
}
Else
{
	SetTextAndResize(hwnd_levelingguidetext2, text2, "s" fSize_leveling_guide, "Fontin SmallCaps")
	;SetTextAndResize(hwnd_levelingguidetext1, text1, "s" fSize_leveling_guide, "Fontin SmallCaps")
	;Gui, leveling_guide1: Show, NA x10000 y10000 AutoSize
	Gui, leveling_guide2: Show, NA x10000 y10000 AutoSize
}

;WinGetPos,,, width, height, ahk_id %hwnd_leveling_guide1%
WinGetPos,,, width2, height, ahk_id %hwnd_leveling_guide2%
;width := (width > width2) ? width : width2
;height := (height > height2) ? height : height2
height := height

Gui, leveling_guide3: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_leveling_guide3
Gui, leveling_guide3: Margin, 0, 0
Gui, leveling_guide3: Color, Black
WinSet, Transparent, %leveling_guide_trans%
Gui, leveling_guide3: Font, % "c" leveling_guide_fontcolor " s"fSize_leveling_guide*(2/3), Fontin SmallCaps
Gui, leveling_guide3: Add, Text, % "BackgroundTrans Section vleveling_guide_jump_back Center gLeveling_guide_progress w"width2/2, % " < "
Gui, leveling_guide3: Add, Text, % "BackgroundTrans ys vleveling_guide_jump_forward Center gLeveling_guide_progress w"width2/2, % " > "
Gui, leveling_guide3: Show, NA x10000 y10000
WinGetPos,,, width3, height3, ahk_id %hwnd_leveling_guide3%

Switch leveling_guide_position
{
	Case "top":
		;Gui, leveling_guide1: Show, % "NA x"xScreenOffSet + poe_width/2 - width - width3/2 + 1 " y"yScreenOffSet " h"height
		Gui, leveling_guide2: Show, % "NA x"xScreenOffSet + poe_width/2 - width2/2 " y"yScreenOffSet + height3 - 1 " h"height
		Gui, leveling_guide3: Show, % "NA x"xScreenOffSet + poe_width/2 - width2/2 " y"yScreenOffSet " w"width2 - 2
	Case "bottom":
		;Gui, leveling_guide1: Show, % "NA x"xScreenOffSet + poe_width/2 - width - width3/2 + 1 " y"yScreenOffSet + (47/48)*poe_height - height " h"height
		Gui, leveling_guide2: Show, % "NA x"xScreenOffSet + poe_width/2 - width2/2 " y"yScreenOffSet + (47/48)*poe_height - height - height3 " h"height
		Gui, leveling_guide3: Show, % "NA x"xScreenOffSet + poe_width/2 - width2/2 " y"yScreenOffSet + (47/48)*poe_height - height3 + 1 " w"width2 - 2
}
;LLK_Overlay("leveling_guide1", "show")
LLK_Overlay("leveling_guide2", "show")
LLK_Overlay("leveling_guide3", "show")
Return

Log_loop:
If (enable_delvelog = 0 || enable_delve = 0) && !WinExist("ahk_id " hwnd_leveling_guide2) && (gear_tracker_char = "")
	Return
current_location := ""
If !WinActive("ahk_group poe_window") && (A_Gui != "leveling_guide_panel") && (A_ThisHotkey != "ESC") && (A_Gui != "gear_tracker")
	Return
FileRead, poe_log_content, % poe_log_file
poe_log_content := SubStr(poe_log_content, -50000)
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
	If (target_location = current_location) ;InStr(SubStr(guide_panel2_text, InStr(guide_panel2_text, "`n",,, LLK_InStrCount(guide_panel2_text, "`n")) + 1), current_location)
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
If !WinExist("ahk_group poe_window") && (A_TickCount >= last_check + kill_timeout*60000) && (kill_script = 1) && (alarm_timestamp = "")
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

Map_info:
If (A_Gui = "")
{
	map_mods_clipped := Clipboard
	map_mods_sample := 0
}
monsters := ""
player := ""
bosses := ""
area := ""
map_mods_panel_player := ""
map_mods_panel_monsters := ""
map_mods_panel_bosses := ""
map_mods_panel_area := ""
map_mods_mod_count := 0
If (map_mods_clipped = "")
{
	IniRead, parseboard, data\Map mods.ini, sample map
	parseboard := SubStr(parseboard, InStr(parseboard, "Item Level:"))
	map_mods_sample := 1
}
Else parseboard := SubStr(map_mods_clipped, InStr(map_mods_clipped, "Item Level:"))
IniRead, map_mods_list, data\Map mods.ini

Loop, Parse, parseboard, `n, `n
{
	If InStr(A_Loopfield, "{")
	{
		If InStr(A_Loopfield, "prefix" || "suffix")
			map_mods_mod_count += 1
		continue
	}
	If (A_LoopField = "") || (SubStr(A_Loopfield, 1, 1) = "(") || InStr(A_Loopfield, "delirium reward type")
		continue
	check := InStr(A_Loopfield, "(") ? SubStr(A_LoopField, 1, InStr(A_Loopfield, "(",,, 1) - 1) SubStr(A_Loopfield, InStr(A_Loopfield, ")") + 1) : A_Loopfield
	check_characters := "-0123456789%"
	map_mod_pretext := ""
	Loop, Parse, check
	{
		If InStr(check_characters, A_LoopField)
			map_mod_pretext := (map_mod_pretext = "") ? A_LoopField : map_mod_pretext A_LoopField
	}
	While (SubStr(map_mod_pretext, 0) = "-")
		map_mod_pretext := SubStr(map_mod_pretext, 1, -1)
	Loop, Parse, map_mods_list, `n, `r`n
	{
		If (A_LoopField = "sample map") || (A_LoopField = "version")
			continue
		If InStr(check, A_LoopField)
		{
			loopfield_copy := A_LoopField
			IniRead, map_mod_type, data\Map mods.ini, %A_LoopField%, type
			IniRead, map_mod_modifier, data\Map mods.ini, %A_LoopField%, mod
			If (A_LoopField = "increased area") && InStr(check, "monster")
				map_mod_type := "monsters"
			Else If (A_LoopField = "increased area") && InStr(check, "boss")
			{
				map_mod_type := "bosses"
				loopfield_copy := "increased area of"
			}
			IniRead, map_mod_ID, data\Map mods.ini, %loopfield_copy%, ID
			If (map_info_short = 1)
				IniRead, map_mod_text, data\Map mods.ini, %loopfield_copy%, text
			Else IniRead, map_mod_text, data\Map mods.ini, %loopfield_copy%, text1
			IniRead, map_mod_mod, data\Map mods.ini, %loopfield_copy%, mod
			If (map_mod_type = "player")
				map_mods_panel_player := (map_mods_panel_player = "") ? map_mod_text : map_mods_panel_player "`n" map_mod_text
			Else If (map_mod_type = "monsters")
			{
				If InStr(map_mods_panel_monsters, map_mod_text)
				{
					map_mod_pretext := SubStr(map_mod_pretext, 1, 2)
					more_life := SubStr(monsters, InStr(monsters, "," map_mod_ID) - 3, 2)
					monsters := StrReplace(monsters, more_life "%," map_mod_ID map_mod_text, map_mod_pretext + more_life "%," map_mod_ID map_mod_text)
					break
				}
				map_mods_panel_monsters := (map_mods_panel_monsters = "") ? map_mod_text : map_mods_panel_monsters "`n" map_mod_text
			}
			Else If (map_mod_type = "bosses")
				map_mods_panel_bosses := (map_mods_panel_bosses = "") ? map_mod_text : map_mods_panel_bosses "`n" map_mod_text
			Else If (map_mod_type = "area")
				map_mods_panel_area := (map_mods_panel_area = "") ? map_mod_text : map_mods_panel_area "`n" map_mod_text
			
			map_mod_pretext := (map_mod_mod = "?") ? "" : map_mod_pretext
			map_mod_text := (map_mod_pretext != "") ? map_mod_pretext "," map_mod_ID map_mod_text : "," map_mod_ID map_mod_text
			If (map_mod_modifier = "+")
				map_mod_text := "+" map_mod_text
			If (map_mod_modifier = "-")
				map_mod_text := "-" map_mod_text
			IniRead, map_mod_rank, ini\map info.ini, %map_mod_ID%, rank
			If (map_mod_type = "player") && (map_mod_rank > 0)
				player := (player = "") ? map_mod_text : player "`n" map_mod_text
			Else If (map_mod_type = "monsters") && (map_mod_rank > 0)
				monsters := (monsters = "") ? map_mod_text : monsters "`n" map_mod_text
			Else If (map_mod_type = "bosses") && (map_mod_rank > 0)
				bosses := (bosses = "") ? map_mod_text : bosses "`n" map_mod_text
			Else If (map_mod_type = "area") && (map_mod_rank > 0)
				area := (area = "") ? map_mod_text : area "`n" map_mod_text
			break
		}
	}
}

map_mods_panel_text := map_mods_panel_player "`n" map_mods_panel_monsters "`n" map_mods_panel_bosses "`n" map_mods_panel_area
width := ""
Loop 2
{
	map_info_difficulty := 0
	map_info_mod_count := 0
	Gui, map_mods_window: New, -DPIScale -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_map_mods_window
	If (A_Index = 1)
		Gui, map_mods_window: Margin, 0, 0
	Else Gui, map_mods_window: Margin, 8, 2
	Gui, map_mods_window: Color, Black
	WinSet, Transparent, %map_info_trans%
	style_map_mods := (width = "") ? "" : " w"width
	Gui, map_mods_window: Font, % "s"fSize0 + fSize_offset_map_info " cAqua underline", Fontin SmallCaps
	If (player != "")
	{
		Gui, map_mods_window: Add, Text, BackgroundTrans %map_info_side% %style_map_mods%, player:
		Gui, map_mods_window: Font, norm
		Loop, Parse, player, `n, `n
		{
			window_ID := SubStr(A_LoopField, InStr(A_LoopField, ",") + 1, 3)
			IniRead, window_rank, ini\map info.ini, %window_ID%, rank, 1
			map_info_difficulty += window_rank
			map_info_mod_count += (window_rank != 0) ? 1 : 0
			window_color := "white"
			window_color := (window_rank > 1) ? "yellow" : window_color
			window_color := (window_rank > 2) ? "red" : window_color
			window_color := (window_rank > 3) ? "fuchsia" : window_color
			window_text := (SubStr(A_Loopfield, 1, 1) = ",") ? StrReplace(A_LoopField, "," window_ID) : StrReplace(A_LoopField, "," window_ID, " ")
			window_text := StrReplace(window_text, "?", "`n")
			window_text := StrReplace(window_text, "$")
			Gui, map_mods_window: Add, Text, BackgroundTrans c%window_color% %map_info_side% %style_map_mods% y+0, %window_text%
		}
		Gui, map_mods_window: Font, underline
	}
	If (monsters != "")
	{
		Gui, map_mods_window: Add, Text, BackgroundTrans y+0 %map_info_side% %style_map_mods%, monsters:
		Gui, map_mods_window: Font, norm
		Loop, Parse, monsters, `n, `n
		{
			window_ID := SubStr(A_LoopField, InStr(A_LoopField, ",") + 1, 3)
			IniRead, window_rank, ini\map info.ini, %window_ID%, rank, 1
			map_info_difficulty += window_rank
			map_info_mod_count += (window_rank != 0) ? 1 : 0
			window_color := "white"
			window_color := (window_rank > 1) ? "yellow" : window_color
			window_color := (window_rank > 2) ? "red" : window_color
			window_color := (window_rank > 3) ? "fuchsia" : window_color
			window_text := (SubStr(A_Loopfield, 1, 1) = ",") ? StrReplace(A_LoopField, "," window_ID) : StrReplace(A_LoopField, "," window_ID, " ")
			window_text := StrReplace(window_text, "?", "`n")
			window_text := StrReplace(window_text, "$")
			Gui, map_mods_window: Add, Text, BackgroundTrans c%window_color% %map_info_side% %style_map_mods% y+0, %window_text%
		}
		Gui, map_mods_window: Font, underline
	}
	If (bosses != "")
	{
		Gui, map_mods_window: Add, Text, BackgroundTrans y+0 %map_info_side% %style_map_mods%, boss:
		Gui, map_mods_window: Font, norm
		Loop, Parse, bosses, `n, `n
		{
			window_ID := SubStr(A_LoopField, InStr(A_LoopField, ",") + 1, 3)
			IniRead, window_rank, ini\map info.ini, %window_ID%, rank, 1
			map_info_difficulty += window_rank
			map_info_mod_count += (window_rank != 0) ? 1 : 0
			window_color := "white"
			window_color := (window_rank > 1) ? "yellow" : window_color
			window_color := (window_rank > 2) ? "red" : window_color
			window_color := (window_rank > 3) ? "fuchsia" : window_color
			window_text := (SubStr(A_Loopfield, 1, 1) = ",") ? StrReplace(A_LoopField, "," window_ID) : StrReplace(A_LoopField, "," window_ID, " ")
			window_text := StrReplace(window_text, "0f", "of")
			window_text := StrReplace(window_text, "a0e", "aoe")
			Gui, map_mods_window: Add, Text, BackgroundTrans c%window_color% %map_info_side% %style_map_mods% y+0, %window_text%
		}
		Gui, map_mods_window: Font, underline
	}
	If (area != "")
	{
		Gui, map_mods_window: Add, Text, BackgroundTrans y+0 %map_info_side% %style_map_mods%, area:
		Gui, map_mods_window: Font, norm
		Loop, Parse, area, `n, `n
		{
			window_ID := SubStr(A_LoopField, InStr(A_LoopField, ",") + 1, 3)
			IniRead, window_rank, ini\map info.ini, %window_ID%, rank, 1
			map_info_difficulty += window_rank
			map_info_mod_count += (window_rank != 0) ? 1 : 0
			window_color := "white"
			window_color := (window_rank > 1) ? "yellow" : window_color
			window_color := (window_rank > 2) ? "red" : window_color
			window_color := (window_rank > 3) ? "fuchsia" : window_color
			window_text := (SubStr(A_Loopfield, 1, 1) = ",") ? StrReplace(A_LoopField, "," window_ID) : StrReplace(A_LoopField, "," window_ID, " ")
			Gui, map_mods_window: Add, Text, BackgroundTrans c%window_color% %map_info_side% %style_map_mods% y+0, %window_text%
		}
		Gui, map_mods_window: Font, underline
	}
	If (A_Index = 1)
	{
		Gui, map_mods_window: Show, NA
		WinGetPos,,, width,, ahk_id %hwnd_map_mods_window%
	}
	Else
	{
		Gui, map_mods_toggle: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_map_mods_toggle
		Gui, map_mods_toggle: Margin, 8, 0
		Gui, map_mods_toggle: Color, Black
		WinSet, Transparent, %map_info_trans%
		Gui, map_mods_toggle: Font, % "s"fSize0 + fSize_offset_map_info " cWhite", Fontin SmallCaps
		Gui, map_mods_toggle: Add, Text, BackgroundTrans %style_map_mods% Center gMap_mods_toggle, % map_mods_mod_count " + " Format("{:0.2f}", map_info_difficulty/map_info_mod_count)
		Gui, map_mods_toggle: Show, NA
		WinGetPos,,, width, height, ahk_id %hwnd_map_mods_toggle%
		map_info_xPos_target := (map_info_xPos > poe_width) ? poe_width : map_info_xPos
		map_info_xPos_target := (map_info_xPos_target >= poe_width/2) ? map_info_xPos_target - width : map_info_xPos_target
		map_info_yPos_target := (map_info_yPos + height > poe_height) ? poe_height - height : map_info_yPos
		If (map_info_xPos >= poe_width - pixel_gamescreen_x1 - 1) && (map_info_yPos_target <= pixel_gamescreen_y1 + 1)
			map_info_yPos_target := pixel_gamescreen_y1 + 1
		Gui, map_mods_window: Show, NA
		WinGetPos,,, width_window, height_window, ahk_id %hwnd_map_mods_window%
		map_info_yPos_target1 := (map_info_yPos > poe_height/2) ? map_info_yPos_target - height_window + 1 : map_info_yPos_target + height - 1
		Gui, map_mods_window: Show, % "NA x"xScreenOffset + map_info_xPos_target " y"yScreenOffset + map_info_yPos_target1
		Gui, map_mods_toggle: Show, % "Hide x"xScreenOffset + map_info_xPos_target " y"yScreenOffset + map_info_yPos_target
		LLK_Overlay("map_mods_toggle", "show")		
		LLK_Overlay("map_mods_window", "show")
		If WinExist("ahk_id " hwnd_map_info_menu) && !WinExist("ahk_id " hwnd_settings_menu)
		{
			WinGetPos,,, edit_width, edit_height, ahk_id %hwnd_map_info_menu%
			edit_xPos := (map_info_xPos_target >= poe_width/2) ? map_info_xPos_target - edit_width + 1 : map_info_xPos_target + width_window - 1
			edit_yPos := (map_info_yPos_target1 + edit_height >= poe_height) ? poe_height - edit_height : map_info_yPos_target1
			WinMove, ahk_id %hwnd_map_info_menu%,, % xScreenOffset + edit_xPos, % yScreenoffset +  edit_yPos
		}
		toggle_map_mods_panel := 1
		map_mods_panel_fresh := 1
	}
	If ((player != "") || (monsters != "") || (bosses != "") || (area != "")) && (A_Gui = "")
		LLK_ToolTip("success", 0.5)
	Else If (player = "") && (monsters = "") && (bosses = "") && (area = "") && (map_info_search = "")
	{
		LLK_ToolTip("no mods", 0.5)
		Gui, map_mods_window: Destroy
		Gui, map_mods_toggle: Destroy
		hwnd_map_mods_toggle := ""
		hwnd_map_mods_window := ""
		map_mods_panel_fresh := 0
		break
	}
}
Return

Map_info_customization:
GuiControl_copy := A_GuiControl
Gui, map_info_menu: destroy
Gui, map_info_menu: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_map_info_menu, Lailloken UI: map mod customization
Gui, map_info_menu: Color, Black
Gui, map_info_menu: Margin, 12, 4
WinSet, Transparent, %trans%
Gui, map_info_menu: Font, % "cWhite s"fSize0, Fontin SmallCaps

If (GuiControl_copy = "Map_info_search")
{
	map_info_hits := ""
	section := 0
	Gui, settings_menu: Submit, NoHide
	If (StrLen(map_info_search) < 3)
		Return
	IniRead, map_mods_search_db, data\Map search.ini
	Loop, Parse, map_mods_search_db, `n, `n
	{
		If InStr(A_LoopField, map_info_search)
		{
			IniRead, map_info_ID, data\Map search.ini, %A_LoopField%, ID
			IniRead, map_mod_%map_info_ID%_rank, ini\map info.ini, %map_info_ID%, rank, 1
			IniRead, map_mod_%map_info_ID%_type, ini\map info.ini, %map_info_ID%, type
			map_mod_text := A_Loopfield
			If (section = 0)
			{
				Gui, map_info_menu: Add, Text, Section BackgroundTrans, set mod difficulty (0-4):
				Gui, map_info_menu: Add, Picture, ys BackgroundTrans vMap_info gSettings_menu_help hp w-1, img\GUI\help.png
				section := 1
			}
			Gui, map_info_menu: Font, % "s"fSize0 - 4
			Gui, map_info_menu: Add, Edit, xs hp Section BackgroundTrans center vMap_mod_edit_%map_info_ID% gMap_mods_save number limit1 cBlack, % map_mod_%map_info_ID%_rank
			Gui, map_info_menu: Font, % "s"fSize0
			Gui, map_info_menu: Add, Text, ys BackgroundTrans, % map_mod_text
		}
	}
	If (section != 0)
	{
		WinGetPos, winXpos, winYpos, winwidth, winheight, ahk_id %hwnd_settings_menu%
		Gui, map_info_menu: Show, % "NA x"winXpos " y"winYpos + winheight
	}
	Return
}

IniRead, map_info_parse, data\Map mods.ini
map_info_parse := StrReplace(map_info_parse, "-")
loop := ""
IDs_hit := ""
Loop, Parse, map_mods_panel_text, `n, `n
{
	If (A_LoopField = "")
		continue
	loop += 1
	check := A_LoopField
	Loop, Parse, map_info_parse, `n, `n
	{
		If (map_info_short = 1)
			IniRead, map_info_text, data\Map mods.ini, %A_LoopField%, text
		Else IniRead, map_info_text, data\Map mods.ini, %A_LoopField%, text1
		If (map_info_text = check)
		{
			IniRead, map_info_ID, data\Map mods.ini, %A_LoopField%, ID
			break
		}
	}
	IniRead, map_mod_%map_info_ID%_rank, ini\map info.ini, %map_info_ID%, rank, 1
	IniRead, map_mod_%map_info_ID%_type, ini\map info.ini, %map_info_ID%, type
	If (loop = 1)
	{
		Gui, map_info_menu: Add, Text, Section BackgroundTrans, set mod difficulty (0-4):
		Gui, map_info_menu: Add, Picture, ys BackgroundTrans vMap_info gSettings_menu_help hp w-1, img\GUI\help.png
	}
	Gui, map_info_menu: Font, % "s"fSize0 - 4
	Gui, map_info_menu: Add, Edit, xs hp Section BackgroundTrans center vMap_mod_edit_%map_info_ID% gMap_mods_save number limit1 cBlack, % map_mod_%map_info_ID%_rank
	Gui, map_info_menu: Font, % "s"fSize0
	map_info_cfg_text := StrReplace(A_LoopField, "-?")
	map_info_cfg_text := StrReplace(map_info_cfg_text, "?", " ")
	map_info_cfg_text := StrReplace(map_info_cfg_text, "0f", "of")
	map_info_cfg_text := StrReplace(map_info_cfg_text, "a0e", "aoe")
	map_info_cfg_text := StrReplace(map_info_cfg_text, "$")
	Gui, map_info_menu: Add, Text, ys BackgroundTrans, % map_info_cfg_text " (" map_mod_%map_info_ID%_type ")"
}
Gui, map_info_menu: Show, Hide
WinGetPos, winx, winy, winw,, ahk_id %hwnd_map_mods_window%
WinGetPos,,, widthedit, height,
If (map_info_side = "right")
	Gui, map_info_menu: Show, % "x"winx - widthedit + 1 " y"winy
Else Gui, map_info_menu: Show, % "x"winx + winw - 1 " y"winy
If (winy + height > yScreenOffSet + poe_height)
	WinMove, ahk_id %hwnd_map_info_menu%,,, % yScreenOffSet + poe_height - height
Return

Map_info_settings_apply:
Gui, settings_menu: Submit, NoHide
If (A_GuiControl = "map_info_short")
{
	IniWrite, % map_info_short, ini\map info.ini, Settings, short descriptions
	IniRead, map_info_parse, data\Map mods.ini
	Loop, Parse, map_info_parse, `n, `n
	{
		If (A_LoopField = "sample map") || (A_LoopField = "version")
			continue
		IniRead, parse_ID, data\Map mods.ini, %A_LoopField%, ID
		If (map_info_short = 1)
			IniRead, parse_text, data\Map mods.ini, %A_LoopField%, text
		Else IniRead, parse_text, data\Map mods.ini, %A_LoopField%, text1
		IniWrite, %parse_text%, ini\map info.ini, %parse_ID%, text
	}
	GoSub, Map_info
	Return
}
If (A_GuiControl = "Map_info_pixelcheck_enable")
{
	If (pixel_gamescreen_color1 = "") || (pixel_gamescreen_color1 = "ERROR")
	{
		LLK_ToolTip("pixel-check setup required")
		map_info_pixelcheck_enable := 0
		GuiControl, settings_menu: , Map_info_pixelcheck_enable, 0
		Return
	}
	IniWrite, %map_info_pixelcheck_enable%, ini\map info.ini, Settings, enable pixel-check
	GoSub, Screenchecks_gamescreen
	Return
}
If (A_GuiControl = "fSize_map_info_minus")
{
	fSize_offset_map_info -= 1
	IniWrite, %fSize_offset_map_info%, ini\map info.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_map_info_plus")
{
	fSize_offset_map_info += 1
	IniWrite, %fSize_offset_map_info%, ini\map info.ini, Settings, font-offset
}
If (A_GuiControl = "fSize_map_info_reset")
{
	fSize_offset_map_info := 0
	IniWrite, %fSize_offset_map_info%, ini\map info.ini, Settings, font-offset
}
If (A_GuiControl = "map_info_opac_minus")
{
	map_info_trans -= (map_info_trans > 100) ? 30 : 0
	IniWrite, %map_info_trans%, ini\map info.ini, Settings, transparency
}
If (A_GuiControl = "map_info_opac_plus")
{
	map_info_trans += (map_info_trans < 250) ? 30 : 0
	IniWrite, %map_info_trans%, ini\map info.ini, Settings, transparency
}
GoSub, Map_info
Return

Map_mods_save:
Gui, map_info_menu: Submit, NoHide
SendInput, ^{a}
map_mod_ID := StrReplace(A_GuiControl, "map_mod_edit_")
map_mod_difficulty := %A_GuiControl%
map_mod_difficulty := (map_mod_difficulty = "") ? 0 : map_mod_difficulty
map_mod_difficulty := (map_mod_difficulty > 4) ? 4 : map_mod_difficulty
IniWrite, %map_mod_difficulty%, ini\map info.ini, %map_mod_ID%, rank
GoSub, Map_info
Return

Map_mods_toggle:
start := A_TickCount
While GetKeyState("LButton", "P")
{
	If (A_TickCount >= start + 300)
	{
		If WinExist("ahk_id " hwnd_map_info_menu)
		{
			Gui, map_info_menu: Destroy
			hwnd_map_info_menu := ""
		}
		If !WinExist("ahk_id " hwnd_map_mods_window)
			LLK_Overlay("map_mods_window", "show")
		WinGetPos,,, wGui, hGui, ahk_id %hwnd_map_mods_toggle%
		WinGetPos,,,, hGui2, ahk_id %hwnd_map_mods_window%
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		map_info_xPos := (panelXpos >= poe_width/2) ? panelXpos + wGui : panelXpos
		map_info_yPos := panelYpos
		map_info_side := (map_info_xPos > poe_width//2) ? "right" : "left"
		IniWrite, % map_info_xPos, ini\map info.ini, Settings, x-coordinate
		IniWrite, % map_info_yPos, ini\map info.ini, Settings, y-coordinate
		GoSub, map_info
		WinActivate, ahk_group poe_window
		Return
	}
}
If (click = 2)
{
	LLK_Overlay("map_mods_window", "show")
	GoSub, Map_info_customization
	Return
}
If WinExist("ahk_id " hwnd_map_info_menu)
{
	Gui, map_info_menu: Destroy
	hwnd_map_info_menu := ""
}
If WinExist("ahk_id " hwnd_map_mods_window)
{
	LLK_Overlay("map_mods_window", "hide")
	toggle_map_mods_panel := 0
}
Else
{
	LLK_Overlay("map_mods_window", "Show")
	toggle_map_mods_panel := 1
}
WinActivate, ahk_group poe_window
Return

Notepad:
start := A_TickCount
Gui, notepad_edit: Submit, NoHide
While GetKeyState("LButton", "P") && InStr(A_Gui, "notepad")
{
	If (A_TickCount >= start + 300)
	{
		WinGetPos,,, wGui, hGui, % "ahk_id " hwnd_%A_Gui%
		If InStr(A_Gui, "notepad_drag")
		{
			notepad_gui := "notepad" StrReplace(A_Gui, "notepad_drag")
			WinGetPos,,, wGui2, hGui2, % "ahk_id " hwnd_%notepad_gui%
		}
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		If InStr(A_GuiControl, "notepad_drag")
		{
			LLK_Overlay(notepad_gui, "show")
			LLK_Overlay(A_Gui, "show")
		}
		Else
		{
			notepad_panel_xpos := panelXpos
			notepad_panel_ypos := panelYpos
			IniWrite, % notepad_panel_xpos, ini\notepad.ini, UI, button xcoord
			IniWrite, % notepad_panel_ypos, ini\notepad.ini, UI, button ycoord
		}
		WinActivate, ahk_group poe_window
		Return
	}
}
If InStr(A_GuiControl, "notepad_drag")
{
	If (A_GuiControl = "notepad_drag_grouped")
	{
		notepad_grouptext := (click = 1) ? (notepad_grouptext > 1) ? notepad_grouptext - 1 : notepad_grouptext : (notepad_grouptext < notepad_notes.Length()) ? notepad_grouptext + 1 : notepad_grouptext
		SetTextAndResize(hwnd_notepad_header, "note " notepad_grouptext "/" notepad_notes.Length() , "s" fSize_notepad, "Fontin SmallCaps")
		SetTextAndResize(hwnd_notepad_text, notepad_notes[notepad_grouptext] , "s" fSize_notepad, "Fontin SmallCaps")
		Gui, notepad: Show, NA Autosize
		WinGetPos, notepad_drag_xPos, notepad_drag_yPos, wDrag, hDrag, ahk_id %hwnd_notepad_drag%
		WinGetPos,,, width, height, ahk_id %hwnd_notepad%
		xPos := (notepad_drag_xPos > xScreenOffSet + poe_width/2) ? notepad_drag_xPos - width + wDrag : notepad_drag_xPos
		yPos := (notepad_drag_yPos > yScreenOffSet + poe_height/2) ? notepad_drag_yPos - height + hDrag : notepad_drag_yPos
		Gui, notepad: Show, % "NA x"xPos " y"yPos
		Gui, notepad_drag: Show, NA
	}
	If (A_GuiControl = "notepad_drag") && (click = 2)
	{
		gui := StrReplace(A_Gui, "notepad_drag")
		LLK_Overlay("notepad" gui, "hide")
		LLK_Overlay("notepad_drag" gui, "hide")
		Gui, notepad%gui%: Destroy
		hwnd_notepad%gui% := ""
		Gui, notepad_drag%gui%: Destroy
		hwnd_notepad_drag%gui% := ""
	}
	WinActivate, ahk_group poe_window
	Return
}
notepad_fontcolor := (notepad_fontcolor = "") ? "White" : notepad_fontcolor
fSize_notepad := fSize0 + fSize_offset_notepad

If InStr(A_GuiControl, "notepad_context_") || InStr(GuiControl_copy, "notepad_context_")
{	
	Gui, notepad_edit: Submit, NoHide
	LLK_Overlay("notepad_edit", "hide")
	notepad_text := StrReplace(notepad_text, "[", "(")
	notepad_text := StrReplace(notepad_text, "]", ")")
	notepad_anchor := poe_height*0.14
	
	If (A_GuiControl = "notepad_context_simple") || (GuiControl_copy = "notepad_context_simple")
	{
		Gui, notepad_drag: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_notepad_drag
		Gui, notepad_drag: Margin, 0, 0
		Gui, notepad_drag: Color, Black
		WinSet, Transparent, % (notepad_trans < 250) ? notepad_trans + 30 : notepad_trans
		Gui, notepad_drag: Font, % "s"fSize_notepad//2, Fontin SmallCaps
		Gui, notepad_drag: Add, Text, x0 y0 BackgroundTrans Center vnotepad_drag gNotepad HWNDhwnd_notepad_dragbutton, % "    "
		ControlGetPos,,, wDrag,,, ahk_id %hwnd_notepad_dragbutton%
		
		text := ""
		If InStr(notepad_text, "#")
		{
			text := SubStr(notepad_text, InStr(notepad_text, "#") + 1)
			text := (SubStr(text, 1, 1) = "`n") ? SubStr(text, 2) : text
			text := (SubStr(text, 1, 1) = " ") ? SubStr(text, 2) : text
			text := (SubStr(text, 0) = "`n") ? SubStr(text, 1, -1) : text
		}
		
		Gui, notepad: New, -DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_notepad
		Gui, notepad: Margin, % wDrag + 2, 0
		Gui, notepad: Color, Black
		WinSet, Transparent, %notepad_trans%
		Gui, notepad: Font, c%notepad_fontcolor% s%fSize_notepad%, Fontin SmallCaps
		Gui, notepad: Add, Text, BackgroundTrans, % (text = "") ? (SubStr(notepad_text, 0) = "`n")? StrReplace(SubStr(notepad_text, 1, -1), "&", "&&") : StrReplace(notepad_text, "&", "&&") : StrReplace(text, "&", "&&")
		Gui, notepad: Show, % "NA AutoSize x"xScreenOffSet " y"yScreenOffSet + notepad_anchor
		Gui, notepad_drag: Show, % "NA AutoSize x"xScreenOffSet " y"yScreenOffSet + notepad_anchor
		LLK_Overlay("notepad", "show")
		LLK_Overlay("notepad_drag", "show")
		notepad_edit := 0
		WinActivate, ahk_group poe_window
	}
	If (A_GuiControl = "notepad_context_multi") || (GuiControl_copy = "notepad_context_multi")
	{
		loop := ""
		Loop, Parse, notepad_text, "#", "#"
		{
			If (A_Loopfield = "") || (A_Index = 1)
				continue
			gui := loop
			loop += 1
			Gui, notepad_drag%gui%: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_notepad_drag%gui%
			Gui, notepad_drag%gui%: Margin, 0, 0
			Gui, notepad_drag%gui%: Color, Black
			WinSet, Transparent, % (notepad_trans < 250) ? notepad_trans + 30 : notepad_trans
			Gui, notepad_drag%gui%: Font, % "s"fSize_notepad//2, Fontin SmallCaps
			Gui, notepad_drag%gui%: Add, Text, x0 y0 BackgroundTrans Center vnotepad_drag gNotepad HWNDhwnd_notepad_dragbutton, % "    "
			ControlGetPos,,, wDrag,,, ahk_id %hwnd_notepad_dragbutton%
			
			Gui, notepad%gui%: New, -DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_notepad%gui%, notepad
			Gui, notepad%gui%: Margin, % wDrag + 2, 0
			Gui, notepad%gui%: Color, Black
			WinSet, Transparent, %notepad_trans%
			Gui, notepad%gui%: Font, c%notepad_fontcolor% s%fSize_notepad%, Fontin SmallCaps
			text := (SubStr(A_Loopfield, 1, 1) = " ") ? SubStr(A_Loopfield, 2) : A_Loopfield
			text := (SubStr(text, 0) = "`n") ? SubStr(text, 1, -1) : text
			Gui, notepad%gui%: Add, Text, BackgroundTrans, % StrReplace(text, "&", "&&")
			Gui, notepad%gui%: Show, % "NA AutoSize x"xScreenOffSet " y"yScreenOffSet + notepad_anchor
			Gui, notepad_drag%gui%: Show, % "NA AutoSize x"xScreenOffSet " y"yScreenOffSet + notepad_anchor
			WinGetPos,,,, height, % "ahk_id " hwnd_notepad%gui%
			notepad_anchor += height*1.1
			
			guilist .= InStr(guilist, "notepad" gui "|") ? "" : "notepad" gui "|"
			guilist .= InStr(guilist, "notepad_drag" gui "|") ? "" : "notepad_drag" gui "|"
			
			LLK_Overlay("notepad" gui, "show")
			LLK_Overlay("notepad_drag" gui, "show")
		}
		notepad_edit := 0
		WinActivate, ahk_group poe_window
	}
	If (A_GuiControl = "notepad_context_grouped") || (GuiControl_copy = "notepad_context_grouped")
	{
		loop := 0
		notepad_notes := []
		Loop, Parse, notepad_text, "#", "#"
		{
			If (A_LoopField = "") || (A_Index = 1)
				continue
			loop += 1
			text := (SubStr(A_Loopfield, 1, 1) = " ") ? SubStr(A_Loopfield, 2) : A_Loopfield
			text := (SubStr(text, 0) = "`n") ? SubStr(text, 1, -1) : text
			notepad_notes.Push(text)
		}
		Gui, notepad_drag: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_notepad_drag
		Gui, notepad_drag: Margin, 0, 0
		Gui, notepad_drag: Color, Black
		WinSet, Transparent, % (notepad_trans < 250) ? notepad_trans + 30 : notepad_trans
		Gui, notepad_drag: Font, % "s"fSize_notepad//2, Fontin SmallCaps
		Gui, notepad_drag: Add, Text, x0 y0 BackgroundTrans Center vnotepad_drag_grouped gNotepad HWNDhwnd_notepad_dragbutton, % "    "
		ControlGetPos,,, wDrag,,, ahk_id %hwnd_notepad_dragbutton%
		
		Gui, notepad: New, -DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_notepad
		Gui, notepad: Margin, % wDrag + 2, 0
		Gui, notepad: Color, Black
		WinSet, Transparent, %notepad_trans%
		Gui, notepad: Font, c%notepad_fontcolor% s%fSize_notepad% underline, Fontin SmallCaps
		Gui, notepad: Add, Text, BackgroundTrans HWNDhwnd_notepad_header, % "note 1/" loop
		Gui, notepad: Font, norm
		Gui, notepad: Add, Text, BackgroundTrans HWNDhwnd_notepad_text y+0, % StrReplace(notepad_notes[1], "&", "&&")
		Gui, notepad: Show, % "NA AutoSize x"xScreenOffSet " y"yScreenOffSet + notepad_anchor
		Gui, notepad_drag: Show, % "NA AutoSize x"xScreenOffSet " y"yScreenOffSet + notepad_anchor
		LLK_Overlay("notepad", "show")
		LLK_Overlay("notepad_drag", "show")
		notepad_edit := 0
		notepad_grouptext := 1
		WinActivate, ahk_group poe_window
	}
	GuiControl_copy := ""
	Return
}

If (A_Gui = "settings_menu")
{
	Gui, notepad_edit: Submit, NoHide
	notepad_text := StrReplace(notepad_text, "[", "(")
	notepad_text := StrReplace(notepad_text, "]", ")")
	Loop
	{
		If !LLK_hwnd("hwnd_notepad")
			break
		If (A_Index = 1)
		{
			Gui, notepad: Destroy
			hwnd_notepad := ""
			Gui, notepad_drag: Destroy
			hwnd_notepad_drag := ""
		}
		Gui, notepad%A_Index%: Destroy
		hwnd_notepad%A_Index% := ""
		Gui, notepad_drag%A_Index%: Destroy
		hwnd_notepad_drag%A_Index% := ""
	}
	Gui, notepad_sample: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_notepad_sample, Lailloken UI: overlay-text preview
	Gui, notepad_sample: Margin, 12, 4
	Gui, notepad_sample: Color, Black
	WinSet, Transparent, %notepad_trans%
	Gui, notepad_sample: Font, c%notepad_fontcolor% s%fSize_notepad%, Fontin SmallCaps
	Gui, notepad_sample: Add, Text, BackgroundTrans, this is what text-`nwidgets look like with`nthe current settings
	Gui, notepad_sample: Show, % "NA AutoSize"
	WinGetPos,,, win_width, win_height, ahk_id %hwnd_notepad_sample%
	Gui, notepad_sample: Show, % "Hide AutoSize x"xScreenOffSet + poe_width/2 - win_width/2 " y"yScreenOffSet
	LLK_Overlay("notepad_sample", "show")
	Return
}

If (click = 2) || (!WinExist("ahk_id " hwnd_notepad_edit) && !LLK_hwnd("hwnd_notepad"))
{
	If !WinExist("ahk_id " hwnd_notepad_edit) && (click = 2) && !LLK_WinExist("hwnd_notepad")
	{
		WinActivate, ahk_group poe_window
		Return
	}
	If WinExist("ahk_id " hwnd_notepad_edit)
	{
		Gui, notepad_edit: Submit, NoHide
		WinGetPos,,, notepad_width, notepad_height, ahk_id %hwnd_notepad_edit%
		notepad_width -= xborder*2
		notepad_height -= caption + yborder*2
		notepad_text := StrReplace(notepad_text, "[", "(")
		notepad_text := StrReplace(notepad_text, "]", ")")
	}
	If (notepad_text != "") || !WinExist("ahk_id " hwnd_notepad_edit)
	{
		If (notepad_edit = 0) || !WinExist("ahk_id " hwnd_notepad_edit)
		{
			Loop
			{
				If (A_Index = 1)
				{
					Gui, notepad: Destroy
					hwnd_notepad := ""
					Gui, notepad_drag: Destroy
					hwnd_notepad_drag := ""
				}
				If (hwnd_notepad%A_Index% = "")
					break
				Gui, notepad%A_Index%: Destroy
				hwnd_notepad%A_Index% := ""
				Gui, notepad_drag%A_Index%: Destroy
				hwnd_notepad_drag%A_Index% := ""
			}
			;LLK_Overlay("notepad_drag", "hide")
			Gui, notepad_edit: New, -DPIScale +Resize +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_notepad_edit, Lailloken-UI: notepad
			Gui, notepad_edit: Margin, 12, 4
			Gui, notepad_edit: Color, Black
			WinSet, Transparent, 220
			Gui, notepad_edit: Font, cBlack s%fSize_notepad%, Fontin SmallCaps
			Gui, notepad_edit: Add, Edit, x0 y0 w1000 h1000 vnotepad_text Lowercase, %notepad_text%
			Gui, notepad_edit: Show, % "x"xScreenOffset + poe_width/2 - notepad_width/2 " y"yScreenOffset + poe_height/2 - notepad_height/2 " w"notepad_width " h"notepad_height
			SendInput, {Right}
			LLK_Overlay("notepad_edit", "show")
			notepad_edit := 1
		}
		Else
		{
			If LLK_InStrCount(notepad_text, "#")
			{
				MouseGetPos, mouseXpos, mouseYpos
				Gui, notepad_contextmenu: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_notepad_contextmenu
				Gui, notepad_contextmenu: Margin, 4, 2
				Gui, notepad_contextmenu: Color, Black
				WinSet, Transparent, %trans%
				Gui, notepad_contextmenu: Font, s%fSize0% cWhite, Fontin SmallCaps
				Gui, notepad_contextmenu: Add, Text, vnotepad_context_simple gNotepad BackgroundTrans Center, simple
				Gui, notepad_contextmenu: Add, Text, vnotepad_context_multi gNotepad BackgroundTrans Center, multi
				Gui, notepad_contextmenu: Add, Text, vnotepad_context_grouped gNotepad BackgroundTrans Center, grouped
				Gui, notepad_contextmenu: Show, NA
				WinGetPos,,, width, height, ahk_id %hwnd_notepad_contextmenu%
				mouseXpos := (mouseXpos + width > xScreenOffSet + poe_width) ? xScreenOffset + poe_width - width : mouseXpos
				mouseYpos := (mouseYpos + height > yScreenOffSet + poe_height) ? yScreenOffSet + poe_height - height : mouseYpos
				Gui, notepad_contextmenu: Show, % "x"mouseXpos " y"mouseYpos
				WinWaitNotActive, ahk_id %hwnd_notepad_contextmenu%
				Gui, notepad_contextmenu: destroy
			}
			Else
			{
				GuiControl_copy := "notepad_context_simple"
				GoSub, Notepad
				Return
			}
		}
	}
	Return
}

If WinExist("ahk_id " hwnd_notepad_edit)
{
	If (notepad_edit != 0)
	{
		WinGetPos,,, notepad_width, notepad_height, ahk_id %hwnd_notepad_edit%
		notepad_width -= xborder*2
		notepad_height -= caption + yborder*2
	}
	Gui, notepad: Submit, NoHide
	notepad_text := StrReplace(notepad_text, "[", "(")
	notepad_text := StrReplace(notepad_text, "]", ")")
	If (notepad_edit = 1)
		LLK_Overlay("notepad_edit", "hide")
}
Else
{
	If LLK_WinExist("hwnd_notepad")
	{
		Loop 100
		{
			If (A_Index = 1) && (hwnd_notepad != "")
			{
				LLK_Overlay("notepad", "hide")
				LLK_Overlay("notepad_drag", "hide")
			}
			If (hwnd_notepad%A_Index% != "")
			{
				LLK_Overlay("notepad" A_Index, "hide")
				LLK_Overlay("notepad_drag" A_Index, "hide")
			}
		}
		WinActivate, ahk_group poe_window
	}
	Else
	{
		Loop 100
		{
			If (A_Index = 1) && (hwnd_notepad != "")
			{
				LLK_Overlay("notepad", "show")
				LLK_Overlay("notepad_drag", "show")
			}
			If (hwnd_notepad%A_Index% != "")
			{
				LLK_Overlay("notepad" A_Index, "show")
				LLK_Overlay("notepad_drag" A_Index, "show")
			}
		}
	}
}
WinActivate, ahk_group poe_window
Return

Notepad_editGuiClose:
If WinExist("ahk_id " hwnd_notepad_edit)
{
	If (notepad_edit != 0)
	{
		WinGetPos,,, notepad_width, notepad_height, ahk_id %hwnd_notepad_edit%
		notepad_width -= xborder*2
		notepad_height -= caption + yborder*2
	}
	Gui, notepad_edit: Submit, NoHide
	notepad_text := StrReplace(notepad_text, "[", "(")
	notepad_text := StrReplace(notepad_text, "]", ")")
	Gui, notepad_edit: Destroy
	hwnd_notepad_edit := ""
}
Return

Omnikey:
If (omnikey_conflict_alt = 1) && (alt_modifier = "")
{
	LLK_ToolTip("custom highlight-key detected:`nomni-key setup required", 2)
	Return
}
clipboard := ""
ThisHotkey_copy := StrReplace(A_ThisHotkey, "~")
ThisHotkey_copy := StrReplace(ThisHotkey_copy, "*")
If (omnikey_conflict_alt = 1)
	SendInput {%alt_modifier% down}^{c}{%alt_modifier% up}
Else SendInput !^{c}
ClipWait, 0.05
If (clipboard != "")
{
	If WinExist("ahk_id " hwnd_gear_tracker)
	{
		If !InStr(clipboard, "requirements:`r`nlevel:") || InStr(clipboard, "unidentified")
		{
			LLK_ToolTip("item cannot be added")
			Return
		}
		Loop, Parse, clipboard, `n, `r
		{
			If InStr(A_Loopfield, "class")
			{
				class := StrReplace(A_Loopfield, "item class: ")
				class := (!InStr(class, "boots") && !InStr(class, "gloves")) ? SubStr(class, InStr(class, " ",,, LLK_InStrCount(class, " ")) +1, -1) : SubStr(class, InStr(class, " ",,, LLK_InStrCount(class, " ")) +1)
			}
			If (A_Index = 3)
			{
				name := StrReplace(A_Loopfield, "`r")
				break
			}
		}
		IniRead, gear_tracker_items, ini\leveling tracker.ini, gear,, % A_Space
		If InStr(gear_tracker_items, name)
		{
			LLK_ToolTip("item already added")
			Return
		}
		required_level := SubStr(clipboard, InStr(clipboard, "requirements:`r`nlevel:"))
		required_level := StrReplace(required_level, "requirements:`r`nlevel: ")
		required_level := StrReplace(required_level, " (unmet)")
		required_level := SubStr(required_level, 1, InStr(required_level, "`r`n") - 1)
		required_level := (StrLen(required_level) = 1) ? 0 required_level : required_level
		If (required_level <= gear_tracker_characters[gear_tracker_char])
		{
			LLK_ToolTip("item can already be equipped")
			Return
		}
		update_gear_tracker := 1
		IniWrite, % (InStr(clipboard, "rarity: rare") || InStr(clipboard, "rarity: magic")) ? "(" required_level ") " class ": " name : "(" required_level ") " name, ini\leveling tracker.ini, gear
		GoSub, Leveling_guide_gear
		Return
	}
	
	Loop, Parse, clipboard, `n, `n
	{
		If InStr(A_LoopField, "item class:")
		{
			item_class := StrReplace(A_LoopField, "item class:")
			item_class := StrReplace(item_class, "`r")
			break
		}
	}
	start := A_TickCount
	If InStr(clipboard, "recombinator") || InStr(clipboard, "power core")
	{
		recomb_item1 := "sample item`nclass x:`n`n`n`n`n`n`n`n"
		recomb_item2 := "sample item`nclass x:`n`n`n`n`n`n`n`n"
		GoSub, Recombinators_add2
		Return
	}
	If InStr(clipboard, "limited to: 1 historic") && WinExist("ahk_id " hwnd_legion_window)
	{
		GoSub, Legion_seeds_parse
		Return
	}
	If WinExist("ahk_id " hwnd_recombinator_window)
	{
		GoSub, Recombinators_add
		Return
	}
	If InStr(clipboard, "Attacks per Second:")
	{
		While GetKeyState(ThisHotkey_copy, "P")
		{
			If (A_TickCount >= start + 200)
			{
				GoSub, Omnikey_dps
				KeyWait, %ThisHotkey_copy%
				Return
			}
		}
	}
	If !InStr(clipboard, "Rarity: Currency") && !InStr(clipboard, "Item Class: Map") && !InStr(clipboard, "Unidentified") && !InStr(clipboard, "Heist") && !InStr(clipboard, "Item Class: Expedition") && !InStr(clipboard, "Item Class: Stackable Currency") || InStr(clipboard, "to the goddess") || InStr(clipboard, "other oils")
	{
		GoSub, Omnikey_context_menu
		Return
	}
	If InStr(clipboard, "Orb of Horizons")
	{
		While GetKeyState(ThisHotkey_copy, "P")
		{
			If (A_TickCount >= start + 200)
			{
				horizon_toggle := 1
				LLK_Omnikey_ToolTip(maps_a)
				KeyWait, %ThisHotkey_copy%
				horizon_toggle := 0
				LLK_Omnikey_ToolTip()
				Return
			}
		}
	}
	If InStr(clipboard, "Item Class: Map") && !InStr(clipboard, "Fragment")
	{
		start := A_TickCount
		While GetKeyState(ThisHotkey_copy, "P")
		{
			If (A_TickCount >= start + 200)
			{
				Loop, Parse, Clipboard, `r`n, `r`n
				{
					If InStr(A_Loopfield, "Map Tier: ")
					{
						parse_tier := StrReplace(A_Loopfield, "Map Tier: ")
						Break
					}
				}
				If InStr(clipboard, "maze of the minotaur") || InStr(clipboard, "forge of the phoenix") || InStr(clipboard, "lair of the hydra") || InStr(clipboard, "pit of the chimera")
					LLK_Omnikey_ToolTip("horizons:maze of the minotaur`nforge of the phoenix`nlair of the hydra`npit of the chimera" )
				Else LLK_Omnikey_ToolTip("horizons:" maps_tier%parse_tier%)
				KeyWait, %ThisHotkey_copy%
				LLK_Omnikey_ToolTip()
				Return
			}
		}
		If InStr(clipboard, "Unidentified") || InStr(clipboard, "Rarity: Normal") || InStr(clipboard, "Rarity: Unique")
		{
			LLK_ToolTip("not supported:`nnormal, unique, un-ID")
			Return
		}
		If (pixel_gamescreen_color1 = "ERROR") || (pixel_gamescreen_color1 = "")
		{
			LLK_ToolTip("pixel-check setup required")
			Return
		}
		Gui, map_info_menu: Destroy
		hwnd_map_info_menu := ""
		GoSub, Map_info
		Return
	}
}
Else GoSub, Omnikey2
Return

Omnikey2:
If WinExist("ahk_id " hwnd_delve_grid)
{
	If (delve_enable_recognition = 1)
		GoSub, Delve_scan
	Return
}
Clipboard := ""
ThisHotkey_copy := StrReplace(A_ThisHotkey, "~")
ThisHotkey_copy := StrReplace(ThisHotkey_copy, "*")
If (enable_pixelchecks = 0 || pixelchecks_enabled = "")
	LLK_PixelSearch("gamescreen")

If (clipboard = "") && (gamescreen = 0)
{
	LLK_ImageSearch()
	If (disable_imagecheck_bestiary = 0) && (bestiary = 1)
		GoSub, Bestiary_search
	If (disable_imagecheck_gwennen = 0) && (gwennen = 1)
		GoSub, Gwennen_search
	If (disable_imagecheck_betrayal = 0) && (betrayal = 1)
		GoSub, Betrayal_search
	If (disable_imagecheck_stash = 0) && (stash = 1)
	{
		stash_search_type := "stash"
		GoSub, Stash_search
	}
	If (disable_imagecheck_vendor = 0) && (vendor = 1)
	{
		stash_search_type := "vendor"
		GoSub, Stash_search
	}
}
Return

Omnikey_context_menu:
Gui, context_menu: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_context_menu
Gui, context_menu: Margin, 4, 2
Gui, context_menu: Color, Black
WinSet, Transparent, %trans%
Gui, context_menu: Font, s%fSize0% cWhite, Fontin SmallCaps
If InStr(clipboard, "Rarity: Unique") || InStr(clipboard, "Rarity: Gem") || InStr(clipboard, "Class: Quest") || InStr(clipboard, "Rarity: Divination Card")
	Gui, context_menu: Add, Text, vwiki_exact gOmnikey_menu_selection BackgroundTrans Center, wiki (exact item)
Else If InStr(clipboard, "to the goddess")
{
	Gui, context_menu: Add, Text, vwiki_exact gOmnikey_menu_selection BackgroundTrans Center, wiki (exact item)
	Gui, context_menu: Add, Text, vlab_layout gOmnikey_menu_selection BackgroundTrans Center, lab info
}
Else If InStr(clipboard, "other oils")
{
	Gui, context_menu: Add, Text, vOil_wiki gOmnikey_menu_selection BackgroundTrans Center, wiki (item class)
	Gui, context_menu: Add, Text, vOil_table gOmnikey_menu_selection BackgroundTrans Center, anoint table
}
Else If InStr(clipboard, "cluster jewel")
{
	If InStr(clipboard, "small cluster")
		cluster_type := "Small"
	Else cluster_type := InStr(clipboard, "medium cluster") ? "Medium" : "Large"
	Gui, context_menu: Add, Text, vcrafting_table_all_cluster gOmnikey_menu_selection BackgroundTrans Center, crafting table: all
	Gui, context_menu: Add, Text, vcrafting_table_%cluster_type%_cluster gOmnikey_menu_selection BackgroundTrans Center, crafting table: %cluster_type%
	Gui, context_menu: Add, Text, vwiki_class gOmnikey_menu_selection BackgroundTrans Center, wiki (item class)
}
Else
{
	Gui, context_menu: Add, Text, vcrafting_table gOmnikey_menu_selection BackgroundTrans Center, crafting table
	Gui, context_menu: Add, Text, vwiki_class gOmnikey_menu_selection BackgroundTrans Center, wiki (item class)
}
If InStr(clipboard, "limited to: 1 historic")
{
	Gui, context_menu: Add, Text, vlegion_seed_explore gOmnikey_menu_selection BackgroundTrans Center, explore seed
}
If InStr(clipboard, "Sockets: ") && !InStr(clipboard, "Class: Ring") && !InStr(clipboard, "Class: Amulet") && !InStr(clipboard, "Class: Belt")
	Gui, context_menu: Add, Text, vchrome_calc gOmnikey_menu_selection BackgroundTrans Center, chromatics
Loop, Parse, allowed_recomb_classes, `,, `,
	If InStr(item_class, A_Loopfield) && !InStr(clipboard, "rarity: unique") && !InStr(clipboard, "unidentified")
	{
		Gui, context_menu: Add, Text, gRecombinators_add BackgroundTrans Center, recombinator
		break
	}
MouseGetPos, mouseX, mouseY
Gui, context_menu: Show, % "Hide x"mouseX " y"mouseY
WinGetPos, x_context,, w_context
Gui, context_menu: Show, % "Hide x"mouseX - w_context " y"mouseY
WinGetPos, x_context,, w_context
If (x_context < xScreenOffset)
	Gui, context_menu: Show, x%xScreenOffset% y%mouseY%
Else Gui, context_menu: Show, % "x"mouseX - w_context " y"mouseY
WinWaitActive, ahk_group poe_window
If WinExist("ahk_id " hwnd_context_menu)
	Gui, context_menu: destroy
Return

Omnikey_craft_chrome:
attribute0 := ""
attribute := ""
strength := ""
dexterity := ""
intelligence := ""
wiki_level := ""
Loop, Parse, clipboard, `r`n, `r`n
{
	If (A_Index=1)
	{
		wiki_term := StrReplace(A_LoopField, "Item Class: ")
		class := wiki_term
		wiki_term := StrReplace(wiki_term, A_Space, "_")
		If InStr(clipboard, "runic") && InStr(clipboard, "ward:")
		{
			If (class = "gloves")
				wiki_term := "Runic_Gauntlets"
			Else wiki_term := (class = "helmets") ? "Runic_Crown" : "Runic_Sabatons"
		}
	}
	If InStr(A_LoopField, "Str: ")
	{
		strength := StrReplace(A_LoopField, "Str: ")
		strength := StrReplace(strength, " (augmented)")
		strength := StrReplace(strength, " (unmet)")
	}
	Else strength := (strength="") ? 0 : strength
	If InStr(A_LoopField, "Dex: ")
	{
		dexterity := StrReplace(A_LoopField, "Dex: ")
		dexterity := StrReplace(dexterity, " (augmented)")
		dexterity := StrReplace(dexterity, " (unmet)")
	}
	Else dexterity := (dexterity="") ? 0 : dexterity
	If InStr(A_LoopField, "Int: ")
	{
		intelligence := StrReplace(A_LoopField, "Int: ")
		intelligence := StrReplace(intelligence, " (augmented)")
		intelligence := StrReplace(intelligence, " (unmet)")
	}
	Else	intelligence := (intelligence="") ? 0 : intelligence
	If InStr(A_LoopField, "Item Level: ")
	{
		wiki_level := SubStr(A_LoopField, InStr(A_LoopField, ":")+1)
		wiki_level := StrReplace(wiki_level, " ")
	}
	If InStr(A_LoopField, "Added Small Passive Skills grant: ")
	{
		wiki_cluster := SubStr(A_LoopField, 35)
		wiki_cluster := StrReplace(wiki_cluster, "+")
	}
}
If (class="Gloves") || (class="Boots") || (class="Body Armours") || (class="Helmets") || (class="Shields")
{
	If InStr(clipboard, "Armour: ")
		attribute := "_str"
	If InStr(clipboard, "Evasion Rating: ")
		attribute := (attribute="") ? "_dex" : attribute "_dex"
	If InStr(clipboard, "Energy Shield: ")
		attribute := (attribute="") ? "_int" : attribute "_int"
}
If InStr(A_GuiControl, "crafting_table")
{
	If InStr(clipboard, "unset ring")
		wiki_term := "Unset_Ring"
	If InStr(clipboard, "iron flask")
		wiki_term := "Iron_Flask"
	If InStr(clipboard, "convoking wand")
		wiki_term := "Convoking_Wand"
	If InStr(clipboard, "silver flask")
		wiki_term := "Silver_Flask"
	If InStr(wiki_term, "abyss_jewel")
	{
		wiki_index := InStr(clipboard, "rarity: normal") ? 3 : 4
		Loop, Parse, clipboard, `n, `n
		{
			If (A_Index = wiki_index)
				wiki_term := StrReplace(A_Loopfield, " ", "_")
			If InStr(A_Loopfield, "item level: ")
			{
				clipboard := StrReplace(A_Loopfield, "item level: ")
				break
			}
		}
		Run, https://poedb.tw/us/%wiki_term%
		Return
	}
	If InStr(clipboard, "Cluster Jewel")
	{
		If (A_GuiControl = "crafting_table_all_cluster")
			Run, https://poedb.tw/us/Cluster_Jewel#EnchantmentModifiers
		Else Run, https://poedb.tw/us/%cluster_type%_Cluster_Jewel#%cluster_type%ClusterJewelEnchantmentModifiers
		wiki_cluster := SubStr(wiki_cluster, 1, InStr(wiki_cluster, "(")-2)
		If (enable_browser_features = 1)
		{
			ToolTip, % "Press F3 to highlight the jewel's enchant/type", % xScreenOffset + poe_width//2, yScreenOffset + poe_height//2, 15
			SetTimer, Timeout_cluster_jewels
		}
	}
	Else If (InStr(clipboard, "runic") && InStr(Clipboard, "ward:"))
		Run, https://poedb.tw/us/%wiki_term%#ModifiersCalc
	Else Run, https://poedb.tw/us/%wiki_term%%attribute%#ModifiersCalc
	clipboard := wiki_level
}
If (A_GuiControl = "chrome_calc")
{
	Run, https://siveran.github.io/calc.html
	If (enable_browser_features = 1)
	{
		ToolTip, Click into the str field and press`nCTRL-V to paste stat requirements, % xScreenOffset + poe_width//2, yScreenOffset + poe_height//2, 15
		clipboard := ""
		SetTimer, Timeout_chromatics
	}
}
Return

Omnikey_dps:
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
MouseGetPos, mousex, mousey
ToolTip, % "pDPS: " pdps "`neDPS: " edps0 "`ncDPS: " cdps "`n-----------`ntDPS: " tdps, % mousex-80, mouseY-20, 1
KeyWait, %ThisHotkey_copy%
ToolTip,,,,1
Return

Omnikey_menu_selection:
If (A_GuiControl = "chrome_calc") || InStr(A_GuiControl, "crafting_table")
	GoSub, Omnikey_craft_chrome
Else If (A_GuiControl = "oil_wiki")
	Run, https://www.poewiki.net/wiki/Oil
Else If (A_GuiControl = "oil_table")
	Run, https://blight.raelys.com/
Else If InStr(A_GuiControl, "wiki")
	GoSub, Omnikey_wiki
Else If InStr(A_GuiControl, "layout")
	GoSub, Lab_info
Else If (A_GuiControl = "legion_seed_explore")
	GoSub, Legion_seeds_parse
KeyWait, LButton
Gui, context_menu: destroy
Return

Omnikey_wiki:
If (A_GuiControl = "wiki_exact")
	wiki_index := 3
If (A_GuiControl = "wiki_class")
	wiki_index := 1
Loop, Parse, clipboard, `n, `n 
{
	If (A_Index=wiki_index)
	{
		wiki_term := StrReplace(A_LoopField, "Item Class: ")
		wiki_term := (InStr(wiki_term, "Body")) ? "Body armour" : wiki_term
		wiki_term := StrReplace(wiki_term, A_Space, "_")
		wiki_term := StrReplace(wiki_term, "'", "%27")
		wiki_term := InStr(wiki_term, "abyss_jewel") ? "abyss_jewel" : wiki_term
		break
	}
}
If InStr(clipboard, "Cluster Jewel")
	wiki_term := "Cluster_Jewel"
If (InStr(clipboard, "runic") && InStr(clipboard, "ward:"))
	Run, https://www.poewiki.net/wiki/Runic_base_type#%wiki_term%
Else Run, https://poewiki.net/wiki/%wiki_term%
Return

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

Recombinators:
mod_pool_count := []
mod_pool_count[0] := 1 "," 1 "," 1
mod_pool_count[1] := 2/3 "," 0 "," 0
mod_pool_count[2] := 2/3 "," 1/3 "," 0
mod_pool_count[3] := 0.3 "," 0.5 "," 0.2
mod_pool_count[4] := 0.1 "," 0.55 "," 0.35
mod_pool_count[5] := 0 "," 0.5 "," 0.5
mod_pool_count[6] := 0 "," 0.3 "," 0.7
Return

Recombinator_windowGuiClose:
recomb_item1 := ""
Gui, recombinator_window: Destroy
hwnd_recombinator_window := ""
WinActivate, ahk_group poe_window
Return

Recombinators_add:
recomb_regular := 1
item_name := ""
item_class := ""
allowed := 0
Loop, Parse, clipboard, `n, `n
{
	If InStr(A_LoopField, "item class:")
	{
		item_class := StrReplace(A_LoopField, "item class:")
		item_class := StrReplace(item_class, "`r")
	}
	If (A_Index = 3)
		item_name := StrReplace(A_LoopField, "`r")
	If (A_Index = 4)
		item_name := InStr(item_class, "sentinel") ? item_name "`nsentinel" : item_name "`n" StrReplace(A_LoopField, "`r")
	If (A_Index > 4)
		break
}
StringLower, item_name, item_name	

Loop, Parse, allowed_recomb_classes, `,, `,
{
	If InStr(item_class, A_LoopField)
	{
		allowed := 1
		break
	}
}
If (allowed = 0) || InStr(clipboard, "unidentified") || InStr(clipboard, "rarity: unique")
{
	LLK_ToolTip("cannot be recombined")
	Return
}

parse_clipboard := ""
Loop, Parse, clipboard, `n, `n
{
	If (A_Loopfield = "") || ((SubStr(A_Loopfield, 1, 1) != "{") && (!InStr(A_Loopfield, "prefix") || !InStr(A_Loopfield, "suffix")))
		continue
	Else If (SubStr(A_Loopfield, 1, 1) = "{") && (InStr(A_Loopfield, "prefix") || InStr(A_Loopfield, "suffix"))
	{
		parse_clipboard := SubStr(clipboard, InStr(clipboard, A_LoopField))
		break
	}
}

prefixes := 0
suffixes := 0
Loop 3
{
	prefix_%A_Index% := ""
	suffix_%A_Index% := ""
}
Loop, Parse, parse_clipboard, `n, `n
{
	If (A_Loopfield = "")
		continue
	If (SubStr(A_Loopfield, 1, 1) = "{")
	{
		If InStr(A_Loopfield, "prefix")
		{
			prefixes += 1
			affix := "prefix"
			brace_expected := 0
		}
		Else If InStr(A_LoopField, "suffix")
		{
			suffixes += 1
			affix := "suffix"
			brace_expected := 0
		}
	}
	Else
	{
		If (brace_expected = 1)
			break
		If (SubStr(A_LoopField, 1, 1) != "(") && (affix = "prefix")
			%affix%_%prefixes% := (%affix%_%prefixes% = "") ? StrReplace(A_Loopfield, "`r") : %affix%_%prefixes% " / " StrReplace(A_Loopfield, "`r")
		Else If (SubStr(A_LoopField, 1, 1) != "(") && (affix = "suffix")
			%affix%_%suffixes% := (%affix%_%suffixes% = "") ? StrReplace(A_Loopfield, "`r") : %affix%_%suffixes% " / " StrReplace(A_Loopfield, "`r")
		%affix%_%suffixes% := StrReplace(%affix%_%suffixes%, " — Unscalable Value")
		brace_expected := InStr(A_Loopfield, "`r") ? 1 : 0
	}
	
	Loop 3
	{
		prefix_%A_Index% := StrReplace(prefix_%A_Index%, " (crafted)")
		suffix_%A_Index% := StrReplace(suffix_%A_Index%, " (crafted)")
	}
}

remove_chars := "+-0123456789()%."

Loop 3
{
	loop := A_Index
	prefix_%A_Index%_clean := ""
	suffix_%A_Index%_clean := ""
	Loop, Parse, prefix_%A_Index%
	{
		If !InStr(remove_chars, A_Loopfield)
			prefix_%loop%_clean := (prefix_%loop%_clean = "") ? A_Loopfield : prefix_%loop%_clean A_Loopfield
	}
	Loop, Parse, suffix_%A_Index%
	{
		If !InStr(remove_chars, A_Loopfield)
			suffix_%loop%_clean := (suffix_%loop%_clean = "") ? A_Loopfield : suffix_%loop%_clean A_Loopfield
	}
	loop := A_Index
	Loop 2
	{
		affix := (A_Index = 1) ? "prefix" : "suffix"
		%affix%_%loop%_clean := StrReplace(%affix%_%loop%_clean, "increased ", "% ")
		%affix%_%loop%_clean := StrReplace(%affix%_%loop%_clean, "stun and block recovery", "stun recovery")
		%affix%_%loop%_clean := (SubStr(%affix%_%loop%_clean, 1, 4) = " to ") ? SubStr(%affix%_%loop%_clean, 5) : %affix%_%loop%_clean
		%affix%_%loop%_clean := (SubStr(%affix%_%loop%_clean, 1, 4) = " of ") ? SubStr(%affix%_%loop%_clean, 5) : %affix%_%loop%_clean
		%affix%_%loop%_clean := (SubStr(%affix%_%loop%_clean, 1, 1) = " ") ? SubStr(%affix%_%loop%_clean, 2) : %affix%_%loop%_clean
		%affix%_%loop%_clean := InStr(%affix%_%loop%_clean, "/  to ") ? StrReplace(%affix%_%loop%_clean, "/  to ", "/ ") : %affix%_%loop%_clean
		%affix%_%loop%_clean := InStr(%affix%_%loop%_clean, "/  ") ? StrReplace(%affix%_%loop%_clean, "/  ", "/ ") : %affix%_%loop%_clean
		%affix%_%loop%_clean := StrReplace(%affix%_%loop%_clean, "  to  ", " ")
		%affix%_%loop%_clean := StrReplace(%affix%_%loop%_clean, "  ", " ")
		StringLower, %affix%_%loop%, %affix%_%loop%_clean
		%affix%_%loop% := (%affix%_%loop% = "") ? "(empty " affix " slot)" : %affix%_%loop%
	}
}

recomb_item2 := (recomb_item1 = "") ? "" : recomb_item1
prefix_pool2 := (prefix_pool1 = "") ? "" : prefix_pool1
prefix_pool1 := "[" prefix_1 "],[" prefix_2 "],[" prefix_3 "],"
prefix_pool1 := StrReplace(prefix_pool1, "[(empty prefix slot)],")
suffix_pool2 := (suffix_pool1 = "") ? "" : suffix_pool1
suffix_pool1 := "[" suffix_1 "],[" suffix_2 "],[" suffix_3 "],"
suffix_pool1 := StrReplace(suffix_pool1, "[(empty suffix slot)],")
recomb_item1 := item_name ":`n`n" prefix_1 "`n" prefix_2 "`n" prefix_3 "`n`n" suffix_1 "`n" suffix_2 "`n" suffix_3
recomb_item1 := StrReplace(recomb_item1, "(empty prefix slot)")
recomb_item1 := StrReplace(recomb_item1, "(empty suffix slot)")
GoSub, Recombinators_add2
Return

Recombinators_add2:
If WinExist("ahk_id " hwnd_recombinator_window)
	WinGetPos, xRecomb_window, yRecomb_window
style_recomb_window := WinExist("ahk_id " hwnd_recombinator_window) ? " x"xRecomb_window " y"yRecomb_window : " Center"
Gui, recombinator_window: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_recombinator_window, Lailloken UI: recombinators (credit: u/TheDiabeetusKing`, u/myrahz)
Gui, recombinator_window: Color, Black
Gui, recombinator_window: Margin, 12, 4
WinSet, Transparent, %trans%
Gui, recombinator_window: Font, % "s"fSize0 " cWhite", Fontin SmallCaps
Loop, Parse, recomb_item1, `n, `n
{
	If (A_Index = 1)
	{
		add_text := (StrLen(A_Loopfield) > 25) ? " [...]" : ""
		Gui, recombinator_window: Add, Text, % "Section BackgroundTrans vRecomb_item1_name w"width_native/8, % SubStr(A_Loopfield, 1, 25) add_text
		continue
	}
	If (A_Index = 2)
	{
		Gui, recombinator_window: Add, Text, % "xs y+0 BackgroundTrans vRecomb_item1_class wp", % A_Loopfield
		Gui, recombinator_window: Font, % "s"fSize0 - 4
		continue
	}
	If A_Index between 4 and 6
	{
		Gui, recombinator_window: Add, Edit, % "xs BackgroundTrans gRecombinators_input cBlack lowercase wp hp vRecomb_item1_prefix"A_Index - 3, % A_LoopField
		continue
	}
	If (A_Index = 8)
		Gui, recombinator_window: Add, Edit, % "xs BackgroundTrans gRecombinators_input cBlack lowercase wp hp y+"fSize0 " vRecomb_item1_suffix"A_Index - 7, % A_LoopField
	If (A_Index > 8)
		Gui, recombinator_window: Add, Edit, % "xs BackgroundTrans gRecombinators_input cBlack lowercase wp hp vRecomb_item1_suffix"A_Index - 7, % A_LoopField
}
recomb_item2 := (recomb_item2 = "") ? "sample item`nclass x:`n`n`n`n`n`n`n`n" : recomb_item2
If (recomb_item2 != "")
{
	prefix_pool_unique := ""
	suffix_pool_unique := ""
	prefix_pool_target := ""
	suffix_pool_target := ""
	
	Loop, Parse, recomb_item1, `n, `n
	{
		If (A_Index < 4) || (A_LoopField = "")
			continue
		If (A_Index < 8)
			prefix_pool_unique := !InStr(prefix_pool_unique, "[" A_LoopField "],") ? prefix_pool_unique "[" A_Loopfield "]," : prefix_pool_unique
		If (A_Index > 7)
			suffix_pool_unique := !InStr(suffix_pool_unique, "[" A_LoopField "],") ? suffix_pool_unique "[" A_LoopField "]," : suffix_pool_unique
	}
	Loop, Parse, recomb_item2, `n, `n
	{
		If (A_Index < 4) || (A_LoopField = "")
			continue
		If (A_Index < 8)
			prefix_pool_unique := !InStr(prefix_pool_unique, "[" A_LoopField "],") ? prefix_pool_unique "[" A_Loopfield "]," : prefix_pool_unique
		If (A_Index > 7)
			suffix_pool_unique := !InStr(suffix_pool_unique, "[" A_LoopField "],") ? suffix_pool_unique "[" A_LoopField "]," : suffix_pool_unique
	}
	prefix_pool_unique := StrReplace(prefix_pool_unique, "[(empty prefix slot)],")
	suffix_pool_unique := StrReplace(suffix_pool_unique, "[(empty suffix slot)],")
	
	Gui, recombinator_window: Font, s%fSize0% underline
	Gui, recombinator_window: Add, Text, % "xs BackgroundTrans HWNDprefix_header wp y+"fSize0*1.2, desired prefixes:
	Gui, recombinator_window: Font, % "norm s"fSize0 - 3
	Loop, Parse, prefix_pool_unique, `,, `,
	{
		If (A_Loopfield = "")
			continue
		Gui, recombinator_window: Add, Checkbox, % "xs wp BackgroundTrans gRecombinators_calc vCheckbox_prefix"A_Index, % SubStr(A_LoopField, 2, -1)
	}
	Gui, recombinator_window: Font, % "norm s"fSize0
	
	Loop, Parse, recomb_item2, `n, `n
	{
		If (A_Index = 1)
		{
			add_text := (StrLen(A_Loopfield) > 25) ? " [...]" : ""
			Gui, recombinator_window: Add, Text, % "ys Section BackgroundTrans vRecomb_item2_name w"width_native/8, % SubStr(A_Loopfield, 1, 25) add_text
			continue
		}
		If (A_Index = 2)
		{
			Gui, recombinator_window: Add, Text, % "xs y+0 BackgroundTrans vRecomb_item2_class wp", % A_Loopfield
			Gui, recombinator_window: Font, % "s"fSize0 - 4
			continue
		}
		If A_Index between 4 and 6
		{
			Gui, recombinator_window: Add, Edit, % "xs BackgroundTrans gRecombinators_input cBlack lowercase wp hp vRecomb_item2_prefix"A_Index - 3, % A_LoopField
			continue
		}
		If (A_Index = 8)
			Gui, recombinator_window: Add, Edit, % "xs BackgroundTrans gRecombinators_input cBlack lowercase wp hp y+"fSize0 " vRecomb_item2_suffix"A_Index - 7, % A_LoopField
		If (A_Index > 8)
			Gui, recombinator_window: Add, Edit, % "xs BackgroundTrans gRecombinators_input cBlack lowercase wp hp vRecomb_item2_suffix"A_Index - 7, % A_LoopField
	}
	Gui, recombinator_window: Font, underline s%fSize0%
	Gui, recombinator_window: Add, Text, % "xs BackgroundTrans HWNDsuffix_header wp y+"fSize0*1.2, desired suffixes:
	Gui, recombinator_window: Font, % "norm s"fSize0 - 3
	Loop, Parse, suffix_pool_unique, `,, `,
	{
		If (A_Loopfield = "")
			continue
		Gui, recombinator_window: Add, Checkbox, % "xs wp BackgroundTrans gRecombinators_calc vCheckbox_suffix"A_Index, % SubStr(A_LoopField, 2, -1)
	}
	Gui, recombinator_window: Font, s%fSize0% underline
	Gui, recombinator_window: Add, Text, % "xs wp vRecomb_success gRecombinators_apply BackgroundTrans y+"fSize0*1.2, % "chance of success: 100.00%"
	GuiControl, Text, recomb_success, chance of success:
	Gui, recombinator_window: Font, norm
}

ControlFocus,, ahk_id %prefix_header%
If (recomb_regular != 1)
	Gui, recombinator_window: Show, %style_recomb_window%
Else Gui, recombinator_window: Show, NA %style_recomb_window%
KeyWait, LButton
Gui, context_menu: Destroy
If (recomb_apply != 1) && (recomb_regular = 1)
	WinActivate, ahk_group poe_window
recomb_regular := 0
recomb_apply := 0
Return

Recombinators_apply:
recomb_apply := 1
refresh_needed := 0
Gui, recombinator_window: Submit, NoHide
Loop 3
{
	If InStr(recomb_item1_prefix%A_Index%, ",") || InStr(recomb_item2_prefix%A_Index%, ",") || InStr(recomb_item1_suffix%A_Index%, ",") || InStr(recomb_item2_suffix%A_Index%, ",")
	{
		LLK_ToolTip("don't use commas in text fields!")
		recomb_apply := 0
		Return
	}
}
GuiControlGet, recomb_item1_name
GuiControlGet, recomb_item1_class
GuiControlGet, recomb_item2_name
GuiControlGet, recomb_item2_class
prefix_pool1 := ""
prefix_pool2 := ""
suffix_pool1 := ""
suffix_pool2 := ""
Loop 3
{
	prefix_pool1 := (recomb_item1_prefix%A_Index% != "") ? prefix_pool1 "[" recomb_item1_prefix%A_Index% "]," : prefix_pool1
	prefix_pool2 := (recomb_item2_prefix%A_Index% != "") ? prefix_pool2 "[" recomb_item2_prefix%A_Index% "]," : prefix_pool2
	suffix_pool1 := (recomb_item1_suffix%A_Index% != "") ? suffix_pool1 "[" recomb_item1_suffix%A_Index% "]," : suffix_pool1
	suffix_pool2 := (recomb_item2_suffix%A_Index% != "") ? suffix_pool2 "[" recomb_item2_suffix%A_Index% "]," : suffix_pool2
}
recomb_item1 := recomb_item1_name "`n" recomb_item1_class "`n`n" recomb_item1_prefix1 "`n" recomb_item1_prefix2 "`n" recomb_item1_prefix3 "`n`n" recomb_item1_suffix1 "`n" recomb_item1_suffix2 "`n" recomb_item1_suffix3
recomb_item2 := recomb_item2_name "`n" recomb_item2_class "`n`n" recomb_item2_prefix1 "`n" recomb_item2_prefix2 "`n" recomb_item2_prefix3 "`n`n" recomb_item2_suffix1 "`n" recomb_item2_suffix2 "`n" recomb_item2_suffix3
;(debugging) ToolTip, % recomb_item1_prefix1 "," recomb_item1_prefix2 "," recomb_item1_prefix3 "," recomb_item1_suffix1 "," recomb_item1_suffix2 "," recomb_item1_suffix3 "`n" recomb_item2_prefix1 "," recomb_item2_prefix2 "," recomb_item2_prefix3 "," recomb_item2_suffix1 "," recomb_item2_suffix2 "," recomb_item2_suffix3 "`n"
GoSub, Recombinators_add2
Return

Recombinators_calc:
If (refresh_needed = 1)
{
	LLK_ToolTip("refresh the window first!")
	GuiControl, , %A_GuiControl%, 0
	Return
}
Gui, recombinator_window: Submit, NoHide
GuiControlGet, checkbox_text,, %A_GuiControl%, text
affix := InStr(prefix_pool_unique, "[" checkbox_text "],") ? "prefix" : "suffix"
%affix%_pool_target := InStr(%affix%_pool_target, "[" checkbox_text "],") ? StrReplace(%affix%_pool_target, "[" checkbox_text "],") : %affix%_pool_target "[" checkbox_text "],"
If (LLK_InStrCount(%affix%_pool_target, ",") > 3)
{
	LLK_ToolTip("too many " affix "es")
	%affix%_pool_target := StrReplace(%affix%_pool_target, "[" checkbox_text "],")
	GuiControl, , %A_GuiControl%, 0
	Return
}
Loop 2
{
	affix := (A_Index = 1) ? "prefix" : "suffix"
	%affix%_pool_total := %affix%_pool1 %affix%_pool2
	%affix%_pool_number := LLK_InStrCount(%affix%_pool_total, ",")
	%affix%_target_number := LLK_InStrCount(%affix%_pool_target, ",")
	%affix%_pool_unique_number := LLK_InStrCount(%affix%_pool_unique, ",")
	pool_number_offset := 0
	Loop, Parse, %affix%_pool_target, `,, `,
	{
		If (A_LoopField = "")
			continue
		If (LLK_InStrCount(%affix%_pool_total, A_Loopfield, ",") > 1)
			pool_number_offset += 1
	}
	%affix%_pool_calc := %affix%_pool_number - pool_number_offset
	Loop, Parse, % mod_pool_count[%affix%_pool_number], `,, `,
		chance_%A_Index%%affix% := A_Loopfield

	chance_1roll := 1
	chance_2roll := 1
	chance_3roll := 1
	If (%affix%_target_number != 0)
	{
		If (%affix%_pool_unique_number = 1)
			chance_1roll := (%affix%_target_number <= 1) ? 1 / %affix%_pool_unique_number : 0
		Else chance_1roll := (%affix%_target_number <= 1) ? 1 / %affix%_pool_calc : 0
		Loop 2
		{
			loopmod := A_Index - 1
			If (%affix%_pool_unique_number <= 2)
				chance_2roll *= (%affix%_target_number <= 2) ? (2 - loopmod) / (%affix%_pool_unique_number - loopmod) : 0
			Else chance_2roll *= (%affix%_target_number <= 2) ? (2 - loopmod) / (%affix%_pool_calc - loopmod) : 0
			If (A_Index = %affix%_target_number)
				break
		}
		Loop 3
		{
			loopmod := A_Index - 1
			If (%affix%_pool_unique_number <= 3)
				chance_3roll *= (3 - loopmod) / (%affix%_pool_unique_number - loopmod)
			Else chance_3roll *= (3 - loopmod) / (%affix%_pool_calc - loopmod)
			If (A_Index = %affix%_target_number)
				break
		}
		chance_2roll := (chance_2roll > 1) ? 1 : chance_2roll
		chance_3roll := (chance_3roll > 1) ? 1 : chance_3roll
	}
	Loop, 3
	{
		chance_%A_Index%roll_%affix% := chance_%A_Index%roll ;chance for X slots to hit desired mods
		chance_%A_Index%roll *= chance_%A_Index%%affix% ;chance for X slots to hit desired mods, and to appear on the final item
	}
	%affix%_chance := (%affix%_target_number != 0) ? chance_1roll + chance_2roll + chance_3roll : 1 ;chance for desired affix-group to appear on the final item
	%affix%_chance := (%affix%_chance > 1) ? 1 : %affix%_chance
}
debug_tooltip =
(
prefix_pool: %prefix_pool1%%prefix_pool2%
suffix_pool: %suffix_pool1%%suffix_pool2%
prefix_pool_unique: %prefix_pool_unique%
suffix_pool_unique: %suffix_pool_unique%
prefix_pool_target: %prefix_pool_target%
suffix_pool_target: %suffix_pool_target%
prefix roll odds: %chance_1roll_prefix%, %chance_2roll_prefix%, %chance_3roll_prefix%,
prefix slot chances: %chance_1prefix%, %chance_2prefix%, %chance_3prefix%
suffix roll odds: %chance_1roll_suffix%, %chance_2roll_suffix%, %chance_3roll_suffix%,
suffix slot chances: %chance_1suffix%, %chance_2suffix%, %chance_3suffix%
)
;ToolTip, % debug_tooltip, 0, 0
If (prefix_target_number + suffix_target_number > 0)
	GuiControl, Text, recomb_success, % "chance of success: " Format("{:0.2f}", (prefix_chance * suffix_chance)*100) "%"
Else GuiControl, Text, recomb_success, % "chance of success: "
Return

Recombinators_input:
refresh_needed := 1
GuiControl, Text, recomb_success, refresh
Return

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

Screenchecks:
If (click = 2)
{
	If InStr(A_GuiControl, "_pixel")
	{
		LLK_PixelRecalibrate(StrReplace(A_GuiControl, "_pixel"))
		GoSub, Settings_menu
		sleep, 100
		While !WinExist("ahk_id " hwnd_settings_menu)
			sleep, 100
		LLK_ToolTip("success")
	}
	Else
	{
		Clipboard := ""
		SendInput, #+{s}
		Sleep, 1000
		If WinExist("ahk_id " hwnd_settings_menu)
			WinWaitActive, ahk_id %hwnd_settings_menu%
		Else WinWaitActive, ahk_group poe_window
		If (Gdip_CreateBitmapFromClipboard() < 0)
		{
			LLK_ToolTip("screen-cap failed")
			Return
		}
		Else Gdip_SaveBitmapToFile(Gdip_CreateBitmapFromClipboard(), "img\Recognition (" poe_height "p)\GUI\" StrReplace(A_GuiControl, "_image") ".bmp", 100)
		GoSub, Settings_menu
	}
	Return
}
Else
{
	If InStr(A_GuiControl, "_pixel")
	{
		If LLK_PixelSearch(StrReplace(A_GuiControl, "_pixel"))
			LLK_ToolTip("test positive")
		Else LLK_ToolTip("test negative")
	}
	Else
	{
		If (LLK_ImageSearch(StrReplace(A_GuiControl, "_image")) > 0)
			LLK_ToolTip("test positive")
		Else LLK_ToolTip("test negative")
	}
}
Return

Screenchecks_gamescreen:
total_pixelcheck_enable := clone_frames_pixelcheck_enable + map_info_pixelcheck_enable
If (total_pixelcheck_enable = 0)
	pixelchecks_enabled := StrReplace(pixelchecks_enabled, "gamescreen,")
Else pixelchecks_enabled := InStr(pixelchecks_enabled, "gamescreen") ? pixelchecks_enabled : pixelchecks_enabled "gamescreen,"
Return

Screenchecks_settings_apply:
Gui, settings_menu: Submit, NoHide
If InStr(A_GuiControl, "disable_imagecheck")
{
	IniWrite, % %A_GuiControl%, ini\screen checks (%poe_height%p).ini, % StrReplace(A_GuiControl, "disable_imagecheck_"), disable
	FileDelete, % "img\Recognition (" poe_height "p)\GUI\" StrReplace(A_GuiControl, "disable_imagecheck_") ".bmp"
	GoSub, Settings_menu
	Return
}
If (A_GuiControl = "image_folder")
{
	Run, explore img\Recognition (%poe_height%p)\GUI\
	Return
}
If (A_GuiControl = "enable_pixelchecks")
	IniWrite, %enable_pixelchecks%, ini\config.ini, Settings, background pixel-checks
If (enable_pixelchecks = 0)
{
	gamescreen := 0
	clone_frames_pixelcheck_enable := 0
	IniWrite, 0, ini\clone frames.ini, Settings, enable pixel-check
	map_info_pixelcheck_enable := 0
	IniWrite, 0, ini\map info.ini, Settings, enable pixel-check
}
Else
{
	clone_frames_pixelcheck_enable := 1
	IniWrite, 1, ini\clone frames.ini, Settings, enable pixel-check
	map_info_pixelcheck_enable := 1
	IniWrite, 1, ini\map info.ini, Settings, enable pixel-check
}
Return

Settings_menu:
SetTimer, Settings_menu, Delete
start := A_TickCount
While GetKeyState("LButton", "P") && (A_Gui = "LLK_panel")
{
	If (A_TickCount >= start + 300)
	{
		WinGetPos,,, wGui, hGui, % "ahk_id " hwnd_%A_Gui%
		While GetKeyState("LButton", "P")
			GoSub, Panel_drag
		KeyWait, LButton
		panel_xpos := panelXpos
		panel_ypos := panelYpos
		IniWrite, % panel_xpos, ini\config.ini, UI, button xcoord
		IniWrite, % panel_ypos, ini\config.ini, UI, button ycoord
		WinActivate, ahk_group poe_window
		Return
	}
}
If (A_GuiControl = "LLK_panel") && (click = 2)
{
	KeyWait, RButton
	Reload
	ExitApp
}
If WinExist("ahk_id " hwnd_settings_menu)
	WinGetPos, xsettings_menu, ysettings_menu,,, ahk_id %hwnd_settings_menu%
If WinExist("ahk_id " hwnd_settings_menu) && (A_Gui = "LLK_panel")
{
	GoSub, Settings_menuGuiClose
	WinActivate, ahk_group poe_window
	Return
}
settings_style := InStr(A_GuiControl, "general") || (A_Gui = "LLK_panel") || (A_Gui = "") ? "cAqua" : "cWhite"
alarm_style := InStr(A_GuiControl, "alarm") ? "cAqua" : "cWhite"
betrayal_style := (InStr(A_GuiControl, "betrayal") && !InStr(A_GuiControl, "image")) ? "cAqua" : "cWhite"
clone_frames_style := InStr(A_GuiControl, "clone") || (new_clone_menu_closed = 1) ? "cAqua" : "cWhite"
delve_style := InStr(A_GuiControl, "delve") ? "cAqua" : "cWhite"
flask_style := InStr(A_GuiControl, "flask") ? "cAqua" : "cWhite"
leveling_style := InStr(A_GuiControl, "leveling") ? "cAqua" : "cWhite"
map_mods_style := InStr(A_GuiControl, "map") ? "cAqua" : "cWhite"
notepad_style := InStr(A_GuiControl, "notepad") ? "cAqua" : "cWhite"
omnikey_style := InStr(A_GuiControl, "omni-key") ? "cAqua" : "cWhite"
pixelcheck_style := (InStr(A_GuiControl, "check") || InStr(A_GuiControl, "image") || InStr(A_GuiControl, "pixel")) ? "cAqua" : "cWhite"
stash_style := InStr(A_GuiControl, "search-strings") || InStr(A_GuiControl, "stash_search") ||(new_stash_search_menu_closed = 1) ? "cAqua" : "cWhite"
geforce_style := InStr(A_GuiControl, "geforce") ? "cAqua" : "cLime"
GuiControl_copy := A_GuiControl
If (A_Gui = "settings_menu")
{
	Gui, settings_menu: Submit
	kill_timeout := (kill_timeout = "") ? 0 : kill_timeout
}
Gui, settings_menu: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_settings_menu, Lailloken UI: settings
Gui, settings_menu: Color, Black
Gui, settings_menu: Margin, 12, 4
WinSet, Transparent, %trans%
Gui, settings_menu: Font, s%fSize0% cWhite underline, Fontin SmallCaps

Gui, settings_menu: Add, Text, % "Section BackgroundTrans " settings_style " gSettings_menu HWNDhwnd_settings_general", % "general"
ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_general%
spacing_settings := width_settings

If (pixel_gamescreen_color1 = "ERROR" || pixel_gamescreen_color1 = "")
	screenchecks_gamescreen_valid := 0
Else screenchecks_gamescreen_valid := 1

Loop, Parse, imagechecks_list, `,, `,
{
	screenchecks_%A_Loopfield%_valid := 1
	If !FileExist("img\Recognition (" poe_height "p)\GUI\" A_Loopfield ".bmp") && (disable_imagecheck_%A_Loopfield% = 0)
		screenchecks_%A_Loopfield%_valid := 0
}

screenchecks_all_valid := 1
screenchecks_all_valid *= screenchecks_gamescreen_valid

Loop, Parse, imagechecks_list, `,, `,
	screenchecks_all_valid *= screenchecks_%A_Loopfield%_valid

If !InStr(buggy_resolutions, poe_height) && (safe_mode != 1)
{
	Gui, settings_menu: Add, Text, xs BackgroundTrans %alarm_style% gSettings_menu HWNDhwnd_settings_alarm, % "alarm-timer"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_alarm%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	
	Gui, settings_menu: Add, Text, xs BackgroundTrans %betrayal_style% gSettings_menu HWNDhwnd_settings_betrayal, % "betrayal-info"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_betrayal%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings

	Gui, settings_menu: Add, Text, xs BackgroundTrans %clone_frames_style% gSettings_menu HWNDhwnd_settings_clone_frames, % "clone-frames"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_clone_frames%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	
	Gui, settings_menu: Add, Text, xs BackgroundTrans %delve_style% gSettings_menu HWNDhwnd_settings_delve, % "delve-helper"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_delve%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	
	If FileExist(poe_log_file)
	{
		Gui, settings_menu: Add, Text, xs BackgroundTrans %leveling_style% gSettings_menu HWNDhwnd_settings_leveling, % "leveling tracker"
		ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_leveling%
		spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	}
	Gui, settings_menu: Add, Text, xs BackgroundTrans %map_mods_style% gSettings_menu HWNDhwnd_settings_map_mods, % "map-info"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_map_mods%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings

	Gui, settings_menu: Add, Text, xs BackgroundTrans %notepad_style% gSettings_menu HWNDhwnd_settings_notepad, % "notepad"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_notepad%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings

	Gui, settings_menu: Add, Text, xs BackgroundTrans %omnikey_style% gSettings_menu HWNDhwnd_settings_omnikey, % "omni-key"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_omnikey%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings

	If pixel_gamescreen_x1 is number
	{
		If (screenchecks_all_valid = 0)
			pixelcheck_style := "cRed"
		Gui, settings_menu: Add, Text, xs BackgroundTrans %pixelcheck_style% gSettings_menu HWNDhwnd_settings_pixelcheck, % "screen-checks"
		ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_pixelcheck%
		spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	}
	
	Gui, settings_menu: Add, Text, xs BackgroundTrans %stash_style% gSettings_menu HWNDhwnd_settings_stashsearch, % "search-strings"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_stashsearch%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
	
	If WinExist("ahk_exe GeForceNOW.exe")
	{
		Gui, settings_menu: Add, Text, xs BackgroundTrans %geforce_style% gSettings_menu HWNDhwnd_settings_geforce, % "geforce now"
		ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_geforce%
		spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
		Gui, settings_menu: Font, cWhite
	}
}
Gui, settings_menu: Font, norm

If !InStr(GuiControl_copy, "notepad") && WinExist("ahk_id " hwnd_notepad_sample)
{
	Gui, notepad_sample: Destroy
	hwnd_notepad_sample := ""
}

If !InStr(GuiControl_copy, "alarm") && WinExist("ahk_id " hwnd_alarm_sample)
{
	Gui, alarm_sample: Destroy
	hwnd_alarm_sample := ""
}

If !InStr(GuiControl_copy, "delve") && WinExist("ahk_id " hwnd_delve_grid)
{
	Gui, delve_grid: Destroy
	hwnd_delve_grid := ""
	Gui, delve_grid2: Destroy
	hwnd_delve_grid2 := ""
}

If InStr(GuiControl_copy, "general") || (A_Gui = "LLK_panel") || (A_Gui = "")
	GoSub, Settings_menu_general
Else If InStr(GuiControl_copy, "alarm")
	GoSub, Settings_menu_alarm
Else If InStr(GuiControl_copy, "betrayal") && !InStr(GuiControl_copy, "image")
	GoSub, Settings_menu_betrayal
Else If InStr(GuiControl_copy, "clone") || (new_clone_menu_closed = 1)
	GoSub, Settings_menu_clone_frames
Else If InStr(GuiControl_copy, "delve")
{
	xsettings_menu := xScreenOffSet
	ysettings_menu := yScreenOffSet + poe_height/3
	GoSub, Settings_menu_delve
}
Else If InStr(GuiControl_copy, "leveling")
	GoSub, Settings_menu_leveling_guide
Else If InStr(GuiControl_copy, "map")
	GoSub, Settings_menu_map_info
Else If InStr(GuiControl_copy, "notepad")
	GoSub, Settings_menu_notepad
Else If InStr(GuiControl_copy, "omni")
	GoSub, Settings_menu_omnikey
Else If InStr(GuiControl_copy, "image") || InStr(GuiControl_copy, "pixel") || InStr(GuiControl_copy, "screen")
	GoSub, Settings_menu_screenchecks
Else If InStr(GuiControl_copy, "search-strings") || InStr(GuiControl_copy, "stash_search") || (new_stash_search_menu_closed = 1)
	GoSub, Settings_menu_stash_search
Else If InStr(GuiControl_copy, "geforce")
	GoSub, Settings_menu_geforce_now

If !InStr(GuiControl_copy, "betrayal")
{
	ControlFocus,, ahk_id %hwnd_settings_general%
	LLK_Overlay("betrayal_info", "hide")
	LLK_Overlay("betrayal_info_overview", "hide")
	LLK_Overlay("betrayal_info_members", "hide")
	Loop, Parse, betrayal_divisions, `,, `,
		LLK_Overlay("betrayal_prioview_" A_Loopfield, "hide")
}
Else ControlFocus,, ahk_id %hwnd_betrayal_edit%

If ((xsettings_menu != "") && (ysettings_menu != ""))
	Gui, settings_menu: Show, Hide x%xsettings_menu% y%ysettings_menu%
Else Gui, settings_menu: Show, Hide
LLK_Overlay("settings_menu", "show", 1)
Return

Settings_menu_alarm:
Gui, settings_menu: Add, Checkbox, % "ys Section BackgroundTrans venable_alarm gApply_settings_alarm checked"enable_alarm " xp+"spacing_settings*1.2, enable alarm-timer
If (enable_alarm = 1)
{
	GoSub, Alarm
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text color:
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans vfontcolor_white cWhite gApply_settings_alarm Border", % " white "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_red cRed gApply_settings_alarm Border x+"fSize0//4, % " red "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_aqua cAqua gApply_settings_alarm Border x+"fSize0//4, % " cyan "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_yellow cYellow gApply_settings_alarm Border x+"fSize0//4, % " yellow "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_lime cLime gApply_settings_alarm Border x+"fSize0//4, % " lime "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_fuchsia cFuchsia gApply_settings_alarm Border x+"fSize0//4, % " purple "
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text-size offset:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_alarm_minus gApply_settings_alarm Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_alarm_reset gApply_settings_alarm Border x+2 wp", % "0"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_alarm_plus gApply_settings_alarm Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans", opacity:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center valarm_opac_minus gApply_settings_alarm Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center valarm_opac_plus gApply_settings_alarm Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, button size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_alarm_minus gApply_settings_alarm Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_alarm_reset gApply_settings_alarm Border x+2 wp", % "0"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_alarm_plus gApply_settings_alarm Border x+2 wp", % "+"
}
Return

Settings_menu_betrayal:
Gui, settings_menu: Add, Checkbox, % "ys Section Center gBetrayal_apply vBetrayal_enable_recognition BackgroundTrans xp+"spacing_settings*1.2 " Checked"betrayal_enable_recognition, use image recognition`n(requires additional setup)
Gui, settings_menu: Add, Checkbox, % "xs Section Center gBetrayal_apply vBetrayal_perma_table BackgroundTrans Checked"betrayal_perma_table, enable table in recognition-mode
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans Border gBetrayal_apply vImage_folder HWNDmain_text", % " open img folder "

choice := (betrayal_info_table_pos = "left") ? 1 : 2
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text y+"fSize0*1.2, % "table position: "
ControlGetPos,,, width,,, ahk_id %main_text%
Gui, settings_menu: Font, % "s"fSize0 - 4
Gui, settings_menu: Add, DDL, % "ys x+0 hp BackgroundTrans cBlack r2 vbetrayal_info_table_pos gBetrayal_apply Choose"choice " w"width/2, left||right
Gui, settings_menu: Font, % "s"fSize0

Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text-size offset:
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_betrayal_minus gBetrayal_apply Border", % " – "
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_betrayal_reset gBetrayal_apply Border x+2 wp", % "0"
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_betrayal_plus gBetrayal_apply Border x+2 wp", % "+"

Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans", opacity:
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbetrayal_opac_minus gBetrayal_apply Border", % " – "
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbetrayal_opac_plus gBetrayal_apply Border x+2 wp", % "+"

color := (betrayal_info_prio_dimensions = 0) || (betrayal_info_prio_transportation = "0,0") || (betrayal_info_prio_fortification = "0,0") || (betrayal_info_prio_research = "0,0") || (betrayal_info_prio_intervention = "0,0") ? "Red" : "White"
Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2 " c"color, % "prio-view settings"
Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", % "frame dimensions: "
Gui, settings_menu: Font, % "s"fSize0 - 4
Gui, settings_menu: Add, Edit, % "ys x+0 Center BackgroundTrans cBlack hp vbetrayal_info_prio_dimensions gBetrayal_apply", % (betrayal_info_prio_dimensions = 0) ? 100 : betrayal_info_prio_dimensions
Gui, settings_menu: Font, % "s"fSize0
Gui, settings_menu: Add, Text, % "ys Center Border BackgroundTrans vbetrayal_info_prio_apply gBetrayal_apply", % " save "

GoSub, Betrayal_search
GoSub, GUI_betrayal_prioview
Return

Settings_menu_clone_frames:
new_clone_menu_closed := 0
clone_frames_enabled := ""
IniRead, clone_frames_list, ini\clone frames.ini
Sort, clone_frames_list, D`n
If (pixel_gamescreen_x1 != "") && (pixel_gamescreen_x1 != "ERROR") && (enable_pixelchecks = 1)
{
	Gui, settings_menu: Add, Checkbox, % "ys Section BackgroundTrans gClone_frames_apply vClone_frames_pixelcheck_enable Checked" clone_frames_pixelcheck_enable " xp+"spacing_settings*1.2, toggle overlay automatically
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vpixelcheck_auto_trigger hp w-1", img\GUI\help.png
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, list of clone-frames currently set up:
}
Else Gui, settings_menu: Add, Text, % "ys Section BackgroundTrans xp+"spacing_settings*1.2, list of clone-frames currently set up:
Loop, Parse, clone_frames_list, `n, `n
{
	If (A_LoopField = "Settings")
		continue
	If clone_frame_%A_LoopField%_enable is not number
		IniRead, clone_frame_%A_LoopField%_enable, ini\clone frames.ini, %A_LoopField%, enable, 1
	If (clone_frame_%A_LoopField%_enable = 1)
	{
		clone_frames_enabled := (clone_frames_enabled = "") ? A_LoopField "," : A_LoopField "," clone_frames_enabled
		Gui, clone_frames_%A_Loopfield%: New, -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_%A_Loopfield%
	}
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gClone_frames_apply Checked" clone_frame_%A_LoopField%_enable " vClone_frame_" A_LoopField "_enable", % "enable: "
	Gui, settings_menu: Font, underline
	Gui, settings_menu: Add, Text, % "ys x+0 BackgroundTrans gClone_frames_preview_list", % A_LoopField
	Gui, settings_menu: Font, norm
}
Gui, settings_menu: Add, Text, % "xs Section Border gClone_frames_new vClone_frames_add BackgroundTrans y+"fSize0*1.2, % " add frame "
Return

Settings_menu_delve:
Gui, settings_menu: Add, Checkbox, % "ys Section BackgroundTrans venable_delve gDelve checked"enable_delve " xp+"spacing_settings*1.2, enable delve-helper
If (enable_delve = 1)
{
	GoSub, Delve
	GoSub, GUI
	Gui, settings_menu: Add, Checkbox, % "xs Center gDelve vdelve_enable_recognition BackgroundTrans Checked"delve_enable_recognition, use image recognition`n(requires additional setup)
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, grid size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vdelvegrid_minus gDelve Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vdelvegrid_reset gDelve Border x+2 wp", % "0"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vdelvegrid_plus gDelve Border x+2 wp", % "+"
	
	If FileExist(poe_log_file)
	{
		Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans venable_delvelog gDelve checked"enable_delvelog " y+"fSize0*1.2, % "only show button while delving"
		Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vdelve_help hp w-1", img\GUI\help.png
	}
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", button size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_delve_minus gDelve Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_delve_reset gDelve Border x+2 wp", % "0"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_delve_plus gDelve Border x+2 wp", % "+"
}
Return

Settings_menu_geforce_now:
Gui, settings_menu: Add, Text, % "ys Section BackgroundTrans HWNDmain_text xp+"spacing_settings*1.2, % "pixel-check allowed variation: "
ControlGetPos,,,, controlheight,, ahk_id %main_text%
Gui, settings_menu: Font, % "s"fSize0-4 "norm"
Gui, settings_menu: Add, Edit, % "ys x+0 hp BackgroundTrans cBlack Number gGeforce_now_apply Center Limit3 vPixelsearch_variation w"controlheight*1.6, %pixelsearch_variation%
Gui, settings_menu: Font, s%fSize0%
Gui, settings_menu: Add, Text, % "xs Section y+0 BackgroundTrans", % "(range: 0–255, default: 0) "
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vGeForce_now_help hp w-1", img\GUI\help.png

Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text y+"fSize0*1.2, % "image-check allowed variation: "
ControlGetPos,,,, controlheight,, ahk_id %main_text%
Gui, settings_menu: Font, % "s"fSize0-4 "norm"
Gui, settings_menu: Add, Edit, % "ys x+0 hp BackgroundTrans cBlack Number gGeforce_now_apply Center Limit3 vImagesearch_variation w"controlheight*1.6, %imagesearch_variation%
Gui, settings_menu: Font, s%fSize0%
Gui, settings_menu: Add, Text, % "xs BackgroundTrans", % "(range: 0–255, default: 25)"
Return

Settings_menu_general:
Gui, settings_menu: Add, Checkbox, % "ys Section BackgroundTrans gApply_settings_general HWNDmain_text Checked" kill_script " vkill_script xp+"spacing_settings*1.2, % "kill script after"
ControlGetPos,,,, controlheight,, ahk_id %main_text%

Gui, settings_menu: Font, % "s"fSize0-4 "norm"
Gui, settings_menu: Add, Edit, % "ys x+0 hp BackgroundTrans cBlack Number gApply_settings_general right Limit2 vkill_timeout w"controlheight*1.2, %kill_timeout%
Gui, settings_menu: Font, % "s"fSize0
Gui, settings_menu: Add, Text, % "ys BackgroundTrans x+"fSize0//2, % "minute(s) w/o poe-client"

Gui, settings_menu: Add, Link, % "xs hp Section HWNDlink_text y+"fSize0*1.2, <a href="https://github.com/Lailloken/Lailloken-UI/discussions/49">custom resolution:</a>
If (fullscreen = "true")	
	Gui, settings_menu: Add, Text, % "ys hp BackgroundTrans HWNDmain_text vcustom_width x+"fSize0//2, % poe_width
Else
{
	Gui, settings_menu: Font, % "s"fSize0-4
	Gui, settings_menu: Add, Edit, % "ys hp Limit4 Number Right cBlack BackgroundTrans vcustom_width HWNDmain_text x+"fSize0//2, % width_native
	GuiControl, text, custom_width, % poe_width
	Gui, settings_menu: Font, % "s"fSize0
}
Gui, settings_menu: Add, Text, % "ys hp BackgroundTrans x+0", %  " x "
ControlGetPos,,,, height,, ahk_id %main_text%
ControlGetPos,,, width,,, ahk_id %main_text%
resolutionsDDL := ""
IniRead, resolutions_all, data\Resolutions.ini
choice := 0
Loop, Parse, resolutions_all, `n,`n
	If !(InStr(A_LoopField, "768") || InStr(A_LoopField, "1024") || InStr(A_LoopField, "1050")) && !(StrReplace(A_LoopField, "p", "") > height_native) && !((StrReplace(A_Loopfield, "p") >= height_native) && (fullscreen != "true"))
		resolutionsDDL := (resolutionsDDL = "") ? StrReplace(A_LoopField, "p", "") : StrReplace(A_LoopField, "p", "") "|" resolutionsDDL
resolutionsDDL := (resolutionsDDL = "") ? height_native : resolutionsDDL
Loop, Parse, resolutionsDDL, |, |
	If (A_LoopField = poe_height)
		choice := A_Index
choice := (choice = 0) ? 1 : choice
Gui, settings_menu: Font, % "s"fSize0-4
Gui, settings_menu: Add, DDL, % "ys BackgroundTrans HWNDmain_text vcustom_resolution r10 Choose" choice " x+0 w"width*1.5 " hp", % resolutionsDDL
Gui, settings_menu: Font, % "s"fSize0
If (fullscreen = "false")
	Gui, settings_menu: Add, Checkbox, % "ys BackgroundTrans Checked" window_docking " vwindow_docking gApply_resolution", % "top-docked"
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans Border gApply_resolution", % " apply && restart "
Gui, settings_menu: Add, Checkbox, % "ys BackgroundTrans HWNDmain_text Checked" custom_resolution_setting " vcustom_resolution_setting gApply_resolution", % "apply on startup "

Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans Checked" hide_panel " vhide_panel gApply_settings_general y+"fSize0*1.2, % "hide llk-ui panel"
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "interface size:"
Gui, settings_menu: Add, Text, ys x+6 BackgroundTrans gApply_settings_general vinterface_size_minus Border Center, % " – "
Gui, settings_menu: Add, Text, wp x+2 ys BackgroundTrans gApply_settings_general vinterface_size_reset Border Center, % "0"
Gui, settings_menu: Add, Text, wp x+2 ys BackgroundTrans gApply_settings_general vinterface_size_plus Border Center, % "+"

Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans y+"fSize0*1.2 " vEnable_browser_features gApply_settings_general Checked"enable_browser_features, % "enable browser features"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vBrowser_features_help hp w-1", img\GUI\help.png

Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans y+"fSize0*1.2 " vEnable_caps_toggling gApply_settings_general Checked"enable_caps_toggling, % "enable capslock-toggling"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vCaps_toggling_help hp w-1", img\GUI\help.png
Return

Settings_menu_help:
MouseGetPos, mouseXpos, mouseYpos
Gui, settings_menu_help: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_settings_menu_help
Gui, settings_menu_help: Color, Black
Gui, settings_menu_help: Margin, 12, 4
Gui, settings_menu_help: Font, s%fSize1% cWhite, Fontin SmallCaps

If (A_GuiControl = "gear_tracker_help")
{
text =
(
the drop-down list contains the most recent characters found in the client-log.

items that are ready to be equipped are highlighted green. the list only shows items up to 5 levels higher than your character.

clicking an item on the list will highlight it in game (stash and vendors). right-clicking will remove it from the list.

you can click the 'select character' label to highlight all green items at once.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "leveling_guide_help")
{
text =
(
explanation
checking this option will enable scanning the client-log generated by the game-client in order to track your character's current location and level.

depending on its file-size and other factors, this may affect general performance.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "delve_help")
{
text =
(
explanation
checking this option will enable scanning the client-log generated by the game-client in order to check whether your character is in the azurite mine.

depending on its file-size and other factors, this may affect general performance.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "map_info")
{
text =
(
explanation
0 hides the mod from now on, and higher values have distinct text-colors.

it's up to you how to tier the mods and whether to use all tiers.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "browser_features_help")
{
text =
(
explanation
enables complementary features when accessing 3rd-party websites in your browser

examples
- chromatics calculator: auto-input of required stats
- cluster jewel crafting: F3 quick-search
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "caps_toggling_help")
{
text =
(
explanation
toggling this checkbox will restart the script due to code-limitations (and the settings menu will close).

if enabled, the script will toggle the state of capslock to off before sending key-presses in order to avoid case-inversions.

the system will handle this toggling as a capslock key-press, so anything bound to it will be activated.

uncheck this option if you have something bound to capslock (e.g. push-to-talk), but keep in mind unwanted case-inversion may occur as a consequence.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "stash_search_new_help")
{
text =
(
explanation
name: has to be unique, otherwise an existing search with the same name will be replaced. only use numbers and regular letters!

use-cases: select which search-fields the string will be used for.

string: has to be a valid string that works in game. it will not be corrected or checked for errors here, so make sure it works before saving it.

scrolling: if enabled, scrolling will adjust a number within the string. strings can only contain -one- number.

string 2: an optional secondary string. this will be used when right-clicking the shortcut.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "geforce_now_help")
{
text =
(
explanation
since geforce now is a streaming-based client, its image quality can fluctuate significantly.
this results in screen-checks being inconsistent and the script behaving abnormally.
to counteract this, screen-checks can be 'loosened' in order to be less strict and adapt to changing image-quality.

instructions
if you have problems with screen-checks, increase variation by 15 and see if that fixes it.
repeat until the script's behavior becomes stable.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "pixelcheck_auto_trigger")
{
text =
(
explanation
allows the script to automatically hide/show its overlays by adapting to what's happening on screen.

requires 'gamescreen' pixel-check to be set up correctly and playing with the mini-map in the center of the screen.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}

If (A_GuiControl = "pixelcheck_help")
{
text =
(
explanation
left-click the button to test the pixel-check, right-click the button to calibrate.

ui textures in PoE sometimes get updated in patches, which leads to screen-checks failing. this is where you recalibrate the checks in order to continue using the script.

disclaimer
these screen-checks merely trigger actions within the script itself and will -NEVER- result in any interaction with the client.

they are used to let the script toggle its ui elements in order to adapt to what's happening on screen, emulating the use of an addon-api.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}
If InStr(A_GuiControl, "gamescreen")
{
text =
(
instructions
to recalibrate, close the inventory and every menu until you're on the main screen (where you control your character). then, set the mini-map to overlay-mode on the center of the screen.

explanation
this check helps the script identify whether the user is in a menu or on the regular 'gamescreen', which enables it to hide overlays automatically in order to prevent obstructing full-screen menus.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"fSize0*20 " w-1", img\GUI\game_screen.jpg
	Gui, settings_menu_help: Add, Text, BackgroundTrans wp, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}
If (A_GuiControl = "pixelcheck_enable_help")
{
text =
(
explanation
this should only be disabled when experiencing severe performance drops while running the script.

when disabled, overlays will not show/hide automatically (if the user navigates through in-game menus) and they have to be toggled manually.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}


If (A_GuiControl = "imagecheck_help")
{
text =
(
explanation
left-click the button to test the image-check, right-click the button to screen-cap.

same concept as pixel-checks (see top of this section) but with images instead of pixels. image-checks are used when pixel-checks are unreliable due to movement on screen.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}
If InStr(A_GuiControl, "bestiary")
{
text =
(
instructions
to recalibrate, open the beastcrafting window and screen-cap the plate displayed above.

explanation
this check helps the script identify whether the beastcrafting window is open or not, which enables the omni-key to trigger open the beastcrafting context-menu.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"fSize0*20 " w-1", img\GUI\bestiary.jpg
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}
If InStr(A_GuiControl, "betrayal")
{
text =
(
instructions
to recalibrate, open the syndicate board, do not zoom into or move it, and screen-cap the area displayed above.
(UltraWide-users: that area will not be right above the health globe but more towards the center).

explanation
this check helps the script identify whether the syndicate board is up or not, which enables the omni-key to trigger the betrayal-info feature.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"fSize0*20 " w-1", img\GUI\betrayal.jpg
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}
If InStr(A_GuiControl, "gwennen")
{
text =
(
instructions
to recalibrate, open Gwennen's gamble window and screen-cap the plate displayed above.

explanation
this check helps the script identify whether Gwennen's gamble window is open or not, which enables the omni-key to trigger the regex-string features.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"fSize0*20 " w-1", img\GUI\gwennen.jpg
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}
If (A_GuiControl = "stash_help")
{
text =
(
instructions
to recalibrate, open your stash and screen-cap the plate displayed above.

explanation
this check helps the script identify whether your stash is open or not, which enables the omni-key to trigger the search-string features.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"fSize0*20 " w-1", img\GUI\stash.jpg
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}
If InStr(A_GuiControl, "vendor")
{
text =
(
instructions
to recalibrate, open the purchase-window of a vendor and screen-cap the plate displayed above.

explanation
this check helps the script identify whether you are interacting with a vendor-npc, which enables the omni-key to trigger the search-string features.

limitation
campaign-lilly and hideout-lilly use different vendor windows. if you don't use search-strings with general vendors, you can calibrate this image-check with hideout-lilly's window. otherwise, you'll have to buy gems from lilly in Act 10 when using the tracker-gems string.
)
	Gui, settings_menu_help: Add, Picture, % "BackgroundTrans w"fSize0*20 " w-1", img\GUI\vendor.jpg
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}


If InStr(A_GuiControl, "omnikey")
{
text =
(
explanation
this hotkey is context-sensitive and used to access the majority of this script's features. it's meant to be the only hotkey you have to use while playing.

this feature does not block the key-press from being sent to the client. if you still want/need to rebind it, bind it to a key that's not used for chatting.

rebinding it will also require clicking certain UI elements (e.g. search fields) in the game first, which is not necessary with the middle mouse-button since it also acts like a click.
)
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, % text
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}
WinGetPos, winx, winy, width, height, ahk_id %hwnd_settings_menu_help%
newxpos := (winx + width > xScreenOffSet + poe_width) ? xScreenOffSet + poe_width - width : winx
newypos := (winy + height > yScreenOffSet + poe_height) ? yScreenOffSet + poe_height - height : winy
Gui, Settings_menu_help: Show, NA x%newxpos% y%newypos%
KeyWait, LButton
Gui, settings_menu_help: Destroy
Return

Settings_menu_leveling_guide:
Gui, settings_menu: Add, Checkbox, % "ys Section BackgroundTrans gLeveling_guide xp+"spacing_settings*1.2 " venable_leveling_guide Checked"enable_leveling_guide, % "enable leveling tracker"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vLeveling_guide_help hp w-1", img\GUI\help.png
If (enable_leveling_guide = 1)
{
	Gui, settings_menu: Font, underline bold
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "guide settings:"
	Gui, settings_menu: Font, norm
	Gui, settings_menu: Add, Text, % "xs Section Border Center gLeveling_guide vLeveling_guide_generate BackgroundTrans", % " generate guide "
	Gui, settings_menu: Add, Text, % "ys Center Border gLeveling_guide vLeveling_guide_import BackgroundTrans", % " import guide "
	
	If (guide_progress = "")
		IniRead, guide_progress, ini\leveling guide.ini, Progress,, % A_Space
	IniRead, guide_text_original, ini\leveling guide.ini, Steps,, % A_Space
	guide_progress_percent := (guide_progress != "" && guide_text_original != "") ? Format("{:0.2f}", (LLK_InStrCount(guide_progress, "`n")/LLK_InStrCount(guide_text_original, "`n"))*100) : 0
	guide_progress_percent := (guide_progress_percent >= 99) ? 100 : guide_progress_percent
	Gui, settings_menu: Add, Text, % "xs Section vLeveling_guide_progress BackgroundTrans", % "current progress: " guide_progress_percent "%"
	Gui, settings_menu: Add, Text, % "ys Center Border gLeveling_guide vLeveling_guide_reset BackgroundTrans", % " reset progress "
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", % "credit: "
	Gui, settings_menu: Add, Link, % "ys x+0 hp", <a href="https://github.com/HeartofPhos/exile-leveling">exile-leveling</a>
	Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans x+"fSize0//3, % "created by"
	Gui, settings_menu: Add, Link, % "ys hp x+"fSize0//3, <a href="https://github.com/HeartofPhos">HeartofPhos</a>
	
	Gui, settings_menu: Font, underline bold
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "ui settings:"
	Gui, settings_menu: Font, norm
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", text color:
	Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans vfontcolor_white cWhite gLeveling_guide Border", % " white "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_red cRed gLeveling_guide Border x+"fSize0//4, % " red "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_aqua cAqua gLeveling_guide Border x+"fSize0//4, % " cyan "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_yellow cYellow gLeveling_guide Border x+"fSize0//4, % " yellow "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_lime cLime gLeveling_guide Border x+"fSize0//4, % " lime "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_fuchsia cFuchsia gLeveling_guide Border x+"fSize0//4, % " purple "
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", text-size offset:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_leveling_guide_minus gLeveling_guide Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_leveling_guide_reset gLeveling_guide Border x+2 wp", % "0"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_leveling_guide_plus gLeveling_guide Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans", opacity:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vleveling_guide_opac_minus gLeveling_guide Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vleveling_guide_opac_plus gLeveling_guide Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", position:
	Gui, settings_menu: Add, Radio, % InStr(leveling_guide_position, "top") ? "ys BackgroundTrans vleveling_guide_position_top gLeveling_guide Checked" : "ys BackgroundTrans vleveling_guide_position_top gLeveling_guide", top
	;Gui, settings_menu: Add, Radio, % InStr(leveling_guide_position, "right") ? "ys BackgroundTrans vleveling_guide_position_right gLeveling_guide Checked" : "ys BackgroundTrans vleveling_guide_position_right gLeveling_guide", right
	Gui, settings_menu: Add, Radio, % InStr(leveling_guide_position, "bottom") ? "ys BackgroundTrans vleveling_guide_position_bottom gLeveling_guide Checked" : "ys BackgroundTrans vleveling_guide_position_bottom gLeveling_guide", bottom
	;Gui, settings_menu: Add, Radio, % InStr(leveling_guide_position, "left") ? "ys BackgroundTrans vleveling_guide_position_left gLeveling_guide Checked" : "ys BackgroundTrans vleveling_guide_position_left gLeveling_guide", left
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans", button size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_leveling_guide_minus gLeveling_guide Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_leveling_guide_reset gLeveling_guide Border x+2 wp", % "0"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_leveling_guide_plus gLeveling_guide Border x+2 wp", % "+"
}
Return

Settings_menu_map_info:
map_info_primary := 0
If (enable_pixelchecks = 1) && (pixel_gamescreen_x1 != "") && (pixel_gamescreen_x1 != "ERROR")
{
	Gui, settings_menu: Add, Checkbox, % "ys Section BackgroundTrans gMap_info_settings_apply xp+"spacing_settings*1.2 " vMap_info_pixelcheck_enable Checked"Map_info_pixelcheck_enable, toggle overlay automatically
	Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vPixelcheck_auto_trigger hp w-1", img\GUI\help.png
	map_info_primary := 1
}
If (map_info_primary = 0)
	Gui, settings_menu: Add, Text, % "ys Section Center BackgroundTrans xp+"spacing_settings*1.2, text-size offset:
Else Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text-size offset:
	
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_map_info_minus gMap_info_settings_apply Border", % " – "
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_map_info_reset gMap_info_settings_apply Border x+2 wp", % "0"
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_map_info_plus gMap_info_settings_apply Border x+2 wp", % "+"

Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans", opacity:
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vmap_info_opac_minus gMap_info_settings_apply Border", % " – "
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vmap_info_opac_plus gMap_info_settings_apply Border x+2 wp", % "+"

Gui, settings_menu: Add, Checkbox, % "xs Section Center gMap_info_settings_apply vMap_info_short BackgroundTrans Checked"map_info_short " y+"fSize0*1.2, % "short mod descriptions"

Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.2, % "search for mods: "
Gui, settings_menu: Font, % "s"fSize0 - 4
Gui, settings_menu: Add, Edit, % "ys x+0 cBlack BackgroundTrans Limit gMap_info_customization vMap_info_search wp"
Gui, settings_menu: Font, % "s"fSize0

GoSub, Map_info
Return

Settings_menu_notepad:
Gui, settings_menu: Add, Checkbox, % "ys Section BackgroundTrans gApply_settings_notepad xp+"spacing_settings*1.2 " venable_notepad Checked"enable_notepad, enable notepad
If (enable_notepad = 1)
{
	GoSub, Notepad
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text color (widget):
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans vfontcolor_white cWhite gApply_settings_notepad Border", % " white "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_red cRed gApply_settings_notepad Border x+"fSize0//4, % " red "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_aqua cAqua gApply_settings_notepad Border x+"fSize0//4, % " cyan "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_yellow cYellow gApply_settings_notepad Border x+"fSize0//4, % " yellow "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_lime cLime gApply_settings_notepad Border x+"fSize0//4, % " lime "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfontcolor_fuchsia cFuchsia gApply_settings_notepad Border x+"fSize0//4, % " purple "
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text-size offset:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_notepad_minus gApply_settings_notepad Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_notepad_reset gApply_settings_notepad Border x+2 wp", % "0"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vfSize_notepad_plus gApply_settings_notepad Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "ys Center BackgroundTrans", opacity:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vnotepad_opac_minus gApply_settings_notepad Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vnotepad_opac_plus gApply_settings_notepad Border x+2 wp", % "+"
	
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, button size:
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_notepad_minus gApply_settings_notepad Border", % " – "
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_notepad_reset gApply_settings_notepad Border x+2 wp", % "0"
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans Center vbutton_notepad_plus gApply_settings_notepad Border x+2 wp", % "+"
}
Return

Settings_menu_omnikey:
If (A_GuiControl = "omnikey_restart")
{
	Gui, settings_menu: Submit, NoHide
	Loop, Parse, blocked_hotkeys, `,, `,
	{
		If (SubStr(omnikey_hotkey2, 1, 1) = A_Loopfield)
		{
			LLK_ToolTip("Chosen omni-hotkey is not supported")
			Return
		}
	}
	IniWrite, % alt_modifier, ini\config.ini, Settings, highlight-key
	IniWrite, % omnikey_hotkey2, ini\config.ini, Settings, omni-hotkey2
	Reload
	ExitApp
	Return
}
If (GuiControl_copy = "reset_omnikey_hotkey") && (omnikey_hotkey != "")
{
	Hotkey, IfWinActive, ahk_group poe_ahk_window
	Hotkey, *~%omnikey_hotkey%,, Off
	omnikey_hotkey := ""
	If (omnikey_conflict_c != 1)
		Hotkey, *~MButton, Omnikey, On
	Else Hotkey, *~MButton, Omnikey2, On
	IniWrite, % omnikey_hotkey, ini\config.ini, Settings, omni-hotkey
}

Gui, settings_menu: Add, Text, % "ys Section BackgroundTrans HWNDmain_text xp+"spacing_settings*1.2, replace mbutton with:
ControlGetPos,,, width,,, ahk_id %main_text%
Gui, settings_menu: Font, % "s"fSize0-4
Gui, settings_menu: Add, Hotkey, % "ys hp BackgroundTrans vomnikey_hotkey gApply_settings_omnikey w"width//3, %omnikey_hotkey%
Gui, settings_menu: Font, % "s"fSize0
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Border vreset_omnikey_hotkey gSettings_menu", % " clear "
Gui, settings_menu: Add, Picture, % "ys BackgroundTrans vOmnikey_help gSettings_menu_help hp w-1", img\GUI\help.png

If (omnikey_conflict_alt = 1) || (omnikey_conflict_c = 1)
{
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0, % "troubleshooting (custom keybinds):"
	If (omnikey_conflict_alt = 1)
	{
		Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans", % "highlight-key:"
		Gui, settings_menu: Font, % "s"fSize0 - 4
		Gui, settings_menu: Add, Edit, % "ys hp valt_modifier BackgroundTrans cBlack w"width//3, % alt_modifier
		Gui, settings_menu: Font, % "s"fSize0
	}
	If (omnikey_conflict_c = 1)
	{
		Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans", % "omni-key (items):"
		Gui, settings_menu: Font, % "s"fSize0 - 4
		Gui, settings_menu: Add, Hotkey, % "ys hp vomnikey_hotkey2 BackgroundTrans w"width//3, % omnikey_hotkey2
		Gui, settings_menu: Font, % "s"fSize0
	}
	Gui, settings_menu: Add, Text, % "xs Border vomnikey_restart gSettings_menu_omnikey Section BackgroundTrans", % " apply && restart "
}
Return

Settings_menu_screenchecks:
Gui, settings_menu: Add, Text, % "ys Section BackgroundTrans HWNDmain_text xp+"spacing_settings*1.2, % "list of integrated pixel-checks: "
ControlGetPos,,,, height,, ahk_id %main_text%
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vPixelcheck_help hp w-1", img\GUI\help.png
Loop, Parse, pixelchecks_list, `,, `,
{
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text border gScreenchecks v" A_Loopfield "_pixel y+"fSize0*0.6, % " test | calibrate "
	If (screenchecks_%A_Loopfield%_valid = 0)
		Gui, settings_menu: Font, cRed underline
	Else Gui, settings_menu: Font, cWhite underline
	Gui, settings_menu: Add, Text, % "ys BackgroundTrans gSettings_menu_help v" A_Loopfield "_help HWNDmain_text", % A_Loopfield
	Gui, settings_menu: Font, norm cWhite
}
Gui, settings_menu: Font, norm
Gui, settings_menu: Add, Checkbox, % "hp xs Section BackgroundTrans gScreenchecks_settings_apply vEnable_pixelchecks Center Checked"enable_pixelchecks, % "enable background pixel-checks"
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vPixelcheck_enable_help hp w-1", img\GUI\help.png

Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text y+"fSize0*1.5, % "list of integrated image-checks: "
Gui, settings_menu: Add, Picture, % "ys x+0 BackgroundTrans gSettings_menu_help vImagecheck_help hp w-1", img\GUI\help.png
Loop, Parse, imagechecks_list, `,, `,
{
	Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text border gScreenchecks v" A_Loopfield "_image y+"fSize0*0.6, % " test | calibrate "
	loopfield_copy := StrReplace(A_Loopfield, "-", "_")
	loopfield_copy := StrReplace(loopfield_copy, " ", "_")
	Gui, settings_menu: Add, Checkbox, % "ys BackgroundTrans gScreenchecks_settings_apply Checked" disable_imagecheck_%loopfield_copy% " vDisable_imagecheck_" loopfield_copy, % "disable: "
	If (screenchecks_%A_Loopfield%_valid = 0)
		Gui, settings_menu: Font, cRed underline
	Else Gui, settings_menu: Font, cWhite underline
	Gui, settings_menu: Add, Text, % "ys x+0 BackgroundTrans gSettings_menu_help v" A_Loopfield "_help", % A_Loopfield
	Gui, settings_menu: Font, norm cWhite
}
Gui, settings_menu: Font, norm
ControlGetPos,,, width,,, ahk_id %main_text%
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans Center Border gScreenchecks_settings_apply vImage_folder HWNDmain_text y+"fSize0*0.6 " w"width, % " img folder "
Return

Settings_menu_stash_search:
new_stash_search_menu_closed := 0
Gui, settings_menu: Add, Text, % "ys Section BackgroundTrans xp+"spacing_settings*1.2, list of searches currently set up:
IniRead, stash_search_list, ini\stash search.ini
Sort, stash_search_list, D`n
Loop, Parse, stash_search_list, `n, `n
{
	loopfield_copy := StrReplace(A_Loopfield, "|", "vertbar")
	If (A_LoopField = "Settings")
		continue
	If stash_search_%loopfield_copy%_enable is not number
		IniRead, stash_search_%loopfield_copy%_enable, ini\stash search.ini, %A_LoopField%, enable, 1
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gStash_search_apply Checked" stash_search_%loopfield_copy%_enable " vStash_search_" loopfield_copy "_enable", % "enable: "
	Gui, settings_menu: Font, underline
	text := StrReplace(A_Loopfield, "_", " ")
	Gui, settings_menu: Add, Text, % "ys x+0 BackgroundTrans gStash_search_preview_list", % text
	Gui, settings_menu: Font, norm
}
Gui, settings_menu: Add, Text, % "xs Section Border gStash_search_new vStash_add BackgroundTrans y+"fSize0*1.2, % " add string "
Return

Settings_menuGuiClose:
WinGetPos, xsettings_menu, ysettings_menu,,, ahk_id %hwnd_settings_menu%
Gui, settings_menu: Submit
kill_timeout := (kill_timeout = "") ? 0 : kill_timeout
Gui, settings_menu: Destroy
hwnd_settings_menu := ""

LLK_Overlay("betrayal_info", "hide")
LLK_Overlay("betrayal_info_overview", "hide")
LLK_Overlay("betrayal_info_members", "hide")
Loop, Parse, betrayal_divisions, `,, `,
	LLK_Overlay("betrayal_prioview_" A_Loopfield, "hide")

Gui, delve_grid: Destroy
hwnd_delve_grid := ""
Gui, delve_grid2: Destroy
hwnd_delve_grid2 := ""

If WinExist("ahk_id " hwnd_notepad_sample)
{
	Gui, notepad_sample: Destroy
	hwnd_notepad_sample := ""
}

If WinExist("ahk_id " hwnd_alarm_sample)
{
	Gui, alarm_sample: Destroy
	hwnd_alarm_sample := ""
}
WinActivate, ahk_group poe_window
Return

Stash_search:
If (A_Gui != "") || (stash_search_trigger = 1)
{
	If (stash_search_trigger != 1)
	{
		string_number := (click = 2) ? 2 : 1
		IniRead, stash_search_string, ini\stash search.ini, % StrReplace(A_GuiControl, " ", "_"), string %string_number%
		IniRead, stash_search_scroll, ini\stash search.ini, % StrReplace(A_GuiControl, " ", "_"), string %string_number% enable scrolling, 0
		KeyWait, LButton
		Gui, stash_search_context_menu: Destroy
		WinActivate, ahk_group poe_window
		WinWaitActive, ahk_group poe_window
	}
	Else
	{
		IniRead, stash_search_string, ini\stash search.ini, % Loopfield_copy, string 1
		IniRead, stash_search_scroll, ini\stash search.ini, % Loopfield_copy, string 1 enable scrolling, 0
	}
	
	Loop
	{
		If (scrollboard%A_Index% != "")
			scrollboard%A_Index% := ""
		Else break
	}
	
	If InStr(stash_search_string, ";")
	{
		scrollboards := 0
		Loop, Parse, stash_search_string, `;, `;
		{
			If (A_Loopfield = "")
				continue
			scrollboard%A_Index% := A_Loopfield
			scrollboards += 1
		}
		scrollboard_active := 1
	}
	
	clipboard := (scrollboard1 = "") ? stash_search_string : scrollboard1
	ClipWait, 0.05
	SendInput, ^{f}^{v}
	If (stash_search_scroll = 1)
	{
		SetTimer, Stash_search_scroll, 100
		stash_search_scroll_mode := 1
	}
	Return
}
MouseGetPos, mouseXpos, mouseYpos
Gui, stash_search_context_menu: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_stash_search_context_menu
Gui, stash_search_context_menu: Margin, 4, 2
Gui, stash_search_context_menu: Color, Black
WinSet, Transparent, %trans%
Gui, stash_search_context_menu: Font, s%fSize0% cWhite, Fontin SmallCaps

IniRead, stash_search_shortcuts, ini\stash search.ini, Settings, % stash_search_type, % A_Space
stash_search_shortcuts_enabled := 0
enabled_shortcuts := ""

Loop, Parse, stash_search_shortcuts, `,,`,
{
	If (A_Loopfield = "")
		continue
	Loopfield_copy := StrReplace(SubStr(A_Loopfield, 2, -1), "|", "vertbar")
	IniRead, stash_search_%Loopfield_copy%_enabled, ini\stash search.ini, % StrReplace(Loopfield_copy, "vertbar", "|"), enable, 0
	stash_search_shortcuts_enabled += stash_search_%Loopfield_copy%_enabled
	enabled_shortcuts .= (stash_search_%Loopfield_copy%_enabled = 1) ? Loopfield_copy "," : ""
}
If (stash_search_shortcuts = "" || stash_search_shortcuts_enabled < 1)
{
	LLK_ToolTip("no strings for this search")
	Return
}

If (stash_search_shortcuts_enabled = 1) ;if only one search-string is enabled, check whether it has two strings
{
	Loopfield_copy := StrReplace(SubStr(enabled_shortcuts, 1, -1), "vertbar", "|")
	IniRead, parse_secondary_click, ini\stash search.ini, % Loopfield_copy, string 2
	If (parse_secondary_click = "")
	{
		Gui, stash_search_context_menu: Destroy
		hwnd_stash_search_context_menu := ""
		stash_search_trigger := 1
		GoSub, Stash_search
		stash_search_trigger := 0
		Return
	}
}

Loop, Parse, stash_search_shortcuts, `,, `,
{
	If (A_LoopField = "")
		continue
	Loopfield_copy := StrReplace(SubStr(A_Loopfield, 2, -1), "|", "vertbar")
	If (stash_search_%Loopfield_copy%_enabled = 1)
		Gui, stash_search_context_menu: Add, Text, gStash_search BackgroundTrans Center, % StrReplace(SubStr(A_LoopField, 2, -1), "_", " ")
}

Gui, Show, x%mouseXpos% y%mouseYpos%
WinWaitActive, ahk_group poe_window
If WinExist("ahk_id " hwnd_stash_search_context_menu)
	Gui, stash_search_context_menu: destroy
Return

Stash_search_apply:
Gui, settings_menu: Submit, NoHide
GuiControl_copy := StrReplace(A_GuiControl, "stash_search_")
GuiControl_copy := StrReplace(GuiControl_copy, "_enable")
GuiControl_copy := StrReplace(GuiControl_copy, "vertbar", "|")
IniWrite, % %A_GuiControl%, ini\stash search.ini, % GuiControl_copy, enable
Return

Stash_search_delete:
delete_string := StrReplace(A_GuiControl, "delete_", "")
delete_string := StrReplace(delete_string, " ", "_")
delete_string := StrReplace(delete_string, "vertbar", "|")
Loop, Parse, stash_search_usecases, `,, `,
{
	IniRead, stash_search_%A_Loopfield%_parse, ini\stash search.ini, Settings, % A_Loopfield
	If InStr(stash_search_%A_Loopfield%_parse, "(" delete_string "),")
		IniWrite, % StrReplace(stash_search_%A_Loopfield%_parse, "(" delete_string "),"), ini\stash search.ini, Settings, % A_Loopfield
}
IniDelete, ini\stash search.ini, %delete_string%
new_stash_search_menu_closed := 1
GoSub, Settings_menu
Return

Stash_search_new:
Gui, settings_menu: Submit
LLK_Overlay("settings_menu", "hide")


If (stash_search_edit_mode = 1)
{
	edit_name := StrReplace(A_GuiControl, "edit_", "")
	edit_name := StrReplace(edit_name, "vertbar", "|")
	Loop, Parse, stash_search_usecases, `,, `,
	{
		IniRead, stash_search_%A_LoopField%_parse, ini\stash search.ini, Settings, % A_LoopField
		stash_search_edit_use_%A_Loopfield% := InStr(stash_search_%A_LoopField%_parse, edit_name) ? 1 : 0
	}
	IniRead, stash_search_edit_scroll1, ini\stash search.ini, % edit_name, string 1 enable scrolling, 0
	IniRead, stash_search_edit_string1, ini\stash search.ini, % edit_name, string 1, % A_Space
	IniRead, stash_search_edit_scroll2, ini\stash search.ini, % edit_name, string 2 enable scrolling, 0
	IniRead, stash_search_edit_string2, ini\stash search.ini, % edit_name, string 2, % A_Space
	stash_search_edit_mode := 0
}
Else
{
	edit_name := ""
	Loop, Parse, stash_search_usecases, `,, `,
		stash_search_edit_use_%A_Loopfield% := 0
	stash_search_edit_scroll1 := 0
	stash_search_edit_scroll2 := 0
	stash_search_edit_string1 := ""
	stash_search_edit_string2 := ""
}


Gui, stash_search_menu: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_stash_search_menu, Lailloken UI: search-strings configuration
Gui, stash_search_menu: Color, Black
Gui, stash_search_menu: Margin, 12, 4
WinSet, Transparent, %trans%
Gui, stash_search_menu: Font, s%fSize0% cWhite, Fontin SmallCaps

Gui, stash_search_menu: Add, Text, Section BackgroundTrans HWNDmain_text, % "unique search name: "
ControlGetPos,,, width,,, ahk_id %main_text%

Gui, stash_search_menu: Font, % "s"fSize0-4 "norm"
Gui, stash_search_menu: Add, Edit, % "ys x+0 hp BackgroundTrans cBlack lowercase vStash_search_new_name wp", % StrReplace(edit_name, "_", " ")

Gui, stash_search_menu: Font, % "s"fSize0
Gui, stash_search_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text y+"fSize0, % "use-cases: "
Loop, Parse, stash_search_usecases, `,, `,
{
	If (A_Index = 1 || A_Index = 5)
		Gui, stash_search_menu: Add, Checkbox, % "xs Section BackgroundTrans vStash_search_use_" A_Loopfield " w"width/2 " Checked"stash_search_edit_use_%A_Loopfield%, % A_Loopfield
	Else Gui, stash_search_menu: Add, Checkbox, % "ys BackgroundTrans vStash_search_use_" A_Loopfield " w"width/2 " Checked"stash_search_edit_use_%A_Loopfield%, % A_Loopfield
}

Gui, stash_search_menu: Font, % "s"fSize0
Gui, stash_search_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0, % "search string 1:"
Gui, stash_search_menu: Add, Checkbox, % "ys BackgroundTrans vStash_search_new_scroll Checked"stash_search_edit_scroll1, enable scrolling
Gui, stash_search_menu: Font, % "s"fSize0-4 "norm"
Gui, stash_search_menu: Add, Edit, % "xs Section hp BackgroundTrans lowercase cBlack vStash_search_new_string w"width*2, % stash_search_edit_string1
Gui, stash_search_menu: Font, % "s"fSize0
Gui, stash_search_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text y+"fSize0, % "search string 2:"
Gui, stash_search_menu: Add, Checkbox, % "ys BackgroundTrans vStash_search_new_scroll1 Checked"stash_search_edit_scroll2, enable scrolling
Gui, stash_search_menu: Font, % "s"fSize0-4 "norm"
Gui, stash_search_menu: Add, Edit, % "xs Section hp BackgroundTrans lowercase cBlack vStash_search_new_string1 w"width*2, % stash_search_edit_string2
Gui, stash_search_menu: Font, % "s"fSize0
Gui, stash_search_menu: Add, Text, xs Section Border BackgroundTrans vStash_search_save gStash_search_save y+%fSize0%, % " save && close "
Gui, stash_search_menu: Add, Picture, % "ys BackgroundTrans gSettings_menu_help vStash_search_new_help hp w-1", img\GUI\help.png

Gui, stash_search_menu: Show, % "Hide Center"
LLK_Overlay("stash_search_menu", "show", 0)
Return

Stash_search_menuGuiClose:
new_stash_search_menu_closed := 1
GoSub, Settings_menu
Gui, stash_search_menu: Destroy
Return

Stash_search_preview_list:
MouseGetPos, mouseXpos, mouseYpos
GuiControl_copy := StrReplace(A_GuiControl, " ", "_")
If (click = 2)
{
	GuiControl_copy := StrReplace(GuiControl_copy, "|", "vertbar")
	Gui, stash_search_context_menu: New, -Caption +Border +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_stash_search_context_menu
	Gui, stash_search_context_menu: Margin, % fSize0//2, fSize0//2
	Gui, stash_search_context_menu: Color, Black
	WinSet, Transparent, %trans%
	Gui, stash_search_context_menu: Font, cWhite s%fSize0%, Fontin SmallCaps
	stash_search_edit_mode := 1
	Gui, stash_search_context_menu: Add, Text, Section BackgroundTrans vEdit_%GuiControl_copy% gStash_search_new, edit
	Gui, stash_search_context_menu: Add, Text, % "xs BackgroundTrans vDelete_" GuiControl_copy " gStash_search_delete y+"fSize0//2, delete
	Gui, stash_search_context_menu: Show, % "AutoSize x"mouseXpos + fSize0 " y"mouseYpos + fSize0
	WinWaitNotActive, ahk_id %hwnd_stash_search_context_menu%
	stash_search_edit_mode := 0
	Gui, stash_search_context_menu: Destroy
	Return
}
Gui, stash_search_preview_list: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs +Border HWNDhwnd_stash_search_preview_list
Gui, stash_search_preview_list: Margin, % 12, 4
Gui, stash_search_preview_list: Color, Black
WinSet, Transparent, %trans%
Gui, stash_search_preview_list: Font, cWhite s%fSize0%, Fontin SmallCaps

use_case := ""
Loop, Parse, stash_search_usecases, `,, `,
{
	IniRead, stash_search_%A_Loopfield%_parse, ini\stash search.ini, Settings, % A_Loopfield
	use_case := InStr(stash_search_%A_Loopfield%_parse, GuiControl_copy) ? use_case A_Loopfield "," : use_case
}
use_case := (SubStr(use_case, 0) = ",") ? SubStr(use_case, 1, -1) : use_case
IniRead, primary_string, ini\stash search.ini, % GuiControl_copy, string 1, % A_Space
IniRead, secondary_string, ini\stash search.ini, % GuiControl_copy, string 2, % A_Space
secondary_string := (secondary_string = "") ? "" : "`nstring 2: " secondary_string
Gui, stash_search_preview_list: Add, Text, Section BackgroundTrans, % "use-cases: " StrReplace(use_case, ",", ", ") "`nstring 1: " primary_string secondary_string
Gui, stash_search_preview_list: Show, NA x%mouseXpos% y%mouseYpos%
KeyWait, LButton
Gui, stash_search_preview_list: Destroy
Return

Stash_search_scroll:
ToolTip, % "              scrolling...`n              ESC to exit",,, 11
KeyWait, ESC, D T0.05
If !ErrorLevel
{
	SetTimer, stash_search_scroll, delete
	ToolTip,,,, 11
	stash_search_scroll_mode := 0
}
Return

Stash_search_save:
Gui, stash_search_menu: Submit, NoHide
stash_search_new_name_first_letter := SubStr(stash_search_new_name, 1, 1)
checkbox_sum := 0
If (stash_search_new_name = "")
{
	LLK_ToolTip("enter a name")
	Return
}
Loop, Parse, stash_search_usecases, `,, `,
	checkbox_sum += stash_search_use_%A_Loopfield%
If (checkbox_sum = 0)
{
	LLK_ToolTip("set at least one use-case")
	Return
}
If (stash_search_new_string = "") && (stash_search_new_string1 = "")
{
	LLK_ToolTip("enter a string")
	Return
}
If (stash_search_new_string = "") && (stash_search_new_string1 != "")
{
	LLK_ToolTip("first string is empty, but second is not")
	Return
}
If (stash_search_new_name = "settings")
{
	LLK_ToolTip("The selected name is not allowed.`nPlease choose a different name.", 3)
	GuiControl, stash_search_menu: Text, stash_search_new_name,
	Return
}
If stash_search_new_name_first_letter is not alnum
{
	LLK_ToolTip("Unsupported first character in frame-name detected.`nPlease choose a different name.", 3)
	GuiControl, stash_search_menu: Text, stash_search_new_name,
	Return
}

Loop 2
{
	loop := A_Index
	string_mod := (A_Index = 1) ? "" : 1
	If (stash_search_new_scroll%string_mod% = 1)
	{
		parse_string := ""
		numbers := 0
		Loop, Parse, stash_search_new_string%string_mod%
		{
			If A_Loopfield is number
				parse_string := (parse_string = "") ? A_Loopfield : parse_string A_Loopfield
			Else parse_string := (parse_string = "") ? "," : parse_string ","
		}
		If !InStr(stash_search_new_string%string_mod%, ";")
		{
			Loop, Parse, parse_string, `,, `,
			{
				If A_Loopfield is number
					numbers += 1
				If (numbers > 1)
				{
					LLK_ToolTip("cannot scroll:`nstring " loop " has more than`none number", 2)
					Return
				}
			}
		}
		If (numbers = 0) && !InStr(stash_search_new_string%string_mod%, ";")
		{
			LLK_ToolTip("cannot scroll string " loop ":`nno number or semi-colon")
			Return
		}
	}
}

stash_search_new_name_save := ""
Loop, Parse, stash_search_new_name
{
	If (A_LoopField = A_Space)
		add_character := "_"
	Else If (A_Loopfield = "|")
		add_character := "|"
	Else If A_LoopField is not alnum
		add_character := "_"
	Else add_character := A_LoopField
	stash_search_new_name_save := (stash_search_new_name_save = "") ? add_character : stash_search_new_name_save add_character
}

usecases := ""
Loop, Parse, stash_search_usecases, `,, `,
{
	IniRead, ThisUsecase, ini\stash search.ini, Settings, % A_Loopfield
	If (stash_search_use_%A_Loopfield% = 1) && !InStr(ThisUsecase, "(" stash_search_new_name_save "),")
		IniWrite, % ThisUsecase "(" stash_search_new_name_save "),", ini\stash search.ini, Settings, % A_Loopfield
	Else If (stash_search_use_%A_Loopfield% = 0) && InStr(ThisUsecase, "(" stash_search_new_name_save "),")
		IniWrite, % StrReplace(ThisUsecase, "(" stash_search_new_name_save "),"), ini\stash search.ini, Settings, % A_Loopfield
}

stash_search_new_string := (SubStr(stash_search_new_string, 0) = ";") ? SubStr(stash_search_new_string, 1, -1) : stash_search_new_string
stash_search_new_string := StrReplace(stash_search_new_string, ";;", ";")
stash_search_new_string1 := (SubStr(stash_search_new_string1, 0) = ";") ? SubStr(stash_search_new_string1, 1, -1) : stash_search_new_string1
stash_search_new_string1 := StrReplace(stash_search_new_string1, ";;", ";")
IniWrite, 1, ini\stash search.ini, % stash_search_new_name_save, enable
IniWrite, "%stash_search_new_string%", ini\stash search.ini, % stash_search_new_name_save, string 1
IniWrite, % stash_search_new_scroll, ini\stash search.ini, % stash_search_new_name_save, string 1 enable scrolling
IniWrite, "%stash_search_new_string1%", ini\stash search.ini, % stash_search_new_name_save, string 2
IniWrite, % stash_search_new_scroll1, ini\stash search.ini, % stash_search_new_name_save, string 2 enable scrolling
GoSub, settings_menu
Gui, stash_search_menu: Destroy
Return

Test:
SoundBeep
Return

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

LLK_DelveGrid(node)
{
	loop := 1
	While (node > 7)
	{
		node -= 7
		loop += 1
	}
	xcoord := node
	ycoord := look
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
	If (hotstring = "gwen")
		gwennen_regex := clipboard
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
		Run, https://www.poewiki.net/w/index.php?search=%hotstringboard%
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
	Gui, gear_tracker_indicator: Add, Text, % "BackgroundTrans Center vgear_tracker_upgrades gLeveling_guide_gear", % "00"
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