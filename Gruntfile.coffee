module.exports = (grunt) ->
  
  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    coffee:
      compile:
        options:
          bare: true
        files:
          'tasks/tuning.js': 'src/tasks/tuning.coffee'
    tuning:
      # required: tuning case name
      test: 
        # required: tuning parameter list
        params: 
          alpha:
            range: [0, 1]
          beta:
            range: [5, 10]
          gamma:
            range: [10, 100]
        # optional: if define this method, it passed to `command`
        env: ()->
          port = 10000
          ()->
            {port: port++}
        # optional (default 10): limit case number            
        limit: 10
        # show each trial result
        trace: true
        # optional (default 1):
        #   target cost value
        #   when cost of each trial is lesser than this value,
        #     `done` method is called
        target: 0.3
        # requreid: trial command
        command: (env, params, next)->
          setTimeout(()->
              next(null, Math.random())
            (Math.random() * 2 + 1) * 1000
          )
        # optional: when tuning ends, this method be called 
        done: (err, results, time)-> 
          console.log results.map((d)-> d.cost), time
          
  grunt.loadTasks('tasks')
  grunt.loadNpmTasks 'grunt-contrib'
  grunt.registerTask 'default', ['coffee', 'tuning']
