package YAHOOUTILS::RequestHandlers

public object CreateXML inherits YAHOOUTILS::#'YahooUtils LLRequestHandlers'#

	override	Boolean	fEnabled = TRUE
				String 	fInputPath = 'D:/MyProject/input/'
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
		Assoc 		data
		String 		key
		Dynamic 	flag
		
		prgCtx	= .PrgSession()
		data = Assoc.FromRecord(request)
		
		for key in Assoc.Keys( data )
			if( IsUndefined( Str.Locate( key, '_1_1_') ) )
				Assoc.Delete( data, key )
			end
		end
		
		Assoc.Delete( data, '_1_1_9_1_Exists_list')
		
		data.inputPath = .fInputPath + request.timestamp + '.xml'
		
		flag = JavaObject.InvokeStaticMethod('com.yahoo.supai.DocGen', 'createXML', { data })
	
		data = Assoc.CreateAssoc()
			
		if !isError( flag ) && flag
			data.status = 'success'
		else
			data.status= 'error'
			data.errMsg = Error.ErrorToString( flag )
		end
		
		$WorkflowPlusDS.Utils.OutputData( prgCtx, ctxOut, data, request )
				
		return Undefined
	end	
end
