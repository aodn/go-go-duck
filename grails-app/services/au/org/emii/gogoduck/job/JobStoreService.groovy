package au.org.emii.gogoduck.job

class JobStoreService {
    def grailsApplication

    Job getJob(uuid) {
        log.debug("file: ${getJsonPathForId(uuid)}, text: ${new File(getJsonPathForId(uuid)).text}")
        Job.fromJsonString(new File(getJsonPathForId(uuid)).text)
    }

    void makeDir(job) {
        log.debug("Making directory: ${getDir(job)}")
        new File(getDir(job)).mkdirs()
    }

    String getAggrPath(job) {
        getAggrPathForId(job.uuid)
    }

    File getAggrFile(job) {
        log.debug("File path: ${getAggrPath(job)}")
        new File(getAggrPath(job))
    }

    void writeToFileAsJson(job) {
        log.debug("Job: ${job.toJsonString()}")
        new File(getJsonPathForId(job.uuid)).write(job.toJsonString())
    }

    private String getDir(job) {
        getDirForId(job.uuid)
    }

    private String getDirForId(jobId) {
        "${grailsApplication.config.worker.outputPath}${File.separator}${jobId}"
    }

    private String getAggrPathForId(jobId) {
        "${getDirForId(jobId)}${File.separator}${grailsApplication.config.worker.outputFilename}"
    }

    private String getJsonPathForId(jobId) {
        "${getDirForId(jobId)}${File.separator}job.json"
    }
}