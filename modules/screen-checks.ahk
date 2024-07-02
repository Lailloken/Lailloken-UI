Init_screenchecks()
{
	local
	global vars, settings

	If (vars.client.h0 / vars.client.w0 < (5/12)) ;if the client is running a resolution that's wider than 21:9, there is a potential for black bars on each side
		settings.general.blackbars := LLK_IniRead("ini\config.ini", "Settings", "black-bar compensation", 0) ;reminder: keep it in config.ini (instead of screen checks.ini) because it's not resolution-specific
	Else settings.general.blackbars := 0

	If settings.general.blackbars ;apply offsets if black-bar compensation is enabled
	{
		settings.general.oGamescreen := Format("{:0.0f}", (vars.client.w0 - (vars.client.h0 / (5/12))) / 2) ;get the width of the black bars (as an offset for pixel-checks)
		vars.client.x := vars.client.x0 + settings.general.oGamescreen, vars.client.w := vars.client.w0 - 2*settings.general.oGamescreen
	}
	Else settings.general.oGamescreen := 0

	settings.features.pixelchecks := LLK_IniRead("ini\config.ini", "Settings", "background pixel-checks", 1) ;reminder: keep it in config.ini (instead of screen checks.ini) because it's not resolution-specific
	vars.pixelsearch := {}, parse := LLK_IniRead("data\Resolutions.ini", vars.client.h "p", "gamescreen coordinates")
	If InStr(parse, ",")
		vars.pixelsearch.gamescreen := {"x1": SubStr(parse, 1, InStr(parse, ",") - 1), "y1": SubStr(parse, InStr(parse, ",") + 1)}

	ini := IniBatchRead("ini\screen checks (" vars.client.h "p).ini")
	vars.pixelsearch.gamescreen.color1 := ini.gamescreen["color 1"]
	vars.pixelsearch.gamescreen.check := 0
	vars.pixelsearch.inventory := {"x1": 0, "x2": 0, "x3": 6, "y1": 0, "y2": 6, "y3": 0, "check": 0}
	Loop 3
		vars.pixelsearch.inventory["color" A_Index] := ini.inventory["color " A_Index]

	vars.pixelsearch.variation := 0, vars.pixelsearch.list := {"gamescreen": 1, "inventory": 1}
	vars.imagesearch := {}
	vars.imagesearch.search := ["skilltree", "necro_lantern", "betrayal"] ;this array is parsed when doing image-checks: order is important (place static checks in front for better performance)
	vars.imagesearch.list := {"betrayal": 1, "necro_lantern": 1, "skilltree": 1, "stash": 0} ;this object is parsed when listing image-checks in the settings menu
	vars.imagesearch.checks := {"betrayal": {"x": vars.client.w - Round((1/72) * vars.client.h) * 2 , "y": Round((1/72) * vars.client.h), "w": Round((1/72) * vars.client.h), "h": Round((1/72) * vars.client.h)}
		, "skilltree": {"x": vars.client.w//2 - Round((1/16) * vars.client.h)//2, "y": Round(0.054 * vars.client.h), "w": Round((1/16) * vars.client.h), "h": Round(0.02 * vars.client.h)}
		, "stash": {"x": Round(0.27 * vars.client.h), "y": Round(0.055 * vars.client.h), "w": Round(0.07 * vars.client.h), "h": Round((1/48) * vars.client.h)}
		, "necro_lantern": ""}
	vars.imagesearch.variation := 15

	For key in vars.imagesearch.list
		parse := StrSplit(ini[key]["last coordinates"], ","), vars.imagesearch[key] := {"check": 0, "x1": parse.1, "y1": parse.2, "x2": parse.3, "y2": parse.4}
}

Screenchecks_ImageRecalibrate(mode := "", check := "")
{
	local
	global vars, settings
	static hwnd_gui2

	If InStr(mode, "button")
	{
		KeyWait, % mode, D
		MouseGetPos, x1, y1
		Gui, LLK_snip_area: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow HWNDhwnd_gui2"
		Gui, LLK_snip_area: Margin, 0, 0
		Gui, LLK_snip_area: Color, Aqua
		WinSet, Trans, 75
		While GetKeyState(mode, "P")
		{
			MouseGetPos, x2, y2
			xPos := Min(x1, x2), yPos := Min(y1, y2), w := Abs(x1 - x2), h := Abs(y1 - y2)
			If w && h
				Gui, LLK_snip_area: Show, % "NA x" xPos " y" yPos " w" w " h" h
			Sleep 10
		}
		If WinExist("ahk_id " hwnd_gui2)
		{
			WinGetPos, x, y, w, h, ahk_id %hwnd_gui2%
			vars.snipping_tool.coords_area := {"x": x, "y": y, "w": w, "h": h}
			If InStr(mode, "LButton")
				vars.snipping_tool.GUI := 0
		}
	}
	Else If mode && IsObject(vars.snipping_tool.coords_area)
	{
		Switch StrReplace(mode, "*")
		{
			Case "w":
				vars.snipping_tool.coords_area[GetKeyState("Shift", "P") ? "h" : "y"] -= 1
			Case "a":
				vars.snipping_tool.coords_area[GetKeyState("Shift", "P") ? "w" : "x"] -= 1
			Case "s":
				vars.snipping_tool.coords_area[GetKeyState("Shift", "P") ? "h" : "y"] += 1
			Case "d":
				vars.snipping_tool.coords_area[GetKeyState("Shift", "P") ? "w" : "x"] += 1
			Case "space":
				vars.snipping_tool.GUI := 0
		}
		Gui, LLK_snip_area: Show, % "NA x" vars.snipping_tool.coords_area.x " y" vars.snipping_tool.coords_area.y " w" vars.snipping_tool.coords_area.w " h" vars.snipping_tool.coords_area.h
	}
	If mode
		Return

	If (check && vars.system.click = 1) && !InStr(check, "necro_")
	{
		pBitmap := Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1), checks := vars.imagesearch.checks
		If settings.general.blackbars
			pBitmap_copy := Gdip_CloneBitmapArea(pBitmap, settings.general.oGamescreen,, vars.client.w, vars.client.h,, 1), Gdip_DisposeImage(pBitmap), pBitmap := pBitmap_copy
		pClip := Gdip_CloneBitmapArea(pBitmap, checks[check].x, checks[check].y, checks[check].w, checks[check].h,, 1), Gdip_DisposeImage(pBitmap)
	}
	Else
	{
		Clipboard := "", vars.general.gui_hide := 1, LLK_Overlay("hide"), vars.snipping_tool := {"GUI": 1}
		pBitmap := Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1), Gdip_GetImageDimensions(pBitmap, width, height), hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)

		Gui, LLK_snip: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_gui"
		Gui, LLK_snip: Font, % "s" Round(settings.general.fSize * 1.5) " cAqua", % vars.system.font
		Gui, LLK_snip: Margin, 0, 0
		Loop 6
			text .= (!text ? " " : "`n ") LangTrans("screen_snipinstructions", A_Index) " "
		vars.hwnd.snipping_tool := {"main": hwnd_gui}, align := "left", LLK_PanelDimensions([text], settings.general.fSize * 2, wText, hText)
		Gui, LLK_snip: Add, Text, % "x0 y" height//2 - hText//2 " w" width " h" hText " BackgroundTrans Left HWNDhwnd_text", % text
		Gui, LLK_snip: Add, Pic, % "x0 y0 wp h" height " BackgroundTrans", img\GUI\square_black_trans.png
		Gui, LLK_snip: Add, Pic, % "xp yp wp hp", HBitmap:*%hBitmap%*
		Gui, LLK_snip: Show, NA x10000 y10000 w%width% h%height%
		WinGetPos, xPos, yPos, width, height, ahk_id %hwnd_gui%
		Gui, LLK_snip: Show, % "x" vars.monitor.x + vars.monitor.w / 2 - width//2 " y" vars.monitor.y + vars.monitor.h / 2 - height//2
		WinGetPos, xPos, yPos, width, height, ahk_id %hwnd_gui%
		vars.snipping_tool.coords := {"x": xPos, "y": yPos, "w": width, "h": height}, coords := vars.snipping_tool.coords

		If vars.client.stream
			Sleep, 1000
		While vars.snipping_tool.GUI && WinActive("ahk_id " hwnd_gui)
		{
			If (align = "left") && (vars.general.xMouse <= coords.x + coords.w // 2)
			{
				GuiControl, +Right, % hwnd_text
				GuiControl, movedraw, % hwnd_text
				align := "right"
			}
			Else If (align = "right") && (vars.general.xMouse >= coords.x + coords.w // 2)
			{
				GuiControl, +Left, % hwnd_text
				GuiControl, movedraw, % hwnd_text
				align := "left"
			}
			Sleep 100
		}

		Gui, LLK_snip: Destroy
		Gui, LLK_snip_area: Destroy
		vars.general.gui_hide := 0, LLK_Overlay("show")
		If IsObject(area := vars.snipping_tool.coords_area)
		&& LLK_IsBetween(area.x, coords.x, coords.x + coords.w) && LLK_IsBetween(area.y, coords.y, coords.y + coords.h)
		&& LLK_IsBetween(area.x + area.w, coords.x, coords.x + coords.w) && LLK_IsBetween(area.y + area.h, coords.y, coords.y + coords.h)
			pClip := Gdip_CloneBitmapArea(pBitmap, area.x - coords.x, area.y - coords.y, area.w, area.h,, 1)
		Else LLK_ToolTip(LangTrans("global_screencap") "`n" LangTrans("global_fail"), 2,,,, "red", settings.general.fSize,,, 1)
		Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap), vars.snipping_tool.GUI := 0
	}
	Return pClip
}

