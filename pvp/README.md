# New Coin

- TreasuryCap
```
0x4accb814d256d0c19db86a8de23888c13738882c3837937c82d3b9aa19cbd8dd
```

- CoinMetadata
```
0xd099f08256aca8e47e8894da65f480557b06d20f8bce2f817d11f395cb9b75bd
```

- CoinType
```
0x16c394da207968fc70871b7a3fb65c2d69fb84a1e41f03618fefdaebc136d6da::batman::BATMAN
```

- SUI
```
0x04fc5b4babc68733fd37c061447c797698236ae5f0f3a910cfae94f63f502b20
```

# PVP Contract

- package
```
0xcca895e3b7e1327af2a55c95a07395398f21e54d71e3292601e2e6e499bae0b8
```

- UpgradeCap
```
0x22c9ab1710dd00468dd12bd8431f454ddf1709a6e738d2ca3a56ab2405988dc0
```

- AdminCap
```
0x968579a85ff469effa95b3de776ec3b25893f4dc5aa7e636e7c893e5f7b0c666
```

- PixelGlobal
```
0x108cfe0a8d5fade9032845db5332ba899388d5b07e95f55361be61d04b42089e
```

- Game
```
0xc0e75d011feeb66be54ca063abbdb516c0c0f12669df14df142b047efcea176f
```

### Listing Coin
```
sui client ptb \
--assign to_address @0x320980d4f22f19442c1e76b207634e0e60c0ec1aebf677340785f0fb60abd4c5 \
--split-coins gas [10000000000] \
--assign coin coin \
--move-call 0xcca895e3b7e1327af2a55c95a07395398f21e54d71e3292601e2e6e499bae0b8::pvp::pixel "<0x16c394da207968fc70871b7a3fb65c2d69fb84a1e41f03618fefdaebc136d6da::batman::BATMAN>" 0x108cfe0a8d5fade9032845db5332ba899388d5b07e95f55361be61d04b42089e 0x4accb814d256d0c19db86a8de23888c13738882c3837937c82d3b9aa19cbd8dd 0xd099f08256aca8e47e8894da65f480557b06d20f8bce2f817d11f395cb9b75bd coin 1 \
--assign coin1 coin1 \
--transfer-objects [coin1] to_address \
--gas-budget 150000000
```

### Start Game
```
sui client call \
--package 0x114504f5a6d442a89f18f5198ee3cd2c0b1d4faae5817f93525a6da930e1e0e8 \
--module manage \
--function start_game \
--args 0x602180f19c1fd6d94c8b4b449dbc9672e5aea8797a308f4f97232828e0130526 0x1c590389c798c388083aaf72e299bf979a74f6ff79a0674332a653ad34367890 0x6 \
--gas-budget 10000000  
```