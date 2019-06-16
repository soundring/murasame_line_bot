class LinebotController < ApplicationController
    require 'line/bot'  # gem 'line-bot-api'
    require 'wikipedia'
    require "json"
    require 'net/http'
    require 'uri'

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

        # Wikipe情報
        if event.message['text'] != nil
            word = event.message['text']
            Wikipedia.Configure {
                domain 'ja.wikipedia.org'
                path 'w/api.php'
            }
        end

        page = Wikipedia.find(word)

        if event.message['text'].include?("天気")
            tenki_url = 'http://api.openweathermap.org/data/2.5/forecast?q=tokyo,jp&lang=ja&appid='
            token = ENV["WEATHER_APIKEY"]

            uri = URI.parse(tenki_url + token)
            http = Net::HTTP.new(uri.host, uri.port)

            req = Net::HTTP::Get.new(uri.request_uri)
            res = http.request(req)
            json = JSON.parse(res.body)
            response = json["list"][0]["weather"][0]["description"] + "だよ！"

        elsif event.message["text"].include?("行ってきます")
            response = "どこいくの？どこいくの？どこいくの？寂しい寂しい寂しい。。。"
        elsif event.message['text'].include?("おはよう")
            response = "おはよう。なんで今まで連絡くれなかったの？"
        else
            response = "説明しよう！！" + "\n" + page.summary + "\n" + page.fullurl
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
