module RemoteExec
  module Validation
    def self.coerce_guard_config(guard_config, sensitive_default)
      guard_config = { command: guard_config } if guard_config.is_a?(Array) || guard_config.is_a?(String)
      raise 'remote guards must be either a String, an Array or a Hash' unless guard_config.is_a?(Hash)
      guard_config[:request_pty] = false unless guard_config.key?(:request_pty)
      guard_config[:sensitive_output] = sensitive_default unless guard_config.key?(:sensitive_output)
      guard_config[:sensitive_command] = sensitive_default unless guard_config.key?(:sensitive_command)
      guard_config
    end

    def self.guard_config_checks
      # :request_pty is defaulted in coerce
      required_keys = [:command, :request_pty, :sensitive_output, :sensitive_command]
      allowed_keys = required_keys + []

      {
        "must be Hash with keys #{required_keys}" => ->(v) { required_keys.all? { |key| v.key?(key) } },
        "must be Hash with only keys #{allowed_keys}" => ->(v) { v.keys.all? { |key| allowed_keys.include?(key) } },
        ':command must be Array or String' => ->(v) { v[:command].is_a?(Array) || v[:command].is_a?(String) },
        ':request_pty must be boolean' => ->(v) { v[:request_pty] == true || v[:request_pty] == false },
        ':sensitive_output must be boolean' => ->(v) { v[:sensitive_output] == true || v[:sensitive_output] == false },
        ':sensitive_command must be boolean' => ->(v) { v[:sensitive_command] == true || v[:sensitive_command] == false },
      }
    end
  end
end
