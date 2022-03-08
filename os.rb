# frozen_string_literal: true

module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.unix?
    !OS.windows?
  end

  def OS.linux?
    OS.unix? and !OS.mac?
  end

  def OS.jruby?
    RUBY_ENGINE == 'jruby'
  end

  def OS.get_os
    return "Windows #{RUBY_PLATFORM}" if OS.windows?
    return "Linux #{RUBY_PLATFORM}" if OS.linux?
    return "Unix #{RUBY_PLATFORM}" if OS.unix?
    return "Mac #{RUBY_PLATFORM}" if OS.mac?
  end
end
