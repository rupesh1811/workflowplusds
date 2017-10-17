package YAHOOUTILS

/**
 * 
 *  This is a good place to put documentation about your OSpace.
 */
public object YahooutilsRoot

	public		Object	Globals = YAHOOUTILS::YahooutilsGlobals



	/**
	 *  Content Server Startup Code
	 */
	public function Void Startup()
	
		//
		// Initialize globals object
		//
	
		Object	globals = $Yahooutils = .Globals.Initialize()
	
		//
		// Initialize objects with __Init methods
		//
	
		$Kernel.OSpaceUtils.InitObjects( globals.f__InitObjs )
	
	end

end
