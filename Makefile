.PHONY: build
build:
	npm run build

.PHONY: run
run: build
	cd build && python3 -m http.server
