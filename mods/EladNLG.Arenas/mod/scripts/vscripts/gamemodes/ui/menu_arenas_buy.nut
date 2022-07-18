global function Arenas_Buy_Init
global function Econ_AddPriceOverride
global function Econ_RemovePriceOverride
global function Econ_OpenBuyMenu
global function Econ_CloseBuyMenu
global function Econ_GetWeaponAmmoPrice
global function Econ_GetWeaponPrice
global function Econ_GetWeaponBaseAmmo
global function Econ_GetWeaponAmmoSize
global function Econ_SetMoney

global function Econ_ResetWeaponData
global function Econ_AddModsToWeapon_ShopTest 
global function Econ_SetClientWeaponData
global function Econ_UI_BuyWeapon
global function Econ_PlayerHasWeapon

global function Econ_NewPurchase
global function Econ_ResetCustomPurchases
global function Econ_ResetConsumables

global function SuitToSpecial

const int CUSTOM_PURCHASE_BUTTONS = 5

struct EconWeaponData
{
    int ammo,
    string className,
    array<string> mods
}

struct
{
    var menu
    EconWeaponData primary
    EconWeaponData secondary
    EconWeaponData weapon3
    EconWeaponData tactical
    EconWeaponData ordnance
    int curSlotEditing = -1
    int money = 0
    table<var, string> buttonToPurchaseId
    table<string, int> customPrices
    int customPurchasesUsed = 0

} file

void function Arenas_Buy_Init()
{
    print("hi")
    AddMenu( "ArenasBuyMenu", $"resource/ui/menus/arenas_buy.menu", InitArenasMenu )
}

void function Econ_SetMoney( int money )
{
    file.money = money
    Hud_SetText( Hud_GetChild( file.menu, "ButtonMoney"), "^FFC81900" + file.money + "$" )
}

