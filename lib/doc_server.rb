# Haplo Platform                                     http://haplo.org
# (c) Haplo Services Ltd 2006 - 2016    http://www.haplo-services.com
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


require 'webrick'

class DocServer

  PORT = 8899

  def self.run
    server = WEBrick::HTTPServer.new(:Port => PORT, :AccessLog => [])
    server.mount('/', DocHandler, 'doc/web/static')
    server.mount('/presentation/font', DocHandler, 'static/images')
    puts "Running documentation server at http://#{`hostname`.chomp}.local:#{PORT} ..."
    server.start
  end

  class DocHandler < WEBrick::HTTPServlet::FileHandler
    def initialize(server, root, options={})
      super(server, root, options)
    end
    def do_GET(request, response)
      path_name = request.meta_vars['PATH_INFO']
      # Reload template
      Documentation.load_html_template
      # Get the node
      node = Documentation.get_node(path_name)
      if node != nil
        puts path_name
        # Attempt a reload of the source file?
        Documentation.read_file_auto(node.filename, DOCS_ROOT) if node.filename != nil
        node = Documentation.get_node(path_name) # get reloaded node
        # Turn it into HTML
        response.body = Documentation.make_html_for_node(node)
        response.header["Content-Type"] = 'text/html; charset=utf-8'
        response.status = 200
      else
        super(request, response)
      end
    end
  end

end
