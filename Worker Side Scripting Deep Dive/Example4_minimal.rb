$copy_fixed_properties_to_custom_metadata = true
$tag_fixed_items = true
$fixed_item_tag = "DatePropertyInTheFuture"
$todays_date = org.joda.time.DateTime.now

def determine_properties_to_fix(properties)
	properties_to_fix = []
	properties.each do |name,value|
		next if value.nil?
		next unless (value.is_a?(org.joda.time.DateTime) || value.is_a?(java.util.Date))
		testable_value = value
		if value.is_a?(java.util.Date)
			testable_value = org.joda.time.DateTime.new(value)
		end
		if value.isAfter($todays_date)
			properties_to_fix << name
		end
	end
	return properties_to_fix
end

def fix_properties(properties,to_fix,worker_item)
	if to_fix.size > 0
		to_fix.each do |property_name|
			if $copy_fixed_properties_to_custom_metadata
				value = properties[property_name]
				worker_item.addCustomMetadata(property_name,value,"date-time","user")
			end
			if $tag_fixed_items
				worker_item.addTag($fixed_item_tag)
			end
			properties.delete(property_name)
		end
		worker_item.setItemProperties(properties)
	end
end

def nuix_worker_item_callback(worker_item)
	source_item = worker_item.getSourceItem
	if source_item.isKind("email")
		properties = source_item.getProperties
		to_fix = determine_properties_to_fix(properties)
		fix_properties(properties, to_fix, worker_item)
	end
end