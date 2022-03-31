# frozen_string_literal: true

module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx|djgpp/ =~ RUBY_PLATFORM) != nil
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

  def OS.get_os
    case
    when OS.windows? then "Windows #{RUBY_PLATFORM}"
    when OS.linux? then "Linux #{RUBY_PLATFORM}"
    when OS.unix? then "Unix #{RUBY_PLATFORM}"
    when OS.mac? then "Mac #{RUBY_PLATFORM}"
    else "Unknown #{RUBY_PLATFORM}"
    end
  end
end
