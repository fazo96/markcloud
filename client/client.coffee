docs = new Meteor.Collection 'docs'
Meteor.subscribe 'user'
UI.registerHelper 'mail', -> Meteor.user().emails[0].address

Router.configure
  layoutTemplate: 'layout'
  loadingTemplate: 'loading'

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
    layoutTemplate: 'docLayout'
    waitOn: -> @docHandle = Meteor.subscribe 'doc', @params._id
    data: -> docs.findOne @params._id
    action: ->
      if @ready() then @render()
      else @render 'loading'
  @route 'verify',
    path: '/verify/:token'
    template: 'loading'
    onBeforeAction: ->
      Accounts.verifyEmail @params.token, (err) ->
        if err then errCallback err else Router.go 'home'
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
  if err.reason then notify msg: err.reason else notify msg: err
Template.notifications.notification = -> notification.get()
Template.notifications.events
  'click .close': -> notify()

Template.layout.showSpinner = ->
  Meteor.status().connected is no or Router.current().ready() is no
Template.home.ndocs = -> docs.find().count()
Template.new.events
  'click #new-btn': (e,t) ->
    id = docs.insert
      title: t.find('#title').value
      text: t.find('#editor').value
      dateCreated: moment().unix()
    if id
      Router.go 'doc', _id: id
    else notify msg: 'document creation failed'

Template.signup.events
  'click #signup': (e,t) ->
    if not t.find('#mail').value
      return notify msg: 'please enter an email'
    else if not t.find('#pw').value
      return notify msg: "Please enter a password"
    else if t.find('#pw').value isnt t.find('#rpw').value
      return notify msg: "The passwords don't match"
    else # Sending actual registration request
      console.log t.find('#mail').value
      Accounts.createUser {
        email: t.find('#mail').value
        password: t.find('#pw').value
      }, (err) -> if err then errCallback err
      else notify type: 'success', msg: 'check your email'
