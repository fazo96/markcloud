docs = new Meteor.Collection 'docs'
Meteor.subscribe 'user'
UI.registerHelper 'mail', -> Meteor.user().emails[0].address

Router.configure
  layoutTemplate: 'layout'
  loadingTemplate: 'loading'

docController = RouteController.extend
  template: 'doc'
  layoutTemplate: 'docLayout'
  waitOn: -> Meteor.subscribe 'doc', @params._id
  data: -> docs.findOne @params._id
  action: ->
    if @ready() then @render()
    else @render 'loading'

Router.map ->
  @route 'home',
    path: '/'
    waitOn: -> Meteor.subscribe 'docs'
    action: ->
      if !@ready()
        @render(); @render 'spinner', to: 'outside'
      else @render()
  @route 'doc',
    path: '/d/:_id'
    controller: docController
  @route 'src',
    path:'/src/:_id'
    controller: docController
  @route 'verify',
    path: '/verify/:token'
    template: 'loading'
    onBeforeAction: ->
      Accounts.verifyEmail @params.token, (err) ->
        if err then errCallback err else Router.go 'home'
  @route 'edit',
    path: '/edit/:_id'
    template: 'new'
    waitOn: -> Meteor.subscribe 'doc', @params._id
    data: -> docs.findOne @params._id
  @route 'list',
    path: '/list/:user?'
    waitOn: -> Meteor.subscribe 'docs', @params.user
    data: -> userId: @params.user
    onBeforeAction: ->
      if Meteor.user() and !@params.user
        Router.go 'list', user: Meteor.user()._id
    action: ->
      if !@params.user then @render '404'
      else @render()
  @route 'new'
  @route 'signup'
  @route 'signin', path: 'login'
  @route '404', path: '*'

notification = new ReactiveVar()
share.notify = notify = (opt) ->
  if !opt then notification.set undefined
  else
    opt.type ?= "danger"
    notification.set opt
errCallback = (err) ->
  return unless err
  if err.reason then notify msg: err.reason else notify msg: err
Template.notifications.notification = -> notification.get()
Template.notifications.events
  'click .close': -> notify()

Template.layout.showSpinner = ->
  Meteor.status().connected is no or Router.current().ready() is no
Template.home.ndocs = -> docs.find().count()
Template.new.showTitleChecked = -> return "checked" unless @showTitle is no
Template.new.events
  'click #upload': (e,t) ->
    if t.find('#title').value is ''
      return notify msg: 'please insert a title'
    if t.find('#editor').value is ''
      return notify msg: "empty documents are not valid"
    if @_id then docs.update @_id, $set: {
      title: t.find('#title').value
      text: t.find('#editor').value
      showTitle: $('#show-title').is(':checked')
    }, (err) =>
      if err then errCallback err
      else
        notify type:'success', msg:'Document updated'
        Router.go 'doc', _id: @_id
    else docs.insert {
      title: t.find('#title').value
      text: t.find('#editor').value
      showTitle: $('#show-title').is(':checked')
    }, (err,id) ->
      if err then errCallback err
      else notify type:'success', msg:'Document created successfully'
      if id then Router.go 'doc', _id: id

Template.list.documents = ->
  console.log docs.find(owner: @userId).fetch()
  docs.find {owner: @userId}, sort: dateCreated: -1

Template.doc.source = -> Router.current().route.name is 'src'
Template.doc.rows = -> ""+@text.split('\n').length
Template.doc.valid = -> @text?
Template.doc.owned = -> Meteor.user()._id is @owner
Template.doc.expirationDays = ->
  if @owner then return 'never'
  else return moment.unix(@dateCreated).add(7,'days').fromNow()
Template.doc.events
  'click #edit-doc': -> Router.go 'edit', _id: @_id
  'click #del-doc': ->
    if Meteor.user()._id is @owner
      docs.remove @_id, (err) ->
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
