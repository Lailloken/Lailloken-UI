Init_cloneframes()
{
	local
	global vars, settings

	If !FileExist("ini" vars.poe_version "\clone frames.ini")
		IniWrite, % "", % "ini" vars.poe_version "\clone frames.ini", settings

	settings.cloneframes := {}, ini := IniBatchRead("ini" vars.poe_version "\clone frames.ini")
	settings.cloneframes.pixelchecks := !Blank(check := ini.settings["enable pixel-check"]) ? check : 0
	settings.cloneframes.hide := !Blank(check := ini.settings["hide in hideout"]) ? check : 0

	If !IsObject(vars.cloneframes)
		vars.cloneframes := {"enabled": 0, "scroll": {}}
	Else ;when calling this function to update clone-frames, destroy old GUIs just in case
	{
		If !vars.general.MultiThreading
			For cloneframe in vars.cloneframes.list
				Gui, % "cloneframe_" StrReplace(cloneframe, " ", "_") ": Destroy"
		vars.cloneframes.enabled := 0, vars.cloneframes.list := {}, vars.cloneframes.editing := ""
	}

	vars.hwnd.cloneframes := {}
	For key, val in ini
	{
		If (key = "settings")
			key := "settings_cloneframe" ;dummy entry for clone-frame creation
		vars.cloneframes.list[key] := {"enable": !Blank(check := ini[key].enable) ? check : 1}
		If !vars.general.MultiThreading
		{
			Gui, % "cloneframe_" StrReplace(key, " ", "_") ": New", -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd
			vars.hwnd.cloneframes[key] := hwnd
		}
		If vars.cloneframes.list[key].enable
			vars.cloneframes.enabled += 1

		vars.cloneframes.list[key].xSource := Format("{:0.0f}", !Blank(check := ini[key]["source x-coordinate"]) ? check : vars.client.x - vars.monitor.x + 4) ;coordinates refer to monitor's coordinates (without offsets)
		vars.cloneframes.list[key].ySource := Format("{:0.0f}", !Blank(check := ini[key]["source y-coordinate"]) ? check : vars.client.y - vars.monitor.y + 4)
		vars.cloneframes.list[key].width := Format("{:0.0f}", !Blank(check := ini[key]["frame-width"]) ? check : 200)
		vars.cloneframes.list[key].height := Format("{:0.0f}", !Blank(check := ini[key]["frame-height"]) ? check : 200)
		vars.cloneframes.list[key].xTarget := Format("{:0.0f}", !Blank(check := ini[key]["target x-coordinate"]) ? check : vars.client.xc - 100)
		vars.cloneframes.list[key].yTarget := Format("{:0.0f}", !Blank(check := ini[key]["target y-coordinate"]) ? check : vars.client.y - vars.monitor.y + 13)
		vars.cloneframes.list[key].xScale := !Blank(check := ini[key]["scaling x-axis"]) ? check : 100
		vars.cloneframes.list[key].yScale := !Blank(check := ini[key]["scaling y-axis"]) ? check : 100
		vars.cloneframes.list[key].opacity := !Blank(check := ini[key]["opacity"]) ? check : 5
	}
	vars.cloneframes.enabled -= 1, vars.cloneframes.list.settings_cloneframe.enable := 0 ;set the dummy entry to disabled
}

Cloneframes_Check()
{
	local
	global vars, settings

	MainThread := !InStr(A_ScriptDir, "modules"), location := vars.log.areaID
	If (vars.cloneframes.enabled
	&& ((settings.cloneframes.pixelchecks && (MainThread && Screenchecks_PixelSearch("gamescreen") || !MainThread && vars.pixels.gamescreen.check)) || !settings.cloneframes.pixelchecks)) ;user is on gamescreen, or auto-toggle is disabled
	&& (!settings.cloneframes.hide || (settings.cloneframes.hide && !LLK_StringCompare(location, ["hideout"]) && !InStr(location, "_town") && !InStr(location, "heisthub") && (location != "login"))) ;outside hideout/town/login, or auto-toggle is disabled
	&& !vars.sanctum.active
	|| (vars.settings.active = "clone-frames") ;accessing the clone-frames section of the settings
		Cloneframes_Show()
	Else Cloneframes_Hide()
}

