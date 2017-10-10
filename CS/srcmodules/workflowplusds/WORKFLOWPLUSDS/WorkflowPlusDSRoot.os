package WORKFLOWPLUSDS

/**
 * 
 *  This is a good place to put documentation about your OSpace.
 */
public object WorkflowPlusDSRoot

	public		Object	Globals = WORKFLOWPLUSDS::WorkflowPlusDSGlobals



	/**
	 *  Content Server Startup Code
	 */
	public function Void Startup()
	
		//
		// Initialize globals object
		//
	
		Object	globals = $WorkflowPlusDS = .Globals.Initialize()
	
		//
		// Initialize objects with __Init methods
		//
	
		$Kernel.OSpaceUtils.InitObjects( globals.f__InitObjs )
	
	end

end
