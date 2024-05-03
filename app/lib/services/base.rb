# frozen_string_literal: true

require 'dry-struct'

module Services
  class Result
    attr_accessor :value, :status

    def initialize(value, status)
      @value = value
      @status = status
    end

    def success?
      is_a? Success
    end

    def failure?
      is_a? Error
    end
  end

  class Success < Result; end
  class Error < Result; end

  class Types
    include Dry.Types()

    Operator = Types.Instance(Operator)
    OperatorMarket = Types.Instance(OperatorMarket)
    User = Types.Instance(User)
    Team = Types.Instance(::Teams::Team)
    CompanyType = Types.Instance(CompanyType)
    Market = Types.Instance(::Markets::Market)
    Relation = Types.Instance(ActiveRecord::Relation)
  end

  class Base < Dry::Struct
    # include Pundit

    def initialize(*args)
      super(*args)
    end

    class CallLater
      def initialize(object_class, **options)
        @object_class = object_class
        @options = options
      end

      def call_later(*args)
        @object_class.new(*args).call_later(@options)
      end
    end

    #  Shortcut
    #
    def self.call(*args)
      new(*args).call
    end

    #
    # call_later(*args)
    # set(wait: 5.minutes).call_later(*args)
    # set(wait: 5.minutes).call_later(*args)

    def self.call_later(*args)
      CallLater.new(self).call_later(*args)
    end

    def self.set(**options)
      CallLater.new(self, options)
    end

    #  Here is the actual logic should run
    #
    def perform
      raise "You must override #perform in class #{self.class.name}"
    end

    #  Wrapper for performing the action
    #
    def call(*params, &block)
      perform(*params, &block)
    end

    #  Action scheduler wrapper
    #
    # call_later
    # call_later(wait: 5.minutes)
    # call_later(wait_until: Time.now.tomorrow)

    def call_later(options = {})
      # ::ServiceJob.set(options).perform_later(self.class.name, attributes)
    end

    protected

    # def pundit_user
    #   CurrentControllerService.get.current_user
    # end

    # result(value = nil, status = nil)

    def success(value = nil, status = 200)
      ::Services::Success.new(value, status)
    end

    private

    def error(value = nil, status = 400)
      ::Services::Error.new(value, status)
    end
  end
end
