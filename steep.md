# typeprof + steep 導入考察

## 現状

- typeprof の推論不足がかなりあるので、必要となる手作業が重め
  - 未完了
- 特に Hash 系のエラーが非常に多い
  - json から取得したデータ
    - しかたなし
    - 入力に false 突っ込まれるとまずい等の実装の指摘
  - 内部だけで管理するような、追っていけば証明可能だが、Hash 型としては証明不能なもの
    - `data['path']` など
    - `Struct` を使う
- リファクタリングが必要なため今の所 workflow には入れない

```
t1 = nil
t2 = nil
t1 = Thread.start do
  sleep 3
  t2.exit
  puts 't1'
end
t2 = Thread.start do
  sleep 5
  t1.exit
  puts 't2'
end
[t1,t2].each(&:join)
```

## 理想

- rb ファイルに型注釈を書きたくない
- typeprof で型情報をある程度自動生成してほしい

## SteepFile

- library は `Standard libraries` とコメントが書かれていたが、fileutils 等大半が使えない
  - json は利用可能
- 一部だけ指定しても中途半端なので、何も指定していない

## typeprof との相性

- 標準ライブラリ周りで UnknownMethodAliasError が出るので、今の所は参考程度に出力するだけ
- ベースは得られるので助けにはなる

## json ライクな Hash 構造の記述

```
type jhash = Hash[String, Integer | String | bool | nil | jhash]
```
