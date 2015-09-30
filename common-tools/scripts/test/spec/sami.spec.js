'use strict';

var
  chai = require('chai'),
  expect = chai.expect;

var sami = require('../../sami');

describe('test sami helpers', function () {
  beforeEach(function () {
    delete process.env.SAMI_URL;
  });
  it("should translate ftps sami url to https, when no dedicated app repo", function () {
    var ftpsRepoURL = "ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compass/";
    var httpsRepoUrl = sami.translateRepoUrl(ftpsRepoURL);

    expect(httpsRepoUrl).to.be.equal("https://s.sa.robot:Manager2010@sami.cdt.int.thomsonreuters.com/binarystore/Releases/Mount17/cpit_compass/");
  });
  it("should translate alternate ftps sami url to https, when no dedicated app repo", function () {
    var ftpsRepoURL = "ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_compass/";
    var httpsRepoUrl = sami.translateRepoUrl(ftpsRepoURL);

    expect(httpsRepoUrl).to.be.equal("https://s.sa.robot:Manager2010@sami.cdt.int.thomsonreuters.com/binarystore/Releases/Mount17/cpit_compass/");
  });
  it("should translate alternate ftps sami url to https, with dedicated app repo for homepage", function () {
    var ftpsRepoURL = "ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compassfile/homepage/";
    var httpsRepoUrl = sami.translateRepoUrl(ftpsRepoURL);

    expect(httpsRepoUrl).to.be.equal("https://s.sa.robot:Manager2010@sami.cdt.int.thomsonreuters.com/binarystore/Releases/Mount17/cpit_compassfile/homepage/");
  });
  it("should translate ftps sami url to https, with dedicated app repo for snark", function () {
    var ftpsRepoURL = "ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_compassfile/snark/";
    var httpsRepoUrl = sami.translateRepoUrl(ftpsRepoURL);

    expect(httpsRepoUrl).to.be.equal("https://s.sa.robot:Manager2010@sami.cdt.int.thomsonreuters.com/binarystore/Releases/Mount17/cpit_compassfile/snark/");
  });
  it("should be able to translate ftps sami url from SAMI_URL environment variable", function () {
    process.env.SAMI_URL = "ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compass/";
    var httpsRepoUrl = sami.translateRepoUrl(process.env.SAMI_URL);

    expect(httpsRepoUrl).to.be.equal("https://s.sa.robot:Manager2010@sami.cdt.int.thomsonreuters.com/binarystore/Releases/Mount17/cpit_compass/");
  });

});






















