package WORKFLOWPLUSDS::WorkflowPlusDSWebWorkWFTask

public object DocuSign inherits WORKFLOWPLUSDS::#'WorkflowPlusDS WebWorkWFTask'#

	override	String	fInboxGif = '16docusign.png'
	override	Boolean	fPaletteTask = TRUE
	override	Integer	fSubType = 1
	override	String	fTaskGif = '32docusign.png'
	override	String	fTaskStatusGif = '16docusign.png'
	override	Integer	fType = 558
	override	String	fSmallGif = '16docusign.png'
	
	override function Assoc GetDisplayInfo( \
					Object		prgCtx, \
					Record		task, \
					Dynamic		context = Undefined )
					
					Assoc		retVal
					Point		pos
					String		title
					Integer		truncLen = $WFMain.WFConst.kWFTruncLen
					
					if ( IsDefined( task.PAINTER ) )
						pos = task.PAINTER[ 1 ]
						context = task.PAINTER[ 2 ]
					end
					
					if ( IsDefined( context ) && ( Type( context ) == StringType ) )
						title = context
					else
						title = task.TITLE
					end
					
					if ( Length( title ) > truncLen )
						title = Str.Format( [WebWork_HTMLLabel.TruncateTitle_], title[ : truncLen ] )
					end
					
					retVal.Title = title
					retVal.Gif = .GetTaskGif( prgCtx, task )
					retVal.Position = pos
					
					return( retVal )
				end

	
	override function Assoc GetFramePaneData( \
					Object		prgCtx, \
					Record		taskInfo, \
					Record		r )		// The args request record
				
		Assoc		a				
		Assoc		displaySettings	
		Assoc		paneData		
		Assoc		retVal			
		Assoc		section			
		Assoc		taskData		
		Dynamic		status			
		List		sections		
		Object		obj				
		Object		settingsCB		
		RecArray	packages		
		Record		p				
		String		baseURL			
		String		defSetting		
		WAPIWORK	work			

		Boolean		ok				 = True
		Boolean		groupStep		 = False
		Integer		i				 = 2
		Object		pkgSubsystem	 = $WebWork.WFPackageSubsystem


		if ( !( $WFMain.WAPIPkg.CheckTaskAssignedToUser( prgCtx, taskInfo ) ) )

			groupStep = True

		end

		settingsCB = $Webll.UserSettingsSubsystem.GetItem( 'Workflow' )
		displaySettings = settingsCB.SettingsGet( prgCtx )

		if ( r.PaneIndex == 0 )
			if ( isDefined( defSetting ) && defSetting == '1' )
				r.PaneIndex = 2
			else
				r.PaneIndex = 1
			end

			if ( displaySettings.Settings.DefaultStepPage == "Overview" )
				r.PaneIndex = 1
			end

			if ( displaySettings.Settings.DefaultStepPage == "General" )
				r.PaneIndex = 2
			end
		end

		if ( r.PaneIndex == 2 )
			a.TaskInfo = taskInfo

			paneData.ModuleName = 'webwork'
			paneData.HTMLFile = 'taskgeneralpane.html'
			paneData.Data = a
		else
			work = prgCtx.WSession().AllocWork()

			if ( !IsError( work ) )
				status = WAPI.AccessWork( work, r.WorkID, r.SubWorkID )

				if ( !IsError( status ) )
					packages = $WFMain.WAPIPkg.GetWorkPackages( prgCtx, work, taskInfo )

					if ( !IsError( packages ) )
						if ( r.PaneIndex == 1 )
							baseURL = Str.Format(
										 '%1?func=work.frametaskright&workid=%2&subworkid=%3&taskid=%4&nextURL=%5',
										 r.SCRIPT_NAME,
										 taskInfo.SUBWORKTASK_WORKID,
										 taskInfo.SUBWORKTASK_SUBWORKID,
										 taskInfo.SUBWORKTASK_TASKID,
										 Web.Escape( $WebDSP.HTMLPkg.ArgsToURL( r ) ) )

							section.Name = [WEBWORK_HTMLLabel.General]
							section.Module = 'webwork'
							section.Gif = '16_general.gif'
							section.AltTag = [WEBWORK_HTMLLabel.General]
							section.Instructions = taskInfo.MapTask_Instructions
							section.Index = i
							section.URL = Str.Format( '%1&paneindex=%2', baseURL, i )

							sections = { @sections, section }

							section = Assoc.CreateAssoc()

							for p in packages
								obj = pkgSubsystem.GetItem( { p.TYPE, p.SUBTYPE } )
								if ( IsDefined( obj ) && IsDefined( p.USERDATA ) )
									status = obj.GetData( prgCtx, taskInfo, p, r, False, ( r.PaneIndex == i ) )
									if ( IsDefined( status ) )
										i += 1

										status = obj.GetOverviewInfo( prgCtx, taskInfo, r, p.USERDATA, baseURL, i )

										section.Name = status.Label
										section.Module = status.Module
										section.Gif = status.Gif
										section.AltTag = status.AltTag
										section.Instructions = status.Instructions
										section.URL = status.URL
										section.Index = i

										sections = { @sections, section }

										section = Assoc.CreateAssoc()

									end
								end
							end

							a.Sections = sections
							a.TaskInfo = taskInfo

							paneData.ModuleName = 'webwork'
							paneData.HTMLFile = 'overviewpane.html'
							paneData.Data = a
						else
							i += 1

							for p in packages
								obj = pkgSubsystem.GetItem( { p.TYPE, p.SUBTYPE } )

								if ( IsDefined( obj ) && IsDefined( p.USERDATA ) )
									status = obj.GetData( prgCtx, taskInfo, p, r, False, ( r.PaneIndex == i ) )
									if ( IsDefined( status ) )
										if ( r.PaneIndex == i )
											paneData = status
											paneData.IsEditable = !groupStep
											break
										end
										i += 1
									end
								end
							end
						end
					else
						ok = False
						retVal.ApiError = work
						retVal.ErrMsg = [Web_ErrMsg2.CouldNotAccessWorkpackage]
						echo( retVal.errMsg )
					end
				else
					ok = False
					retVal.ApiError = work
					retVal.ErrMsg = [Web_ErrMsg2.CouldNotAccessWork]
					echo( retVal.errMsg )
				end
				WAPI.FreeWork( work )
			else
				ok = False
				retVal.ApiError = work
				retVal.ErrMsg = [Web_ErrMsg2.CouldNotAllocwork]
				echo( retVal.errMsg )
			end
		end

		taskData.ModuleName = 'webwork'
		taskData.HTMLFile = 'tgenericrightframe.html'
		taskData.TaskInfo = taskInfo
		taskData.PaneData = paneData

		retVal.OK = ok
		retVal.Data = taskData
		retVal.CookieData = paneData.CookieData

		return ( retVal )
	end

	/*
				* Returns a list of assoc properties for the menu
				* items for this task type.  The boolean viewonly
				* should be true if the view set of menu should
				* be returned (not editing), or false if the standard edit
				* menu items should be returned.  Override as needed.
				* "userdata" properties that are "RHandler[*]" will be converted
				* to urls later, based on painterinfo.rhandler*
				* values.
				* For information on java menu box item properties
				* see com.opentext.awt.tlpane.MenuBoxItem.java
				*
				* @param {Object} prgCtx
				* @param {Boolean} viewOnly
				*
				* @return {List}
				*/
	override function List GetPainterMenu( \
					Object		prgCtx, \
					Boolean		viewOnly )
				
		List		retVal
		Assoc		menuItem
		
	
		if ( !viewOnly )
	
			menuItem.label = [WebWork_MenuLabel.Edit]
			menuItem.font = "bold"	// do not xlate.
			menuItem.help = [WebWork_MenuLabel.EditThisStepSAttributes]
			menuItem.userdata = "rhandler" // do not xlate.
			
			retVal = { menuItem }
			
			if ( $LLIAPI.FactoryUtil.IsCreatable( prgCtx, { .fType, .fSubType }, $FactoryTypeWFTaskType ) )
			
				menuItem = Assoc.CreateAssoc()
				menuItem.label = [WebWork_MenuLabel.Duplicate]
				menuItem.help = [WebWork_MenuLabel.DuplicateTheCurrentStepSelection]
				menuItem.userdata = "duplicate" // do not xlate.
				
				retVal = { @retVal, menuItem }
			
			end
			
			menuItem = Assoc.CreateAssoc()
			menuItem.separator = "true" // do not xlate.
			
			retVal = { @retVal, menuItem }
			
			menuItem = Assoc.CreateAssoc()
			menuItem.label = [WebWork_MenuLabel.Delete]
			menuItem.help = [WebWork_MenuLabel.DeleteTheCurrentStepSelection]
			menuItem.userdata = "delete" // do not xlate.
			
			retVal = { @retVal, menuItem }
			
		else
		
			menuItem.label = [WebWork_MenuLabel.View]
			menuItem.font = "bold" // do not xlate.
			menuItem.help = [WebWork_MenuLabel.ViewThisStep]
			menuItem.userdata = "rhandlerWorkView" // do not xlate.
	
			retVal = { menuItem }
			
		end
		
		return retVal
	end
	
	override function Assoc GetTaskEditData( \
					Object		prgCtx, \
					Record		taskInfo, \
					Record		r )		// The args request record
				
		Assoc		retVal
		
		retVal.OK = True
		retVal.RHandler = Str.Format(
							 '%1?func=work.EditTaskHeader&workid=%2&subworkid=%3&taskid=%4&nexturl=%5',
							 r.SCRIPT_NAME,
							 r.WorkID,
							 r.SubWorkID,
							 r.TaskID,
							 Web.Escape( r.NextURL ) )

		return( retVal )
	end

	
	override function Assoc GetTaskEditFrameData( \
					Object		prgCtx, \
					Record		taskInfo, \
					Record		r )		// The args request record
				
		Assoc		data			
		Assoc		retVal			
		Assoc		section			
		Dynamic		status			
		List		sections		
		Object		obj				
		RecArray	packages		
		Record		p				
		String		baseURL			
		WAPIWORK	work			

		Boolean		groupStep		 = False
		Boolean		ok				 = true
		Integer		flags			 = WAPI.STARTTASK_FLAG_REEXECUTE | WAPI.STARTTASK_FLAG_NOAUDIT
		Integer		i				 = 1
		Object		pkgSubsystem	 = $WebWork.WFPackageSubsystem
		Object		wfPkg			 = $WebWork.WFPkg


		data.HTMLFile = 'tgenericframe.html'
		data.ModuleName = 'webwork'
		data.TaskInfo = taskInfo

		baseURL = Str.Format(
					 '%1?func=work.frametaskright&workid=%2&subworkid=%3&taskid=%4&paneindex=%5&nextURL=%6',
					 r.SCRIPT_NAME,
					 taskInfo.SUBWORKTASK_WORKID,
					 taskInfo.SUBWORKTASK_SUBWORKID,
					 taskInfo.SUBWORKTASK_TASKID,
					 0,
					 Web.Escape( $WebDSP.HTMLPkg.ArgsToURL( r ) ) )
		
		// get a work handle

		work = prgCtx.WSession().AllocWork()

		if ( !IsError( work ) )
			if ( !( $WFMain.WAPIPkg.CheckTaskAssignedToUser( prgCtx, taskInfo ) ) )
				groupStep = True
			end

			if ( groupStep )
				status = WAPI.AccessWork( work, r.WorkID, r.SubWorkID )
			else
				status = WAPI.StartTask( work, r.WorkID, r.SubWorkID, r.TaskID, flags )
			end

			if ( !IsError( status ) )
				packages = $WFMain.WAPIPkg.GetWorkPackages( prgCtx, work, taskInfo )

				if ( !IsError( packages ) )
					section.Name = [WEBWORK_HTMLLabel.Overview]
					section.Index = i
					section.Module = 'webwork'
					section.Gif = '16_overview.gif'
					section.AltTag = [WEBWORK_HTMLLabel.Overview]
					section.Checkbox = False
					section.URL = wfPkg.SetPaneIndexArg( baseURL, i )

					sections = { section }

					section = Assoc.CreateAssoc()

					i += 1

					section.Name = [WEBWORK_HTMLLabel.General]
					section.Index = i
					section.Module = 'webwork'
					section.Gif = '16_general.gif'
					section.AltTag = [WEBWORK_HTMLLabel.General]
					section.Checkbox = False
					section.URL = wfPkg.SetPaneIndexArg( baseURL, i )

					sections = { @sections, section }

					section = Assoc.CreateAssoc()

					i += 1

					for p in packages
						obj = pkgSubsystem.GetItem( { p.TYPE, p.SUBTYPE } )

						if ( IsDefined( obj ) && IsDefined( p.USERDATA ) )
							status = obj.GetData( prgCtx, taskInfo, p, r, False, False )
							if ( IsDefined( status ) )
								status = obj.GetOverviewInfo( prgCtx, taskInfo, r, p.USERDATA, baseURL, i )

								section.Name = status.Label
								section.Index = i
								section.Module = status.Module
								section.Gif = status.Gif
								section.AltTag = status.AltTag
								section.Type = status.Type
								section.SubType = status.SubType
								section.URL = status.URL
								section.Checkbox = !groupStep

								sections = { @sections, section }

								section = Assoc.CreateAssoc()
								i += 1
							end

						end

					end

					section = Assoc.CreateAssoc()
					data.Sections = sections
				else
					ok = False
					retVal.ApiError = work
					retVal.ErrMsg = [Web_ErrMsg2.CouldNotAccessWorkpackage]
				end
			else
				ok = False
				retVal.ApiError = work
				retVal.ErrMsg = [Web_ErrMsg2.CouldNotAccessWork]
				echo( retVal.errMsg )

				status = prgCtx.WSession().LoadTaskStatus( r.WorkID, r.SubWorkID, r.TaskID )

				if ( !IsError( status ) )

					if ( status[ 1 ].SUBWORKTASK_STATUS < 0 )

						retVal.ErrMsg = [WEBWORK_ErrMsg.TaskAlreadyCompleted]
						echo( retVal.errMsg )

					end

				end

			end

			WAPI.FreeWork( work )

		else

			ok = False
			retVal.ApiError = work
			retVal.ErrMsg = [Web_ErrMsg2.CouldNotAllocwork]
			echo( retVal.errMsg )

		end

		data.GroupStep = groupStep

		retVal.OK = ok
		retVal.Data = data

		return ( retVal )
	end
	
	override function Assoc NewPerformer( \
					Object		prgCtx, \
					Record		task, \
					Integer		newID, \
					String		roleName = Undefined )
					
					Assoc		retVal
		
		retVal.OK = True
		
		task.PERFORMERID = newID
		
		return( retVal )
	end
	
	override function Assoc SaveData( \
					Object		prgCtx, \
					Record		taskInfo, \
					Record		request )
		//
		// SaveData() is the companion function for GetTaskEditData().
		//
		// For in process workflows. (not for webwfp...)
		//
		Assoc		retVal
		
		retVal.OK = TRUE
		
		return( retVal )	
	end

end
