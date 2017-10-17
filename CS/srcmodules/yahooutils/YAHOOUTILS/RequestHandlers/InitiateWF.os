package YAHOOUTILS::RequestHandlers

public object InitiateWF inherits YAHOOUTILS::#'YahooUtils LLRequestHandlers'#
	
	override	Boolean	fEnabled = TRUE
				String 	fOutputPath = 'D:\MyProject\output\'
	/*
		* This is the method subclasses implement to provide their functionality.
		*
		* @param {Dynamic} ctxIn
		* @param {Dynamic} ctxOut
		* @param {Record} request
		*
		* @return {Dynamic} Undefined
		*/
	override function Dynamic Execute( \
			Dynamic		ctxIn, \
			Dynamic		ctxOut, \
			Record		request )
			
		Object		prgCtx
		Object 		obj
		Assoc 		status
		Dynamic     workPackage
		Record      mapInfo
		Integer     dataID
		Dynamic 	result
		
		prgCtx	= .PrgSession()
		status.ok = TRUE
		
		obj = $WFMain.WFPackageSubsystem.GetItemByName('DAPIAttachments')
		
		if ( status.ok )    
            status = $WEBWORK.WFPkg.LoadMap( prgCtx, Str.StringToInteger( request.mapId ), DAPI.VERSION_GET_CURRENT_PUBLISHED )
        end 
      
        if ( status.ok )    
            mapInfo = status.mapInfo
           
            for workPackage in mapInfo.WORK_PACKAGES
                if ( { workPackage.TYPE, workPackage.SUBTYPE } == { obj.fType, obj.fSubType } )
                    dataID = workPackage.USERDATA
                    break
                end 
            end
            
            result = DAPI.GetNodeById( prgCtx.dSession().fSession, DAPI.BY_DATAID, dataID )
		
			if ( !IsError( result ) )
            	status.node = result 
            else
                status.ok = FALSE
                status.errMsg = Error.ErrorToString( result )
                status.apiError = result
            end
            
		end
		
		if ( status.ok )
			status = $Yahooutils.Utils.CreateDocument( status.node, .fOutputPath + request.timestamp + '.pdf', request.timestamp )
		end
		
		if status.ok
			File.Delete( .fOutputPath + request.timestamp + '.pdf' )
		end
		
		$WorkflowPlusDS.Utils.OutputData( prgCtx, ctxOut, status, request )
		
		return Undefined
	end
end
