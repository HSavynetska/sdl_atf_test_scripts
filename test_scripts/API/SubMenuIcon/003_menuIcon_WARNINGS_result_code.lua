---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0085-submenu-icon.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) Mobile application sends AddSubMenu request to SDL with "menuIcon"= icon.png  -  ("Icon.png" is missing on the system, it was not added via PutFile) .
-- SDL does:
-- 1) Forward UI.AddSubMenu request <image> to HMI and HMI respond with "resultCode": WARNINGS  .
-- 2) Transfer WARNINGS (success:true) to mobile application.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SubMenuIcon/commonSubMenuIcon')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
	menuID = 1000,
	position = 500,
	menuName ="SubMenupositive",
	menuIcon = {
		imageType = "DYNAMIC",
		value = "action.png"
	}
}

local responseUiParams = {
	menuID = requestParams.menuID,
	menuParams = {
		position = requestParams.position,
		menuName = requestParams.menuName,
	},
	menuIcon = requestParams.menuIcon
}

local allParams = {
	requestParams = requestParams,
	responseUiParams = responseUiParams
}

local function addSubMenu_WARNINGS(params, pSuccess)
  local mobSession = common.getMobileSession()
  local cid = mobSession:SendRPC("AddSubMenu", params.requestParams)
  EXPECT_HMICALL("UI.AddSubMenu", params.requestUiParams)
  :Do(function(_,data)
  	common.getHMIConnection():SendResponse(data.id, data.method, "WARNINGS", {})
  end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "WARNINGS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("Activate Application", common.activateApp)

runner.Title("Test")
runner.Step("MenuIcon with result code_WARNINGS", addSubMenu_WARNINGS, {allParams, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
