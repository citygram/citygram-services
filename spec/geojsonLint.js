var path = require('path');
var expect = require('chai').expect;

var geojsonLint = require(path.join(__dirname, '..', './geojsonLint.js'));

describe('geojsonLint()', function () {
  'use strict';

  it('exists', function () {
    expect(geojsonLint).to.be.a('Object');

  });

});

describe('all()', function () {
  it('finds all endpoints to test', function () {
    expect(geojsonLint.all).to.be.a('function')
  });
});

describe('testPath()', function() {
  it("should be a function", function () {
    expect(geojsonLint.testPath).to.be.a('function')
  });

  it("should test a path", function () {
    var firstPath = geojsonLint.findEndpoints()[0];
    expect(geojsonLint.testPath(firstPath)).to.be.true
  });

});

describe('findEndpoints()', function () {
  it('finds all endpoints to test', function () {
    expect(geojsonLint.findEndpoints).to.be.a('function')
  });

  it('returns more than a dozen values', function () {
    expect(geojsonLint.findEndpoints()).to.be.an('Array')
    expect(geojsonLint.findEndpoints().length).to.be.above(12)
  });

  it('strips RB from filenames', function () {
    var firstPath = geojsonLint.findEndpoints()[0];
    expect(firstPath).to.be.an('String');
    expect(firstPath).not.to.match(/rb/);
  });
});
