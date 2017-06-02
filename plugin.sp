#include <sourcemod>
#include <sdktools>
#include <cstrike>

new Handle:GunMenu = INVALID_HANDLE;
new String:secondaryWeapon[MAXPLAYERS + 1][20];
new String:lastSecondaryWeapon[MAXPLAYERS + 1][20];
new bool:gotWeaponThisLifeMenu[MAXPLAYERS + 1];
new armourOffset;
new helmetOffset;

public Plugin:myinfo = {

	name = "Pistol Only",
	author = "Robin Linusson",
	description = "Pistol Only",
	version = "1.0",
	url = "http://www.synt3x.com"

};

public OnPluginStart() {

	armourOffset = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	helmetOffset = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");

	// Pistol Menu
	GunMenu = BuildOptionsMenu();

	// Commands
	RegConsoleCmd("sm_pistol", pistolMenu);
	RegConsoleCmd("sm_pistols", pistolMenu);
	RegConsoleCmd("sm_guns", pistolMenu);

	// Hooks
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);

}

public OnClientDisconnect(client) {

	secondaryWeapon[client] = "";
	lastSecondaryWeapon[client] = "";

}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) {

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	PrintToChat(client, "Type !pistol, !pistols or !guns to choose a new pistol");

}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	gotWeaponThisLifeMenu[client] = false;
	GiveArmorHelm(client);

	if (IsClientInGame(client) && !IsFakeClient(client) && ((Teams:GetClientTeam(client) == CS_TEAM_T) || (Teams:GetClientTeam(client) == CS_TEAM_CT)) && IsPlayerAlive(client)) {

		RemoveWeapon(client);
		GivePlayerItem(client, "weapon_knife");

		if (!(StrEqual(secondaryWeapon[client],""))) {

			GivePlayerItem(client, secondaryWeapon[client]);

		} else {

			GivePlayerItem(client, "weapon_glock");
			DisplayMenu(GunMenu, client, 20)

		}

	}

}

GiveArmorHelm(client) {

	SetEntData(client, armourOffset, 100);
	SetEntData(client, helmetOffset, 1);

}

RemoveWeapon(client) {

    for(new i = 0; i < 4; i++) {

        new ent = GetPlayerWeaponSlot(client, i);

        if (ent != -1) {

            RemovePlayerItem(client, ent);
            RemoveEdict(ent);

        }

    }

}

Handle:BuildOptionsMenu() {

	new Handle:menu = CreateMenu(Menu_Options);
	SetMenuTitle(menu, "Pistol Menu:");
	SetMenuExitButton(menu, false);

	AddMenuItem(menu, "same", "Same Every Round");

	AddMenuItem(menu, "weapon_hkp2000", "HKP-2000");
	AddMenuItem(menu, "weapon_usp_silencer", "USP Silencer");
	AddMenuItem(menu, "weapon_glock", "Glock");
	AddMenuItem(menu, "weapon_p250", "P250");
	AddMenuItem(menu, "weapon_fiveseven", "Five Seven");
	AddMenuItem(menu, "weapon_CZ75", "CZ75 Auto");
	AddMenuItem(menu, "weapon_elite", "Dual Elite");
	AddMenuItem(menu, "weapon_tec9", "Tec9");
	AddMenuItem(menu, "weapon_deagle", "Deagle");

	return menu;

}

public Menu_Options(Handle:menu, MenuAction:action, client, param2) {

	if (action == MenuAction_Select) {

		// Debug what weapon you got
		// decl String:info[20];
		// new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		// PrintToConsole(client, "You selected item: %d (found? %d info: %s)", param2, found, info);
		// You selected item: 0 (found? 1 info: weapon_ak47)
		// You selected item: 4 (found? 1 info: weapon_awp)

		decl String:info[20];
		GetMenuItem(menu, param2, info, sizeof(info));

		if (StrEqual(info,"same")) {

			RemoveWeapon(client);
			GivePlayerItem(client, "weapon_knife");

			if (StrEqual(lastSecondaryWeapon[client],"")) {

				lastSecondaryWeapon[client] = "weapon_glock";

			}

			secondaryWeapon[client] = lastSecondaryWeapon[client];
			GivePlayerItem(client, secondaryWeapon[client]);



		} else {

			RemoveWeapon(client);
			GivePlayerItem(client, "weapon_knife");
			GivePlayerItem(client, info);

			lastSecondaryWeapon[client] = info;
		}

		gotWeaponThisLifeMenu[client] = true;
	}

}

public Action:pistolMenu(client, args) {

	secondaryWeapon[client] = "";

	if (!gotWeaponThisLifeMenu[client]) {

		gotWeaponThisLifeMenu[client] = true;
		DisplayMenu(GunMenu, client, MENU_TIME_FOREVER);

	} else {

		PrintToChat(client, "Pistol menu will appear next time you spawn.");

	}

	return Plugin_Continue;

}
