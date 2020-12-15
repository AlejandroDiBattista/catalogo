require 'discordrb'

bot = Discordrb::Bot.new token: 'Nzg4MjExNjAwNTg2MDQ3NTU4.X9gNQQ.p_tSsd3hj5pw_jFrFwhTSVqD2PQ'


bot.send_message 'franco-bot#5114', "Hola mundo!"

# '
# # p Discordrb::Channel.new(1,1)
# # bot.message(with_text: 'Ping!') do |event|
# #   event.respond 'Pong!'
# # end

# # bot.chanel
# # at_exit{bot.stop}
# # bot.run