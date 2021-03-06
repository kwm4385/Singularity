Handlebars = require 'handlebars'
moment = require 'moment'
Utils = require './utils'

Handlebars.registerHelper 'appRoot', ->
    config.appRoot

Handlebars.registerHelper 'apiDocs', ->
    config.apiDocs

Handlebars.registerHelper 'ifEqual', (v1, v2, options) ->
    if v1 is v2 then options.fn @ else options.inverse @

Handlebars.registerHelper 'ifNotEqual', (v1, v2, options) ->
    if v1 isnt v2 then options.fn @ else options.inverse @

Handlebars.registerHelper 'ifLT', (v1, v2, options) ->
    if v1 < v2 then options.fn @ else options.inverse @

Handlebars.registerHelper 'ifGT', (v1, v2, options) ->
    if v1 > v2 then options.fn @ else options.inverse @

Handlebars.registerHelper "ifAll", (conditions..., options)->
    for condition in conditions
        return options.inverse @ unless condition?
    options.fn @

Handlebars.registerHelper 'percentageOf', (v1, v2) ->
    (v1/v2) * 100

# Override decimal rounding: {{fixedDecimal data.cpuUsage place="4"}}
Handlebars.registerHelper 'fixedDecimal', (value, options) ->
    if options.hash.place then place = options.hash.place else place = 2
    +(value).toFixed(place)

Handlebars.registerHelper 'ifTaskInList', (list, task, options) ->
    for t in list
      if t.id == task
        return options.fn @
    return options.inverse @

Handlebars.registerHelper 'ifInSubFilter', (needle, haystack, options) ->
    return options.fn @ if haystack is 'all'
    if haystack.indexOf(needle) isnt -1
        options.fn @
    else
        options.inverse @

Handlebars.registerHelper 'unlessInSubFilter', (needle, haystack, options) ->
    return options.inverse @ if haystack is 'all'
    if haystack.indexOf(needle) is -1
        options.fn @
    else
        options.inverse @


# {{#withLast [1, 2, 3]}}
#     {{! this = 3 }}
# {{/withLast}}
Handlebars.registerHelper 'withLast', (list, options) ->
    options.fn _.last list

# {{#withFirst [1, 2, 3]}}
#     {{! this = 1 }}
# {{/withFirst}}
Handlebars.registerHelper 'withFirst', (list, options) ->
    options.fn list[0]

# 1234567890 => 20 minutes ago
Handlebars.registerHelper 'timestampFromNow', (timestamp) ->
    return '' if not timestamp
    timeObject = moment timestamp
    "#{timeObject.fromNow()} (#{ timeObject.format window.config.timestampFormat})"

Handlebars.registerHelper 'ifTimestampInPast', (timestamp, options) ->
    return options.inverse @ if not timestamp
    timeObject = moment timestamp
    now = moment()
    if timeObject.isBefore(now)
        options.fn @
    else
        options.inverse @

Handlebars.registerHelper 'ifTimestampSecondsInPast', (timestamp, seconds, options) ->
    return options.inverse @ if not timestamp
    timeObject = moment timestamp
    past = moment().subtract(seconds, "seconds")
    if timeObject.isBefore(past)
        options.fn @
    else
        options.inverse @

Handlebars.registerHelper 'ifTimestampSecondsInFuture', (timestamp, seconds, options) ->
    return options.inverse @ if not timestamp
    timeObject = moment timestamp
    future = moment().add(seconds, "seconds")
    if timeObject.isAfter(future)
        options.fn @
    else
        options.inverse @

# 12345 => 12 seconds
Handlebars.registerHelper 'timestampDuration', (timestamp) ->
    return '' if not timestamp
    moment.duration(timestamp).humanize()


# 1234567890 => 1 Aug 1991 15:00
Handlebars.registerHelper 'timestampFormatted', (timestamp) ->
    return '' if not timestamp
    timeObject = moment timestamp
    timeObject.format window.config.timestampFormat

