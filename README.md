# mssql-regex
Simple package allowing to use CLR RegEx within MSSQL.
The package uses the static function of the RegEx class with the compiled flag for better performance.
There's an initial cost upon executing a new regex as the regex plan is compiled into intermediate language opcodes and cached for reuse.

The functions return either a scalar string value or the ones that are named *Matches* return a table of strings containing each match
