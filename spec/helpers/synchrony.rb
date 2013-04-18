# Monkey patching to wrap test in EM.synchrony context
class MiniTest::Spec < MiniTest::Unit::TestCase
  module DSL
    alias_method :old_it, :it
    alias_method :old_before, :before
    alias_method :old_after, :after
    
    def it(desc = "anonymous", &block)
      sync_block = proc do
        EM.synchrony do
          self.instance_eval(&block)
          EM.stop
        end
      end
      old_it(desc, &sync_block)
    end

    def before(type = nil, &block)
      sync_block = proc do
        EM.synchrony do
          self.instance_eval(&block)
          EM.stop
        end
      end
      old_before(type, &sync_block)
    end

    def after(type = nil, &block)
      sync_block = proc do
        EM.synchrony do
          self.instance_eval(&block)
          EM.stop
        end
      end
      old_after(type, &sync_block)
    end
  end
end