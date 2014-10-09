docs = new Meteor.Collection 'docs'

amIValid = ->
  return no unless Meteor.user()
  return yes if !Meteor.user().emails?
  return yes for mail in Meteor.user().emails when mail.verified is yes; no

UI.registerHelper 'mail', ->
  if Meteor.user().emails then Meteor.user().emails[0].address
UI.registerHelper 'amIValid', amIValid

Router.configure
  layoutTemplate: 'layout'
  loadingTemplate: 'loading'

docController = RouteController.extend
  template: 'doc'
  layoutTemplate: 'docLayout'
  waitOn: -> Meteor.subscribe 'doc', @params._id
  data: -> docs.findOne @params._id
  action: ->
    if @ready()
      if @data()? then @render()
      else @render '404'
    else @render 'loading'

loggedOutController = RouteController.extend
  onBeforeAction: ->
    if Meteor.user() then Router.go 'profile', user: Meteor.user().username
  action: ->
    @render()
    if Meteor.loggingIn() then @render 'spinner', to: 'outside'
loggedInController = RouteController.extend
  action: -> if !Meteor.user() then @render '404' else @render()

Router.map ->
  @route 'home',
    path: '/'
    action: ->
      if !@ready() then @render 'spinner', to: 'outside'
      @render()
  @route 'doc',
    path: '/d/:_id'
    controller: docController
  @route 'userDoc',
    path: '/@:user/:_id'
    controller: docController
  @route 'src',
    path:'/src/:_id'
    controller: docController
  @route 'verify',
    path: '/verify/:token?'
    template: 'loading'
    onBeforeAction: ->
      Accounts.verifyEmail @params.token, (err) ->
        if err then errCallback err
        else Router.go 'profile', user: Meteor.user().username
  @route 'edit',
    path: '/edit/:_id'
    template: 'editor'
    controller: loggedInController
    waitOn: -> Meteor.subscribe 'doc', @params._id
    data: -> docs.findOne @params._id
    action: ->
      if !Meteor.user() then @render '404'
      else if @ready() then @render()
  @route 'profile',
    path: '/@:user'
    waitOn: ->
      [Meteor.subscribe('docs', @params.user),
      Meteor.subscribe('user', @params.user)]
    data: -> Meteor.users.findOne username: @params.user
    action: ->
      if Meteor.loggingIn() then @render 'loading'
      else if @ready()
        if !@data() then @render '404' else @render()
      else @render 'loading'
  @route 'new', template: 'editor'
  @route 'signup', controller: loggedOutController
  @route 'signin',
    path: 'login'
    controller: loggedOutController
  @route '404', path: '*'

share.notify = notify = (opt) ->
  if opt.type? then type = opt.type
  else type = 'error'
  if opt.title? then title = opt.title
  else title = if type is 'error' then 'Error' else 'Ok'
  swal title, opt.msg, type

errCallback = (err) ->
  return unless err
  if err.reason
    notify title: err.code or 'Error', msg: err.reason, type: 'error'
  else notify title: 'Error', msg: err, type: 'error'

Template.magicIcon.notHome = -> Router.current().route.name isnt 'home'
Template.layout.showSpinner = -> Meteor.status().connected is yes
Template.home.events
  'click #twitter-login': ->
    if Meteor.user() then return notify msg: "You're already Logged In!"
    Meteor.loginWithTwitter {}, (e) ->
      if e then errCallback e
      else
        Meteor.subscribe 'user'
        notify type: 'success', msg: 'Logged in'

Template.editor.rendered = ->
  ed = MandrillAce.getInstance(); ed.isFocused()
  #ed.setTheme 'ace/theme/monokai'
  ed.setMode 'ace/mode/markdown'
  if Router.current().data().text
    ed.ace.setValue Router.current().data().text
