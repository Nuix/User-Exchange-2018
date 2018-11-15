package com.nuix.gutenberg;

import java.io.IOException;
import java.io.InputStream;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import org.apache.log4j.Logger;

import nuix.Utilities;
import nuix.engine.AvailableLicence;
import nuix.engine.CredentialsCallback;
import nuix.engine.CredentialsCallbackInfo;
import nuix.engine.Engine;
import nuix.engine.GlobalContainer;
import nuix.engine.GlobalContainerFactory;
import nuix.engine.LicenceSource;
import nuix.engine.Licensor;

public class BookReader {
	
	private static final Logger logger = Logger.getRootLogger();

	public static void main(String[] args) throws Exception {
		System.setProperty("nuix.logdir", "logs");
		try(GlobalContainer container = GlobalContainerFactory.newContainer()) {
			Map<String,Object> config = new HashMap<String,Object>();
			config.put("userDataDirs", "C:\\UE2018\\DTSESS04\\7.4.5\\user-data\\");
			try(Engine engine = container.newEngine(config)) {
				Utilities utilities = getUtilities(engine);
				logger.info("Successfully acquired Nuix License " + utilities.getLicence().getShortName() + " with " + utilities.getLicence().getWorkers() + " workers.");
								
				try(nuix.SimpleCase caze = (nuix.SimpleCase) utilities.getCaseFactory().create("idxs\\idx-" + System.currentTimeMillis(), config)) {
					nuix.Processor processor = caze.createProcessor();
					
					Map<String,Object> workers = new HashMap<String,Object>();
					workers.put("workerCount", 4);
					workers.put("workerMemory", 1024);
					workers.put("workerTemp", "C:/temp");
					processor.setParallelProcessingSettings(workers);
					
					Map<String,Object> settings = new HashMap<String,Object>();
					settings.put("workerItemCallback", "java:com.nuix.gutenberg.FeelingsCallback");
					processor.setProcessingSettings(settings);
					
					processor.whenItemProcessed(new nuix.ItemProcessedCallback(){
						public void itemProcessed(nuix.ProcessedItem item) {
							StringBuilder path = new StringBuilder();
							for(String s : item.getPath())
								path.append(s + "\\");
							logger.info("Processed " + path.substring(0, path.length() - 1));
						}
					});
					
					processor.whenProgressUpdated(new nuix.ProgressUpdatedCallback(){
						public void progressUpdated(nuix.ProcessingProgressInfo info) {
							logger.info("Progress: " + info.getCurrentSize() + "/" + info.getTotalSize());
						}
					});
					
					processor.whenCleaningUp(new nuix.ProcessorCleaningUpCallback(){
						public void cleaningUp() {
							logger.info("Cleaning up...");
						}
					});
				
					nuix.EvidenceContainer evidence = processor.newEvidenceContainer("My Reading List");
					Map<String,String> containerMetadata = new HashMap<String,String>();
					evidence.addFile("books-to-read");
					evidence.save();
					logger.info("Initiating processing");
					long start = System.currentTimeMillis();
					processor.process();
					logger.info("Processed " + caze.getStatistics().getFileSize("*", null)/1024/1024 + "mb in " + elapsed(start, System.currentTimeMillis()));
				}
			}
		}
				
	}
	
	public static Utilities getUtilities(Engine engine) throws Exception {
		engine.whenAskedForCredentials(new CredentialsCallback(){
			@Override
			public void execute(CredentialsCallbackInfo callback) {
				callback.setUsername("codemonkey");
				callback.setPassword("codemonkey");
			}
		});
		Licensor licensor = engine.getLicensor();
		for(LicenceSource source : licensor.findLicenceSources()) {
			try {
				for(AvailableLicence available : source.findAvailableLicences()) {
					if(available.getShortName().compareToIgnoreCase("enterprise-workstation") == 0  && source.getLocation().toLowerCase().compareToIgnoreCase("CON-DBX01-LAP.nuix.com:27443") == 0) {
						available.acquire();
						return engine.getUtilities();
					}
				}
			} catch(Exception ex) {
				logger.error(ex);
			}
		}
		throw new Exception("Unable to acquire the desired license.  Please review the configuration and ensure the specified license source and type is available.");
	}

	public static String elapsed(long start, long finish) {
		long elapsed = finish - start;
		long days = TimeUnit.MILLISECONDS.toDays(elapsed);
		long hours = TimeUnit.MILLISECONDS.toHours(elapsed) - TimeUnit.DAYS.toHours(TimeUnit.MILLISECONDS.toDays(elapsed));
		long minutes = TimeUnit.MILLISECONDS.toMinutes(elapsed) - TimeUnit.HOURS.toMinutes(TimeUnit.MILLISECONDS.toHours(elapsed));
		long seconds = TimeUnit.MILLISECONDS.toSeconds(elapsed) - TimeUnit.MINUTES.toSeconds(TimeUnit.MILLISECONDS.toMinutes(elapsed));
		long millis = elapsed - TimeUnit.SECONDS.toMillis(TimeUnit.MILLISECONDS.toSeconds(elapsed));
		return days + "-days " + hours + "-hours " + minutes + "-minutes " + seconds + "-seconds " + millis + "-milliseconds";
	}
}
