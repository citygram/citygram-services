/*! geojsonLint v0.0.0 - MIT license */
'use strict';

var geojsonhint = require('geojsonhint');
var path = require('path');
var fs = require('fs');
var request = require('request');

var geojsonLint = {
  all: function (path) {
    return geojsonhint(path);
  },

  testPath: function (path) {
    var results = request('http://localhost:5000/'+path, function (error, response, body) {
      if (!error && response.statusCode == 200) {
        debugger;
        return geojsonhint(body);
      } else {
        return false
      }
    });
    return results;
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