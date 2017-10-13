package WORKFLOWPLUSDS::WorkflowPlusDSLLRequestHandlers

public object GetDocuments inherits WORKFLOWPLUSDS::#'WorkflowPlusDS LLRequestHandlers'#
	
	override	Boolean	fEnabled = TRUE
	override	Dynamic	fPrototype = { { 'templateId', StringType, 'Template ID', FALSE } }
	override	Dynamic	fHTMLFile = 'listdocuments.html'
				Assoc 	fDocuments
				
	override function Dynamic Execute( \
			Dynamic		ctxIn, \
			Dynamic		ctxOut, \
			Record		request )
			
		Assoc 		status
		Object		prgCtx
		String 		temp
		List		values
		Assoc 		documents
		
		prgCtx		= .PrgSession()
		status.ok	= FALSE
		
		if IsDefined( request.templateId )
			status = $WorkflowPlusDS.Utils.GetDocuSignDocuments( prgCtx, request.templateId )
		end
		
		if status.ok
			for temp in status.documents
				values = Str.Elements( temp, '^')
				documents.( values[ 1 ] ) = values[ 2 ]
			end
			.fDocuments = documents
		end
		
		return Undefined
	end

	
	override function SubclassExecuteComponents()
		
		Object		title
		Object		livelink
		
		Assoc		guiComponents = .fGUIComponents
		Object		pageManager = .GetPageManager()
		
		OS.Delete( pageManager )
	 	pageManager = $WEBNODE.DialogPageManager._New()
	 	$WebNode.ComponentUtils.DisposeOfComponents( guiComponents )
	 	guiComponents = $WEBNODE.ComponentUtils.GetComponents( undefined, Assoc.CreateAssoc(), {} )
	
		title = guiComponents.title
		title.SetTitle1( 'Select Document for:' )
		title.SetTitle2( 'DocuSign' )
		title.SetUserNameDisplay( FALSE )
		title.SetLinkIsEnabled( FALSE )
		
		livelink = guiComponents.livelink	
		livelink.SetContentHTMLFile( .TemplatePrefix(), .fHTMLFile )
		
		guiComponents.Search.SetIsEnabled( FALSE )
		guiComponents.Menu.SetIsEnabled( FALSE )
		guiComponents.Footer.SetIsEnabled( FALSE )
		
		pageManager.SetContentComponents( { livelink } )
		pageManager.SetTitleString( [WORKFLOWPLUSDS_LABEL.SelectDocument] )
		
		.fGUIComponents = guiComponents
	 	.fPageManager = pageManager
	end

end
