package com.sheetmusicreader;

import io.javalin.Javalin;
import io.javalin.http.Context;
import com.google.gson.Gson;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;

/**
 * REST API service for Audiveris OMR processing
 * 
 * This service wraps Audiveris (AGPLv3) and provides a simple REST API
 * for converting sheet music images/PDFs to MusicXML format.
 */
public class AudiverisService {
    private static final int DEFAULT_PORT = 8081;
    private static final String TEMP_DIR = System.getProperty("java.io.tmpdir") + "/audiveris-service";
    private static final Gson gson = new Gson();
    private static final Map<String, ConversionJob> jobs = new ConcurrentHashMap<>();
    private static final ExecutorService executor = Executors.newFixedThreadPool(4);

    public static void main(String[] args) {
        int port = args.length > 0 ? Integer.parseInt(args[0]) : DEFAULT_PORT;
        
        // Create temp directory
        new File(TEMP_DIR).mkdirs();
        
        Javalin app = Javalin.create(config -> {
            config.showJavalinBanner = false;
        }).start(port);

        System.out.println("Audiveris Service started on port " + port);
        
        // Health check endpoint
        app.get("/health", ctx -> {
            ctx.json(Map.of(
                "status", "ok",
                "service", "audiveris-omr",
                "version", "0.1.0"
            ));
        });
        
        // Convert image/PDF to MusicXML (synchronous)
        app.post("/convert", AudiverisService::handleConvertSync);
        
        // Convert image/PDF to MusicXML (asynchronous)
        app.post("/convert/async", AudiverisService::handleConvertAsync);
        
        // Get job status
        app.get("/status/{jobId}", AudiverisService::handleJobStatus);
        
        // Download result
        app.get("/jobs/{jobId}/download", AudiverisService::handleDownload);
        
        // List all jobs
        app.get("/jobs", ctx -> {
            ctx.json(jobs);
        });
    }

