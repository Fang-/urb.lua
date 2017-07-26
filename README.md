# urb.lua

`urb.lua` attempts to make it easy to communicate with your Urbit in Lua, while also providing utility functions relating to Urbit as a whole.

...That said, none of the "communicate with your Urbit" functionality is currently implemented. This will be done once Urbit's HTTP API stabilizes a little bit.

## Functionality

```
--------------------------------------------------------------------------------
core -- urbit http communication
* Coming Soon™
--------------------------------------------------------------------------------
urb.nom -- ship names & numbers
* nume ( ship name )
    => address number
* nome ( address number )
    => ship name
* clan ( ship name or address number (int or bn) )
    => "galaxy", "star", "planet", "moon" or "comet"
* sein ( ship name or address number (int or bn) )
    => parent name or address number
```

## Usage

Just like `local urb = require("urb")`.

In `nom`, to support all 128 bits that can make up an Urbit address, `lib/bn` is used for numbers. If your address is larger than can be stored in a Lua integer, use `lib/bn` to pass in `bn("number")` instead. Returned numeric results are always `bn` tables.

## Contributing

PRs welcome!

## Dependencies

* [user-none/lua-nums](https://github.com/user-none/lua-nums) (just the bignum implementation)

## License

MIT License.
