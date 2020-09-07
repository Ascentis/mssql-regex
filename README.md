# mssql-regex
Simple package allowing to use CLR Regex class within MSSQL.
The package caches compiled Regex objects based on regex pattern. Regex objects are popped from the cache, used and returned back to the cache.
There's an initial cost upon executing a new regex as the regex plan is compiled into intermediate language opcodes and cached for reuse.

The functions return either a scalar string value or the ones that are named *Matches* return a table of strings containing each match

The library provides a set of functions to inspect the status of the cache and the number of executions performed since the library was loaded.
Methods to reset the stats are provided.
