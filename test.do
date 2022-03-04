redo-ifchange all
for f in app/*_okey.sh; do
	"$f" --verbose 2>&1
done
for f in app/*_fail.sh; do
	"$f" --verbose 2>&1 || :
done
