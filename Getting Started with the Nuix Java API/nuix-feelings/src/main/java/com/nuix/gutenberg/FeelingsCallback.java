package com.nuix.gutenberg;

import java.io.IOException;
import java.io.InputStream;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

import org.apache.commons.lang.StringUtils;

import com.basistech.rosette.api.HttpRosetteAPI;
import com.basistech.rosette.apimodel.DocumentRequest;
import com.basistech.rosette.apimodel.Entity;
import com.basistech.rosette.apimodel.Response;
import com.basistech.rosette.apimodel.SentimentOptions;
import com.basistech.rosette.apimodel.SentimentResponse;
import com.basistech.rosette.apimodel.jackson.ApiModelMixinModule;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;

import com.fasterxml.jackson.databind.ObjectMapper;

import nuix.Binary;
import nuix.SourceItem;
import nuix.Text;
import nuix.WorkerItem;

public class FeelingsCallback implements Consumer<WorkerItem> {
	
	private final static ObjectMapper mapper = new ObjectMapper();
	
	@Override
	public void accept(WorkerItem workerItem) {
		SourceItem sourceItem = workerItem.getSourceItem();
		String mimeType = sourceItem.getType().getName();
		System.out.println(" This worker is processing > " + StringUtils.join(sourceItem.getPathNames(), "\\"));
		System.out.println(" MIME-Type: " + mimeType);
		System.out.println("     WorkerItem [GuidPath=" + StringUtils.join(workerItem.getGuidPath(), "\\") + ",ProcessEmbedded=" + workerItem.getProcessEmbedded() + ",ProcessImages=" + workerItem.getProcessImages() + ",ProcessItem=" + workerItem.getProcessItem() + ",ProcessText=" + workerItem.getProcessText() + ",StoreBinary=" + workerItem.getStoreBinary() + "]");
		System.out.println("     SourceItem [Name=" + sourceItem.getName() + ",FileSize=" + sourceItem.getFileSize() + ",Kind=" + sourceItem.getKind() + "]");
		Map<String,Object> properties = sourceItem.getProperties();
		Text text = sourceItem.getText();
		try {
			if("application/json".compareTo(mimeType) == 0) {
				properties.putAll(new ObjectMapper().readValue(text.toString(), HashMap.class));
				workerItem.setItemProperties(properties);
			}
			if("text/plain".compareTo(mimeType) == 0) {
				if(sourceItem.getText().length() > 0) {
					Map<String,Object> myFeelings = assessFeelings(text.toString());
					properties.put("My Feelings On This Thing", myFeelings.get("feelings"));
					properties.put("Strength of My Feelings", myFeelings.get("conviction"));
					workerItem.setItemProperties(properties);
					List<Map<String,Object>> noteables = (List<Map<String, Object>>) myFeelings.get("noteables");
					List<Path> children = new ArrayList<Path>();
					for(Map<String,Object> noteable : noteables) 
						children.add(createTempDataFile(mapper.writeValueAsString(noteable)));
					workerItem.setChildren(children);
				}
			}
		} catch (Exception ex) {
			System.out.println(ex.getMessage());
			ex.printStackTrace(System.out);
		}
	}	
	
	public static Map<String,Object> assessFeelings(String text) throws JsonProcessingException, IOException {
		if(text.length() > 25000)
			text = text.substring(0, 25000);
		Map<String,Object> out = new HashMap<String,Object>();
		System.out.println("Preparing to assess my feelings on " + text.length() + " characters of text.");
		try(HttpRosetteAPI rosetteApi = new HttpRosetteAPI.Builder().key("e98c27e60d67998cb0563e44bd13488b").build()) {
			Path tmp = createTempDataFile(text);
			try (InputStream inputStream = Files.newInputStream(tmp)) {
				DocumentRequest<SentimentOptions> request = DocumentRequest.<SentimentOptions>builder().content(inputStream, "text/plain").build();
	            try {
	            	SentimentResponse response = rosetteApi.perform(HttpRosetteAPI.SENTIMENT_SERVICE_PATH, request, SentimentResponse.class);
	            	
	            	double confidence = response.getDocument().getConfidence();
	            	String label = response.getDocument().getLabel();
	            	out.put("conviction", confidence);
	            	out.put("feelings", label);
	            	
	            	List<Map<String,Object>> noteables = new ArrayList<Map<String,Object>>();
	            	for(Entity entity : response.getEntities()) {
	            		Map<String,Object> noteable = new HashMap<String,Object>();
	            		noteable.put("Occurences of Thing", entity.getCount());
	            		noteable.put("Type of Thing", entity.getType());
	            		noteable.put("Name", entity.getMention());
	            		noteable.put("My Feelings On This Thing", entity.getSentiment().getLabel());
	            		noteable.put("Strength of My Feelings", entity.getSentiment().getConfidence());
	            		noteables.add(noteable);
	            	}
	            	
	            	out.put("noteables", noteables);
	            	
	            } catch(Exception ex) {
	            	System.out.println(ex.getMessage());
	            	ex.printStackTrace(System.out);
	            }
	            
			}
        }
		return out;
	}

	public static String responseToJson(Response response) throws JsonProcessingException {
        ObjectMapper mapper = ApiModelMixinModule.setupObjectMapper(new ObjectMapper());
        mapper.enable(SerializationFeature.INDENT_OUTPUT);
        mapper.setSerializationInclusion(JsonInclude.Include.NON_NULL);
        return mapper.writeValueAsString(response);
    }
	
    public static Path createTempDataFile(String data) throws IOException {
        Path file = Files.createTempFile("nuix.", ".txt");
        try (Writer writer = Files.newBufferedWriter(file, StandardCharsets.UTF_8)) {
            writer.write(data);
        }
        file.toFile().deleteOnExit();
        return file;
	}
}
