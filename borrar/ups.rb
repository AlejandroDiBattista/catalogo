require 'httparty'

class UPS
  include HTTParty
  base_uri 'www.ups.com/track'

  def initialize(track_id="1ZAY63950428667095")
    @options = {:query => {Locale: "en_AR", TrackingNumber: [track_id]}, :options => { :headers => { 'Content-Type' => 'application/json' } }}
  end

  def questions
    self.class.post("", @options )
  end
end

ups = UPS.new()
puts ups.questions
