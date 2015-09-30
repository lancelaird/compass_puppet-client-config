'use strict';

var stack = null;
// Automation of component stack version is not supported by public CUDL APIs and is deprecated at this time
//try {
//    stack = require('../../stack'); // May be overridden in enclosing component puppet repo
//} catch (e) {
//    stack = require('./stack'); // Default is mananged centrally suitable for all but shared components
//}

var sami = require('./sami');

function Component(name, version) {

    // To manally validate your JSON, run 'node' on cmd line (REPL) and paste in the following:
    // var Component = require('./component'); new Component("Very Special Component", 42);

    var group = "Compass Monitoring"; // Umbrella for all compass tools as per Mat

    // We assume that component and stack are given the same name by designer in CUDL!
    var componentname = name;
    var componentstackname = name;

    var shortId = (name + '-' + version).replace(/\s/g, "_").toLowerCase();
    var fullyQualifiedId = (group + '.' + name + '-' + version).replace(/\s/g, "_").toLowerCase();

    var componentversionUid = "config:componentversion:aggregator:" + fullyQualifiedId;
    var componentstackversionUid = "config:componentstackversion:aggregator:" + fullyQualifiedId;

    // Used at deploy time until we have ENC and deployment group
    // As per Chris: Take 'componentstackname' => 'platform_core' + '_' +  'version' => '1.0.15'
    // and perform the gsub on it (so all non-word characters become '_'), in ruby:
    // environment = "#{@component_group['componentstackname']}_#{@component_group['version']}".gsub(/\W/,'_')
    var environment = (componentstackname + '_' + version).replace(/\W/g, "_").toLowerCase();

    //var httpRepoUrl = "http://pcpuppetmoma.amers1.ciscloud/puppet-master-package-1.0.10.auto-2.tar";
    //var httpRepoUrl = "http://upg-fileserver.emea1.ciscloud/compass/";

    // Use SAMI artifacts for faster pipeline as no replication delay to regional fileservers like above
    var httpRepoUrl = sami.translateRepoUrl(process.env.SAMI_URL);

    var packageurl = httpRepoUrl + shortId + ".tar";

    // e.g. If you want to use r10k, this is using raw git protocol to an arbitrary box running git daemon, not a real repo!
    // var packageurl = "git://andy-compass-test-3.amers1b.ciscloud/compass_puppet-web-homepage-r10k";

//    http://eikonrelease.thomsonreuters.com/api/v1/components?componentgroup=%22Compass%20Tools%22

    var componentversion = JSON.stringify({
        platform: "eikon",
        uid: componentversionUid,
        source: "aggregator",
        sourceid: fullyQualifiedId,
        type: "componentversion",
        componentgroup: group,
        nature: "config",
        componentreleaseversion: version, // We allow hypens here for now, Rafe prefers underscores
        component: componentname,
        packageurl: packageurl,
        versionvalidated: "" // Setting or resetting to blank will trigger puppet master jenkins
    });

    // By default assume stack not required and we shouldn't build one, return null
    componentstackversion = null;

    if (stack !== null) {

        console.info("\nStack:\n");
        console.info(stack);

        var stackArray = stack.stack;

        stackArray.unshift(componentversionUid); // Insert new component version at the beginning of the array

        var componentstackversion = JSON.stringify({
            componentreleaseversion: stackArray,

//        componentreleaseversion: [
//            componentversionUid,
//            "config:componentversion:aggregator:compass_tools.shared_compass-0.1.1.master-manual-2007",
//            "config:componentversion:aggregator:compass_deployment_automation.cda_agent-0.2.2" // Contains LVM and StdLib puppet labs modules. LVM now in cda-base which is implicit!
////        "config:componentversion:aggregator:cda_agent-0.2.1" // Contains LVM and StdLib puppet labs modules. LVM now in cda-base which is implicit!
////        "config:componentversion:aggregator:clientplatformcore-0.0.15" // Contains LVM and StdLib puppet labs modules. LVM now in cda-base which is implicit!
//        ],
            version: version,
            componentnameinstack: [
                "empty"
            ],
            type: "componentstackversion",
            uid: componentstackversionUid,
            nature: "config",
            componentstackname: componentstackname,
            source: "aggregator",
            puppetrejected: "",
            sourceid: fullyQualifiedId,
            versionvalidated: "" // Setting or resetting to blank will trigger puppet master jenkins
        });
    }

    console.info("\nComponent UID '" + componentversionUid + "' for component " + componentversion);
    console.info("\nComponent Stack UID '" + componentstackversionUid + "' for component " + componentstackversion);
    console.info("\nEnvironment: " + environment + "\n");

    this._componentversion = componentversion;
    this._componentversionUid = componentversionUid;
    this._componentstackversion = componentstackversion;
    this._componentstackversionUid = componentstackversionUid;
    this._environment = environment;
}

Component.prototype.componentversion = function () {
    return this._componentversion;
};
Component.prototype.componentstackversion = function () {
    return this._componentstackversion;
};
Component.prototype.componentversionUid = function () {
    return this._componentversionUid;
};
Component.prototype.componentstackversionUid = function () {
    return this._componentstackversionUid;
};
Component.prototype.environment = function () {
    return this._environment;
};

module.exports = Component;
