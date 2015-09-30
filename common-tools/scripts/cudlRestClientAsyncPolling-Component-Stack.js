'use strict';

var Component = require('./component');

// Arguments
var args = process.argv.slice(2);

if (args.length !== 2) {
    console.error("CUDL REST Client expects exactly two args: <component> <version>");
    process.exit(1);
}

var name = args[0];
var version = args[1];

var component = new Component(name, version);

var componentversion = component.componentversion();
var componentversionUid = component.componentversionUid();
var componentstackversion = component.componentstackversion();
var componentstackversionUid = component.componentstackversionUid();
var environment = component.environment();

//console.info("\nComponent UID '" + componentversionUid + "' for component " + componentversion);
//console.info("\nComponent Stack UID '" + componentstackversionUid + "' for component " + componentstackversion);
//console.info("\nEnvironment: " + environment + "\n");

// Interact with UPG puppet master via CUDL

////////////////////////////////
var http = require("http");
var cudlHost = 'api.compass.int.thomsonreuters.com'; // 2015 New API HTTP only endpoint for internal integration
var cudlAPIprefix = '/common/cudl/v1/';
////////////////////////////////
//var http = require("https");
//var cudlHost = 'compass.thomsonreuters.com'; // 2014 CUDL production URL
//var cudlAPIprefix = '/api/common/cudl/v1/';
////////////////////////////////
//var http = require("http");
//var cudlHost = 'ermt-app-tst.emea1.ciscloud'; // Build 10xx
//var cudlAPIprefix = '/api/v1/';
////////////////////////////////

//var cudlHost = 'eikonrelease.thomsonreuters.com'; // Now hopelessly out of date 4xx

function cudlRestPut(method, data, cb) {
    var options = {
        host: cudlHost,
        path: cudlAPIprefix + method,
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            'X-Compass-APIKEY': 'Cx6wdERJKPuBQszMkCYm1yaf9Z10R3Pd3XbFHxtUM7ObgWZszYmGCUvdxa3nxHwD',
            'Content-Length': Buffer.byteLength(data, 'utf8')
        }
    };
//    console.info('Options prepared:');
//    console.info(options);
//    console.info('Data prepared:');
//    console.info(data);

    var request = http.request(options, function (response) {
        var buffer = '';
        response.on('data', function (chunk) {
            buffer += chunk;
        });
        response.on('end', function () {
            console.info('PUT result:');
            console.info(buffer);
            console.info('PUT completed');
            cb();
        });
    });

    request.on('error', function (e) {
        console.error('HTTP Error talking to server hosting CUDL API: ' + e.message);
        cb(e);
    });

    request.write(data);
    request.end();
}

function cudlRestGet(method, uid, cb) {
    var options = {
        host: cudlHost,
        path: cudlAPIprefix + method + '?uid=' + uid,
        method: 'GET'
    };
//    console.info('Options prepared:');
//    console.info(options);
//    console.info('Do the GET call');

    var request = http.request(options, function (response) {
        var buffer = '';
        response.on('data', function (chunk) {
            buffer += chunk;
        });
        response.on('end', function () {
//            console.info('GET result:');
//            console.info(buffer);
//            console.info('GET completed');
            try {
                var resp = JSON.parse(buffer);
                if (!resp || resp.length === 0) {
                    console.error('Empty Response from CUDL!');
                    cb(true, null);
                }
                cb(null, resp);
            } catch (syntaxError) {
                // Don't print the syntax parse error as it's not relevant in practice...the error is the body of the message!
                console.error(buffer);
                console.error('CUDL API Error');
                cb(syntaxError, null);
            }
        });
    });

    request.on('error', function (e) {
        console.error('HTTP Error talking to server hosting CUDL API: ' + e.message);
        cb(e);
    });

    request.end();
}

var interval = 10000; // poll every 10s for validation status, five secs too chatty

var componentversionUrl = 'http://' + cudlHost + cudlAPIprefix + 'componentversions?uid=' + componentversionUid;
var componentstackversionUrl ='http://' + cudlHost + cudlAPIprefix + 'componentstackversions?uid=' + componentstackversionUid;

// Serial Execution required

console.info('\nPUT to CUDL: ' + componentversionUrl);
console.info(componentversion);

cudlRestPut('componentversions', componentversion, function (e) {
    e && process.exit(1);
    // schedule polling for completion of puppet validation using tail recursion
    console.info('\nPolling...');
    (function schedule() {
        setTimeout(function () {
            console.info('GET from CUDL: ' + componentversionUrl);
            cudlRestGet('componentversions', componentversionUid, function (e, data) {
                    e && process.exit(1);
                    // Chris has added intermediate "processing" status, which means we must check for 'true' rather not being 'false' or empty
                    var status = data[0].versionvalidated;
                    if (status !== null && status == 'false') {
                        console.info(data);
                        console.error('CUDL Component Version Validation Failed!');
                        process.exit(1);
                    }
                    else if (status !== null && status == 'true')  {
                        // shared components won't have a stack of their own
                        if (componentstackversion !== null) {
                            console.info('\nPUT to CUDL: ' + componentstackversionUrl);
                            console.info(componentstackversion);
                            cudlRestPut('componentstackversions', componentstackversion, function (e) {
                                e && process.exit(1);
                                // schedule polling for completion of puppet validation using tail recursion
                                console.info('\nPolling...');
                                (function schedule() {
                                    setTimeout(function () {
                                        console.info('GET from CUDL: ' + componentstackversionUrl);
                                        cudlRestGet('componentstackversions', componentstackversionUid, function (e, data) {
                                                e && process.exit(1);
                                                // Chris has added intermediate "processing" status, which means we must check for 'true' rather not being 'false' or empty
                                                var status = data[0].versionvalidated;
                                                if (status !== null && status == 'false') {
                                                    console.info(data);
                                                    console.error('CUDL Component Stack Version Validation Failed!');
                                                    process.exit(1);
                                                }
                                                else if (status !== null && status == 'true') {
//                                                console.info('\nEnsure versionvalidated is true for your component and componentstack versions below, after a few minutes before procedeing.');
//                                                console.info(cudlComponentGet);
//                                                console.info(cudlComponentVersionGet);

                                                    console.info(data);

                                                    console.info('\nTo deploy this release, puppet master must run with environment: ' + environment);
                                                    console.info('On a CIS machine, trigger puppet agent against master run manually as root:');
                                                    console.info('> sudo puppet agent -t --server nonprod.puppet.int.thomsonreuters.com --environment ' + environment);

                                                    console.info('\nAfter component version validation you must wait 2-4 minutes for global puppet master catalog to be updated, before triggering puppet agent!');

                                                    process.exit(0);
                                                } else {
                                                    // Assume intermediate status if 'processing', '' or null
                                                    schedule();
                                                }
                                            }
                                        )
                                        ;
                                    }, interval)
                                })();
                            });
                        }
                    } else {
                        // Assume intermediate status if 'processing', '' or null
                        schedule();
                    }
                }
            )
            ;
        }, interval)
    })();
});

// TODO We need to add error handling for CUDL PUT errors ... we handle GET
//        Do the PUT call
//        PUT result:
//
//          Error 405: ["componentversions is mandatory"]
//        PUT completed
// Or http rather than https
//PUT result:
//    <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
//        <html><head>
//            <title>405 Method Not Allowed</title>
//        </head><body>
//            <h1>Method Not Allowed</h1>
//            <p>The requested method PUT is not allowed for the URL /api/v1/componentversions.</p>
//            <hr>
//                <address>Apache/2.2.15 (Oracle) Server at compass.thomsonreuters.com Port 80</address>
//            </body></html>
//
//        PUT completed