Screenchecks_ImageSearch(name := "") ;performing image screen-checks: use parameter to perform a specific check, leave blank to go through every check
{
	local
	global vars, settings

	For key, val in vars.imagesearch.search
		vars.imagesearch[val].check := 0 ;reset results for all checks
	check := 0
	For index, val in ["betrayal", "leveltracker", "necropolis", "maptracker"]
		check += (val = "maptracker") ? settings.features.maptracker * settings.maptracker.loot : settings.features[val]
	If !check
		Return

	pHaystack := Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1) ;take screenshot from client
	For index, val in vars.imagesearch.search
	{
		If name ;if parameter was passed to function, override val
			val := name

		If (val != name) && ((settings.features[val] = 0) || InStr(val, "necro_") && !settings.features.necropolis || (val = "skilltree" && !settings.features.leveltracker) || (val = "stash" && (!settings.features.maptracker || !settings.maptracker.loot)))
			continue ;skip check if the connected feature is not enabled

		If InStr(A_Gui, "settings_menu") ;when testing a screen-check via the settings, check the whole screenshot
			x1 := 0, y1 := 0, x2 := 0, y2 := 0, settings_menu := 1
		Else If !vars.imagesearch[val].x1 || !FileExist("img\Recognition (" vars.client.h "p)\GUI\" val ".bmp") ;skip check if reference-image or coordinates are missing
			continue
		Else If (val = "necro_lantern")
			x1 := settings.general.oGamescreen + vars.client.w // 2 - Round(vars.client.h * 0.215), y1 := 0, x2 := settings.general.oGamescreen + vars.client.w//2 + Round(vars.client.h * 0.215), y2 := vars.client.h // 2
		Else x1 := vars.imagesearch[val].x1, y1 := vars.imagesearch[val].y1, x2 := vars.imagesearch[val].x2, y2 := vars.imagesearch[val].y2

		pNeedle := Gdip_CreateBitmapFromFile("img\Recognition (" vars.client.h "p)\GUI\" val ".bmp") ;load the reference image
		If (Gdip_ImageSearch(pHaystack, pNeedle, LIST, x1, y1, x2, y2, vars.imagesearch.variation,, 1, 1) > 0) ;search within the screenshot
		{
			Gdip_GetImageDimension(pNeedle, width, height)
			vars.imagesearch[val].check := 1, vars.imagesearch[val].found := StrSplit(LIST, ",")
			vars.imagesearch[val].found.1 -= settings.general.oGamescreen, vars.imagesearch[val].found.3 := width, vars.imagesearch[val].found.4 := height
			If (!InStr(val, "necro") || settings_menu) && (SubStr(LIST, 1, InStr(LIST, ",") - 1) != vars.imagesearch[val].x1 || SubStr(LIST, InStr(LIST, ",") + 1) != vars.imagesearch[val].y1) ;if the coordinates are different from those saved in the ini, update them
			{
				coords := LIST "," SubStr(LIST, 1, InStr(LIST, ",") - 1) + Format("{:0.0f}", width) "," SubStr(LIST, InStr(LIST, ",") + 1) + Format("{:0.0f}", height)
				IniWrite, % coords, % "ini\screen checks ("vars.client.h "p).ini", % val, last coordinates
				Loop, Parse, coords, `,
				{
					If (A_Index = 1)
						vars.imagesearch[val].x1 := A_LoopField
					Else If (A_Index = 2)
						vars.imagesearch[val].y1 := A_LoopField
					Else If (A_Index = 3)
						vars.imagesearch[val].x2 := A_LoopField
					Else vars.imagesearch[val].y2 := A_LoopField
				}
			}
			Gdip_DisposeImage(pNeedle)
			If (val != "necro_lantern") ;for the necropolis lantern, don't dispose of the image but make a copy of the pointer
				Gdip_DisposeImage(pHaystack)
			Else vars.imagesearch[val].pHaystack := pHaystack
			Return 1
		}
		Else Gdip_DisposeImage(pNeedle)
		If name
			break
	}
	Gdip_DisposeImage(pHaystack)
	Return 0
}

Screenchecks_Info(name) ;holding the <info> button to view instructions
{
	local
	global vars, settings

	If !IsObject(vars.help.screenchecks[name])
		Return

	Gui, screencheck_info: New, -Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border +E0x20 +E0x02000000 +E0x00080000 HWNDscreencheck_info
	Gui, screencheck_info: Color, 202020
	Gui, screencheck_info: Margin, % settings.general.fWidth/2, % settings.general.fWidth/2
	Gui, screencheck_info: Font, % "s"settings.general.fSize - 2 " cWhite", % vars.system.font
	vars.hwnd.screencheck_info := {"main": screencheck_info}

	If FileExist("img\GUI\screen-checks\"name ".jpg")
	{
		pBitmap0 := Gdip_CreateBitmapFromFile("img\GUI\screen-checks\" name ".jpg"), pBitmap := Gdip_ResizeBitmap(pBitmap0, vars.settings.w - settings.general.fWidth - 1, 10000, 1, 7, 1), Gdip_DisposeImage(pBitmap0)
		hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap), Gdip_DisposeImage(pBitmap)
		Gui, screencheck_info: Add, Pic, % "Section w"vars.settings.w - settings.general.fWidth - 1 " h-1", HBitmap:*%hBitmap%
		DeleteObject(hBitmap)
	}

	For index, text in vars.help.screenchecks[name]
	{
		font := InStr(text, "(/bold)") ? "bold" : "", font .= InStr(text, "(/underline)") ? (font ? " " : "") "underline" : "", font := !font ? "norm" : font
		text := StrReplace(StrReplace(text, "(/bold)"), "(/underline)")
		Gui, screencheck_info: Font, % font
		Gui, screencheck_info: Add, Text, % (A_Index = 1 ? "Section " : "xs y+0 ") "w"vars.settings.w - settings.general.fWidth - 1, % text
	}

	Gui, screencheck_info: Show, NA x10000 y10000
	WinGetPos, x, y, w, h, ahk_id %screencheck_info%
	xPos := vars.settings.x, yPos := (vars.settings.y + h > vars.monitor.y + vars.monitor.h) ? vars.monitor.y + vars.monitor.h - h : vars.settings.y
	Gui, screencheck_info: Show, % "NA x"xPos " y"yPos
	KeyWait, LButton
	Gui, screencheck_info: Destroy
}

Screenchecks_PixelRecalibrate(name) ;recalibrating a pixel-check
{
	local
	global vars, settings

	Switch name
	{
		Case "gamescreen":
			loopcount := 1
		Case "inventory":
			loopcount := 3
	}
	Loop %loopcount%
	{
		PixelGetColor, parse, % vars.client.x + vars.client.w - 1 - vars.pixelsearch[name]["x" A_Index], % vars.client.y + vars.pixelsearch[name]["y" A_Index], RGB
		vars.pixelsearch[name]["color" A_Index] := parse
		IniWrite, % parse, % "ini\screen checks ("vars.client.h "p).ini", %name%, color %A_Index%
	}
}

Screenchecks_PixelSearch(name) ;performing pixel-checks
{
	local
	global vars, settings

	pixel_check := 1
	Switch name
	{
		Case "gamescreen":
			loopcount := 1
		Case "inventory":
			loopcount := 3
	}

	Loop %loopcount%
	{
		If (vars.pixelsearch[name]["color" A_Index] = "ERROR") || Blank(vars.pixelsearch[name]["color" A_Index])
		{
			pixel_check := 0
			break
		}

		PixelSearch, x, y, vars.client.x + vars.client.w - 1 - vars.pixelsearch[name]["x" A_Index], vars.client.y + vars.pixelsearch[name]["y" A_Index], vars.client.x + vars.client.w - 1 - vars.pixelsearch[name]["x" A_Index]
		, vars.client.y + vars.pixelsearch[name]["y" A_Index], % vars.pixelsearch[name]["color" A_Index], % vars.pixelsearch.variation, Fast RGB
		pixel_check -= ErrorLevel
		If !pixel_check
			break
	}
	vars.pixelsearch[name].check := pixel_check ? 1 : 0 ;global variable that is checked in the main loop
	Return vars.pixelsearch[name].check
}
