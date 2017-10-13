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
	
	function Assoc GetDocuSignDocuments(Object prgCtx, String templateId) 
		
		CAPILogin 		login
		Dynamic 		data
		Assoc 			retVal
		
		login = prgCtx.GetCAPILogin()
		data = Assoc.CreateAssoc()
		
		data.url = CAPI.IniGet( login, 'Workflowplus', 'docusign_URL' )
		data.username = CAPI.IniGet( login, 'Workflowplus', 'docusign_username' )
		data.password = CAPI.IniGet( login, 'Workflowplus', 'docusign_password' )
		data.integratorKey = CAPI.IniGet( login, 'Workflowplus', 'docusign_key' )
		data.templateId = templateId
		
		data = JavaObject.InvokeStaticMethod( 'com.yahoo.supai.DocGen', 'getDocuments', { data })
		
		if IsError( data )
			retVal.ok = FALSE
			retVal.errMsg = Error.ErrorToString( data )
		else
			retVal = data
		end
		
		return retVal
	end
	
	function Assoc GetDocuSignRoles( Object prgCtx, String templateId, String documentId ) 
		
		CAPILogin 		login
		Dynamic 		data
		Assoc 			retVal
		
		login = prgCtx.GetCAPILogin()
		data = Assoc.CreateAssoc()
		
		data.url = CAPI.IniGet( login, 'Workflowplus', 'docusign_URL' )
		data.username = CAPI.IniGet( login, 'Workflowplus', 'docusign_username' )
		data.password = CAPI.IniGet( login, 'Workflowplus', 'docusign_password' )
		data.integratorKey = CAPI.IniGet( login, 'Workflowplus', 'docusign_key' )
		data.templateId = templateId
		data.documentId = documentId
		
		data = JavaObject.InvokeStaticMethod( 'com.yahoo.supai.DocGen', 'getRoleList', { data })
		
		if IsError( data )
			retVal.ok = FALSE
			retVal.errMsg = Error.ErrorToString( data )
		else
			retVal = data
		end
		
		return retVal
	end
	
	function Assoc GetElementFromList( List docList, Dynamic key, Dynamic value ) 
		
		Boolean 	found
		Assoc 		retVal
		Assoc 		element
		
		found 		= FALSE
		
		for element in docList
			if element.(key) == value
				found = TRUE
				break
			end
		end
		
		retVal.ok = found
		
		if found
			retVal.element = element
		end
		
		return retVal
	end
	
	function Assoc GetParameterData( Object prgCtx, RecArray workPackages, String param, Assoc data )
		
		Assoc 		retVal
		Assoc 		status
		Assoc 		formData
		Object		formObj
		List 		mapList
		List	 	attrData
		List 		tmpList
		Integer 	attrId
		String 		key
		String 		tmpKey
		Integer		templateId
		Integer 	formIndex
		Integer 	i
		Integer 	j
		
		formObj = $WFMain.WFPackageSubsystem.GetItemByName( 'Form' )
		
		attrData = IsFeature( data, 'attrData' ) && IsDefined( data.attrData ) ? data.attrData : Undefined
		formData = IsFeature( data, 'formData' ) && IsDefined( data.formData ) ? data.formData : Assoc.CreateAssoc()
		
		mapList = Str.Elements( param, ':' )
		
		status.ok = TRUE
		
		if mapList[ 1 ] == '1_3' 
			
			retVal.name = ''
			
			if IsUndefined( attrData ) 
				status = $Workflowplus.AttributeUtils.GetAttributes( prgCtx, mapList[ 1 ], workPackages )
			end
			
			if status.ok
				attrData = status.attributes
				status = .GetElementFromList( attrData, 'id', Str.StringToInteger( mapList[ 2 ] ) )
			end
			
			if status.ok
				retVal.name = 'Workflow Attribute:' + status.element.DisplayName
				retVal.ok = TRUE
			end
			
		elseif mapList[ 1 ] == '1_4' 
			
			retVal.name = ''
			
			tmpList = Str.Elements( mapList[ 2 ], '_' )
			
			templateId = Str.StringToInteger( tmpList[ 1 ] )
			formIndex = Str.StringToInteger( tmpList[ 2 ] )
			attrId = Str.StringToInteger( tmpList[ 3 ] )
			key = Str.Format( '%1_%2', templateId, formIndex )
			
			status.ok = TRUE
			
			if ! Assoc.IsKey( formData, key )
				status = $WFReport.WFRepUtils.GetFieldListData( prgCtx, Undefined, workPackages, templateId, formObj )								
			
				if status.ok
					formData.( key ) = status
				end
			end	
			
			if status.ok
				for tmpKey in Assoc.keys( formData )
					if tmpKey == key
						for i = 1 to Length(formData.( key ).Attributes )
							if attrId == formData.(key).Attributes[ i ].id
								if ( formData.(key).Attributes[ i ].Type != $AttrTypeSet )
									retVal.name = formData.(key).Attributes[ i ].TemplateName + ':' + formData.(key).Attributes[ i ].DisplayName 
									retVal.ok = TRUE
								else
									for j = 1 to Length( formData.( key ).Attributes[ i ].children )
										if Str.StringToInteger( mapList[ 3 ] ) == formData.( key ).Attributes[ i ].children[ j ].id
											retVal.name = formData.( key ).Attributes[ i ].TemplateName +':' + \
														  formData.( key ).Attributes[ i ].DisplayName + '(Set):' + \
														  formData.(key).Attributes[ i ].children[ j ].DisplayName
											retVal.ok = TRUE
											break
										end
									end
								end
								break
							end
						end
						break
					end 
				end
			end
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
