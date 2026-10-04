require_relative 'config/environment'
class TestController < ApplicationController
  def index
    response.set_cookie('raw_cookie', value: 'hello', httponly: true)
    render json: { ok: true }
  end
end
