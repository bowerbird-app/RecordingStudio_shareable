# frozen_string_literal: true

module CapabilitySnapshot
  def snapshot_shareable_state!
    configuration = RecordingStudio.configuration
    @original_capabilities = configuration.instance_variable_get(:@capabilities).transform_values(&:dup)
    @original_capability_options = configuration.instance_variable_get(:@capability_options).dup
    @original_shareable_configuration = RecordingStudioShareable.instance_variable_get(:@configuration)
    configuration.instance_variable_set(:@capabilities, {})
    configuration.instance_variable_set(:@capability_options, {})
    RecordingStudioShareable.instance_variable_set(
      :@configuration,
      RecordingStudioShareable::Configuration.new
    )
  end

  def restore_shareable_state!
    RecordingStudio.configuration.instance_variable_set(:@capabilities, @original_capabilities)
    RecordingStudio.configuration.instance_variable_set(:@capability_options, @original_capability_options)
    RecordingStudioShareable.instance_variable_set(:@configuration, @original_shareable_configuration)
  end
end
