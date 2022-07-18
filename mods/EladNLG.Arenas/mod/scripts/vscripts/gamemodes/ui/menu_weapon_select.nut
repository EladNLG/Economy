untyped

global function Econ_SetHoloShiftActive
global function MenuWeaponSelect_Init
global function SetWeaponArray
global function Econ_SetWeaponBudget
global function InitWeaponMenu


const int BUTTONS_PER_PAGE = 6


struct {
	int deltaX = 0
	int deltaY = 0
} mouseDeltaBuffer

struct {
	int mapsPerPage = 24
	int currentMapPage
	
	array< var > gridInfos
	array< var > gridButtons
	
	array< string > weaponArrayFiltered
	array< string > weaponArray
	
	int scrollOffset = 0
	
	int lastSelectedID
	
	var menu

	int budget

	bool holoShiftActive = false
} file

void function Econ_SetHoloShiftActive(bool active)
{
	file.holoShiftActive = active
}

void function SetWeaponArray( array<string> arr )
{
	file.weaponArray = arr
}

void function Econ_SetWeaponBudget( int budget )
{
	file.budget = budget
}


void function MenuWeaponSelect_Init()
{
	AddMenu( "EconWeaponSelect", $"resource/ui/menus/weapon_select.menu", InitWeaponMenu)
	RegisterSignal( "OnCloseWeaponMenu" )
}

void function InitWeaponMenu()
{
	file.menu = GetMenu( "EconWeaponSelect" )
	
	AddMouseMovementCaptureHandler( file.menu, UpdateMouseDeltaBuffer )
	

	AddMenuEventHandler( file.menu, eUIEvent.MENU_CLOSE, OnCloseWeaponMenu )
	AddMenuEventHandler( file.menu, eUIEvent.MENU_OPEN, OnOpenWeaponMenu )

	

	AddMenuFooterOption( file.menu, BUTTON_A, "#A_BUTTON_SELECT" )
	AddMenuFooterOption( file.menu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )
	
	AddButtonEventHandler( Hud_GetChild( file.menu, "BtnWeaponGridUpArrow"), UIE_CLICK, OnUpArrowSelected )
	AddButtonEventHandler( Hud_GetChild( file.menu, "BtnWeaponGridDownArrow"), UIE_CLICK, OnDownArrowSelected )
	
	AddButtonEventHandler( Hud_GetChild( file.menu, "BtnFiltersClear"), UIE_CLICK, OnBtnFiltersClear_Activate )
	
	AddButtonEventHandler( Hud_GetChild( file.menu, "SwtBtnHideLocked"), UIE_CHANGE, OnFiltersChanged )
	AddButtonEventHandler( Hud_GetChild( file.menu, "BtnMapsSearch"), UIE_CHANGE, OnFiltersChanged )
	
	RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "SwtBtnhideLocked")), "buttonText", "")
	
	file.gridInfos = GetElementsByClassname( file.menu, "WeaponGridInfo" )
	
	file.gridButtons = GetElementsByClassname( file.menu, "WeaponGridButtons" )
	
	AddButtonEventHandler( Hud_GetChild( Hud_GetChild( file.menu , "WeaponGridPanel" ), "DummyTop" ), UIE_GET_FOCUS, OnHitDummyTop )
	AddButtonEventHandler( Hud_GetChild( Hud_GetChild( file.menu , "WeaponGridPanel" ), "DummyBottom" ), UIE_GET_FOCUS, OnHitDummyBottom )
	
	// uhh
	foreach ( var button in file.gridButtons )
	{
		AddButtonEventHandler( button, UIE_CLICK, MapButton_Activate )
		AddButtonEventHandler( button, UIE_GET_FOCUS, MapButton_Focus )
	}
	
	
	FilterMapsArray()
}


// https://youtu.be/VHi2wKBKBc4

void function OnCloseWeaponMenu()
{
	Signal( uiGlobal.signalDummy, "OnCloseWeaponMenu" )
	
	try
	{
		DeregisterButtonPressedCallback(MOUSE_WHEEL_UP , OnScrollUp)
		DeregisterButtonPressedCallback(MOUSE_WHEEL_DOWN , OnScrollDown)
		//DeregisterButtonPressedCallback(KEY_TAB , OnKeyTabPressed)
	}
	catch ( ex ) {}
}

