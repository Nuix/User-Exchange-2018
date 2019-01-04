=begin
Copyright 2018 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Written by Jason Wells 2018/08/20
=end

# This worker side script looks at all metadata properties of a given item.  If a date property
# is found to have a value after today's date, this script will remove that property from the item
# and optionally record it as custom metadata as a backup.

# When set to true, any data property removed from an item are also annotated
# back on the item as custom metadata.
$copy_fixed_properties_to_custom_metadata = true

# When true, items which have a date property removed will also be tagged
$tag_fixed_items = true

# When $tag_fixed_items is set to true, this is the tag which will be annotated
$fixed_item_tag = "DatePropertyInTheFuture"

# If true will log some extra messages to worker log, mostly for debugging purposes
$verbose_logging = true

$todays_date = org.joda.time.DateTime.now

puts "Using as todays date: #{$todays_date}"

# Define our worker item callback
def nuix_worker_item_callback(worker_item)
	# Obtain source item
	source_item = worker_item.getSourceItem
	# Obtain a copy of item's properties
	properties = source_item.getProperties
	# List of properties we have determined need to be fixed
	properties_to_fix = []
	# Iterate properties and check each
	properties.each do |name,value|
		# First check if this property is not nil, then check if it is a date value
		if !value.nil? && (value.is_a?(org.joda.time.DateTime) || value.is_a?(java.util.Date))
			testable_value = value
			# If value is java.util.Date we should convert it to joda datetime from comparison
			if value.is_a?(java.util.Date)
				testable_value = org.joda.time.DateTime.new(value)
			end
			# Check if this property falls on a date after today
			if value.isAfter($todays_date)
				puts "#{worker_item.getItemGuid}:#{name}: #{value} is after #{$todays_date}" if $verbose_logging
				# Add this property to list of properties to be fixed
				properties_to_fix << name
			else
				puts "#{worker_item.getItemGuid}:#{name}: #{value} is not after #{$todays_date}" if $verbose_logging
			end
		end
	end
	# Now that we have determined what properties we want to fix, lets remove them from our
	# copy of this item's metadata properties and optionally copy them to custom metadata fields
	if properties_to_fix.size > 0
		properties_to_fix.each do |property_name|
			puts "Fixing date property: #{property_name} on item with GUID #{worker_item.getItemGuid}" if $verbose_logging

			# Copy property to custom metadata if settings state that we should
			if $copy_fixed_properties_to_custom_metadata
				puts "  Copying to custom metadata field..." if $verbose_logging
				value = properties[property_name]
				worker_item.addCustomMetadata(property_name,value,"date-time","user")
			end

			# Apply tag if settings state that we should
			if $tag_fixed_items
				puts "  Tagging with #{$fixed_item_tag}..." if $verbose_logging
				worker_item.addTag($fixed_item_tag)
			end

			# Remove this property from our copy of the properties Map/Hash
			properties.delete(property_name)
		end

		# At this point we should have applied any annotations and deleted all the appropriate
		# properties from our copy, now we just need to push our copy of the proerties back over to the item
		# so they actually show up as the item's properties
		worker_item.setItemProperties(properties)
	end
end