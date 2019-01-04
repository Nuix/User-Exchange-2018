def nuix_worker_item_callback(worker_item)
	source_item = worker_item.getSourceItem
	item_date = source_item.getDate
	year = item_date.getYear
	properties = source_item.getProperties
	properties["Year"] = year
	worker_item.setItemProperties(properties)
end