void function InitArenasMenu()
{
    print("we meet again")

    AddUICallback_OnLevelInit( Econ_ResetCustomPurchases )

    file.menu = GetMenu( "ArenasBuyMenu" )
    AddMenuEventHandler( file.menu, eUIEvent.MENU_OPEN, OnMenuOpened )
	AddMenuEventHandler( file.menu, eUIEvent.MENU_CLOSE, OnMenuClosed )
	AddMenuFooterOption( file.menu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonPrimary"), UIE_CLICK, void function (var button) : () {
        file.curSlotEditing = 0
        Econ_SetWeaponBudget( file.money + Econ_CalculateWeaponWorth( 0, file.primary ) )
        AdvanceMenu( GetMenu( "EconWeaponSelect" ) ) 
    } )
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonSecondary"), UIE_CLICK, void function (var button) : () {
        file.curSlotEditing = 1
        Econ_SetWeaponBudget( file.money + Econ_CalculateWeaponWorth( 1, file.secondary ) )
        AdvanceMenu( GetMenu( "EconWeaponSelect" ) ) 
    } )
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonWeapon3"), UIE_CLICK, void function (var button) : () {
        file.curSlotEditing = 2
        Econ_SetWeaponBudget( file.money + Econ_CalculateWeaponWorth( 2, file.weapon3 ) )
        AdvanceMenu( GetMenu( "EconWeaponSelect" ) ) 
    }  )
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonSuit"), UIE_CLICK, void function( var button ) : (){
        SetWeaponArray( [ "geist", "medium", "grapple", "nomad", "heavy", "light", "stalker"])
        file.curSlotEditing = 3
        Econ_SetWeaponBudget( file.money + Econ_CalculateWeaponWorth( 3, file.tactical ) )
        AdvanceMenu( GetMenu( "EconWeaponSelect" ) )
    } )
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonOrdnance"), UIE_CLICK, void function( var button ) : (){
        SetWeaponArray( [ "mp_weapon_frag_grenade", "mp_weapon_grenade_emp", "mp_weapon_thermite_grenade", "mp_weapon_grenade_gravity", "mp_weapon_grenade_electric_smoke", "mp_weapon_satchel"])
        file.curSlotEditing = 4
        Econ_SetWeaponBudget( file.money + Econ_CalculateWeaponWorth( 4, file.ordnance ) )
        AdvanceMenu( GetMenu( "EconWeaponSelect" ) )
    } )

    // primary buy ammo/sell
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonPrimaryBuyAmmo"), UIE_CLICK, void function( var button ) : (){
        Econ_UI_BuyWeaponAmmo( 0, file.primary )
    } )
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonPrimarySell"), UIE_CLICK, void function( var button ) : (){
        Econ_UI_SellWeapon( 0, file.primary )
    } )

    // secondary buy ammo/sell
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonSecondaryBuyAmmo"), UIE_CLICK, void function( var button ) : (){
        Econ_UI_BuyWeaponAmmo( 1, file.secondary )
    } )
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonSecondarySell"), UIE_CLICK, void function( var button ) : (){
        Econ_UI_SellWeapon( 1, file.secondary )
    } )

    // weapon3 buy ammo/sell
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonWeapon3BuyAmmo"), UIE_CLICK, void function( var button ) : (){
        Econ_UI_BuyWeaponAmmo( 2, file.weapon3 )
    } )
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonWeapon3Sell"), UIE_CLICK, void function( var button ) : (){
        Econ_UI_SellWeapon( 2, file.weapon3 )
    } )
    
    // ordnance buy ammo/sell
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonOrdnanceBuyAmmo"), UIE_CLICK, void function( var button ) : (){
        Econ_UI_BuyWeaponAmmo( 4, file.ordnance )
    } )
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonOrdnanceSell"), UIE_CLICK, void function( var button ) : (){
        Econ_UI_SellWeapon( 4, file.ordnance )
    } )
    
    // tactical buy ammo/sell
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonSuitBuyAmmo"), UIE_CLICK, void function( var button ) : (){
        Econ_UI_BuyWeaponAmmo( 3, file.tactical )
    } )
    Hud_AddEventHandler( Hud_GetChild( file.menu, "ButtonSuitSell"), UIE_CLICK, void function( var button ) : (){
        Econ_UI_SellWeapon( 3, file.tactical )
    } )

    for (int i = 0; i < CUSTOM_PURCHASE_BUTTONS; i++)
    {
        Hud_AddEventHandler( Hud_GetChild( file.menu, "BuyConsumable" + i), UIE_CLICK, void function( var button ) : ( i ){
            if (Hud_IsLocked( button) ) return
            try {
                string id = file.buttonToPurchaseId[button]
                if (!Econ_PlayerHasEnoughMoney( file.customPrices[id] ))
                {
                    return
                }
                Econ_SetMoney( file.money - file.customPrices[id] )
                Hud_SetLocked( button, true )
                ClientCommand( "buy " + id )
            }
            catch (ex)
            {

            }
        } )

        Hud_SetVisible( Hud_GetChild( file.menu, "BuyConsumable" + i), false )
        Hud_SetVisible( Hud_GetChild( file.menu, "BuyConsumable" + i + "Price"), false )
    }

    Hud_SetBarProgress( Hud_GetChild( file.menu, "OrdnanceBarBG"), 1.0 )
    Hud_SetBarProgress( Hud_GetChild( file.menu, "TacticalBarBG"), 1.0 )
}