Template.editor.isPublic = -> return "checked" if @public is yes
Template.editor.showTitleChecked = -> return "checked" unless @showTitle is no
Template.editor.events
  'click #upload': (e,t) ->
    if Meteor.loggingIn()
      return notify
        msg: "Can't upload while Logging In.\nTry again in a few seconds."
    if t.find('#title').value is ''
      return notify msg: 'Please insert a title.'
    if t.find('#editor').value is ''
      return notify msg: "Empty documents are not valid."
    if @_id then docs.update @_id, $set: {
      title: t.find('#title').value
      text: t.find('#editor').value
      showTitle: $('#show-title').is(':checked')
      public: $('#make-public').is(':checked')
    }, (err) =>
      if err then errCallback err
      else
        notify type:'success', msg:'Document updated.'
        Router.go 'doc', _id: @_id
    else docs.insert {
      title: t.find('#title').value
      text: t.find('#editor').value
      showTitle: $('#show-title').is(':checked')
      public: $('#make-public').is(':checked')
    }, (err,id) ->
      if err then errCallback err
      else notify type:'success', msg:'Document created successfully!'
      if id then Router.go 'doc', _id: id

Template.profile.isMe = ->
  Meteor.user() and Meteor.user()._id is @_id
Template.profile.noDocs = -> docs.find(owner: @_id).count() is 0
Template.profile.documents = ->
  docs.find {owner: @_id}, sort: dateCreated: -1
Template.profile.events
  'click #resend': ->
    Meteor.call 'sendVerificationEmail', (e,r) ->
      if e then errCallback e
      else notify msg: r, type:'success'
  'click #logout': -> Meteor.logout(); Router.go 'home'
  'click #deleteme': -> swal {
    title: 'Are you sure?'
    text: 'Do you want to permanently delete all your data?'
    type: 'warning'
    showCancelButton: yes
    confirmButtonColor: "#DD6B55"
    confirmButtonText: "Yes!"
    }, -> Meteor.call 'deleteMe', (e,r) ->
    if e then errCallback e
    else notify type: 'success', msg: 'Account deleted'

Template.doc.valid = -> @text?
Template.doc.source = -> Router.current().route.name is 'src'
Template.doc.rows = -> ""+@text.split('\n').length
Template.doc.owned = -> Meteor.user() and Meteor.user()._id is @owner
Template.doc.privateUrl = ->
Template.doc.ownerName = ->
  if Router.current().route.name is 'userDoc'
    return Router.current().params.user
Template.doc.expirationDays = ->
  if @owner then return 'never'
  else return moment.unix(@dateCreated).add(7,'days').fromNow()
Template.doc.events
  'click #edit-doc': -> Router.go 'edit', _id: @_id
  'click #del-doc': ->
    if Meteor.user()._id is @owner
      swal {
        title: 'Are you sure?'
        text: 'This document will be deleted permanently'
        type: 'warning'
        showCancelButton: yes
        confirmButtonColor: "#DD6B55"
        confirmButtonText: "Yes!"
      }, => docs.remove @_id, (err) ->
        if err then errCallback err
        else notify type:'success', msg:'Document removed'
  'click #src-doc': ->
    if Router.current().route.name is 'src'
      Router.go 'doc', _id: @_id
    else Router.go 'src', _id: @_id

Template.signin.events
  'click #signin': (e,t) ->
    if not t.find('#mail').value
      return notify msg: 'please enter your email or username'
    else if not t.find('#pw').value
      return notify msg: "Please enter a password"
    else
      Meteor.loginWithPassword t.find('#mail').value, t.find('#pw').value,(e)->
        if e then errCallback e
        else notify type:'success', msg:'Welcome back!'; Router.go 'home'

Template.signup.events
  'click #signup': (e,t) ->
    if not t.find('#mail').value
      return notify msg: 'please enter your email'
    if not t.find('#name').value
      return notify msg: 'please enter your user name'
    else if not t.find('#pw').value
      return notify msg: "Please enter a password"
    else if t.find('#pw').value isnt t.find('#rpw').value
      return notify msg: "The passwords don't match"
    else # Sending actual registration request
      Accounts.createUser {
        username: t.find('#name').value
        email: t.find('#mail').value
        password: t.find('#pw').value
      }, (err) -> if err then errCallback err
      else notify type: 'success', msg: 'check your email'
