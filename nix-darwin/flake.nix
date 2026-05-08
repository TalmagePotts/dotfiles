{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs; [
        # basex                             # XML database and XPath/XQuery processor
        bat                                 # better cat
        bun
        cloudflared                       # Cloudflare daemon
        cocoapods                         # Manage dependencies for Xcode projects
        direnv                            # Load Nix environment from .envrc files
        dust                              # Disk usage tool (du, but better)
        ffmpeg                            # Video/audio encoding and streaming
        flyctl                            # CLI for Fly.io
        fzf                               # Fuzzy find files
        fd                                # Better find
        gh                                # GitHub CLI
        git-filter-repo                   # Git repository history rewriter
        git-lfs                           # Git Large File Storage
        gnupg                             # GPG key manager
        # httrack                           # Website mirroring utility
        imagemagick                       # Image manipulation toolkit
        javaPackages.compiler.openjdk17   # Java 17
        javaPackages.compiler.openjdk21   # Java 21
        lazygit                           # Git, but lazy
        libimobiledevice                  # iOS device communication library
        mas                               # CLI to manage Mac App Store apps
        neovim                            # Vim, but epic
        nix-direnv                        # Faster direnv for Nix
        nodejs_22                         # Node.js 22
        nushell                           # Modern shell with structured data
        ollama                            # Run LLMs locally
        pandoc                            # Universal document converter
        pipx                              # Install Python apps in isolated environments
        pnpm                              # Fast, disk-efficient package manager
        poppler                           # PDF rendering library
        potrace                           # Bitmap tracing tool
        restic                            # Backup manager
        ripgrep                           # Better grep
        ruby                              # Ruby programming language
        supabase-cli                      # Supabase CLI
        swift-format                      # Swift code formatter (Apple's official)
        swiftformat                       # Swift code formatter
        swiftlint                         # Swift linter
        tesseract
        tldr                              # Simplified man pages
        stow
        tree                              # Display directory structure
        vim                               # Vim text editor
        wget                              # Download files from web
        xcbeautify                        # Beautifier for xcodebuild
        xcodegen                          # Generate Xcode projects
        yazi                              # Terminal file manager
        zoxide                            # Better cd (directory jumper)
        ];

      # Set nvim as default editor
      environment.variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };

      programs.direnv = {
        enable = true;
        # silent = true;
        nix-direnv.enable = true;
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Primary user for user-specific options like Homebrew
      system.primaryUser = "talmage";

      # Passwordless Sudo
      security.sudo.extraConfig = ''
        talmage ALL=(ALL) NOPASSWD: ALL
      '';

      # Remap right Command key to Escape at login
      launchd.user.agents.remap-keys = {
        serviceConfig = {
          ProgramArguments = [
            "/usr/bin/hidutil"
            "property"
            "--set"
            ''{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0},{"HIDKeyboardModifierMappingSrc":0x7000000E7,"HIDKeyboardModifierMappingDst":0x700000029}]}''
          ];
          RunAtLoad = true;
        };
      };

      # Homebrew configuration
      homebrew = {
        enable = true;

        # Taps (third-party repositories)
        taps = [
          "whatpulse/whatpulse"
        ];

        # CLI tools
        brews = [
          "atuin"
          "codex"
          "elixir"
          "mole"
          "ocrmypdf"
          "opencode"
          "pass"
          "pdftk-java"
          "postgresql"
          "powerlevel10k"
          "python@3.14"
          "sqlite"
          "tmux"
          "xcode-build-server"
        ];

        # GUI Applications
        casks = [
          "android-studio"
          "anki"
          "arc"
          "audacity"
          "basictex"
          # "balenaetcher"
          "chatgpt"
          "claude"
          "cursor"
          "flutter"
          "ghostty"
          "github"
          "godot"
          "google-chrome"
          "hammerspoon"
          "homerow"
          "iina"
          "imazing"
          "karabiner-elements"
          "logos"
          "loom"
          "microsoft-onenote"
          "microsoft-powerpoint"
          "microsoft-word"
          "minecraft"
          "moonlight"
          "obsidian"
          "parsec"
          "raycast"
          "remnote"
          "retroarch"
          "sf-symbols"
          "steam"
          "tailscale-app"
          "termius"
          "utm"
          "visual-studio-code"
          "webex"
          "whatpulse"
          "windows-app"
          "zed"
          # "balenaetcher"
          # "grandperspective"
          # "notion"
          # "obs"
          # "openmtp"
          # "opencode-desktop"
          # "prusaslicer"
          # "visualboyadvance-m"
          # "void"
          # "zoom"
        ];

        # Mac App Store apps by ID
        masApps = {
          # "Base" = 402383384;
          # "DaVinci Resolve" = 571213070;
          # "DevCleaner" = 1388020431;
          # "Harvest" = 506189836;
          # "Magnet" = 441258766;
          # "Numbers" = 409203825;
          # "Pages" = 409201541;
          # "RocketSim" = 1504940162;
          # "Slack" = 803453959;
          "Developer" = 640199958;
          "NotesAI" = 6504924859;
          "Obsidian Web Clipper" = 6720708363;
          "Reins" = 6739738501;
          "SmartGo One" = 1465746992;
          "TestFlight" = 899247664;
          "Xcode" = 497799835;
        };

# Manual installs (no Homebrew cask or MAS available):
# - Comet (email) — download from superhuman.com
# - Conductor — conductor.build
# - iClicker — iclicker.com

# Manual npm global installs (not in nixpkgs):
# npm install -g @google/gemini-cli
# npm install -g @qwen-code/qwen-code
# npm install -g @supabase/mcp-server-supabase
# npm install -g @tcsenpai/ollama-code

        # Automatically uninstall things in Homebrew not listed in this flake
        onActivation.cleanup = "zap";

        # Auto-update Homebrew
        onActivation.autoUpdate = true;

        # Upgrade outdated packages
        onActivation.upgrade = true;
      };

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;
      nixpkgs.config.allowUnfree = true;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild switch --flake .#talmage
    darwinConfigurations."talmage" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
