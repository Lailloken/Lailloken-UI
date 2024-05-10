Init_stash(refresh := 0)
{
	local
	global vars, settings, db, Json

	settings.features.stash := LLK_IniRead("ini\config.ini", "features", "enable stash-ninja", 0)
	If IsObject(settings.stash)
		backup := settings.stash.Clone()
	settings.stash := {"fSize": LLK_IniRead("ini\stash-ninja.ini", "settings", "font-size", settings.general.fSize)}
	settings.stash.fSize2 := settings.stash.fSize - 3
	settings.stash.league := LLK_IniRead("ini\stash-ninja.ini", "settings", "league", "Necropolis")
	LLK_FontDimensions(settings.stash.fSize, height, width), LLK_FontDimensions(settings.stash.fSize2, height2, width2)
	settings.stash.fWidth := width, settings.stash.fHeight := height, settings.stash.fWidth2 := width2, settings.stash.fHeight2 := height2
	settings.stash.colors := [LLK_IniRead("ini\stash-ninja.ini", "UI", "text color", "000000"), LLK_IniRead("ini\stash-ninja.ini", "UI", "background color", "00FF00")]

	If !IsObject(vars.stash) || refresh
	{
		width := Floor(vars.client.h * (37/60)), height := vars.client.h
		If !refresh
			vars.stash := {"checks": {"delve": [Floor(width//2 - height * 0.1), Floor(height * (2/3)), width//4, height//36]
			, "fragments": [width//8 - height//20, height//7, height//10, height//80]
			, "scarabs": [Floor(width * (3/8) - height//20), height//7, height//10, height//80]
			, "breach": [Floor(width * (5/8) - height//20), height//7, height//10, height//80]
			;, "eldritch": [Floor(width * (7/8) - height//20), height//7, height//10, height//80]
			, "currency1": []
			, "currency2": []}
			, "width": width}
		json_data := Json.Load(LLK_FileRead("data\global\[stash-ninja] tabs.json")), dBox := vars.client.h//30
		For tab, array in json_data
		{
			vars.stash[tab] := {}, gap := LLK_IniRead("ini\stash-ninja.ini", tab, "gap", 2)
			For index, array1 in array
			{
				If (SubStr(array1.3, 1, 3) = "of ")
					name := name0 " " array1.3
				Else name0 := name := array1.3
				xCoord := array1.1 ? Floor((array1.1 / 1440) * vars.client.h) : xCoord + dBox + gap * (tab = "scarabs" && index > 102 ? 2 : 1)
				yCoord := array1.2 ? Floor((array1.2 / 1440) * vars.client.h) : yCoord
				vars.stash[tab][name] := {"coords": [xCoord, yCoord], "prices": StrSplit(LLK_IniRead("data\global\[stash-ninja] prices.ini", tab, name, "0, 0, 0"), ",", A_Space, 3)}
			}
		}
	}

	dLimits := {"scarabs": [[0.5, "", 3], [0.25, 0.5, 3], [10, 30, 1], [1, 10, 1], ["", 1, 1]]}
	For tab in vars.stash.checks
		If (tab = "scarabs")
		{
			settings.stash[tab] := {"gap": LLK_IniRead("ini\stash-ninja.ini", tab, "gap", 2), "limits": [], "profile": !backup[tab].profile ? 1 : backup[tab].profile}
			Loop 5
			{
				ini1 := ((check := LLK_IniRead("ini\stash-ninja.ini", tab, "limit " A_Index " bot", dLimits[tab][A_Index].1)) = "null") ? "" : check
				ini2 := ((check := LLK_IniRead("ini\stash-ninja.ini", tab, "limit " A_Index " top", dLimits[tab][A_Index].2)) = "null") ? "" : check
				ini3 := ((check := LLK_IniRead("ini\stash-ninja.ini", tab, "limit " A_Index " cur", dLimits[tab][A_Index].3)) = "null") ? "" : check
				settings.stash[tab].limits.Push([ini1, ini2, ini3])
			}
		}
}

Stash_(mode, test := 0)
{
	local
	global vars, settings
	static toggle := 0

	tab := (mode = "refresh") ? vars.stash.active : mode

	/*
	Else
	{
		For check in vars.stash.checks
			If FileExist("img\Recognition (" vars.client.h "p)\Stash-Ninja\" check ".bmp")
			{
				file_check := 1
				Break
			}
	
		If !file_check
			Return
	
		pBitmap := Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1)
		If settings.general.blackbars
			Bitmap_copy := Gdip_CloneBitmapArea(pBitmap, vars.client.x, 0, vars.client.w, vars.client.h,, 1), Gdip_DisposeImage(pBitmap), pBitmap := Bitmap_copy
	
		For check, array in vars.stash.checks
		{
			If !FileExist("img\Recognition (" vars.client.h "p)\Stash-Ninja\" check ".bmp")
				Continue
			pNeedle := Gdip_CreateBitmapFromFile("img\Recognition (" vars.client.h "p)\Stash-Ninja\" check ".bmp")
			result := Gdip_ImageSearch(pBitmap, pNeedle, LIST, array.1, array.2, array.1 + array.3, array.2 + array.4, vars.imagesearch.variation), Gdip_DisposeImage(pNeedle)
			If (result > 0)
			{
				tab := check
				Break
			}
		}

		Gdip_DisposeImage(pBitmap)
		If !tab
			Return
	}
	*/

	toggle := !toggle, GUI_name := "stash_ninja" toggle, vars.stash.active := tab, now := A_Now
	timestamp := LLK_IniRead("data\global\[stash-ninja] prices.ini", tab, "timestamp"), league := LLK_IniRead("data\global\[stash-ninja] prices.ini", tab, "league")
	EnvSub, now, timestamp, Minutes
	If (league != settings.stash.league) || Blank(timestamp) || Blank(now) || (now >= 31)
	{
		check := Stash_PriceFetch()
		vars.tooltip[vars.hwnd["tooltipstashprices"]] := A_TickCount
		If !check && !(InStr(LLK_IniRead("data\global\[stash-ninja] prices.ini", tab), "`n",,, 3) || league = settings.stash.league)
		{
			MsgBox, % LangTrans("stash_updateerror")
			Return -1
		}
		Else If !check
		{
			LLK_ToolTip(LangTrans("stash_updateerror", 2), 2,,,, "red"), now := A_Now
			EnvAdd, now, -20, Minutes
			IniWrite, % now, data\global\[stash-ninja] prices.ini, % tab, timestamp
		}
	}

	Gui, %GUI_name%: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x20 +E0x02000000 +E0x00080000 HWNDhwnd_stash"
	Gui, %GUI_name%: Font, % "s" settings.stash.fSize2 " cWhite", % vars.system.font
	Gui, %GUI_name%: Color, Purple
	WinSet, TransColor, Purple
	Gui, %GUI_name%: Margin, 0, 0
	If test
		settings.stash[tab].profile := 0
	Else If !settings.stash[tab].profile
		settings.stash[tab].profile := 1
	hwnd_old := vars.hwnd.stash.main, vars.hwnd.stash := {"main": hwnd_stash, "GUI_name": GUI_name}, vars.stash.box := dBox := vars.client.h//30, profile := settings.stash[tab].profile
	lBot := settings.stash[tab].limits[profile].1, lTop := settings.stash[tab].limits[profile].2, lType := settings.stash[tab].limits[profile].3
	lBot := Blank(lBot) ? 0 : lBot, lTop := Blank(lTop) ? 999999 : lTop
	count := added := 0, width := Floor(vars.client.h * (37/60)), height := vars.client.h, currencies := ["chaos", "exalt", "divine"], vars.stash.wait := 1, vars.stash.enter := 0

	For item, val in vars.stash[tab]
		If !Blank(lType) && LLK_IsBetween(val.prices[lType], lBot, lTop) || test ;|| (item = vars.stash.hover)
		{
			colors := settings.stash.colors.Clone(), hidden := (vars.stash.hover && item != vars.stash.hover) ? 1 : 0
			Gui, %GUI_name%: Add, Text, % "BackgroundTrans Border Right c" colors.1 " x" val.coords.1 " y" val.coords.2 + dBox - settings.stash.fHeight2 " w" dBox . (hidden ? " Hidden" : ""), % (test ? A_Index : val.prices[lType]) " "
			Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp HWNDhwnd Background" colors.2 . (hidden ? " Hidden" : ""), 0
			vars.hwnd.stash[item] := hwnd
			If (vars.stash.hover = item)
			{
				ControlGetPos, xAnchor, yAnchor, wAnchor, hAnchor,, ahk_id %hwnd%
				xAnchor += wAnchor
				Gui, %GUI_name%: Font, % "s" settings.stash.fSize
				For index, cType in ["chaos", "exalt", "divine"]
				{
					Gui, %GUI_name%: Add, Pic, % (index != 1 ? "xs " : "x+" settings.stash.fWidth " yp+" settings.stash.fWidth) " Section BackgroundTrans h" settings.stash.fHeight2 * 2 " w-1", % "img\GUI\" cType ".png"
					Gui, %GUI_name%: Add, Text, % "ys hp BackgroundTrans HWNDhwnd 0x200 x+" settings.stash.fWidth//2, % val.prices[index]
					ControlGetPos, xLast, yLast, wLast, hLast,, ahk_id %hwnd%
					wMax := (wLast > wMax) ? wLast : wMax
				}
				Gui, %GUI_name%: Add, Text, % "BackgroundTrans Border x" xAnchor " y" yAnchor " w" xLast + wMax - xAnchor + settings.stash.fWidth " h" yLast + hLast - yAnchor + settings.stash.fWidth, % " "
				Gui, %GUI_name%: Add, Progress, % "BackgroundBlack Disabled xp yp wp hp", 0
				Gui, %GUI_name%: Font, % "s" settings.stash.fSize2
			}
		}

	For outer in ["", ""]
		For index, limit in settings.stash[tab].limits
		{
			count += (outer = 1 && !Blank(limit.3)) ? 1 : 0
			If (outer = 1) || Blank(limit.3)
				Continue
			style := !added ? "x" width//2 - (count/2) * settings.stash.fWidth * 6 " y" vars.client.h * 0.8 - settings.stash.fWidth * 6 - settings.stash.fHeight : "ys"
			color1 := (index = profile) ? " c" settings.stash.colors.1 : ""
			color2 := (index = profile) ? settings.stash.colors.2 : "Black"
			Gui, %GUI_name%: Font, % "bold s" settings.stash.fSize
			Gui, %GUI_name%: Add, Text, % "Section " style " Center BackgroundTrans Border w" settings.stash.fWidth * 6 . color1, % index
			Gui, %GUI_name%: Add, Progress, % " Disabled cBlack xp yp wp hp Border BackgroundBlack c" color2, 100
			Gui, %GUI_name%: Add, Text, % "xs BackgroundTrans wp Center Border HWNDhwnd h" settings.stash.fWidth * 6, % " "
			ControlGetPos, x, y, w, h,, ahk_id %hwnd%
			Gui, %GUI_name%: Font, % "norm s" settings.stash.fSize2
			If !Blank(limit.2)
			{
				Gui, %GUI_name%: Add, Text, % "xp yp BackgroundTrans Border", % " " limit.2 " "
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp BackgroundBlack Disabled", 0
			}
			If !Blank(limit.1)
			{
				Gui, %GUI_name%: Add, Text, % "xp y" y + h - settings.stash.fheight2 " BackgroundTrans Border", % " " limit.1 " "
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp BackgroundBlack Disabled", 0
			}
			
			Gui, %GUI_name%: Add, Pic, % "xp y" y " BackgroundTrans w" w - 2 " h-1 Border", % "img\GUI\" currencies[limit.3] ".png"
			Gui, %GUI_name%: Add, Progress, % "BackgroundBlack Disabled cBlack xp yp wp hp Border", 100
			added += 1
		}

	Gui, %GUI_name%: Show, % "NA x" vars.client.x " y" vars.client.y
	LLK_Overlay(hwnd_stash, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
	vars.stash.GUI := 1, vars.stash.wait := 0
	Return 1
}

Stash_Calibrate(cHWND)
{
	local
	global vars, settings

	KeyWait, LButton
	KeyWait, RButton

	If (vars.system.click = 2)
	{
		If FileExist("img\Recognition (" vars.client.h "p)\Stash-Ninja\")
			Run, % "explore img\Recognition (" vars.client.h "p)\Stash-Ninja\"
		Return
	}
	check := LLK_HasVal(vars.hwnd.settings, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	If !InStr(check, "cal_")
		Return

	pBitmap := Gdip_BitmapFromHWND(vars.hwnd.poe_client, 1)
	If settings.general.blackbars
		Bitmap_copy := Gdip_CloneBitmapArea(pBitmap, vars.client.x, 0, vars.client.w, vars.client.h,, 1), Gdip_DisposeImage(pBitmap), pBitmap := Bitmap_copy
	checks := vars.stash.checks, Bitmap_copy := Gdip_CloneBitmapArea(pBitmap, checks[control].1, checks[control].2, checks[control].3, checks[control].4,, 1), Gdip_DisposeImage(pBitmap), pBitmap := Bitmap_copy
	Gdip_SaveBitmapToFile(pBitmap, "img\Recognition (" vars.client.h "p)\Stash-Ninja\" control ".bmp", 100), Gdip_DisposeImage(pBitmap)
	If FileExist("img\Recognition (" vars.client.h "p)\Stash-Ninja\" control ".bmp")
	{
		GuiControl, +cWhite, % cHWND
		GuiControl, movedraw, % cHWND
	}
}

Stash_Close()
{
	local
	global vars, settings

	LLK_Overlay(vars.hwnd.stash.main, "destroy")
	vars.stash.GUI := vars.stash.hover := vars.hwnd.stash.main := ""
}

Stash_Hotkeys()
{
	local
	global vars, settings
	static in_progress

	start := A_TickCount, hotkey := A_ThisHotkey, tab := vars.stash.active
	If vars.stash.wait || in_progress
		Return
	in_progress := 1
	Loop, Parse, % "~+!#*^"
		hotkey := StrReplace(hotkey, A_LoopField)

	If IsNumber(hotkey) && (hotkey < 6) && !Blank(settings.stash[tab].limits[hotkey]) && (hotkey != settings.stash[tab].profile)
		settings.stash[tab].profile := hotkey, Stash_("refresh")
	Else If !IsNumber(hotkey) && vars.stash.hover
	{
		LLK_Overlay(vars.hwnd.stash.main, "hide"), vars.stash.GUI := 0, vars.stash.enter := 1
		While vars.stash.enter
			Sleep 10
		LLK_Overlay(vars.hwnd.stash.main, "show")
		/*
		start := A_TickCount
		While GetKeyState(hotkey, "P")
			If (A_TickCount >= start + 300)
			{
				Clipboard := """note:"""
				SendInput, ^{f}^{v}{ENTER}
				KeyWait, % hotkey
				in_progress := 0
				Return
			}
		If (vars.general.wMouse != vars.hwnd.stash.main)
			SendInput, ^{LButton}
		Else
		{
			vars.stash.wait := 1
			Gui, % vars.hwnd.stash.GUI_name ": +E0x20"
			Sleep 100
			SendInput, ^{LButton}
			Gui, % vars.hwnd.stash.GUI_name ": -E0x20"
			Sleep 100
			vars.stash.wait := 0
		}
		*/
	}
	KeyWait, % hotkey
	in_progress := 0
}

Stash_PriceCheck(price)
{
	local
	global vars, settings

	If Blank(price)
		Return

	num := unit := "", valid := [["c", "ch", "chaos"], ["e", "ex", "exa", "exalt", "exalts"], ["d", "div", "divine", "divines"]]
	Loop, Parse, % StrReplace(price, " ")
		If IsNumber(A_LoopField) || InStr(",.<", A_LoopField) && !InStr(num, A_LoopField)
			num .= (A_LoopField = ",") ? "." : A_LoopField
		Else If LLK_IsType(A_LoopField, "alpha")
			unit .= A_LoopField
		Else Return

	If (SubStr(num, 1, 1) = ".") || (SubStr(num, 0) = ".")
		Return

	If IsNumber(StrReplace(num, "<")) && (StrReplace(num, "<") > 0) && (currency := LLK_HasVal(valid, unit,,,, 1))
		Return [num, currency]
}

Stash_PriceFetch()
{
	local
	global vars, settings, json

	types := {"scarabs": "Scarab"}
	vars.stash.active := "scarabs"
	tab := vars.stash.active, type := types[tab], league := StrReplace(settings.stash.league, " ", "+")
	LLK_ToolTip(LangTrans("stash_update"), 10000,,, "stashprices", "lime")
	UrlDownloadToFile, % "https://poe.ninja/api/data/itemoverview?league=" league "&type=" type, data\global\[stash-ninja] prices_temp.json
	If ErrorLevel || !FileExist("data\global\[stash-ninja] prices_temp.json")
		Return
	prices := Json.Load(LLK_FileRead("data\global\[stash-ninja] prices_temp.json"))
	If !prices.lines.Count()
		Return
	IniDelete, data\global\[stash-ninja] prices.ini, % tab
	ini_dump := "timestamp=" A_Now "`nleague=" settings.stash.league
	For index, val in prices.lines
	{
		name := LLK_StringCase(val.name), price := val.chaosvalue ", " val.exaltedvalue ", " val.divinevalue
		If settings.general.dev && !vars.stash[tab].HasKey(name)
			MsgBox, % name
		ini_dump .= "`n" name "=""" price """", vars.stash[tab][name].prices := StrSplit(price, ",", A_Space,3)
	}
	IniWrite, % ini_dump, data\global\[stash-ninja] prices.ini, % tab
	FileDelete, data\global\[stash-ninja] prices_temp.json
	Return 1
}