void function OnOpenWeaponMenu()
{
	RefreshList()
	SetBlurEnabled( true )
	
	Hud_SetFocused( file.gridButtons[0] )
	
	RegisterButtonPressedCallback(MOUSE_WHEEL_UP , OnScrollUp)
	RegisterButtonPressedCallback(MOUSE_WHEEL_DOWN , OnScrollDown)
	//RegisterButtonPressedCallback(KEY_TAB , OnKeyTabPressed)
}

void function OnHitDummyTop( var button )
{
	if( file.scrollOffset == 0 )
	{
		Hud_SetFocused( file.gridButtons[ file.lastSelectedID ] )
		return
	}
	
	file.scrollOffset--
	
	UpdateWeaponGrid()
	UpdateListSliderPosition()
	UpdateNextMapInfo()
	
	Hud_SetFocused( file.gridButtons[ file.lastSelectedID ] )
}

void function OnHitDummyBottom( var button )
{
	if ( file.weaponArrayFiltered.len() <= BUTTONS_PER_PAGE || file.weaponArrayFiltered.len() <= 24 )
		return
		
	file.scrollOffset += 1
	
	if ((file.scrollOffset + BUTTONS_PER_PAGE) * 4 > file.weaponArrayFiltered.len())
		file.scrollOffset = (file.weaponArrayFiltered.len() - BUTTONS_PER_PAGE * 4) / 4 + 1
	
	UpdateWeaponGrid()
	UpdateListSliderPosition()
	UpdateNextMapInfo()
	
	int scriptID = file.lastSelectedID
	
	if( scriptID > file.weaponArrayFiltered.len() - 1 - file.scrollOffset * 4 )
		scriptID = file.weaponArrayFiltered.len() - file.scrollOffset * 4 - 1
	
	
	var lastButton = file.gridButtons[ scriptID ]
	
	Hud_SetFocused( lastButton )
}

void function RefreshList()
{
	file.scrollOffset = 0
	FilterMapsArray()
	UpdateWeaponGrid()
	if ( file.weaponArrayFiltered.len() != 0 )
		UpdateMapsInfo( file.weaponArrayFiltered[0] )
	UpdateListSliderHeight()
	UpdateListSliderPosition()
	UpdateNextMapInfo()
}

void function OnFiltersChanged( var button )
{
	FilterMapsArray()
	RefreshList()
}

void function MapButton_Activate( var button )
{
	if ( !AmIPartyLeader() && GetPartySize() > 1 )
		return

	int mapID = int( Hud_GetScriptID(  button  ) )
	string mapName = SuitToSpecial( file.weaponArrayFiltered[ mapID + file.scrollOffset * 4 ] )
	
	if ( IsLocked( SuitToSpecial( mapName ) ) )
		return
	
	printt( mapName, mapID )
	
	Econ_UI_BuyWeapon( mapName )
	CloseActiveMenu()
}

void function MapButton_Focus( var button )
{
	int mapID = int( Hud_GetScriptID(  button  ) )
	string mapName = file.weaponArrayFiltered[ mapID + file.scrollOffset * 4 ]
	
	file.lastSelectedID = mapID
	
	UpdateMapsInfo( mapName )
}

void function OnBtnFiltersClear_Activate( var button )
{
	Hud_SetText( Hud_GetChild( file.menu, "BtnMapsSearch" ), "" )

	SetConVarInt( "filter_map_hide_locked", 0 )
	
	RefreshList()
}

void function UpdateMapsInfo( string map )
{
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "NextMapImage" ) ), "basicImage", map[2] != '_' ? GetImage( GetItemType( map ), map ) : GetWeaponInfoFileKeyFieldAsset_Global( map, "menu_icon" ))
	//Hud_SetText( Hud_GetChild( file.menu, "NextMapDescription" ), GetMapDisplayDesc( map ) )
	Hud_SetText( Hud_GetChild( file.menu, "NextMapName" ), Localize( GetWeaponInfoFileKeyField_GlobalString( SuitToSpecial( map ), "shortprintname" ) ) )
}