Cloneframes_Hide()
{
	local
	global vars, settings

	For cloneframe in vars.cloneframes.list
	{
		If vars.hwnd.cloneframes[cloneframe] && WinExist("ahk_id " vars.hwnd.cloneframes[cloneframe])
			Gui, % "cloneframe_" StrReplace(cloneframe, " ", "_") ": Hide"
		If vars.hwnd.cloneframe_borders.main && WinExist("ahk_id " vars.hwnd.cloneframe_borders.main)
			Gui, cloneframe_border: Hide
		If vars.hwnd.cloneframe_borders.second && WinExist("ahk_id " vars.hwnd.cloneframe_borders.second)
			Gui, cloneframe_border2: Hide
	}
}

Cloneframes_SettingsAdd()
{
	local
	global vars, settings

	name := LLK_ControlGet(vars.hwnd.settings.name)
	While (SubStr(name, 1, 1) = " ")
		name := SubStr(name, 2)
	While (SubStr(name, 0) = " ")
		name := SubStr(name, 1, -1)

	If vars.cloneframes.list.HasKey(name)
		error := [Lang_Trans("global_errorname", 4), 1.5, "red"]
	Else If vars.cloneframes.editing
		error := [Lang_Trans("m_clone_exitedit"), 1.5, "red"]
	Else If (name = "")
		error := [Lang_Trans("global_errorname", 1), 1.5, "red"]

	Loop, Parse, name
		If !LLK_IsType(A_LoopField, "alnum")
		{
			error := [Lang_Trans("global_errorname", 3), 2, "red"]
			Break
		}

	If InStr(name, "settings")
		error := [Lang_Trans("global_errorname", 5) "settings", 2, "red"]

	If error
	{
		WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.settings.name
		LLK_ToolTip(error.1, error.2, x, y + h,, error.3)
		Return
	}

	IniDelete, % "ini" vars.poe_version "\clone frames.ini", % name
	IniWrite, 1, % "ini" vars.poe_version "\clone frames.ini", % name, enable
	Init_cloneframes(), Cloneframes_Thread()
	Settings_menu("clone-frames")
}

