build/index.html: src/routes/+page.svelte
	npm run build

.PHONY: run dev
run: build/index.html
	cd build && python3 -m http.server

dev:
	npm run dev
