'use strict';

// Assume sami url is specified correctly with trailing slash by our bash script
function translateRepoUrl(ftpsRepoUrl) {
//  process.env.SAMI_URL = "ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compass/";
//  var httpsRepoUrl = "https://s.sa.robot:Manager2010@sami.cdt.int.thomsonreuters.com/binarystore/Releases/Mount17/cpit_compass/";

  var httpsURIPrefix = "https://s.sa.robot:Manager2010@sami.cdt.int.thomsonreuters.com/binarystore/Releases/";

  var httpsRepoUrl = ftpsRepoUrl.replace(/^.*\/Releases\//, httpsURIPrefix);

  return httpsRepoUrl;
}

module.exports.translateRepoUrl = translateRepoUrl;
