Init_stash(refresh := 0)
{
	local
	global vars, settings, db, Json
	static json_data, exceptions := {"currency": ["reality fragment", "devouring fragment", "decaying fragment", "blazing fragment", "synthesising fragment", "cosmic fragment", "awakening fragment"
	, "blessing of chayula", "blessing of xoph", "blessing of uul-netol", "blessing of tul", "blessing of esh", "ritual vessel", "oil extractor"], "fragments": ["simulacrum", "simulacrum splinter"]}
	, dLimits := [[0.5, "", 3], [0.25, 0.5, 3], [10, 30, 1], [1, 10, 1], ["", 1, 1]], essences := ["whispering", "muttering", "weeping", "wailing", "screaming", "shrieking", "deafening"]

	If !FileExist("ini\stash-ninja.ini")
		IniWrite, % "", ini\stash-ninja.ini, settings

	If Blank(settings.features.stash)
		settings.features.stash := LLK_IniRead("ini\config.ini", "features", "enable stash-ninja", 0)
	If IsObject(settings.stash)
		backup := settings.stash.Clone()
	Else
	{
		settings.stash := {"indexes": 15}, ini := IniBatchRead("ini\stash-ninja.ini")
		settings.stash.fSize := !Blank(check := ini.settings["font-size"]) ? check : settings.general.fSize
		settings.stash.leagues := [["necro", "Necropolis"], ["hc necro", "Hardcore Necropolis"], ["standard", "Standard"]]
		settings.stash.league := !Blank(check := ini.settings["league"]) ? check : settings.stash.leagues.1.2
		settings.stash.history := !Blank(check := ini.settings["enable price history"]) ? check : 1
		settings.stash.show_exalt := !Blank(check := ini.settings["show exalt conversion"]) ? check : 0
		settings.stash.bulk_trade := !Blank(check := ini.settings["show bulk-sale suggestions"]) ? check : 1
		settings.stash.min_trade := !Blank(check := ini.settings["minimum trade value"]) ? check : ""
		settings.stash.autoprofiles := !Blank(check := ini.settings["enable trade-value profiles"]) ? check : 0
		settings.stash.retry := !Blank(check := ini.settings["retry"]) ? check : 0
		settings.stash.index_stock := !Blank(check := ini.settings["show stock in index"]) ? check : 1
		settings.stash.rate_limits := {"timestamp": ""}
		settings.stash.colors := [!Blank(check := ini.UI["text color"]) ? check : "000000", !Blank(check1 := ini.UI["background color"]) ? check1 : "00FF00"
							, !Blank(check2 := ini.UI["text color2"]) ? check2 : "000000", !Blank(check3 := ini.UI["background color2"]) ? check3 : "FF8000"]
		settings.stash.cBars := ["404060", "C16100", "606060"]

		If vars.client.stream
		{
			settings.stash.hotkey := !Blank(check := ini.settings.hotkey) ? check : "F2"
			Hotkey, IfWinActive, ahk_group poe_window
			Hotkey, % settings.stash.hotkey, Stash_Selection, On
		}
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
				iTab := ini[tab], settings.stash[tab] := {"gap": !Blank(check := iTab.gap) ? check : vars.stash.tabs[tab].2, "limits0": [], "limits": [], "profile": Blank(check1 := backup[tab].profile) ? 1 : check1, "in_folder": !Blank(check3 := iTab["tab is in folder"]) ? check3 : 0}, vars.stash[tab] := {}
			Loop 5
			{
				If !oCheck
				{
					ini1 := !Blank(check := iTab["limit " A_Index " bot"]) ? (check = "null" ? "" : check) : dLimits[A_Index].1
					ini2 := !Blank(check := iTab["limit " A_Index " top"]) ? (check = "null" ? "" : check) : dLimits[A_Index].2
					ini3 := !Blank(check := iTab["limit " A_Index " cur"]) ? (check = "null" ? "" : check) : dLimits[A_Index].3
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
		ini := IniBatchRead("data\global\[stash-ninja] prices.ini",, "65001")
		For tab in json_data
			If !InStr("currency2, breach", tab)
				tab := InStr(tab, "currency") ? "currency" : tab, vars.stash[tab].timestamp := ini[tab].timestamp, vars.stash[tab].league := ini[tab].league
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
			prices := IsObject(vars.stash[tab][name].prices) ? vars.stash[tab][name].prices.Clone() : StrSplit(!Blank(check := ini[tab0][name]) ? check : "0, 0, 0", ",", A_Space, 3)
			trend := IsObject(vars.stash[tab][name].trend) ? vars.stash[tab][name].trend.Clone() : StrSplit(!Blank(check := ini[tab0][name "_trend"]) ? check : "0, 0, 0, 0, 0, 0, 0", ",", A_Space)
			vars.stash[tab][name] := {"coords": [xCoord, yCoord], "exchange": array1.4, "prices": prices, "source": ["ninja"], "trend": trend}
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
		If (league != settings.stash.league) || Blank(timestamp) || Blank(now) || (now >= 61)
		{
			If !tooltip
				LLK_ToolTip(LangTrans("stash_update"), 10000,,, "stashprices", "lime")
			check := Stash_PriceFetch(tab), tooltip := 1
			If !check
			{
				LLK_ToolTip(LangTrans("stash_updateerror", 2), 2,,,, "red"), now := A_Now
				EnvAdd, now, -50, Minutes
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
		If IsObject(val) && (!Blank(lType) && LLK_IsBetween((lType = 4) ? val.trend[val.trend.MaxIndex()] : Round(val.prices[lType], 2), lBot, lTop) || test || InStr(item, "tab_"))
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
				price := Round(val.prices[lType], (val.prices[lType] > 1000) ? 0 : (val.prices[lType] > 10) ? 1 : 2), trade := val.source.2[lType]
				exception1 := LLK_PatternMatch(item, "", ["potent", "powerful", "prime"]) ? 1 : 0, exception2 := LLK_PatternMatch(item, "", ["powerful", "prime"]) ? 1 : 0
				Gui, %GUI_name%: Add, Text, % "BackgroundTrans Border Right c" colors[trade ? 3 : 1] " x" val.coords.1 " y" val.coords.2 + (exception1 ? vars.client.h * (1/12) : dBox) - settings.stash.fHeight2
				. " w" (exception2 ? vars.client.h * (1/12) : dBox) . (hidden ? " Hidden" : ""), % (test ? A_Index : (lType = 4) ? val.trend[val.trend.MaxIndex()] : price) " "
				Gui, %GUI_name%: Add, Progress, % "Disabled xp yp wp hp HWNDhwnd Border BackgroundBlack c" colors[trade ? 4 : 2] . (hidden ? " Hidden" : ""), 100
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

			If !vars.pics.stashninja[currencies[limit.3]]
				For index, currency in currencies
					vars.pics.stashninja[currency] := LLK_ImageCache("img\GUI\" currency ".png")
			Gui, %GUI_name%: Add, Pic, % "xp y" y " BackgroundTrans w" w - 2 " h-1 Border", % "HBitmap:*" vars.pics.stashninja[currencies[limit.3]]
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
		If !vars.client.stream && (!Clipboard || InStr(hotkey, "LButton") && (InStr(Clipboard, LangTrans("items_stack") " 1/") || !InStr(Clipboard, LangTrans("items_stack"))))
		{
			in_progress := 0
			Return
		}
		If settings.stash.bulk_trade && InStr(hotkey, "RButton") && vars.stash[vars.stash.active][vars.stash.hover].prices.1
			Stash_PricePicker()
		LLK_Overlay(vars.hwnd.stash.main, "hide"), vars.stash.GUI := 0, vars.stash.enter := 1
		While vars.stash.enter
			Sleep 1
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

	If (tab = "flush") ; when changing leagues, flush prices first to avoid old prices carrying over
	{
		For tab, tab_object in vars.stash
			For item, item_object in tab_object
			{
				If item_object.HasKey("prices")
					vars.stash[tab][item].prices := [0, 0, 0]
				If item_object.HasKey("source")
					vars.stash[tab][item].source := ["ninja", [], []]
			}
		Return
	}

	Loop, % (tab = "delve") ? 2 : 1
	{
		tab := InStr(tab, "currency") ? "currency" : tab, type := types[tab][A_Index], league := StrReplace(settings.stash.league, " ", "+"), outer := A_Index
		data_type := (InStr("fragments,currency", tab) ? "currency" : "item") "overview"
		Try prices := HTTPtoVar("https://poe.ninja/api/data/" data_type "?league=" league "&type=" type)
		If !(SubStr(prices, 1, 1) . SubStr(prices, 0) = "{}")
			Return 0
		prices := Json.Load(prices), ini_dump := "timestamp=" A_Now "`nleague=" settings.stash.league
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
			{
				If (vars.stash[check][name].source.1 = "trade")
				{
					Loop, Parse, price, `,, % A_Space
						If !vars.stash[check][name].source.2[A_Index]
							vars.stash[check][name].prices[A_Index] := A_LoopField
				}
				Else vars.stash[check][name].prices := StrSplit(price, ",", A_Space, 3), vars.stash[check][name].source := ["ninja", []]
				vars.stash[check][name].trend := Blank(trend) ? [0, 0, 0, 0, 0, 0, 0] : StrSplit(trend, ",", A_Space, 7)
			}
		}
		If (A_Index = 1)
		{
			IniWrite, % ini_dump, data\global\[stash-ninja] prices.ini, % tab
			vars.stash[tab].timestamp := A_Now, vars.stash[tab].league := settings.stash.league
		}
	}
	Return 1
}

Stash_PriceFetchTrade(array)
{
	local
	global vars, settings

	item := vars.stash.hover, tab := vars.stash.active, currencies := ["chaos", "exalted", "divine"]
	For rKey, rVal in array.2
	{
		If (A_Index = 1)
			settings.stash.rate_limits.limits := {}, settings.stash.rate_limits.timestamp := A_TickCount
		settings.stash.rate_limits.limits[rKey] := [rVal.1, rVal.2]
		If (rVal.1/rVal.2 = 1)
		{
			retry := A_Now
			EnvAdd, retry, % Ceil((rKey/rVal.1)*2), seconds
			settings.stash.retry := retry
		}
	}
	If IsNumber(array.4)
	{
		retry := A_Now
		EnvAdd, retry, % array.4 + 3, seconds
		IniWrite, % (settings.stash.retry := retry), ini\stash-ninja.ini, settings, retry
	}
	If (array.3 != 200)
	{
		LLK_ToolTip(LangTrans("global_error"),,,,, "Red")
		Return -1
	}

	listings := {}, stocks := {}
	For kResult, vResult in array.1.result
		For index, offer in vResult.listing.offers
		{
			currency := offer.exchange.currency, price := offer.exchange.amount, amount := offer.item.amount, stock := offer.item.stock, price_norm := price/amount
			If (index = 1)
				max_stock := 0
			If !IsObject(stocks[currency])
				stocks[currency] := {}
			If !IsObject(listings[currency])
				listings[currency] := {"prices": {}, "stocks": {}}
			If !IsObject(listings[currency].prices[price_norm])
				listings[currency].prices[price_norm] := [0, 0, 0], stocks[currency][price_norm] := {"total": 0, "max": 0}
			listings[currency].prices[price_norm].1 += 1, stocks[currency][price_norm].total += stock

			If (amount < listings[currency].prices[price_norm].3) || !listings[currency].prices[price_norm].3
			{
				Loop, % amount
					If (currency = "divine" && RegExMatch(price/amount, "i)\.\d00000"))
					{
						listings[currency].prices[price_norm].2 := Round(price/amount, 1), listings[currency].prices[price_norm].3 := 1
						Break
					}
					Else If (A_Index > 1) && !Mod(amount, A_Index) && !Mod(price, A_Index)
						listings[currency].prices[price_norm].2 := Round(price/A_Index), listings[currency].prices[price_norm].3 := Round(amount/A_Index)
				If !listings[currency].prices[price_norm].3
					listings[currency].prices[price_norm].2 := price, listings[currency].prices[price_norm].3 := amount
			}
			stocks[currency][price_norm].max := (stock > stocks[currency][price_norm].max) ? stock : stocks[currency][price_norm].max
		}

	For currency in listings
	{
		If (A_Index = 1)
			vars.stash[tab][item].source.1 := "trade"
		vars.stash[tab][item].source.2[(pCheck := LLK_HasVal(currencies, currency))] := A_TickCount, list := "", max := 0
		For price, entries in listings[currency].prices
			Loop, % entries.1
				list .= (Blank(list) ? "" : ",") price
		Sort, list, D`, N
		Loop, Parse, list, `,
		{
			If (A_Index = 1)
				list := [], list0 := []
			If !(iCheck := LLK_HasVal(list, A_LoopField,,,, 1, 1))
				list.Push([A_LoopField, listings[currency].prices[A_LoopField].2, listings[currency].prices[A_LoopField].3]), list[list.Length()].0 := 1
			Else list[iCheck].0 := Round(list[iCheck].0 + 1)
			list0.Push(A_LoopField)
		}
		median := list0[Ceil(list0.Length()/2)], listings[currency].prices := {}, count := max := max2 := max_decimals := 0
		While (list0.1 <= median * 0.1)
		{
			removed := list0.RemoveAt(1)
			While (list.1.1 <= removed)
				list.RemoveAt(1)
			median := list0[Ceil(list0.Length()/2)]
		}
		While (list0.Length() > 25 && list0[list0.Length()] >= median * 1.25)
		{
			popped := list0.Pop()
			While (list[list.Length()].1 >= popped)
				list.Pop()
			median := list0[Ceil(list0.Length()/2)]
		}
		iMedian := LLK_HasVal(list, median,,,, 1, 1), listings[currency].bulk := [list[iMedian].3, list[iMedian].2]
		For index, price in list
		{
			If (index > settings.stash.indexes)
				Break
			decimal_check := LLK_TrimDecimals(price.1), decimal_check := InStr(decimal_check, ".") ? SubStr(decimal_check, InStr(decimal_check, ".") + 1) : 0
			max_decimals := (StrLen(decimal_check) > max_decimals) ? StrLen(decimal_check) : max_decimals
			If !listings[currency].prices[price.1]
				listings[currency].prices[price.1] := price.0
			listings[currency].stocks[price.1] := [stocks[currency][price.1].total, stocks[currency][price.1].max]
			max := (stocks[currency][price.1].total > max) ? stocks[currency][price.1].total : max
			max2 := (stocks[currency][price.1].max > max2) ? stocks[currency][price.1].max : max2
		}
		listings[currency].stocks.max := [max, max2], listings[currency].decimals := max_decimals
		For price, entries in listings[currency].prices
			count += entries, max_listings := (entries > max_listings) ? entries : max_listings
		listings[currency].prices := list.Clone()
		average := listings[currency].stats := [list.1.1, median, list[list.Count()].1], listings[currency].listings := [count, max_listings]
		vars.stash[tab][item].prices[pCheck] := average.2
		vars.stash[tab][item].source.3[pCheck] := listings[currency].Clone()
	}
	Return IsObject(average)
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
	Gui, %gui_name%: Add, Progress, % "Disabled BackgroundWhite x" x " y" yLine1 " w" data.Count() * wSlice " h2", 0
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

Stash_PriceIndex(cHWND, currency := "")
{
	local
	global vars, settings
	static toggle := 0, xMain, yMain, wMain, last_currency

	If (cHWND = "destroy")
	{
		LLK_Overlay(vars.hwnd.stash_index.main, "destroy"), vars.hwnd.stash_index.main := ""
		Return
	}

	currencies := ["chaos", "exalt", "divine"], tab := vars.stash.active, width := settings.stash.fWidth2 * 5, item := vars.stash.hover
	If currency && !LLK_HasVal(currencies, currency)
	{
		KeyWait, LButton
		KeyWait, RButton
		check := LLK_HasVal(vars.hwnd.stash_index, cHWND), control := SubStr(check, InStr(check, "_") + 1)
		If InStr(check, "indexpick_")
		{
			prev_selection := vars.stash[tab][item].prices[(currency := LLK_HasVal(currencies, last_currency))]
			GuiControl, +cWhite, % vars.hwnd.stash_index["indexpick_" prev_selection]
			GuiControl, movedraw, % vars.hwnd.stash_index["indexpick_" prev_selection]
			vars.stash[tab][item].prices[currency] := control
			object := vars.stash[tab][item].source.3[currency], iPrice := LLK_HasVal(object.prices, control,,,, 1, 1)
			listed_bulk0 := listed_bulk := object.prices[iPrice].3, listed_price0 := listed_price := object.prices[iPrice].2
			object.bulk := [listed_bulk, listed_price]
			While settings.stash.min_trade && (currency = 1 && listed_price0 < settings.stash.min_trade) && (listed_price0 + listed_price <= 1200) && (listed_bulk0 + listed_bulk <= vars.stash.available0)
				listed_bulk0 += listed_bulk, listed_price0 += listed_price
			listed_bulk := listed_bulk0, listed_price := listed_price0
			GuiControl, +cLime, % cHWND
			GuiControl, movedraw, % cHWND
			GuiControl,, % vars.hwnd.stash_picker["bulksize_" currency], % listed_bulk
			GuiControl,, % vars.hwnd.stash_picker["bulkprice_" currency], % LLK_TrimDecimals(listed_price)
			Return
		}
		Else If (check = "stock")
			IniWrite, % (settings.stash.index_stock := !settings.stash.index_stock), ini\stash-ninja.ini, settings, show stock in index
	}
	Else
	{
		WinGetPos, xMain, yMain, wMain,, % "ahk_id " vars.hwnd.stash_picker.main
		last_currency := currency ? currency : last_currency
	}

	array := vars.stash[tab][item].source.3[(pCheck := LLK_HasVal(currencies, last_currency))]
	max := array.listings.2, max_stock := array.stocks.max.1, max_stock2 := array.stocks.max.2
	toggle := !toggle, GUI_name := "stash_priceindex" toggle, vals := [LangTrans("global_price")], counts := [array.listings.1]
	Gui, %GUI_name%: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDhwnd_index"
	Gui, %GUI_name%: Font, % "s" settings.stash.fSize - 2 " cWhite", % vars.system.font
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, -1, -1
	hwnd_old := vars.hwnd.stash_index.main, vars.hwnd.stash_index := {"main": hwnd_index}
	LLK_PanelDimensions([array.listings.1 " " LangTrans("stash_open") "  >"], settings.stash.fSize - 2, wListing_header, hListing_header)
	LLK_PanelDimensions([array.stocks.max.1], settings.stash.fSize - 2, wStock, hStock), LLK_PanelDimensions([array.stocks.max.2], settings.stash.fSize - 2, wStock2, hStock2)
	LLK_PanelDimensions([LangTrans("stash_stock"), LangTrans("global_all"), LangTrans("stash_solo")], settings.stash.fSize - 2, wStock3, hStock3)
	LLK_PanelDimensions([">"], settings.stash.fSize - 2, wToggle, hToggle), wStock3 := Max(wStock, wStock2, wStock3)
	cBars := settings.stash.cBars.1, cBars2 := settings.stash.cBars.2, cBars3 := settings.stash.cBars.3
	For index, val in array.prices
		If (index <= settings.stash.indexes)
			counts.Push(val.0), vals.Push(Round(val.1, array.decimals))

	LLK_PanelDimensions(vals, settings.stash.fSize - 2, wPrice, hPrice), LLK_PanelDimensions(counts, settings.stash.fSize - 2, wListings, hListings), prev := ""
	For index, val in array.prices
	{
		If !added
		{
			Gui, %GUI_name%: Add, Text, % "x-1 y-1 Section Border Center w" wPrice, % LangTrans("global_price")
			Gui, %GUI_name%: Add, Text, % "ys x+" wListing_header - wToggle - 1 " Border BackgroundTrans gStash_PriceIndex HWNDhwnd Center w" wToggle, % (settings.stash.index_stock ? "<" : ">")
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack c" cBars3, 100
			Gui, %GUI_name%: Add, Text, % "ys x" wPrice - 2 " Border Left w" wListing_header, % " " array.listings.1 " " LangTrans("stash_open") "  >"
			vars.hwnd.stash_index.stock := hwnd
			If settings.stash.index_stock
			{
				Gui, %GUI_name%: Add, Text, % "ys Border BackgroundTrans Center w" wStock3*2 - 1, % LangTrans("stash_stock")
				Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack c" cBars3, 100
			}
		}
		pListings := (vars.stash[tab][item].prices[pCheck] = val.1)
		Gui, %GUI_name%: Add, Text, % "xs Section BackgroundTrans gStash_PriceIndex HWNDhwnd Border Right w" wPrice . (pListings ? " cLime" : ""), % Round(val.1, array.decimals) " "
		Gui, %GUI_name%: Font, norm
		If (array.stats.2 = val.1)
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled cBlack BackgroundYellow", 100
		Gui, %GUI_name%: Add, Text, % "ys BackgroundTrans Right w" wListings, % val.0 " "
		Gui, %GUI_name%: Add, Text, % "xp yp Border HWNDhwnd2 BackgroundTrans w" wListing_header, % ""
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled HWNDhwnd2 BackgroundBlack Range0-" max " c" cBars, % val.0
		vars.hwnd.stash_index["indexpick_" val.1] := hwnd, added := 1
		If settings.stash.index_stock
		{
			Gui, %GUI_name%: Add, Text, % "ys Border BackgroundTrans Right w" wStock3, % array.stocks[val.1].1 " "
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack Range0-" max_stock " c" (array.stocks[val.1].1 = max_stock ? cBars2 : cBars), % array.stocks[val.1].1
			Gui, %GUI_name%: Add, Text, % "ys Border BackgroundTrans Right w" wStock3, % array.stocks[val.1].2 " "
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack Range0-" max_stock2 " c" (array.stocks[val.1].2 = max_stock2 ? cBars2 : cBars), % array.stocks[val.1].2
		}
		If (index = settings.stash.indexes)
			Break
	}

	ago := (A_TickCount - vars.stash[tab][item].source.2[pCheck])//1000
	ControlGetPos, xLast, yLast, wLast, hLast,, ahk_id %hwnd2%
	Gui, %GUI_name%: Add, Text, % "xs Section Border Center w" xLast + wLast, % "t+" FormatSeconds(ago, 0)
	If settings.stash.index_stock
	{
		Gui, %GUI_name%: Add, Text, % "ys Border BackgroundTrans Center w" wStock3, % LangTrans("global_all")
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack c" cBars3, % 100
		Gui, %GUI_name%: Add, Text, % "ys Border BackgroundTrans Center w" wStock3, % LangTrans("stash_solo")
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack c" cBars3, % 100
	}
	Gui, %GUI_name%: Show, % "NA x10000 y10000"
	WinGetPos,,,, height, ahk_id %hwnd_index%
	Gui, %GUI_name%: Show, % "x" xMain + wMain " y" (yMain + height >= vars.monitor.y + vars.monitor.h ? vars.monitor.y + vars.monitor.h - height : yMain)
	LLK_Overlay(hwnd_index, "show", 0, GUI_name), LLK_Overlay(hwnd_old, "destroy")
}

Stash_PriceInfo(GUI_name, xAnchor, yAnchor, item, val, trend := 1, currency := 0)
{
	local
	global vars, settings
	static last_currency := {}

	available := vars.stash.available, available0 := vars.stash.available0, max_stack := vars.stash.max_stack, note := vars.stash.note, tab := vars.stash.active
	exalt := settings.stash.show_exalt, lines := 0, trend_data := vars.stash[tab][item].trend.Clone(), bulk_sizes := []

	Gui, %GUI_name%: Font, % "s" settings.stash.fSize
	If !trend
	{
		LLK_PanelDimensions(["@777.777777`n"], settings.stash.fSize, wMarket, hMarket)
		wValue := wMarket + hMarket

		Gui, %GUI_name%: Add, Text, % "x-1 y-1 Hidden HWNDhwnd Border Center BackgroundTrans", % " x "
		ControlGetPos,,, wClose,,, ahk_id %hwnd%
		Gui, %GUI_name%: Font, % "s" settings.stash.fSize - 4
		Gui, %GUI_name%: Add, Edit, % "Hidden Disabled HWNDhwnd x-1 y-1", % "777777"
		ControlGetPos,,, wEdit,,, ahk_id %hwnd%
		Gui, %GUI_name%: Font, % "s" settings.stash.fSize

		Gui, %GUI_name%: Add, Text, % "x-1 y-1 Section BackgroundTrans Center HWNDhwnd Border w" wEdit, % LangTrans("stash_sell")
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled BackgroundBlack c" settings.stash.cBars.3 " Border w" wEdit, 100
		Gui, %GUI_name%: Add, Text, % "ys BackgroundTrans Center HWNDhwnd Border w" wEdit, % LangTrans("stash_sell", 2)
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled BackgroundBlack c" settings.stash.cBars.3 " Border w" wEdit, 100
		last_currency[item] := currency ? currency : last_currency[item]
		Gui, %GUI_name%: Add, Text, % "ys Border Center HWNDhwnd BackgroundTrans w" wValue - wClose, % LangTrans("stash_value")
		Gui, %GUI_name%: Add, Text, % "ys Border Center gStash_PricePicker", % " x "
	}
	Else LLK_PanelDimensions([Round(val.prices.1, 2), Round(val.prices.2, 2), Round(val.prices.3, 2), ".`n."], settings.stash.fSize, wMarket, hMarket)

	For index, cType in ["chaos", "exalt", "divine"]
	{
		If (cType = "exalt") && !exalt || !trend && (item = cType " orb" || item = cType "ed orb") || !trend && (val.prices[index] > 1200*1.1)
			Continue
		lines += 1, color := (val.source.1 = "trade" && val.source.2[index]) ? " cLime" : ""

		If !trend
		{
			If InStr(note, cType)
			{
				Loop, Parse, note
					If IsNumber(A_LoopField) || InStr("/.", A_LoopField)
						pNote .= A_LoopField
				pNote := StrSplit(pNote, "/",, 2), listed_price := pNote.1, listed_bulk := pNote.2 ? pNote.2 : 1, vars.stash[tab][item].prices[index] := Round(listed_price/listed_bulk, 6)
				val.source.3[index].bulk := [listed_bulk, listed_price]
				color := " cAqua"
			}
			Else If IsObject(prices := val.source.3[index].prices)
				iPrice := LLK_HasVal(prices, val.prices[index],,,, 1, 1), listed_price0 := listed_price := prices[iPrice].2, listed_bulk0 := listed_bulk := prices[iPrice].3
			Else listed_bulk0 := listed_bulk := 1, listed_price0 := listed_price := val.prices[index]

			If (index = last_currency[item]) && IsObject(val.source.3[index].prices)
			{
				If !InStr(note, cType)
				{
					While settings.stash.min_trade && (cType = "chaos" && listed_price0 < settings.stash.min_trade) && (listed_price0 + listed_price <= 1200)
					&& (listed_bulk0 + listed_bulk <= max_stack * 60) && (listed_bulk0 + listed_bulk <= available0)
						listed_bulk0 += listed_bulk, listed_price0 += listed_price
					listed_bulk := listed_bulk0, listed_price := listed_price0
				}
				Gui, %GUI_name%: Font, % "s" settings.stash.fSize - 4
				Gui, %GUI_name%: Add, Edit, % "xs Section Limit Number gStash_PricePicker cBlack Center h" Ceil(hMarket/2) " HWNDhwnd w" wEdit, % listed_bulk
				Gui, %GUI_name%: Add, Edit, % "ys Limit gStash_PricePicker cBlack Center h" Ceil(hMarket/2) " HWNDhwnd2 w" wEdit, % LLK_TrimDecimals(listed_price)
				Gui, %GUI_name%: Font, % "s" settings.stash.fSize
				vars.hwnd.stash_picker["bulksize_" index] := hwnd, vars.hwnd.stash_picker["bulkprice_" index] := hwnd2
				gLabel := (listed_price <= 1200 && listed_bulk <= max_stack * 60 && listed_bulk <= available0) || (available = -1) ? " gStash_PricePicker" (available = -1 ? " cYellow" : "") : " cRed"
				Gui, %GUI_name%: Add, Text, % "xs BackgroundTrans HWNDhwnd Border Center w" wEdit*2 - 1 . gLabel, % LangTrans("global_confirm")
				vars.hwnd.stash_picker["confirm_" index] := hwnd
			}
			Else
			{
				Gui, %GUI_name%: Add, Text, % "xs Border BackgroundTrans Section w" wEdit " h" hMarket, % " "
				Gui, %GUI_name%: Add, Text, % "ys Border BackgroundTrans wp hp", % " "
			}
			text := (available > 1 || available = -1) ? Round(Abs(available) * val.prices[index], 2) " `n@" LLK_TrimDecimals(val.prices[index]) : Round(val.prices[index], 2)
			Gui, %GUI_name%: Add, Text, % "ys Border Right BackgroundTrans HWNDhwnd w" wMarket " h" hMarket . (available > 1 || available = -1 ? "" : " 0x200") . color, % text " "
			vars.hwnd.stash_picker["value_" index] := hwnd
		}
		Else Gui, %GUI_name%: Add, Text, % "Right " (index != 1 ? "xs " : "x+" settings.stash.fWidth " yp+" settings.stash.fWidth + 0) " Section BackgroundTrans HWNDhwnd w" wMarket " h" hMarket " 0x200" color, % Round(val.prices[index], 2) " "

		Gui, %GUI_name%: Add, Pic, % "ys HWNDhwnd BackgroundTrans h" hMarket - (!trend ? 2 : 0) " w-1" (!trend ? " Border gStash_PricePicker" : ""), % "HBitmap:*" vars.pics.stashninja[cType]
		If !trend
			vars.hwnd.stash_picker["tradecheck_" cType] := hwnd
		If (lines = 1)
			ControlGetPos, xAnchor2, yAnchor2,,,, ahk_id %hwnd%
		ControlGetPos, xLast, yLast, wLast, hLast,, ahk_id %hwnd%
		wMax := (wLast > wMax) ? wLast : wMax
	}

	If trend
	{
		If trend_data.Count() && settings.stash.history
		{
			wMax += Stash_PriceHistory(GUI_name, xLast + wMax, yAnchor + settings.stash.fWidth, yLast + hLast - yAnchor - settings.stash.fWidth, settings.stash.fWidth, trend_data, min_max)
			LLK_PanelDimensions(min_max, settings.stash.fSize, wTrend, hTrend,,, 0)
			For index, mm in min_max
			{
				style := (index = 1 ? "Section x" xLast + wMax + settings.stash.fWidth//2 " y" yAnchor2 : "xs"), color := (index = 2) ? " cB266FF" : (index = 1 ? " cLime" : " cRed")
				If (index = 1)
					wMax := 0
				text := (mm = "0.0%" && index != 2 || index = 1 && mm = min_max[index + 1] || index = 3 && mm = min_max[index - 1]) ? "" : mm
				Gui, %GUI_name%: Add, Text, % style " BackgroundTrans HWNDhwnd Right 0x200 w" wTrend " h" hMarket * (!exalt ? 2/3 : 1) . color, % text
				ControlGetPos, xLast,, wLast,,, ahk_id %hwnd%
				wMax := (wLast > wMax) ? wLast : wMax
			}
		}
		Gui, %GUI_name%: Add, Text, % "Section BackgroundTrans Border x" xAnchor " y" yAnchor " w" xLast + wMax - xAnchor + settings.stash.fWidth * 1.5 " h" yLast + hLast - yAnchor + settings.stash.fWidth
		Gui, %GUI_name%: Add, Progress, % "BackgroundBlack Disabled xp yp wp hp", 0
		Gui, %GUI_name%: Font, % "s" settings.stash.fSize2
		Gui, %GUI_name%: Add, Text, % "xs y+-1 Border Center BackgroundTrans wp", % item
		Gui, %GUI_name%: Add, Progress, % "BackgroundBlack Disabled xp yp wp hp", 0
	}
	Else
	{
		dimensions := [], lCount := settings.stash.rate_limits.limits.Count()
		For limit in settings.stash.rate_limits.limits
			max_limit := limit, dimensions.Push(limit)
		LLK_PanelDimensions(dimensions, settings.stash.fSize, width, height)
		MsgBox, % settings.stash.retry ", " A_Now
		If (pCheck := settings.stash.rate_limits.limits) || (settings.stash.retry > A_Now)
		{
			Gui, %GUI_name%: Add, Text, % "Section xs y+0 Border BackgroundTrans Center HWNDhwnd" (pCheck ? " w" xLast + wLast + 1 - (width*lCount - (lCount - 1)) : ""), % (pCheck ? "" : " ") . LangTrans("stash_limits") . (pCheck ? "" : " ")
			If (settings.stash.retry > A_Now)
			{
				retry := settings.stash.retry
				EnvSub, retry, A_Now, seconds
			}
			Else retry := 0
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack HWNDhwnd1 cMaroon Range0-" retry, % retry
			vars.hwnd.stash_picker.tradecheck := hwnd, vars.hwnd.stash_picker.retry := hwnd1
		}
		For limit, array in settings.stash.rate_limits.limits
		{
			Gui, %GUI_name%: Add, Text, % "ys Border Center BackgroundTrans w" width, % limit
			color := (array.1 >= array.2 * 0.66) ? "Maroon" : (array.1 >= array.2 * 0.33) ? "CC6600" : "Green"
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp BackgroundBlack Border HWNDhwnd Range0-" array.2 " c" color, % array.1
			vars.hwnd.stash_picker["ratelimit_" limit] := hwnd
		}
		ControlGetPos,, yLast,, hLast,, ahk_id %hwnd%
		If vars.stash.note
		{
			Gui, %GUI_name%: Add, Text, % "x-1 y+0 Border Center BackgroundTrans w" xLast + wLast, % " " LangTrans("stash_reminder") " "
			Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cMaroon", 100
		}
	}
}

Stash_PricePicker(cHWND := "")
{
	local
	global vars, settings
	static toggle := 0, available, available0, max_stack, last_currency

	item := vars.stash.hover, tab := vars.stash.active, vars.stash.note := InStr(Clipboard, "`nnote:")
	If (cHWND = "destroy" || item = "chaos orb")
	{
		LLK_Overlay(vars.hwnd.stash_picker.main, "destroy"), vars.hwnd.stash_picker.main := ""
		Return
	}

	If !Blank(cHWND)
	{
		check := LLK_HasVal(vars.hwnd.stash_picker, cHWND), control := SubStr(check, InStr(check, "_") + 1), currencies := ["chaos", "exalt", "divine"]
		If InStr("+-,reset", cHWND)
		{
			check := LLK_HasVal(vars.hwnd.stash_picker, vars.general.cMouse), control := SubStr(check, InStr(check, "_") + 1)
			object := vars.stash[tab][item].source.3[control], listed_bulk0 := listed_bulk := object.bulk.1, listed_price0 := listed_price := object.bulk.2
			bulk := LLK_ControlGet(vars.hwnd.stash_picker["bulksize_" control])
			If (cHWND = "-" && bulk - listed_bulk < 1) || (cHWND = "+") && ((bulk + listed_bulk)/listed_bulk * listed_price > 1200 || available > 0 && bulk + listed_bulk > available0)
				Return
			Else If (cHWND = "reset" && control = 1) && settings.stash.min_trade
			{
				While (listed_price0 < settings.stash.min_trade) && (listed_price0 + listed_price <= 1200) && (listed_bulk0 + listed_bulk <= vars.stash.available0)
					listed_bulk0 += listed_bulk, listed_price0 += listed_price
				bulk := listed_bulk := listed_bulk0, listed_price := listed_price0
			}
			Else bulk := (cHWND = "reset") ? listed_bulk : (cHWND = "-") ? bulk - listed_bulk : bulk + listed_bulk
			GuiControl,, % vars.hwnd.stash_picker["bulksize_" control], % bulk
			GuiControl,, % vars.hwnd.stash_picker["bulkprice_" control], % (cHWND = "reset" || bulk/listed_bulk = 1) ? LLK_TrimDecimals(bulk/listed_bulk * listed_price) : Round(bulk/listed_bulk * listed_price)
			Return
		}
		Else If InStr(check, "confirm_")
		{
			KeyWait, LButton
			price := LLK_ControlGet(vars.hwnd.stash_picker["bulkprice_" control]), bulk := LLK_ControlGet(vars.hwnd.stash_picker["bulksize_" control]), curr := currencies[control]
			bulk := (bulk = 1) ? "" : "/" bulk
			Clipboard := "~price " LLK_TrimDecimals(price) . bulk " " curr . (control = 2 ? "ed" : "")
			Stash_PricePicker("destroy"), vars.stash.enter := 0
			WinActivate, % "ahk_id " vars.hwnd.poe_client
			WinWaitActive, % "ahk_id " vars.hwnd.poe_client
			SendInput, ^{a}
			Sleep, 50
			SendInput, ^{v}{Enter}
			Return
		}
		Else If (SubStr(check, 1, 4) = "bulk")
		{
			valid := 1, price := LLK_ControlGet(vars.hwnd.stash_picker["bulkprice_" control]), bulk := LLK_ControlGet(vars.hwnd.stash_picker["bulksize_" control])
			object := vars.stash[tab][item].source.3[control], listed_bulk := object.bulk.1, listed_price := object.bulk.2
			If !price || !bulk || (bulk > 1) && InStr(price, ".") || (bulk > available0) || (price > 1200)
				valid := (available = -1) ? 1 : 0
			GuiControl, Text, % vars.hwnd.stash_picker["value_" control], % Round(Abs(available) * (price/bulk), 2) " " (available > 1 || available = -1 ? "`n@" LLK_TrimDecimals(price/bulk) " " : "")
			GuiControl, % "+c" (price != bulk/listed_bulk * listed_price ? "Yellow" : "Lime"), % vars.hwnd.stash_picker["value_" control]
			GuiControl, movedraw, % vars.hwnd.stash_picker["value_" control]
			GuiControl, % "+c" (valid ? (available = -1 ? "Yellow" : "White") " +gStash_PricePicker" : "Red -g"), % vars.hwnd.stash_picker["confirm_" control]
			GuiControl, % "movedraw", % vars.hwnd.stash_picker["confirm_" control]
			Return
		}
		Else If (A_GuiControl = " x ")
		{
			KeyWait, LButton
			Stash_PricePicker("destroy"), vars.stash.enter := 0, Stash_PriceIndex("destroy")
			Return
		}
		Else If InStr(check, "tradecheck_")
		{
			KeyWait, LButton
			KeyWait, RButton
			If !vars.stash[tab][item].source.2[(currency := LLK_HasVal(currencies, control))] || (vars.system.click = 2)
			{
				If (settings.stash.retry > A_Now)
					Return
				If WinExist("ahk_id " vars.hwnd.stash_index.main)
					WinActivate, % "ahk_id " vars.hwnd.stash_index.main
				KeyWait, LButton
				KeyWait, RButton
				If IsObject(vars.stash[tab][item])
					ID := vars.stash[tab][item].exchange
				If ID
					Try trade_check := HTTPtoVar(ID, "exchange", (control = "exalt") ? "exalted" : control)
				If !IsObject(trade_check)
				{
					LLK_ToolTip(LangTrans("global_fail"),,,,, "red")
					Return
				}
				Else (tradecheck_status := Stash_PriceFetchTrade(trade_check)), index_check := vars.stash[tab][item].source.2[currency]
			}
			Else If (vars.system.click = 1)
			{
				If WinExist("ahk_id " vars.hwnd.stash_index.main) && (currency = last_currency)
				{
					Stash_PriceIndex("destroy")
					Return
				}
				Stash_PriceIndex(1, control)
				If (currency = last_currency)
					Return
			}
			last_currency := currency
		}
	}
	Else
	{
		If !InStr(Clipboard, LangTrans("items_stack"))
			available := max_stack := -1
		Else available := SubStr(Clipboard, InStr(Clipboard, LangTrans("items_stack")) + StrLen(LangTrans("items_stack")) + 1),	max_stack := SubStr(available, InStr(available, "/") + 1)
			, max_stack := SubStr(max_stack, 1, InStr(max_stack, "`r") - 1), available := SubStr(available, 1, InStr(available, "/") - 1)
	}
	KeyWait, RButton
	toggle := !toggle, GUI_name := "stash_pricepicker" toggle, note := vars.stash.note := vars.stash.note ? SubStr(Clipboard, vars.stash.note + 7) : ""

	For key, val in {"available": available, "max_stack": max_stack}
		Loop, Parse, val
			loopfield_copy := IsNumber(A_LoopField) || (A_LoopField = "-") ? A_LoopField : "", %key% := (A_Index = 1) ? loopfield_copy : %key% . loopfield_copy
	vars.stash.available := available, vars.stash.max_stack := max_stack, available0 := vars.stash.available0 := (available/max_stack > 60) ? max_stack * 60 : available
	Gui, %GUI_name%: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDhwnd_stash"
	Gui, %GUI_name%: Font, % "s" settings.stash.fSize - 2 " cWhite", % vars.system.font
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, -1, -1

	hwnd_old := vars.hwnd.stash_picker.main, vars.hwnd.stash_picker := {"main": hwnd_stash}
	Stash_PriceInfo(GUI_name, 0, 0, item, vars.stash[tab][item], 0, currency)
	Gui, %GUI_name%: Show, NA x10000 y10000
	WinGetPos,,, w, h, ahk_id %hwnd_stash%
	xPos := vars.client.x + vars.stash[tab][item].coords.1 + vars.stash[tab].box//2 - w//2, xPos := (xPos < vars.monitor.x) ? vars.monitor.x : xPos, yPos := vars.stash[tab][item].coords.2 - h - settings.stash.fWidth, yPos := (yPos < vars.monitor.y) ? vars.monitor.y : yPos
	Gui, %GUI_name%: Show, % "NA x" xPos " y" yPos
	LLK_Overlay(hwnd_stash, "show", 0, GUI_name), LLK_Overlay(hwnd_old, "destroy")
	If settings.stash.rate_limits.timestamp || (settings.stash.retry > A_Now)
		Stash_RateTick(1)
	If (tradecheck_status > 0) && index_check
		Stash_PriceIndex(1, control)
	If (tradecheck_status = 0)
		LLK_ToolTip(LangTrans("stash_nolistings"), 2,,,, "yellow"), Stash_PriceIndex("destroy")
}

Stash_RateTick(mode := 0)
{
	local
	global vars, settings
	static limits
	start := A_TickCount
	If mode
	{
		SetTimer, Stash_RateTick, Delete
		limits := settings.stash.rate_limits.limits.Clone()
	}
	elapsed := (A_TickCount - settings.stash.rate_limits.timestamp)//1000
	If settings.stash.retry
	{
		If (settings.stash.retry >= A_Now)
		{
			retry := settings.stash.retry
			EnvSub, retry, A_Now, seconds
			GuiControl,, % vars.hwnd.stash_picker.retry, % retry
		}
		Else
		{
			settings.stash.retry := 0
			IniDelete, ini\stash-ninja.ini, settings, retry
		}
	}

	If !settings.stash.retry
		For key, array in settings.stash.rate_limits.limits
		{
			tick := Ceil(key/Max(1, array.1)), limit := limits[key].1 - elapsed//tick, limit := (limit <= 0) ? "" : limit, limits[key].1 := limit
			interval := !interval && limits[key].1 ? key*1000 : interval, interval := (tick && tick*1000 < interval) ? tick*1000 : interval, color := (limit >= limits[key].2 * 0.66) ? "Maroon" : (limit >= limits[key].2 * 0.33) ? "CC6600" : "Green"
			GuiControl,, % vars.hwnd.stash_picker["ratelimit_" key], % limit
			GuiControl, % "+c" color, % vars.hwnd.stash_picker["ratelimit_" key]
		}
	If interval || !Blank(retry)
		SetTimer, Stash_RateTick, % !Blank(retry) ? -1000 : -interval
}

Stash_Selection(cHWND := "") ; GeForce Now
{
	local
	global vars, settings

	If !settings.features.stash
		Return
	If cHWND
		check := LLK_HasVal(vars.hwnd.stash_selection, cHWND)
	If check
	{
		Stash_(check)
		Gui, stash_selection: Destroy
		Return
	}
	dimensions := [], dimensions0 := []
	Gui, stash_selection: New, % "-Caption -DPIScale +LastFound +AlwaysOnTop +ToolWindow +Border +E0x02000000 +E0x00080000 HWNDhwndGUI"
	Gui, stash_selection: Font, % "s" settings.stash.fSize - 2 " cWhite", % vars.system.font
	Gui, stash_selection: Color, Black
	Gui, stash_selection: Margin, 0, 0

	For tab in vars.stash.tabs
		dimensions.Push(LangTrans("m_stash_" tab)), dimensions0.Push(tab)
	LLK_PanelDimensions(dimensions, settings.stash.fSize, width, height), vars.hwnd.stash_selection := {"main": hwndGUI}
	For index, tab in dimensions
	{
		Gui, stash_selection: Add, Text, % "xs Section gStash_selection HWNDhwnd w" width, % " " tab " "
		vars.hwnd.stash_selection[dimensions0[index]] := hwnd
	}
	Gui, stash_selection: Show, % "x" vars.general.xMouse - width//2 " y" vars.general.yMouse - settings.stash.fHeight
	WinWait, ahk_id %hwndGUI%
	While WinActive("ahk_id " hwndGUI)
		Sleep 100
	Gui, stash_selection: Destroy
}
