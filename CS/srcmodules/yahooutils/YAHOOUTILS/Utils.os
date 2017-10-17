package YAHOOUTILS

public object Utils inherits YAHOOUTILS::YahooutilsRoot

	function Bytes ReadFileData(
		File 	pkgFile )
		
		Assoc 	filestats
		Integer	len
		Integer x = 0
		Integer blockSize = ( 1 << 16 )
		Bytes 	readbytes
		Bytes 	tmpBytes
		
		filestats = File.stat( pkgFile )
		len = filestats.st_size
		tmpBytes = Bytes.Allocate( len + 1 )
		
		while ( IsNotError( readbytes = File.ReadBytes( pkgFile, blockSize ) ) )
			Bytes.PutBytes( tmpBytes, x, readBytes, Bytes.InPlace )
			x += blockSize
		end
		
		File.Close( pkgFile )
		
		return tmpBytes
	end
	
	function Dynamic CreateDocument( \
					DAPINODE parent, \
					String filePath, \
					String fileName )
	
		Assoc opts
        Object llNode
        Dynamic status
        DAPINODE node
        opts = Assoc.CreateAssoc()
        opts.comment = ''
        opts.filename = fileName
        opts.fileType = filePath[Length(filePath)-2:]
        opts.mimeType = $WebDsp.MIMETypePkg.GetFileExtMIMEType(opts.fileType)
        opts.platform = DAPI.PLATFORM_WINDOWS
        opts.versionFile =filePath
        opts.inheritNode = parent
        llNode = $LLIAPI.LLNodeSubsystem.GetItem( 144 )
        status = llnode.NodeAlloc(parent,fileName)    
        if(status.ok)
            node = status.node
            status = llnode.NodeCreate(node,parent,opts)           
        end    
                
        return status
	end
end