void function UpdateNextMapInfo()
{
	array< string > mapsArray = file.weaponArrayFiltered
	
	if( !mapsArray.len() )
		return
	
	var nextMapName = Hud_GetChild( file.menu, "NextMapName" )
	Hud_SetText( nextMapName, GetMapDisplayName( mapsArray[ 0 ] ) )
}

void function UpdateWeaponGrid()
{	
	HideAllMapButtons()
	
	array< string > mapsArray = file.weaponArrayFiltered
	
	
	int trueOffset = file.scrollOffset * 4
	
	foreach ( int _index,  var element in file.gridInfos )
	{
		if ( ( _index + trueOffset ) >= mapsArray.len() ) return
		
		var mapImage = Hud_GetChild( element, "WeaponImage" )
		var mapBorder = Hud_GetChild( element, "WeaponBorders" )
		var mapName = Hud_GetChild( element, "WeaponName" )
		var reserveData = Hud_GetChild( element, "WeaponReserves" )
		var weaponPrice = Hud_GetChild( element, "WeaponPrice" )
		
		string name = mapsArray[ _index + trueOffset ]
		printt( name, name[2] != '_' )
		
		RuiSetImage( Hud_GetRui( mapImage ), "basicImage", name[2] != '_' ? GetImage( GetItemType( name ), name ) : GetWeaponInfoFileKeyFieldAsset_Global( name, "menu_icon" ) )
		switch (SuitToSpecial(name))
		{
			case "mp_weapon_satchel":
				if (GetCurrentPlaylistVarInt( "Satchel", 0 ) != 0)
				{
					Hud_SetText( mapName, "Phase Satchel" )
					break
				}
				Hud_SetText( mapName, GetWeaponInfoFileKeyField_GlobalString( SuitToSpecial( name ), "shortprintname" ) )
				break
			case "mp_ability_holopilot":
				if (file.holoShiftActive)
				{
					Hud_SetText( mapName, "HoloShift" )
					break
				}
			default:
				Hud_SetText( mapName, GetWeaponInfoFileKeyField_GlobalString( SuitToSpecial( name ), "shortprintname" ) )
				break

		}
		Hud_SetText( weaponPrice, "^FFC81900"+ Econ_GetWeaponPrice( SuitToSpecial( name ) ) + "$" )
		if ( file.weaponArray[0] != "geist" && file.weaponArray[0] != "mp_weapon_frag_grenade" )
		{
			string mags = ""
			if (IsWeaponKeyFieldDefined( name, "ammo_clip_size" ))
			{	
				if (GetWeaponInfoFileKeyField_GlobalInt( name, "ammo_clip_size") > 0)
				{
					mags = GetWeaponInfoFileKeyField_GlobalInt( name, "ammo_clip_size") + "/" + Econ_GetWeaponBaseAmmo( name )
				}
				else mags = string(Econ_GetWeaponBaseAmmo( name ))
			}
			else mags = string (Econ_GetWeaponBaseAmmo( name ))
			Hud_SetText( reserveData, "(^FFC81900" + Econ_GetWeaponAmmoPrice( SuitToSpecial( name ) ) + "$^FFFFFF00|"+ Econ_GetWeaponAmmoSize( SuitToSpecial( name ) ) +
			")\n" + mags )
			RuiSetImage( Hud_GetRui( mapImage ), "basicImage", name[2] != '_' ? GetImage( GetItemType( name ), name ) : GetWeaponInfoFileKeyFieldAsset_Global( name, "menu_icon" ) )
			RuiSetImage( Hud_GetRui( mapBorder ), "basicImage", $"vgui/hud/empty" )
		}
		else
		{
			Hud_SetText( reserveData, "" )
			RuiSetImage( Hud_GetRui( mapBorder ), "basicImage", name[2] != '_' ? GetImage( GetItemType( name ), name ) : GetWeaponInfoFileKeyFieldAsset_Global( name, "menu_icon" ) )
			RuiSetImage( Hud_GetRui( mapImage ), "basicImage", $"vgui/hud/empty" )
		}
		
		if ( IsLocked( SuitToSpecial( name ) ) )
			LockMapButton( element )
		
		Hud_SetVisible( file.gridButtons[ _index ], true )
		Hud_SetEnabled( file.gridButtons[ _index ], true )
		MakeMapButtonVisible( element )
	}
}

