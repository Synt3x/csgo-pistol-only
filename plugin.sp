#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.5"
#define WEAPON_NAME_LENGTH 32
#define FALLBACK_WEAPON "weapon_usp_silencer"

enum struct Pistol {
	char weapon[WEAPON_NAME_LENGTH]; // Entity class name, e.g. "weapon_glock"
	char name[WEAPON_NAME_LENGTH];   // Menu label
	int defindex;                    // Item definition index, to check what was given
}

// Pistols that can be chosen, in menu order
static const Pistol PISTOLS[] = {
	{ "weapon_glock",        "Glock",        4 },
	{ "weapon_hkp2000",      "HKP-2000",     32 },
	{ "weapon_usp_silencer", "USP Silencer", 61 },
	{ "weapon_p250",         "P250",         36 },
	{ "weapon_fiveseven",    "Five Seven",   3 },
	{ "weapon_cz75a",        "CZ75 Auto",    63 },
	{ "weapon_elite",        "Dual Elite",   2 },
	{ "weapon_tec9",         "Tec9",         30 },
	{ "weapon_deagle",       "Deagle",       1 },
	{ "weapon_revolver",     "R8 Revolver",  64 }
};

Menu dialog = null;

char defaultWeapon[WEAPON_NAME_LENGTH];
char currentWeapon[MAXPLAYERS + 1][WEAPON_NAME_LENGTH];

bool receiveDialog[MAXPLAYERS + 1];
bool receivedWeaponOnSpawnFromMenu[MAXPLAYERS + 1];
bool shownSpawnHint[MAXPLAYERS + 1];

// What bots get on spawn (sm_pistolonly_bots)
enum BotMode {
	BotMode_Off,    // 0: leave bots alone
	BotMode_Random, // 1: random pistol every spawn
	BotMode_Fixed   // pistol name: always that pistol
};

BotMode botMode = BotMode_Random;
char botWeapon[WEAPON_NAME_LENGTH];

ConVar cvarDefaultWeapon;
ConVar cvarDebug;
ConVar cvarBots;

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

	// Settings, saved to cfg/sourcemod/pistol_only.cfg
	CreateConVar("sm_pistolonly_version", PLUGIN_VERSION, "Pistol Only version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarDefaultWeapon = CreateConVar("sm_pistolonly_default", FALLBACK_WEAPON, "Pistol for players who haven't chosen one, e.g. weapon_glock or weapon_deagle");
	cvarDebug = CreateConVar("sm_pistolonly_debug", "0", "1 = print menu picks to the player's console", _, true, 0.0, true, 1.0);
	cvarBots = CreateConVar("sm_pistolonly_bots", "1", "Bot pistols: 1 = random every spawn, 0 = off, or a pistol name, e.g. weapon_deagle");
	cvarDefaultWeapon.AddChangeHook(OnDefaultWeaponChanged);
	cvarBots.AddChangeHook(OnBotsChanged);
	AutoExecConfig(true, "pistol_only");
	UpdateDefaultWeapon();
	UpdateBotMode();

	// Register chat commands for opening the pistol menu
	RegConsoleCmd("sm_gun", changeWeapon);
	RegConsoleCmd("sm_guns", changeWeapon);
	RegConsoleCmd("sm_pistol", changeWeapon);
	RegConsoleCmd("sm_pistols", changeWeapon);

	// Listen for player spawns
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
}

public void OnConfigsExecuted() {
	UpdateDefaultWeapon();
	UpdateBotMode();
}

public void OnDefaultWeaponChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	UpdateDefaultWeapon();
}

public void OnBotsChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	UpdateBotMode();
}

// Read a ConVar as a weapon name, accepting names without "weapon_", e.g. "deagle"
void GetWeaponConVar(ConVar convar, char[] value, int maxlength) {
	convar.GetString(value, maxlength);
	TrimString(value);

	if (value[0] != '\0' && StrContains(value, "weapon_") != 0) {
		Format(value, maxlength, "weapon_%s", value);
	}
}

// Read sm_pistolonly_bots: 0 = off, 1 = random, or a pistol name
void UpdateBotMode() {
	char value[WEAPON_NAME_LENGTH];
	cvarBots.GetString(value, sizeof(value));
	TrimString(value);

	if (StrEqual(value, "0")) {
		botMode = BotMode_Off;
		return;
	}

	if (StrEqual(value, "1")) {
		botMode = BotMode_Random;
		return;
	}

	GetWeaponConVar(cvarBots, value, sizeof(value));
	if (FindPistol(value) == -1) {
		LogError("sm_pistolonly_bots \"%s\" is not 0, 1 or a pistol from the menu, using random pistols", value);
		botMode = BotMode_Random;
		return;
	}

	botMode = BotMode_Fixed;
	strcopy(botWeapon, sizeof(botWeapon), value);
}

// Read sm_pistolonly_default, falling back to the USP-S if it isn't a menu pistol
void UpdateDefaultWeapon() {
	char value[WEAPON_NAME_LENGTH];
	GetWeaponConVar(cvarDefaultWeapon, value, sizeof(value));

	if (FindPistol(value) == -1) {
		LogError("sm_pistolonly_default \"%s\" is not a pistol from the menu, using %s", value, FALLBACK_WEAPON);
		strcopy(value, sizeof(value), FALLBACK_WEAPON);
	}

	strcopy(defaultWeapon, sizeof(defaultWeapon), value);
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

	// Only handle players on T or CT who are alive and in game
	if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client)) {
		return;
	}

	int team = GetClientTeam(client);
	if (team != CS_TEAM_T && team != CS_TEAM_CT) {
		return;
	}

	// Bots get their pistol without the menu
	if (IsFakeClient(client)) {
		GiveBotPistol(client);
		return;
	}

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

// Give a bot its pistol and armor, based on sm_pistolonly_bots
void GiveBotPistol(int client) {
	if (botMode == BotMode_Off) {
		return;
	}

	if (botMode == BotMode_Random) {
		GivePistol(client, PISTOLS[GetRandomInt(0, sizeof(PISTOLS) - 1)].weapon);
	} else {
		GivePistol(client, botWeapon);
	}

	GiveArmorToPlayer(client);
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
		if (given != PISTOLS[index].defindex) {
			LogError("Asked for %s (item %d) but %N got item %d", weapon, PISTOLS[index].defindex, client, given);
		}
	}
}

// Return the position of a weapon in PISTOLS, or -1 if it isn't a pistol
int FindPistol(const char[] weapon) {
	for (int i = 0; i < sizeof(PISTOLS); i++) {
		if (StrEqual(PISTOLS[i].weapon, weapon)) {
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

	for (int i = 0; i < sizeof(PISTOLS); i++) {
		menu.AddItem(PISTOLS[i].weapon, PISTOLS[i].name);
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
		if (cvarDebug.BoolValue) {
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
