#!/bin/bash

#
# gogoduck.sh - a netcdf aggregator
# Copyright (C) 2013 Dan Fruehauf <malkoadan@gmail.com>
# Copyright (C) 2013 IMOS <imos.org.au>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

# given a plugin name, it'll find the most appropriate plugin for it
test_get_profile_module() {
    source $GOGODUCK_NO_MAIN
    local profile

    profile=`_get_profile_module acorn`
    profile=`basename $profile`
    assertTrue 'acorn -> acorn' \
        "[ "$profile" = "acorn" ]"

    profile=`_get_profile_module acorn_uga_booga`
    profile=`basename $profile`
    assertTrue 'acorn_uga_booga -> acorn' \
        "[ "$profile" = "acorn" ]"

    profile=`_get_profile_module profiles/uga_booga`
    profile=`basename $profile`
    assertTrue 'profiles/acorn_uga_booga -> profiles/acorn' \
        "[ "$profile" = "default" ]"
}

# test if acorn can get some files for a specific layer
test_get_files_acorn() {
    source $GOGODUCK_NO_MAIN
    local tmp_file=`mktemp`
    _get_list_of_urls profiles/acorn acorn_hourly_avg_sag_nonqc_timeseries_url $tmp_file "TIME,2013-12-21T00:30:00.000Z,2013-12-21T04:30:00.000Z;LATITUDE,-36.375741295316,-35.683114342188;LONGITUDE,134.60681553516,136.11743565234" acorn_hourly_avg_sag_nonqc_timeseries_url

    # expect 5 urls
    assertTrue '5 urls returned for acorn_hourly_avg_sag_nonqc_timeseries_url 21/12/2013 00:30-04:30' \
        "[ `cat $tmp_file | wc -l` -eq 5 ]"

    rm -f $tmp_file
}

# test file limit in gogoduck, not allowing processing of too many files
test_file_limit() {
    source $GOGODUCK_NO_MAIN

    local tmp_file=`mktemp`
    # generate a file with 5 lines
    seq 1 5 > $tmp_file

    _enforce_file_limit $tmp_file 4 >& /dev/null
    local -i retval=$?
    assertFalse 'enforcing limit (4) on 5 urls' \
        "[ $retval -eq 0 ]"

    _enforce_file_limit $tmp_file 10 >& /dev/null
    local -i retval=$?
    assertTrue 'allowing limit (10) on 5 urls' \
        "[ $retval -eq 0 ]"

    rm -f $tmp_file
}

# test for acorn metadata update
test_header_acorn_metadata() {
    source $GOGODUCK_NO_MAIN
    local tmp_netcdf=`mktemp`

    # download some random netcdf file
    curl -s -o $tmp_netcdf \
        "http://data.aodn.org.au/IMOS/opendap/ACORN/gridded_1h-avg-current-map_QC/ROT/2012/04/04/IMOS_ACORN_V_20120404T033000Z_ROT_FV01_1-hour-avg.nc"

    _update_header profiles/acorn acorn_hourly_avg_rot_qc_timeseries_url $tmp_netcdf \
        "TIME,2013-11-20T00:30:00.000Z,2013-11-20T10:30:00.000Z;LATITUDE,-33.433849,-32.150743;LONGITUDE,114.15197,115.741219"


    local title=`ncdump $tmp_netcdf | grep ":title" | cut -d\" -f2`
    assertTrue 'aggregated file title' \
        '[ "$title" = "IMOS ACORN Rottnest Shelf (ROT), one hour averaged current QC data, 2013-11-20T00:30:00.000Z, 2013-11-20T10:30:00.000Z" ]'

    local geospatial_lon_min=`ncdump $tmp_netcdf | grep ":geospatial_lon_min" | cut -d\" -f2`
    assertTrue 'aggregated file lon_min' \
        '[ "$geospatial_lon_min" = "114.15197" ]'


    local geospatial_lon_max=`ncdump $tmp_netcdf | grep ":geospatial_lon_max" | cut -d\" -f2`
    assertTrue 'aggregated file lon_max' \
        '[ "$geospatial_lon_max" = "115.741219" ]'


    local geospatial_lat_min=`ncdump $tmp_netcdf | grep ":geospatial_lat_min" | cut -d\" -f2`
    assertTrue 'aggregated file lat_min' \
        '[ "$geospatial_lat_min" = "-33.433849" ]'

    local geospatial_lat_max=`ncdump $tmp_netcdf | grep ":geospatial_lat_max" | cut -d\" -f2`
    assertTrue 'aggregated file lat_max' \
        '[ "$geospatial_lat_max" = "-32.150743" ]'


    local time_coverage_start=`ncdump $tmp_netcdf | grep ":time_coverage_start" | cut -d\" -f2`
    assertTrue 'aggregated file time_coverage_start' \
        '[ "$time_coverage_start" = "2013-11-20T00:30:00.000Z" ]'

    local time_coverage_end=`ncdump $tmp_netcdf | grep ":time_coverage_end" | cut -d\" -f2`
    assertTrue 'aggregated file time_coverage_end' \
        '[ "$time_coverage_end" = "2013-11-20T10:30:00.000Z" ]'

    rm -f $tmp_netcdf
}

# integration test for testing acorn
test_aggregation_acorn_file_size() {
    source $GOGODUCK_NO_MAIN
    local tmp_output_file=`mktemp`
    gogoduck_main \
        100 \
        "acorn_hourly_avg_rot_qc_timeseries_url" \
        "TIME,2013-11-20T00:30:00.000Z,2013-11-20T10:30:00.000Z;LATITUDE,-33.433849,-32.150743;LONGITUDE,114.15197,115.741219" \
        $tmp_output_file >& /dev/null

    local -i file_size=`cat $tmp_output_file | wc --bytes`
    rm -f $tmp_output_file

    # expect something like 100KB, OK?? :)
    assertTrue 'acorn aggregation file size is around 100KB' \
        "[ $file_size -lt 130000 ] && [ $file_size -gt 80000 ]"
}


##################
# SETUP/TEARDOWN #
##################

oneTimeSetUp() {
    # load include to test
    GOGODUCK=`dirname $0`/gogoduck.sh
    GOGODUCK_NO_MAIN=`mktemp`
    sed -e 's/^main .*//' $GOGODUCK > $GOGODUCK_NO_MAIN
}

oneTimeTearDown() {
    rm -f $GOGODUCK_NO_MAIN
}

setUp() {
    true
}

tearDown() {
    true
}

# load and run shUnit2
. /usr/share/shunit2/shunit2