    private static void handleConvertSync(Context ctx) {
        try {
            // Get uploaded file
            var uploadedFile = ctx.uploadedFile("file");
            if (uploadedFile == null) {
                ctx.status(400).json(Map.of("status", "error", "message", "No file uploaded"));
                return;
            }

            // Generate job ID
            String jobId = UUID.randomUUID().toString();
            
            // Save uploaded file
            String inputPath = TEMP_DIR + "/" + jobId + "_input" + getFileExtension(uploadedFile.filename());
            Files.copy(uploadedFile.content(), Paths.get(inputPath), StandardCopyOption.REPLACE_EXISTING);
            
            // Process synchronously
            String outputPath = TEMP_DIR + "/" + jobId + "_output.musicxml";
            String musicXml = performConversion(inputPath, outputPath);
            
            if (musicXml != null) {
                ctx.json(Map.of(
                    "status", "success",
                    "musicxml", musicXml,
                    "jobId", jobId
                ));
            } else {
                ctx.status(500).json(Map.of(
                    "status", "error",
                    "message", "Conversion failed"
                ));
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            ctx.status(500).json(Map.of("status", "error", "message", e.getMessage()));
        }
    }

    private static void handleConvertAsync(Context ctx) {
        try {
            // Get uploaded file
            var uploadedFile = ctx.uploadedFile("file");
            if (uploadedFile == null) {
                ctx.status(400).json(Map.of("error", "No file uploaded"));
                return;
            }

            // Generate job ID
            String jobId = UUID.randomUUID().toString();
            
            // Save uploaded file
            String inputPath = TEMP_DIR + "/" + jobId + "_input" + getFileExtension(uploadedFile.filename());
            Files.copy(uploadedFile.content(), Paths.get(inputPath), StandardCopyOption.REPLACE_EXISTING);
            
            // Create job
            ConversionJob job = new ConversionJob(jobId, inputPath);
            jobs.put(jobId, job);
            
            // Start conversion asynchronously
            executor.submit(() -> processConversion(jobId, inputPath));
            
            ctx.json(Map.of(
                "jobId", jobId,
                "status", "processing"
            ));
            
        } catch (Exception e) {
            e.printStackTrace();
            ctx.status(500).json(Map.of("error", e.getMessage()));
        }
    }

    private static void handleJobStatus(Context ctx) {
        String jobId = ctx.pathParam("jobId");
        ConversionJob job = jobs.get(jobId);
        
        if (job == null) {
            ctx.status(404).json(Map.of("status", "error", "message", "Job not found"));
            return;
        }
        
        Map<String, Object> response = new HashMap<>();
        response.put("status", job.status);
        response.put("jobId", job.jobId);
        
        if (job.status.equals("completed") && job.outputPath != null) {
            try {
                String musicXml = Files.readString(Paths.get(job.outputPath));
                response.put("musicxml", musicXml);
            } catch (IOException e) {
                response.put("status", "error");
                response.put("message", "Failed to read output file");
            }
        } else if (job.status.equals("failed")) {
            response.put("message", job.error);
        }
        
        ctx.json(response);
    }

    private static void handleDownload(Context ctx) {
        String jobId = ctx.pathParam("jobId");
        ConversionJob job = jobs.get(jobId);
        
        if (job == null) {
            ctx.status(404).json(Map.of("error", "Job not found"));
            return;
        }
        
        if (!job.status.equals("completed")) {
            ctx.status(400).json(Map.of("error", "Job not completed"));
            return;
        }
        
        File outputFile = new File(job.outputPath);
        if (!outputFile.exists()) {
            ctx.status(404).json(Map.of("error", "Output file not found"));
            return;
        }
        
        ctx.contentType("application/xml");
        ctx.header("Content-Disposition", "attachment; filename=\"" + jobId + ".musicxml\"");
        ctx.result(new FileInputStream(outputFile));
    }

    private static void processConversion(String jobId, String inputPath) {
        ConversionJob job = jobs.get(jobId);
        
        try {
            job.status = "processing";
            job.startTime = System.currentTimeMillis();
            
            // Output path
            String outputPath = TEMP_DIR + "/" + jobId + "_output.musicxml";
            
            // Perform conversion
            performConversion(inputPath, outputPath);
            
            job.status = "completed";
            job.outputPath = outputPath;
            job.endTime = System.currentTimeMillis();
            
        } catch (Exception e) {
            job.status = "failed";
            job.error = e.getMessage();
            job.endTime = System.currentTimeMillis();
            e.printStackTrace();
        }
    }

    private static String performConversion(String inputPath, String outputPath) throws Exception {
        // TODO: Actual Audiveris integration
        // For now, this is a placeholder that would call Audiveris
        // The actual implementation would use Audiveris API:
        // 
        // Book book = OMR.engine.process(new File(inputPath));
        // book.export(new File(outputPath));
        
        // Simulate processing time
        Thread.sleep(2000);
        
        // Create dummy MusicXML for testing
        String dummyXml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
            "<!DOCTYPE score-partwise PUBLIC \"-//Recordare//DTD MusicXML 3.1 Partwise//EN\" " +
            "\"http://www.musicxml.org/dtds/partwise.dtd\">\n" +
            "<score-partwise version=\"3.1\">\n" +
            "  <work><work-title>Converted Sheet Music</work-title></work>\n" +
            "  <identification>\n" +
            "    <creator type=\"software\">Audiveris Service</creator>\n" +
            "  </identification>\n" +
            "  <part-list>\n" +
            "    <score-part id=\"P1\">\n" +
            "      <part-name>Music</part-name>\n" +
            "    </score-part>\n" +
            "  </part-list>\n" +
            "  <part id=\"P1\">\n" +
            "    <measure number=\"1\">\n" +
            "      <attributes>\n" +
            "        <divisions>1</divisions>\n" +
            "        <key><fifths>0</fifths></key>\n" +
            "        <time><beats>4</beats><beat-type>4</beat-type></time>\n" +
            "        <clef><sign>G</sign><line>2</line></clef>\n" +
            "      </attributes>\n" +
            "      <note><pitch><step>C</step><octave>4</octave></pitch><duration>4</duration><type>whole</type></note>\n" +
            "    </measure>\n" +
            "  </part>\n" +
            "</score-partwise>";
        
        Files.write(Paths.get(outputPath), dummyXml.getBytes());
        return dummyXml;
    }

    private static String getFileExtension(String filename) {
        int lastDot = filename.lastIndexOf('.');
        return lastDot > 0 ? filename.substring(lastDot) : "";
    }

    static class ConversionJob {
        String jobId;
        String inputPath;
        String outputPath;
        String status; // pending, processing, completed, failed
        String error;
        long startTime;
        long endTime;
        
        ConversionJob(String jobId, String inputPath) {
            this.jobId = jobId;
            this.inputPath = inputPath;
            this.status = "pending";
        }
    }
}
