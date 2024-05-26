Init_stash(refresh := 0)
{
	local
	global vars, settings, db, Json
	static json_data, exceptions := {"currency": ["reality fragment", "devouring fragment", "decaying fragment", "blazing fragment", "synthesising fragment", "cosmic fragment", "awakening fragment"
	, "blessing of chayula", "blessing of xoph", "blessing of uul-netol", "blessing of tul", "blessing of esh", "ritual vessel", "oil extractor"], "fragments": ["simulacrum", "simulacrum splinter"]}
	, dLimits := [[0.5, "", 3], [0.25, 0.5, 3], [10, 30, 1], [1, 10, 1], ["", 1, 1]], essences := ["whispering", "muttering", "weeping", "wailing", "screaming", "shrieking", "deafening"]

	If Blank(settings.features.stash)
		settings.features.stash := LLK_IniRead("ini\config.ini", "features", "enable stash-ninja", 0)
	If IsObject(settings.stash)
		backup := settings.stash.Clone()
	Else
	{
		settings.stash := {}, iSettings := IniBatchRead("ini\stash-ninja.ini", "settings"), iUI := IniBatchRead("ini\stash-ninja.ini", "UI")
		settings.stash.fSize := !Blank(check := iSettings["font-size"]) ? check : settings.general.fSize
		settings.stash.league := !Blank(check := iSettings["league"]) ? check : "Necropolis"
		settings.stash.history := !Blank(check := iSettings["enble price history"]) ? check : 1
		settings.stash.show_exalt := !Blank(check := iSettings["show exalt conversion"]) ? check : 0
		settings.stash.bulk_trade := !Blank(check := iSettings["show bulk-sale suggestions"]) ? check : 1
		settings.stash.min_trade := !Blank(check := iSettings["minimum trade value"]) ? check : ""
		settings.stash.autoprofiles := !Blank(check := iSettings["enable trade-value profiles"]) ? check : 0
		settings.stash.margins := !Blank(check := iSettings["margins"]) ? check : "0, 5, 10, 15, 20"
		settings.stash.colors := [!Blank(check := iUI["text color"]) ? check : "000000", !Blank(check1 := iUI["background color"]) ? check1 : "00FF00"]
	}
	settings.stash.fSize2 := settings.stash.fSize - 3, LLK_FontDimensions(settings.stash.fSize, height, width), LLK_FontDimensions(settings.stash.fSize2, height2, width2)
	settings.stash.fWidth := width, settings.stash.fHeight := height, settings.stash.fWidth2 := width2, settings.stash.fHeight2 := height2
	If (refresh = "font")
		Return

	width := Floor(vars.client.h * (37/60)), height := vars.client.h
	If !(oCheck := IsObject(vars.stash)) || (refresh = "bulk_trade")
	{
		If !oCheck
			vars.stash := {"currency": {}, "tabs": {"delve": [20, Round(height * (1/80))], "essences": [24, 4], "fragments": [24, Round(height * (1/72))], "scarabs": [30, 2]
			, "breach": [20, Round(height * (1/80))], "currency1": [24, Round(height * (1/90))], "currency2": [24, Round(height * (1/90))], "blight": [24, Round(height * (1/60))]
			, "delirium": [20, Round(height * (1/72))], "ultimatum": [20, Round(height * (1/90))]}
			, "width": width, "buttons": Round(height * (1/36)), "exalt": StrSplit(LLK_IniRead("data\global\[stash-ninja] prices.ini", "currency", "exalted orb", "0"), ",", A_Space, 3).1
			, "divine": StrSplit(LLK_IniRead("data\global\[stash-ninja] prices.ini", "currency", "divine orb", "0"), ",", A_Space, 3).1}
			, json_data := Json.Load(LLK_FileRead("data\global\[stash-ninja] tabs.json"))
		For tab, array in json_data
		{
			If !oCheck
				iTab := IniBatchRead("ini\stash-ninja.ini", tab), settings.stash[tab] := {"gap": !Blank(check := iTab.gap) ? check : vars.stash.tabs[tab].2, "limits0": [], "limits": [], "profile": Blank(check1 := backup[tab].profile) ? 1 : check1, "margin": !Blank(check2 := iTab.margin) ? check2 : 0
				, "in_folder": !Blank(check3 := iTab["tab is in folder"]) ? check3 : 0}, iLimits := IniBatchRead("ini\stash-ninja.ini", tab), vars.stash[tab] := {}
			Loop 5
			{
				If !oCheck
				{
					ini1 := !Blank(check := iLimits["limit " A_Index " bot"]) ? (check = "null" ? "" : check) : dLimits[A_Index].1
					ini2 := !Blank(check := iLimits["limit " A_Index " top"]) ? (check = "null" ? "" : check) : dLimits[A_Index].2
					ini3 := !Blank(check := iLimits["limit " A_Index " cur"]) ? (check = "null" ? "" : check) : dLimits[A_Index].3
					settings.stash[tab].limits0[A_Index] := [ini1, ini2, ini3]
				}
				settings.stash[tab].limits[A_Index] := settings.stash[tab].limits0[A_Index].Clone()
				If (A_Index < 5) && settings.stash.bulk_trade && settings.stash.min_trade && settings.stash.autoprofiles
				{
					max := (A_Index = 1) ? "" : (A_Index = 2) ? settings.stash.min_trade - 0.01 : min - 0.01
					min := Round(settings.stash.min_trade / A_Index, 2)
					settings.stash[tab].limits[A_Index] := [min, max ? Round(max, 2) : "", 1]
				}
			}
		}
	}

	If !oCheck
	{
		For tab in json_data
			If !InStr("currency2, breach", tab)
				tab := InStr(tab, "currency") ? "currency" : tab, i%tab% := IniBatchRead("data\global\[stash-ninja] prices.ini", tab)
				, vars.stash[tab].timestamp := i%tab%.timestamp, vars.stash[tab].league := i%tab%.league
	}
	tabs := vars.stash.tabs
	For tab, array in json_data
	{
		gap := settings.stash[tab].gap, vars.stash[tab].box := dBox := vars.client.h//tabs[tab].1, in_folder := settings.stash[tab].in_folder
		For index, array1 in array
		{
			If (tab = "scarabs" && SubStr(array1.3, 1, 3) = "of ")
				name := name0 " " array1.3
			Else If (tab = "essences")
				name := IsNumber(SubStr(array1.3, 1, 1)) ? StrReplace(array1.3, SubStr(array1.3, 1, 1), essences[SubStr(array1.3, 1, 1)] " essence of") : array1.3
			Else If (tab = "blight")
				name := array1.3 . (!InStr(array1.3, "extractor") ? " oil" : "")
			Else If (tab = "delirium")
				name := array1.3 . (!InStr(array1.3, "simulacrum") ? " delirium orb" : "")
			Else If (tab = "ultimatum")
				name := array1.3 " catalyst"
			Else name0 := name := array1.3 (tab = "delve" && !InStr(array1.3, "resonator") ? " fossil" : "")
			exception1 := LLK_PatternMatch(name, "", ["potent", "powerful", "prime"]) ? 1 : 0, exception2 := LLK_PatternMatch(name, "", ["prime"]) ? 1 : 0
			xCoord := array1.1 ? Floor((array1.1 / 1440) * vars.client.h) : xCoord + (exception2 ? vars.client.h * (1/12) : dBox) + gap * (tab = "scarabs" && index > 105 ? 2 : 1)
			yCoord := array1.2 ? Floor(((array1.2 + (in_folder ? 47 : 0)) / 1440) * vars.client.h) : yCoord
			tab0 := (check := LLK_HasVal(exceptions, name,,,, 1)) ? check : (tab = "breach") ? "fragments" : InStr(tab, "currency") || (tab = "ultimatum") ? "currency" : tab
			prices := IsObject(vars.stash[tab][name].prices) ? vars.stash[tab][name].prices.Clone() : StrSplit(!Blank(check := i%tab0%[name]) ? check : "0, 0, 0", ",", A_Space, 3)
			trend := IsObject(vars.stash[tab][name].trend) ? vars.stash[tab][name].trend.Clone() : StrSplit(!Blank(check := i%tab0%[name "_trend"]) ? check : "0, 0, 0, 0, 0, 0, 0", ",", A_Space)
			vars.stash[tab][name] := {"coords": [xCoord, yCoord], "prices": prices, "trend": trend}
		}
	}
	vars.stash.currency1["chaos orb"].prices := [1, 1/vars.stash.exalt, 1/vars.stash.divine]
	If (refresh = "bulk_trade") && WinExist("ahk_id " vars.hwnd.stash.main)
		Stash_("refresh")
}

