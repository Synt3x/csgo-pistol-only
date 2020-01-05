#include <cstrike>
#include <sourcemod>
#include <sdktools>

new Handle:dialog = INVALID_HANDLE;

new String:defaultWeapon[20];
new String:currentWeapon[MAXPLAYERS + 1][20];
new String:previousWeapon[MAXPLAYERS + 1][20];

new bool:receiveDialog[MAXPLAYERS + 1];
new bool:receivedWeaponOnSpawnFromMenu[MAXPLAYERS + 1];
new bool:debugmode = false;

new item_bodyarmor;
new item_helmet;

public Plugin:myinfo =  {
	name = "Pistol Only",
	author = "Robin Linusson",
	description = "Pistol Only for Counter-Strike:Global Offensive",
	version = "1.3",
	url = "http://www.synt3x.com"
};

public OnPluginStart() {

	// Body armor and helmt
	item_bodyarmor = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
	item_helmet = FindSendPropInfo("CCSPlayer", "m_bHasHelmet");

	// Pistol Menu
	dialog = PistolMenu();

	// Default weapon
	defaultWeapon = "weapon_glock";

	// Reg chat commando
	RegConsoleCmd("sm_gun", changeWeapon);
	RegConsoleCmd("sm_guns", changeWeapon);
	RegConsoleCmd("sm_pistol", changeWeapon);
	RegConsoleCmd("sm_pistols", changeWeapon);

	//HookEvent (Listener)
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

// Cleaning up after the player left the server
public OnClientDisconnect(client) {
	currentWeapon[client] = "";
	previousWeapon[client] = "";
	receiveDialog[client] = true;
	receivedWeaponOnSpawnFromMenu[client] = false;
}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {

	// Get the client that we are going to work with
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	// Checks if it's a real player and didn't join spectator
	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client) && (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)) {

		// Keep updating witch weapon we previoused used
		previousWeapon[client] = currentWeapon[client];

		// Player doesn't have any weapon. Maybe because it's first time spawning?
		if (StrEqual(previousWeapon[client],"")) {
			currentWeapon[client] = defaultWeapon;
		} else {
			currentWeapon[client] = previousWeapon[client];
		}

		// Send game instructions to the player
		PrintToChat(client, "Type !gun, !guns, !pistol or !pistols to choose a new pistol");

		// Fix items and armor
		RemoveWeaponsFromPlayer(client);
		GivePlayerItem(client, "weapon_knife");
		GivePlayerItem(client, currentWeapon[client]);
		GiveArmorToPlayer(client);
		receivedWeaponOnSpawnFromMenu[client] = false;

		// Player want to receive previous weapon. Then we don't show him the dialog
		if (receiveDialog[client]) {
			DisplayMenu(dialog, client, MENU_TIME_FOREVER);
		}
	}
}

public GiveArmorToPlayer(client) {
	SetEntData(client, item_bodyarmor, 100);
	SetEntData(client, item_helmet, 1);
}

public RemoveWeaponsFromPlayer(client) {

	for (new i = 0; i <= 3; i++) {
		new entity = GetPlayerWeaponSlot(client, i);

		if (entity != -1) {
			RemovePlayerItem(client, entity);
			//RemoveEdict(entity); should we use this?
		}
	}
}

public Action:changeWeapon(client, args) {

	receiveDialog[client] = true;

	if (receivedWeaponOnSpawnFromMenu[client]) {
		PrintToChat(client, "Pistol menu will appear next time you spawn.");
	} else {
		DisplayMenu(dialog, client, MENU_TIME_FOREVER);
	}

	return Plugin_Continue;
}

// Creating a Menu/Dialog
Handle:PistolMenu() {

	new Handle:menu = CreateMenu(PistolMenuFunction);
	SetMenuTitle(menu, "Pistol Menu:");
	SetMenuExitButton(menu, false);

	AddMenuItem(menu, "same", "Hide Menu");

	AddMenuItem(menu, "weapon_glock", "Glock");
	AddMenuItem(menu, "weapon_hkp2000", "HKP-2000");
	AddMenuItem(menu, "weapon_usp_silencer", "USP Silencer");
	AddMenuItem(menu, "weapon_p250", "P250");
	AddMenuItem(menu, "weapon_fiveseven", "Five Seven");
	AddMenuItem(menu, "weapon_cz75a", "CZ75 Auto");
	AddMenuItem(menu, "weapon_elite", "Dual Elite");
	AddMenuItem(menu, "weapon_tec9", "Tec9");
	AddMenuItem(menu, "weapon_deagle", "Deagle");
	AddMenuItem(menu, "weapon_revolver", "R8 Revolver");

	return menu;
}

public PistolMenuFunction(Handle:menu, MenuAction:action, client, item) {

	// We selected an item, do some magic.
	if (action == MenuAction_Select) {

		// Get the name of the weapon the client selected in the menu
		decl String:selectedWeapon[20];
		GetMenuItem(menu, item, selectedWeapon, sizeof(selectedWeapon));

		// Print information about current weapon selected if debug is enable
		if (debugmode) {
			PrintToConsole(client, "You selected item: '%d'. You selected weapon: '%s'.",item, selectedWeapon);
		}

		//  If player choosed "same" he will get same weapon everyround
		if (StrEqual(selectedWeapon,"same")) {
			receiveDialog[client] = false;
		} else {

			// Remove players weapon and gives the selected one
			currentWeapon[client] = selectedWeapon;
			RemoveWeaponsFromPlayer(client);
			GivePlayerItem(client, "weapon_knife");
			GivePlayerItem(client, currentWeapon[client]);

			// Update boolean so that we can't receive any extra weapon with !pistol
			receivedWeaponOnSpawnFromMenu[client] = true;
		}
	}
}
