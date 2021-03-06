require "bundler/setup"

ENV["MT_NO_EXPECTATIONS"] = "1"

require "minitest"
require "minitest/spec"
require "minitest/pride"

require "mocha/minitest"

require "docker-api"
require "http"

require "./test/support/deprecated_helper"

puts "Docker URL: #{Docker.url}"

image = "kennethreitz/httpbin"
port  = 8080

unless Docker::Image.exist?(image)
  puts "Pulling #{image}..."

  Docker::Image.create("fromImage" => image)
end

begin
  container = Docker::Container.get("httpbin")
rescue Docker::Error::NotFoundError
  puts "Creating #{image}..."

  container = Docker::Container.create(
    "name" => "httpbin",
    "Image" => image,
    "HostConfig" => {
      "PortBindings" => {
        "80/tcp" => [{ "HostPort" => port.to_s }]
      }
    }
  )
end

puts "Starting #{image}..."

container.start

at_exit do
  puts "Stopping #{image}..."

  container.kill
end

$httpbin = "http://localhost:#{port}"

HTTP.get($httpbin).to_s rescue retry # wait until service has started

Minitest.autorun
