module RemoteExec
  module Validation
    def self.coerce_guard_config(guard_config)
      guard_config = { command: guard_config } if guard_config.is_a?(Array) || guard_config.is_a?(String)
      raise 'remote guards must be either a String, an Array or a Hash' unless guard_config.is_a?(Hash)
      guard_config[:request_pty] = false unless guard_config.key?(:request_pty)
      guard_config
    end

    def self.guard_config_checks
      # :request_pty is defaulted in coerce
      required_keys = [:command, :request_pty]
      allowed_keys = required_keys + []

      {
        "must be Hash with keys #{required_keys}" => ->(v) { required_keys.all? { |key| v.key?(key) } },
        "must be Hash with only keys #{allowed_keys}" => ->(v) { v.keys.all? { |key| allowed_keys.include?(key) } },
        ':command must be Array or String' => ->(v) { v[:command].is_a?(Array) || v[:command].is_a?(String) },
        ':request_pty must be boolean' => ->(v) { v[:request_pty] == true || v[:request_pty] == false },
      }
    end
  end
end
