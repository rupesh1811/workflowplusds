package WORKFLOWPLUSDS

public object Utils inherits WORKFLOWPLUSDS::WorkflowPlusDSRoot
	
	function Assoc GetDocuSignTemplates(Object prgCtx) 
		
		CAPILogin 		login
		Dynamic 		data
		Assoc 			retVal
		
		login = prgCtx.GetCAPILogin()
		data = Assoc.CreateAssoc()
		
		data.url = CAPI.IniGet( login, 'Workflowplus', 'docusign_URL' )
		data.username = CAPI.IniGet( login, 'Workflowplus', 'docusign_username' )
		data.password = CAPI.IniGet( login, 'Workflowplus', 'docusign_password' )
		data.integratorKey = CAPI.IniGet( login, 'Workflowplus', 'docusign_key' )
		
		data = JavaObject.InvokeStaticMethod( 'com.yahoo.supai.DocGen', 'getTemplateList', { data })
		
		if IsError( data )
			retVal.ok = FALSE
			retVal.errMsg = Error.ErrorToString( data )
		else
			retVal = data
		end
		
		return retVal
	end
	
	function Assoc OutputData( Object prgCtx, \
									Dynamic ctxOut, \
									Dynamic data, \
									Record request, \
									Integer statCode = 200, \
									String	extraHeaders = "" )
		
		Assoc	retVal
		String	errMsg
		String 	apiError
		String	jsonData = ""
		String	statusStr
		String	headers
		Integer	byteLength
				
		Boolean ok = TRUE
		Boolean	suppressStatusCodes = FALSE
		
		//users have the option of suppressing status codes for the return
		//since some web clients do not support anything besides a 200 status code.
		if ( IsFeature( request, "suppress_response_codes" ) && IsDefined( request.suppress_response_codes ))
		
			suppressStatusCodes = request.suppress_response_codes
		
		end
		
		//if we are suppressing status codes
		//always return 200 OK, and embed the statusCode in the return structure
		
		if ( suppressStatusCodes )
		
			statusStr = "200 OK"
			data.statusCode = statCode
			
		else
		
			statusStr = $RestAPI.RestAPIUtils.StatusCodeToHeader( statCode )
			
		end
		
		//convert the output data to json
		if ( IsDefined( data ))
		
			jsonData = Web.ToJSON( data )
			
		end
		
		if ( IsDefined( jsonData ) && IsNotError( jsonData ))
	
			//calculate the length of the output data in bytes
			byteLength = Str.ByteLength( jsonData )
		
			//generate the headers for the response
			//note the servlet uses the Status header to set the http response code.
			headers = Str.Format( "Status: %1%2Content-type: application/json; charset=UTF-8%3Content-Length: %4", statusStr, Web.CRLF, Web.CRLF, byteLength )
		
			if ( Length( extraHeaders ) > 0 )
			
				Web.Write( ctxOut, extraHeaders )
				
			end
			
			//write the headers string.
			Web.Write( ctxOut, headers )
					
			Web.Write( ctxOut, Str.Format("%1%1", Web.CRLF))
			
			//write the data.
			if ( byteLength > 0 )
			
				Web.Write ( ctxOut, jsonData )
				
			end
		
		else
		
			ok = FALSE
			errMsg = "Error converting the data to JSON."
			apiError = jsonData
		
		end
		
		retVal.ok = ok
		retVal.errMsg = errMsg
		retVal.apiError = apiError
		
		return retVal
		
	end
end
