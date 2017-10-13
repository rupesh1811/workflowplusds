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
					Object		obj
					List 		info
					Record		d
					
					Object		pkgSubsystem = $WFMain.WFPackageSubsystem
					Object		wapiPkg = $WFMain.WAPIPkg
					
					retVal.OK = True
					
					userData.PERMFLAGS = r.USERFLAGS
				
					r.USERDATA = userData
				
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
					info = { { 558, 'workflowflusds' } }
					
					r.DoneCB = info
					
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

end
