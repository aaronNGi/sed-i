 sed-i
========================================================================

A wrapper for sed(1), to emulate the non-portable in-place editing
capability (`-i`, `--in-place`) by using a temporary file.  It mirrors
the options mandated by POSIX (`-e`, `-f`, `-n`), with the addition of
the non-portable `-r` and `-E`, for extended regular expressions, and
GNU style long-option versions.  If no `-i` is used, a single sed(1)
will be run, as opposed to running one per file, where each one is
writing to a temporary file.  The temporary file will eventially be
moved to overwrite the original file.

There are a lot of unportable build scripts/systems, preventing the
usage of sed(1) from sbase or 9base, for example.  Instead of keeping a
separate sed(1) around, this wrapper can be used as compatiblity layer.

To use this wrapper, it should be placed in a directory which is listed
in $PATH first, before the directory containing the wrapped sed(1).


 Installation
------------------------------------------------------------------------

    make install
    PATH=/usr/local/bin:$PATH


 Options
------------------------------------------------------------------------

    -e <script> | --expression=<script> | --expression <script>
    -f <script_file> | --file=<script_file> | --file <script_file>
    -i[<suffix>] | --in-place[=<suffix>]
    -n | --quiet | --silent
    -r | -E | --regexp-extended

All other options will be passed to the wrapped sed(1) as is.
