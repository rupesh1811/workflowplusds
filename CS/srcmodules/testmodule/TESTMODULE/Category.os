package TESTMODULE

public object Category inherits DOCGEN::LLRequestHandler
	
	override	Boolean	fEnabled = TRUE

	override	Dynamic	fHTMLFile = 'index.html'

	
	
	public function Assoc AddCategory( Object prgCtx, Integer nodeID, Integer categoryID, Assoc categoryInfo )
	
		Dynamic  	attrData, catList
		Object 		llNode
		Dynamic 	node
		Assoc 		retVal
		List 		catIds
		Integer 	i
		Boolean 	found
		
		retVal.ok = TRUE
		
		node = DAPI.GetNodeByID( prgCtx.DSession().fSession, nodeID )
		
		if IsError( node )
	
			retVal.ok = FALSE
			retVal.errMsg = Error.ErrorToString( node )
			return retVal
		end
		
		if retVal.ok 
			llNode = $LLIApi.LLNodeSubsystem.GetItem( node.pSubType )
			catList	= llNode.NodeCategoriesGet( node ) 
			
			if catList.ok 
				attrData = catList.attrData
			end
		end
		
		if retVal.ok
			catIds = Assoc.keys(attrData.fData)
			
			if Length(catIds) > 0
				for i=1 to Length(catIds)
					found = ( catIds[i][1] == categoryID )
					break	
				end
			end
			
			if !found
				retVal = attrData.AttrGroupAdd( categoryID )
			end
		end
		
		if retVal.ok
			.UpdateCategory( categoryID, attrData, categoryInfo )
		end
		
		if retVal.ok
			retVal = llNode.NodeCategoriesUpdate( node, attrData )
		end
		
		return retVal
	
	end
	
	public function Assoc UpdateCategory( Integer categoryID, Object attrData, Assoc categoryInfo )
		
		Integer 	j, id
		String 		displayName
		Assoc 		retVal
		List		key, categoryKeys, attrDataKeys
		
		categoryKeys = Assoc.Keys( categoryInfo )
		attrDataKeys = Assoc.Keys( attrData.fData )
		
		for j=1 to Length( attrDataKeys )
			if attrDataKeys[ j ][ 1 ] == categoryID 
				key = attrDataKeys[ j ]
				break
			end	
		end
		
		for j=1 to length(attrData.fDefinitions.(key).Children)
            
            id = attrData.fDefinitions.(key).Children[ j ].ID
            displayName = Str.Trim( attrData.fDefinitions.(key).Children[ j ].DisplayName )
            
            if displayName in categoryKeys
            	
            	if Type( categoryInfo.( displayName ) ) == StringType
            		attrData.fData.(key).Values[ 1 ].(id).Values[ 1 ] = categoryInfo.( displayName )
            	elseif Type( categoryInfo.( displayName ) ) == DateType
            		attrData.fData.(key).Values[ 1 ].(id).Values[ 1 ] = categoryInfo.( displayName )
            	elseif Type( categoryInfo.( displayName ) ) == ListType
            		attrData.fData.(key).Values[ 1 ].(id).Values = categoryInfo.( displayName )
            	end
            	
            end
      	end
		
		retVal.ok = TRUE
		
		return retVal
	end
	/*
		* This is the method subclasses implement to provide their functionality.
		*
		* @param {Dynamic} ctxIn
		* @param {Dynamic} ctxOut
		* @param {Record} request
		*
		* @return {Dynamic} Undefined
		*/

	override function Dynamic Execute( Dynamic ctxIn, Dynamic ctxOut, Record request )

		Object		prgCtx		 = .PrgSession()

		Assoc data
		
		data.'Corporate Name' = 'Oath Inc.'
		data.'Type of Entity' = 'Inc'
		data.'Effective Date' = Date.Now()
		.AddCategory( prgCtx, 48111, 25973, data )
		return Undefined

	end


end

