Init_cloneframes()
{
	local
	global vars, settings
	
	If !FileExist("ini\clone frames.ini")
		IniWrite, 0, ini\clone frames.ini, Settings, enable pixel-check
	
	settings.cloneframes := {}
	settings.cloneframes.pixelchecks := LLK_IniRead("ini\clone frames.ini", "Settings", "enable pixel-check", 1)
	settings.cloneframes.hide := LLK_IniRead("ini\clone frames.ini", "Settings", "hide in hideout", 0)
	
	If !IsObject(vars.cloneframes)
		vars.cloneframes := {"enabled": 0, "scroll": {}}
	Else ;when calling this function to update clone-frames, destroy old GUIs just in case
	{
		For cloneframe in vars.cloneframes.list
		{
			Gui, % StrReplace(cloneframe, " ", "_") ": Destroy"
			vars.hwnd.Delete(cloneframe)
		}
		vars.cloneframes.enabled := 0, vars.cloneframes.list := {}, vars.cloneframes.editing := ""
	}
	
	iniread := StrReplace(LLK_IniRead("ini\clone frames.ini"), "settings`n")
	Loop, Parse, iniread, `n ;remove underscores from old name-formatting
	{
		If InStr(A_LoopField, "_")
		{
			IniRead, parse, ini\clone frames.ini, % A_LoopField
			IniDelete, ini\clone frames.ini, % A_LoopField
			IniWrite, % parse, ini\clone frames.ini, % StrReplace(A_LoopField, "_", " ")
		}
	}

	vars.hwnd.cloneframes := {}, iniread := StrReplace(LLK_IniRead("ini\clone frames.ini"), "settings", "settings_cloneframe") ;replace 'settings' ini-section with a dummy entry for clone-frame creation
	Loop, Parse, iniread, `n
	{
		If (A_LoopField = "")
			continue
		vars.cloneframes.list[A_LoopField] := {"enable": LLK_IniRead("ini\clone frames.ini", A_LoopField, "enable", 1)}
		Gui, % StrReplace(A_LoopField, " ", "_") ": New", -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd
		vars.hwnd.cloneframes[A_LoopField] := hwnd
		If vars.cloneframes.list[A_LoopField].enable
			vars.cloneframes.enabled += 1
		
		vars.cloneframes.list[A_LoopField].xSource := Format("{:0.0f}", LLK_IniRead("ini\clone frames.ini", A_LoopField, "source x-coordinate", vars.client.x + 4 - vars.monitor.x)) ;coordinates refer to monitor's coordinates (without offsets)
		vars.cloneframes.list[A_LoopField].ySource := Format("{:0.0f}", LLK_IniRead("ini\clone frames.ini", A_LoopField, "source y-coordinate", vars.client.y + 4 - vars.monitor.y))
		vars.cloneframes.list[A_LoopField].width := Format("{:0.0f}", LLK_IniRead("ini\clone frames.ini", A_LoopField, "frame-width", 200))
		vars.cloneframes.list[A_LoopField].height := Format("{:0.0f}", LLK_IniRead("ini\clone frames.ini", A_LoopField, "frame-height", 200))
		vars.cloneframes.list[A_LoopField].xTarget := Format("{:0.0f}", LLK_IniRead("ini\clone frames.ini", A_LoopField, "target x-coordinate", vars.client.xc - 100 - vars.monitor.x))
		vars.cloneframes.list[A_LoopField].yTarget := Format("{:0.0f}", LLK_IniRead("ini\clone frames.ini", A_LoopField, "target y-coordinate", vars.client.y + 13 - vars.monitor.y))
		vars.cloneframes.list[A_LoopField].xScale := LLK_IniRead("ini\clone frames.ini", A_LoopField, "scaling x-axis", 100)
		vars.cloneframes.list[A_LoopField].yScale := LLK_IniRead("ini\clone frames.ini", A_LoopField, "scaling y-axis", 100)
		vars.cloneframes.list[A_LoopField].opacity := LLK_IniRead("ini\clone frames.ini", A_LoopField, "opacity", 5)
	}
	vars.cloneframes.enabled -= 1, vars.cloneframes.list.settings_cloneframe.enable := 0 ;set the dummy entry to disabled
}