void function OnMenuOpened()
{
    print("\n\n\n\n\n\n")
	SetBlurEnabled( true )
    if (file.curSlotEditing == -1)
        RunClientScript( "EconUI_GetClientWeapons" )
    SetWeaponArray( ["mp_weapon_rspn101", "mp_weapon_rspn101_og", "mp_weapon_hemlok", "mp_weapon_g2", "mp_weapon_vinson", 
                    "mp_weapon_car", "mp_weapon_alternator_smg", "mp_weapon_hemlok_smg","mp_weapon_r97", 
                    "mp_weapon_lmg", "mp_weapon_lstar", "mp_weapon_esaw",
                    "mp_weapon_sniper", "mp_weapon_doubletake", "mp_weapon_dmr",
                    "mp_weapon_shotgun", "mp_weapon_mastiff",
                    "mp_weapon_smr", "mp_weapon_epg", "mp_weapon_softball", "mp_weapon_pulse_lmg",
                    "mp_weapon_wingman_n", "mp_weapon_shotgun_pistol",
                    "mp_weapon_autopistol", "mp_weapon_semipistol", "mp_weapon_wingman",
                   "mp_weapon_defender", "mp_weapon_mgl", ])// "mp_weapon_arc_launcher", "mp_weapon_peacekraber"])
}

void function OnMenuClosed()
{
    Hud_SetBarProgress( Hud_GetChild( file.menu, "OrdnanceBar"), 0.0 )
    Hud_SetBarProgress( Hud_GetChild( file.menu, "TacticalBar"), 0.0 )
    file.curSlotEditing = -1
}
void function Econ_OpenBuyMenu()
{
    CloseAllMenus()
    AdvanceMenu( GetMenu( "ArenasBuyMenu" ) )
}

void function Econ_CloseBuyMenu()
{
    if (uiGlobal.activeMenu == file.menu || uiGlobal.activeMenu == GetMenu( "EconWeaponSelect" ) )
        CloseAllMenus()
}

void function Econ_ResetWeaponData()
{
    ResetWeapon(0)
    ResetWeapon(1)
    ResetWeapon(2)
    ResetWeapon(3)
    ResetWeapon(4)
}

void function Econ_AddModsToWeapon_ShopTest( int slot, string modSer)
{
    array<string> mods = split( modSer, "\n")

    if (slot == 0)
    {
        file.primary.mods = mods
    }
    else if (slot == 1)
    {
        file.secondary.mods = mods
    }
    else if (slot == 2)
    {
        file.weapon3.mods = mods
    }
    else if (slot == 3)
    {
        file.tactical.mods = mods
    }
    else if (slot == 4)
    {
        file.ordnance.mods = mods
    }
} 

