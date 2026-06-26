{lib, ...}:
let inherit (lib) mkDefault; in {
  programs.bash.promptInit = mkDefault ''
    if [ "$(id -u)" = 0 ]
      then PS1='\[\e[01;31m\]\$ \[\e[00m\]'
      else PS1='\[\e[01;32m\]\$ \[\e[00m\]'
    fi
  '';
}
