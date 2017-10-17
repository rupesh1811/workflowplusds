package YAHOOUTILS

public object yahooutilsWebModule inherits WEBDSP::WebModule

	override	Boolean	fEnabled = TRUE
	override	String	fModuleName = 'yahooutils'
	override	String	fName = 'yahooutils'
	override	List	fOSpaces = { 'yahooutils' }
	override	String	fSetUpQueryString = 'func=yahooutils.configure&module=yahooutils&nextUrl=%1'
	override	List	fVersion = { '16', '0', 'r', '0' }

end