CloneframesHide()
{
	local
	global vars, settings
	
	For cloneframe in vars.cloneframes.list
	{
		If vars.hwnd.cloneframes[cloneframe] && WinExist("ahk_id " vars.hwnd.cloneframes[cloneframe])
			Gui, % StrReplace(cloneframe, " ", "_") ": Hide"
		If vars.hwnd.cloneframe_borders.main && WinExist("ahk_id " vars.hwnd.cloneframe_borders.main)
			Gui, cloneframe_border: Hide
		If vars.hwnd.cloneframe_borders.second && WinExist("ahk_id " vars.hwnd.cloneframe_borders.second)
			Gui, cloneframe_border2: Hide
	}
}

CloneframesSettingsAdd()
{
	local
	global vars, settings
	
	name := LLK_ControlGet(vars.hwnd.settings.name)
	While (SubStr(name, 1, 1) = " ")
		name := SubStr(name, 2)
	While (SubStr(name, 0) = " ")
		name := SubStr(name, 1, -1)

	If vars.cloneframes.list.HasKey(name)
		error := [LangTrans("global_errorname", 4), 1.5, "red"]
	Else If vars.cloneframes.editing
		error := [LangTrans("m_clone_exitedit"), 1.5, "red"]
	Else If (name = "")
		error := [LangTrans("global_errorname", 1), 1.5, "red"]

	Loop, Parse, name
		If !LLK_IsType(A_LoopField, "alnum")
		{
			error := [LangTrans("global_errorname", 3), 2, "red"]
			Break
		}

	If InStr(name, "settings")
		error := [LangTrans("global_errorname", 5) "settings", 2, "red"]

	If error
	{
		WinGetPos, x, y, w, h, % "ahk_id "vars.hwnd.settings.name
		LLK_ToolTip(error.1, error.2, x, y + h,, error.3)
		Return
	}

	IniDelete, ini\clone frames.ini, % name
	IniWrite, 1, ini\clone frames.ini, % name, enable
	Init_cloneframes()
	Settings_menu("clone-frames")
}

