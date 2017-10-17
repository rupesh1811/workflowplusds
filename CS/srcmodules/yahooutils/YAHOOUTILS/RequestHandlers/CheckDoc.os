package YAHOOUTILS::RequestHandlers

public object CheckDoc inherits YAHOOUTILS::#'YahooUtils LLRequestHandlers'#
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
			
		Assoc data
		File outputFile
		Bytes fileBytes
		
		Object		prgCtx		 = .PrgSession()
		
		if File.Exists( .fOutputPath + request.timestamp + ".pdf" )
			data.status = 'success'
			outputFile = File.Open( .fOutputPath + request.timestamp + ".pdf" , File.ReadBinMode )
			fileBytes = $Yahooutils.Utils.ReadFileData( outputFile )
			data.base64 = Bytes.ToBase64( fileBytes )
		else
			data.status = 'pending'
		end
		
		$WorkflowPlusDS.Utils.OutputData( prgCtx, ctxOut, data, request )
		
		return Undefined
	end
end
