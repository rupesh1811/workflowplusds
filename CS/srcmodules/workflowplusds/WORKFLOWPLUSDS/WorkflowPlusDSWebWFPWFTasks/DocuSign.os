package WORKFLOWPLUSDS::WorkflowPlusDSWebWFPWFTasks

public object DocuSign inherits WORKFLOWPLUSDS::#'WorkflowPlusDS WebWFPWFTasks'#

	override	String	fSmallGif = '16user.gif'
	override	Integer	fSubType = 1
	override	String	fTaskGif = '16user.gif'
	override	Integer	fType = 558


	
	public function Assoc GetFormData( Object prgCtx, Record mapRec )
				
				Assoc		formData
				Object		obj	
				Record		p
				
				obj = $WebWFP.WFPackageSubsystem.GetItemByName('Form')
				if IsDefined(obj)
					for p in mapRec.WORK_PACKAGES
						if ( p.TYPE == obj.fType and p.SUBTYPE == obj.fSubType )
							if ( IsDefined( p.USERDATA ) )
								formData = $WFReport.WFRepUtils.GetFormFields( prgCtx, p.USERDATA )
							end
						end
					end
				end
				
				return formData
			end

	
	override function Assoc GetMapData( \
					Object		prgCtx, \
					Integer		mapID, \
					Integer		taskID, \
					Record		mapRec, \
					Record		request )
				
				Assoc a
				Assoc paneData
				Assoc performerInfo
				Assoc retVal
				Assoc tabPaneInfo
				Assoc docusignData
				Assoc formData
				Assoc attrData
				Assoc taskInfoAssoc
				Dynamic tmp
				Integer whichTab
				Object obj
				Record p
				Assoc eventInfo
				Boolean knownUser = FALSE
				Integer i = 1
				Record taskInfo = mapRec.TASKS[ taskID ]
				String gif = 'guy.gif'
				String name
				String objName = .OSName
		
				whichTab = ( RecArray.IsColumn( request, 'PaneIndex' ) ) ? \
				Str.StringToInteger( request.PaneIndex ) : 1
				
				//Specify the commonedittask.html file as the HTML file to
				//display when the creator of a workflow map edits a custom
				//display step in the Workflow Designer. Specify the location of
				//the commonedittask.html file (that is, the webwfp module).
		
				retVal.HTMLFile = "commonedittask.html"
				retVal.ModuleName = 'workflowplusds'
		
				//Create an Assoc named retVal.Data and populate it with the step
				//and map information, including the ID of the workflow map, the
				//ID of the step, the URL of the next page to display, and the
				//header information for the step.
		
				retVal.Data = Assoc.CreateAssoc()
				retVal.Data.MapID = mapID
				retVal.Data.TaskID = taskID
				retVal.Data.NextURL = request.NextURL
				retVal.Data.HeaderArgs = $WebWork.WFPkg.GetHeaderTypeArgs( \
				'PAINT', $WebWork.WFPkg.GetMapName( prgCtx, mapID, \
				mapRec ) )
		
				retVal.Data.HeaderLabel = [WebWFP_HTMLLabel.StartStepDefinition]
				
				//Create an Assoc named tmp that stores all of the data required
				//to paint the first tab that appears when the creator of a
				//workflow map edits the custom display step in the Workflow
				//Painter (that is, the General tab).
		
				tmp = Assoc.CreateAssoc()
				tmp.Label = [WebWork_HTMLLabel.General]
				tmp.URL = $WebWork.WFPkg.SetPaneIndexArg( \
				$WebDSP.HTMLPkg.ArgsToURL( request ), i )
				tmp.HelpKey = objName
				tmp.Active = FALSE
		
				//This step type uses the commonedittask.html file. This HTML
				//file expects to be passed a list of tab names, along with a
				//list of the data to be displayed on each tab. TabList is a list
				//of Assocs that identifies each tab to be displayed. There is
				//another list of Assocs that lists the panes to be displayed
				//with each tab. This second list of Assocs contains the HTML
				//information and all other information that the pane needs to
				//draw itself.
		
				tabPaneInfo.TabList = { tmp }
				
				a = Assoc.CreateAssoc()
				a.workPackages = mapRec.WORK_PACKAGES 
				a.TaskInfo = taskInfo
				a.MapID = mapID
				a.TaskID = taskID - 1
				a.NextURL = request.NextURL
				a.TypeLabel = 'DocuSign'
				
				a.CanAssignToEngine = ( $LLIApi.FactoryUtil.IsCreatable( prgCtx, { 1, 1 }, $FactoryTypeWFEngineUser ) )
				//Retrieves the name of the performer of the step and a .gif file
				//that represents the performer type (that is, a user or a
				//group). If the step is assigned to the initiator of the
				//workflow, then >Initiator< is returned as the performer's name.
		
				if ( IsDefined( taskInfo.PERFORMERID ) )
					if ( taskInfo.PERFORMERID == -1 )
						if ( IsDefined( taskInfo.ExAtts.LL_Role ) )
							name = Str.Format( '<%1>', taskInfo.ExAtts.LL_Role )
						else
							taskInfo.PERFORMERID = Undefined
						end
					elseif ( taskInfo.PERFORMERID == 0 )
						name = [WebWork_HTMLLabel.Initiator]
					else
						tmp = UAPI.GetByID( prgCtx.USession().fSession, \
						taskInfo.PERFORMERID )
						if ( !IsError( tmp ) )
							knownUser = True
							name = tmp[ 1 ].NAME
							if ( tmp[ 1 ].TYPE != UAPI.USER )
								gif = '2-guys.gif'
							end
						end
					end
				end
				if ( gif == '2-guys.gif' )
					a.Gif = '16group.gif'
				else
					a.Gif = '16user.gif'
				end
		
				performerInfo.Name = name
				performerInfo.Gif = gif
				performerInfo.KnownUser = knownUser
				performerInfo.ID = taskInfo.PERFORMERID
		
				a.PerformerInfo = performerInfo
		
				//Create an Assoc named tmp that stores the name of your custom
				//module, the HTML file to display, and the data that appears on
				//the General tab.
		
				tmp = Assoc.CreateAssoc()
				tmp.ModuleName = 'workflowplusds'
				tmp.HTMLFile = 't_dmt.html'
				tmp.Data = a
		
				//Set the name of the Step Definition page for this step type.
				//This page is displayed when the creator of a workflow map edits
				//a custom display step in the Workflow Designer.
		
				retVal.Data.HeaderLabel = 'DocuSign Step Definition'
		
				tabPaneInfo.PaneList = { tmp }
				
				i = Length( tabPaneInfo.TabList ) + 1
		
				//Set up any data type information that is required for this type
				//of step.
		
				for p in mapRec.WORK_PACKAGES
					obj = $WebWFP.WFPackageSubsystem.GetItem( { p.TYPE, \
					p.SUBTYPE } )
		
					if ( IsDefined( obj ) && IsDefined( p.USERDATA ) )
						a = obj.GetTabInfo( prgCtx, request, p.USERDATA, i )
						a.Active = FALSE
						if IsDefined( a.HelpKey )
							a.HelpKey = objName + "." + a.HelpKey
						else
							a.HelpKey = objName
						end
			
						paneData = obj.GetMapData( prgCtx, taskInfo, p.USERDATA )
						
						if ( IsDefined( paneData ) )
							i += 1
			
							tabPaneInfo.TabList = { @tabPaneInfo.TabList, a }
							tabPaneInfo.PaneList = { @tabPaneInfo.PaneList, paneData }
						end
					end
				end
				
				if($LLIApi.FACTORYUTIL.isCreatable(prgCtx,{this.fType,this.fSubType},2))
					
					taskInfo.USERDATA.workPackages = mapRec.WORK_PACKAGES
					docuSignData = taskInfo.USERDATA.docusignData
			
					//Getting form data and assigning it to taskinfo userdata
					formData = .GetFormData(prgCtx, mapRec)
					taskInfoAssoc = Assoc.FromRecord(taskInfo)
					
					if Assoc.isKey(taskInfoAssoc.userData,'docusignData') && Assoc.isKey(taskInfoAssoc.userData.docusignData,'formData') && Assoc.isKey(taskInfoAssoc.userData.docusignData.formData, 'fields') 
						taskInfoAssoc.userData.docusignData.formData.invAssoc = formData.invAssoc
						taskInfoAssoc.userData.docusignData.formData.popupAssoc = formData.popupAssoc
					else
						docusignData.formData = formData
						taskInfoAssoc.userData.docusignData = docusignData
					end	
					
					//Getting attribute data and assigning it to taskinfo userdata
					attrData = $WFReport.WFRepUtils.GetAttrData(prgCtx, mapRec)
					taskInfoAssoc = Assoc.FromRecord(taskInfo)
					
					if Assoc.isKey(taskInfoAssoc.userData,'docusignData') && Assoc.isKey(taskInfoAssoc.userData.docusignData,'attrData') && Assoc.isKey(taskInfoAssoc.userData.docusignData.attrData, 'fields') 
						//attrData.attrs = taskInfoAssoc.userData.reportData.attrData.attrs
						taskInfoAssoc.userData.docusignData.attrData.invAssoc = attrData.invAssoc
						taskInfoAssoc.userData.docusignData.attrData.popupAssoc = attrData.popupAssoc
						
					else
						docusignData.attrData = attrData
						taskInfoAssoc.userData.docusignData = docusignData
					end	
					
					//Code for getting form data ends here
					
					
					taskInfo = Assoc.ToRecord(taskInfoAssoc)
					
					tmp = Assoc.CreateAssoc()
					tmp.Label = [WORKFLOWPLUSDS_HTMLLABEL.Docusign]   // Tab name
					tmp.URL = $WebWork.WFPkg.SetPaneIndexArg( $WebDSP.HTMLPkg.ArgsToURL( request ), i)
					tmp.HelpKey = objName + "." + 'DocuSign' // do not XLATE
					tmp.Active = FALSE
					
					tabPaneInfo.TabList = { @tabPaneInfo.TabList, tmp }
					
					a = Assoc.CreateAssoc()	
					a.TaskInfo = taskInfo
					a.PerformerInfo = performerInfo
					a.MapID = mapID
					a.TaskID = taskID
					//Extra code added here to store other data
					
					a.title = [WORKFLOWPLUSDS_HTMLLABEL.Docusign]
					
					//Extra code ends here
					
					tmp = Assoc.CreateAssoc()
					a.paneIndex = request.paneIndex
					tmp.ModuleName = 'workflowplusds'
					tmp.HTMLFile = 'docusign_tab.html'	
					tmp.Data = a
					
					i += 1			
					tabPaneInfo.PaneList = { @tabPaneInfo.PaneList, tmp }
				//end
				end
				i = Length( tabPaneInfo.TabList ) + 1
			
				//List the callback scripts that fire, if applicable.
				
				List fields = { 'PERFORMERCB', 'READYCB', 'DONECB' }
				List events = { [WebWFP_HTMLLabel.AssignStepPerformer], \
							[WebWFP_HTMLLabel.StepBecomesReady], \
							[WebWFP_HTMLLabel.StepIsDone] }
				eventInfo.Events = events
				eventInfo.FieldNames = fields
				eventInfo = $WFMain.WFMapPkg.GetValidEvents( prgCtx, eventInfo )
			
				if ( eventInfo.NumberOfEvents > 0 )
					tmp = Assoc.CreateAssoc()
					tmp.Label = [WebWFP_HTMLLabel.EventScripts]
					tmp.URL = $WebWork.WFPkg.SetPaneIndexArg( \
					$WebDSP.HTMLPkg.ArgsToURL( request ), i )
					tmp.HelpKey = objName + "." + 'EventScripts'
					tmp.Active = FALSE
					tabPaneInfo.TabList = { @tabPaneInfo.TabList, tmp }
					a = Assoc.CreateAssoc()
					a.EventInfo = eventInfo
					a.DataRec = taskInfo
					tmp = Assoc.CreateAssoc()
					tmp.ModuleName = 'webwfp'
					tmp.HTMLFile = 't_events.html'
					tmp.Data = a
					tabPaneInfo.PaneList = { @tabPaneInfo.PaneList, tmp }
				end
			
				//Store the pane information for the tabs in the data Assoc. Then
				//set the active tab. By default, the active tab is 1 (or
				//whichever tab was originally passed into the script).
			
				if ( whichTab > Length( tabPaneInfo.TabList ) ) 
					whichTab = 1
				end
				
				tabPaneInfo.TabList[ whichTab ].Active = True
				retVal.Data.TabInfo = tabPaneInfo
				retVal.Data.Tab = whichTab
				
				return( retVal )
			end

	
	override function assoc PutMapData( \
					Object		prgCtx, \
					Record		mapRec, \
					Record		taskInfo, \
					Record		r )
				
				Assoc		retVal
				
				
				//
				// This virtual function is responsible for saving the data as presented
				// in the record r. The field names for r correspond to those choosen
				// by the implementor of the html file whose name is returned by 
				// GetMapData().
				//
				
				retVal.OK = TRUE
				
				return retVal
			end

end
