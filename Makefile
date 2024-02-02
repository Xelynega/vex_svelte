build/index.html: src/routes/+page.svelte src/routes/control/+page.svelte src/routes/admin/+page.svelte static/gifs/* static/robots/*
	npm run build

.PHONY: run dev iframe
run: build/index.html
	cd build && python3 -m http.server

dev:
	npm run dev

iframe: build/index.html
	cp iframe.html build/iframe.html && cd build && python3 -m http.server
