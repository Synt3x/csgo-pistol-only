#include <cstrike>
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

new Handle:dialog = INVALID_HANDLE;

#define WEAPON_NAME_LENGTH 32

new String:defaultWeapon[WEAPON_NAME_LENGTH];
new String:currentWeapon[MAXPLAYERS + 1][WEAPON_NAME_LENGTH];

new bool:receiveDialog[MAXPLAYERS + 1];
new bool:receivedWeaponOnSpawnFromMenu[MAXPLAYERS + 1];
new bool:shownSpawnHint[MAXPLAYERS + 1];
new bool:debugmode = false;

public Plugin:myinfo =  {
	name = "Pistol Only",
	author = "Robin Linusson",
	description = "Pistol Only for Counter-Strike:Global Offensive",
	version = PLUGIN_VERSION,
	url = "https://github.com/Synt3x/csgo-pistol-only"
};

public OnPluginStart() {

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

// Show the pistol menu by default to players who join
public OnClientPutInServer(client) {
	receiveDialog[client] = true;
}

// Reset stored player data when they leave the server
public OnClientDisconnect(client) {
	currentWeapon[client] = "";
	receiveDialog[client] = true;
	receivedWeaponOnSpawnFromMenu[client] = false;
	shownSpawnHint[client] = false;
}

public EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {

	// Wait one frame so the game's own spawn weapons don't override ours
	RequestFrame(OnPlayerSpawnFrame, GetEventInt(event, "userid"));
}

public OnPlayerSpawnFrame(any:userid) {

	// Get the client who spawned (0 if they left during the frame)
	new client = GetClientOfUserId(userid);

	// Only handle real players on T or CT who are alive and in game
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client) && (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)) {

		// Use the default pistol if the player hasn't chosen one yet
		if (currentWeapon[client][0] == '\0') {
			currentWeapon[client] = defaultWeapon;
		}

		// Tell the player how to reopen the pistol menu, once per visit
		if (!shownSpawnHint[client]) {
			PrintCommandHint(client);
			shownSpawnHint[client] = true;
		}

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

// Tell the player how to open the pistol menu
PrintCommandHint(client) {
	PrintToChat(client, "Type !gun, !guns, !pistol or !pistols to choose a new pistol");
}

public GiveArmorToPlayer(client) {
	SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
	SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
}

public RemoveWeaponsFromPlayer(client) {

	// Slots 0-3: primary, secondary, knife, grenades (slot 4, the bomb, is kept)
	for (new i = 0; i <= 3; i++) {
		new entity;

		// A slot can hold several items (e.g. grenades), so empty it completely
		while ((entity = GetPlayerWeaponSlot(client, i)) != -1) {
			if (!RemovePlayerItem(client, entity)) {
				break;
			}

			// Delete the weapon so it isn't left behind in the world
			AcceptEntityInput(entity, "Kill");
		}
	}
}

public Action:changeWeapon(client, args) {

	// The server console can't use menus
	if (client == 0) {
		ReplyToCommand(client, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	receiveDialog[client] = true;

	if (receivedWeaponOnSpawnFromMenu[client]) {
		PrintToChat(client, "Pistol menu will appear next time you spawn.");
	} else {
		DisplayMenu(dialog, client, MENU_TIME_FOREVER);
	}

	return Plugin_Handled;
}

// Create the pistol selection menu
Handle:PistolMenu() {

	new Handle:menu = CreateMenu(PistolMenuFunction);
	SetMenuTitle(menu, "Pistol Menu:");
	SetMenuExitButton(menu, false);

	AddMenuItem(menu, "same", "Keep current pistol");

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
		decl String:selectedWeapon[WEAPON_NAME_LENGTH];
		GetMenuItem(menu, item, selectedWeapon, sizeof(selectedWeapon));

		// Print debug information about the selected weapon
		if (debugmode) {
			PrintToConsole(client, "You selected item: '%d'. You selected weapon: '%s'.",item, selectedWeapon);
		}

		// If the player selected "same", keep the same pistol and stop showing the menu
		if (StrEqual(selectedWeapon,"same")) {
			receiveDialog[client] = false;
			PrintCommandHint(client);
		} else {

			// Remember the selected pistol for the next spawn
			currentWeapon[client] = selectedWeapon;

			// Dead players and spectators get it when they spawn instead
			new team = GetClientTeam(client);
			if (!IsPlayerAlive(client) || (team != CS_TEAM_T && team != CS_TEAM_CT)) {
				return;
			}

			// Replace the player's current weapons with the selected pistol
			RemoveWeaponsFromPlayer(client);
			GivePlayerItem(client, "weapon_knife");
			GivePlayerItem(client, currentWeapon[client]);

			// Mark that the player already received a pistol from the menu this spawn
			receivedWeaponOnSpawnFromMenu[client] = true;
		}
	}
}
