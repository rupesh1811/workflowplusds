package WORKFLOWPLUSDS

public object #'WorkflowPlusDS WFCustomScriptPkg'# inherits WFMAIN::WFCustomScriptPkg
	
	override function Assoc CBExecute( \
			Object		prgCtx, \
			WAPIWORK	work, \
			Integer		workID, \
			Integer		subWorkID, \
			Integer		taskID, \
			Integer		returnSubWorkID, \
			Integer		returnTaskID, \
			List		info, \
			Dynamic		extraData )
			
		Assoc		data
		Assoc		docusignData	
		Dynamic		retVal		
		Dynamic		taskInfo
		Boolean		handled = FALSE
		Object		wSession	 = prgCtx.WSession()
		
		switch( info[ 1 ] )
			case 558
				handled = ( Str.Upper( info[ 2 ] ) == 'WORKFLOWPLUSDS' )
			end
			default
				handled = False
			end
		end
		
		if handled
			taskInfo = wSession.LoadTaskStatus( workID, subWorkID, taskID )
			
			if ( !( isDefined( taskInfo ) ) && isError( taskInfo ) )
				retVal = Assoc.CreateAssoc()
				retVal.ok = FALSE
				retVal.ErrMsg = "Error getting the taskInfo"
			else
				taskInfo = taskInfo[ 1 ]
		
				if ( Assoc.isKey( taskInfo.SUBWORKTASK_USERDATA, 'docusignData' ) )
					docusignData = taskInfo.SUBWORKTASK_USERDATA.docusignData
					retVal = ._ProcessDocusign( prgCtx, work, workID, subWorkID, taskID, taskInfo, docusignData )
				end
			end
		end
		
		data.Handled = handled
		data.retVal = retVal
		
		return( data )
	
	end
	
	
	function Assoc _ProcessDocusign( Object  prgCtx, \
									         WAPIWORK work, \
									         Integer   workID, \
									         Integer   subWorkID, \
									         Integer   taskID, \
									         Record  taskInfo, \
									         Assoc 	docusignData )
	
		Assoc 		document
		Dynamic		workData
		Dynamic		retVal
		Integer 	index
		Integer 	apiError
		Assoc   	data
		Assoc 		status
		Assoc		role
		FilePrefs	fprefs
		String 		attrs
		String 		filePath
		String 		docName
		String		value
		List 		attrList
		CAPILOGIN 	login
	  	
	  	status.ok = TRUE
	  	
	  	if ! Assoc.IsKey( docusignData, 'templateId' ) || IsUndefined( docusignData.templateId )
	  		status.ok = FALSE
	  		status.errMsg = [WORKFLOWPLUSDS_ERRMSG.TemplateNotSelected]
	  	elseif ! Assoc.IsKey( docusignData, 'envelopeId' ) || IsUndefined( docusignData.envelopeId )
	  		status.ok = FALSE
	  		status.errMsg = [WORKFLOWPLUSDS_ERRMSG.MappingForEnvelopeIdNotSpecified]	
	  	elseif ! Assoc.IsKey( docusignData, 'status' ) || IsUndefined( docusignData.status )
	  		status.ok = FALSE
	  		status.errMsg = [WORKFLOWPLUSDS_ERRMSG.MappingForDocusignStatusNotSpecified]	
	  	end
		
		login = prgCtx.GetCAPILogin()
			
		data.url = CAPI.IniGet( login, 'Workflowplus', 'docusign_URL' )
		data.username = CAPI.IniGet( login, 'Workflowplus', 'docusign_username' )
		data.password = CAPI.IniGet( login, 'Workflowplus', 'docusign_password' )
		data.integratorKey = CAPI.IniGet( login, 'Workflowplus', 'docusign_key' )
		
		if status.ok
			workData = $WFMain.WAPIPkg.LoadWorkData( prgCtx, work )
			
			if IsError( workData )
				status.ok = FALSE
				status.errMsg = [WORKFLOWPLUSDS_ERRMSG.CouldNotLoadWorkdataForWorkflow]
			end
		end
		
		if status.ok
			status = ._GetParamValue( prgCtx, workData, docusignData.envelopeId , {} )
		end
		
		if status.ok
			data.envelopeId = status.value
			
			retVal = JavaObject.InvokeStaticMethod("com.yahoo.supai.DocGen", "isCompleted", { data })
			
			if IsError( retVal )
				status.ok = FALSE
				status.errMsg = Str.Format( [WORKFLOWPLUSDS_ERRMSG.ErrorInvlokingMethod], 'CheckStatus' )
				status.apiError = Error.ErrorToString( retVal )
			else
				status = retVal
			end
			
			if status.ok
				if Str.Upper( status.status ) == 'COMPLETED'
					data.filePath = $Kernel.FileUtils.GetTempDir() + Str.String( workID ) + '.pdf'
					
					retVal = JavaObject.InvokeStaticMethod( 'com.yahoo.supai.DocGen', 'downloadDocument', {data})		
				
					if IsError( retVal )
						status.ok = FALSE
						status.errMsg = Str.Format( [WORKFLOWPLUSDS_ERRMSG.ErrorInvlokingMethod], 'DownloadDocument' )
						status.apiError = Error.ErrorToString( retVal )
					else
						status = retVal
					end
					
					if status.ok
						for value in status.filepaths
							docName = value[ : Str.Locate( value, '|') - 1 ]
							filePath = value[ Str.Locate( value, '|') + 1 : ]
							
							status = $WorkflowPlusDS.Utils.GetElementFromList( docusignData.documentList, 'name', docName )
							
							if status.ok
								status = ._GetNodeFromSource( prgCtx, status.element.source, work )
							end
							
							if status.ok
								data = Assoc.CreateAssoc()
								data.comment = ''
								data.filename = status.node.pName
								data.fileType = filePath[ Str.Locate(filePath, '.') + 1 : ]
								data.mimeType = $WebDsp.MIMETypePkg.GetFileExtMIMEType(data.fileType)
								data.platform = DAPI.PLATFORM_WINDOWS
								data.versionFile = filePath
								
								status = $LLIApi.LLNodeSubsystem.GetItem( $TypeDocument ).NodeAddVersion( status.node, data )
							end
							
							if status.ok
								File.Delete( filePath )
							end
						end
					end
					
					if status.ok
						status.status = 'completed'
					end	
				end
			end
		else
			
			fprefs = Fileprefs.Open( $Kernel.ModuleUtils.ModuleIniPath( "docgen" ) )
			attrs = Fileprefs.GetPref( fprefs, 'DocusignTabs', 'Tabs' )
			Fileprefs.Close( fprefs )
			
			attrList = Str.Elements( attrs, ',' )	
			
			data.templateId = docusignData.templateId
		
			data.documents = Assoc.CreateAssoc()
				
			for document in docusignData.documentList
				
				value = ''
				
				if IsFeature( document, 'source' ) && IsDefined( document.source )
					status = ._GetNodeFromSource( prgCtx, document.source, work )
				end
				
				if status.ok
					index += 1
					filePath = Str.Format( '%1%2_%3.pdf', $Kernel.FileUtils.GetTempDir(), workID, index )
					
					if ( ( apiError = DAPI.FetchVersion( DAPI.GetVersion( status.node, DAPI.VERSION_GET_CURRENT ), filePath ) ) != DAPI.OK )
						
						status.OK = FALSE
						status.ErrMsg = [WORKFLOWPLUSDS_ERRMSG.CouldNotFetchTheDocument]
						status.ApiError = apiError
					end
				end
			
				if status.ok
					value = filePath + '|'
					
					for role in document.roles
						value += role.name + '~'
						
						for index = 1 to Length( attrList )
							 status = $WorkflowPlusDS.Utils.GetElementFromList( role.tabs, 'name', attrList[ index ] )
						
							if status.ok
								status = ._GetParamValue( prgCtx, workData, status.element.mapping, {} )
							end
							
							if status.ok && Assoc.IsKey( status, 'value' ) && IsDefined( status.value )
								value += Str.String( status.value ) + '~' 
							else
								value += '~'
							end
						end
						value = value[ : -2 ] + '^'
					end
					
					value = value[ : -2 ]
					
					data.documents.( document.id ) = value
				end
			end
		
			retVal = JavaObject.InvokeStaticMethod("com.yahoo.supai.DocGen", "sendDoc1", { data })
			
			if IsError( retVal )
				status.ok = FALSE
				status.errMsg = Str.Format( [WORKFLOWPLUSDS_ERRMSG.ErrorInvlokingMethod], 'SendDoc' )
				status.apiError = Error.ErrorToString( retVal )
			else
				status = retVal
				status.status = 'sent'
			end
				
		end
		
		if status.ok
			data = Assoc.CreateAssoc()
			
			if Assoc.IsKey( docusignData, 'envelopeId' ) && docusignData.envelopeId != '' && IsFeature(status, 'envelopeId')
				data.( docusignData.envelopeId ) = status.envelopeId
			end
			
			if Assoc.IsKey( docusignData, 'status' ) && docusignData.status != '' && IsFeature(status, 'status')
				data.( docusignData.status ) = status.status
			end
			
			status = ._SetParamValue( prgCtx, workID, subWorkID, work, workData, data )
		end
		
		return status
	end
	
	function Assoc _GetParamValue( 
				Object 			prgCtx,
				RecArray		workArray,
				String 			param,
				List			workflowParams )
		
		List		inputList
		Object		obj	
		String 		dataType
		Assoc 		retVal
		
		inputList = Str.Elements( param, ':' )
	
		for obj in $WFReport.WFRepPkgSubsystem.GetItems()
			dataType = Str.Format( '%1_%2', obj.fType, obj.fSubType )
			if ( dataType == inputList[ 1 ] )
				retVal = obj.GetParamValue(
							 prgCtx,
							 workArray,
							 inputList[ 2 ],
							 workflowParams,
							 ( Length( inputList ) == 3 ) ? inputList[ 3 ] : Undefined )
				break
			end
		end
		
		return retVal	
	end
	
	
	function Assoc _GetNodeFromSource( Object prgCtx, Assoc source, WAPIWORK work ) 
		
		Assoc 		retVal
		Assoc 		status
		String 		docType
		String 		docPath
		String 		docName
		String 		docID
		Integer 	containerID
		Object 		AttachmentObj
		Dynamic 	workData
		Dynamic 	containerNode
		
		docType = source.docType
		docPath = source.docPath
		docName = source.docName
		docID = source.docID
		status.ok = TRUE
		
		if docType == 'WFAttachment'
			
			AttachmentObj = $WFMain.WFPackageSubsystem.GetItemByName('DAPIAttachments')
			workData = WAPI.GetWorkData( work, AttachmentObj.fType, AttachmentObj.fSubType )
			
			if IsError( workData )
				status.ok = FALSE
				status.errMsg = Error.ErrorToString( workData )
			end
			
			if status.ok
				containerID = workData[ 1 ].Data_UserData
				containerNode = DAPI.GetNodeByID( prgCtx.dSession().fSession, DAPI.BY_DATAID, containerID )
			
				if IsError( containerNode )
					status.ok = FALSE
					status.errMsg = [WORKFLOWPLUSDS_ERRMSG.CouldNotFetchAttachmentNode]
					return status
				end
			end
			
			if 	status.ok	
				if docPath == 'Attachments'
					if DAPI.NumSubNodes( containerNode ) > 0 
						containerNode = DAPI.ListSubNodes(containerNode)[ 1 ]
					else
						containerNode = Undefined
					end
				else
					containerNode = DAPI.GetNodeByID( prgCtx.dSession().fSession, Str.StringToInteger( docID ) )
				end
				
				if IsUndefined( containerNode ) || IsError( containerNode )
					status.ok = FALSE
					status.errMsg = [WORKFLOWPLUSDS_ERRMSG.CouldNotFetchWorkflowAttachment]
					return status
				end
			end
		elseif docType == 'Workflow'
			
			AttachmentObj = $WFMain.WFPackageSubsystem.GetItemByName('DAPIAttachments')
			workData = WAPI.GetWorkData( work, AttachmentObj.fType, AttachmentObj.fSubType )
			
			if IsError( workData )
				status.ok = FALSE
				status.errMsg = Error.ErrorToString( workData )
			end
			
			if IsUndefined( containerNode ) || IsError( containerNode )
				retVal.ok = FALSE
				retVal.errMsg = Error.ErrorToString( containerNode )
				return retVal
			end
			
			if 	status.ok
				containerNode = DAPI.GetNode( docName, containerNode )
			end
			
			if IsUndefined( containerNode ) || IsError( containerNode )
				retVal.ok = FALSE
				retVal.errMsg = Error.ErrorToString( containerNode )
				return retVal
			end
			
		elseif docType == 'Livelink'
			
			containerNode = DAPI.GetNodeByID( prgCtx.dSession().fSession, Str.StringToInteger( docID ) )
			
			if IsUndefined( containerNode ) || IsError( containerNode )
				retVal.ok = FALSE
				retVal.errMsg = Error.ErrorToString( containerNode )
				return retVal
			end
			
		elseif docType == 'WFAttribute'
			
			status = $Workflowplus.AttributeUtils._GetWFAttribValue( prgCtx, work, docName )
			
			if status.ok
				containerNode = DAPI.GetNodeByID( prgCtx.dSession().fSession, status.attribValue )
			end
			
			if IsUndefined( containerNode ) || IsError( containerNode )
				retVal.ok = FALSE
				retVal.errMsg = Error.ErrorToString( containerNode )
				return retVal
			end
		else
			retVal.ok = FALSE
			retVal.errMsg = Error.ErrorToString( containerNode )
			return retVal
		end
		
		retVal.ok = TRUE
		retVal.node = containerNode
		
		return retVal
	end
	
	
	function Assoc _SetParamValue( Object prgCtx, workID, subWorkID, WAPIWORK work, RecArray workData, Assoc attrs )
		
		Assoc 		data
		Assoc 		status
		String 		key
		List 		tmpList
		List 		mapList
		
		data.formData = Assoc.CreateAssoc()
		data.attrData = Assoc.CreateAssoc()
		
		data.attrData.ids = {}
		data.attrData.values = {}
		
		for key in Assoc.Keys( attrs ) 
			mapList = Str.Elements( key, ':' )
			
			if mapList[ 1 ] == '1_3'
				data.attrData.ids = List.SetAdd( data.attrData.ids, Str.StringToInteger( mapList[ 2 ] ) )
				data.attrData.values = List.SetAdd( data.attrData.values, attrs.( key ) )
			elseif mapList[ 1 ] == '1_4'
				if Length( mapList ) == 3
					tmpList = Str.Elements( mapList[ 2 ] , '_')
					
					if ! Assoc.IsKey( data.formData, tmpList[ 1 ]  ) 
						data.formData.( tmpList[ 1 ] ) = Assoc.CreateAssoc()
						data.formData.( tmpList[ 1 ] ).ids = {}
						data.formData.( tmpList[ 1 ] ).values = {}
					end
					
					data.formData.( tmpList[ 1 ] ).ids = List.SetAdd( data.formData.( tmpList[ 1 ] ).ids, Str.Format( '%1:%2', tmpList[ 3 ], mapList[ 3 ] ) )
					data.formData.( tmpList[ 1 ] ).values = List.SetAdd( data.formData.( tmpList[ 1 ] ).ids, attrs.( key ) )
				elseif Length( mapList ) == 2
					tmpList = Str.Elements( mapList[ 2 ] , '_')
					
					if ! Assoc.IsKey( data.formData,  tmpList[ 1 ] ) 
						data.formData.( tmpList[ 1 ] ) = Assoc.CreateAssoc()
						data.formData.( tmpList[ 1 ] ).ids = {}
						data.formData.( tmpList[ 1 ] ).values = {}
					end
					
					data.formData.( tmpList[ 1 ] ).ids = List.SetAdd( data.formData.( tmpList[ 1 ] ).ids, Str.StringToInteger( tmpList[ 3 ] ) )
					data.formData.( tmpList[ 1 ] ).values = List.SetAdd( data.formData.( tmpList[ 1 ] ).ids, attrs.( key ) )
				end
			end
		end
		
		if Assoc.IsKey( data.attrData, 'ids' ) &&  Length( data.attrData.ids ) > 0
			status = $Wfreport.WFRepUtils._PostWFAttrValues( prgCtx, work, workData, data.attrData.ids, data.attrData.values )
		end
		
		return status
	end
	
end
