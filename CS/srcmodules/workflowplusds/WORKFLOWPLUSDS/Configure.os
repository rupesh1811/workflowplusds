package WORKFLOWPLUSDS

public object Configure inherits WEBADMIN::AdminRequestHandler::Configure

	override	Boolean	fEnabled = TRUE
	override	String	fFuncPrefix = 'workflowplusds'

end
