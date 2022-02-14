/*
	CustomFont v2.01 (2018-8-25)
	---------------------------------------------------------
	Description: Load font from file or resource, without needed install to system.
	---------------------------------------------------------
	Useage Examples:
		* Load From File
			font1 := New CustomFont("ewatch.ttf")
			Gui, Font, s100, ewatch
		* Load From Resource
			Gui, Add, Text, HWNDhCtrl w400 h200, 12345
			font2 := New CustomFont("res:ewatch.ttf", "ewatch", 80) ; <- Add a res: prefix to the resource name.
			font2.ApplyTo(hCtrl)
		* The fonts will removed automatically when script exits.
		  To remove a font manually, just clear the variable (e.g. font1 := "").
*/
Class CustomFont
{
	static FR_PRIVATE  := 0x10

	__New(FontFile, FontName="", FontSize=30) {
		if RegExMatch(FontFile, "i)res:\K.*", _FontFile)
			this.AddFromResource(_FontFile, FontName, FontSize)
		else
			this.AddFromFile(FontFile)
	}

	AddFromFile(FontFile) {
		if !FileExist(FontFile) {
			throw "Unable to find font file: " FontFile
		}
		DllCall( "AddFontResourceEx", "Str", FontFile, "UInt", this.FR_PRIVATE, "UInt", 0 )
		this.data := FontFile
	}

	AddFromResource(ResourceName, FontName, FontSize = 30) {
		static FW_NORMAL := 400, DEFAULT_CHARSET := 0x1

		nSize    := this.ResRead(fData, ResourceName)
		fh       := DllCall( "AddFontMemResourceEx", "Ptr", &fData, "UInt", nSize, "UInt", 0, "UIntP", nFonts )
		hFont    := DllCall( "CreateFont", Int,FontSize, Int,0, Int,0, Int,0, UInt,FW_NORMAL, UInt,0
		            , Int,0, Int,0, UInt,DEFAULT_CHARSET, Int,0, Int,0, Int,0, Int,0, Str,FontName )

		this.data := {fh: fh, hFont: hFont}
	}

	ApplyTo(hCtrl) {
		SendMessage, 0x30, this.data.hFont, 1,, ahk_id %hCtrl%
	}

	__Delete() {
		if IsObject(this.data) {
			DllCall( "RemoveFontMemResourceEx", "UInt", this.data.fh    )
			DllCall( "DeleteObject"           , "UInt", this.data.hFont )
		} else {
			DllCall( "RemoveFontResourceEx"   , "Str", this.data, "UInt", this.FR_PRIVATE, "UInt", 0 )
		}
	}

	; ResRead() By SKAN, from http://www.autohotkey.com/board/topic/57631-crazy-scripting-resource-only-dll-for-dummies-36l-v07/?p=609282
	ResRead( ByRef Var, Key ) {
		VarSetCapacity( Var, 128 ), VarSetCapacity( Var, 0 )
		If ! ( A_IsCompiled ) {
			FileGetSize, nSize, %Key%
			FileRead, Var, *c %Key%
			Return nSize
		}

		If hMod := DllCall( "GetModuleHandle", UInt,0 )
			If hRes := DllCall( "FindResource", UInt,hMod, Str,Key, UInt,10 )
				If hData := DllCall( "LoadResource", UInt,hMod, UInt,hRes )
					If pData := DllCall( "LockResource", UInt,hData )
						Return VarSetCapacity( Var, nSize := DllCall( "SizeofResource", UInt,hMod, UInt,hRes ) )
							,  DllCall( "RtlMoveMemory", Str,Var, UInt,pData, UInt,nSize )
		Return 0
	}
}