void function Econ_SetClientWeaponData( int slot, string className, int ammo )
{
    printt(slot, className, ammo)
    if (slot == 0)
    {
        file.primary.className = className
        file.primary.ammo = ammo
        RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "ButtonPrimary") ), "buttonImage", GetWeaponInfoFileKeyFieldAsset_Global( className, "menu_icon" ) )

        Hud_SetText( Hud_GetChild( file.menu, "ButtonPrimaryBuyPrice"), "-" + Econ_GetWeaponAmmoPrice( file.primary.className ) + "$" )
        Hud_SetText( Hud_GetChild( file.menu, "ButtonPrimaryAmmo"), string( file.primary.ammo ) )
        if (file.primary.ammo > Econ_GetWeaponBaseAmmo( file.primary.className ))
        {
			int ammoTaken = int( min( Econ_GetWeaponAmmoSize( file.primary.className ), file.primary.ammo - Econ_GetWeaponBaseAmmo(file.primary.className ) ) )
			float ammoFrac = ammoTaken / float( Econ_GetWeaponAmmoSize( file.primary.className ) )
			int money = int( ammoFrac * Econ_GetWeaponAmmoPrice( file.primary.className ) )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonPrimarySellPrice"), "+" + money + "$" )
        }
        else Hud_SetText( Hud_GetChild( file.menu, "ButtonPrimarySellPrice"), "+" + Econ_GetWeaponPrice( file.primary.className ) + "$" )
        return
    }
    if (slot == 1)
    {
        print("hi")
        file.secondary.className = className
        file.secondary.ammo = ammo
        RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "ButtonSecondary") ), "buttonImage", GetWeaponInfoFileKeyFieldAsset_Global( className, "menu_icon" ) )

        Hud_SetText( Hud_GetChild( file.menu, "ButtonSecondaryBuyPrice"), "-" + Econ_GetWeaponAmmoPrice( file.secondary.className ) + "$" )
        Hud_SetText( Hud_GetChild( file.menu, "ButtonSecondaryAmmo"), string( file.secondary.ammo ) )
        if (file.secondary.ammo > Econ_GetWeaponBaseAmmo( file.secondary.className ))
        {
			int ammoTaken = int( min( Econ_GetWeaponAmmoSize( file.secondary.className ), file.secondary.ammo - Econ_GetWeaponBaseAmmo(file.secondary.className ) ) )
			float ammoFrac = ammoTaken / float( Econ_GetWeaponAmmoSize( file.secondary.className ) )
			int money = int( ammoFrac * Econ_GetWeaponAmmoPrice( file.secondary.className ) )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonSecondarySellPrice"), "+" + money + "$" )
        }
        else Hud_SetText( Hud_GetChild( file.menu, "ButtonSecondarySellPrice"), "+" + Econ_GetWeaponPrice( file.secondary.className ) + "$" )
        return
    }
    if (slot == 2)
    {
        file.weapon3.className = className
        file.weapon3.ammo = ammo
        RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "ButtonWeapon3") ), "buttonImage", GetWeaponInfoFileKeyFieldAsset_Global( className, "menu_icon" ) )
        
        Hud_SetText( Hud_GetChild( file.menu, "ButtonWeapon3BuyPrice"), "-" + Econ_GetWeaponAmmoPrice( file.weapon3.className ) + "$" )
        Hud_SetText( Hud_GetChild( file.menu, "ButtonWeapon3Ammo"),string(  file.weapon3.ammo ) )
        if (file.weapon3.ammo > Econ_GetWeaponBaseAmmo( file.weapon3.className ))
        {
			int ammoTaken = int( min( Econ_GetWeaponAmmoSize( file.weapon3.className ), file.weapon3.ammo - Econ_GetWeaponBaseAmmo(file.weapon3.className ) ) )
			float ammoFrac = ammoTaken / float( Econ_GetWeaponAmmoSize( file.weapon3.className ) )
			int money = int( ammoFrac * Econ_GetWeaponAmmoPrice( file.weapon3.className ) )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonWeapon3SellPrice"), "+" + money + "$" )
        }
        else Hud_SetText( Hud_GetChild( file.menu, "ButtonWeapon3SellPrice"), "+" + Econ_GetWeaponPrice( file.weapon3.className ) + "$" )
        return
    }
    if (slot == 3)
    {
        file.tactical.className = className
        file.tactical.ammo = ammo
        if (file.tactical.className == "mp_ability_grapple")
            Hud_SetBarProgress( Hud_GetChild( file.menu, "TacticalBar"), float(file.tactical.ammo) / 100.0 )
        else Hud_SetBarProgress( Hud_GetChild( file.menu, "TacticalBar"), float(file.tactical.ammo) / 4.0 )
        RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "ButtonSuit") ), "buttonImage", GetImage( GetItemType( SpecialToSuit( file.tactical.className ) ), SpecialToSuit( file.tactical.className ) ) )
        if (file.tactical.className == "mp_ability_grapple")
        {
			int ammoTaken = int( min( 25, file.tactical.ammo ) )
			float ammoFrac = ammoTaken / 25.0
			int money = int( ammoFrac * Econ_GetWeaponPrice( file.tactical.className ) )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonSuitSellPrice"), "+" + money + "$" )
        }
        else Hud_SetText( Hud_GetChild( file.menu, "ButtonSuitSellPrice"), "+" + Econ_GetWeaponPrice( file.tactical.className ) + "$" )
        Hud_SetText( Hud_GetChild( file.menu, "ButtonSuitBuyPrice"), "-" + Econ_GetWeaponPrice( file.tactical.className ) + "$" )
        return
    }
    if (slot == 4)
    {
        file.ordnance.className = className
        file.ordnance.ammo = ammo
        Hud_SetBarProgress( Hud_GetChild( file.menu, "OrdnanceBar"), float(file.ordnance.ammo) / 4.0 )
        RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "ButtonOrdnance") ), "buttonImage", GetWeaponInfoFileKeyFieldAsset_Global( className, "menu_icon" ) )
        Hud_SetText( Hud_GetChild( file.menu, "ButtonOrdnanceBuyPrice"), "-" + Econ_GetWeaponPrice( file.ordnance.className ) + "$" )
        Hud_SetText( Hud_GetChild( file.menu, "ButtonOrdnanceSellPrice"), "+" + Econ_GetWeaponPrice( file.ordnance.className ) + "$" )
        return
    }
}

