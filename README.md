# CLS-Wrapper

A wrapper for cls libraries to be used as stdio/fio purpose. If you have a cls based (de)compressor and want to use that with file/std io but not using freearc, you can use this.
In order to use cls with this, cls-xxx.dll must be renamed to arc-xxx.dll to avoid conflicts with freearc.

## Usage:
clsw.exe c:{compressor} {parameters} infile outfile
clsw.exe d:{compressor} infile outfile

Here, c: and d: represents compress and decompress. InFile/OutFile can be replaced with "-" for stdin/stdout

## Sample usage:

[External compressor:lolz]
header = 0
packcmd = lolz_x64.exe {options} $$arcdatafile$$.tmp $$arcpackedfile$$.tmp
unpackcmd = clsw.exe d:lolz - - <stdin> <stdout>

[External compressor:bpk]
header = 0
packcmd = clsw.exe c:bpk - - <stdin> <stdout>
unpackcmd = clsw.exe d:bpk_u - - <stdin> <stdout>

[External compressor:diskspan]
header = 0
packcmd = clsw.exe c:diskspan 100mb:512mb - - <stdin> <stdout>
unpackcmd = clsw.exe d:diskspan - - <stdin> <stdout>
