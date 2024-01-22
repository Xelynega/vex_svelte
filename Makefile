build/index.html: src/routes/+page.svelte
	npm run build

.PHONY: run dev iframe
run: build/index.html
	cd build && python3 -m http.server

dev:
	npm run dev

iframe: build/index.html
	cp iframe.html build/iframe.html && cd build && python3 -m http.server