table<string, int> priceOverrides

void function Econ_AddPriceOverride( string weapon, int price )
{
    print("adding price override for " + weapon + ", now " + price )
	priceOverrides[weapon] <- price
}

void function Econ_RemovePriceOverride( string weapon )
{
    delete priceOverrides[weapon]
}

int function Econ_GetWeaponPrice( string weapon )
{
    if (weapon in priceOverrides)
        return priceOverrides[weapon]
    return GetCurrentPlaylistVarInt( "econ_price_" + weapon.slice( 3, weapon.len() ), -1 )
}

int function Econ_GetWeaponAmmoPrice( string weapon )
{
    return GetCurrentPlaylistVarInt( "econ_price_" + weapon.slice( 3, weapon.len() ) + "_ammo", -1 )
}

int function Econ_GetWeaponBaseAmmo( string weapon )
{
    return GetCurrentPlaylistVarInt( "econ_" + weapon.slice( 3, weapon.len() ) + "_stockpile", -1 )
}

int function Econ_GetWeaponAmmoSize( string weapon )
{
    return GetCurrentPlaylistVarInt( "econ_" + weapon.slice( 3, weapon.len() ) + "_ammo_size", -1 )
}

string function SuitToSpecial( string suit )
{
    switch ( suit )
    {
        case "grapple":
            return "mp_ability_grapple"
        case "nomad":
            return "mp_ability_heal"
        case "stalker":
            return "mp_ability_holopilot"
        case "medium":
            return "mp_weapon_grenade_sonar"
        case "heavy":
            return "mp_weapon_deployable_cover"
        case "light":
            return "mp_ability_shifter"
        case "geist":
            return "mp_ability_cloak"
    }
    return suit
}

string function SpecialToSuit( string suit )
{
    switch ( suit )
    {
        case "mp_ability_grapple":
            return "grapple"
        case "mp_ability_heal":
            return "nomad"
        case "mp_ability_holopilot":
            return "stalker"
        case "mp_weapon_grenade_sonar":
            return "medium"
        case "mp_weapon_deployable_cover":
            return "heavy"
        case "mp_ability_shifter":
            return "light"
        case "mp_ability_cloak":
            return "geist"
    }
    return suit
}

void function Econ_UI_BuyWeaponAmmo( int index, EconWeaponData weapon )
{
    if (weapon.className == "")
        return
    if (!Econ_PlayerHasEnoughMoney( Econ_GetWeaponAmmoPrice( weapon.className ) ))
        return
    if (index > 2)
    {
        if (!Econ_PlayerHasEnoughMoney( Econ_GetWeaponPrice( weapon.className ) ))
            return
        Econ_SetMoney( file.money - Econ_GetWeaponPrice( weapon.className ) )
        Econ_SetClientWeaponData( index, weapon.className, weapon.ammo + (weapon.className == "mp_ability_grapple" ? 25 : 1) )
    }
    else {
        Econ_SetMoney( file.money - Econ_GetWeaponAmmoPrice( weapon.className ) )
        Econ_SetClientWeaponData( index, weapon.className, weapon.ammo + Econ_GetWeaponAmmoSize( weapon.className ) )
    }
    ClientCommand( "buy " + weapon.className )
}

