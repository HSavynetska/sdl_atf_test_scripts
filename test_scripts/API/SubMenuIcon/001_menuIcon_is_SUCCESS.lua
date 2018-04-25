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
-- 1) Mobile application sends AddSubMenu request to SDL with valid "menuIcon" parameter.
-- SDL does:
-- 1) Forward  UI.AddSubMenu request params to HMI.
-- 2) Respond with (resultCode: SUCCESS, success:true) to mobile application.
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
		value = "icon.png"
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

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("Activate Application", common.activateApp)
runner.Step("Upload icon file", common.putFile)

runner.Title("Test")
runner.Step("MenuIcon with result code_SUCCESS ", common.AddSubMenu, {allParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
