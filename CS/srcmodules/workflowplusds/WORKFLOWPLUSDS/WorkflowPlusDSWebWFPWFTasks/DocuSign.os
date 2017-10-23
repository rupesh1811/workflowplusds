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
		
				retVal.Data.HeaderLabel = [WORKFLOWPLUSDS_HeaderLabel.DocusignStepDefinition]
		
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
					tmp.Label = [WORKFLOWPLUSDS_TabHeader.Docusign]   // Tab name
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
					
					a.title = [WORKFLOWPLUSDS_TABHEADER.Docusign]
					
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
				
		Assoc 		paneData
		Assoc 		retVal
		Integer 	i
		Object 		obj
		Real 		time
		Record 		p
		Assoc 		document
		Assoc 		status
		Dynamic 	data
		String 		temp
		List 		docList
		List		mapList
		Assoc 		tempAssoc
		Assoc 		holder
		Boolean		handled = False
		
		retVal.OK = TRUE
		
		
		if ( ( r.PaneIndex == 1 ) || ( r.PaneIndex == 0 ) )
			//Save the step name.
	
			if ( RecArray.IsColumn( r, 'Title' ) )
				taskInfo.Title = $LLIAPI.FormatPkg.ValToString( r.title )
			end
	
			//Save the start date.
	
			if ( RecArray.IsColumn( r, 'StartDate' ) )
				taskInfo.StartDate = ._CrackDate( r.StartDate )
			end
			
			//
			// Save the priority
			//
			if ( RecArray.IsColumn( r, 'Priority' ) )
				taskInfo.Priority = Str.StringToInteger( r.Priority )
			end
			
			//Save the instructions.
	
			if ( RecArray.IsColumn( r, 'Instructions' ) )
				taskInfo.Instructions = \
				$LLIAPI.FormatPkg.ValToString( r.Instructions )
			end
			
			//
			// Save the recalc due dates flag
			//

			if ( RecArray.IsColumn( r, 'Recalc' ) )
				taskInfo.Flags |= WAPI.MAPTASK_FLAG_RECALCULATE
			elseif ( ( taskInfo.Flags & WAPI.MAPTASK_FLAG_RECALCULATE ) == WAPI.MAPTASK_FLAG_RECALCULATE )
				taskInfo.Flags ^= WAPI.MAPTASK_FLAG_RECALCULATE
			end
			
			//Save the callback script that the creator of the workflow map
			//selects from the Script to run field.

			if ( IsFeature( r, 'CustTaskScript' ) && ( \
			r.CustTaskScript != [WebWFP_HTMLLabel._None_] ) )
				taskInfo.ExAtts.CustTaskScript = r.CustTaskScript
	
				//Save the information about when to execute the callback
				//script (that is, the workflow event that triggers the
				//callback script).
	
				taskInfo.ExAtts.RunScript = r.RunScript
			else
				taskInfo.ExAtts.CustTaskScript = Undefined
			end

			//Save the template that the creator of the workflow map
			//selects from the Template to use field.
	
			if ( IsFeature( r, 'CustTaskTemplate' ) && ( \
			r.CustTaskTemplate != [WebWFP_HTMLLabel._None_] ) )
				taskInfo.CustomData.CustTaskTemplate = r.CustTaskTemplate
			else
				taskInfo.CustomData.CustTaskTemplate = Undefined
			end

			//Save the duration.
	
			if ( RecArray.IsColumn( r, 'Duration' ) )
				if IsDefined( r.Duration ) && Length( r.Duration )
					Boolean inDays = ( r.DurationUnits == "Days" )
					
					time = $LLIAPI.FormatPkg.StringToVal( r.Duration, \
					RealType )
	
					if ( Type( time ) != RealType )
						retVal.OK = FALSE
	
						if inDays
							retVal.ErrMsg = \
							[WebWork_ErrMsg.DurationMustBeANumberOfDays]
						else
							retVal.ErrMsg = \
							[WebWork_ErrMsg.DurationMustBeANumberOfHours]
						end
					else
						taskInfo.DueDuration = \
						$LLIAPI.FormatPkg.ConvertToSeconds( inDays, time )
					end
				else
					taskInfo.DueDuration = Undefined
				end
			end
			
			taskInfo.USERDATA.PERFORMERDATA.AssignToEngine = IsFeature( r, 'AssignToEngine' )
			
			if ( taskInfo.FLAGS & WAPI.SUBWORKTASK_FLAG_BACKGROUND )
				taskInfo.FLAGS -= WAPI.SUBWORKTASK_FLAG_BACKGROUND
			end
			
			if ( r.Performer_Name == '' )
				r.Performer_ID = Undefined
			end
	
			retVal = $WebWFP.WFPkg.GetPerformer( prgCtx, mapRec, taskInfo, r )
			
			//Save the group options.
			if RecArray.IsColumn( r, "GroupFlags" )
				taskInfo.EXATTS.GroupFlags = Str.StringToInteger( \
				r.GROUPFLAGS )
			end
		else
			//Determine whether the data types that are attached to the
			//workflow need to display anything before setting up the data
			//for a particular step. For example, the custom display step
			//type needs to display a tab that allows the creator of a
			//workflow map to specify whether certain workflow attributes
			//are editable, required, or read-only.
		
			i = 2

			for p in mapRec.WORK_PACKAGES
				obj = $WebWFP.WFPackageSubsystem.GetItem( { p.TYPE, p.SUBTYPE } )
				if ( IsDefined( obj ) && IsDefined( p.USERDATA ) )
					paneData = obj.GetMapData( prgCtx, taskInfo, p.USERDATA )
					if ( IsDefined( paneData ) )
						if ( i == r.PaneIndex )
							retVal = obj.PutMapData( prgCtx, taskInfo, p.USERDATA, r )
							handled = TRUE
							break
						else
							i += 1
						end
					end
				end
			end
			
			if ( !handled )
				
				if IsFeature( r, 'data' ) && r.data != ''
					
					data = Web.FromJSON( r.data );
					
					for holder in taskInfo.USERDATA.docusignData.documentList
						holder.roles = {}
					end
					
					if Type( data ) == Assoc.AssocType
						
						for temp in Assoc.Keys( data )
							
							docList = Str.Elements( temp, ':' )
							
							if Length( docList ) == 3
								mapList = Str.Elements( data.( temp ), '|')
								
								status = $WorkflowPlusDS.Utils.GetElementFromList( taskInfo.USERDATA.docusignData.documentList, 'id', docList[ 1 ] )
								
								if status.ok && ! Assoc.IsKey( status.element, 'roles')
									status.element.roles = {}
								end
								
								if status.ok
									holder = status.element
									status = $WorkflowPlusDS.Utils.GetElementFromList( holder.roles, 'name', docList[ 2 ] )
								
									if !status.ok
										tempAssoc = Assoc.CreateAssoc()
										tempAssoc.name = docList[ 2 ]
										tempAssoc.tabs = {}
										holder.roles = List.SetAdd( holder.roles, tempAssoc )
										status.element = tempAssoc
										status.ok = TRUE
									end
								end
								
								if status.ok
									holder = status.element
									status = $WorkflowPlusDS.Utils.GetElementFromList( holder.tabs, 'name', docList[ 3 ] )
								
									if !status.ok
										tempAssoc = Assoc.CreateAssoc()
										tempAssoc.name = docList[ 3 ]
										holder.tabs = List.SetAdd( holder.tabs, tempAssoc )
										status.element = tempAssoc
										status.ok = TRUE
									end	
								end
								
								if status.ok
									holder = status.element
									holder.mapping = data.( temp )
								end
							elseif Length( docList ) == 1
								
								status = $WorkflowPlusDS.Utils.GetElementFromList( taskInfo.USERDATA.docusignData.documentList, 'id', docList[ 1 ] )
								
								if status.ok
									
									holder = status.element
									
									if data.( temp ) != ''
										
										mapList = Str.Elements( data.( temp ), '|')
										
										tempAssoc = Assoc.CreateAssoc()
										tempAssoc.docName = mapList[ 1 ]
										tempAssoc.docPath = mapList[ 2 ]
										tempAssoc.docID = mapList[ 3 ]
										tempAssoc.docType = mapList[ 4 ]
										tempAssoc.displayName = mapList[ 5 ]
										
										holder.source = tempAssoc
									
									else
										holder.source = Undefined
									end
								end
							
							end
						end
					end
					
				elseif IsFeature( r, 'removeId' ) && r.removeId != ''
					
					status = $WorkflowPlusDS.Utils.GetElementFromList( taskInfo.USERDATA.docusignData.documentList, 'id', r.removeId )
						
					if status.ok
						taskInfo.USERDATA.docusignData.documentList = List.SetRemove( taskInfo.USERDATA.docusignData.documentList, status.element )
					end
					
				elseif IsFeature( r, 'templateId') && IsFeature( r, 'documentId') && r.documentId != ''
					
					document.id = r.documentId
					document.name = r.Name
					
					status = $WorkflowPlusDS.Utils.GetElementFromList( taskInfo.USERDATA.docusignData.documentList, 'id', r.documentId )
					
					if ! status.ok
						taskInfo.USERDATA.docusignData.documentList = List.SetAdd( taskInfo.USERDATA.docusignData.documentList, document )
					end
					
					status = $WorkflowPlusDS.Utils.GetElementFromList( taskInfo.USERDATA.templates, 'id', r.templateId )
						
					if status.ok
						holder = status.element
						holder.documents.( r.documentId ) = Assoc.Copy( document )
						
						status = $WorkflowPlusDS.Utils.GetDocuSignRoles(prgCtx, taskInfo.USERDATA.docusignData.templateId, r.documentId  )
							
						if status.ok
							holder.documents.( r.documentId ).roles = status.roles
						end
						
					end
					
				elseif IsFeature( r, 'templateId')
				
					taskInfo.USERDATA.docusignData.templateId  = r.templateId
					taskInfo.USERDATA.docusignData.envelopeId  = ''
					taskInfo.USERDATA.docusignData.status  = ''
					taskInfo.USERDATA.docusignData.documentList  = {}
				
				end
				
				if IsFeature( r, 'Envelope ID' ) && IsDefined( r.'Envelope ID' ) && r.'Envelope ID' != ''
					taskInfo.USERDATA.docusignData.envelopeId = r.'Envelope ID'
				end
				
				if IsFeature( r, 'DocuSign Status' ) && IsDefined( r.'DocuSign Status' ) && r.'DocuSign Status' != ''
					taskInfo.USERDATA.docusignData.status = r.'DocuSign Status'
				end
				
				if IsFeature( r, 'isUpdated' ) && IsDefined( r.'isUpdated' ) && r.'isUpdated' != ''
					
					status = $WorkflowPlusDS.Utils.GetDocuSignTemplates( prgCtx )
					
					if status.ok
						for temp in status.templates
							tempAssoc = Assoc.CreateAssoc()
							tempAssoc.id = temp[ : Str.Locate(temp, '^') - 1]
							tempAssoc.name = temp[ Str.Locate(temp, '^') + 1 : ]
							tempAssoc.documents = Assoc.CreateAssoc()
							docList = List.SetAdd( docList, tempAssoc )
						end
						
						taskInfo.USERDATA.templates = docList
					end
					
					
				end
			end
		end
		
		if (!handled) 
			//Save any callback data.
			$WEBWFP.WFContentManager.StoreCallbackData( taskInfo, r )
		end
		
		if ( !$LLIApi.FactoryUtil.IsCreatable( prgCtx, { 1, 1 }, $FactoryTypeWFFeatures ) )
			taskInfo.USERDATA.PERFORMERDATA.AssignToEngine = False
			
			if ( taskInfo.FLAGS & WAPI.SUBWORKTASK_FLAG_BACKGROUND )
				taskInfo.FLAGS -= WAPI.SUBWORKTASK_FLAG_BACKGROUND 
			end
		end
		return retVal
	end
end
