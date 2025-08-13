.PHONY: sync
sync:
	git pull origin main
	git submodule sync --recursive
	git submodule update --init --recursive --remote