void function Econ_UI_BuyWeapon( string weapon )
{

    switch (file.curSlotEditing)
    {
        case 0:
            if (Econ_PlayerHasWeapon(weapon) != -1)
                return
            while (file.primary.className != "")
            {
                Econ_UI_SellWeapon( 0, file.primary, true )
            }
            print("weapon sold, purchasing...")
            
            if (!Econ_PlayerHasEnoughMoney( Econ_GetWeaponPrice( weapon ) ))
                break
            
            Econ_SetMoney( file.money - Econ_GetWeaponPrice( weapon ) )
            ClientCommand( "buy " + weapon + " 0" )

            Econ_SetClientWeaponData( 0, weapon, Econ_GetWeaponBaseAmmo( weapon ) )
            break
        case 1:
            if (Econ_PlayerHasWeapon(weapon) != -1)
                return
            while (file.secondary.className != "")
            {
                Econ_UI_SellWeapon( 1, file.secondary, true )
            }
            print("weapon sold, purchasing...")
            
            if (!Econ_PlayerHasEnoughMoney( Econ_GetWeaponPrice( weapon ) ))
                break
                
            Econ_SetMoney( file.money - Econ_GetWeaponPrice( weapon ) )
            ClientCommand( "buy " + weapon + " 1" )
            print("weboughttheweapon")
            
            if (file.primary.className == "")
            {
                Econ_SetClientWeaponData( 0, weapon, Econ_GetWeaponBaseAmmo( weapon ) )
            print("replacing primary")
                break
            }
            Econ_SetClientWeaponData( 1, weapon, Econ_GetWeaponBaseAmmo( weapon ) )
            print("so we are here")
            break
        case 2:
            print("sup")
            if (Econ_PlayerHasWeapon(weapon) != -1)
                return
            while (file.weapon3.className != "")
            {
                Econ_UI_SellWeapon( 2, file.weapon3, true )
            }
            print("weapon sold, purchasing...")
            if (!Econ_PlayerHasEnoughMoney( Econ_GetWeaponPrice( weapon ) ))
                break
                
            Econ_SetMoney( file.money - Econ_GetWeaponPrice( weapon ) )
            ClientCommand( "buy " + weapon + " 2" )
            print("weboughttheweapon")

            if (file.primary.className == "")
            {
                Econ_SetClientWeaponData( 0, weapon, Econ_GetWeaponBaseAmmo( weapon ) )
                break
            }
            if (file.secondary.className == "")
            {
                Econ_SetClientWeaponData( 1, weapon, Econ_GetWeaponBaseAmmo( weapon ) )
                break
            }
            Econ_SetClientWeaponData( 2, weapon, Econ_GetWeaponBaseAmmo( weapon ) )
            break
        case 3:
            if (Econ_PlayerHasWeapon(weapon) != -1)
                return
            while (file.tactical.className != "")
            {
                Econ_UI_SellWeapon( 3, file.tactical, true )
            }
            print("weapon sold, purchasing...")
            if (Econ_PlayerHasEnoughMoney( Econ_GetWeaponPrice( weapon ) ))
            {
                Econ_SetClientWeaponData( 3, weapon, weapon == "mp_ability_grapple" ? 25 : 1 )
                Econ_SetMoney( file.money - Econ_GetWeaponPrice( weapon ) )
                ClientCommand( "buy " + weapon + " 3" )
            }
            break
        case 4:
            if (Econ_PlayerHasWeapon(weapon) != -1)
                return
            while (file.ordnance.className != "")
            {
                Econ_UI_SellWeapon( 4, file.ordnance, true )
            }
            print("weapon sold, purchasing...")
            if (Econ_PlayerHasEnoughMoney( Econ_GetWeaponPrice( weapon ) ))
            {
                Econ_SetClientWeaponData( 4, weapon, 1 )
                Econ_SetMoney( file.money - Econ_GetWeaponPrice( weapon ) )
                ClientCommand( "buy " + weapon + " 4" )
            }
            break
    }

}

