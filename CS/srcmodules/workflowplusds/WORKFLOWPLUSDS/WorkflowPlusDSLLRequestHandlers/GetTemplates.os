package WORKFLOWPLUSDS::WorkflowPlusDSLLRequestHandlers

public object GetTemplates inherits WORKFLOWPLUSDS::#'WorkflowPlusDS LLRequestHandlers'#

	override	Boolean	fEnabled = TRUE
	 
	override function Dynamic Execute( \
			Dynamic		ctxIn, \
			Dynamic		ctxOut, \
			Record		request )
			
		Object		prgCtx
		Assoc		data
		Assoc		status
		Assoc 		template
		String 		temp
		
		prgCtx = .PrgSession()
		
		status = $WorkflowPlusDS.Utils.GetDocuSignTemplates( prgCtx )
		data.templates = {}
		
		if status.ok
			for temp in status.templates
				template = Assoc.CreateAssoc()
				template.id = temp[ : Str.Locate(temp, '^') - 1]
				template.name = temp[ Str.Locate(temp, '^') + 1 : ]
				data.templates = List.SetAdd( data.templates, template )
			end
		end
		
		$WorkflowPlusDS.Utils.OutputData(prgCtx, ctxOut, data, request )
		
		return Undefined
	end

end
