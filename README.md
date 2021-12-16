# RLECompressor
A simple compressor for .bin graphics files that are 4096 bytes (4K) or less, in the VGA Mode 13h 8bpp format. This won't run on modern Windows, you'll need to use DosBOX or something similar. This program is a work in progress, use at your own risk! It works as long as the input is good; there is some checking for bad input but it hasn't been rigorously tested for all bad input yet.


The easiest way to use this is to have the executable in the same folder as the file you wish to compress. Then open DOSBox and type:

Mount C: \FilePath\


where \FilePath\ is the directory containing both this executable and the file you wish to compress. For example, if you have DOSBox somewhere in C:\ and your executable and the picture file in C:\foo\ then you can type:

Mount C: \foo\

Then type

C:
RLE.exe /filename.bin

where filename is the name of your file.
It needs to be in .bin format for now, other formats will be supported soon. It also assumes that the picture is an indexed 8bpp image (max 256 colors), excluding 0xFE. 0xFE is used as the terminator so don't use a color with that index in your picture or it will be truncated early.

The program will open the input file read-only, so it will not actually change the input file in any way. However, the file it creates will be named "out.bin", so any file with that name in the same directory will be overwritten.

The output is RLE compressed using the following custom scheme, which was created to help with other projects I'm working on:

* A "run" is encoded with 3 bytes. 0xF8 signals the start of a run. The next byte is the run length (one-indexed). The byte after that is the data.
* A sequence of consecutive bytes that is 3 or less will not be run-length encoded and shall be stored as is. This prevents "checkerboards" from taking up more space than the original file. 
* The 0xFE terminator is not checked for when the program parses a run length, so it is perfectly valid to have a run length of 254 or a run of any size greater than 3 whose data is 254, without the program terminating early. However, 0xFE cannot be a standalone pixel. This 0xFE was chosen based on the fact that in the standard VGA palette, color indices 0xF8-0xFF are essentially unused, therefore they make excellent control codes. 0xFF was deliberately not used as a terminator because doing so would lead to incompatibility between this program and sprite blitters.

