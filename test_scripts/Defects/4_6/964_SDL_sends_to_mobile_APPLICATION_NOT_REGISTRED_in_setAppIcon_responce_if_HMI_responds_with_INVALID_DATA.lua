---------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/964
--
-- Precondition:
-- SDL Core and HMI are started. App is registered, HMI level = FULL
-- Description:
-- Steps to reproduce:
-- 1) Mobile app sends PutFile(request).
-- 2) Mobile app sends invalid SetAppIcon(requests).
-- Expected:
-- 1) Respond successfully processed PutFile requests.
-- 2) Send to mobile resultCode(INVALID_DATA) which was sent to SDL by HMI.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require("user_modules/utils")

--[[ Local Variables ]]
local function getConfigAppParams(pAppId)
  if not pAppId then pAppId = 1 end
  return config["application" .. pAppId].registerAppInterfaceParams
end

local function getPathToFileInStorage(pFileName, pAppId)
  if not pAppId then pAppId = 1 end
  return commonPreconditions:GetPathToSDL() .. "storage/"
    .. getConfigAppParams(pAppId).appID .. "_"
    .. utils.getDeviceMAC() .. "/" .. pFileName
end

local function putFile(self)
  local cid = self.mobileSession1:SendRPC( "PutFile",
    {syncFileName = "\\syncFileName", fileType = "GRAPHIC_PNG", persistentFile = false, systemFile = false},
  "files/\\syncFileName")

  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

local requestParams = { syncFileName = "\\syncFileName" } -- invalid type of parameter

local requestUiParams = {
  syncFileName = {
    imageType = "DYNAMIC",
    value = getPathToFileInStorage(requestParams.syncFileName)
  }
}

local allParams = {requestParams = requestParams, requestUiParams = requestUiParams }

local function setAppIcon_INVALID_DATA(pParams, self)
  local cid = self.mobileSession1:SendRPC("SetAppIcon", pParams.requestParams)
  pParams.requestUiParams.appID = common.getHMIAppId()
  EXPECT_HMICALL("UI.SetAppIcon", pParams.requestUiParams)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
    end)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_ptu_n)
runner.Step("Activate App", common.activate_app)
runner.Step("Upload icon file", putFile)

runner.Title("Test")
runner.Step("SetAppIcon sends invalid type of parameter", setAppIcon_INVALID_DATA, { allParams })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
