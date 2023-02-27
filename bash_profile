# .bashrc is ignored on Mac OS X
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
if [ -f ~/.zshrc ]; then
  . ~/.zshrc
fi

source /Users/geonu/.docker/init-bash.sh || true # Added by Docker Desktop
