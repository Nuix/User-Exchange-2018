begin
	case_factory = $utilities.getCaseFactory
	caze = case_factory.create("cases\\User Exchange 2018")
	processor = caze.createProcessor
	
	# Processing Settings
	processingSettings = {
		"processText" => true,
		"traversalScope" => "full_traversal",
		"processLooseFileContents" => true,
		"processForensicImages" => true,
		"analysisLanguage" => "en",
		"stopWords" => false,
		"stemming" => false,
		"enableExactQueries" => false,
		"extractNamedEntities" => false,
		"extractNamedEntitiesFromText" => false,
		"extractNamedEntitiesFromProperties" => false,
		"extractNamedEntitiesFromTextStripped" => false,
		"extractShingles" => true,
		"processTextSummaries" => true,
		"calculateSSDeepFuzzyHash" => false,
		"calculatePhotoDNARobustHash" => false,
		"detectFaces" => true,
		"classifyImagesWithDeepLearning" => false,
		"imageClassificationModelUrl" => nil,
		"extractFromSlackSpace" => false,
		"carveFileSystemUnallocatedSpace" => false,
		"carveUnidentifiedData" => false,
		"carvingBlockSize" => nil,
		"recoverDeletedFiles" => true,
		"extractEndOfFileSlackSpace" => false,
		"smartProcessRegistry" => true,
		"identifyPhysicalFiles" => true,
		"createThumbnails" => true,
		"skinToneAnalysis" => false,
		"calculateAuditedSize" => false,
		"storeBinary" => false,
		"maxStoredBinary" => 250000000,
		"maxDigestSize" => 250000000,
		"digests" => ["MD5"],
		"addBccToEmailDigests" => false,
		"addCommunicationDateToEmailDigests" => false,
		"reuseEvidenceStores" => false,
		"processFamilyFields" => false,
		"hideEmbeddedImmaterialData" => false,
		"reportProcessingStatus" => "none",
		#"enableCustomProcessing" => nil,
		#"workerItemCallback" => nil,
		"performOcr" => false,
		#"ocrProfileName" => "Default",
		"createPrintedImage" => false,
		#"imagingProfileName" => "Processing Default",
		"exportMetadata" => false#,
		#"metadatExportProfileName" => nil
	}
	processor.setProcessingSettings(processingSettings)
	
	# Parallel Processing Settings
	parallelProcessingSettings = {
		"workerCount" => 2,
		"workerMemory" => 4096,
		"workerTemp" => "C:/Temp",
		"embedBroker"=> true,
		"brokerMemory" => 768
	}
	processor.setParallelProcessingSettings(parallelProcessingSettings)
	
	# MimeType processing settings
	txtProcessingSettings = {
		"enabled" => true,
		"processEmbedded" => true,
		"processText" => true,
		#"textStrip" => false,
		"processNamedEntities" => true,
		"processImages" => true,
		"storeBinary" => true
	}
	
	xlsxProcessingSettings = {"enabled" => false}
	
	processor.setMimeTypeProcessingSettings("text/plain", txtProcessingSettings)
	processor.setMimeTypeProcessingSettings("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", xlsxProcessingSettings)
	
	
	# === Create a ProcessingProfileBuilder ===
	builder = $utilities.getProcessingProfileBuilder()
	builder.withName("User Exchange 2018")
	
	builder.withProcessingSettings(processingSettings)
	
	builder.withParallelProcessingSettings(parallelProcessingSettings)
	
	builder.withMimeTypeProcessingSettings("text/plain", txtProcessingSettings)
	builder.withMimeTypeProcessingSettings("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", xlsxProcessingSettings)
	
	# Build and save the processing profile
	processingProfile = builder.build
	processingProfile.save()
	# === End Create a ProcessingProfileBuilder ===
	
	
	# Create evidence container
	evidence = processor.newEvidenceContainer("Evidence 1")
	evidence.addFile("evidence")
	evidence.save
	
	# Event Logging
	processor.whenItemProcessed do | item |
		path = item.getPath.join("\\")
		puts "Processed #{path}"
	end
	
	processor.whenProgressUpdated do | info |
		puts "Progress: #{info.getCurrentSize}/#{info.getTotalSize}"
	end
	
	processor.whenCleaningUp do
		puts "Cleaning up..."
	end
	
	# Start processing
	puts "Initiating processing"
	start = Time.now
	processor.process
	finish = Time.now
	puts "Processing completed! Duration: #{Time.at(finish - start).gmtime.strftime("%H:%M:%S")}"

rescue Exception => exc
	puts exc.message
	puts exc.backtrace.join("\n")
ensure
	if !caze.nil?
		caze.close
	end
end