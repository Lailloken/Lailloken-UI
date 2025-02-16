Init_legion(mode := "")
{
	local
	global vars, settings, db, Json

	If vars.poe_version
		Return

	If !FileExist("ini" vars.poe_version "\seed-explorer.ini")
		IniWrite, % "", % "ini" vars.poe_version "\seed-explorer.ini", settings

	If !mode
	{
		If !FileExist("data\" settings.general.lang_client "\timeless jewels.json")
			db.legion := Json.Load(LLK_FileRead("data\english\timeless jewels.json"))
		Else db.legion := Json.Load(LLK_FileRead("data\" settings.general.lang_client "\timeless jewels.json"))

		ini := IniBatchRead("ini" vars.poe_version "\seed-explorer.ini")
		settings.legion := {"fSize": !Blank(check := ini.settings["font-size"]) ? check : settings.general.fSize, "profile": !Blank(check1 := ini.settings["profile"]) ? check1 : 1}
		settings.legion.version := !Blank(check := ini.settings.version) ? check : 0
		LLK_FontDimensions(settings.legion.fSize, height, width), settings.legion.fWidth := width, settings.legion.fHeight := height
		vars.legion := {}
	}
	settings.legion.highlights := {}
	Loop, Parse, % LLK_IniRead("ini" vars.poe_version "\seed-explorer.ini", "highlights profile "settings.legion.profile), `n
		key := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1), val := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1), settings.legion.highlights[key] := val
}

Legion(cHWND := "")
{
	local
	global vars, settings, db

	check := LLK_HasVal(InStr(A_Gui, "tree") ? vars.hwnd.legion_tree : vars.hwnd.legion, cHWND), control := SubStr(check, InStr(check, "_") + 1)
	If InStr(check, "profile_")
	{
		If (vars.system.click = 2) && LLK_Progress(vars.hwnd.legion["delbar_"control], "RButton")
		{
			IniDelete, ini\seed-explorer.ini, highlights profile %control%
			If (control = settings.legion.profile)
				settings.legion.highlights := {}
			Legion_GUI()
			KeyWait, RButton
			Return
		}
		Else If (vars.system.click = 2)
			Return
		IniWrite, % control, ini\seed-explorer.ini, settings, profile
		settings.legion.profile := control, Init_legion("highlights"), Legion_GUI()
	}
	Else If (check = "import")
	{
		If Legion_Parse()
			Legion_GUI()
	}
	Else If (check = "trade")
	{
		conquerors := []
		For key, val in db.legion.jewels[vars.legion.jewel]
			If (key != "_decoder")
				conquerors.Push(val.1)
		legion_trade := "{%22query%22:{%22status%22:{%22option%22:%22any%22},%22stats%22:[{%22type%22:%22count%22,%22filters%22:[{%22id%22:%22explicit.pseudo_timeless_jewel_" conquerors.1 "%22,%22value%22:{%22min%22:" vars.legion.seed ",%22max%22:" vars.legion.seed
		. "},%22disabled%22:false},{%22id%22:%22explicit.pseudo_timeless_jewel_" conquerors.2 "%22,%22value%22:{%22min%22:" vars.legion.seed ",%22max%22:" vars.legion.seed
		. "},%22disabled%22:false},{%22id%22:%22explicit.pseudo_timeless_jewel_" conquerors.3 "%22,%22value%22:{%22min%22:" vars.legion.seed ",%22max%22:" vars.legion.seed "},%22disabled%22:false}],%22value%22:{%22min%22:1}}]},%22sort%22:{%22price%22:%22asc%22}}"
		Run, https://www.pathofexile.com/trade/search/?q=%legion_trade%
		Return
	}
	Else If (control = "+5 devotion")
		Return
	Else If InStr(check, "font_")
	{
		While GetKeyState("LButton")
		{
			If (control = "minus") && (settings.legion.fSize > 6)
				settings.legion.fSize -= 1
			Else If (control = "reset")
				settings.legion.fSize := settings.general.fsize
			Else If (control = "plus")
				settings.legion.fSize += 1
			GuiControl, text, % vars.hwnd.legion.font_reset, % settings.legion.fSize
			Sleep, 125
		}
		LLK_FontDimensions(settings.legion.fSize, height, width), settings.legion.fWidth := width, settings.legion.fHeight := height, vars.legion.fSize_tree := ""
		IniWrite, % settings.legion.fSize, ini\seed-explorer.ini, settings, font-size
		Legion_GUI()
	}
	Else If InStr(check, "mod_")
	{
		If (vars.system.click = 1)
		{
			regex_string := "nota ^("
			KeyWait, LButton
			If !vars.legion.socket
				Return
			vars.legion.selection := control, Legion_GUI()
			WinActivate, ahk_group poe_window
			WinWaitActive, ahk_group poe_window
			If vars.legion.nodes.HasKey(control)
				Clipboard := "^(" StrReplace(StrReplace(control, "ash frost and storm", "ash, frost and storm"), " ", "\s") ")"
			Else
			{
				For index, val in LLK_HasVal(vars.legion.data.3, vars.legion.decoder_invert[control],,, 1)
					If !Blank(LLK_HasVal(db.legion.sockets[vars.legion.socket].nodes, vars.legion.nodes_invert[val]))
					{
						db_clone := db.legion.notables.Clone()
						Loop, Parse, % "mine", `;
							db_clone.Push(A_LoopField)
						check := Legion_CreateRegex(vars.legion.nodes_invert[val], db_clone)
						regex_string .= check ? StrReplace(check, " ", "\s") "|" : ""
					}
				Clipboard := SubStr(regex_string, 1, -1) ")"
			}
			SendInput, ^{f}^{v}{Enter}
		}
		Else If (vars.system.click = 2)
		{
			settings.legion.highlights[control] := settings.legion.highlights[control] ? 0 : 1
			IniWrite, % settings.legion.highlights[control], ini\seed-explorer.ini, % "highlights profile "settings.legion.profile, % control
			Legion_GUI()
		}
	}
	Else If InStr(check, "socket_")
		vars.legion.socket := (vars.legion.socket != control) ? control : "", vars.legion.selection := "", Legion_GUI()
	Else LLK_ToolTip("no action")
}

