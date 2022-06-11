redo-ifchange inc/* app/*
for f in app/*_okey.sh; do
	"$f" 2>&1
done
for f in app/*_fail.sh; do
	"$f" 2>&1 || :
done
