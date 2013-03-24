module Monga
  class Response
    include EM::Deferrable

    def self.surround
      resp = new
      yield(resp)
      resp
    end
  end
end