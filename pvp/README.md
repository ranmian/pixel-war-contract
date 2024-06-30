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
--package 0x21d6f80250f95aea4dc40aadf085cf6023f54dd0d1b76249b344065db1fd47db \
--module manage \
--function start_game \
--args 0x66e8958be109331e3d8d72b93b0bd6dec854001b310d29715e0fed335739be86 0x9fda1f0f6adb692a4782ec1683c936a4820a801436d9f5c6671a8959e751c8b2 0x6 \
--gas-budget 10000000  
```