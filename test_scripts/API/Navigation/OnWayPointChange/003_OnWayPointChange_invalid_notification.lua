---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/28
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Notification_about_changes_to_Destination_or_Waypoints.md
-- Item: Use Case 1: Exception 2 : Received notification about changes to destination or waypoints from HMI is invalid
--
-- Requirement summary:
-- [OnWayPointChange] As a mobile application I want to be able to be notified on changes
-- to Destination or Waypoints based on my subscription
--
-- Description:
-- In case:
-- 1) SDL and HMI are started, Navi interface and embedded navigation source are available on HMI,
--    mobile applications are registered on SDL and subscribed on destination and waypoints changes notification
-- 2) Received notification about changes to destination or waypoints from HMI is invalid

-- SDL must:
-- 1) SDL logs the error internally and ignores such notification without transfering it to any of subscribed mobile applications
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Functions ]]
local function emptyNotification(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", {})
  self.mobileSession1:ExpectNotification("OnWayPointChange"):Times(0)
  common:DelayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Subscribe OnWayPointChange", common.subscribeWayPoints)
runner.Step("OnWayPointChange emptyNotification", emptyNotification)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)