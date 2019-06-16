class LinebotController < ApplicationController
    require 'line/bot'  # gem 'line-bot-api'
    require "json"
    require "open-uri"

  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)

    events.each { |event|

        if event.message['text'].include?("天気")
            API_KEY = ENV["WEATHER_APIKEY"]
            BASE_URL = "http://api.openweathermap.org/data/2.5/forecast"

            weatherResponse = open(BASE_URL + "?q=tokyo,jp&APPID=#{API_KEY}")
            otenki = weatherResponse.weather[0].main
            response = otenki
        elsif event.message["text"].include?("行ってきます")
            response = "どこいくの？どこいくの？どこいくの？寂しい寂しい寂しい。。。"
        elsif event.message['text'].include?("おはよう")
            response = "おはよう。なんで今まで連絡くれなかったの？"
        else
            response = "こんにちは"
        end

        case event
        when Line::Bot::Event::Message
            case event.type
            when Line::Bot::Event::MessageType::Text
            message = {
                type: 'text',
                text: response
            }
            client.reply_message(event['replyToken'], message)
            end
        end
    }

    head :ok
  end
end
