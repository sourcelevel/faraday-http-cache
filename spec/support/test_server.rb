require 'net/http'

class TestServer
  attr_reader :endpoint

  def initialize
    @host = 'localhost'
    @port = find_port
    @endpoint = "http://#{@host}:#{@port}"
  end

  def start
    @pid = run!
    wait
  end

  def stop
    `kill -9 #{@pid}`
  end

  private

  def run!
    fork do
      require 'webrick'
      log = File.open('log/test.log', 'w+')
      log.sync = true
      webrick_opts = {
       :Port => @port,
       :Logger => WEBrick::Log::new(log),
       :AccessLog => [[log, "[%{X-Faraday-Adapter}i] %m  %U  ->  %s %b"]]
      }
      Rack::Handler::WEBrick.run(TestApp, webrick_opts)
    end
  end

  def wait
    conn = Net::HTTP.new @host, @port
    conn.open_timeout = conn.read_timeout = 0.1

    responsive = lambda { |path|
      begin
        res = conn.start { conn.get(path) }
        res.is_a?(Net::HTTPSuccess)
      rescue Errno::ECONNREFUSED, Errno::EBADF, Timeout::Error, Net::HTTPBadResponse
        false
      end
    }

    server_pings = 0
    begin
      server_pings += 1
      sleep 0.05
      abort "test server didn't manage to start" if server_pings >= 50
    end until responsive.call('/ping')
  end

  def find_port
    server = TCPServer.new(@host, 0)
    server.addr[1]
  ensure
    server.close if server
  end
end