Legion_Close()
{
	local
	global vars

	LLK_Overlay(vars.hwnd.legion.main, "destroy"), vars.hwnd.legion.main := "", LLK_Overlay(vars.hwnd.legion_tree.main, "destroy"), LLK_Overlay(vars.hwnd.legion.tooltip, "destroy")
}

Legion_CreateRegex(string, database)
{
	local

	If Blank(string) || !IsObject(database) || (StrLen(string) < 4)
		Return 0
	While (A_Index <= StrLen(string))
	{
		check := SubStr(string, 1, A_Index), matches := 0
		For index, val in database
			matches += StrMatch(val, check) ? 1 : 0
		If (matches < 2)
			Return check
	}
	Return string
}

Legion_GUI()
{
	local
	global vars, settings, db
	static toggle := 0

	vars.legion.width := settings.legion.fWidth*29, LLK_Overlay(vars.hwnd.legion.tooltip, "destroy"), vars.legion.tooltip := "", vars.legion.wait := 1
	If !IsObject(vars.legion.nodes)
		Loop, Parse, % vars.legion.nodes, `,
		{
			If (A_Index = 1)
				vars.legion.nodes := {}, vars.legion.nodes_invert := []
			vars.legion.nodes[StrReplace(A_LoopField, "ash frost and storm", "ash, frost and storm")] := A_Index, vars.legion.nodes_invert.Push(StrReplace(A_LoopField, "ash frost and storm", "ash, frost and storm"))
		}
	toggle := !toggle, GUI_name := "legion" toggle
	Gui, %GUI_name%: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDlegion"
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, 0, 0
	Gui, %GUI_name%: Font, % "s"settings.legion.fSize " cWhite", % vars.system.font
	hwnd_old := vars.hwnd.legion.main, vars.hwnd.legion := {"main": legion, "tooltips": {}, "tooltips2": {}}

	Gui, %GUI_name%: Add, Text, % "x"settings.legion.fWidth/2 " y"settings.legion.fWidth/2 " Section HWNDhwnd", % Lang_Trans("seed_profile")
	ControlGetPos, xAnchor, yAnchor, wAnchor, hAnchor,, ahk_id %hwnd%
	Loop 5
	{
		Gui, %GUI_name%: Add, Text, % "ys x+"(settings.legion.fWidth/(A_Index = 1 ? 2 : 4)) " Border BackgroundTrans Center gLegion HWNDhwnd w"settings.legion.fWidth*2 (A_Index = settings.legion.profile ? " cFuchsia" : ""), % A_Index
		Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Border Disabled BackgroundBlack cRed Range0-500 HWNDhwndbar", 0
		vars.hwnd.legion["profile_"A_Index] := hwnd, vars.hwnd.legion["delbar_"A_Index] := hwndbar
	}

	file_check := !FileExist("data\global\[legion]*") ? 0 : 1
	Gui, %GUI_name%: Add, Text, % "xs Border HWNDhwnd0 BackgroundTrans gLegion_Update y+"settings.legion.fWidth/2 (file_check ? "" : " cRed"), % " " (!file_check ? Lang_Trans("seed_download") : Lang_Trans("seed_update")) " "
	Gui, %GUI_name%: Add, Progress, % "xp yp wp hp Disabled BackgroundBlack cGreen Range0-5 HWNDhwnd", 0
	vars.hwnd.legion.update := hwnd0, vars.hwnd.legion.update_bar := vars.hwnd.help_tooltips["seed-explorer_" (file_check ? "update" : "download")] := hwnd

	Gui, %GUI_name%: Font, % "underline bold"
	Gui, %GUI_name%: Add, Text, % "xs y+"settings.legion.fWidth/2, % Lang_Trans("seed_jewel")
	Gui, %GUI_name%: Font, % "norm"
	Gui, %GUI_name%: Add, Text, % "xs y+0", % Lang_Trans("global_type") " " vars.legion.jewel
	Gui, %GUI_name%: Add, Text, % "xs y+0", % Lang_Trans("seed_seed") " " vars.legion.seed
	Gui, %GUI_name%: Add, Text, % "xs y+0", % Lang_Trans("seed_conqueror") " " vars.legion.leader

	Gui, %GUI_name%: Add, Text, % "xs Center Border HWNDhwndimport gLegion", % " " Lang_Trans("global_import") " "
	Gui, %GUI_name%: Add, Text, % "x+"settings.legion.fWidth/2 " yp Center Border HWNDhwndtrade gLegion", % " " Lang_Trans("seed_trade") " "
	vars.hwnd.legion.import := vars.hwnd.help_tooltips["seed-explorer_import"] := hwndimport, vars.hwnd.legion.trade := vars.hwnd.help_tooltips["seed-explorer_trade"] := hwndtrade

	Gui, %GUI_name%: Font, % "underline bold"
	Gui, %GUI_name%: Add, Text, % "xs y+"settings.legion.fWidth, % Lang_Trans("seed_keystones")
	Gui, %GUI_name%: Font, % "norm"
	For keystone, val in db.legion.jewels[vars.legion.jewel]
		If !InStr(keystone, "decoder")
		{
			Gui, %GUI_name%: Add, Text, % "xs HWNDhwnd y+0"(val.1 = vars.legion.leader ? " cLime" : ""), % keystone
			vars.hwnd.legion.tooltips[keystone] := hwnd
		}

	If vars.legion.socket
	{
		Gui, %GUI_name%: Font, % "underline bold"
		Gui, %GUI_name%: Add, Text, % "xs Section y+"settings.legion.fWidth, % Lang_Trans("seed_notables")
		Gui, %GUI_name%: Font, % "norm"

		Gui, %GUI_name%: Add, Pic, % "ys hp w-1 HWNDhwnd x+" settings.legion.fWidth/2, % "HBitmap:*" vars.pics.global.help
		vars.hwnd.help_tooltips["seed-explorer_legion notables socket"] := hwnd

		mods := {}
		For index, node in db.legion.sockets[vars.legion.socket].nodes
			text := db.legion.jewels[vars.legion.jewel]["_decoder"][vars.legion.data.3[vars.legion.nodes[node]]], mods[text] := mods[text] ? mods[text] + 1 : 1
		For mod, count in mods
		{
			Gui, %GUI_name%: Add, Text, % "xs HWNDhwnd gLegion"(settings.legion.highlights[mod] ? " cAqua" : "") (vars.legion.selection = mod ? " Border" : ""), % mod " (" count ")"
			vars.hwnd.legion["mod_"mod] := hwnd
			If db.legion.jewels.descriptions.HasKey(mod)
				vars.hwnd.legion.tooltips[mod] := hwnd
		}
	}

	Gui, %GUI_name%: Add, Text, % "x0 y0 Border BackgroundTrans w"vars.legion.width " h"vars.monitor.h - vars.legion.width + 1
	If !vars.pics.legion.treemap
		vars.pics.legion.treemap := LLK_ImageCache("img\GUI\legion_treemap.jpg")
	Gui, %GUI_name%: Add, Pic, % "xp y+-1 Border HWNDhwnd w"vars.legion.width - 2 " h-1", % "HBitmap:*" vars.pics.legion.treemap
	vars.hwnd.legion.treemap := hwnd

	Gui, %GUI_name%: Add, Text, % "Section x"xAnchor + vars.legion.width " y"yAnchor, % Lang_Trans("global_font") " "
	Gui, %GUI_name%: Add, Text, % "ys x+0 Center Border gLegion HWNDhwnd w"settings.legion.fWidth*2, % "–"
	vars.hwnd.legion.font_minus := hwnd
	Gui, %GUI_name%: Add, Text, % "ys x+"settings.legion.fWidth/4 " Center Border gLegion HWNDhwnd w"settings.legion.fWidth*3, % settings.legion.fSize
	vars.hwnd.legion.font_reset := hwnd
	Gui, %GUI_name%: Add, Text, % "ys x+"settings.legion.fWidth/4 " Center Border gLegion HWNDhwnd w"settings.legion.fWidth*2, % "+"
	vars.hwnd.legion.font_plus := hwnd

	Gui, %GUI_name%: Font, % "underline bold"
	Gui, %GUI_name%: Add, Text, % "xs Section y+"settings.legion.fWidth/2, % vars.legion.socket ? Lang_Trans("seed_notables", 2) : Lang_Trans("seed_notables", 3)
	Gui, %GUI_name%: Font, % "norm"

	Gui, %GUI_name%: Add, Pic, % "ys hp w-1 HWNDhwnd x+" settings.legion.fWidth/2, % "HBitmap:*" vars.pics.global.help
	vars.hwnd.help_tooltips["seed-explorer_" (vars.legion.socket ? "socket" : "legion notables")] := hwnd

	If !vars.legion.socket
	{
		For index, mod in vars.legion.jewel_mods
		{
			Gui, %GUI_name%: Add, Text, % "xs HWNDhwnd gLegion"(settings.legion.highlights[mod] ? " cAqua" : ""), % mod
			vars.hwnd.legion["mod_"mod] := hwnd
			If db.legion.jewels.descriptions.HasKey(mod)
				vars.hwnd.legion.tooltips[mod] := hwnd
		}
	}
	Else
		For index, node in db.legion.sockets[vars.legion.socket].nodes
		{
			mod := db.legion.jewels[vars.legion.jewel]["_decoder"][vars.legion.data.3[vars.legion.nodes[node]]]
			color := settings.legion.highlights[node] && settings.legion.highlights[mod] ? " cYellow" : settings.legion.highlights[node] ? " cLime" : ""
			Gui, %GUI_name%: Add, Text, % "xs HWNDhwnd gLegion"color (vars.legion.selection = node ? " Border" : ""), % node
			While vars.hwnd.legion.tooltips2.HasKey(mod)
				mod .= "_"
			vars.hwnd.legion["mod_"node] := hwnd, vars.hwnd.legion.tooltips2[mod] := hwnd
		}

	Gui, %GUI_name%: Add, Text, % "x"vars.legion.width - 1 " y0 Border BackgroundTrans w"vars.legion.width " h"vars.monitor.h

	Gui, %GUI_name%: Show, % "NA x10000 y10000 h"vars.monitor.h
	If InStr(A_Gui, "tree")
		Gui, % Gui_Name(vars.hwnd.legion_tree.main) ": +Owner" GUI_name
	Gui, %GUI_name%: Show, % "Hide x"vars.monitor.x " y"vars.monitor.y
	LLK_Overlay(legion, "show", 0, GUI_name), LLK_Overlay(hwnd_old, "destroy")
	If InStr(A_Gui, "tree")
		Legion_Tree()
	vars.legion.wait := 0
}

Legion_Hover()
{
	local
	global vars, settings, db
	static tooltip

	If vars.legion.wait
		Return
	ControlGetPos,, y,, h,, % "ahk_id "vars.general.cMouse
	check := LLK_HasVal(vars.hwnd.legion.tooltips, vars.general.cMouse), check2 := !check ? StrReplace(LLK_HasVal(vars.hwnd.legion.tooltips2, vars.general.cMouse), "_") : "0"
	If (vars.general.cMouse = vars.hwnd.legion.treemap) && !WinExist("ahk_id "vars.hwnd.legion_tree.main)
		Legion_Tree()
	Else If WinExist("ahk_id "vars.hwnd.legion_tree.main) && (vars.general.wMouse != vars.hwnd.legion_tree.main)
		LLK_Overlay(vars.hwnd.legion_tree.main, "destroy")

	If vars.general.cMouse && (check || check2) && (vars.legion.tooltip != check) && (vars.legion.tooltip != check2)
	{
		Gui, legion_tooltip: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +Border +E0x20 +E0x02000000 +E0x00080000 HWNDtooltip"
		Gui, legion_tooltip: Color, 202020
		Gui, legion_tooltip: Margin, 0, 0
		Gui, legion_tooltip: Font, % "s"settings.legion.fSize " cWhite", % vars.system.font
		vars.hwnd.legion.tooltip := tooltip, parse := db.legion.jewels.descriptions[check ? check : check2] ? db.legion.jewels.descriptions[check ? check : check2].Clone() : []
		If check2
			parse.0 := "result:`n"check2
		For index, text in parse
			Gui, legion_tooltip: Add, Text, % (A_Index = 1 ? "" : "xs y+0") " Center Border w"settings.legion.fWidth*29 - 2, % text
		vars.legion.tooltip := check ? check : check2
		Gui, legion_tooltip: Show, % "NA x"(vars.general.xMouse - vars.monitor.x < vars.legion.width ? vars.monitor.x : vars.monitor.x + vars.legion.width - 1) " y"y + h + 1
		LLK_Overlay(tooltip, "show",, "legion_tooltip")
	}
	Else If !check && !check2 && vars.legion.tooltip
	{
		vars.legion.tooltip := ""
		Gui, legion_tooltip: Destroy
	}
}

