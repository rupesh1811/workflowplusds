package WORKFLOWPLUSDS::WorkflowPlusDSWFMainStandardTasks

public object DocuSign inherits WORKFLOWPLUSDS::#'WorkflowPlusDS WFMainStandardTasks'#

	override	Integer	fSubType = 1
	override	String	fTaskName = 'DocuSign'
	override	Integer	fType = 558

	override function Dynamic GetPainterInfo( \
					Object		prgCtx, \
					Record		task, \
					Dynamic		context = Undefined )
					Dynamic retVal
				
				if ( IsDefined( context ) )
					retVal = context.ID
				end
				
				return( retVal )
			end

	
	override function Assoc ReadyTaskForInitiation( \
					Object		prgCtx, \
					Record		r, \
					RecArray	workPkg, \
					Assoc		taskIDs, \
					Assoc		workData )
				
		Assoc		retVal
		Assoc		userData
		Assoc		docusignData
		Assoc		document
		Assoc		role
		Assoc 		tab
		Object		obj
		List 		info
		Record		d
		Boolean 	isEmailValid
		Boolean 	isNameValid
		Object		pkgSubsystem = $WFMain.WFPackageSubsystem
		Object		wapiPkg = $WFMain.WAPIPkg

		isEmailValid = FALSE
		isNameValid = FALSE
		retVal.OK = True
		
		userData.PERMFLAGS = r.USERFLAGS
	
		userData = r.USERDATA
	
		r.TITLE = wapiPkg.ReplaceVariable( prgCtx, r.TITLE, workData )
		r.INSTRUCTIONS = wapiPkg.ReplaceVariable( prgCtx, r.INSTRUCTIONS, workData )
		r.DESCRIPTION = wapiPkg.ReplaceVariable( prgCtx, r.DESCRIPTION, workData )
		
		for d in workPkg
			obj = pkgSubsystem.GetItem( { d.TYPE, d.SUBTYPE } )
			
			if ( IsDefined( obj ) )
				obj.ReplaceVariables( prgCtx, r, d.USERDATA, workData )
			end
		end
		
		if ( r.PERFORMERID == 0 )
			r.PERFORMERCB = { { $WFMain.WFConst.kCBGetInitiator, Undefined } }
		end

		if ( userData.PERFORMERDATA.AssignToEngine )
			r.Flags |= WAPI.SUBWORKTASK_FLAG_BACKGROUND
		end

		info = r.ReadyCB

		if ( IsUndefined( info ) )
			info = {}
		end

		r.ReadyCB = info
		info = r.DoneCB

		if ( IsUndefined( info ) )
			info = {}
		end

		info = { @info, { $WFMain.WFConst.kCBDMTPerformOperations, Undefined } }
		info = { @info, { $WFMain.WFConst.kCBSetTaskDoneData, Undefined } }
		info = { { 558, 'workflowplusds' } }
		
		r.DoneCB = info
		
		docusignData = userData.docusignData
		
		if ( !IsDefined( docusignData.templateId ) || !Length( Str.Trim( docusignData.templateId ) ) )
			retVal.OK = False
			retVal.ApiError = undefined
			retVal.errMsg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoDocusignTemplateDefined], .fTaskName, r.TITLE )
		elseif ( !IsDefined( docusignData.envelopeId ) || !Length( Str.Trim( docusignData.envelopeId ) ) )
			retVal.OK = False
			retVal.ApiError = undefined
			retVal.errMsg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoEnvelopeIdDefined], .fTaskName, r.TITLE )
		elseif ( !IsDefined( docusignData.documentList ) || !Length( docusignData.documentList ) )
			retVal.OK = False
			retVal.ApiError = undefined
			retVal.errMsg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoDSDocumentSelected], .fTaskName, r.TITLE )
		else
			for document in docusignData.documentList
				if ( !IsDefined( document.source ) || !Length( document.source ) )
					retVal.OK = False
					retVal.ApiError = undefined
					retVal.errMsg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoSourceDefined], .fTaskName, r.TITLE, document.name )
				elseif ( !IsDefined( document.roles ) || !Length( document.roles ) )
					retVal.OK = False
					retVal.ApiError = undefined
					retVal.errMsg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoTabDefined], .fTaskName, r.TITLE, document.name )
				else
					isEmailValid = FALSE
					isNameValid = FALSE
					
					for role in document.roles
						isEmailValid = FALSE
						isNameValid = FALSE
						
						for tab in role.tabs
							if tab.name == 'Email Address' && tab.mapping  != ''
								 isEmailValid = TRUE
							elseif tab.name == 'Full Name' && tab.mapping  != ''
								isNameValid = TRUE
							end
							
							if isEmailValid && isNameValid
								break
							end
						end
						
						retVal.ok = isEmailValid && isNameValid
						retVal.ApiError = Undefined
						if !isEmailValid && !isNameValid
							retVal.errMsg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoEmailAddressFullNameDefined], .fTaskName, r.TITLE, role.name, document.name )
						elseif !isEmailValid
							retVal.errMsg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoEmailAddressDefined], .fTaskName, r.TITLE, role.name, document.name )
						elseif !isNameValid
							retVal.errMsg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoFullNameDefined], .fTaskName, r.TITLE, role.name, document.name )
						end
						
						if !retVal.ok
							break
						end
					end
					
					if !retVal.ok
						break
					end
				end
			end
		end
		
		return( retVal )
	end
	
	override function Void SetTaskDefaults( \
					Object		prgCtx, \
					Record		taskRec, \
					Dynamic		context = Undefined )
		
		Assoc template
		Assoc status
		List templates
		String temp
					
		taskRec.TYPE = .fType
		taskRec.SUBTYPE = .fSubType
		taskRec.EXATTS = Assoc.CreateAssoc()
		taskRec.CUSTOMDATA = Assoc.CreateAssoc()
		taskRec.USERDATA = Assoc.CreateAssoc()
		taskRec.USERDATA.docusignData = Assoc.CreateAssoc()
		taskRec.USERDATA.docusignData.documentList = {}
		taskRec.USERDATA.docusignData.templateId = ''
		
		if ( IsUndefined( context ) )
			taskRec.TITLE = Str.String( .fTaskName )
			taskRec.PERFORMERID = Undefined
		else
			taskRec.TITLE = context.NAME
			taskRec.PERFORMERID = context.ID
		end
		
		status = $WorkflowPlusDS.Utils.GetDocuSignTemplates( prgCtx )
					
		if status.ok
			for temp in status.templates
				template = Assoc.CreateAssoc()
				template.id = temp[ : Str.Locate(temp, '^') - 1]
				template.name = temp[ Str.Locate(temp, '^') + 1 : ]
				template.documents = Assoc.CreateAssoc()
				templates = List.SetAdd( templates, template )
			end
		end
		taskRec.USERDATA.templates = templates
		taskRec.USERDATA.PerformerData = Assoc.CreateAssoc()
		taskRec.FLAGS = 0
		taskRec.EXATTS.GroupFlags = $WFMain.WFConst.kWFGroupStandard
		taskRec.EXATTS.RunScript = 'ReadyCB'
		
	end

	
	override function Void SetTaskRecFromMapTask( \
					WAPIMAPTASK	task, \
					Record		r, \
					Record		taskData )
					
		Dynamic		data = task.pUserData
		
		r.TYPE = task.pType
		r.SUBTYPE = task.pSubType
		r.USERFLAGS = data.PERMFLAGS
		r.SUBMAPID = task.pSubMapID
		r.PERFORMERID = taskData.WORK.SUBWORKTASK_PERFORMERID
		r.READYCB = task.pReadyCB
		r.DONECB = task.pDoneCB
		r.KILLCB = task.pKillCB
		r.PERFORMERCB = task.pPerformerCB
		r.SUBMAPIDCB = task.pSubMapIdCB
		r.CONDITIONCB = task.pConditionCB
		r.FORM = task.pForm
		r.PAINTER = task.pPainter
		r.STARTDATE = task.pStartDate
		r.DUEDURATION = task.pDueDuration
		r.DUEDATE = task.pDueDate
		r.DUETIME = task.pDueTime
		r.TITLE = taskData.WORK.SUBWORKTASK_TITLE
		r.DESCRIPTION = task.pDescription
		r.INSTRUCTIONS = task.pInstructions
		r.PRIORITY = task.pPriority
		r.TASKID = task.pTaskID + 1
		r.USERDATA = data
		r.EXATTS = Assoc.CreateAssoc()
		
	end

	
	override function Void VerifyDefinition( \
			Object		prgCtx, \
			Record		task, \
			Record		mapRec, \
			RecArray	verifyData )
			
			Assoc		roleInfo
			List		roleList
			Object		obj
			String		msg
			Assoc		docusignData
			Assoc 		document
			Assoc 		role
			Assoc 		tab
			Boolean 	isEmailValid
			Boolean 	isNameValid
			
			docusignData = task.USERDATA.docusignData
			
			if ( !IsDefined( task.TITLE ) || !Length( Str.Trim( task.TITLE ) ) )
				msg = Str.Format( [WFMain_VerifyMsg.NoStepNameDefined], .fTaskName )
				RecArray.AddRecord( verifyData, { $WFMain.WFConst.kWFSeverityWarning, msg } )
			elseif ( !IsDefined( docusignData.templateId ) || !Length( Str.Trim( docusignData.templateId ) ) )
				msg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoDocusignTemplateDefined], .fTaskName, task.TITLE )
				RecArray.AddRecord( verifyData, { $WFMain.WFConst.kWFSeverityError, msg } )
			else
				if ( !IsDefined( docusignData.envelopeId ) || !Length( Str.Trim( docusignData.envelopeId ) ) )
					msg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoEnvelopeIdDefined], .fTaskName, task.TITLE )
					RecArray.AddRecord( verifyData, { $WFMain.WFConst.kWFSeverityError, msg } )
				end
				
				if ( !IsDefined( docusignData.status ) || !Length( Str.Trim( docusignData.status ) ) )
					msg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoDSStatusDefined], .fTaskName, task.TITLE )
					RecArray.AddRecord( verifyData, { $WFMain.WFConst.kWFSeverityWarning, msg } )
				end
				
				if ( !IsDefined( docusignData.documentList ) || !Length( docusignData.documentList ) )
					msg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoDSDocumentSelected], .fTaskName, task.TITLE )
					RecArray.AddRecord( verifyData, { $WFMain.WFConst.kWFSeverityError, msg } )
				else
					for document in docusignData.documentList
						if ( !IsDefined( document.source ) || !Length( document.source ) )
							msg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoSourceDefined], .fTaskName, task.TITLE, document.name )
							RecArray.AddRecord( verifyData, { $WFMain.WFConst.kWFSeverityError, msg } )
						end
						
						if ( !IsDefined( document.roles ) || !Length( document.roles ) )
							msg = Str.Format( 'The %1 step "%2" does not have any role defined for Document "%3"', .fTaskName, task.TITLE, document.name )
							RecArray.AddRecord( verifyData, { $WFMain.WFConst.kWFSeverityError, msg } )
						else
							for role in document.roles
								isEmailValid = FALSE
								isNameValid  = FALSE
								
								if ( !IsDefined( document.roles ) || !Length( document.roles ) )
									msg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoTabDefined], .fTaskName, task.TITLE, document.name )
									RecArray.AddRecord( verifyData, { $WFMain.WFConst.kWFSeverityError, msg } )
								else
									for tab in role.tabs
										if tab.name == 'Email Address' && tab.mapping != ''
											isEmailValid = TRUE
										elseif tab.name == 'Full Name' && tab.mapping != '' 
											isNameValid = TRUE
										end
									end
									
									if !isEmailValid	
										msg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoEmailAddressDefined], .fTaskName, task.TITLE, role.name, document.name )
										RecArray.AddRecord( verifyData, { $WFMain.WFConst.kWFSeverityError, msg } )
									end
									if !isNameValid
										msg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoFullNameDefined], .fTaskName, task.TITLE, role.name, document.name )
										RecArray.AddRecord( verifyData, { $WFMain.WFConst.kWFSeverityError, msg } )
									end
								end
							end
						end
					end
				end
			end
			
			if ( !IsDefined( task.PERFORMERID ) && !IsDefined( task.PERFORMERCB ) )
				if ( IsDefined( task.EXATTS.PerformerData ) )
					$WFMain.AdvancedPerformerPkg.VerifyDefinition( prgCtx, task, mapRec, verifyData )
				else
					msg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.NoStepAssignee], .fTaskName, task.TITLE )
					RecArray.AddRecord( verifyData, { $WFMain.WFConst.kWFSeverityWarning, msg } )
				end
			elseif ( task.PERFORMERID == -1 )
				roleInfo = mapRec.MapInfo.ExAtts.LL_Role
				
				if ( IsDefined( roleInfo ) )
					obj = $WFMain.WFRoleSubsystem.GetItem( { roleInfo.Type, roleInfo.SubType } )
					if ( IsDefined( obj ) )
						roleList = obj.GetRoleNames( prgCtx, roleInfo.Data )
					end
				end
				
				if ( !( task.EXATTS.LL_Role in roleList ) )
					msg = Str.Format( [WORKFLOWPLUSDS_VERIFYMSG.RoleNoLongerDefined], .fTaskName, task.TITLE, task.EXATTS.LL_Role )
					RecArray.AddRecord( verifyData, { $WFMain.WFConst.kWFSeverityWarning, msg } )
				end
			end
			
		end

end
