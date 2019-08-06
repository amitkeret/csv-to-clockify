window.clicker = (id, func)-> document.getElementById(id).addEventListener 'click', func

window.rest = everest.createRestClient
    host:       'api.clockify.me/api/v1'
    useSSL:     yes
    dataFormat: 'json'
  .withHeader 'Content-Type', 'application/json'

$('#tz-timezone').append "<option value='#{zone}'>#{zone}</option>" for zone in do moment.tz.names
do $('#tz-timezone').selectpicker

clicker 'get-workspaces', (
    e
    apiKey = do $('#api-key').val
    rest = window.rest
  )->
  if apiKey is '' then toastr['error'] 'Missing API Key.'
  else
    (icon = do $(this).next).removeClass 'd-none'
    rest.withHeader 'X-Api-Key', apiKey
    rest.read('/workspaces').done (workspaces)->
      $('#workspaces-list').append "
        <div class='form-check'>
          <input class='form-check-input' type='radio' name='workspaces' value='#{workspace.id}'>
          <label class='form-check-label'>#{workspace.name}</label>
        </div>
      " for workspace in workspaces
      icon.addClass 'd-none'

window.clicker 'get-projects', (
    e
    workspace = do $('input[name=workspaces]:checked').val
    rest = window.rest
  )->
  if not workspace then toastr['error'] 'Please choose workspace.'
  else
    (icon = do $(this).next).removeClass 'd-none'
    rest.read("/workspaces/#{workspace}/projects").done (projects)->
      $('#projects-list').append "
        <div class='form-check'>
          <input class='form-check-input' type='radio' name='projects' value='#{project.id}'>
          <label class='form-check-label'>#{project.name}</label>
        </div>
      " for project in projects
      icon.addClass 'd-none'

handleFileSelect = (
    evt
    format = do $('#tz-format').val
    timezone = do $('#tz-timezone').val
    #data = window.entriesData    # this doesn't work; not reference correctly inside Papaparse callback
  )->
  if      format   is '' then toastr['error'] 'Timestamp format required.'
  else if timezone is '' then toastr['error'] 'Timestamp timezone required.'
  else
    Papa.parse evt.target.files[0],
      complete: (results)->
        data = window.entriesData = results.data
        moment.tz.setDefault timezone
        data.map (e)->
          e[0] = moment(e[0], format).utc().format()
          e[1] = moment(e[1], format).utc().format()
          e[3] = '<i class="material-icons">schedule</i>' # cached
        $('table').bootstrapTable data: data
        $('#send-entries').prop 'disabled', no
document.getElementById('csv-file').addEventListener 'change', handleFileSelect, no

window.clicker 'send-entries', (
    e
    workspace = do $('input[name=workspaces]:checked').val
    project = do $('input[name=projects]:checked').val
    data = window.entriesData
    rest = window.rest
  )->
  if      not data      then toastr['error'] 'Missing entries.'
  else if not workspace then toastr['error'] 'Please choose workspace.'
  else if not project   then toastr['error'] 'Please choose project.'
  else
    for entry in data
      postData =
        projectId:    project
        billable:     yes
        start:        entry[0]
        end:          entry[1]
        description:  entry[2]
      rest.create "/workspaces/#{workspace}/time-entries", postData
        .done ((i)->
            -> $('table tbody tr').eq(i).find('td:last-child i.material-icons').text 'done'
          )(i)

###
DELETE STUFF
rest.read("/workspaces/#{workspace}/user/#{user}/time-entries",
    project: project
    'page-size': 100
	.done (entries)->
		console.log res
    window.rest.remove "/workspaces/#{workspace}/time-entries/#{entry.id}" for entry in entries
###