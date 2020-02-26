---------------------------------------------------------------------------------------------------
-- User story:
--
-- Description: SDL does not crash if app is re-registered with another AppHMIType after PTU
-- Steps to reproduce:
-- 1) SDL and HMI are started
-- 2) App1 and App2 are registered
-- 3) App1 is unregistered
-- 4) PTU is performed(during PTU AppHMIType was changed for App1)
-- 5) App1 is re-registered
-- SDL does:
-- - a) SDL does not crash
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}

 -- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function unRegister(pAppId)
  local cid = common.mobile.getSession(pAppId):SendRPC("UnregisterAppInterface", {})
  common.mobile.getSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = false, appID = common.app.getHMIId(pAppId) })
end

local function PTUfunc(tbl)
  tbl.policy_table.app_policies[config.application1.registerAppInterfaceParams.fullAppID].AppHMIType = { "DEFAULT" }
end

local function re_registerApp(pAppId)
	local CorIdRAI = common.mobile.getSession(pAppId):SendRPC("RegisterAppInterface", common.app.getParams(pAppId))
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
  { application = { appName = common.app.getParams(pAppId).appName } })
	common.mobile.getSession(pAppId):ExpectResponse(CorIdRAI, { success = true, resultCode = "WARNINGS" })
	common.mobile.getSession(pAppId):ExpectNotification("OnHMIStatus",
		{ hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
    common.mobile.getSession():ExpectNotification("OnPermissionsChange")
end

runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App1", common.registerAppWOPTU, { 1 })
runner.Step("Register App2", common.registerApp, { 2 })
runner.Step("UnRegister App1",unRegister)

runner.Title("Test")
runner.Step("Perform PTU", common.policyTableUpdate, { PTUfunc })
runner.Step("re-Register App1", re_registerApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
