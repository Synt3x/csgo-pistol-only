#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"
#define WEAPON_NAME_LENGTH 32

// Pistols that can be chosen, in menu order
static const char PISTOL_WEAPONS[][] = {
	"weapon_glock",
	"weapon_hkp2000",
	"weapon_usp_silencer",
	"weapon_p250",
	"weapon_fiveseven",
	"weapon_cz75a",
	"weapon_elite",
	"weapon_tec9",
	"weapon_deagle",
	"weapon_revolver"
};

// Menu labels, in the same order as PISTOL_WEAPONS
static const char PISTOL_NAMES[][] = {
	"Glock",
	"HKP-2000",
	"USP Silencer",
	"P250",
	"Five Seven",
	"CZ75 Auto",
	"Dual Elite",
	"Tec9",
	"Deagle",
	"R8 Revolver"
};

// Item definition indexes, in the same order as PISTOL_WEAPONS
static const int PISTOL_DEFINDEXES[] = {
	4,  // weapon_glock
	32, // weapon_hkp2000
	61, // weapon_usp_silencer
	36, // weapon_p250
	3,  // weapon_fiveseven
	63, // weapon_cz75a
	2,  // weapon_elite
	30, // weapon_tec9
	1,  // weapon_deagle
	64  // weapon_revolver
};

Menu dialog = null;

char defaultWeapon[WEAPON_NAME_LENGTH];
char currentWeapon[MAXPLAYERS + 1][WEAPON_NAME_LENGTH];

bool receiveDialog[MAXPLAYERS + 1];
bool receivedWeaponOnSpawnFromMenu[MAXPLAYERS + 1];
bool shownSpawnHint[MAXPLAYERS + 1];
bool debugmode = false;

public Plugin myinfo = {
	name = "Pistol Only",
	author = "Robin Linusson",
	description = "Pistol Only for Counter-Strike:Global Offensive",
	version = PLUGIN_VERSION,
	url = "https://github.com/Synt3x/csgo-pistol-only"
};

public void OnPluginStart() {

	// Create the pistol selection menu
	dialog = PistolMenu();

	// Set the default pistol
	strcopy(defaultWeapon, sizeof(defaultWeapon), "weapon_glock");

	// Register chat commands for opening the pistol menu
	RegConsoleCmd("sm_gun", changeWeapon);
	RegConsoleCmd("sm_guns", changeWeapon);
	RegConsoleCmd("sm_pistol", changeWeapon);
	RegConsoleCmd("sm_pistols", changeWeapon);

	// Listen for player spawns
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

// Show the pistol menu by default to players who join
public void OnClientPutInServer(int client) {
	receiveDialog[client] = true;
}

// Reset stored player data when they leave the server
public void OnClientDisconnect(int client) {
	currentWeapon[client][0] = '\0';
	receiveDialog[client] = true;
	receivedWeaponOnSpawnFromMenu[client] = false;
	shownSpawnHint[client] = false;
}

public void EventPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {

	// Wait one frame so the game's own spawn weapons don't override ours
	RequestFrame(OnPlayerSpawnFrame, event.GetInt("userid"));
}

public void OnPlayerSpawnFrame(any userid) {

	// Get the client who spawned (0 if they left during the frame)
	int client = GetClientOfUserId(userid);

	// Only handle real players on T or CT who are alive and in game
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client) && (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)) {

		// Use the default pistol if the player hasn't chosen one yet
		if (currentWeapon[client][0] == '\0') {
			strcopy(currentWeapon[client], sizeof(currentWeapon[]), defaultWeapon);
		}

		// Tell the player how to reopen the pistol menu, once per visit
		if (!shownSpawnHint[client]) {
			PrintCommandHint(client);
			shownSpawnHint[client] = true;
		}

		// Replace the player's weapons with knife and pistol, then give armor
		GivePistol(client, currentWeapon[client]);
		GiveArmorToPlayer(client);
		receivedWeaponOnSpawnFromMenu[client] = false;

		// Show the menu unless the player chose to keep using the same pistol
		if (receiveDialog[client]) {
			dialog.Display(client, MENU_TIME_FOREVER);
		}
	}
}

