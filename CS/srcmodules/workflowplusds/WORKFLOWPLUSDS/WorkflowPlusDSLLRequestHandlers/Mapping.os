package WORKFLOWPLUSDS::WorkflowPlusDSLLRequestHandlers

public object Mapping inherits WORKFLOWPLUSDS::#'WorkflowPlusDS LLRequestHandlers'#
	
	override	Boolean	fEnabled = TRUE
	override	Dynamic	fHTMLFile = 'wfdocattrs.html'
				Assoc	fData
				
	override function Dynamic Execute( \
			Dynamic		ctxIn, \
			Dynamic		ctxOut, \
			Record		request )
		
		FilePrefs	fprefs
		String 		attrs
		
		fprefs = Fileprefs.Open( $Kernel.ModuleUtils.ModuleIniPath( "workflowplusds" ) )
		attrs = Fileprefs.GetPref( fprefs, 'DocusignTabs', 'Tabs' )
		.fData.Attrs = Str.Elements(attrs, ',')
		.fData.rec = request.'for'
		.fData.type = request.type
	
		return Undefined
	end
	
	
	override function SubclassExecuteComponents()
		
		Object	pageManager
								
		Object	title = .fGUIComponents.title
		Object	guiComponents = .fGUIComponents
		Object	livelink = .fGUIComponents.livelink
		
		//title.SetPictogram( $Kernel.SystemPreferences.GetPrefGeneral( 'HTMLImagePrefix' ) + 'icon_exprbuilder.gif' )
		title.SetPictogram( $Kernel.SystemPreferences.GetPrefGeneral( 'HTMLImagePrefix' ) + \
		                      'workflowplus' + File.Separator() + 'propertiesbig.gif' )
		//                    File.Separator()  + 'propertiesbig.gif' )
		title.SetPictogramAlt( [DOCGEN_HTMLLabel.SelectAttribute] )
		title.fDefaultBGImage = 'webwork/workflow_header.gif'
		title.SetChickletClickable( false )
	
		if ( IsFeature( .fArgs, 'pageTitle' ) && IsDefined( .fArgs.pageTitle ) && ( Length( .fArgs.pageTitle ) > 0 ) )
			title.SetTitle1( 'Select Attribute' )	
			title.SetTitle2( .fArgs.pageTitle )
		else
			title.SetTitle1( 'Select Attribute' )
		end
		
		guiComponents.title.SetUserNameDisplay( true )
		guiComponents.Search.SetIsEnabled( false )
		guiComponents.Menu.SetIsEnabled( false )
		guiComponents.Footer.SetIsEnabled( true )
		
		livelink.SetContentHTMLFile( .TemplatePrefix(), .fHTMLFile )
		
		pageManager = .GetPageManager()
		pageManager.SetContentComponents( { livelink } )
		pageManager.SetTitleString( 'Select Attribute' )
			
	end

end
