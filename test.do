redo-ifchange all
for f in app/*.sh; do
	sh "$f"
done
