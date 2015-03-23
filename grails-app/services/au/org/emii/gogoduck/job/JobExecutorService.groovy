package au.org.emii.gogoduck.job

import au.org.emii.gogoduck.worker.Worker


class JobExecutorService {

    static final JobQueue JOB_QUEUE = new JobQueue()

    def grailsApplication
    def jobStoreService
    def notificationService

    static {
        new Thread(JOB_QUEUE).start()
    }

    static void clearQueue() {
        JOB_QUEUE.clear()
    }

    def register(job) {
        setJobStatusAndSave(job, Status.NEW)
        notificationService.sendJobRegisteredNotification(job)

        JOB_QUEUE.offer([job: job, executor: this])
        log.debug "job offered, queue size: ${JOB_QUEUE.size()}"
    }

    def run(job) {
        setJobStatusAndSave(job, Status.IN_PROGRESS)
        newWorker(job).run(successHandler, failureHandler)
    }

    def newWorker(job) {
        return new Worker(
            shellCmd: grailsApplication.config.worker.cmd,
            job: job,
            outputFilename: jobStoreService.getAggrPath(job),
            reportFilename: jobStoreService.getReportPath(job),
            maxGogoduckTimeMinutes: grailsApplication.config.worker.maxGogoduckTimeMinutes,
            fileLimit: grailsApplication.config.worker.fileLimit
        )
    }

    def getQueuePosition(job) {
        return JOB_QUEUE.getQueuePosition(job)
    }

    def successHandler = {
        job ->

        setJobStatusAndSave(job, Status.SUCCEEDED)
        notificationService.sendJobSuccessNotification(job)
    }

    def failureHandler = {
        job ->

        setJobStatusAndSave(job, Status.FAILED)
        notificationService.sendJobFailureNotification(job)
    }

    def setJobStatusAndSave(job, status) {
        job.status = status
        jobStoreService.save(job)
    }
}
