package au.org.emii.gogoduck.job

import grails.test.mixin.*
import spock.lang.Specification

import au.org.emii.gogoduck.test.TestHelper

class JobSpec extends Specification {
    def "initialised with a UUID"() {
        given:
        Set<String> existingIds = new HashSet<String>()

        expect:

        // Ok, not mathematically fool proof, but good enough for us (probably).
        1000.times {
            def job = TestHelper.createJob()
            assert job.getUuid()
            assert existingIds.add(job.getUuid())
        }
    }

    def "to JSON"() {
        given:
        def job = TestHelper.createJob()
        job.uuid = '1234'

        def expectedJson = '''{
   "subsetDescriptor": {
      "spatialExtent": {
         "south": "-33.433849",
         "north": "-32.150743",
         "east": "115.741219",
         "west": "114.15197"
      },
      "temporalExtent": {
         "start": "2013-11-20T00:30:00.000Z",
         "end": "2013-11-20T10:30:00.000Z"
      }
   },
   "emailAddress": "gogo@duck.com",
   "layerName": "some_layer",
   "uuid": "1234"
}'''

        expect:
        job.toJsonString() == expectedJson
    }
}
