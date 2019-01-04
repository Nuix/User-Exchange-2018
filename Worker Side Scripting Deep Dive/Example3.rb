def nuix_worker_item_callback(worker_item)
	source_item = worker_item.getSourceItem
	item_kind = source_item.getKind
	item_kind_name = item_kind.getName
	if item_kind_name == "email"
		children = source_item.getChildren
		child_count = children.size
		if child_count > 0
			worker_item.addTag("Has Attachments")
			worker_item.addCustomMetadata("Attachment Count",child_count,"integer","user")
		end
	end
end