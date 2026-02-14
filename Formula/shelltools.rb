# Homebrew Formula for MacShellTool
# Save this file as: homebrew-tap/Formula/shelltools.rb

class Shelltools < Formula
  desc "macOS Terminal Toolkit - All-in-One System Maintenance & Development Tools"
  homepage "https://github.com/JIANGJINGZHE/MacShellTool"
  url "https://github.com/JIANGJINGZHE/MacShellTool/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"
  license "MIT"
  version "1.0.0"

  def install
    libexec.install Dir["*.sh"]
    libexec.install "tool"
    
    # Update TOOL_DIR path in main script
    inreplace libexec/"tool", 'TOOL_DIR="$HOME/ShellTools"', "TOOL_DIR=\"#{libexec}\""
    
    bin.install_symlink libexec/"tool"
  end

  test do
    system "#{bin}/tool", "help"
  end
end
