'use strict';

// Automation of component stack version is not supported by public CUDL APIs and is deprecated at this time
// Setting to null to skip processing of stack, stopping instead after component version
module.exports = null;

//module.exports = {
//    stack: [
//        "config:componentversion:aggregator:compass_tools.shared_compass-0.1.1.master-manual-2007",
//        "config:componentversion:aggregator:compass_deployment_automation.cda_agent-0.2.2" // Contains LVM and StdLib puppet labs modules. LVM now in cda-base which is implicit!
//    ]
//};

