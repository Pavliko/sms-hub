require "rubygems"
require "sinatra/base"
require 'json'
require 'slack-notifier'
require 'yaml'

config = YAML.load_file('config/settings.yml')

$notifier = Slack::Notifier.new(config['slack_webhook'])

class SmsHub < Sinatra::Base
  post '/pull' do
    success = false
    if params[:secret] == '1945'
      $notifier.username = params['from']
      $notifier.ping params['message'], icon_url: 'http://smssync.ushahidi.com/assets/media/logo.png'
      success = true
    end

    content_type :json
    {
      payload: {
        success: success,
        error: nil
      }
    }.to_json
  end
end
