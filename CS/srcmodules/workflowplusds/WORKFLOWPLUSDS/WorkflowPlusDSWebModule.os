package WORKFLOWPLUSDS

public object WorkflowPlusDSWebModule inherits WEBDSP::WebModule

	override	Boolean	fEnabled = TRUE
	override	String	fModuleName = 'workflowplusds'
	override	String	fName = 'Content Server WorkflowPlus for DocuSign'
	override	List	fOSpaces = { 'workflowplusds' }
	override	String	fSetUpQueryString = 'func=workflowplusds.configure&module=workflowplusds&nextUrl=%1'
	override	List	fVersion = { '16', '0', 'r', '0' }
	override	List	fDependencies = { { 'kernel', 16, 0 }, { 'workflowplus', 16, 0 } }

end
