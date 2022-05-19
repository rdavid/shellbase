redo-ifchange ./*.sh
shellcheck -x ./*.sh
redo-ifchange inc/*
shellcheck inc/*
