--This script contains all test cases to array TTSChunks Parameter
--How to use:
	--1. local arrayTTSChunksParameter = require('user_modules/shared_testcases/testCasesForArrayTTSChunksParameter')
	--2. arrayTTSChunksParameter:verify_TTSChunks_Parameter(Request, Parameter, Boundary, Mandatory)
---------------------------------------------------------------------------------------------


local testCasesForArrayTTSChunksParameter = {}

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local TTSChunkParameter = require('user_modules/shared_testcases/testCasesForTTSChunkParameter')


---------------------------------------------------------------------------------------------
--Test cases to verify array TTSChunks parameter
---------------------------------------------------------------------------------------------
	--1. IsMissed
	--2. IsEmpty
	--3. IsWrongType
	--4. IsLowerBound
	--5. IsUpperBound
	--6. IsOutLowerBound
	--7. IsOutUpperBound
	--8. Check parameters in side TTSChunk:
		--text: minlength="0" maxlength="500" type="String"
		--type: type="SpeechCapabilities": "TEXT", "SAPI_PHONEMES", "LHPLUS_PHONEMES", "PRE_RECORDED", "SILENCE"

	
	
--Contains all test cases
function testCasesForArrayTTSChunksParameter:verify_TTSChunks_Parameter(Request, Parameter, Boundary, Mandatory)
	
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		--1. IsMissed
		local resultCode = "INVALID_DATA"
		if Mandatory == false then
			resultCode = "SUCCESS"
		end
		
		commonFunctions:TestCase(self, Request, Parameter, "IsMissed", nil, resultCode)		
		
		
		--2. IsWrongDataType
		commonFunctions:TestCase(self, Request, Parameter, "IsWrongDataType", 123, "INVALID_DATA")
		
		
		--3. IsLowerBound
		local verification = "IsLowerBound"
		if Boundary[1] == 0 then
			verification = "IsLowerBound_IsEmpty"
		end
		
		local value = commonFunctions:createTTSChunks("a", "TEXT", Boundary[1])
		commonFunctions:TestCase(self, Request, Parameter, verification, value, "SUCCESS")
		
		
		--4. IsOutLowerBound
		local value = commonFunctions:createTTSChunks("a", "TEXT", Boundary[1]-1)
		if Boundary[1] >= 2 then
			commonFunctions:TestCase(self, Request, Parameter, "IsOutLowerBound", value, "INVALID_DATA")
		elseif Boundary[1] == 1 then		
			commonFunctions:TestCase(self, Request, Parameter, "IsOutLowerBound_IsEmpty", value, "INVALID_DATA")
		else
			--minlength = 0, no check out lower bound
		end
		
		
		--5. IsUpperBound
		local value = commonFunctions:createTTSChunks("a", "TEXT", Boundary[2])
		commonFunctions:TestCase(self, Request, Parameter, "IsUpperBound", value, "SUCCESS")
		
		
		--6. IsOutUpperBound
		local value = commonFunctions:createTTSChunks("a", "TEXT", Boundary[2] + 1)
		commonFunctions:TestCase(self, Request, Parameter, "IsOutUpperBound", value, "INVALID_DATA")
		
		
		--7. Verify TTSChunk
		--text: minlength="0" maxlength="500" type="String"
		--type: type="SpeechCapabilities": "TEXT", "SAPI_PHONEMES", "LHPLUS_PHONEMES", "PRE_RECORDED", "SILENCE"
		
		--Set default parameters for request
		TestingRequest = commonFunctions:cloneTable(RequestParametersValues)
		commonFunctions:setValueForParameter(TestingRequest, Parameter, commonFunctions:createTTSChunks("a", "TEXT", 1))
		
		local parameter_element = commonFunctions:BuildChildParameter(Parameter, 1) -- element #1

		TTSChunkParameter:verify_TTSChunk_Parameter(TestingRequest, parameter_element, true)
		
				
		
end


return testCasesForArrayTTSChunksParameter