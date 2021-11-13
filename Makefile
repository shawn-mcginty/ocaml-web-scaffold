# Change executable name as needed
executable = scaffold.exe

.PHONY:install
install:
	npx esy install

.PHONY: build
build:
	npx esy b dune build src/$(executable)

.PHONY: start
start:
	npx esy b dune exec src/$(executable)

.PHONY: clean
clean:
	rm -r dist | true