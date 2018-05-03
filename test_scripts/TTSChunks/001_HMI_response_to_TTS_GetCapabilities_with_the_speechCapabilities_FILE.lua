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
-- 2) New app registers
-- SDL does:
-- 1) Send ‘RegisterAppInterface’ response to mobile app with ‘FILE’ item in ‘speechCapabilities’ parameter
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TTSChunks/commonTTSChunks')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)

runner.Title("Test")
runner.Step("Start SDL, start HMI, HMI responds to the TTS.GetCapabilities with 'speechCapabilities':'FILE', connect Mobile, start Session", common.start, {common.hmi_value})
runner.Step("SDL respond to mobile app with 'speechCapabilities':'FILE' parameter", common.registerApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions) 