int function Econ_PlayerHasWeapon( string weapon )
{
    if (file.primary.className == weapon)
        return 0
    if (file.secondary.className == weapon)
        return 1
    if (file.weapon3.className == weapon)
        return 2
    if (file.tactical.className == weapon)
        return 3
    if (file.ordnance.className == weapon)
        return 4
    return -1
}

void function Econ_UI_SellWeapon( int index, EconWeaponData weapon, bool doNotCommunicate = false )
{
    if (weapon.className == "") return
    if (index > 2)
    {
        if (weapon.className == "mp_ability_grapple")
        {
            if ( weapon.ammo > 25 )
            {
                int money = Econ_GetWeaponPrice( weapon.className )

                Econ_SetMoney( file.money + money )
                weapon.ammo -= 25
                Econ_SetClientWeaponData( index, weapon.className, weapon.ammo )
                if (!doNotCommunicate) ClientCommand( "sell " + weapon.className )
            }
            else
            {
                Econ_SetMoney( file.money + int(Econ_GetWeaponPrice( weapon.className ) * (weapon.ammo / 25.0)) )
                if (!doNotCommunicate) ClientCommand( "sell " + weapon.className )
                weapon.className = ""
                ResetWeapon( index )
            }
        }
        else if ( weapon.ammo > 1 )
        {
            int money = Econ_GetWeaponPrice( weapon.className )

            Econ_SetMoney( file.money + money )
            weapon.ammo -= 1
            Econ_SetClientWeaponData( index, weapon.className, weapon.ammo )
            if (!doNotCommunicate) ClientCommand( "sell " + weapon.className )
        }
        else
        {
            Econ_SetMoney( file.money + Econ_GetWeaponPrice( weapon.className ) )
            if (!doNotCommunicate) ClientCommand( "sell " + weapon.className )
            weapon.className = ""
            ResetWeapon( index )
        }
    }
    else if ( weapon.ammo > Econ_GetWeaponBaseAmmo( weapon.className ) )
    {
        int ammoTaken = int( min( Econ_GetWeaponAmmoSize( weapon.className ), weapon.ammo - Econ_GetWeaponBaseAmmo(weapon.className ) ) )
        float ammoFrac = ammoTaken / float( Econ_GetWeaponAmmoSize( weapon.className ) )
        int money = int( ammoFrac * Econ_GetWeaponAmmoPrice( weapon.className ) )

        Econ_SetMoney( file.money + money )
        weapon.ammo -= ammoTaken
        Econ_SetClientWeaponData( index, weapon.className, weapon.ammo )
        if (!doNotCommunicate) ClientCommand( "sell " + weapon.className )
    }
    else
    {
        Econ_SetMoney( file.money + Econ_GetWeaponPrice( weapon.className ) )
        if (!doNotCommunicate) ClientCommand( "sell " + weapon.className )
        weapon.className = ""
        ResetWeapon( index )
    }
}

