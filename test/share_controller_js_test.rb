# frozen_string_literal: true

require "test_helper"

class ShareControllerJsTest < Minitest::Test
  def test_native_share_stays_hidden_unless_navigator_share_exists
    source = File.read(
      File.expand_path("../app/javascript/recording_studio_shareable/share_controller.js", __dir__)
    )

    assert_includes source, 'typeof navigator.share !== "function"'
    assert_includes source, "this.hasNativeTarget"
    assert_includes source, "this.nativeTarget.hidden = false"
    assert_includes source, "this.nativeTarget.classList.remove(\"hidden\")"
    assert_includes source, "await navigator.share("
    assert_includes source, "title: this.titleValue, text: this.textValue, url: this.urlValue"
    assert_includes source, 'error.name === "AbortError"'
  end
end