Stash_(mode, test := 0)
{
	local
	global vars, settings
	static toggle := 0

	toggle := !toggle, GUI_name := "stash_ninja" toggle
	Loop, % (mode = "delirium" || vars.stash.active = "delirium") ? 3 : 2
	{
		If (A_Index = 2) && (mode = "ultimatum" || vars.stash.active = "ultimatum")
			Continue
		tab := (A_Index = 1 || InStr(mode, "currency") ? "currency" : (mode = "refresh") ? (InStr(vars.stash.active, "currency") ? "currency" : vars.stash.active) : mode)
		tab := (tab = "breach" || A_Index = 3) ? "fragments" : tab, now := A_Now, timestamp := vars.stash[tab].timestamp, league := vars.stash[tab].league
		EnvSub, now, timestamp, Minutes
		If (league != settings.stash.league) || Blank(timestamp) || Blank(now) || (now >= 31)
		{
			If !tooltip
				LLK_ToolTip(LangTrans("stash_update"), 10000,,, "stashprices", "lime")
			check := Stash_PriceFetch(tab), tooltip := 1
			If !check
			{
				LLK_ToolTip(LangTrans("stash_updateerror", 2), 2,,,, "red"), now := A_Now
				EnvAdd, now, -20, Minutes
				IniWrite, % now, data\global\[stash-ninja] prices.ini, % tab, timestamp
				vars.stash[tab].timestamp := now
			}
		}
	}
	If !Blank(check)
		vars.tooltip[vars.hwnd["tooltipstashprices"]] := A_TickCount

	Gui, %GUI_name%: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x20 +E0x02000000 +E0x00080000 HWNDhwnd_stash"
	Gui, %GUI_name%: Font, % "s" settings.stash.fSize2 " cWhite", % vars.system.font
	Gui, %GUI_name%: Color, Purple
	WinSet, TransColor, Purple
	Gui, %GUI_name%: Margin, 0, 0
	tab := (mode = "refresh") ? vars.stash.active : mode, profile := settings.stash[tab].profile, vars.stash.active := tab

	If test
		settings.stash[tab].profile := profile := "test"
	Else If Blank(settings.stash[tab].limits[settings.stash[tab].profile].3)
		Loop 5
			If !Blank(settings.stash[tab].limits[A_Index].3)
			{
				settings.stash[tab].profile := profile := A_Index
				Break
			}
	hwnd_old := vars.hwnd.stash.main, vars.hwnd.stash := {"main": hwnd_stash, "GUI_name": GUI_name}, dBox := vars.stash[tab].box, dButtons := vars.stash.buttons
	lBot := settings.stash[tab].limits[profile].1, lTop := settings.stash[tab].limits[profile].2, lType := settings.stash[tab].limits[profile].3
	lBot := Blank(lBot) ? (lType = 4) ? -999 : 0 : lBot, lTop := Blank(lTop) ? 999999 : lTop
	count := added := 0, width := Floor(vars.client.h * (37/60)), height := vars.client.h, currencies := ["chaos", "exalt", "divine", "percent"], vars.stash.wait := 1, vars.stash.enter := 0

	For item, val in vars.stash[tab]
		If IsObject(val) && (!Blank(lType) && LLK_IsBetween((lType = 4) ? val.trend[val.trend.MaxIndex()] : Round(val.prices[lType], 2), lBot, lTop) || test || InStr(item, "tab_")) ;|| (item = vars.stash.hover)
		{
			colors := settings.stash.colors.Clone(), hidden := (vars.stash.hover && item != vars.stash.hover && !InStr(vars.stash.hover, "tab_")) ? 1 : 0
			If InStr(item, "tab_")
			{
				button := SubStr(item, InStr(item, "_") + 1)
				Gui, %GUI_name%: Add, Text, % "BackgroundTrans Border x" val.coords.1 + 4 " y" val.coords.2 + 4 " w" dButtons * 4.5 - 8 " h" dButtons - 8 . (hidden ? " Hidden" : "")
				Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp HWNDhwnd BackgroundPurple" . (hidden ? " Hidden" : ""), 0
				Gui, %GUI_name%: Add, Text, % "BackgroundTrans Border x" val.coords.1 " y" val.coords.2 " w" dButtons * 4.5 " h" dButtons . (hidden ? " Hidden" : "")
				Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp HWNDhwnd Background" (button = tab ? colors.2 : "Black") . (hidden ? " Hidden" : ""), 0
			}
			Else
			{
				price := Round(val.prices[lType], (val.prices[lType] > 1000) ? 0 : (val.prices[lType] > 100) ? 1 : 2)
				exception1 := LLK_PatternMatch(item, "", ["potent", "powerful", "prime"]) ? 1 : 0, exception2 := LLK_PatternMatch(item, "", ["powerful", "prime"]) ? 1 : 0
				Gui, %GUI_name%: Add, Text, % "BackgroundTrans Border Right c" colors.1 " x" val.coords.1 " y" val.coords.2 + (exception1 ? vars.client.h * (1/12) : dBox) - settings.stash.fHeight2
				. " w" (exception2 ? vars.client.h * (1/12) : dBox) . (hidden ? " Hidden" : ""), % (test ? A_Index : (lType = 4) ? val.trend[val.trend.MaxIndex()] : price) " "
				Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp HWNDhwnd Background" colors.2 . (hidden ? " Hidden" : ""), 0
				vars.hwnd.stash[item] := hwnd
				If (vars.stash.hover = item)
				{
					ControlGetPos, xAnchor, yAnchor, wAnchor, hAnchor,, ahk_id %hwnd%
					xAnchor += wAnchor, Stash_PriceInfo(GUI_name, xAnchor, yAnchor, item, val)
				}
			}
		}

	For outer in ["", ""]
		For index, limit in settings.stash[tab].limits
		{
			count += (outer = 1 && !Blank(limit.3)) ? 1 : 0
			If (outer = 1) || Blank(limit.3)
				Continue
			style := !added ? "x" width//2 - (count/2) * settings.stash.fWidth * 6 " y" vars.client.h * 0.8 - settings.stash.fWidth * 6 - settings.stash.fHeight : "ys"
			color1 := (index = profile) ? " c" settings.stash.colors.1 : "", color2 := (index = profile) ? settings.stash.colors.2 : "Black"
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
	If (mode != "refresh") && WinExist("ahk_id " vars.hwnd.settings.main) && (vars.settings.active = "stash-ninja")
		vars.settings.selected_tab := tab, Settings_menu("stash-ninja")
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
	tabs := vars.stash.tabs, Bitmap_copy := Gdip_CloneBitmapArea(pBitmap, tabs[control].1, tabs[control].2, tabs[control].3, tabs[control].4,, 1), Gdip_DisposeImage(pBitmap), pBitmap := Bitmap_copy
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
	vars.stash.GUI := vars.stash.hover := vars.hwnd.stash.main := "", vars.settings.selected_tab := ""
	If WinExist("ahk_id " vars.hwnd.settings.main) && (vars.settings.active = "stash-ninja")
		Settings_menu("stash-ninja")
}

Stash_Hotkeys()
{
	local
	global vars, settings
	static in_progress

	hotkey := A_ThisHotkey, tab := vars.stash.active
	If vars.stash.wait || in_progress
		Return
	in_progress := 1
	Loop, Parse, % "~+!#*^"
		hotkey := StrReplace(hotkey, A_LoopField)

	If IsNumber(hotkey) && !Blank(settings.stash[tab].limits[hotkey].3) && (hotkey != settings.stash[tab].profile)
		settings.stash[tab].profile := hotkey, Stash_("refresh")
	Else If InStr(hotkey, "Button") && vars.stash.hover
	{
		Clipboard := ""
		SendInput, ^{c}
		ClipWait, 0.05
		If !Clipboard || InStr(hotkey, "LButton") && (InStr(Clipboard, LangTrans("items_stack") " 1/") || !InStr(Clipboard, LangTrans("items_stack")))
		{
			in_progress := 0
			Return
		}
		If settings.stash.bulk_trade && InStr(hotkey, "RButton") && vars.stash[vars.stash.active][vars.stash.hover].prices.1
			Stash_PricePicker()
		LLK_Overlay(vars.hwnd.stash.main, "hide"), vars.stash.GUI := 0, vars.stash.enter := 1
		While vars.stash.enter
			Sleep 10
		LLK_Overlay(vars.hwnd.stash.main, "show")
	}
	KeyWait, % hotkey
	in_progress := 0
}

Stash_PriceFetch(tab)
{
	local
	global vars, settings, json
	static types := {"fragments": ["Fragment"], "scarabs": ["Scarab"], "currency": ["Currency"], "delve": ["Fossil", "Resonator"], "essences": ["Essence"], "blight": ["Oil"], "delirium": ["DeliriumOrb"]}

	Loop, % (tab = "delve") ? 2 : 1
	{
		tab := InStr(tab, "currency") ? "currency" : tab, type := types[tab][A_Index], league := StrReplace(settings.stash.league, " ", "+"), outer := A_Index
		data_type := (InStr("fragments,currency", tab) ? "currency" : "item") "overview"
		UrlDownloadToFile, % "https://poe.ninja/api/data/" data_type "?league=" league "&type=" type, data\global\[stash-ninja] prices_temp.json
		If ErrorLevel || !FileExist("data\global\[stash-ninja] prices_temp.json")
			Return 0
		prices := Json.Load(LLK_FileRead("data\global\[stash-ninja] prices_temp.json")), ini_dump := "timestamp=" A_Now "`nleague=" settings.stash.league
		If !prices.lines.Count()
			Return 0
		If (A_Index = 1)
			IniDelete, data\global\[stash-ninja] prices.ini, % tab
		If (tab = "currency")
			For index, val in prices.lines
				If (val.currencytypename = "exalted orb")
					vars.stash.exalt := val.chaosequivalent
				Else If (val.currencytypename = "divine orb")
					vars.stash.divine := val.chaosequivalent

		For index, val in prices.lines
		{
			name := LLK_StringCase(val[InStr(data_type, "item") ? "name" : "currencytypename"]), price0 := val["chaos" (InStr(data_type, "item") ? "value" : "equivalent")]
			price := price0 ", " price0 / vars.stash.exalt ", " price0 / vars.stash.divine, trend := ""
			For iTrend, vTrend in val[(InStr(data_type, "item") ? "" : "receive") "sparkline"].data
				trend .= (Blank(trend) ? "" : ", ") . (IsNumber(vTrend) ? vTrend : 0)
			If (outer = 2)
			{
				IniWrite, % """" price """", data\global\[stash-ninja] prices.ini, % tab, % name
				If !Blank(trend)
					IniWrite, % """" trend """", data\global\[stash-ninja] prices.ini, % tab, % name "_trend"
			}
			Else ini_dump .= "`n" name "=""" price """", ini_dump .= !Blank(trend) ? "`n" name "_trend=""" trend """" : ""
			If (check := LLK_HasKey(vars.stash, name,,,, 1))
				vars.stash[check][name].prices := StrSplit(price, ",", A_Space, 3), vars.stash[check][name].trend := Blank(trend) ? [0, 0, 0, 0, 0, 0, 0] : StrSplit(trend, ",", A_Space, 7)
		}
		If (A_Index = 1)
		{
			IniWrite, % ini_dump, data\global\[stash-ninja] prices.ini, % tab
			vars.stash[tab].timestamp := A_Now, vars.stash[tab].league := settings.stash.league
		}
		FileDelete, data\global\[stash-ninja] prices_temp.json
	}
	Return 1
}

Stash_PriceHistory(gui_name, x, y, h, wSlice, data, ByRef min_max)
{
	local
	global vars, settings

	If !IsObject(data) || Blank(x . h . wSlice) || !IsNumber(x + h + wSlice)
		Return 0
	For index, percent in data
		max_percent := (Abs(percent) > max_percent) ? Abs(percent) : max_percent
	hScaled := (h//2) / Max(max_percent, 1)
	yLine1 := y + h//2 - 1, yLine2 := y + h//2 + 1, min_max := [0, 0, 0]
	Gui, %gui_name%: Add, Progress, % "BackgroundWhite x" x " y" yLine1 " w" data.Count() * wSlice " h2", 0
	For index, percent in data
	{
		style := (index = 1 ? "x" x : "x+0") " Disabled Vertical HWNDhwnd Background" (index = data.MaxIndex() ? "B266FF" : (percent >= 0 ? "Lime" : "Red")), y := !percent ? h//2 : (percent < 0 ? yLine2 : yLine1 + 1 - Abs(percent) * hScaled)
		Gui, %gui_name%: Add, Progress, % style " y" y " w" wSlice " h" Abs(percent) * hScaled, 0
		ControlGetPos, xControl, yControl, wControl, hControl,, ahk_id %hwnd%
		xControl -= x, min_max.2 := percent
		If (percent > 0)
			min_max.1 := (percent > min_max.1) ? percent : min_max.1
		Else min_max.3 := (percent < min_max.3) ? percent : min_max.3
		min_max := [Round(min_max.1, 1), Round(percent, 1), Round(min_max.3, 1)]
	}
	min_max := [min_max.1 "%", min_max.2 "%", min_max.3 "%"]
	Return xControl + wControl
}

Stash_PriceInfo(GUI_name, xAnchor, yAnchor, item, val, trend := 1, stack := "")
{
	local
	global vars, settings

	available := vars.stash.available, exalt := settings.stash.show_exalt, currencies := ["c", "e", "d"], currencies_verbose := ["chaos", "exalted", "divine"], lines := 0, tab := vars.stash.active
	trend_data := vars.stash[tab][item].trend.Clone(), margins := StrSplit(settings.stash.margins, ",", A_Space), bulk_sizes := []
	margin := settings.stash[tab].margin := LLK_HasVal(margins, settings.stash[tab].margin) ? settings.stash[tab].margin : margins.1, margin := margin ? Round(margin / 100, 2) : margin
	Gui, %GUI_name%: Font, % "s" settings.stash.fSize
	If !trend
	{
		Gui, %GUI_name%: Add, Text, % "x0 y0 Section Border Center BackgroundTrans", % " " LangTrans("stash_margin") ": "
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp BackgroundBlack Disabled Border", 0
		Loop, Parse, % settings.stash.margins, `,, % A_Space
		{
			style := (A_Index = 1 ? "Section " : "") "ys x+-1"
			Gui, %GUI_name%: Add, Text, % style " Border HWNDhwnd gStash_PricePicker BackgroundTrans", % " " A_LoopField " "
			vars.hwnd.stash_picker["margin_" A_LoopField] := hwnd
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp BackgroundBlack Disabled Border c" (Round(margin * 100) = A_LoopField ? "Green" : "Black"), 100
			ControlGetPos, xMargin,, wMargin,,, ahk_id %hwnd%
			xMargin%A_Index% := xMargin, wMargin%A_Index% := wMargin, wGUI := (xMargin + wMargin > wGUI) ? xMargin + wMargin : wGUI
		}
		dimensions := [], wColumn := settings.stash.fWidth * 7
		Loop 4
			If exalt && (A_Index = 2) || !exalt && (A_Index != 2)
				dimensions[A_Index] := " " (A_Index = 4 ? LangTrans("stash_value") : Round(available * val.prices[A_Index], 2) . (available > 1 ? "`n@" Round(val.prices[A_Index], 2) : "`n")) " "
		LLK_PanelDimensions(dimensions, settings.stash.fSize, wMarket, hMarket)
		Gui, %GUI_name%: Add, Text, % "x0 y+-1 Section Border Center HWNDhwnd BackgroundTrans w" wMarket + hMarket - 1, % LangTrans("stash_value")
		Gui, %GUI_name%: Add, Progress, % "ys x+-1 Disabled Background606060 w" settings.stash.fWidth//2 " hp", 0
		available0 := (available / vars.stash.max_stack > 60) ? vars.stash.max_stack * 60 : available

		Loop, % stack ? 5 : available0
		{
			amount := stack ? 6 - A_Index : Round(available0 // A_Index)
			If (bulk_sizes.Count() = 5)
				Break
			If LLK_HasVal(bulk_sizes, amount) || bulk_sizes.Count() && (Round(amount * val.prices.1 * (1 + margin)) < settings.stash.min_trade)
				Continue
			bulk_sizes.Push(amount)
			If vars.stash.note
				color := (InStr(vars.stash.note, "/" amount " ") || !InStr(vars.stash.note, "/") && (amount = 1) ? " cLime" : "")
			Gui, %GUI_name%: Add, Text, % "ys x+-1 BackgroundTrans HWNDhwnd Border Center w" wColumn . color, % amount (!stack && (check := Mod(available0, amount)) ? " (+" check ")" : "")
			If stack || (available != available0)
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled Border BackgroundBlack c" (stack ? "603030" : "303060"), 100
		}
		ControlGetPos, xColumn, yColumn, wColumn, hColumn,, ahk_id %hwnd%
		Gui, %GUI_name%: Add, Progress, % "x0 y+-1 Disabled Background606060 w" xColumn + wColumn " h" settings.stash.fWidth//2, 0
	}
	Else LLK_PanelDimensions([Round(val.prices.1, 2), Round(val.prices.2, 2), Round(val.prices.3, 2), ".`n."], settings.stash.fSize, wMarket, hMarket)

	For index, cType in ["chaos", "exalt", "divine"]
	{
		If (cType = "exalt") && !exalt || !trend && (available * val.prices[index] * (1 + margin) < 0.5) || price11 && (price11 < settings.stash.min_trade) || !trend && (item = cType " orb" || item = cType "ed orb")
			Continue
		hLine := hMarket, style := " Section HWNDhwnd BackgroundTrans h" hLine - (!trend ? 2 : 0) " w-1" (!trend ? " Border" : ""), lines += 1, price := ""
		Gui, %GUI_name%: Add, Pic, % (index != 1 || !trend ? "xs " (!trend ? "y+-1" : "") : "x+" settings.stash.fWidth " yp+" settings.stash.fWidth + (!trend ? settings.stash.fHeight : 0)) . style, % "img\GUI\" cType ".png"
		If (lines = 1)
			ControlGetPos, xAnchor2, yAnchor2,,,, ahk_id %hwnd%
		Gui, %GUI_name%: Add, Text, % (!trend ? "Border x+-1 Center " : "") "ys hp BackgroundTrans HWNDhwnd w" wMarket . (!trend && available > 1 ? "" : " 0x200"), % (!trend && available > 1 ? Round(available * val.prices[index], 2) "`n@" : "") . Round(val.prices[index], 2)
		ControlGetPos, xLast, yLast, wLast, hLast,, ahk_id %hwnd%
		If !trend
			Gui, %GUI_name%: Add, Progress, % "ys x+-1 Disabled Background606060 w" settings.stash.fWidth//2 " hp", 0
		wMax := (wLast > wMax) ? wLast : wMax

		If !trend
		{
			For iBulk, vBulk in bulk_sizes
			{
				price0 := vBulk * val.prices[index], price := Round(price0 * (1 + margin)), price%index%%iBulk% := price, inventory_check := (price / 20 > 60) ? 0 : 1
				Gui, %GUI_name%: Add, Text, % "ys x+-1 BackgroundTrans HWNDhwnd Border Center w" wColumn . (price >= 1 && inventory_check ? " gStash_PricePicker" : "") . (index = 1 && price < settings.stash.min_trade ? " cRed" : !inventory_check ? " cGray" : "")
				, % (price >= 1) ? price "`n(" Round((price/price0) * 100 - 100, 1) "%)" : "`n"
				vars.hwnd.stash_picker["pickprice_" (price = vBulk || vBulk = 1 ? price : price "_" vBulk) " " currencies_verbose[index]] := hwnd
				ControlGetPos, xBox, yBox, wBox, hBox,, ahk_id %hwnd%
			}
		}
	}

	If trend
	{
		If trend_data.Count() && settings.stash.history
		{
			wMax += Stash_PriceHistory(GUI_name, xLast + wMax, yAnchor + settings.stash.fWidth, yLast + hLast - yAnchor - settings.stash.fWidth, settings.stash.fWidth, trend_data, min_max), LLK_PanelDimensions(min_max, settings.stash.fSize, wTrend, hTrend,,, 0)
			For index, mm in min_max
			{
				style := (index = 1 ? "Section x" xLast + wMax + settings.stash.fWidth*1.5 " y" yAnchor2 : "xs"), color := (index = 2) ? " cB266FF" : (index = 1 ? " cLime" : " cRed")
				If (index = 1)
					wMax := 0
				text := (mm = "0.0%" && index != 2 || index = 1 && mm = min_max[index + 1] || index = 3 && mm = min_max[index - 1]) ? "" : mm
				Gui, %GUI_name%: Add, Text, % style " BackgroundTrans HWNDhwnd Right 0x200 w" wTrend " h" hLine * (!exalt ? 2/3 : 1) . color, % text
				ControlGetPos, xLast,, wLast,,, ahk_id %hwnd%
				wMax := (wLast > wMax) ? wLast : wMax
			}
		}
		Gui, %GUI_name%: Add, Text, % "BackgroundTrans Border x" xAnchor " y" yAnchor " w" xLast + wMax - xAnchor + settings.stash.fWidth*1.5 " h" yLast + hLast - yAnchor + settings.stash.fWidth
		Gui, %GUI_name%: Add, Progress, % "BackgroundBlack Disabled xp yp wp hp", 0
		Gui, %GUI_name%: Font, % "s" settings.stash.fSize2	
	}
	Else
	{
		Gui, %GUI_name%: Add, Text, % "Section Border BackgroundTrans x0 y0 w" Max(wGUI, xColumn + wColumn) " h" yLast + hLast
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled BackgroundBlack", 0
		If vars.stash.note
		{
			Gui, %GUI_name%: Add, Text, % "xp wp y+-1 Border Center BackgroundTrans", % " " LangTrans("stash_reminder") " "
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cMaroon", 100
		}
	}
}

/*
Stash_PriceInfo(GUI_name, xAnchor, yAnchor, item, val, trend := 1)
{
	local
	global vars, settings

	available := vars.stash.available, exalt := settings.stash.show_exalt, currencies := ["c", "e", "d"], currencies_verbose := ["chaos", "exalted", "divine"], lines := 0, tab := vars.stash.active, trend_data := vars.stash[tab][item].trend.Clone()
	margin := settings.stash[tab].margin, margin := margin ? Round(margin / 100, 2) : margin
	Gui, %GUI_name%: Font, % "s" settings.stash.fSize
	If !trend
	{
		Gui, %GUI_name%: Add, Text, % "x0 y0 Section Border Center BackgroundTrans", % " " LangTrans("stash_margin") ": "
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp BackgroundBlack Disabled Border", 0
		For index, vMargin in [0, 5, 10, 15, 20]
		{
			Gui, %GUI_name%: Add, Text, % "ys x+-1 Border HWNDhwnd gStash_PricePicker BackgroundTrans", % " " vMargin "% "
			vars.hwnd.stash_picker["margin_" vMargin] := hwnd
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp HWNDhwnd BackgroundBlack Disabled Border c" (margin * 100 = vMargin ? "Green" : "Black"), 100
		}
		ControlGetPos, xMargin, yMargin, wMargin,,, ahk_id %hwnd%
		dimensions := []
		Loop 4
			If exalt && (A_Index = 2) || !exalt && (A_Index != 2) || (val.prices[A_Index] < 0.02)
				dimensions[A_Index] := " " (A_Index = 4 ? LangTrans("stash_value") : Round(available * val.prices[A_Index], 2) (available > 1 ? " `n @" val.prices[A_Index] : "`n")) " "
		LLK_PanelDimensions(dimensions, settings.stash.fSize, wMarket, hMarket,,, 0)
		Gui, %GUI_name%: Add, Text, % "xs y+-1 Section Border Center HWNDhwnd BackgroundTrans w" wMarket + hMarket - 1, % LangTrans("stash_value")
	}
	Else LLK_PanelDimensions([val.prices.1, val.prices.2, val.prices.3, ".`n."], settings.stash.fSize, wMarket, hMarket,,, 0)

	For index, cType in ["chaos", "exalt", "divine"]
	{
		If (cType = "exalt") && !exalt || !trend && (val.prices[index] < 0.02 || available * val.prices[index] * (1 + margin) < 0.8)
			Continue
		hLine := hMarket, style := " Section HWNDhwnd BackgroundTrans h" hLine - (!trend ? 2 : 0) " w-1" (!trend ? " Border" : ""), lines += 1
		Gui, %GUI_name%: Add, Pic, % (index != 1 || !trend ? "xs " (!trend ? "y+-1" : "") : "x+" settings.stash.fWidth " yp+" settings.stash.fWidth + (!trend ? settings.stash.fHeight : 0)) . style, % "img\GUI\" cType ".png"
		If (index = 1)
			ControlGetPos, xAnchor2, yAnchor2,,,, ahk_id %hwnd%
		Gui, %GUI_name%: Add, Text, % (!trend ? "Border x+-1 Center " : "") "ys hp BackgroundTrans HWNDhwnd w" wMarket . (!trend && available > 1 ? "" : " 0x200"), % (!trend && available > 1 ? Round(available * val.prices[index], 2) "`n@" : "") . val.prices[index]
		ControlGetPos, xLast, yLast, wLast, hLast,, ahk_id %hwnd%
		wMax := (wLast > wMax) ? wLast : wMax
	}

	If trend
	{
		If trend_data.Count() && settings.stash.history
		{
			wMax += Stash_PriceHistory(GUI_name, xLast + wMax + settings.stash.fWidth, yAnchor + settings.stash.fWidth, yLast + hLast - yAnchor - settings.stash.fWidth, settings.stash.fWidth, trend_data, min_max), LLK_PanelDimensions(min_max, settings.stash.fSize, wTrend, hTrend,,, 0)
			For index, mm in min_max
			{
				style := (index = 1 ? "Section x" xLast + wMax + settings.stash.fWidth*1.5 " y" yAnchor2 : "xs"), color := (index = 2) ? " cB266FF" : (index = 1 ? " cLime" : " cRed")
				If (index = 1)
					wMax := 0
				text := (mm = "0.0%" && index != 2 || index = 1 && mm = min_max[index + 1] || index = 3 && mm = min_max[index - 1]) ? "" : mm
				Gui, %GUI_name%: Add, Text, % style " BackgroundTrans HWNDhwnd Right 0x200 w" wTrend " h" hLine * (!exalt ? 2/3 : 1) . color, % text
				ControlGetPos, xLast,, wLast,,, ahk_id %hwnd%
				wMax := (wLast > wMax) ? wLast : wMax
			}
		}
		Gui, %GUI_name%: Add, Text, % "BackgroundTrans Border x" xAnchor " y" yAnchor " w" xLast + wMax - xAnchor + settings.stash.fWidth*1.5 " h" yLast + hLast - yAnchor + settings.stash.fWidth, % " "
		Gui, %GUI_name%: Add, Progress, % "BackgroundBlack Disabled xp yp wp hp", 0
		Gui, %GUI_name%: Font, % "s" settings.stash.fSize2	
	}
	Else
	{
		Gui, %GUI_name%: Add, Progress, % "Section ys x+-1 y" settings.stash.fHeight - 1 " Disabled Background606060 w" settings.stash.fWidth//2 " h" settings.stash.fHeight + hLine * lines - lines, 0
		added := []
		Loop, % available
		{
			outer := A_Index, amount := Round(available // outer)
			If (outer > available) || (outer > 5)
				Break
			If added[Round(amount)] || (available / vars.stash.max_stack > 60) ;|| (amount * val.prices.1 < settings.stash.min_trade)
				Continue
			added[Round(amount)] := 1
			Gui, %GUI_name%: Add, Text, % "ys x+-1 Section BackgroundTrans Border Center w" settings.stash.fWidth * 7, % amount
			Loop 3
			{
				If !exalt && (A_Index = 2) || (val.prices[A_Index] < 0.02) || (amount * val.prices[A_Index] * (1 + margin) < 0.8) || (A_Index > 1 && price1 < settings.stash.min_trade)
					Continue
				price0 := amount * val.prices[A_Index], price := Round(price0 * (1 + margin)), price%A_Index% := price
				Gui, %GUI_name%: Add, Text, % "xs y+-1 BackgroundTrans HWNDhwnd Border Center wp" (price >= 1 ? " gStash_PricePicker" : "") . (price1 < settings.stash.min_trade ? " cRed" : "")
				, % (price >= 1) ? price "`n(" Round((price/price0) * 100 - 100, 1) "%)" : "`n"
				vars.hwnd.stash_picker["pickprice_" (price = amount || amount = 1 ? price : price "_" amount) " " currencies_verbose[A_Index]] := hwnd
				ControlGetPos, xBox, yBox, wBox, hBox,, ahk_id %hwnd%
			}
		}
		Gui, %GUI_name%: Add, Text, % "Border BackgroundTrans x0 y0 w" Max(xMargin + wMargin, !IsNumber(xBox + wBox) ? 0 : xBox + wBox) " h" settings.stash.fHeight*2 - 1 + hLine * lines - lines, 0
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled BackgroundBlack", 0
		If vars.stash.note
		{
			Gui, %GUI_name%: Add, Text, % "xp wp y+-1 Border Center BackgroundTrans", % " " LangTrans("stash_reminder") " "
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cMaroon", 100
		}
	}
}
*/

Stash_PricePicker(cHWND := "")
{
	local
	global vars, settings
	static toggle := 0

	item := vars.stash.hover, tab := vars.stash.active, vars.stash.note := InStr(Clipboard, "`nnote:")
	If !Blank(cHWND)
	{
		KeyWait, LButton
		check := LLK_HasVal(vars.hwnd.stash_picker, cHWND), control := SubStr(check, InStr(check, "_") + 1)
		If InStr(check, "margin_")
			IniWrite, % (settings.stash[tab].margin := control), ini\stash-ninja.ini, % tab, margin
		Else If InStr(check, "pickprice_")
		{
			price := StrReplace(control, "_", "/",, 1), Clipboard := "~price " price
			LLK_Overlay(vars.hwnd.stash_picker.main, "destroy"), vars.stash.enter := 0
			WinActivate, % "ahk_id " vars.hwnd.poe_client
			WinWaitActive, % "ahk_id " vars.hwnd.poe_client
			SendInput, ^{a}
			Sleep, 50
			SendInput, ^{v}{Enter}
			Return
		}
	}

	toggle := !toggle, GUI_name := "stash_pricepicker" toggle, note := vars.stash.note := vars.stash.note ? SubStr(Clipboard, vars.stash.note + 7) : ""
	If !InStr(Clipboard, LangTrans("items_stack"))
		available := 5, max_stack := 1, stack_unknown := 1
	Else available := SubStr(Clipboard, InStr(Clipboard, LangTrans("items_stack")) + StrLen(LangTrans("items_stack")) + 1),	max_stack := SubStr(available, InStr(available, "/") + 1)
		, max_stack := SubStr(max_stack, 1, InStr(max_stack, "`r") - 1), available := SubStr(available, 1, InStr(available, "/") - 1)

	For key, val in {"available": available, "max_stack": max_stack}
		Loop, Parse, val
			loopfield_copy := IsNumber(A_LoopField) ? A_LoopField : "", %key% := (A_Index = 1) ? loopfield_copy : %key% . loopfield_copy
	vars.stash.available := available, vars.stash.max_stack := max_stack
	Gui, %GUI_name%: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDhwnd_stash"
	Gui, %GUI_name%: Font, % "s" settings.stash.fSize2 " cWhite", % vars.system.font
	Gui, %GUI_name%: Color, Purple
	WinSet, TransColor, Purple
	Gui, %GUI_name%: Margin, 0, 0

	hwnd_old := vars.hwnd.stash_picker.main, vars.hwnd.stash_picker := {"main": hwnd_stash}
	Stash_PriceInfo(GUI_name, 0, 0, item, vars.stash[tab][item], 0, stack_unknown)
	Gui, %GUI_name%: Show, NA x10000 y10000
	WinGetPos,,, w, h, ahk_id %hwnd_stash%
	xPos := vars.client.x + vars.stash[tab][item].coords.1 + vars.stash[tab].box//2 - w//2, xPos := (xPos < vars.monitor.x) ? vars.monitor.x : xPos, yPos := vars.stash[tab][item].coords.2 - h - settings.stash.fWidth, yPos := (yPos < vars.monitor.y) ? vars.monitor.y : yPos
	Gui, %GUI_name%: Show, % "NA x" xPos " y" yPos
	LLK_Overlay(hwnd_stash, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy")
}