Legion_Parse()
{
	local
	global vars, settings, db

	leaders := vars.lang.seed_conquerors, item := vars.omnikey.item
	jewels := ["glorious vanity", "lethal pride", "brutal restraint", "militant faith", "elegant hubris"], vars.legion.selection := ""

	For index, val in jewels
		For index1, val1 in vars.lang["seed_" val]
			If InStr(Clipboard, val1 "(")
				vars.legion.jewel := val, vars.legion.leader := val1, check := 1

	If !check
	{
		LLK_ToolTip(Lang_Trans("lvltracker_importerror", 2), 1.5,,,, "red")
		Return 0
	}

	Loop, Parse, Clipboard, `n, `r
	{
		If !InStr(A_LoopField, vars.legion.leader)
			Continue
		Loop, Parse, A_LoopField
		{
			seed .= IsNumber(A_LoopField) ? A_LoopField : ""
			If seed && !IsNumber(A_LoopField)
				Break 2
		}
	}

	vars.legion.seed := seed, vars.legion.jewel_number := LLK_HasVal(jewels, vars.legion.jewel) ;the url for vilsol's calculator uses numbers to specify the jewel-type
	If (vars.legion.data.1 != vars.legion.jewel || vars.legion.data.2 != vars.legion.seed)
	{
		vars.legion.data := [vars.legion.jewel, vars.legion.seed, []]
		Loop, Parse, % LLK_FileRead("data\global\[legion] " vars.legion.jewel ".csv"), `n, `r
		{
			If !vars.legion.nodes && (A_Index = 1)
				vars.legion.nodes := SubStr(A_LoopField, InStr(A_LoopField, ",") + 1)
			If (SubStr(A_LoopField, 1, InStr(A_LoopField, ",") - 1) = vars.legion.seed)
			{
				Loop, Parse, A_LoopField, `,
					If (A_Index > 1)
						vars.legion.data.3.Push(A_LoopField)
				Break
			}
		}
	}
	vars.legion.jewel_mods := [], vars.legion.decoder_invert := {}
	For index, mod in db.legion.jewels[vars.legion.jewel]["_decoder"]
		vars.legion.jewel_mods.Push(mod), vars.legion.decoder_invert[mod] := index
	vars.legion.jewel_mods := LLK_ArraySort(vars.legion.jewel_mods)
	If vars.legion.jewel_mods.Count()
		Return 1
}

Legion_Tree()
{
	local
	global vars, settings, db
	static toggle := 0

	vars.legion.wait := 1
	If !vars.legion.fSize_tree
		vars.legion.fSize_tree := LLK_FontSizeGet(vars.legion.width/20, width), LLK_FontDimensions(vars.legion.fSize_tree, fHeight, fWidth), vars.legion.fWidth_tree := fWidth, vars.legion.fHeight_tree := fHeight

	toggle := !toggle, GUI_name := "tree" toggle
	Gui, %GUI_name%: New, % "-DPIScale -Caption +LastFound +AlwaysOnTop +ToolWindow +E0x02000000 +E0x00080000 HWNDtree +Owner" Gui_Name(vars.hwnd.legion.main)
	Gui, %GUI_name%: Color, Black
	Gui, %GUI_name%: Margin, 0, 0
	Gui, %GUI_name%: Font, % "s"vars.legion.fSize_tree " cWhite bold", % vars.system.font
	hwnd_old := vars.hwnd.legion_tree.main, vars.hwnd.legion_tree := {"main": tree}

	Gui, %GUI_name%: Add, Pic, % "x" settings.legion.fWidth//2 " y" settings.legion.fWidth//2 " HWNDhwnd h" settings.legion.fHeight " w-1", % "HBitmap:*" vars.pics.global.help
	vars.hwnd.help_tooltips["seed-explorer_tree"] := hwnd

	For socket, val in db.legion.sockets
	{
		hAqua := 0, hYellow := 0, mods := {}
		For index, node in db.legion.sockets[socket].nodes
			mod := db.legion.jewels[vars.legion.jewel]["_decoder"][vars.legion.data.3[vars.legion.nodes[node]]], hYellow += settings.legion.highlights[node] && settings.legion.highlights[mod] ? 1 : 0
		For index, node in db.legion.sockets[socket].nodes
			text := db.legion.jewels[vars.legion.jewel]["_decoder"][vars.legion.data.3[vars.legion.nodes[node]]], mods[text] := mods[text] ? mods[text] + 1 : 1
		For mod, count in mods
			hAqua += settings.legion.highlights[mod] ? count : 0
		Gui, %GUI_name%: Add, Text, % "BackgroundTrans Center cYellow w"vars.legion.fHeight_tree*1.8 " x"val.x * vars.legion.width*2 " y"val.y * vars.legion.width*2, % hYellow ? hYellow : ""
		Gui, %GUI_name%: Add, Text, % "BackgroundTrans Center cAqua w"vars.legion.fHeight_tree*1.8 " x"val.x * vars.legion.width*2 " y+-"vars.legion.fHeight_tree*0.2, % hAqua ? hAqua : ""
		If !vars.pics.legion.socket1
			vars.pics.legion.socket1 := LLK_ImageCache("img\GUI\legion_socket1.jpg"), vars.pics.legion.socket0 := LLK_ImageCache("img\GUI\legion_socket0.jpg")
		Gui, %GUI_name%: Add, Pic, % "BackgroundTrans gLegion HWNDhwnd h"vars.legion.fHeight_tree*1.8 " w-1 x"val.x * vars.legion.width*2 " y"val.y * vars.legion.width*2
		, % "HBitmap:*" vars.pics.legion["socket" (socket = vars.legion.socket ? 1 : 0)]
		vars.hwnd.legion_tree["socket_"socket] := hwnd
	}
	If !vars.pics.legion.treemap
		vars.pics.legion.treemap := LLK_ImageCache("img\GUI\legion_treemap.jpg")
	Gui, %GUI_name%: Add, Pic, % "x0 y0 Border HWNDhwnd w"vars.legion.width*2 - 3 " h-1", % "HBitmap:*" vars.pics.legion.treemap
	vars.hwnd.legion_tree.map := hwnd
	Gui, %GUI_name%: Show, % "NA x" vars.monitor.x " y" vars.monitor.y + vars.monitor.h - vars.legion.width*2
	LLK_Overlay(tree, "show",, GUI_name), LLK_Overlay(hwnd_old, "destroy"), vars.legion.wait := 0
	Gui, %GUI_name%: -Owner
}

Legion_Update()
{
	local
	global vars, settings

	jewels := ["glorious vanity", "lethal pride", "brutal restraint", "militant faith", "elegant hubris"]
	For index, val in jewels
		If FileExist("data\global\[legion] " val ".csv")
			count := !count ? 1 : count + 1

	Try version_check := HTTPtoVar("https://raw.githubusercontent.com/Lailloken/Lailloken-UI/" (settings.general.dev_env ? "dev" : "main") "/data/global/%5Blegion%5D%20version.txt")
	If Blank(version_check) || InStr(version_check, "404: not found")
	{
		LLK_ToolTip(Lang_Trans("global_error") ": version-check", 2,,,, "Red")
		Return
	}
	version_online := StrReplace(StrReplace(version_check, "`n"), "`r")

	If (count = 5)
	{
		update := (version_online > settings.legion.version) ? 1 : 0
		If !update
			LLK_ToolTip(Lang_Trans("seed_uptodate"),,,,, "Lime")
	}

	If (count != 5) || update
	{
		LLK_ToolTip("downloading...", 0,,, "legion_update", "Lime")
		GuiControl, +cGreen, % vars.hwnd.legion.update_bar
		GuiControl, movedraw, % vars.hwnd.legion.update_bar
		GuiControl,, % vars.hwnd.legion.update_bar, 0
		For index, val in jewels
		{
			UrlDownloadToFile, % "https://raw.githubusercontent.com/Lailloken/Lailloken-UI/" (settings.general.dev_env ? "dev" : "main") "/data/global/%5Blegion%5D%20" StrReplace(val, " ", "%20") ".csv", % "data\global\[legion] " val ".csv"
			If ErrorLevel
			{
				error := 1
				GuiControl, +cRed, % vars.hwnd.legion.update_bar
				GuiControl, movedraw, % vars.hwnd.legion.update_bar
				Break
			}
			Else GuiControl,, % vars.hwnd.legion.update_bar, % index
		}
		vars.tooltip[vars.hwnd["tooltiplegion_update"]] := A_TickCount
		If !error
		{
			IniWrite, % (settings.legion.version := version_online), ini\seed-explorer.ini, settings, version
			vars.legion := {}, Legion_Parse(), Legion_GUI(), LLK_ToolTip(Lang_Trans("global_success"), 1,,,, "Lime")
		}
		Else LLK_ToolTip(Lang_Trans("global_error"), 2,,, "Red")
	}
}
