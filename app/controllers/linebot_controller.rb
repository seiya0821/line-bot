class LinebotController < ApplicationController
    require 'line/bot'  # gem 'line-bot-api'
    require 'open-uri'
    require 'kconv'
    require 'rexml/document'
  
    # callbackアクションのCSRFトークン認証を無効
    protect_from_forgery :except => [:callback]
  
    def callback
      body = request.body.read
      signature = request.env['HTTP_X_LINE_SIGNATURE']
      unless client.validate_signature(body, signature)
        error 400 do 'Bad Request' end
      end
      events = client.parse_events_from(body)
      events.each { |event|
        case event
          # メッセージが送信された場合の対応（機能①）
        when Line::Bot::Event::Message
          case event.type
            # ユーザーからテキスト形式のメッセージが送られて来た場合
          when Line::Bot::Event::MessageType::Text
            # event.message['text']：ユーザーから送られたメッセージ
            input = event.message['text']
            url  = "https://www.drk7.jp/weather/xml/13.xml"
            xml  = open( url ).read.toutf8
            doc = REXML::Document.new(xml)
            xpath = 'weatherforecast/pref/area[4]/'
            # 当日朝のメッセージの送信の下限値は20％としているが、明日・明後日雨が降るかどうかの下限値は30％としている
            min_per = 30
            case input
              # 「明日」or「あした」というワードが含まれる場合
            when /.*(明日|あした).*/
              # info[2]：明日の天気
              per06to12 = doc.elements[xpath + 'info[2]/rainfallchance/period[2]'].text
              per12to18 = doc.elements[xpath + 'info[2]/rainfallchance/period[3]'].text
              per18to24 = doc.elements[xpath + 'info[2]/rainfallchance/period[4]'].text
              if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
                push =
                  "今日もお疲れ様！明日の天気だよね。\n明日は雨が降りそう、、傘を持って出かけるのがいいかも！\n今のところ降水確率はこんな感じだよ。\n　  6〜12時　#{per06to12}％\n　12〜18時　 #{per12to18}％\n　18〜24時　#{per18to24}％\nまた明日の朝の最新の天気予報で雨が降りそうだったら教えるね！"
              else
                push =
                  "明日の天気？\n明日は雨が降らない予定だよ！\nまた明日の朝の最新の天気予報で雨が降りそうだったら教えるねん！"
              end
            when /.*(明後日|あさって).*/
              per06to12 = doc.elements[xpath + 'info[3]/rainfallchance/period[2]l'].text
              per12to18 = doc.elements[xpath + 'info[3]/rainfallchance/period[3]l'].text
              per18to24 = doc.elements[xpath + 'info[3]/rainfallchance/period[4]l'].text
              if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
                push =
                  "明後日の天気だよね。\n何か素敵な予定があるのかな？\n明後日は雨が降りそう…\n当日の朝に雨が降りそうだったら教えるからね！"
              else
                push =
                  "明後日の天気？\n雨を吹き飛ばすぞ〜！！\n明後日は雨は降らない予定だよん\nまた当日の朝の最新の天気予報で雨が降りそうだったら教えるからね！"
              end
            when /.*(かわいい|可愛い|カワイイ|きれい|綺麗|キレイ|素敵|ステキ|すてき|面白い|おもしろい|ありがと|すごい|スゴイ|スゴい|頑張|がんば|ガンバ).*/
              push =
                "ありがとう！！！\nそんな優しい言葉をかけてくれるあなたはとても素敵です！！"
            when /.*(好き|すき).*/
              push = 
                "ふふふっこちらこそ大好きだよおおおお！！"
            when /.*(まりな).*/
              push = 
                "何よりも大切でかけがいのない人です。いつも側にいてくれて、幸せをくれてありがとう！！大好きですっ！！！"
            when /.*(こんにちは|こんばんは|初めまして|はじめまして|おはよう).*/
              push =
                "こんにちは。\n声をかけてくれてありがとう\n今日があなたにとっていい日になりますように！！"
            when /.*(せいや|聖矢).*/
                push =
                "まりな〜いつもありがとう！大好きだよおお！！"
            when /.*(会いたい|あいたい).*/
                push = 
                "俺もあいたいよおお！！早くよしよししたいですっ"
            when /.*(お腹すいた|おなかすいた|おなかすいたよ|お腹すきました).*/
                push = 
                "お腹すいたね〜！今日のご飯は何にしよっか！！外に食べに行くのもいいかもだよ！！"
            when /.*(辛い|つらい).*/
                push =
                "あんまり無理しないで、深呼吸深呼吸だよ！大丈夫必ずいい方向に向かうから！一緒にがんばろっ！忘れないでまりなは一人じゃないからね！"
            when /.*(眠い|ねむい).*/
                push =
                "お疲れ様だよおお！今日もよく頑張りました！美味しいもの食べて今日は早めにおやすみしよっ"
            when /.*(こはく).*/
                push =
                "ずっとまりなが大好きってしっぽふってます！"
            when /.*(ぽんた).*/
                push =
                "もうねむいみたいですぴ〜って寝てます！よしよししてあげてね！"
            when /.*(ごめんね|ごめん).*/
                pish =
                "こちらこそごめんよお、、一緒に美味しいもの食べに行かない？"
            else
              per06to12 = doc.elements[xpath + 'info/rainfallchance/period[2]l'].text
              per12to18 = doc.elements[xpath + 'info/rainfallchance/period[3]l'].text
              per18to24 = doc.elements[xpath + 'info/rainfallchance/period[4]l'].text
              if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
                word =
                  ["雨だけど元気出していこうね！",
                   "雨に負けずファイトだよおおお！！",
                   "雨だけど必ずいいことあるよお！！風邪ひかないようにだよ！"].sample
                push =
                  "今日の天気？\n今日は雨が降りそうだから傘があった方が安心かも！\n　  6〜12時　#{per06to12}％\n　12〜18時　 #{per12to18}％\n　18〜24時　#{per18to24}％\n#{word}"
              else
                word =
                  ["天気もいいから色々見て回るといいかもっ！！",
                   "今日会う人のいいところを見つけて是非その人に教えてあげて！",
                   "今日がとっても素晴らしい一日になりますように！",
                   "雨が降っちゃったらごめんよお"].sample
                push =
                  "今日の天気？\n今日は雨は降らなさそうだよ！\n#{word}"
              end
            end
            # テキスト以外（画像等）のメッセージが送られた場合
          else
            push = "テキストで入力してくれるとお話できるかも！"
          end
          message = {
            type: 'text',
            text: push
          }
          client.reply_message(event['replyToken'], message)
          # LINEお友達追された場合（機能②）
        when Line::Bot::Event::Follow
          # 登録したユーザーのidをユーザーテーブルに格納
          line_id = event['source']['userId']
          User.create(line_id: line_id)
          # LINEお友達解除された場合（機能③）
        when Line::Bot::Event::Unfollow
          # お友達解除したユーザーのデータをユーザーテーブルから削除
          line_id = event['source']['userId']
          User.find_by(line_id: line_id).destroy
        end
      }
      head :ok
    end
  
    private
  
    def client
      @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      }
    end
  end