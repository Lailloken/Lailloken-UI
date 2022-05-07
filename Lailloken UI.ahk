#NoEnv
#SingleInstance, Force
#InstallKeybdHook
#InstallMouseHook
#Hotstring EndChars `n
#Hotstring NoMouse
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
OnMessage(0x0204, "LLK_Rightclick")
SetKeyDelay, 100
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
CoordMode, ToolTip, Screen
SendMode, Input
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1
OnExit, Exit
Menu, Tray, Tip, Lailloken UI
#Include Class_CustomFont.ahk
font1 := New CustomFont("Fontin-SmallCaps.ttf")
timeout := 1

If !pToken := Gdip_Startup()
{
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}

GroupAdd, poe_window, ahk_exe PathOfExile.exe
GroupAdd, poe_window, ahk_exe PathOfExile_x64.exe
GroupAdd, poe_window, ahk_exe PathOfExileSteam.exe
GroupAdd, poe_window, ahk_exe PathOfExile_x64Steam.exe
GroupAdd, poe_window, ahk_exe GeForceNOW.exe

If !FileExist("Resolutions.ini")
	LLK_Error("Critical files are missing. Make sure have installed the script correctly.")
If !FileExist("ini\")
	FileCreateDir, ini\

IniWrite, 12400, ini\config.ini, Versions, ini-version ;1.24.1 = 12401, 1.24.10 = 12410
IniRead, kill_timeout, ini\config.ini, Settings, kill-timeout, 1
IniRead, kill_script, ini\config.ini, Settings, kill script, 1

startup := A_TickCount
While !WinExist("ahk_group poe_window")
{
	If (A_TickCount >= startup + kill_timeout*60000) && (kill_script = 1)
		ExitApp
	sleep, 5000
}

last_check := A_TickCount
WinGetPos, xScreenOffset, yScreenOffset, poe_width, poe_height, ahk_group poe_window

;determine native resolution of the active monitor
Gui, Test: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow -Caption
WinSet, Trans, 0
Gui, Test: Show, x%xScreenOffset% y%yScreenOffset% Maximize
WinGetPos,,, width_native, height_native
Gui, Test: Destroy

IniRead, fSize_config0, Resolutions.ini, %poe_height%p, font-size0
IniRead, fSize_config1, Resolutions.ini, %poe_height%p, font-size1
fSize0 := fSize_config0
fSize1 := fSize_config1

IniRead, custom_resolution_setting, ini\config.ini, Settings, enable custom-resolution
If (custom_resolution_setting != 0) && (custom_resolution_setting != 1)
{
	IniWrite, 0, ini\config.ini, Settings, enable custom-resolution
	custom_resolution_setting := 0
}

If (custom_resolution_setting = 1)
{
	IniRead, custom_resolution, ini\config.ini, Settings, custom-resolution
	If custom_resolution is not number
	{
		MsgBox, Incorrect config.ini settings detected: custom resolution enabled but none selected.`nThe setting will be reset and the script restarted.
		IniWrite, 0, ini\config.ini, Settings, enable custom-resolution
		Reload
		ExitApp
	}

	If (custom_resolution > height_native) ;check resolution in case of manual .ini edit
	{
		MsgBox, Incorrect config.ini settings detected: custom height > monitor height`nThe script will now exit.
		IniWrite, 0, ini\config.ini, Settings, enable custom-resolution
		IniWrite, %height_native%, ini\config.ini, Settings, custom-resolution
		ExitApp
	}
	WinMove, ahk_group poe_window,, %xScreenOffset%, %yScreenOffset%, %poe_width%, %custom_resolution%
	poe_height := custom_resolution
}

trans := 220

IniRead, panel_position0, ini\config.ini, UI, panel-position0, bottom
IniRead, panel_position1, ini\config.ini, UI, panel-position1, left
IniRead, hide_panel, ini\config.ini, UI, hide panel, 0

IniRead, game_version, ini\config.ini, Versions, game-version, 31800 ;3.17.4 = 31704, 3.17.10 = 31710
IniRead, resolution_warning, ini\config.ini, Versions, resolution warning, 0
IniRead, fSize_offset, ini\config.ini, UI, font-offset, 0
fSize0 := fSize_config0 + fSize_offset
fSize1 := fSize_config1 + fSize_offset

IniRead, alarm_xpos, ini\alarm.ini, UI, xcoord, % xScreenOffset+poe_width//2
alarm_xpos := (alarm_xpos = "") ? xScreenOffset+poe_width//2 : alarm_xpos
IniRead, alarm_ypos, ini\alarm.ini, UI, ycoord, % yScreenOffset+poe_height//2
alarm_ypos := (alarm_ypos = "") ? yScreenOffset+poe_height//2 : alarm_ypos
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

If !FileExist("ini\clone frames.ini")
	IniWrite, 0, ini\clone frames.ini, Settings, enable pixel-check
IniRead, clone_frames_list, ini\clone frames.ini,
IniRead, clone_frames_pixelcheck_enable, ini\clone frames.ini, Settings, enable pixel-check, 0
If (clone_frames_pixelcheck_enable = 1)
	pixelchecks_enabled := (pixelchecks_enabled = "") ? "gamescreen," : pixelchecks_enabled "gamescreen,"
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

IniRead, notepad_xpos, ini\notepad.ini, UI, xcoord, % xScreenOffset+poe_width//2
notepad_xpos := (notepad_xpos = "") ? xScreenOffset+poe_width//2 : notepad_xpos
IniRead, notepad_ypos, ini\notepad.ini, UI, ycoord, % yScreenOffset+poe_height//2
notepad_ypos := (notepad_ypos = "") ? yScreenOffset+poe_height//2 : notepad_ypos
IniRead, notepad_width, ini\notepad.ini, UI, width, 400
IniRead, notepad_height, ini\notepad.ini, UI, height, 400
IniRead, notepad_text, ini\notepad.ini, Text, text, %A_Space%
If (notepad_text != "")
	notepad_text := StrReplace(notepad_text, ",,", "`n")
IniRead, fSize_offset_notepad, ini\notepad.ini, Settings, font-offset, 0
If fSize_offset_notepad is not number
	fSize_offset_notepad := 0
IniRead, notepad_fontcolor, ini\notepad.ini, Settings, font-color, %A_Space%
notepad_fontcolor := (notepad_fontcolor = "") ? "White" : notepad_fontcolor
IniRead, notepad_trans, ini\notepad.ini, Settings, transparency
If notepad_trans is not number
	notepad_trans := 255

IniRead, pixelchecks_list, Resolutions.ini, Pixel-checks
Loop, Parse, pixelchecks_list, `n, `n
{
	IniRead, pixel_%A_LoopField%_x1, Resolutions.ini, %poe_height%p, %A_LoopField% x-coordinate 1
	IniRead, pixel_%A_LoopField%_y1, Resolutions.ini, %poe_height%p, %A_LoopField% y-coordinate 1
	If (A_LoopField != "gamescreen")
	{
		IniRead, pixel_%A_LoopField%_x2, Resolutions.ini, %poe_height%p, %A_LoopField% x-coordinate 2
		IniRead, pixel_%A_LoopField%_y2, Resolutions.ini, %poe_height%p, %A_LoopField% y-coordinate 2
	}
	IniRead, pixel_%A_LoopField%_color1, ini\pixel checks (%poe_height%p).ini, %A_LoopField%, color 1
	IniRead, pixel_%A_LoopField%_color2, ini\pixel checks (%poe_height%p).ini, %A_LoopField%, color 2
}
If (pixel_gamescreen_color1 = "ERROR") || (pixel_gamescreen_color1 = "")
{
	clone_frames_pixelcheck_enable := 0
	pixelchecks_enabled := StrReplace(pixelchecks_enabled, "gamescreen,")
}

IniRead, enable_notepad, ini\config.ini, Features, enable notepad, 0
IniRead, enable_alarm, ini\config.ini, Features, enable alarm, 0

IniRead, omnikey_hotkey, ini\config.ini, Settings, omni-hotkey, %A_Space%
If (omnikey_hotkey != "")
{
	Hotkey, IfWinActive, ahk_group poe_window
	Hotkey, ~%omnikey_hotkey%, Omnikey, On
	Hotkey, ~MButton, Omnikey, Off
}
Else
{
	Hotkey, IfWinActive, ahk_group poe_window
	Hotkey, ~MButton, Omnikey, On
}

SetTimer, Loop, 1000

guilist := "LLK_panel|notepad|notepad_sample|settings_menu|alarm|alarm_sample|clone_frames_window"
buggy_resolutions := "768,1024,1050"

timeout := 0
If (custom_resolution_setting = 1)
	WinActivate, ahk_group poe_window
WinWaitActive, ahk_group poe_window
If InStr(buggy_resolutions, poe_height) && (resolution_warning = 0)
{
	MsgBox, Uncommon resolution detected.`n`nThe script has detected a vertical screen-resolution of %poe_height%p which has caused issues in the past. The script should still be usable, but a few advanced features might be disabled and I cannot guarantee a smooth user-experience.`n`nI would suggest using a custom resolution which can be set up in the settings menu.
	IniWrite, 1, ini\config.ini, Versions, resolution warning
}
SoundBeep, 100
GoSub, GUI
SetTimer, MainLoop, 100
Return

#IfWinActive ahk_group poe_window
	
::/llk::
SendInput, {Enter}
GoSub, Settings_menu
Return

#If WinExist("ahk_id " hwnd_clone_frames_menu)

F1::
MouseGetPos, mouseXpos, mouseYpos
clone_frame_new_topleft_x := mouseXpos
clone_frame_new_topleft_y := mouseYpos
GuiControl, clone_frames_menu: Text, clone_frame_new_topleft_x, % clone_frame_new_topleft_x
GuiControl, clone_frames_menu: Text, clone_frame_new_topleft_y, % clone_frame_new_topleft_y
GoSub, Clone_frames_dimensions
Return

F2::
MouseGetPos, mouseXpos, mouseYpos
clone_frame_new_width := mouseXpos - clone_frame_new_topleft_x
clone_frame_new_height := mouseYpos - clone_frame_new_topleft_y
GuiControl, clone_frames_menu: Text, clone_frame_new_width, % clone_frame_new_width
GuiControl, clone_frames_menu: Text, clone_frame_new_height, % clone_frame_new_height
GoSub, Clone_frames_dimensions
Return

F3::
MouseGetPos, mouseXpos, mouseYpos
clone_frame_new_target_x := (mouseXpos + clone_frame_new_width * clone_frame_new_scale_x//100 > xScreenOffset + poe_width) ? xScreenOffSet + poe_width - clone_frame_new_width * clone_frame_new_scale_x//100 : mouseXpos
clone_frame_new_target_y := (mouseYpos + clone_frame_new_height * clone_frame_new_scale_y//100 > yScreenOffset + poe_height) ? yScreenOffSet + poe_height - clone_frame_new_height * clone_frame_new_scale_y//100 : mouseYpos
GuiControl, clone_frames_menu: Text, clone_frame_new_target_x, % clone_frame_new_target_x
GuiControl, clone_frames_menu: Text, clone_frame_new_target_y, % clone_frame_new_target_y
GoSub, Clone_frames_dimensions
Return

#If

Alarm:
alarm_fontcolor := (alarm_fontcolor = "") ? "White" : alarm_fontcolor
fSize_alarm := fSize0 + fSize_offset_alarm
If (alarm_timestamp != "") && (alarm_timestamp < A_Now)
{
	Gui, alarm: Destroy
	hwnd_alarm := ""
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
	If (alarm_sample_xpos != "") && (alarm_sample_ypos != "")
		Gui, alarm_sample: Show, Hide x%alarm_sample_xpos% y%alarm_sample_ypos% AutoSize
	Else
	{
		Gui, alarm_sample: Show, Hide AutoSize
		WinGetPos,,, win_width, win_height
		Gui, alarm_sample: Show, % "Hide AutoSize x"xScreenOffSet + poe_width//2 - win_width//2 " y"yScreenOffSet + poe_height//2 - win_height//2
	}
	LLK_Overlay("alarm_sample", "show")
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
		alarm_timestamp := A_Now
		EnvAdd, alarm_timestamp, %alarm_minutes%, S
	}
	Gui, alarm: New, -DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_alarm,
	Gui, alarm: Color, Black
	Gui, alarm: Margin, 12, 4
	WinSet, Transparent, %alarm_trans%
	Gui, alarm: Font, s%fSize_alarm% c%alarm_fontcolor%, Fontin SmallCaps
	Gui, alarm: Add, Text, xp BackgroundTrans Center valarm_countdown, XX:XX
	GuiControl, Text, alarm_countdown,
	Gui, alarm: Show, Hide x%alarm_xpos% y%alarm_ypos% AutoSize
	LLK_Overlay("alarm", "show")
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
			Gui, alarm: Destroy
			hwnd_alarm := ""
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
		If (alarm_xpos = "") || (alarm_ypos = "")
			Gui, alarm: Show, Hide Center
		Else Gui, alarm: Show, Hide x%alarm_xpos% y%alarm_ypos%
		LLK_Overlay("alarm", "show", 1)
		WinGetPos,,,, alarm_height, ahk_id %hwnd_alarm%
		Return
	}
}

If !WinExist("ahk_id " hwnd_alarm)
	LLK_Overlay("alarm", "show", 1)
Else
{
	WinGetPos, alarm_xpos, alarm_ypos,,, ahk_id %hwnd_alarm%
	LLK_Overlay("alarm", "hide")
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
kill_timeout := (kill_timeout = "") ? 0 : kill_timeout
WinMove, ahk_group poe_window,, %xScreenOffset%, %yScreenOffset%, %poe_width%, %custom_resolution%
poe_height := custom_resolution
IniWrite, %custom_resolution_setting%, ini\config.ini, Settings, enable custom-resolution
IniWrite, %custom_resolution%, ini\config.ini, Settings, custom-resolution
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
	GoSub, GUI
	GoSub, Settings_menu
	Return
}
If (A_GuiControl = "fSize_alarm_minus")
	fSize_offset_alarm -= 1
If (A_GuiControl = "fSize_alarm_plus")
	fSize_offset_alarm += 1
If (A_GuiControl = "fSize_alarm_reset")
	fSize_offset_alarm := 0
If (A_GuiControl = "alarm_opac_minus")
	alarm_trans -= (alarm_trans > 100) ? 30 : 0
If (A_GuiControl = "alarm_opac_plus")
	alarm_trans += (alarm_trans < 250) ? 30 : 0
WinGetPos, alarm_sample_xpos, alarm_sample_ypos,,, ahk_id %hwnd_alarm_sample%
alarm_fontcolor := InStr(A_GuiControl, "fontcolor_") ? StrReplace(A_GuiControl, "fontcolor_", "") : alarm_fontcolor
GoSub, Alarm
Return

Apply_settings_general:
If (A_GuiControl = "interface_size_minus")
	fSize_offset -= 1
If (A_GuiControl = "interface_size_plus")
	fSize_offset += 1
If (A_GuiControl = "interface_size_reset")
	fSize_offset := 0
fSize0 := fSize_config0 + fSize_offset
fSize1 := fSize_config1 + fSize_offset
Gui, settings_menu: Submit, NoHide
SetTimer, Settings_menu, 10
GoSub, GUI
WinActivate, ahk_group poe_window
Return

Apply_settings_notepad:
If (A_GuiControl = "enable_notepad")
{
	Gui, settings_menu: Submit, NoHide
	If WinExist("ahk_id " hwnd_notepad_sample) && (enable_notepad = 0)
	{
		Gui, notepad_sample: Destroy
		hwnd_notepad_sample := ""
	}
	If WinExist("ahk_id " hwnd_notepad) && (enable_notepad = 0)
	{
		Gui, Notepad: Submit, NoHide
		Gui, notepad: Destroy
		hwnd_notepad := ""
	}
	GoSub, GUI
	GoSub, Settings_menu
	Return
}
If (A_GuiControl = "fSize_notepad_minus")
	fSize_offset_notepad -= 1
If (A_GuiControl = "fSize_notepad_plus")
	fSize_offset_notepad += 1
If (A_GuiControl = "fSize_notepad_reset")
	fSize_offset_notepad := 0
If (A_GuiControl = "notepad_opac_minus")
	notepad_trans -= (notepad_trans > 100) ? 30 : 0
If (A_GuiControl = "notepad_opac_plus")
	notepad_trans += (notepad_trans < 250) ? 30 : 0
WinGetPos, notepad_sample_xpos, notepad_sample_ypos,,, ahk_id %hwnd_notepad_sample%
notepad_fontcolor := InStr(A_GuiControl, "fontcolor_") ? StrReplace(A_GuiControl, "fontcolor_", "") : notepad_fontcolor
GoSub, Notepad
Return

Apply_settings_omnikey:
Gui, settings_menu: Submit, NoHide
If (A_GuiControl = "omnikey_hotkey") && (omnikey_hotkey != "")
{
	If (omnikey_hotkey_old != omnikey_hotkey) && (omnikey_hotkey_old != "")
	{
		Hotkey, IfWinActive, ahk_group poe_window
		Hotkey, ~%omnikey_hotkey_old%,, Off
	}
	omnikey_hotkey_old := omnikey_hotkey
	Hotkey, IfWinActive, ahk_group poe_window
	Hotkey, ~%omnikey_hotkey%, Omnikey, On
}
GoSub, Settings_menu
Return

Clone_frames_apply:
Gui, Settings_menu: Submit, NoHide
If (A_GuiControl = "Clone_frames_pixelcheck_enable") && ((pixel_gamescreen_color1 = "ERROR") || (pixel_gamescreen_color1 = ""))
{
	LLK_ToolTip("The pixel-check has not been calibrated yet.`nPlease go to the pixel-check section and calibrate it.")
	GuiControl, settings_menu: , clone_frames_pixelcheck_enable, 0
	Return
}
If InStr(A_GuiControl, "pixel")
{
	If (clone_frames_pixelcheck_enable = 0)
		pixelchecks_enabled := StrReplace(pixelchecks_enabled, "gamescreen,")
	Else pixelchecks_enabled := InStr(pixelchecks_enabled, "gamescreen") ? pixelchecks_enabled : pixelchecks_enabled "gamescreen,"
	Return
}
clone_frames_enabled := ""
Loop, Parse, clone_frames_list, `n, `n
{
	If (clone_frame_%A_LoopField%_enable = 1)
		clone_frames_enabled := (clone_frames_enabled = "") ? A_LoopField "," : A_LoopField "," clone_frames_enabled
}
Return

Clone_frames_dimensions:
Gui, clone_frames_menu: Submit, NoHide
GuiControl, clone_frames_menu: Text, clone_frame_new_dimensions, % clone_frame_new_width " x " clone_frame_new_height " pixels"
Gui, clone_frame_preview: New, -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_clone_frame_preview
Gui, clone_frame_preview: Show, NA
bmpCloneFrameScreenshot := Gdip_BitmapFromScreen(clone_frame_new_topleft_x "|" clone_frame_new_topleft_y "|" clone_frame_new_width "|" clone_frame_new_height)
Gui, clone_frame_preview_frame: New, -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +Border +OwnDialogs HWNDhwnd_clone_frame_preview_frame
Gui, clone_frame_preview_frame: Color, Black
WinSet, TransColor, Black
If ((clone_frame_new_width > 1) && (clone_frame_new_height > 1))
	Gui, clone_frame_preview_frame: Show, % "NA x"clone_frame_new_topleft_x - 1 " y"clone_frame_new_topleft_y - 1 " w"clone_frame_new_width " h"clone_frame_new_height
Else Gui, clone_frame_preview_frame: Hide
SetTimer, Clone_frames_preview, 100
Return

Clone_frames_delete:
delete_string := StrReplace(A_GuiControl, "delete_", "")
IniDelete, ini\clone frames.ini, %delete_string%
new_clone_menu_closed := 1
GoSub, Settings_menu
Return

Clone_frames_new:
Gui, settings_menu: Submit
LLK_Overlay("settings_menu", "hide")
If (clone_frames_edit_mode = 1)
{
	edit_string := StrReplace(A_GuiControl, "edit_", "")
	clone_frames_enabled := StrReplace(clone_frames_enabled, edit_string ",", "")
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
	clone_frame_edit_target_x := xScreenOffSet
	clone_frame_edit_target_y := yScreenOffSet
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
bmpPreview := Gdip_BitmapFromScreen(clone_frame_new_topleft_x "|" clone_frame_new_topleft_y "|" clone_frame_new_width "|" clone_frame_new_height)
;WinGetPos, winXpos, winYpos,, winheight, ahk_id %hwnd_clone_frames_menu%
Gdip_GetImageDimensions(bmpPreview, WidthPreview, HeightPreview)
hbmPreview := CreateDIBSection(poe_width, poe_height)
hdcPreview := CreateCompatibleDC()
obmPreview := SelectObject(hdcPreview, hbmPreview)
GPreview := Gdip_GraphicsFromHDC(hdcPreview)
Gdip_SetInterpolationMode(GPreview, 0)
Gdip_DrawImage(GPreview, bmpPreview, clone_frame_new_target_x - xScreenOffSet, clone_frame_new_target_y - yScreenOffSet, clone_frame_new_width * clone_frame_new_scale_x//100, clone_frame_new_height * clone_frame_new_scale_y//100, 0, 0, WidthPreview, HeightPreview, 0.2 + 0.16 * clone_frame_new_opacity)
UpdateLayeredWindow(hwnd_clone_frame_preview, hdcPreview, xScreenOffSet, yScreenOffSet, poe_width, poe_height)
SelectObject(hdcPreview, obmPreview)
DeleteObject(hbmPreview)
DeleteDC(hdcPreview)
Gdip_DeleteGraphics(GPreview)
Gdip_DisposeImage(bmpPreview)
Return

Clone_frames_preview_list:
MouseGetPos, mouseXpos, mouseYpos
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
bmpPreview_list := Gdip_BitmapFromScreen(clone_frame_%A_GuiControl%_topleft_x "|" clone_frame_%A_GuiControl%_topleft_y "|" clone_frame_%A_GuiControl%_width "|" clone_frame_%A_GuiControl%_height)
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
		add_character := " "
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
GoSub, Clone_frames_menuGuiClose
Return

Exit:
Gdip_Shutdown(pToken)
If (timeout != 1)
{
	IniWrite, %alarm_xpos%, ini\alarm.ini, UI, xcoord
	IniWrite, %alarm_ypos%, ini\alarm.ini, UI, ycoord
	alarm_timestamp := (alarm_timestamp < A_Now) ? "" : alarm_timestamp
	IniWrite, %alarm_timestamp%, ini\alarm.ini, Settings, alarm-timestamp
	IniWrite, %fSize_offset_alarm%, ini\alarm.ini, Settings, font-offset
	IniWrite, %alarm_fontcolor%, ini\alarm.ini, Settings, font-color
	IniWrite, %alarm_trans%, ini\alarm.ini, Settings, transparency
	
	IniWrite, %notepad_xpos%, ini\notepad.ini, UI, xcoord
	IniWrite, %notepad_ypos%, ini\notepad.ini, UI, ycoord
	IniWrite, %notepad_width%, ini\notepad.ini, UI, width
	IniWrite, %notepad_height%, ini\notepad.ini, UI, height
	notepad_text := StrReplace(notepad_text, "`n", ",,")
	IniWrite, %notepad_text%, ini\notepad.ini, Text, text
	IniWrite, %fSize_offset_notepad%, ini\notepad.ini, Settings, font-offset
	IniWrite, %notepad_fontcolor%, ini\notepad.ini, Settings, font-color
	IniWrite, %notepad_trans%, ini\notepad.ini, Settings, transparency
	
	IniWrite, %panel_position0%, ini\config.ini, UI, panel-position0
	IniWrite, %panel_position1%, ini\config.ini, UI, panel-position1
	IniWrite, %hide_panel%, ini\config.ini, UI, hide panel
	IniWrite, %fSize_offset%, ini\config.ini, UI, font-offset
	IniWrite, %kill_script%, ini\config.ini, Settings, kill script
	IniWrite, %kill_timeout%, ini\config.ini, Settings, kill-timeout
	IniWrite, %omnikey_hotkey%, ini\config.ini, Settings, omni-hotkey
	IniWrite, %enable_notepad%, ini\config.ini, Features, enable notepad
	IniWrite, %enable_alarm%, ini\config.ini, Features, enable alarm
	
	Loop, Parse, clone_frames_list, `n, `n
	{
		If (A_LoopField = "Settings")
			continue
		IniWrite, % clone_frame_%A_LoopField%_enable, ini\clone frames.ini, %A_LoopField%, enable
	}
	IniWrite, % clone_frames_pixelcheck_enable, ini\clone frames.ini, Settings, enable pixel-check
}
ExitApp
Return

GUI:
Gui, LLK_panel: New, -DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_LLK_panel
Gui, LLK_panel: Margin, 2, 2
Gui, LLK_panel: Color, Black
WinSet, Transparent, %trans%
Gui, LLK_panel: Font, % "s"fSize1 " cWhite underline", Fontin SmallCaps
Gui, LLK_panel: Add, Text, Section Center BackgroundTrans HWNDmain_text gSettings_menu, % "LLK UI:"
ControlGetPos,, ypos,, height,, ahk_id %main_text%
If (enable_notepad = 1)
	Gui, LLK_panel: Add, Picture, % "ys x+6 Center BackgroundTrans hp w-1 gNotepad", img\GUI\notepad.jpg
If (enable_alarm = 1)
	Gui, LLK_panel: Add, Picture, % "ys x+6 Center BackgroundTrans hp w-1 gAlarm", img\GUI\alarm.jpg
Gui, LLK_panel: Show, Hide
WinGetPos,,, panel_width, panel_height
panel_style := (hide_panel = 1) ? "hide" : "show"
panel_xpos := (panel_position1 = "left") ? xScreenOffset : xScreenOffset + poe_width - panel_width
panel_ypos := (panel_position0 = "bottom") ? yScreenOffset + poe_height - panel_height : yScreenOffset
Gui, LLK_panel: Show, % "Hide x"panel_xpos " y"panel_ypos
LLK_Overlay("LLK_panel", panel_style)
Gui, clone_frames_window: New, -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd_clone_frames_window
If (continue_alarm = 1)
	GoSub, Alarm
Return

Loop:
If !WinExist("ahk_group poe_window")
	poe_window_closed := 1
If !WinExist("ahk_group poe_window") && (A_TickCount >= last_check + kill_timeout*60000) && (kill_script = 1) && (alarm_timestamp = "")
	ExitApp
If WinExist("ahk_group poe_window")
{
	last_check := A_TickCount
	If (poe_window_closed = 1) && (custom_resolution_setting = 1)
	{
		While !WinActive("ahk_class POEWindowClass")
			Sleep, 2000
		WinMove, ahk_group poe_window,, %xScreenOffset%, %yScreenOffset%, %poe_width%, %custom_resolution%
		poe_height := custom_resolution
		poe_window_closed := 0
	}
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
			Gui, alarm: Show, % "NA h"alarm_height//2
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
		Gui, context_menu: Destroy
		LLK_Overlay("hide")
	}
}
If WinActive("ahk_group poe_window") || WinActive("ahk_class AutoHotkeyGUI")
{
	If (inactive_counter != 0)
	{
		inactive_counter := 0
		Gui, omni_info: Destroy
		LLK_Overlay("show")
	}
	If (pixelchecks_enabled != "")
	{
		Loop, Parse, pixelchecks_enabled, `,, `,
		{
			If (A_LoopField = "")
				break
			LLK_PixelSearch(A_LoopField)
		}
	}
	If ((clone_frames_enabled != "") && (clone_frames_pixelcheck_enable = 0)) || ((clone_frames_enabled != "") && (clone_frames_pixelcheck_enable = 1) && (gamescreen = 1))
	{
		If !WinExist("ahk_id " hwnd_clone_frames_window)
			Gui, clone_frames_window: Show, NA
		
		hbmClone_frames := CreateDIBSection(poe_width, poe_height)
		hdcClone_frames := CreateCompatibleDC()
		obmClone_frames := SelectObject(hdcClone_frames, hbmClone_frames)
		GClone_frames := Gdip_GraphicsFromHDC(hdcClone_frames)
		Gdip_SetInterpolationMode(GClone_frames, 0)
		
		Loop, Parse, clone_frames_enabled, `,, `,
		{
			If (A_LoopField = "")
				Break
			bmpClone_frames := Gdip_BitmapFromScreen(clone_frame_%A_LoopField%_topleft_x "|" clone_frame_%A_LoopField%_topleft_y "|" clone_frame_%A_LoopField%_width "|" clone_frame_%A_LoopField%_height)
			Gdip_GetImageDimensions(bmpClone_frames, WidthClone_frames, HeightClone_frames)
			Gdip_DrawImage(GClone_frames, bmpClone_frames, clone_frame_%A_LoopField%_target_x - xScreenOffSet, clone_frame_%A_LoopField%_target_y - yScreenOffSet, clone_frame_%A_LoopField%_width * clone_frame_%A_LoopField%_scale_x//100, clone_frame_%A_LoopField%_height * clone_frame_%A_LoopField%_scale_y//100, 0, 0, WidthClone_frames, HeightClone_frames, 0.2 + 0.16 * clone_frame_%A_LoopField%_opacity)
			Gdip_DisposeImage(bmpClone_frames)
		}
		UpdateLayeredWindow(hwnd_clone_frames_window, hdcClone_frames, xScreenOffSet, yScreenOffSet, poe_width, poe_height)
		SelectObject(hdcClone_frames, obmClone_frames)
		DeleteObject(hbmClone_frames)
		DeleteDC(hdcClone_frames)
		Gdip_DeleteGraphics(GClone_frames)
	}
	Else If WinExist("ahk_id " hwnd_clone_frames_window)
		Gui, clone_frames_window: Hide
}
Return

Notepad:
notepad_fontcolor := (notepad_fontcolor = "") ? "White" : notepad_fontcolor
fSize_notepad := fSize0 + fSize_offset_notepad
If (A_Gui = "settings_menu")
{
	Gui, notepad: Submit, NoHide
	Gui, notepad: Destroy
	hwnd_notepad := ""
	Gui, notepad_sample: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_notepad_sample, Lailloken UI: overlay-text preview
	Gui, notepad_sample: Margin, 12, 4
	Gui, notepad_sample: Color, Black
	WinSet, Transparent, %notepad_trans%
	Gui, notepad_sample: Font, c%notepad_fontcolor% s%fSize_notepad%, Fontin SmallCaps
	Gui, notepad_sample: Add, Text, BackgroundTrans, this is what the`nnotepad-overlay looks`nlike with the current`nsettings
	If (notepad_sample_xpos != "") && (notepad_sample_ypos != "")
		Gui, notepad_sample: Show, Hide x%notepad_sample_xpos% y%notepad_sample_ypos% AutoSize
	Else
	{
		Gui, notepad_sample: Show, % "Hide AutoSize"
		WinGetPos,,, win_width, win_height
		Gui, notepad_sample: Show, % "Hide AutoSize x"xScreenOffSet + poe_width//2 - win_width//2 " y"yScreenOffSet + poe_height//2 - win_height//2
	}
	LLK_Overlay("notepad_sample", "show")
	Return
}
If (click = 2) || (hwnd_notepad = "")
{
	If !WinExist("ahk_id " hwnd_notepad) && (click = 2)
	{
		WinActivate, ahk_group poe_window
		Return
	}
	If WinExist("ahk_id " hwnd_notepad)
		Gui, notepad: Submit, NoHide
	If (notepad_text != "") || (hwnd_notepad = "")
	{
		If (notepad_edit = 1) || (hwnd_notepad = "")
		{
			Gui, notepad: New, -DPIScale +Resize +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_notepad, Lailloken-UI: notepad
			Gui, notepad: Margin, 12, 4
			Gui, notepad: Color, Black
			WinSet, Transparent, 220
			Gui, notepad: Font, cBlack s%fSize_notepad%, Fontin SmallCaps
			Gui, notepad: Add, Edit, x0 y0 w1000 h1000 vnotepad_text Lowercase, %notepad_text%
			Gui, notepad: Show, x%notepad_xpos% y%notepad_ypos% w%notepad_width% h%notepad_height%
			SendInput, {Right}
			notepad_edit := 0
		}
		Else
		{
			WinGetPos, notepad_xpos, notepad_ypos,,, ahk_id %hwnd_notepad%
			Gui, notepad: New, -DPIScale +E0x20 +LastFound +AlwaysOnTop +ToolWindow -Caption +Border HWNDhwnd_notepad
			Gui, notepad: Margin, 12, 4
			Gui, notepad: Color, Black
			WinSet, Transparent, %notepad_trans%
			Gui, notepad: Font, c%notepad_fontcolor% s%fSize_notepad%, Fontin SmallCaps
			Gui, notepad: Add, Text, BackgroundTrans, %notepad_text%
			Gui, notepad: Show, NA x%notepad_xpos% y%notepad_ypos% AutoSize
			notepad_edit := 1
			WinActivate, ahk_group poe_window
		}
	}
	Return
}

If WinExist("ahk_id " hwnd_notepad)
{
	If (notepad_edit != 1)
		WinGetPos, notepad_xpos, notepad_ypos, notepad_width, notepad_height, ahk_id %hwnd_notepad%
	Gui, notepad: Submit, NoHide
	If notepad_edit = 0
	{
		Gui, notepad: Destroy
		hwnd_notepad := ""
	}
	Else LLK_Overlay("notepad", "hide")
	WinActivate, ahk_group poe_window
}
Else LLK_Overlay("notepad", "show", 1)
Return

NotepadGuiClose:
If WinExist("ahk_id " hwnd_notepad)
{
	If (notepad_edit != 1)
		WinGetPos, notepad_xpos, notepad_ypos, notepad_width, notepad_height, ahk_id %hwnd_notepad%
	Gui, notepad: Submit, NoHide
	LLK_Overlay("notepad", "hide")
}
Return

Omnikey:
clipboard := ""
SendInput ^{c}
ClipWait, 0.2
If (clipboard != "")
{
	start := A_TickCount
	ThisHotkey_copy := StrReplace(A_ThisHotkey, "~", "")
	While GetKeyState(ThisHotkey_copy, "P")
	{
		If (A_TickCount >= start + 300)
		{
			If InStr(clipboard, "Attacks per Second:")
				GoSub, Omnikey_dps
			KeyWait, %ThisHotkey_copy%
			Return
		}
	}
	KeyWait, %ThisHotkey_copy%
	If !InStr(clipboard, "Rarity: Currency") && !InStr(clipboard, "Item Class: Map") && !InStr(clipboard, "Unidentified") && !InStr(clipboard, "Heist") && !InStr(clipboard, "Item Class: Expedition") && !InStr(clipboard, "Item Class: Stackable Currency")
	{
		Gui, context_menu: New, -Caption +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_context_menu
		Gui, context_menu: Margin, 4, 2
		Gui, context_menu: Color, Black
		WinSet, Transparent, %trans%
		Gui, context_menu: Font, s%fSize0% cWhite, Fontin SmallCaps
		If InStr(clipboard, "Rarity: Unique") || InStr(clipboard, "Rarity: Gem") || InStr(clipboard, "Class: Quest") || InStr(clipboard, "Rarity: Divination Card")
			Gui, context_menu: Add, Text, vwiki_exact gOmnikey_menu_selection BackgroundTrans Center, wiki (exact item)
		Else
		{
			Gui, context_menu: Add, Text, vcrafting_table gOmnikey_menu_selection BackgroundTrans Center, crafting table
			Gui, context_menu: Add, Text, vwiki_class gOmnikey_menu_selection BackgroundTrans Center, wiki (item class)
		}
		If InStr(clipboard, "Sockets: ") && !InStr(clipboard, "Class: Ring") && !InStr(clipboard, "Class: Amulet") && !InStr(clipboard, "Class: Belt")
			Gui, context_menu: Add, Text, vchrome_calc gOmnikey_menu_selection BackgroundTrans Center, chromatics
		MouseGetPos, mouseX, mouseY
		Gui, context_menu: Show, % "x"mouseX-160 " y"mouseY
		WinGetPos, x_context
		If (x_context < xScreenOffset)
			Gui, context_menu: Show, x%xScreenOffset% y%mouseY%
		WinWaitActive, ahk_group poe_window,,, Lailloken
		If WinExist("ahk_id " hwnd_context_menu)
			Gui, context_menu: destroy
	}
}
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
		wiki_cluster := SubStr(A_LoopField, 35)
}
If (class="Gloves") || (class="Boots") || (class="Body Armours") || (class="Helmets") || (class="Shields")
{
	attribute0 := Max(strength, dexterity, intelligence)
	If (attribute0=strength)
		attribute := "_str"
	If (attribute0=dexterity)
		attribute := (attribute="") ? "_dex" : attribute "_dex"
	If (attribute0=intelligence)
		attribute := (attribute="") ? "_int" : attribute "_int"
}
If (A_GuiControl = "crafting_table")
{
	If InStr(clipboard, "Cluster Jewel")
	{
		Run, https://poedb.tw/us/Cluster_Jewel#EnchantmentModifiers
		wiki_cluster := SubStr(wiki_cluster, 1, InStr(wiki_cluster, "(")-2)
		ToolTip, Press F3 to search for modifiers, % xScreenOffset + poe_width//2 - 100, yScreenOffset + poe_height//2, 15
		KeyWait, F3, D
		KeyWait, F3
		ToolTip,,,, 15
		SendInput, %wiki_cluster%
	}
	Else Run, https://poedb.tw/us/%wiki_term%%attribute%#ModifiersCalc
	clipboard := wiki_level
}
If (A_GuiControl = "chrome_calc")
{
	ToolTip, Press CTRL-V to paste stat requirements, % xScreenOffset + poe_width//2 - 100, yScreenOffset + poe_height//2, 15
	Run, https://siveran.github.io/calc.html
	clipboard := ""
	KeyWait, v, D
	SendInput, %strength%{tab}%dexterity%{tab}%intelligence%
	ToolTip,,,, 15
}
Return

Omnikey_dps:
phys_dmg := 0
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
Gui, omni_info: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_omni_info, Lailloken UI: Omni-key Info
Gui, omni_info: Margin, 12, 4
Gui, omni_info: Color, Black
WinSet, Transparent, %trans%
Gui, omni_info: Font, cWhite s%fSize0%, Fontin SmallCaps
If (A_GuiControl = "chrome_calc") || (A_GuiControl = "crafting_table")
	GoSub, Omnikey_craft_chrome
If InStr(A_GuiControl, "wiki")
	GoSub, Omnikey_wiki
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
		break
	}
}
If InStr(clipboard, "Cluster Jewel")
	wiki_term := "Cluster_Jewel"
Run, https://poewiki.net/wiki/%wiki_term%
Return

Pixelchecks:
If (click = 2)
{
	LLK_PixelRecalibrate("gamescreen")
	Return
}
If LLK_PixelSearch(A_GuiControl)
	LLK_ToolTip("success")
Else LLK_ToolTip("failed")
Return

Settings_menu:
SetTimer, Settings_menu, Delete
If WinExist("ahk_id " hwnd_settings_menu)
	WinGetPos, xsettings_menu, ysettings_menu,,, ahk_id %hwnd_settings_menu%
If WinExist("ahk_id " hwnd_settings_menu) && (A_Gui = "LLK_panel")
{
	GoSub, Settings_menuGuiClose
	WinActivate, ahk_group poe_window
	Return
}
settings_style := InStr(A_GuiControl, "general") || (A_Gui = "LLK_panel") || (A_Gui = "") ? "border" : ""
alarm_style := InStr(A_GuiControl, "alarm") ? "border" : ""
clone_frames_style := InStr(A_GuiControl, "clone") || (new_clone_menu_closed = 1) ? "border" : ""
flask_style := InStr(A_GuiControl, "flask") ? "border" : ""
notepad_style := InStr(A_GuiControl, "notepad") ? "border" : ""
omnikey_style := InStr(A_GuiControl, "omni-key") ? "border" : ""
pixelcheck_style := InStr(A_GuiControl, "pixel") ? "border" : ""
GuiControl_copy := A_GuiControl
If (A_Gui = "settings_menu")
{
	Gui, settings_menu: Submit
	kill_timeout := (kill_timeout = "") ? 0 : kill_timeout
}
Gui, settings_menu: New, -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_settings_menu, Lailloken UI: settings
Gui, settings_menu: Color, Black
Gui, settings_menu: Margin, 12, 4
WinSet, Transparent, %trans%
Gui, settings_menu: Font, s%fSize0% cWhite underline, Fontin SmallCaps

Gui, settings_menu: Add, Text, % "Section BackgroundTrans " settings_style " gSettings_menu HWNDhwnd_settings_general", % "general"
ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_general%
spacing_settings := width_settings

Gui, settings_menu: Add, Text, xs BackgroundTrans %alarm_style% gSettings_menu HWNDhwnd_settings_alarm, % "alarm-timer"
ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_alarm%
spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings

Gui, settings_menu: Add, Text, xs BackgroundTrans %clone_frames_style% gSettings_menu HWNDhwnd_settings_clone_frames, % "clone-frames"
ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_clone_frames%
spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings

Gui, settings_menu: Add, Text, xs BackgroundTrans %notepad_style% gSettings_menu HWNDhwnd_settings_notepad, % "notepad"
ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_notepad%
spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings

Gui, settings_menu: Add, Text, xs BackgroundTrans %omnikey_style% gSettings_menu HWNDhwnd_settings_omnikey, % "omni-key"
ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_omnikey%
spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings

If pixel_gamescreen_x1 is number
{
	Gui, settings_menu: Add, Text, xs BackgroundTrans %pixelcheck_style% gSettings_menu HWNDhwnd_settings_pixelcheck, % "pixel-checks"
	ControlGetPos,,, width_settings,,, ahk_id %hwnd_settings_pixelcheck%
	spacing_settings := (width_settings > spacing_settings) ? width_settings : spacing_settings
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

If InStr(GuiControl_copy, "general") || (A_Gui = "LLK_panel") || (A_Gui = "")
	GoSub, Settings_menu_general
Else If InStr(GuiControl_copy, "alarm")
	GoSub, Settings_menu_alarm
Else If InStr(GuiControl_copy, "clone") || (new_clone_menu_closed = 1)
	GoSub, Settings_menu_clone_frames
Else If InStr(GuiControl_copy, "notepad")
	GoSub, Settings_menu_notepad
Else If InStr(GuiControl_copy, "omni")
	GoSub, Settings_menu_omnikey
Else If InStr(GuiControl_copy, "pixel")
	GoSub, Settings_menu_pixelchecks

ControlFocus,, ahk_id %hwnd_settings_general%
If (xsettings_menu != "") && (ysettings_menu != "")
	Gui, settings_menu: Show, Hide x%xsettings_menu% y%ysettings_menu%
Else
{
	Gui, settings_menu: Show, Hide
	WinGetPos,,, wsettings_menu
	Gui, settings_menu: Show, % "Hide x"xScreenOffset + poe_width//2 - wsettings_menu//2 " y"yScreenOffset
}
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
}
Return

Settings_menu_clone_frames:
new_clone_menu_closed := 0
clone_frames_enabled := ""
IniRead, clone_frames_list, ini\clone frames.ini
Sort, clone_frames_list, D`n
If pixel_gamescreen_x1 is number
{
	Gui, settings_menu: Add, Checkbox, % "ys Section BackgroundTrans gClone_frames_apply vClone_frames_pixelcheck_enable Checked" clone_frames_pixelcheck_enable " xp+"spacing_settings*1.2, trigger overlay via 'game-screen' pixel-check
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
		clone_frames_enabled := (clone_frames_enabled = "") ? A_LoopField "," : A_LoopField "," clone_frames_enabled
	Gui, settings_menu: Add, Checkbox, % "xs Section BackgroundTrans gClone_frames_apply Checked" clone_frame_%A_LoopField%_enable " vClone_frame_" A_LoopField "_enable", % "enable: "
	Gui, settings_menu: Font, underline
	Gui, settings_menu: Add, Text, % "ys x+0 BackgroundTrans gClone_frames_preview_list", % A_LoopField
	Gui, settings_menu: Font, norm
}
Gui, settings_menu: Add, Text, % "xs Section Border gClone_frames_new vClone_frames_add BackgroundTrans y+"fSize0*1.2, % " add frame "
Return

Settings_menu_general:
Gui, settings_menu: Add, Checkbox, % "ys Section BackgroundTrans HWNDmain_text Checked" kill_script " vkill_script xp+"spacing_settings*1.2, % "kill script after"
ControlGetPos,,,, controlheight,, ahk_id %main_text%

Gui, settings_menu: Font, % "s"fSize0-4 "norm"
Gui, settings_menu: Add, Edit, % "ys x+0 hp BackgroundTrans cBlack Number right Limit2 vkill_timeout w"controlheight*1.2, %kill_timeout%
Gui, settings_menu: Font, % "s"fSize0
Gui, settings_menu: Add, Text, % "ys BackgroundTrans x+"fSize0//2, % "minute(s) w/o poe-client"

Gui, settings_menu: Add, Link, % "xs hp Section HWNDlink_text y+"fSize0*1.5, <a href="https://github.com/Lailloken/Lailloken-UI/discussions/49">custom resolution:</a>
Gui, settings_menu: Add, Text, % "ys BackgroundTrans HWNDmain_text x+"fSize0//2, % poe_width " x "
ControlGetPos,,,, height,, ahk_id %main_text%
ControlGetPos,,, width,,, ahk_id %link_text%
resolutionsDDL := ""
IniRead, resolutions_all, Resolutions.ini
choice := 0
Loop, Parse, resolutions_all, `n,`n
	If !(InStr(A_LoopField, "768") || InStr(A_LoopField, "1024") || InStr(A_LoopField, "1050")) && !(StrReplace(A_LoopField, "p", "") > height_native)
		resolutionsDDL := (resolutionsDDL = "") ? StrReplace(A_LoopField, "p", "") : StrReplace(A_LoopField, "p", "") "|" resolutionsDDL
Loop, Parse, resolutionsDDL, |, |
	If (A_LoopField = poe_height)
		choice := A_Index
Gui, settings_menu: Font, % "s"fSize0-4
Gui, settings_menu: Add, DDL, % "ys x+0 BackgroundTrans HWNDmain_text vcustom_resolution r10 wp Choose" choice, % resolutionsDDL
Gui, settings_menu: Font, % "s"fSize0
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans Border gApply_resolution", % " apply && restart "
Gui, settings_menu: Add, Checkbox, % "ys BackgroundTrans HWNDmain_text Checked" custom_resolution_setting " vcustom_resolution_setting ", % "apply on startup "
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans Center HWNDmain_text y+"fSize0*1.5, % "panel position:"
ControlGetPos,,, width,,, ahk_id %main_text%
Gui, settings_menu: Font, % "s"fSize0-4
If (panel_position0 = "top")
	Gui, settings_menu: Add, DDL, % "hp x+6 ys BackgroundTrans Border Center vpanel_position0 gApply_settings_general r2 w"width*0.6, % "top||bottom"
Else Gui, settings_menu: Add, DDL, % "hp x+6 ys BackgroundTrans Border Center vpanel_position0 gApply_settings_general r2 w"width*0.6, % "top|bottom||"
If (panel_position1 = "left") || (panel_position1 = "")
	Gui, settings_menu: Add, DDL, % "hp x+2 ys BackgroundTrans Border Center vpanel_position1 gApply_settings_general r2 w"width*0.6, % "left||right"
Else Gui, settings_menu: Add, DDL, % "hp x+2 ys BackgroundTrans Border Center vpanel_position1 gApply_settings_general r2 w"width*0.6, % "left|right||"
	Gui, settings_menu: Font, % "s"fSize0
Gui, settings_menu: Add, Checkbox, % "ys BackgroundTrans Checked" hide_panel " vhide_panel gApply_settings_general", % "hide panel"
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans y+"fSize0*1.5, % "interface size:"
Gui, settings_menu: Add, Text, ys x+6 BackgroundTrans gApply_settings_general vinterface_size_minus Border Center, % " – "
Gui, settings_menu: Add, Text, wp x+2 ys BackgroundTrans gApply_settings_general vinterface_size_reset Border Center, % "0"
Gui, settings_menu: Add, Text, wp x+2 ys BackgroundTrans gApply_settings_general vinterface_size_plus Border Center, % "+"
Return

Settings_menu_help:
MouseGetPos, mouseXpos, mouseYpos
Gui, settings_menu_help: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border HWNDhwnd_settings_menu_help
Gui, settings_menu_help: Color, Black
Gui, settings_menu_help: Margin, 12, 4
WinSet, Transparent, %trans%
Gui, settings_menu_help: Font, s%fSize1% cWhite, Fontin SmallCaps

If InStr(A_GuiControl, "pixelcheck")
{
	Gui, settings_menu_help: Add, Text, % "BackgroundTrans w"fSize0*20, explanation:`nthese pixel-checks merely trigger actions within the script itself and will -NEVER- result in any interaction with the client.`n`nui textures in PoE are sometimes updated in patches, which leads to pixel-checks failing. This is where you recalibrate the checks in order to continue using the script.
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}
If InStr(A_GuiControl, "gamescreen")
{
	Gui, settings_menu_help: Add, Picture, BackgroundTrans, img\GUI\game_screen.jpg
	Gui, settings_menu_help: Add, Text, BackgroundTrans wp, instructions:`nwhen recalibrating, make sure this panel with realm/league-info is visible in the top-right corner of the screen.`n`nexplanation:`nthis check helps the script identify whether the user is in a menu or on the regular 'game-screen', which enables it to hide overlays automatically in order to prevent obstructing full-screen menus.
	Gui, settings_menu_help: Show, % "NA x"mouseXpos " y"mouseYpos " AutoSize"
}
KeyWait, LButton
Gui, settings_menu_help: Destroy
Return

Settings_menu_notepad:
Gui, settings_menu: Add, Checkbox, % "ys Section BackgroundTrans gApply_settings_notepad xp+"spacing_settings*1.2 " venable_notepad Checked"enable_notepad, enable notepad
If (enable_notepad = 1)
{
	GoSub, Notepad
	Gui, settings_menu: Add, Text, % "xs Section Center BackgroundTrans y+"fSize0*1.2, text color (overlay):
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
}
Return

Settings_menu_omnikey:
If (GuiControl_copy = "reset_omnikey_hotkey") && (omnikey_hotkey != "")
{
	Hotkey, IfWinActive, ahk_group poe_window
	Hotkey, ~%omnikey_hotkey%,, Off
	omnikey_hotkey := ""
	Hotkey, ~MButton, Omnikey, On
}

Gui, settings_menu: Add, Text, % "ys Section BackgroundTrans HWNDmain_text xp+"spacing_settings*1.2, replace mbutton with:
ControlGetPos,,, width,,, ahk_id %main_text%
Gui, settings_menu: Font, % "s"fSize0-4
Gui, settings_menu: Add, Hotkey, % "ys hp BackgroundTrans vomnikey_hotkey gApply_settings_omnikey w"width//3, %omnikey_hotkey%
Gui, settings_menu: Font, % "s"fSize0
Gui, settings_menu: Add, Text, % "ys BackgroundTrans Border vreset_omnikey_hotkey gSettings_menu", % " clear "
Return

Settings_menu_pixelchecks:
Gui, settings_menu: Add, Text, % "ys Section BackgroundTrans HWNDmain_text xp+"spacing_settings*1.2, list of integrated pixel-checks:
ControlGetPos,,,, height,, ahk_id %main_text%
Gui, settings_menu: Add, Picture, % "ys BackgroundTrans gSettings_menu_help vPixelcheck_help h"height " w-1", img\GUI\help.png
Gui, settings_menu: Add, Text, % "xs Section BackgroundTrans HWNDmain_text border gPixelchecks vGamescreen y+"fSize0*1.2, % " check | calibrate "
Gui, settings_menu: Font, underline
Gui, settings_menu: Add, Text, % "ys BackgroundTrans gSettings_menu_help vGamescreen_help HWNDmain_text", % "game-screen"
Gui, settings_menu: Font, norm
Return

Settings_menuGuiClose:
WinGetPos, xsettings_menu, ysettings_menu,,, ahk_id %hwnd_settings_menu%
Gui, settings_menu: Submit
kill_timeout := (kill_timeout = "") ? 0 : kill_timeout
Gui, settings_menu: Destroy
hwnd_settings_menu := ""

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
Return

ToolTip_clear:
SetTimer, ToolTip_clear, delete
ToolTip,,,, 17
Return

LLK_Error(ErrorMessage)
{
	global
	MsgBox, % ErrorMessage
	ExitApp
}

LLK_Overlay(gui, toggleshowhide:="toggle", NA:=1)
{
	global
	If (gui="hide")
	{
		Loop, Parse, guilist, |, |
			Gui, %A_LoopField%: Hide
		Return
	}
	If (gui="show")
	{
		Loop, Parse, guilist, |, |
			If (state_%A_LoopField%=1) && (hwnd_%A_LoopField% != "")
				Gui, %A_LoopField%: Show, NA
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
	If (toggleshowhide="show")
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

LLK_PixelRecalibrate(name)
{
	global
	IniRead, pixel_%name%_x1, Resolutions.ini, %poe_height%p, %name% x-coordinate 1
	IniRead, pixel_%name%_y1, Resolutions.ini, %poe_height%p, %name% y-coordinate 1
	If (name != "gamescreen")
	{
		IniRead, pixel_%name%_x2, Resolutions.ini, %poe_height%p, %name% x-coordinate 2
		IniRead, pixel_%name%_y2, Resolutions.ini, %poe_height%p, %name% y-coordinate 2
	}
	loopcount := (name = "gamescreen") ? 1 : 2
	Loop %loopcount%
	{
		PixelGetColor, pixel_%name%_color%A_Index%, % xScreenOffSet + poe_width - pixel_%name%_x%A_Index%, % yScreenOffSet + pixel_%name%_y%A_Index%, RGB
		IniWrite, % pixel_%name%_color%A_Index%, ini\pixel checks (%poe_height%p).ini, gamescreen, color %A_Index%
	}
}

LLK_PixelSearch(name)
{
	global
	PixelSearch, OutputVarX, OutputVarY, xScreenOffSet + poe_width - pixel_%name%_x1, yScreenOffSet + pixel_%name%_y1, xScreenOffSet + poe_width - pixel_%name%_x1, yScreenOffSet + pixel_%name%_y1, pixel_%name%_color1, %pixelsearch_variation%, Fast RGB
	If (ErrorLevel = 0) && (name != "gamescreen")
		PixelSearch, OutputVarX, OutputVarY, xScreenOffSet + poe_width - pixel_%name%_x2, yScreenOffSet + pixel_%name%_y2, xScreenOffSet + poe_width - pixel_%name%_x2, yScreenOffSet + pixel_%name%_y2, pixel_%name%_color2, %pixelsearch_variation%, Fast RGB
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

LLK_ToolTip(message, duration := 1)
{
	global
	ToolTip, % message,,, 17
	SetTimer, ToolTip_clear, % 1000 * duration
}

#include External Functions.ahk