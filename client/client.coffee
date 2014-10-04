docs = new Meteor.Collection 'docs'

Router.configure
  layoutTemplate: 'layout'

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
      if @ready()
        @render()
      else @render 'loading'
  @route 'new'

Template.layout.showSpinner = ->
  Meteor.status().connected is no or Router.current().ready() is no
Template.home.ndocs = -> docs.find().count()
Template.new.events
  'click #new-btn': (e,t) ->
    id = docs.insert
      text: t.find('#editor').value
    if id?
      Router.go 'doc', _id: id
