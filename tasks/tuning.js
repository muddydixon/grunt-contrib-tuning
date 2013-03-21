'use strict';
var EventEmitter, TuningWatcher, createParamSet, d3, parseParam, showParams,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

d3 = require('d3');

EventEmitter = require('events').EventEmitter;

module.exports = function(grunt) {
  return grunt.registerMultiTask('tuning', 'tuning system', function() {
    var async, beginTuning, command, done, env, limit, name, options, params, strategy, target, trace, watcher, _results;

    beginTuning = new Date();
    name = this.name;
    async = this.async();
    options = this.options(this.data);
    if (options.command == null) {
      throw new Error('command required.');
    }
    command = options.command;
    done = options.done || function(err, results) {
      var bestCase, bestCost, result, _i, _len;

      bestCase = null;
      bestCost = Infinity;
      for (_i = 0, _len = results.length; _i < _len; _i++) {
        result = results[_i];
        if (result.cost < bestCost) {
          bestCost = result.cost;
          bestCase = result;
        }
      }
      grunt.log.writeln("tuning: " + results.length + " cases, time: " + ((new Date() - beginTuning) / 1000) + " sec");
      grunt.log.writeln("\tbest score: " + bestCase.cost);
      return grunt.log.writeln("\ton: " + (JSON.stringify(bestCase.params)));
    };
    limit = options.limit || 10;
    target = options.target || 1;
    env = options.env() || function() {};
    trace = options.trace || false;
    params = {};
    strategy = null;
    watcher = new TuningWatcher(limit, target, function(err, results) {
      done(err, results, {
        begin: beginTuning,
        end: new Date()
      });
      return async();
    });
    _results = [];
    while (limit-- > 0) {
      params = createParamSet(options.params, strategy);
      _results.push((function(params) {
        return command(env(), params, function(err, cost) {
          if (trace) {
            grunt.log.writeln("" + name + ": " + cost + " on " + (showParams(params)));
          }
          return watcher.emit('data', params, cost);
        });
      })(params));
    }
    return _results;
  });
};

parseParam = function(setting) {
  var gen;

  gen = null;
  if (setting.range == null) {
    gen = function() {
      return setting;
    };
  }
  if (setting.range) {
    gen = d3.scale.linear().range(setting.range);
  }
  return function(strategy) {
    return gen(Math.random());
  };
};

createParamSet = function(params, strategy) {
  var key, param, val;

  param = {};
  for (key in params) {
    val = params[key];
    param[key] = parseParam(val)(strategy);
  }
  return param;
};

showParams = function(params) {
  var key, val;

  return ((function() {
    var _results;

    _results = [];
    for (key in params) {
      val = params[key];
      _results.push("" + key + ": " + val);
    }
    return _results;
  })()).join(', ');
};

TuningWatcher = (function(_super) {
  __extends(TuningWatcher, _super);

  function TuningWatcher(limit, target, callback) {
    var _this = this;

    this.limit = limit;
    this.target = target;
    this.callback = callback;
    this.data = [];
    this.cnt = 0;
    this.on('data', function(params, cost) {
      _this.data.push({
        params: params,
        cost: cost
      });
      _this.cnt++;
      if (_this.cnt === _this.limit || cost < _this.target) {
        return _this.emit('end', null, _this.data);
      }
    });
    this.on('error', function(err) {
      return _this.emit('end', err);
    });
    this.on('end', function(err, data) {
      _this.removeAllListeners();
      return typeof callback === "function" ? callback(err, data) : void 0;
    });
  }

  return TuningWatcher;

})(EventEmitter);
