Init_screenchecks()
{
	local
	global vars, settings

	settings.features.pixelchecks := LLK_IniRead("ini\config.ini", "Settings", "background pixel-checks", 1) ;reminder: keep it in config.ini (instead of screen checks.ini) because it's not resolution-specific
	vars.pixelsearch := {}, parse := LLK_IniRead("data\Resolutions.ini", vars.client.h "p", "gamescreen coordinates")
	If InStr(parse, ",")
		vars.pixelsearch.gamescreen := {"x1": SubStr(parse, 1, InStr(parse, ",") - 1), "y1": SubStr(parse, InStr(parse, ",") + 1)}
	
	vars.pixelsearch.gamescreen.color1 := LLK_IniRead("ini\screen checks (" vars.client.h "p).ini", "gamescreen", "color 1")
	vars.pixelsearch.gamescreen.check := 0
	
	vars.pixelsearch.inventory := {"x1": 0, "x2": 0, "x3": 6, "y1": 0, "y2": 6, "y3": 0, "check": 0}
	Loop 3
		vars.pixelsearch.inventory["color" A_Index] := LLK_IniRead("ini\screen checks (" vars.client.h "p).ini", "inventory", "color " A_Index)
	
	vars.pixelsearch.variation := 0, vars.pixelsearch.list := {"gamescreen": 1, "inventory": 1}
	vars.imagesearch := {}
	vars.imagesearch.search := ["skilltree", "betrayal"] ;this array is parsed when doing image-checks: order is important (place static checks in front for better performance)
	vars.imagesearch.list := {"betrayal": 1, "skilltree": 1, "stash": 0} ;this object is parsed when listing image-checks in the settings menu
	vars.imagesearch.variation := 15

	For key in vars.imagesearch.list
	{
		vars.imagesearch[key] := {"check": 0} ;set the result to 0 by default
		Loop, Parse, % LLK_IniRead("ini\screen checks (" vars.client.h "p).ini", key, "last coordinates"), `, ;coordinates are stored in ini-file like this: x,y,w,h
		{
			If (A_LoopField = "")
				continue
			If (A_Index = 1)
				vars.imagesearch[key].x1 := A_LoopField
			Else If (A_Index = 2)
				vars.imagesearch[key].y1 := A_LoopField
			Else If (A_Index = 3)
				vars.imagesearch[key].x2 := A_LoopField ;technically a misnomer but doesn't really matter (it's the width of the reference-image)
			Else vars.imagesearch[key].y2 := A_LoopField ;same (it's the height)
		}
	}
	
	If (vars.client.h0 / vars.client.w0 < (5/12)) ;if the client is running a resolution that's wider than 21:9, there is a potential for black bars on each side
		settings.general.blackbars := LLK_IniRead("ini\config.ini", "Settings", "black-bar compensation", 0) ;reminder: keep it in config.ini (instead of screen checks.ini) because it's not resolution-specific
	Else settings.general.blackbars := 0
	
	If settings.general.blackbars ;apply offsets if black-bar compensation is enabled
	{
		settings.general.oGamescreen := Format("{:0.0f}", (vars.client.w0 - (vars.client.h0 / (5/12))) / 2) ;get the width of the black bars (as an offset for pixel-checks)
		vars.client.x := vars.client.x0 + settings.general.oGamescreen, vars.client.w := vars.client.w0 - 2*settings.general.oGamescreen
	}
	Else settings.general.oGamescreen := 0
}

Screenchecks_ImageRecalibrate()
{
	local
	global vars, settings

	Clipboard := ""
	KeyWait, LButton
	vars.general.gui_hide := 1
	LLK_Overlay("hide")
	SendInput, #+{s}
	WinWaitActive, ahk_group snipping_tools,, 2
	WinWaitNotActive, ahk_group snipping_tools
	pClipboard := Gdip_CreateBitmapFromClipboard()
	If (pClipboard <= 0)
	{
		vars.general.gui_hide := 0
		LLK_Overlay(vars.hwnd.settings.main, "show", 0)
		WinWait, % "ahk_id " vars.hwnd.settings.main
		LLK_ToolTip("screen-cap failed",,,,, "red")
		Return
	}
	vars.general.gui_hide := 0
	WinWait, % "ahk_id " vars.hwnd.settings.main
	Return pClipboard
}

Screenchecks_ImageSearch(name := "") ;performing image screen-checks: use parameter to perform a specific check, leave blank to go through every check
{
	local
	global vars, settings

	For key, val in vars.imagesearch.search
		vars.imagesearch[val].check := 0 ;reset results for all checks

	pHaystack := Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1) ;take screenshot from client
	For key, val in vars.imagesearch.search
	{
		If name ;if parameter was passed to function, override val
			val := name
		
		If (val != name) && ((settings.features[val] = 0) || (val = "skilltree" && !settings.features.leveltracker) || (val = "stash" && (!settings.features.maptracker || !settings.maptracker.loot)))
			continue ;skip check if the connected feature is not enabled

		If (A_Gui = DummyGUI(vars.hwnd.settings.main)) && (val != "betrayal") ;when testing a screen-check via the settings, check the whole screenshot (unless it's betrayal)
			x1 := 0, y1 := 0, x2 := 0, y2 := 0
		Else If (val = "betrayal") ;scan a specific area for betrayal
			x1 := settings.general.oGamescreen, y1 := 0, x2 := vars.client.w/2 + settings.general.oGamescreen, y2 := vars.client.h/8
		Else If !vars.imagesearch[val].x1 || !FileExist("img\Recognition (" vars.client.h "p)\GUI\" val ".bmp") ;skip check if reference-image or coordinates are missing
			continue
		Else x1 := vars.imagesearch[val].x1, y1 := vars.imagesearch[val].y1, x2 := vars.imagesearch[val].x2, y2 := vars.imagesearch[val].y2
		
		pNeedle := Gdip_CreateBitmapFromFile("img\Recognition (" vars.client.h "p)\GUI\" val ".bmp") ;load the reference image
		If (Gdip_ImageSearch(pHaystack, pNeedle, LIST, x1, y1, x2, y2, vars.imagesearch.variation,, 1, 1) > 0) ;search within the screenshot
		{
			vars.imagesearch[val].check := 1 ;set the result to 1
			If (SubStr(LIST, 1, InStr(LIST, ",") - 1) != vars.imagesearch[val].x1) || (SubStr(LIST, InStr(LIST, ",") + 1) != vars.imagesearch[val].y1) ;if the coordinates are different from those saved in the ini, update them
			{
				Gdip_GetImageDimension(pNeedle, width, height)
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
			Gdip_DisposeImage(pHaystack)
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
	Gui, screencheck_info: Font, % "s"settings.general.fSize - 2 " cWhite", Fontin SmallCaps
	vars.hwnd.screencheck_info := {"main": screencheck_info}
	
	If FileExist("img\GUI\screen-checks\"name ".jpg")
	{
		img := 1
		Gui, screencheck_info: Add, Pic, % "Section w"vars.settings.w - settings.general.fWidth - 1 " h-1", % "img\GUI\screen-checks\"name ".jpg"
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
