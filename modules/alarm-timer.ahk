Alarm:
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

start := A_TickCount
While GetKeyState("LButton", "P") && (A_Gui = "alarm_panel" || A_Gui = "alarm_drag")
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
		If !IsNumber(alarm_minutes)
		{
			LLK_ToolTip("incorrect input", 2)
			Return
		}
		alarm_minutes := (alarm_minutes > 60) ? 60 : alarm_minutes
		alarm_minutes := Floor(alarm_minutes*60)
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
		Gui, alarm: Add, Edit, % "ys hp x+6 cBlack BackgroundTrans Center valarm_minutes Limit4 w"fSize0*1.8, 0
		Gui, alarm: Font, s%fSize0%
		Gui, alarm: Add, Text, ys x+6 BackgroundTrans Center, minute(s)
		Gui, alarm: Add, Checkbox, xs BackgroundTrans Center valarm_loop, loop && beep
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
IniRead, alarm_panel_xpos, ini\alarm.ini, UI, button xcoord, % A_Space
If !alarm_panel_xpos
	alarm_panel_xpos := poe_width/2 - (alarm_panel_dimensions + 2)/2
IniRead, alarm_panel_ypos, ini\alarm.ini, UI, button ycoord, % A_Space
If !alarm_panel_ypos
	alarm_panel_ypos := poe_height - (alarm_panel_dimensions + 2)
Return

alarmGuiClose()
{
	global
	If !WinExist("ahk_group poe_window") || (alarm_timestamp < A_Now)
	{
		alarm_timestamp := ""
		hwnd_alarm := ""
	}
	LLK_Overlay("alarm", "hide")
}