var http = require("http");
var https = require("https");

// Arguments
var args = process.argv.slice(2);

//if (args.length != 2) {
//    console.error("CUDL REST Client expects exactly two args: <component> <version>");
//    process.exit(1);
//}

//var component = args[0];
//var version = args[1];
////var component = "puppet-master-package";
////var version = "1.0.10.auto-2";
//
////var httpRepoUrl = "http://pcpuppetmoma.amers1.ciscloud/puppet-master-package-1.0.10.auto-2.tar";
////var httpRepoUrl = "http://upg-fileserver.emea1.ciscloud/compass/";
//var httpRepoUrl = "https://s.sa.robot:Manager2010@sami.cdt.int.thomsonreuters.com/binarystore/Releases/Mount17/cpit_compass/";
//var packageurl = httpRepoUrl + component + "-" + version + ".tar";
//
//var componentname = "compass_puppet";
//var componentstackname = "compass_puppet";
//var sourceid = component + "-" + version;
//var componentversionUid = "config:componentversion:aggregator:" + sourceid;
//var componentstackversionUid = "config:componentstackversion:aggregator:" + sourceid;
//
//// Used at deploy time:
//// As per Chris: Take 'componentstackname' => 'platform_core' + '_' +  'version' => '1.0.15'
//// and perform the gsub on it (so all non-word characters become '_'), in ruby:
//// environment = "#{@component_group['componentstackname']}_#{@component_group['version']}".gsub(/\W/,'_')
//var environment = componentstackname + '_' + version
//    .replace(/\W/g, "_");

//var componentversion = JSON.stringify({
//    platform: "compass",
//    uid: componentversionUid,
//    sourceid: sourceid,
//    type: "componentversion",
//    componentgroup: "compass",
//    nature: "config",
//    componentreleaseversion: version,
//    component: componentname,
//    packageurl: packageurl,
//    versionvalidated: "", // Setting or resetting to blank will trigger puppet master jenkins
//    source: "aggregator"
//});

//
//var componentstackversion = JSON.stringify({
//    componentreleaseversion: [
//        componentversionUid,
//        // TODO Compass Mon Client - Release UI?
//        "config:componentversion:aggregator:clientplatformcore-0.0.15" // Contains LVM and StdLib puppet labs modules
//    ],
//    version: version,
//    componentnameinstack: [
//        "empty"
//    ],
//    type: "componentstackversion",
//    uid: componentstackversionUid,
//    versionvalidated: "", // Setting or resetting to blank will trigger puppet master jenkins
//    nature: "config",
//    componentstackname: componentstackname,
//    source: "aggregator",
//    puppetrejected: "",
//    sourceid: sourceid
//});


var deployGroupHackDev = JSON.stringify(
    {
        "name": "andy-compass-test-3 - andyw and AJ Thursday test - try 1",
        "uid": "config:deploymentgroup:aggregator:1412267652994", // Not set in UI
        "sourceid": 1412267652994, // Not set in UI
        "nature": "config",
        "type": "deploymentgroup",
        "componentstackversion": {
            "uid": "config:componentstackversion:aggregator:1412267431177"
        }
    }
);

var deployGroupHackProd = JSON.stringify( //
    {
        name: "Compass Web EMEA Production - Release 418",
        uid: "config:deploymentgroup:aggregator:1412332229590",
        sourceid: 1412332229590,
        "nature": "config",
        "type": "deploymentgroup",
        "componentstackversion": {
            "uid": "config:componentstackversion:aggregator:compass-puppet-master-package-1.0.10.master-manual-418"
        }
    }
);

// must be POST not PUT with POSTMAN?!

var deployGroupHackProdTry2 = JSON.stringify( // If you copy/paste into postman don't forget to quote all field names
    {
        "name": "Compass Web EMEA Production - Release 418 - try 2",
        "uid": "config:deploymentgroup:aggregator:1412337371253",
        "sourceid": 1412337371253,
        "nature": "config",
        "type": "deploymentgroup",
        "componentstackversion": {
            "uid": "config:componentstackversion:aggregator:compass-puppet-master-package-1.0.10.master-manual-418"
        }
    }
);


// Interact with CDA puppet master via CUDL

// CUDL production URL
//var cudlHost = 'eikonrelease.thomsonreuters.com';
var cudlHost = 'ermt-app-tst.emea1.ciscloud';
var cudlAPIprefix = '/api/v1/';

////component
////http://ermt-app-tst.emea1.ciscloud/api/v1/componentversions?uid=config:componentversion:aggregator:puppet-master-package-1.0.10.auto-20
//var cudlComponentGet = 'http://' + cudlHost + cudlAPIprefix + 'componentversions?uid=' + componentversionUid;
////componentstack:
////http://ermt-app-tst.emea1.ciscloud/api/v1/componentstackversions?uid=config:componentstackversion:aggregator:puppet-master-package-1.0.10.auto-20
//var cudlComponentVersionGet = 'http://' + cudlHost + cudlAPIprefix + 'componentstackversions?uid=' + componentstackversionUid;

function cudlRestCall(method, data, cb) {
    var options = {
        host: cudlHost,
        path: cudlAPIprefix + method,
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(data, 'utf8')
        }
    };
    console.info('Options prepared:');
    console.info(options);
    console.info('Data prepared:');
    console.info(data);
    console.info('Do the PUT call');

    var request = http.request(options, function (response) {
        var buffer = '';
        response.on('data', function (chunk) {
            buffer += chunk;
        });
        response.on('end', function () {
            console.info('PUT result:\n');
            process.stdout.write(buffer);
            console.info('\nPUT completed');
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


// Serial Execution required
//cudlRestCall('selfregistrationdevices', prodHost, function (e) {
//    if (e) {
//        process.exit(1);
//    }
//});

cudlRestCall('deploymentgroups', deployGroupHackProd, function (e) {
    if (e) {
        process.exit(1);
    }
});

