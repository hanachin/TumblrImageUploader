# for drop event
jQuery.event.props.push('dataTransfer');

class BlogSelectorView extends Backbone.View
  el: 'header'
  events:
    'click li': 'toggleExpand'
    'mouseleave': 'close'

  initialize: ->
    @$blogs = @$('li')
    @$blogs.not('.primary').hide()

  toggleExpand: (ev) ->
    @$('.primary').removeClass('primary')
    $(ev.currentTarget).addClass('primary')
    if @$el.hasClass('expand')
      @close()
    else
      @$el.addClass('expand')
      @$blogs.not('.primary').slideDown(100)

  close: ->
    @$el.removeClass('expand')
    @$blogs.not('.primary').slideUp(100)

class ImageModel extends Backbone.Model
  readAsDataURL: ->
    fr = new FileReader
    fr.onload = (ev) =>
      result = ev.target.result
      @trigger('data_url', result)
    fr.readAsDataURL(@get('file'))

  upload: (hostname) ->
    data = new FormData
    data.append('data[]', @.get('file'))
    $.ajax
      url: "/photos/#{@.get('hostname')}"
      type: 'post'
      data: data
      processData: false
      contentType: false
      dataType: 'json'
    .done (data) =>
      if data.success
        @trigger('upload_done', data)
      else
        @trigger('upload_fail', data)
    .fail (data) =>
      @trigger('upload_fail', data)

class ImageView extends Backbone.View
  tagName: 'div'
  className: 'image'
  initialize: ->
    @render()
    @$el.css('opacity', 0)

    @model.on 'data_url', (result) =>
      @$('img')
      .attr(src: result)
      .one 'load', =>
        img_height = @$('img').height()
        font_size =`img_height > 200 ? 200 : img_height`

        @$el.height(img_height + 10)
        @$('.status').css(height: img_height + 10, 'font-size': font_size)
        @$el.hide().css('opacity': 1).fadeIn()
        $('#images').append(@$el).masonry('reload')

    @model.readAsDataURL()

    @model.on 'upload_done', (data) =>
      @$('.status')
      .removeClass()
      .addClass('status done')

      @$('.icon')
      .removeClass()
      .addClass('icon icon-ok')

    @model.on 'upload_fail', (data) =>
      @$('.status')
      .removeClass()
      .addClass('status fail')

      @$('.icon')
      .removeClass()
      .addClass('icon icon-repeat')

      @$el.one 'click', =>
        @$('.status')
        .removeClass()
        .addClass('status')

        @$('.icon')
        .removeClass()
        .addClass('icon icon-refresh')
        @model.upload()

      @$('status').text(' retry')

    @model.upload()

  reupload: ->
    @$

  render: ->
    $('<img/>').attr(src: 'dummy.png').appendTo(@$el)
    $('<span/>').attr(class:'status').appendTo(@$el)
    $('<i/>').attr(class: 'icon icon-refresh').appendTo(@$('span'))
    @

class ImageUploaderView extends Backbone.View
  el: 'body'
  events:
    'drop': 'upload'

  initialize: ->
    $('#images').masonry(itemSelector: '.image')
    $('body, #content')
    .mousedown ->
      $(this).removeAttr('draggable')
    .mouseup ->
      $(this).attr('draggable': true)

  hideDescription: -> @$('.description').fadeOut()

  upload: (ev) ->
    ev.stopPropagation()
    ev.preventDefault()

    @hideDescription()

    files = ev.dataTransfer.files
    for file in files
      model = new ImageModel(file: file, hostname: @$('.primary').data('hostname'))
      iv = new ImageView(model: model)
      @$el.append(iv.$el)
    false

$ ->
  blog_selector  = new BlogSelectorView
  image_uploader = new ImageUploaderView
