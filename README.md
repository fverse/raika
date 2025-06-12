# Raika

Raika is a command-line tool for managing Procfile-based applications. Run and manage multiple processes in your development environment with ease.

Note: Raiks is under development. Not all features are available now.

## Installation

**Build from source**  

Currently, there are no prebuilt binaries available. You will need to build it from source, which requires OCaml, OPAM, and Dune to be installed.

Clone the repository:

   ```
   git clone https://github.com/fverse/raika.git && cd raika
   ```

Install dependencies:

   ```
   opam install . --deps-only
   ```

Build the project:

   ```
   dune build
   ```

## Usage

Create a Procfile in your project root:

```
# Procfile
web: npm run dev
redis: redis-server
db: ./scripts/start_db.sh
```

Run Raika from your terminal:

```bash
raika
```

To use a different `Procfile`:

```bash
raika --file path/to/your/file/Procfile.dev
```

Use the `--help` flag to see all available commands and flags: `raika --help`
