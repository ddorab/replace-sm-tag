#include <colorvariables>
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

ConVar gCv_Tag;

char gS_Tag[64];

public Plugin myinfo =
{
	name        = "replace-sm-tag",
	author      = "Keldra",
	description = "",
	version     = "1.0.0",
	url         = "https://github.com/ddorab/replace-sm-tag"
};

public void OnPluginStart()
{
	gCv_Tag = CreateConVar("sm_chat_tag", "");

	HookUserMessage(GetUserMessageId("TextMsg"), Hook_TextMsg, true);

	gCv_Tag.AddChangeHook(OnConVarChanged);

	AutoExecConfig(true, "sm-tag-replace");
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	strcopy(gS_Tag, sizeof(gS_Tag), newValue);
	CProcessVariables(gS_Tag, sizeof(gS_Tag));

	Format(gS_Tag, sizeof(gS_Tag), " %s", gS_Tag);
}

Action Hook_TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (reliable)
	{
		char sBuffer[256];
		PbReadString(msg, "params", sBuffer, sizeof(sBuffer), 0);

		if (StrContains(sBuffer, "[SM]") == 0)
		{
			DataPack pack = new DataPack();

			pack.WriteCell(playersNum);
			for (int i = 0; i < playersNum; i++) pack.WriteCell(players[i]);
			pack.WriteString(sBuffer);

			RequestFrame(Frame_TextMsg, pack);

			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}

void Frame_TextMsg(DataPack pack)
{
	pack.Reset();
	int playersNum = pack.ReadCell();
	int[] players  = new int[playersNum];
	int client;
	int count;

	for (int i = 0; i < playersNum; i++)
	{
		client = pack.ReadCell();
		if (IsClientInGame(client)) players[count++] = client;
	}

	if (count < 0) return;

	playersNum = count;

	char sBuffer[255];
	pack.ReadString(sBuffer, sizeof(sBuffer));
	ReplaceStringEx(sBuffer, sizeof(sBuffer), "[SM]", gS_Tag);

	Handle pb = StartMessage("SayText2", players, playersNum, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);

	PbSetInt(pb, "ent_idx", -1);
	PbSetBool(pb, "chat", true);
	PbSetString(pb, "msg_name", sBuffer);
	PbAddString(pb, "params", "");
	PbAddString(pb, "params", "");
	PbAddString(pb, "params", "");
	PbAddString(pb, "params", "");
	EndMessage();
}