var path = require('path');
var expect = require('chai').expect;

var geojsonLint = require(path.join(__dirname, '..', './geojsonLint.js'));

describe('geojsonLint()', function () {
  'use strict';

  it('exists', function () {
    expect(geojsonLint).to.be.a('function');

  });

  it('does something', function () {
    expect(true).to.equal(false);
  });

  it('does something else', function () {
    expect(true).to.equal(false);
  });

  // Add more assertions here
});
