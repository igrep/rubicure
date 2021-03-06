module Rubicure
  # Precure girl (ex. Cure Peace, Cure Rosetta, Cure Honey)
  #
  # this is record of "config/girls.yml"
  class Girl
    attr_reader :human_name, :precure_name, :transform_message, :extra_names,
                :current_state, :state_names, :created_date, :attack_messages,
                :transform_calls
    attr_writer :io

    @@cache = {}
    @@config = nil
    @@sleep_sec = 1

    def initialize(human_name: nil, precure_name: nil, transform_message: nil, extra_names: [],
                   created_date: nil, attack_messages: [], transform_calls: [])
      @human_name        = human_name
      @precure_name      = precure_name
      @transform_message = transform_message
      @extra_names       = extra_names || []
      @created_date      = created_date
      @current_state     = 0
      @state_names = [@human_name, @precure_name]
      @state_names += @extra_names unless @extra_names.empty?
      @attack_messages   = [""] + attack_messages
      @transform_calls   = transform_calls

      @io = $stdout
    end

    def ==(other)
      other.is_a?(self.class) && self.human_name == other.human_name
    end

    # @return [String] name of current form
    def name
      @state_names[@current_state]
    end
    alias to_s name

    # human -> precure ( -> extra forms ) -> human ...
    # @return [Rubicure::Girl] self
    def transform!
      @current_state += 1
      @current_state = 0 unless @current_state < @state_names.length

      print_by_line @transform_message  if @current_state == 1

      self
    end

    def humanize!
      @current_state = 0
      self
    end
    alias :humanize :humanize!
    deprecate :humanize, :humanize!

    def attack!
      raise "require transform" if current_attack_message.blank?

      print_by_line current_attack_message

      current_attack_message
    end

    # @param girl_name [Symbol]
    # @return [Rubicure::Girl]
    def self.find(girl_name)
      raise "unknown girl: #{girl_name}" unless valid?(girl_name)

      unless @@cache[girl_name]
        girl_config = config[girl_name] || {}
        @@cache[girl_name] = Rubicure::Girl.new(girl_config)
      end

      @@cache[girl_name]
    end

    # @return [Array<Symbol>]
    def self.names
      config.keys
    end

    # @return [Array<Symbol>]
    def self.uniq_names
      uniq_names = []
      config.each do |name, series|
        uniq_names << name unless uniq_names.any? { |uniq_name| config[uniq_name][:precure_name] == series[:precure_name] }
      end
      uniq_names
    end

    # @return [Hash] content of config/girls.yml
    def self.config
      unless @@config
        config_file = "#{File.dirname(__FILE__)}/../../config/girls.yml"
        @@config = YAML.load_file(config_file).deep_symbolize_keys
      end
      @@config
    end

    # @return [Hash] content of config/precure.yml
    def self.reload_config!
      @@cache = {}
      @@config = nil
      config
    end

    # @param [Symbol] girl_name
    def self.valid?(girl_name)
      names.include?(girl_name)
    end

    def self.sleep_sec=(sleep_sec)
      @@sleep_sec = sleep_sec
    end

    private

    def current_attack_message
      attack_messages[current_state]
    end

    def print_by_line(message)
      index = 0
      message.each_line do |line|
        sleep(@@sleep_sec) if index > 0
        @io.puts line
        index += 1
      end
    end

    def method_missing(method_name, *args)
      shortened_name = method_name.to_s.
          sub(%r/\Aprecure_|_precure\z/, "").
          sub(%r/!\z/, "")

      return transform!(*args) if @transform_calls.include?(shortened_name)

      super
    end
  end
end