void function FilterMapsArray()
{
	file.weaponArrayFiltered.clear()
	
	string searchTerm = Hud_GetUTF8Text( Hud_GetChild( file.menu, "BtnMapsSearch" ) )
	
	bool useSearch =  searchTerm != ""
	
	bool hideLocked = bool( GetConVarInt( "filter_map_hide_locked" ) )
	
	foreach ( string weapon in file.weaponArray )
	{
		bool containsTerm = Localize( GetWeaponInfoFileKeyField_GlobalString( SuitToSpecial( weapon ), "shortprintname" ) ).tolower().find( searchTerm.tolower() ) == null ? false : true
		
		if ( hideLocked && !IsLocked( SuitToSpecial( weapon ) ) && ( useSearch == true ? containsTerm : true ) )
		{
			file.weaponArrayFiltered.append( weapon )
		}
		else if ( !hideLocked && ( useSearch == true ? containsTerm : true ) )
		{
			file.weaponArrayFiltered.append( weapon )
		}
	}
}

void function HideAllMapButtons()
{
	foreach ( _index, var element in file.gridInfos )
	{
		Hud_SetVisible( element, false )
		Hud_SetEnabled( element, false )
		
		var mapButton = file.gridButtons[ _index ]
		var mapFG = Hud_GetChild( element, "WeaponNameLockedForeground" )
		
		Hud_SetLocked( mapButton, false )
		Hud_SetVisible( mapButton, false )
		Hud_SetVisible( mapFG, false )
	}
}

// :trol:
void function MakeMapButtonVisible( var element )
{
	Hud_SetVisible( element, true )
}

void function LockMapButton( var element )
{
	var mapFG = Hud_GetChild( element, "WeaponNameLockedForeground" )
	
	Hud_SetVisible( mapFG, true )
}

bool function IsLocked( string map )
{
	
	if ( Econ_GetWeaponPrice( map ) > file.budget )
		return true
	
	if ( Econ_PlayerHasWeapon( map ) != -1 )
		return true
	
	return false
}

//////////////////////////////
// Slider
//////////////////////////////
void function UpdateMouseDeltaBuffer(int x, int y)
{
	mouseDeltaBuffer.deltaX += x
	mouseDeltaBuffer.deltaY += y

	SliderBarUpdate()
}

void function FlushMouseDeltaBuffer()
{
	mouseDeltaBuffer.deltaX = 0
	mouseDeltaBuffer.deltaY = 0
}


void function SliderBarUpdate()
{
	if ( file.weaponArrayFiltered.len() <= BUTTONS_PER_PAGE || file.weaponArrayFiltered.len() <= 24 )
	{
		FlushMouseDeltaBuffer()
		return
	}

	var sliderButton = Hud_GetChild( file.menu , "BtnWeaponGridSlider" )
	var sliderPanel = Hud_GetChild( file.menu , "BtnWeaponGridSliderPanel" )
	var movementCapture = Hud_GetChild( file.menu , "MouseMovementCapture" )

	Hud_SetFocused(sliderButton)

	float minYPos = -42.0 * (GetScreenSize()[1] / 1080.0)
	float maxHeight = 582.0  * (GetScreenSize()[1] / 1080.0)
	float maxYPos = minYPos - (maxHeight - Hud_GetHeight( sliderPanel ))
	float useableSpace = ( maxHeight - Hud_GetHeight( sliderPanel ))

	float jump = minYPos - ( useableSpace / (  file.weaponArrayFiltered.len() / 4 + 1 ))

	// got local from official respaw scripts, without untyped throws an error
	local pos =	Hud_GetPos(sliderButton)[1]
	local newPos = pos - mouseDeltaBuffer.deltaY
	FlushMouseDeltaBuffer()

	if ( newPos < maxYPos ) newPos = maxYPos
	if ( newPos > minYPos ) newPos = minYPos

	Hud_SetPos( sliderButton , 2, newPos )
	Hud_SetPos( sliderPanel , 2, newPos )
	Hud_SetPos( movementCapture , 2, newPos )

	file.scrollOffset = -int( ( (newPos - minYPos) / useableSpace ) * ( file.weaponArrayFiltered.len() / 4 + 1 - BUTTONS_PER_PAGE) )
	UpdateWeaponGrid()
}

