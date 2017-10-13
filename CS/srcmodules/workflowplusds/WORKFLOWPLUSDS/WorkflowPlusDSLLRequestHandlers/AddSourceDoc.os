package WORKFLOWPLUSDS::WorkflowPlusDSLLRequestHandlers

public object AddSourceDoc inherits WORKFLOWPLUSDS::#'WorkflowPlusDS LLRequestHandlers'#

	override	Boolean	fEnabled = TRUE
	override	Dynamic	fHTMLFile = 'source_doc.html'
				Assoc 	fData

	override function Dynamic Execute( \
			Dynamic		ctxIn, \
			Dynamic		ctxOut, \
			Record		request )
			
		Object 		obj
		Assoc 		mapData
		Assoc 		attachData
		Record		mapInfo
		Dynamic		status
		Integer 	dataID
		Dynamic 	p
		List		itemReference = {}
		Object		prgCtx
		
		prgCtx		= .PrgSession()
		
		obj = $WFMain.WFPackageSubsystem.GetItemByName('DAPIAttachments')
		
		.fData.Mapid = request.mapID
		.fData.taskID = request.taskID
		.fData.WFAttachments = request.WFAttachments
		.fData.nextUrl = request.nextUrl
		
		mapData = $WebWFP.WFPkg.LoadMap( prgCtx, Str.StringToInteger(request.MapID) )	
		
		if ( .CheckError( mapData ) )
			mapInfo = mapData.MapInfo	
			
			if isDefined(mapInfo) and isDefined(mapInfo.work_packages)
				status = $WorkflowPlus.AttributeUtils.GetWFAttrItemRef(mapInfo.WORK_PACKAGES)
				
				if status.OK and Assoc.isKey(status, 'itemReference')
					itemReference = status.itemReference
				end
				
				for p in mapInfo.work_packages
					if ( { p.TYPE, p.SUBTYPE } == { obj.fType, obj.fSubType } )
	                    attachData.AttachID = p.USERDATA
	                    break
	                end 
				end
			end
			
		end
		
		attachData.BrowseHeader = [WFMAIN_LABEL.SelectItem]
		attachData.Label = [WFMAIN_LABEL.WorkflowAttachment]
		attachData.NodeTypes = { $TypeDocument }
		attachData.Type = obj.fType
		attachData.SubType = obj.fSubType
		
		.fData.itemReference = itemReference	
		.fData.AttachmentData = attachData
		
		return Undefined
	end

end
