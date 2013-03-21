'use strict'

d3 = require 'd3'
EventEmitter = require('events').EventEmitter

module.exports = (grunt)->
  grunt.registerMultiTask 'tuning', 'tuning system', ()->
    beginTuning = new Date()
    name = @name
    async = @async()
    options = @options @data
    if not options.command?
      throw new Error 'command required.'

    command = options.command
    done = options.done or (err, results)->
      bestCase = null
      bestCost = Infinity
      for result in results
        if result.cost < bestCost
          bestCost = result.cost
          bestCase = result
      grunt.log.writeln "tuning: #{results.length} cases, time: #{(new Date() - beginTuning) / 1000} sec"
      grunt.log.writeln "\tbest score: #{bestCase.cost}"
      grunt.log.writeln "\ton: #{JSON.stringify(bestCase.params)}"
      
    limit = options.limit or 10
    target = options.target or 1
    env = options.env() or ()->
    trace = options.trace or false

    params = {}
    strategy = null

    watcher = new TuningWatcher(limit, target, (err, results)->
      done(err, results)
      async()
    )

    # job insert        
    while limit-- > 0
      params = createParamSet(options.params, strategy)
      do (params)->
        command(env(), params, (err, cost)->
          if trace
            grunt.log.writeln "#{name}: #{cost} on #{showParams(params)}"
          watcher.emit 'data', params, cost
        )
      
############################################################
#
# range
parseParam = (setting)->
  gen = null

  if not setting.range?
    gen = ()-> return setting

  if setting.range
    gen = d3.scale.linear().range(setting.range)
  
  (strategy)->
    gen(Math.random())
  
createParamSet = (params, strategy)->
  param = {}
  for key, val of params
    param[key] = parseParam(val)(strategy)
  param

showParams = (params)->
  ("#{key}: #{val}" for key, val of params).join ', '


############################################################
#
# TuningWatcher
 
class TuningWatcher extends EventEmitter
  constructor: (@limit, @target, @callback)->
    @data = []
    @cnt = 0
    @on 'data', (params, cost)=>
      @data.push 
        params: params
        cost: cost
        
      @cnt++

      if @cnt is @limit or cost < @target
        @emit 'end', null, @data
        
    @on 'error', (err)=>
      @emit 'end', err
      
    @on 'end', (err, data)=>
      @removeAllListeners()
      callback?(err, data)

unless module.parent?
  watcher = new TuningWatcher(5, 0.1, (err, data)->
    console.log data
  )
    
  # watcher.emit('error', 'Psuedo error');
  watcher.emit('data', Math.random(), 1)
  watcher.emit('data', Math.random(), 1)
  watcher.emit('data', Math.random(), 0.01)
  watcher.emit('data', Math.random(), 1)
  watcher.emit('data', Math.random(), 1)
  