void function ResetWeapon( int index )
{
    print("RESETTING WEAPON " + index )
    switch (index)
    {
        case 0: 
            RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "ButtonPrimary") ), "buttonImage", $"vgui/hud/empty" )
            file.primary.className = ""
            Hud_SetText( Hud_GetChild( file.menu, "ButtonPrimaryBuyPrice"), "" )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonPrimaryAmmo"), "--" )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonPrimarySellPrice"), "" )
            break
        case 1:
            file.secondary.className = ""
            RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "ButtonSecondary") ), "buttonImage", $"vgui/hud/empty" )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonSecondarySellPrice"), "" )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonSecondaryBuyPrice"), "" )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonSecondaryAmmo"), "--" )
            break
        case 2:
            file.weapon3.className = ""
            RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "ButtonWeapon3") ), "buttonImage", $"vgui/hud/empty" )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonWeapon3SellPrice"), "" )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonWeapon3BuyPrice"), "" )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonWeapon3Ammo"), "--" )
            break
        case 3:
            file.tactical.className = ""
            Hud_SetBarProgress( Hud_GetChild( file.menu, "TacticalBar"), 0.0 )
            RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "ButtonSuit") ), "buttonImage", $"vgui/hud/empty" )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonSuitSellPrice"), "" )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonSuitBuyPrice"), "" )
            break
        case 4:
            file.ordnance.className = ""
            RuiSetImage( Hud_GetRui( Hud_GetChild( file.menu, "ButtonOrdnance") ), "buttonImage", $"vgui/hud/empty" )
            Hud_SetBarProgress( Hud_GetChild( file.menu, "OrdnanceBar"), 0.0 )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonOrdnanceBuyPrice"), "" )
            Hud_SetText( Hud_GetChild( file.menu, "ButtonOrdnanceSellPrice"), "" )
            break
    }
}

bool function Econ_PlayerHasEnoughMoney( int amount )
{
    return file.money >= amount
}

int function Econ_CalculateWeaponWorth( int index, EconWeaponData weapon )
{
    if (weapon.className == "") return 0
    int price = Econ_GetWeaponPrice( weapon.className )
    int ammoPrice = Econ_GetWeaponAmmoPrice( weapon.className )
    int ammo = weapon.ammo
    
    if (index > 2) {
        if (weapon.className != "mp_ability_grapple") return weapon.ammo * price
        else return weapon.ammo * price / 25
    }
    else while (ammo > Econ_GetWeaponBaseAmmo( weapon.className ))
    {
        int ammoTaken = int( min( Econ_GetWeaponAmmoSize( weapon.className ), ammo - Econ_GetWeaponBaseAmmo(weapon.className ) ) )
        float ammoFrac = ammoTaken / float( Econ_GetWeaponAmmoSize( weapon.className ) )
        int money = int( ammoFrac * Econ_GetWeaponAmmoPrice( weapon.className ) )

        price += money
        ammo -= ammoTaken
    }

    return price
}

void function Econ_NewPurchase( string id, int price, string name )
{
    if (file.customPurchasesUsed >= CUSTOM_PURCHASE_BUTTONS)
    {
        print("Too many custom purchases")
        return
    }

    Hud_SetVisible( Hud_GetChild( file.menu, "BuyConsumable" + file.customPurchasesUsed ), true )
    Hud_SetVisible( Hud_GetChild( file.menu, "BuyConsumable" + file.customPurchasesUsed + "Price" ), true )
    Hud_SetText( Hud_GetChild( file.menu, "BuyConsumable" + file.customPurchasesUsed + "Price" ), string( price ) + "$" )
    print(price + "$")
    Hud_SetText( Hud_GetChild( file.menu, "BuyConsumable" + file.customPurchasesUsed ), name )
    file.buttonToPurchaseId[Hud_GetChild( file.menu, "BuyConsumable" + file.customPurchasesUsed )] <- id
    file.customPrices[id] <- price
    file.customPurchasesUsed++
}

void function Econ_ResetCustomPurchases()
{
    for (int i = 0; i < CUSTOM_PURCHASE_BUTTONS; i++){
        print("a" + i)
        Hud_SetVisible( Hud_GetChild( file.menu, "BuyConsumable" + i), false )
        Hud_SetVisible( Hud_GetChild( file.menu, "BuyConsumable" + i + "Price"), false )
    }
    foreach (string key, int value in priceOverrides)
        delete priceOverrides[key]
    file.customPurchasesUsed = 0
}

void function Econ_ResetConsumables()
{
	for (int i = 0; i < CUSTOM_PURCHASE_BUTTONS; i++){
        Hud_SetLocked( Hud_GetChild( file.menu, "BuyConsumable" + i), false )
    }
}