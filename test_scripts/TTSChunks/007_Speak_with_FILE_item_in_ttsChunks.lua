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
-- 2) New app registers and send Speak with ‘FILE’ item in ‘ttsChunks’ parameter
-- SDL does:
-- 1) Send TTS.Speak request to HMI with ‘FILE’ item in ‘ttsChunks’ parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TTSChunks/commonTTSChunks')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local requestParams = {
	ttsChunks = {
		{
			text ="Speak",
			type = "FILE"
		}
	},
}

local ttsSpeakRequestParams = {
	ttsChunks = requestParams.ttsChunks,
}

local allParams = {
	requestParams = requestParams,
	ttsSpeakRequestParams = ttsSpeakRequestParams
}

local function speakSuccess(params)

	local responseDelay = 3000
	local mobSession = common.getMobileSession()
	local hmiConnection = common.getHMIConnection()
	local cid = mobSession:SendRPC("Speak", params.requestParams)

	params.ttsSpeakRequestParams.appID = common.getHMIAppId()
	EXPECT_HMICALL("TTS.Speak", params.ttsSpeakRequestParams)
	:Do(function(_, data)
			hmiConnection:SendNotification("TTS.Started")
			local speakId = data.id
			local function speakResponse()
				hmiConnection:SendResponse(speakId, "TTS.Speak", "SUCCESS", { })
				hmiConnection:SendNotification("TTS.Stopped")
			end

		RUN_AFTER(speakResponse, responseDelay - 1000)

	end)

	mobSession:ExpectNotification("OnHMIStatus",
		{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED" },
		{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
	:Times(2)
	:Timeout(20000)
	mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
	:Timeout(20000)
end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, {common.hmi_value})
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Upload icon file", common.putFile)

runner.Title("Test")
runner.Step("Speak Positive Case", speakSuccess, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