void function UpdateListSliderHeight()
{
	var sliderButton = Hud_GetChild( file.menu , "BtnWeaponGridSlider" )
	var sliderPanel = Hud_GetChild( file.menu , "BtnWeaponGridSliderPanel" )
	var movementCapture = Hud_GetChild( file.menu , "MouseMovementCapture" )
	
	float maps = float ( file.weaponArrayFiltered.len() / 4 )

	float maxHeight = 582.0 * (GetScreenSize()[1] / 1080.0)
	float minHeight = 80.0 * (GetScreenSize()[1] / 1080.0)

	float height = maxHeight * ( float( BUTTONS_PER_PAGE ) / maps )

	if ( height > maxHeight ) height = maxHeight
	if ( height < minHeight ) height = minHeight

	Hud_SetHeight( sliderButton , height )
	Hud_SetHeight( sliderPanel , height )
	Hud_SetHeight( movementCapture , height )
}


void function UpdateListSliderPosition()
{
	if ( file.weaponArrayFiltered.len() == 24 )
		return
	
	var sliderButton = Hud_GetChild( file.menu , "BtnWeaponGridSlider" )
	var sliderPanel = Hud_GetChild( file.menu , "BtnWeaponGridSliderPanel" )
	var movementCapture = Hud_GetChild( file.menu , "MouseMovementCapture" )
	
	float maps = float ( file.weaponArrayFiltered.len() / 4 + 1 )

	float minYPos = -42.0 * (GetScreenSize()[1] / 1080.0)
	float useableSpace = (582.0 * (GetScreenSize()[1] / 1080.0) - Hud_GetHeight( sliderPanel ))

	float jump = minYPos - ( useableSpace / ( maps - float( BUTTONS_PER_PAGE ) ) * file.scrollOffset )

	//jump = jump * (GetScreenSize()[1] / 1080.0)

	if ( jump > minYPos ) jump = minYPos

	Hud_SetPos( sliderButton , 2, jump )
	Hud_SetPos( sliderPanel , 2, jump )
	Hud_SetPos( movementCapture , 2, jump )
}

void function OnDownArrowSelected( var button )
{
	if ( file.weaponArrayFiltered.len() <= BUTTONS_PER_PAGE || file.weaponArrayFiltered.len() <= 24 ) return
	file.scrollOffset += 1
	if ((file.scrollOffset + BUTTONS_PER_PAGE) * 4 > file.weaponArrayFiltered.len()) {
		file.scrollOffset = (file.weaponArrayFiltered.len() - BUTTONS_PER_PAGE * 4) / 4 + 1
	}
	UpdateWeaponGrid()
	UpdateListSliderPosition()
}


void function OnUpArrowSelected( var button )
{
	file.scrollOffset -= 1
	if (file.scrollOffset < 0) {
		file.scrollOffset = 0
	}
	UpdateWeaponGrid()
	UpdateListSliderPosition()
}

void function OnScrollDown( var button )
{
	if ( file.weaponArrayFiltered.len() <= BUTTONS_PER_PAGE || file.weaponArrayFiltered.len() <= 24 ) return
	file.scrollOffset += 2
	if ((file.scrollOffset + BUTTONS_PER_PAGE) * 4 > file.weaponArrayFiltered.len()) {
		file.scrollOffset = (file.weaponArrayFiltered.len() - BUTTONS_PER_PAGE * 4) / 4 + 1
	}
	UpdateWeaponGrid()
	UpdateListSliderPosition()
}

void function OnScrollUp( var button )
{
	file.scrollOffset -= 2
	if (file.scrollOffset < 0) {
		file.scrollOffset = 0
	}
	UpdateWeaponGrid()
	UpdateListSliderPosition()
}