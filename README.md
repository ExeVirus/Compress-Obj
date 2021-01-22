# Compress-Obj
Lossless and lossy Obj Compression Utility in Lua

# Usage

### Simple usage:

```
lua compress.lua -f test.obj
```

### Advanced Parameters:

**-f <filename>**
- specify the file to compress

**-o <filename>**   
- specify the filename of the output (default is to overwrite original file)

**-precision <number>**
- Specify the precision of decimals to output for all values (1-6). Default is 6, smallest file size is 1.
Typically a good number for most use cases is 2 or 3. This is a lossy operation! 

**-comments** 
- Keep comments in the file. (removed by default)

**-h**
- Show this usage information
