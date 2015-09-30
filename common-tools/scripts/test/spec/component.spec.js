'use strict';

var
  chai = require('chai'),
  expect = chai.expect;

var Component = require('../../component');

describe('test component object', function () {
  afterEach(function () {
    delete process.env.SAMI_URL;
  });
  it("should instantiate a very special component", function () {
    process.env.SAMI_URL = "ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compass/";
    var specialComponent = new Component("Very Special Component", 42);

    console.info(specialComponent);

    var componentversion = JSON.parse(specialComponent._componentversion);

    expect(componentversion.component).to.be.equal("Very Special Component");
    expect(componentversion.componentreleaseversion).to.be.equal(42);
    expect(componentversion.packageurl).to.be.equal("https://s.sa.robot:Manager2010@sami.cdt.int.thomsonreuters.com/binarystore/Releases/Mount17/cpit_compass/very_special_component-42.tar");
  });
  it("should instantiate a special component called snark", function () {
    process.env.SAMI_URL = "ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compassfile/snark/";
    var specialComponent = new Component("Snark Component", 777);

    console.info(specialComponent);

    var componentversion = JSON.parse(specialComponent._componentversion);

    expect(componentversion.component).to.be.equal("Snark Component");
    expect(componentversion.componentreleaseversion).to.be.equal(777);
    expect(componentversion.packageurl).to.be.equal("https://s.sa.robot:Manager2010@sami.cdt.int.thomsonreuters.com/binarystore/Releases/Mount17/cpit_compassfile/snark/snark_component-777.tar");
  });

});






















