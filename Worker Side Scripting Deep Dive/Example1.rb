$word_document_mime_type = "application/vnd.ms-word"

def nuix_worker_item_callback(worker_item)
	source_item = worker_item.getSourceItem
	item_type = source_item.getType
	mime_type = item_type.getName
	if mime_type == $word_document_mime_type
		worker_item.setProcessItem(false)
	end
end