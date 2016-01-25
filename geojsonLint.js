/*! geojsonLint v0.0.0 - MIT license */
'use strict';

var geojsonhint = require('geojsonhint');
var path = require('path');
var fs = require('fs');
var request = require('request');

var geojsonLint = {
  all: function (path, callback) {
    var allResults = findEndpoints.map( function(path) {
      return testPath(path, pathTester)
    });
    callback(allResults);
  },

  testPath: function (path, callback) {
    return request('http://localhost:5000/'+path, function (error, response, body) {
      if (!error && response.statusCode == 200) {
        callback(geojsonhint.hint(body), error, response);
      } else {
        callback(body, error, response);
      }
    });
  },

  pathTester: function(geojsonhintResult, error, response) {
    console.log(geojsonhintResult)
    return false;
  },

  findEndpoints: function () {
    var endpointsPath = path.join(__dirname, 'lib/spy_glass/registry');
    return fs.readdirSync(endpointsPath).map(function(elt){
      return elt.substr(0, elt.length-3)
    });
  }
}

if ( typeof module !== "undefined" ) {
  module.exports = geojsonLint;
}