Handlebars.registerHelper 'timestampFormattedWithSeconds', (timestamp) ->
    return '' if not timestamp
    timeObject = moment timestamp
    timeObject.format window.config.timestampWithSecondsFormat

# 'DRIVER_NOT_RUNNING' => 'Driver not running'
Handlebars.registerHelper 'humanizeText', (text) ->
    return Utils.humanizeText text

# 2121 => '2 KB'
Handlebars.registerHelper 'humanizeFileSize', (bytes) ->
    return Utils.humanizeFileSize bytes

Handlebars.registerHelper 'ifCauseOfFailure', (task, deploy, options) ->
    thisTaskFailedTheDeploy = false
    deploy.deployResult.deployFailures.map (failure) ->
        if failure.taskId and failure.taskId.id is task.taskId
            thisTaskFailedTheDeploy = true
    if thisTaskFailedTheDeploy
        options.fn @
    else
        options.inverse @

Handlebars.registerHelper 'ifDeployFailureCausedTaskToBeKilled', (task, options) ->
    deployFailed = false
    taskKilled = false
    task.taskUpdates.map (update) ->
        if update.statusMessage and update.statusMessage.indexOf 'DEPLOY_FAILED' isnt -1
            deployFailed = true
        if update.taskState is 'TASK_KILLED'
            taskKilled = true
    if deployFailed and taskKilled
        options.fn @
    else
        options.inverse @

Handlebars.registerHelper 'causeOfDeployFailure', (task, deploy) ->
    failureCause = ''
    deploy.deployResult.deployFailures.map (failure) ->
        if failure.taskId and failure.taskId.id is task.taskId
            failureCause = Handlebars.helpers.humanizeText failure.reason
    return failureCause if failureCause

# 'sbacanu@hubspot.com' => 'sbacanu'
# 'seb'                 => 'seb'
Handlebars.registerHelper 'usernameFromEmail', (email) ->
    return '' if not email
    email.split('@')[0]

Handlebars.registerHelper 'substituteTaskId', (value, taskId) ->
    Utils.substituteTaskId value, taskId

Handlebars.registerHelper 'filename', (value) ->
    Utils.fileName(value)

Handlebars.registerHelper 'getLabelClass', (state) ->
    Utils.getLabelClassFromTaskState state

Handlebars.registerHelper 'trimS3File', (filename, taskId) ->
    unless config.taskS3LogOmitPrefix
        return filename

    finalRegex = config.taskS3LogOmitPrefix.replace('%taskId', taskId.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')).replace('%index', '[0-9]+').replace('%s', '[0-9]+')

    return filename.replace(new RegExp(finalRegex), '')

Handlebars.registerHelper 'isRunningState', (list, options) ->
    switch _.last(list).taskState
        when 'TASK_RUNNING'
            options.fn(@)
        else
            options.inverse(@)

Handlebars.registerHelper 'isSingularityExecutor', (value, options) ->
    if value and value.indexOf 'singularity-executor' != -1
        options.fn(@)
    else
        options.inverse(@)

Handlebars.registerHelper 'lastShellRequestStatus', (statuses) ->
    if statuses.length > 0
      statuses[0].updateType

Handlebars.registerHelper 'shellRequestOutputFilename', (statuses) ->
    for status in statuses
      if status.outputFilename
        return status.outputFilename

Handlebars.registerHelper 'ifShellRequestHasOutputFilename', (statuses, options) ->
    for status in statuses
      if status.outputFilename
        return options.fn @
    return options.inverse @

Handlebars.registerHelper 'reverseEach', (context, options) ->
  ret = ''
  if context and context.length > 0
    i = context.length - 1
    while i >= 0
      ret += options.fn(context[i])
      i--
  else
    ret = options.inverse(this)
  ret

Handlebars.registerHelper 'ifCurrentState', (state, updates, options) ->
    lastState = _.last updates
    if lastState.taskState is state then options.fn @ else options.inverse @