Cloneframes_SettingsRefresh(name := "")
{
	local
	global vars, settings

	style := (name != "") ? "-" : "+"
	If (vars.cloneframes.editing != "")
	{
		GuiControl, % "+c"(vars.cloneframes.list[vars.cloneframes.editing].enable ? "White" : "Gray"), % vars.hwnd.settings["enable_"vars.cloneframes.editing]
		GuiControl, movedraw, % vars.hwnd.settings["enable_"vars.cloneframes.editing]
	}

	Init_cloneframes(), Cloneframes_Thread()
	vars.cloneframes.editing := name, StringSend("clone-edit=" name)
	GuiControl, +cLime, % vars.hwnd.settings["enable_"vars.cloneframes.editing]
	GuiControl, movedraw, % vars.hwnd.settings["enable_"vars.cloneframes.editing]
	If (name = "")
	{
		name := "settings_cloneframe"
		Settings_menu("clone-frames")
		Return
	}
	GuiControl, % style "Disabled", % vars.hwnd.settings.xSource ;it's not possible to remove Disabled and set the new value with a single GuiControl call
	GuiControl,, % vars.hwnd.settings.xSource, % vars.cloneframes.list[name].xSource
	GuiControl, % style "Disabled", % vars.hwnd.settings.ySource
	GuiControl,, % vars.hwnd.settings.ySource, % vars.cloneframes.list[name].ySource
	GuiControl, % style "Disabled", % vars.hwnd.settings.width
	GuiControl,, % vars.hwnd.settings.width, % vars.cloneframes.list[name].width
	GuiControl, % style "Disabled", % vars.hwnd.settings.height
	GuiControl,, % vars.hwnd.settings.height, % vars.cloneframes.list[name].height
	GuiControl, % style "Disabled", % vars.hwnd.settings.xTarget
	GuiControl,, % vars.hwnd.settings.xTarget, % vars.cloneframes.list[name].xTarget
	GuiControl, % style "Disabled", % vars.hwnd.settings.yTarget
	GuiControl,, % vars.hwnd.settings.yTarget, % vars.cloneframes.list[name].yTarget
	GuiControl, % style "Disabled", % vars.hwnd.settings.xScale
	GuiControl,, % vars.hwnd.settings.xScale, % vars.cloneframes.list[name].xScale
	GuiControl, % style "Disabled", % vars.hwnd.settings.yScale
	GuiControl,, % vars.hwnd.settings.yScale, % vars.cloneframes.list[name].yScale
	GuiControl, % style "Disabled", % vars.hwnd.settings.opacity
	GuiControl,, % vars.hwnd.settings.opacity, % vars.cloneframes.list[name].opacity
	GuiControl, % style "Disabled", % vars.hwnd.settings.xSource
	GuiControl, % vars.hwnd.settings.main ": "(style = "+" ? "+cWhite" : "+cLime"), % "clone-frame editing:"
	GuiControl, % vars.hwnd.settings.main ": movedraw", % "clone-frame editing:"
	GuiControl, % (style = "+") ? "-g +cGray" : "+gSettings_cloneframes2 +cLime", % vars.hwnd.settings.save
	GuiControl, movedraw, % vars.hwnd.settings.save
	GuiControl, % (style = "+") ? "-g +cGray" : "+gSettings_cloneframes2 +cRed", % vars.hwnd.settings.discard
	GuiControl, movedraw, % vars.hwnd.settings.discard
}

Cloneframes_SettingsSave()
{
	local
	global vars, settings

	name := vars.cloneframes.editing
	IniWrite, % vars.cloneframes.list[name].xSource, % "ini" vars.poe_version "\clone frames.ini", % name, source x-coordinate
	IniWrite, % vars.cloneframes.list[name].ySource, % "ini" vars.poe_version "\clone frames.ini", % name, source y-coordinate
	IniWrite, % vars.cloneframes.list[name].xTarget, % "ini" vars.poe_version "\clone frames.ini", % name, target x-coordinate
	IniWrite, % vars.cloneframes.list[name].yTarget, % "ini" vars.poe_version "\clone frames.ini", % name, target y-coordinate
	IniWrite, % vars.cloneframes.list[name].width, % "ini" vars.poe_version "\clone frames.ini", % name, frame-width
	IniWrite, % vars.cloneframes.list[name].height, % "ini" vars.poe_version "\clone frames.ini", % name, frame-height
	IniWrite, % vars.cloneframes.list[name].xScale, % "ini" vars.poe_version "\clone frames.ini", % name, scaling x-axis
	IniWrite, % vars.cloneframes.list[name].yScale, % "ini" vars.poe_version "\clone frames.ini", % name, scaling y-axis
	IniWrite, % vars.cloneframes.list[name].opacity, % "ini" vars.poe_version "\clone frames.ini", % name, opacity

	Cloneframes_SettingsRefresh()
}

