---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0014-adding-audio-file-playback-to-ttschunk.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) HMI provides ‘FILE’ item in ‘speechCapabilities’ parameter of ‘TTS.GetCapabilities’ response
-- 2) New app registers and send SetGlobalProperties with ‘FILE’ item in ‘helpPrompt’, ‘timeoutPrompt’ parameters
-- SDL does:
-- 1) Send TTS.SetGlobalProperties request to HMI with ‘FILE’ item in ‘helpPrompt’, ‘timeoutPrompt’ parameters
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TTSChunks/commonTTSChunks')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local requestParams = {
	helpPrompt = {
		{
			text = "Help prompt",
			type = "FILE"
		}
	},
	timeoutPrompt =	{
		{
			text = "Timeout prompt",
			type = "FILE"
		}
	},
	vrHelpTitle = "VR help title",
	vrHelp = {
		{
			position = 1,
			text = "VR help item"
		}
	},
	menuTitle = "Menu Title",
	keyboardProperties = {
		keyboardLayout = "QWERTY",
		keypressMode = "SINGLE_KEYPRESS",
		limitedCharacterList = {"a"},
		language = "EN-US",
		autoCompleteText = "Daemon, Freedom"
	}
}

local responseUiParams = {
	vrHelpTitle = requestParams.vrHelpTitle,
	menuTitle = requestParams.menuTitle,
	keyboardProperties = requestParams.keyboardProperties
}

local responseTtsParams = {
	timeoutPrompt = requestParams.timeoutPrompt,
	helpPrompt = requestParams.helpPrompt
}

local allParams = {
	requestParams = requestParams,
	responseTtsParams = responseTtsParams
}

--[[ Local Functions ]]
local function setGlobalProperties(params)
	local mobSession = common.getMobileSession()
	local hmiConnection = common.getHMIConnection()
	local cid = mobSession:SendRPC("SetGlobalProperties", params.requestParams)

	EXPECT_HMICALL("UI.SetGlobalProperties", params.responseUiParams)
	:Do(function(_,data)
		hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	params.responseTtsParams.appID = common.getHMIAppId()
	EXPECT_HMICALL("TTS.SetGlobalProperties", params.responseTtsParams)
	:Do(function(_,data)
		hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)

	mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
	mobSession:ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, {common.hmi_value})
runner.Step("App registration", common.registerApp, {1, pttsName})
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile)

runner.Title("Test")
runner.Step("SetGlobalProperties Positive Case", setGlobalProperties, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
