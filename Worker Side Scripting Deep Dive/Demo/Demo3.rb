begin
	case_factory = $utilities.getCaseFactory
	caze = case_factory.open("cases\\User Exchange 2018")
	processor = caze.createProcessor
	
	# Load processing profile
	processingProfileStore = $utilities.getProcessingProfileStore
	
	profileName = "User Exchange 2018"
	if !processingProfileStore.containsProfile(profileName)
		raise "Profile, #{profileName}, does not exist!"
	end
	
	ueProfile = processingProfileStore.getProfile(profileName)
	
	# Get ProcessingProfileBuilder
	builder = $utilities.getProcessingProfileBuilder
	
	# Copy processing profile
	builder.copy(ueProfile)
		   .withName("User Exchange 2018 updated")
	
	# Add password list
	builder.addPasswordList("Default", ["password"])
		   .withPasswordDiscoverySettings({"mode" => "word-list", "word-list" => "Default"})
	
	# Build and save new profile
	newProfile = builder.build
	newProfile.save
	
	# Export new profile
	processingProfileStore.exportProfile("User Exchange 2018", "D:/User Exchange/2018/exported profiles", "UE 2018 Exported")
	
	# Apply the new profile
	processor.setProcessingProfile("User Exchange 2018 updated")
	
	encryptedItems = caze.search("flag:encrypted")
	
	puts "Encrypted item count: #{encryptedItems.length}"
	
	reloadItems = []
	
	caze.withWriteAccess do
		encryptedItems.each do |item|
			reloadItems << item.getParent
			item.removeItemAndDescendants
		end
	end
	
	processor.reloadItemsFromSourceData(reloadItems)
	
	# Event logging
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
	volume = caze.getStatistics.getFileSize("*",nil) / 1024 / 1024
	puts "Processed #{volume}MB in #{Time.at(finish - start).gmtime.strftime("%H:%M:%S")}"

rescue Exception => exc
	puts exc.message
	puts exc.backtrace.join("\n")
ensure
	if !caze.nil?
		caze.close
	end
end