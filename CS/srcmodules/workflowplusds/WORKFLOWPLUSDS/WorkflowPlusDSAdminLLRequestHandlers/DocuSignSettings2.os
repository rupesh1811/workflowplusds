package WORKFLOWPLUSDS::WorkflowPlusDSAdminLLRequestHandlers

public object DocuSignSettings2 inherits WORKFLOWPLUSDS::#'WorkflowPlusDS AdminLLRequestHandlers'#

	override	Boolean	fEnabled = TRUE


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
					
					Object		prgCtx	= .PrgSession()
					
					CAPILogin login = prgCtx.GetCAPILogin()
																					
					CAPI.IniPut( login, "Workflowplus", "docusign_URL", request.docusign_URL )
					CAPI.IniPut( login, "Workflowplus", "docusign_username", request.docusign_username )
					CAPI.IniPut( login, "Workflowplus", "docusign_password", request.docusign_password )
					CAPI.IniPut( login, "Workflowplus", "docusign_key", request.docusign_key )
					
					.fLocation = .Url() + "?func=admin.index#docusign"
					
					return Undefined
				end

end
