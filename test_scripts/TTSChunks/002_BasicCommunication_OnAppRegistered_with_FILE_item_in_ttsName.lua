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
-- 2) New app registers with ‘FILE’ item in ‘ttsName’ parameter
-- SDL does:
-- 1) Send BC.OnAppRegistered notification to HMI with ‘FILE’ item in ‘ttsName’ parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TTSChunks/commonTTSChunks')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, {common.hmi_value})

runner.Title("Test")
runner.Step("App registration with 'ttsName':'FILE', HMI receives BC.OnAppRegistered notification with new parameters", common.registerApp, { 1, pttsName})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