// Tell the player how to open the pistol menu
void PrintCommandHint(int client) {
	PrintToChat(client, "Type !gun, !guns, !pistol or !pistols to choose a new pistol");
}

// Strip the player's weapons, then give a knife and the pistol
void GivePistol(int client, const char[] weapon) {
	RemoveWeaponsFromPlayer(client);
	GivePlayerItem(client, "weapon_knife");

	// Pistols that share a loadout slot (P2000/USP-S, P250/CZ75, Deagle/R8 ...)
	// are swapped for the one in the player's inventory. Without a T/CT team
	// the game has no loadout to use, so the plain weapon is given instead.
	int team = GetEntProp(client, Prop_Send, "m_iTeamNum");
	SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_NONE);
	int entity = GivePlayerItem(client, weapon);
	SetEntProp(client, Prop_Send, "m_iTeamNum", team);

	// Log it if the game still gave a different pistol
	int index = FindPistol(weapon);
	if (entity != -1 && index != -1) {
		int given = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		if (given != PISTOL_DEFINDEXES[index]) {
			LogError("Asked for %s (item %d) but %N got item %d", weapon, PISTOL_DEFINDEXES[index], client, given);
		}
	}
}

// Return the position of a weapon in PISTOL_WEAPONS, or -1 if it isn't a pistol
int FindPistol(const char[] weapon) {
	for (int i = 0; i < sizeof(PISTOL_WEAPONS); i++) {
		if (StrEqual(PISTOL_WEAPONS[i], weapon)) {
			return i;
		}
	}
	return -1;
}

void GiveArmorToPlayer(int client) {
	SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
	SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
}

void RemoveWeaponsFromPlayer(int client) {

	// Slots 0-3: primary, secondary, knife, grenades (slot 4, the bomb, is kept)
	for (int i = 0; i <= 3; i++) {
		int entity;

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

public Action changeWeapon(int client, int args) {

	// The server console can't use menus
	if (client == 0) {
		ReplyToCommand(client, "This command can only be used in-game.");
		return Plugin_Handled;
	}

	receiveDialog[client] = true;

	if (receivedWeaponOnSpawnFromMenu[client]) {
		PrintToChat(client, "Pistol menu will appear next time you spawn.");
	} else {
		dialog.Display(client, MENU_TIME_FOREVER);
	}

	return Plugin_Handled;
}

// Create the pistol selection menu
Menu PistolMenu() {

	Menu menu = new Menu(PistolMenuFunction);
	menu.SetTitle("Pistol Menu:");
	menu.ExitButton = false;

	menu.AddItem("same", "Keep current pistol");

	for (int i = 0; i < sizeof(PISTOL_WEAPONS); i++) {
		menu.AddItem(PISTOL_WEAPONS[i], PISTOL_NAMES[i]);
	}

	return menu;
}

public int PistolMenuFunction(Menu menu, MenuAction action, int client, int item) {

	// Handle the player's menu selection
	if (action == MenuAction_Select) {

		// Read the internal weapon name from the selected menu item
		char selectedWeapon[WEAPON_NAME_LENGTH];
		menu.GetItem(item, selectedWeapon, sizeof(selectedWeapon));

		// Print debug information about the selected weapon
		if (debugmode) {
			PrintToConsole(client, "You selected item: '%d'. You selected weapon: '%s'.", item, selectedWeapon);
		}

		// If the player selected "same", keep the same pistol and stop showing the menu
		if (StrEqual(selectedWeapon, "same")) {
			receiveDialog[client] = false;
			PrintCommandHint(client);
		} else {

			// Remember the selected pistol for the next spawn
			strcopy(currentWeapon[client], sizeof(currentWeapon[]), selectedWeapon);

			// Dead players and spectators get it when they spawn instead
			int team = GetClientTeam(client);
			if (!IsPlayerAlive(client) || (team != CS_TEAM_T && team != CS_TEAM_CT)) {
				return 0;
			}

			// Replace the player's current weapons with the selected pistol
			GivePistol(client, currentWeapon[client]);

			// Mark that the player already received a pistol from the menu this spawn
			receivedWeaponOnSpawnFromMenu[client] = true;
		}
	}

	return 0;
}
