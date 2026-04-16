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

	// Cache the sendprop offsets for armor and helmet
	item_bodyarmor = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
	item_helmet = FindSendPropInfo("CCSPlayer", "m_bHasHelmet");

	// Create the pistol selection menu
	dialog = PistolMenu();

	// Set the default pistol
	defaultWeapon = "weapon_glock";

	// Register chat commands for opening the pistol menu
	RegConsoleCmd("sm_gun", changeWeapon);
	RegConsoleCmd("sm_guns", changeWeapon);
	RegConsoleCmd("sm_pistol", changeWeapon);
	RegConsoleCmd("sm_pistols", changeWeapon);

	// Listen for player spawns
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

// Reset stored player data when they leave the server
public OnClientDisconnect(client) {
	currentWeapon[client] = "";
	previousWeapon[client] = "";
	receiveDialog[client] = true;
	receivedWeaponOnSpawnFromMenu[client] = false;
}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {

	// Get the client who triggered this spawn event
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	// Only handle real players on T or CT who are alive and in game
	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client) && (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)) {

		// Remember the pistol the player used previously
		previousWeapon[client] = currentWeapon[client];

		// Use the default pistol if this is the player's first valid spawn
		if (StrEqual(previousWeapon[client],"")) {
			currentWeapon[client] = defaultWeapon;
		} else {
			currentWeapon[client] = previousWeapon[client];
		}

		// Tell the player how to reopen the pistol menu
		PrintToChat(client, "Type !gun, !guns, !pistol or !pistols to choose a new pistol");

		// Strip current weapons, then give knife, pistol, and armor
		RemoveWeaponsFromPlayer(client);
		GivePlayerItem(client, "weapon_knife");
		GivePlayerItem(client, currentWeapon[client]);
		GiveArmorToPlayer(client);
		receivedWeaponOnSpawnFromMenu[client] = false;

		// Show the menu unless the player chose to keep using the same pistol
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

// Create the pistol selection menu
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

	// Handle the player's menu selection
	if (action == MenuAction_Select) {

		// Read the internal weapon name from the selected menu item
		decl String:selectedWeapon[20];
		GetMenuItem(menu, item, selectedWeapon, sizeof(selectedWeapon));

		// Print debug information about the selected weapon
		if (debugmode) {
			PrintToConsole(client, "You selected item: '%d'. You selected weapon: '%s'.",item, selectedWeapon);
		}

		// If the player selected "same", keep the same pistol every round
		if (StrEqual(selectedWeapon,"same")) {
			receiveDialog[client] = false;
		} else {

			// Replace the player's current weapons with the selected pistol
			currentWeapon[client] = selectedWeapon;
			RemoveWeaponsFromPlayer(client);
			GivePlayerItem(client, "weapon_knife");
			GivePlayerItem(client, currentWeapon[client]);

			// Mark that the player already received a pistol from the menu this spawn
			receivedWeaponOnSpawnFromMenu[client] = true;
		}
	}
}
