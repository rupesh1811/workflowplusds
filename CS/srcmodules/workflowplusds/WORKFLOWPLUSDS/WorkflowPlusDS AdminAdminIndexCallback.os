package WORKFLOWPLUSDS

public object #'WorkflowPlusDS AdminAdminIndexCallback'# inherits WEBADMIN::AdminIndexCallback::AdminAdminIndexCallback

	
	override function Assoc Execute( \
							Object	prgCtx, \
							Record	request )
							
					Dynamic	apiError
					String	errMsg
					Assoc	retVal
					Assoc	sections
					
					Boolean	ok = TRUE
					Assoc	section_1 = ._NewSection()
					Assoc	section_1_1 = ._NewSection()
					
					String	scriptName = request.SCRIPT_NAME
			
					//	Section 1
					section_1.anchorName = [WORKFLOWPLUSDS_HTMLLABEL.WorkflowPlusDS]
					section_1.heading = [WORKFLOWPLUSDS_HTMLLABEL.DocuSignConfiguration]
				
					sections.( section_1.heading ) = section_1
					
					section_1_1.anchorHREF = scriptName + "?func=workflowplusds.DocuSignSettings"
					section_1_1.heading = [WORKFLOWPLUSDS_HTMLLABEL.ConfigureDocuSignConnectionParameters]
					section_1_1.text = [WORKFLOWPLUSDS_HTMLLABEL.ConfigureDocuSignConnectionParametersDesc]
				
					section_1.sections.( section_1_1.heading ) = section_1_1
					
					if ( IsUndefined( retVal.ok ) )
						
						retVal.ok = ok
						retVal.apiError = apiError
						retVal.errMsg = errMsg
						retVal.sections = sections
					end
					
					return retVal
				end

end
