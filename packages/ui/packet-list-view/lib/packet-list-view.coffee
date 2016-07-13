$ = require('jquery')
_ = require('underscore')
riot = require('riot')
fs = require('fs')
Component = require('dripcap/component')
remote = require('electron').remote
Menu = remote.Menu
MenuItem = remote.MenuItem
dialog = remote.dialog

class PacketListView
  activate: ->
    new Promise (res) =>
      @comp = new Component "#{__dirname}/../tag/*.tag"
      dripcap.package.load('main-view').then (pkg) =>
        $ =>
          m = $('<div class="wrapper noscroll" />')
          pkg.root.panel.left('packet-list-view', m)

          n = $('<div class="wrapper" />').attr('tabIndex', '0').appendTo m
          @list = riot.mount(n[0], 'packet-list-view', items: [])[0]

          @packets = 0
          @prevStart = -1
          @prevEnd = -1

          @view = $('[riot-tag=packet-list-view]')
          @view.scroll _.debounce((=> @update()), 200)

          dripcap.session.on 'created', (session) =>
            session.on 'packet', (pkt) => console.log(pkt)
            @session = session

          @main = $('[riot-tag=packet-list-view] div.main')
          for i in [0..50]
            @main.append($('<div class="packet">'))
          @cells = @main.children('div.packet')
          @cells.hide()

          dripcap.pubsub.sub 'core:captured-packets', (n) =>
            @packets = n
            @update()

  update: () ->
    @main.css('height', (32 * @packets) + 'px')
    start = Math.max(1, Math.floor(@view.scrollTop() / 32 - 5))
    end = Math.min(@packets, Math.floor((@view.scrollTop() + @view.height()) / 32 + 5))

    @main.children('div.packet:visible').each (i, ele) =>
      pos = parseInt($(ele).css('top'))
      margin = 120
      if pos + $(ele).height() + margin < @view.scrollTop() || pos - margin > @view.scrollTop() + @view.height()
        $(ele).hide()

    if @prevStart != start || @prevEnd != end
      @prevStart = start
      @prevEnd = end
      if @session? && start <= end
        packets = []
        for i in [start..end]
          unless @cells.is("[data-packet=#{i}]:visible")
            packets.push(i)

        @session.requestPackets(packets)
        @main.children('div.packet:not(:visible)').each (i, ele) =>
          return if (packets.length == 0)
          id = packets.shift()
          $(ele).attr('data-packet', id).text('#' + id).css('top', (32 * (id - 1)) + 'px').show()


  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    dripcap.package.load('main-view').then (pkg) =>
      pkg.root.panel.left('packet-list-view')
      @list.unmount()
      @comp.destroy()

module.exports = PacketListView
