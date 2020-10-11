# Compiler options

`tl` supports some compiler options. These can either be specified on the command line or inside a `tlconfig.lua` file.

## Project configuration

When running `tl`, the compiler will try to read the compilation options from a file called `tlconfig.lua` inside the current working directory.

Here is an example of a `tlconfig.lua` file:
```lua
return {
    include_dir = {
        "folder1/",
        "folder2/"
    },
    preload_modules = {
        "my.other.module"
    }
}
```

## List of compiler options

| Command line option      | Config key        | Type       | Relevant Commands           | Description                                                                                                     |
| ---                      | ---               | ---        | ---                         | ---                                                                                                             |
| `-l --preload`           | `preload_modules` | `{string}` | `build` `check` `gen` `run` | Execute the equivalent of `require('modulename')` before executing the tl script(s).                            |
| `-I --include-dir`       | `include_dir`     | `{string}` | `build` `check` `gen` `run` | Prepend this directory to the module search path.                                                               |
| `--skip-compat53`        | `skip_compat53`   | `boolean`  | `build` `gen`               | Skip compat53 insertions.                                                                                       |
|                          | `include`         | `{string}` | `build`                     | The set of files to compile/check. See below for details on patterns.                                           |
|                          | `exclude`         | `{string}` | `build`                     | The set of files to exclude. See below for details on patterns.                                                 |
| `-s --source-dir`        | `source_dir`      | `string`   | `build`                     | Set the directory to be searched for files. `gen` will compile every .tl file in every subdirectory by default. |
| `-b --build-dir`         | `build_dir`       | `string`   | `build`                     | Set the directory for generated files, mimicking the file structure of the source files.                        |
|                          | `files`           | `{string}` | `build`                     | The names of files to be compiled. Does not accept patterns like `include`.                                     |
| `-p --pretend --dry-run` |                   |            | `build` `gen`               | Don't compile/write to any files, but type check and log what files would be written to.                        |
| `-q --quiet`             | `quiet`           | `boolean`  | `check`                     | Do not print information messages to stdout. Errors may still be printed to stderr.                             |

### Include/Exclude patterns

The `include` and `exclude` fields can have glob-like patterns in them:
- `*`: Matches any number of characters (excluding directory separators)
- `**/`: Matches any number subdirectories

In addition
- setting the `source_dir` has the effect of prepending `source_dir` to all patterns.
- currently, `include` will only include `.tl` files even if the extension isn't specified

For example:
If our project was laid out as such:
```
tlconfig.lua
src/
| foo/
| | bar.tl
| | baz.tl
| bar/
| | a/
| | | foo.tl
| | b/
| | | foo.tl
```

and our tlconfig.lua contained the following:
```lua
return {
   source_dir = "src",
   build_dir = "build",
   include = {
      "foo/*.tl",
      "bar/**/*.tl"
   },
   exclude = {
      "foo/bar.tl"
   }
}
```

Running `tl build -p` will type check the `include`d files and show what would be written to.
Running `tl build` will produce the following files.
```
tlconfig.lua
src/
| foo/
| | bar.tl
| | baz.tl
| bar/
| | a/
| | | foo.tl
| | b/
| | | foo.tl
build/
| foo/
| | baz.lua
| bar/
| | a/
| | | foo.lua
| | b/
| | | foo.lua
```

Additionally, complex patterns can be used for whatever convoluted file structure we need.
```lua
return {
   include = {
      "foo/**/bar/**/baz/**/*.tl"
   }
}
```
This will compile any `.tl` file with a sequential `foo`, `bar`, and `baz` directory in its path.
