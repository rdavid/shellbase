redo-ifchange lib/* app/*
for f in app/*_okey; do
	"$f" 2>&1
done
for f in app/*_fail; do
	"$f" 2>&1 || :
done