CloneframesSettingsRefresh(name := "")
{
	local
	global vars, settings
	
	style := (name != "") ? "-" : "+"	
	If (vars.cloneframes.editing != "")
	{
		GuiControl, % "+c"(vars.cloneframes.list[vars.cloneframes.editing].enable ? "White" : "Gray"), % vars.hwnd.settings["enable_"vars.cloneframes.editing]
		GuiControl, movedraw, % vars.hwnd.settings["enable_"vars.cloneframes.editing]
	}

	Init_cloneframes()
	vars.cloneframes.editing := name
	GuiControl, +cLime, % vars.hwnd.settings["enable_"vars.cloneframes.editing]
	GuiControl, movedraw, % vars.hwnd.settings["enable_"vars.cloneframes.editing]
	If (name = "")
	{
		Init_cloneframes()
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

CloneframesSettingsSave()
{
	local
	global vars, settings

	name := vars.cloneframes.editing
	IniWrite, % vars.cloneframes.list[name].xSource, ini\clone frames.ini, % name, source x-coordinate
	IniWrite, % vars.cloneframes.list[name].ySource, ini\clone frames.ini, % name, source y-coordinate
	IniWrite, % vars.cloneframes.list[name].xTarget, ini\clone frames.ini, % name, target x-coordinate
	IniWrite, % vars.cloneframes.list[name].yTarget, ini\clone frames.ini, % name, target y-coordinate
	IniWrite, % vars.cloneframes.list[name].width, ini\clone frames.ini, % name, frame-width
	IniWrite, % vars.cloneframes.list[name].height, ini\clone frames.ini, % name, frame-height
	IniWrite, % vars.cloneframes.list[name].xScale, ini\clone frames.ini, % name, scaling x-axis
	IniWrite, % vars.cloneframes.list[name].yScale, ini\clone frames.ini, % name, scaling y-axis
	IniWrite, % vars.cloneframes.list[name].opacity, ini\clone frames.ini, % name, opacity

	CloneframesSettingsRefresh()
}

CloneframesSettingsApply(cHWND, hotkey := "")
{
	local
	global vars, settings
	
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
}

CloneframesShow()
{
	local
	global vars, settings
	
	For cloneframe, val in vars.cloneframes.list
	{
		If !val.enable && !(vars.cloneframes.editing && cloneframe = vars.cloneframes.editing) || (cloneframe = "settings_cloneframe")
		{
			If WinExist("ahk_id " vars.hwnd.cloneframes[cloneframe])
				Gui, % StrReplace(cloneframe, " ", "_") ": Hide"
			If vars.hwnd.cloneframe_borders.main && WinExist("ahk_id " vars.hwnd.cloneframe_borders.main) && !vars.cloneframes.editing
				Gui, cloneframe_border: Hide
			If vars.hwnd.cloneframe_borders.second && WinExist("ahk_id " vars.hwnd.cloneframe_borders.second) && !vars.cloneframes.editing
				Gui, cloneframe_border2: Hide
			continue
		}
		If !WinExist("ahk_id " vars.hwnd.cloneframes[cloneframe])
			Gui, % StrReplace(cloneframe, " ", "_") ": Show", NA
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
				Gui, cloneframe_border: New, -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs HWNDhwnd ;source-frame with two colored corners
				Gui, cloneframe_border: Margin, 4, 4
				Gui, cloneframe_border: Color, Silver
				WinSet, TransColor, Black
				For index, array in vars.GUI
					If LLK_HasVal(array, vars.hwnd.cloneframe_borders.main) || LLK_HasVal(array, vars.hwnd.cloneframe_borders.second)
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

CloneframesSnap(hotkey)
{
	local
	global vars, settings
	
	If vars.cloneframes.last
		Return
	name := vars.cloneframes.editing, vars.cloneframes.last := A_TickCount
	
	Switch hotkey
	{
		Case "F1":
			;vars.cloneframes.list[name].xSource := vars.general.xMouse - vars.monitor.x, vars.cloneframes.list[name].ySource := vars.general.yMouse - vars.monitor.y
			GuiControl,, % vars.hwnd.settings.xSource, % vars.general.xMouse - vars.monitor.x
			GuiControl,, % vars.hwnd.settings.ySource, % vars.general.yMouse - vars.monitor.y
		Case "F2":
			If (vars.general.xMouse - vars.monitor.x - vars.cloneframes.list[name].xSource <= 0) || (vars.general.yMouse - vars.monitor.y - vars.cloneframes.list[name].ySource <= 0) ;prevent negative widths/heights
			{
				LLK_ToolTip(LangTrans("m_clone_errorborders"),,,,, "red")
				Return
			}
			;vars.cloneframes.list[name].width := vars.general.xMouse - vars.monitor.x - vars.cloneframes.list[name].xSource
			;vars.cloneframes.list[name].height := vars.general.yMouse - vars.monitor.y - vars.cloneframes.list[name].ySource
			GuiControl,, % vars.hwnd.settings.width, % vars.general.xMouse - vars.monitor.x - vars.cloneframes.list[name].xSource
			GuiControl,, % vars.hwnd.settings.height, % vars.general.yMouse - vars.monitor.y - vars.cloneframes.list[name].ySource
		Case "F3":
			;vars.cloneframes.list[name].xTarget := vars.general.xMouse - vars.monitor.x, vars.cloneframes.list[name].yTarget := vars.general.yMouse - vars.monitor.y
			GuiControl,, % vars.hwnd.settings.xTarget, % vars.general.xMouse - vars.monitor.x
			GuiControl,, % vars.hwnd.settings.yTarget, % vars.general.yMouse - vars.monitor.y
	}
}
