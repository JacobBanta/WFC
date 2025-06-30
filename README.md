# WFC

A Wave Function Collapse library for Zig 0.14.0.

## Installation

```sh
zig fetch --save git+https://github.com/JacobBanta/WFC
```

Then add the following to `build.zig`:

```zig
const WFC = b.dependency("WFC", opts).module("WFC");
exe.root_module.addImport("WFC", WFC);
```

## How to use

```zig
const WFC = @import("WFC").create(TileSet, SIZE_X, SIZE_Y);
```

TileSet should be an enum like the following:

```zig
const TileSet = enum {
    ocean,
    water,
    beach,
    grass,
    forest,
};
```

In this example, neighboring tiles in the enum will be placed next to eachother.

eg. beach tiles will only be placed next to grass and water tiles.

To initilize the board, you could do something like:

```zig
var board: [SIZE_Y][SIZE_X]WFC.Tile = [_][SIZE_X]WFC.Tile{
    ([_]WFC.Tile{WFC.Tile{
        .uncollapsed = std.math.maxInt(WFC.Tile.T),
    }} ** SIZE_X),
} ** SIZE_Y;
```

Then, to compute the board, run:

```zig
var seed: u64 = undefined;
std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
var prng = std.rand.DefaultPrng.init(seed);
const rand = prng.random();

wfc.computeWFC(&board, rand);
```

Now, you have a board full of unions with the .collapsed set to the value from TileSet.

Hope you enjoy :)
