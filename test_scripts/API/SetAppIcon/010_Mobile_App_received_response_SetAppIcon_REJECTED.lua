---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0041-appicon-resumption.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) SDL, HMI are started.
-- 2) Mobile app is registered. Sends  PutFile and valid SetAppIcon requests.
-- 3) HMI responds with REJECTED resultCode to SetAppIcon request. Mobile App received response SetAppIcon(REJECTED).
-- 4) App is re-registered.
-- SDL does:
-- 1) Registers an app successfully, responds to RAI with result code "SUCCESS", "iconResumed" = false.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SetAppIcon/commonIconResumed')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  syncFileName = "icon.png"
}
local requestUiParams = {
  syncFileName = {
    imageType = "DYNAMIC",
    value = common.getPathToFileInStorage(requestParams.syncFileName)
  }
}
local allParams = {
  requestParams = requestParams,
  requestUiParams = requestUiParams
}

--[[ Local Functions ]]
local function setAppIcon_resultCode_REJECTED(params)
  if not pAppId then pAppId = 1 end
  local mobSession = common.getMobileSession(pAppId)
  local cid = mobSession:SendRPC("SetAppIcon", params.requestParams)
  params.requestUiParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("UI.SetAppIcon", params.requestUiParams)
  :Do(function(_,data)
  	-- sending UI.SetAppIcon response
  	common.getHMIConnection():SendResponse(data.id, data.method, "REJECTED", {})
  end)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("App registration with iconResumed = false", common.registerApp, { 1, false })
runner.Step("Upload icon file", common.putFile)
runner.Step("SetAppIcon", common.setAppIcon, { allParams } )
runner.Step("Mobile App received response SetAppIcon(REJECTED)", setAppIcon_resultCode_REJECTED, { allParams } )
runner.Step("App unregistration", common.unregisterAppInterface, { 1 })
runner.Step("App registration with iconResumed = true", common.registerApp, { 1, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
