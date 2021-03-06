---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Support of "http" flow of Policy Table Update
--
-- Description:
-- SDL should be successfully built with "EXTENDED_POLICY: HTTP" flag
-- 1. Performed steps
-- Build SDL
--
-- Expected result:
-- SDL is successfully built
-- The flag EXTENDED_POLICY is set to HTTP
-- PTU passes successfully
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
config.defaultProtocolVersion = 2
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_ConnectMobile')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_Connect_device()
  self:connectMobile()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Trigger_HTTP_RAI()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
      local RequestIDRai1 = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appName = config.application1.registerAppInterfaceParams.appName } })
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",
        { status = "UPDATE_NEEDED" }, {status = "UPDATING"}):Times(2)

      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "LOCK_SCREEN_ICON_URL"}, {requestType = "HTTP"}):Times(2)

      self.mobileSession:ExpectResponse(RequestIDRai1, { success = true, resultCode = "SUCCESS" })
      self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
end

function Test:TestStep_HTTP_Flow_AfterBuild ()
  commonFunctions:check_ptu_sequence_partly(self, "files/ptu.json", "PolicyTableUpdate")
  --testCasesForPolicyTable:flow_PTU_SUCCEESS_HTTP(self)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
