require 'sinatra/base'

class TestApp < Sinatra::Base

  set :environment, :test
  set :server, 'webrick'
  disable :protection

  set :counter, 0
  set :requests, 0
  set :yesterday, 1.day.ago.httpdate

  get '/ping' do
    'PONG'
  end

  get '/clear' do
    settings.counter = 0
    settings.requests = 0
    status 204
  end

  get '/json' do
    json = MultiJson.encode(count: settings.requests += 1)
    [200, { 'Cache-Control' => 'max-age=400', 'Content-Type' => 'application/json' }, json]
  end

  post '/post' do
    [200, { 'Cache-Control' => 'max-age=400' }, "#{settings.requests += 1}"]
  end

  get '/broken' do
    [500, { 'Cache-Control' => 'max-age=400' }, "#{settings.requests += 1}"]
  end

  get '/get' do
    [200, { 'Cache-Control' => 'max-age=200' }, "#{settings.requests += 1}"]
  end

  get '/private' do
    [200, { 'Cache-Control' => 'private' }, "#{settings.requests += 1}"]
  end

  get '/dontstore' do
    [200, { 'Cache-Control' => 'no-store' }, "#{settings.requests += 1}"]
  end

  get '/expires' do
    [200, { 'Expires' => (Time.now + 10).httpdate }, "#{settings.requests += 1}"]
  end

  get '/yesterday' do
    [200, { 'Date' => settings.yesterday, 'Expires' => settings.yesterday }, "#{settings.requests += 1}"]
  end

  get '/timestamped' do
    settings.counter += 1
    header = settings.counter > 2 ? '1' : '2'

    if env['HTTP_IF_MODIFIED_SINCE'] == header
      [304, {}, '']
    else
      [200, { 'Last-Modified' => header }, "#{settings.requests += 1}"]
    end
  end

  get '/etag' do
    settings.counter += 1
    tag = settings.counter > 2 ? '1' : '2'

    if env['HTTP_IF_NONE_MATCH'] == tag
      [304, { 'ETag' => tag, 'Cache-Control' => 'max-age=200', 'Date' => Time.now.httpdate, 'Expires' => (Time.now + 200).httpdate, 'Vary' => '*' }, ""]
    else
      [200, { 'ETag' => tag, 'Cache-Control' => 'max-age=0', 'Date' => settings.yesterday, 'Expires' => Time.now.httpdate, 'Vary' => 'Accept' }, "#{settings.requests += 1}"]
    end
  end
end