Cloneframes_SettingsApply(cHWND, hotkey := "")
{
	local
	global vars, settings, json
	static hotkeys := {"LButton": 1, "RButton": 1, "MButton": 1, "WheelUp": 1, "WheelDown": 1}

	If Blank(vars.cloneframes.editing)
		Return
	check := LLK_HasVal(vars.cloneframes.scroll, cHWND), editing := vars.cloneframes.editing

	value := InStr(hotkey, "wheel") ? vars.cloneframes.list[editing][check] + (hotkey = "WheelUp" ? 1 : -1) : LLK_ControlGet(cHWND), value := Blank(value) ? 0 : value
	If (check = "opacity")
		value := (value > 5) ? 5 : (value < 1) ? 1 : value, vars.cloneframes.list[editing][check] := value
	If InStr("width, height", check)
		value := (value < 8) ? 8 : value
	If InStr(check, "scale")
		value := (value < 20) ? 20 : value
	If InStr(hotkey, "wheel")
		GuiControl,, % vars.hwnd.settings[check], % value
	Else vars.cloneframes.list[editing][check] := value

	If hotkeys[A_ThisHotkey] && vars.general.MultiThreading
		StringSend("clone-edit=" json.dump(vars.cloneframes.list[editing]))
}

Cloneframes_Show()
{
	local
	global vars, settings

	For cloneframe, val in vars.cloneframes.list
	{
		If !val.enable && !(vars.cloneframes.editing && cloneframe = vars.cloneframes.editing) || (cloneframe = "settings_cloneframe")
		{
			If WinExist("ahk_id " vars.hwnd.cloneframes[cloneframe])
				Gui, % "cloneframe_" StrReplace(cloneframe, " ", "_") ": Hide"
			If vars.hwnd.cloneframe_borders.main && WinExist("ahk_id " vars.hwnd.cloneframe_borders.main) && !vars.cloneframes.editing
				Gui, cloneframe_border: Hide
			If vars.hwnd.cloneframe_borders.second && WinExist("ahk_id " vars.hwnd.cloneframe_borders.second) && !vars.cloneframes.editing
				Gui, cloneframe_border2: Hide
			continue
		}

		If !WinExist("ahk_id " vars.hwnd.cloneframes[cloneframe])
			Gui, % "cloneframe_" StrReplace(cloneframe, " ", "_") ": Show", NA
		pBitmap := Gdip_BitmapFromScreen(vars.monitor.x + val.xSource "|" vars.monitor.y + val.ySource "|" val.width "|" val.height)
		width := val.width* val.xScale/100, height := val.height* val.yScale/100
		hbmBitmap := CreateDIBSection(width, height), hdcBitmap := CreateCompatibleDC(), obmBitmap := SelectObject(hdcBitmap, hbmBitmap), gBitmap := Gdip_GraphicsFromHDC(hdcBitmap)
		Gdip_SetInterpolationMode(gBitmap, 0)
		Gdip_DrawImage(gBitmap, pBitmap, 0, 0, width, height, 0, 0, val.width, val.height, 0.2 + 0.16* val.opacity)
		If vars.cloneframes.editing && (cloneframe = vars.cloneframes.editing)
		{
			If !IsObject(vars.hwnd.cloneframe_borders)
				vars.hwnd.cloneframe_borders := {}
			If !vars.hwnd.cloneframe_borders.main
			{
				Gui, cloneframe_border: New, -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd, LLK-UI: Clone-Frames Borders ;source-frame with two colored corners
				Gui, cloneframe_border: Margin, 4, 4
				Gui, cloneframe_border: Color, Silver
				WinSet, TransColor, Black
				For index, array in vars.GUI
					If !Blank(LLK_HasVal(array, vars.hwnd.cloneframe_borders.main)) || !Blank(LLK_HasVal(array, vars.hwnd.cloneframe_borders.second))
						remove .= index ";"
				Loop, Parse, remove, `;
					If IsNumber(A_LoopField)
						vars.GUI.RemoveAt(A_LoopField)
				vars.hwnd.cloneframe_borders.main := hwnd
				Gui, cloneframe_border: Add, Picture, % "x0 y0 w"val.height/2 " h"val.height/2 " HWNDhwnd", img\GUI\cloneframe_corner1.png
				vars.hwnd.cloneframe_borders.corner1 := hwnd
				Gui, cloneframe_border: Add, Picture, % "x"8 + val.width - val.height/2 " y"8 + val.height/2 " w"val.height/2 " h"val.height/2 " HWNDhwnd", img\GUI\cloneframe_corner2.png
				vars.hwnd.cloneframe_borders.corner2 := hwnd
				Gui, cloneframe_border: Margin, 0, 0
				Gui, cloneframe_border: Add, Picture, x4 y4 HWNDhwnd, img\GUI\square_black.png
				vars.hwnd.cloneframe_borders.trans := hwnd

				Gui, cloneframe_border2: New, -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd ;GUI that highlights the top-left corner of the target-frame
				Gui, cloneframe_border2: Margin, 4, 4
				Gui, cloneframe_border2: Color, Black
				WinSet, TransColor, Black
				vars.hwnd.cloneframe_borders.second := hwnd
				Gui, cloneframe_border2: Add, Progress, % "x0 y0 w12 h12 BackgroundYellow Disabled HWNDhwnd", 0
				vars.hwnd.cloneframe_borders.corner3 := hwnd
			}
			short_edge := (val.height < val.width) ? val.height : val.width
			GuiControl, Move, % vars.hwnd.cloneframe_borders.trans, % "w"val.width " h"val.height
			GuiControl, Move, % vars.hwnd.cloneframe_borders.corner1, % "w"short_edge/2 " h"short_edge/2
			GuiControl, Move, % vars.hwnd.cloneframe_borders.corner2, % "x"9 + val.width - short_edge/2 " y"9 + val.height -short_edge/2 " w"short_edge/2 " h"short_edge/2
			If IsNumber(val.xSource) && IsNumber(val.ySource)
			{
				Gui, cloneframe_border: Show, % "NA x"vars.monitor.x + val.xSource - 4 " y"vars.monitor.y + val.ySource - 4 " w"val.width + 8 " h"val.height + 8
				Gui, cloneframe_border2: Show, % "NA x"vars.monitor.x + val.xTarget - 12 " y"vars.monitor.y + val.yTarget - 12 " AutoSize"
			}
		}
		UpdateLayeredWindow(vars.hwnd.cloneframes[cloneframe], hdcBitmap, vars.monitor.x + val.xTarget, vars.monitor.y + val.yTarget, width, height)
		Gdip_DisposeImage(pBitmap)
		SelectObject(hdcBitmap, obmBitmap)
		DeleteObject(hbmBitmap)
		DeleteDC(hdcBitmap)
		Gdip_DeleteGraphics(gBitmap)
	}
}

Cloneframes_Snap(hotkey)
{
	local
	global vars, settings

	name := vars.cloneframes.editing

	Switch hotkey
	{
		Case "LButton":
			GuiControl,, % vars.hwnd.settings.xSource, % vars.general.xMouse - vars.monitor.x
			GuiControl,, % vars.hwnd.settings.ySource, % vars.general.yMouse - vars.monitor.y
		Case "RButton":
			If (vars.general.xMouse - vars.monitor.x - vars.cloneframes.list[name].xSource <= 0) || (vars.general.yMouse - vars.monitor.y - vars.cloneframes.list[name].ySource <= 0) ;prevent negative widths/heights
			{
				LLK_ToolTip(Lang_Trans("m_clone_errorborders"),,,,, "red")
				Return
			}
			GuiControl,, % vars.hwnd.settings.width, % vars.general.xMouse - vars.monitor.x - vars.cloneframes.list[name].xSource
			GuiControl,, % vars.hwnd.settings.height, % vars.general.yMouse - vars.monitor.y - vars.cloneframes.list[name].ySource
		Case "MButton":
			GuiControl,, % vars.hwnd.settings.xTarget, % vars.general.xMouse - vars.monitor.x
			GuiControl,, % vars.hwnd.settings.yTarget, % vars.general.yMouse - vars.monitor.y
	}
	KeyWait, %hotkey%
}

Cloneframes_Thread(wParam := 0, lParam := 0)
{
	local
	global vars

	If !vars.general.MultiThreading
		Return
	SendMessage, 0x8001, wParam, lParam,, % vars.general.bThread,,,, 1000
}
