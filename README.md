Make minicomputer (HITAC10) with FPGA

<Tape reader function>
1. This unit has a tape reader function attached to the HITAC10 main unit.
2. The tape reader function operates in response to a request from the main unit.
3. The connection with the tape reader is simple (unique) connection.
4. OML and MASS are continuously stored in the memory (12KB) as tape data.

<Execution step>
1. Immediately after reset, this unit transfers the IPL to the core memory unit and executes the IPL from PC = 2.
2.IPL requests tape reader to read tape (OML).
3. The tape reader reads the tape data and sends it to the main unit.
4.When reading of OML is completed, reading of extension mechanism software is started.
5. When reading is completed, jump to PC = 0x20 and start reading MASS tape.
※ This part is a manual operation originally, a function not found in HITAC10.
後 6, After reading the first block of the MASS tape, jump to PC = 0x180.
7. Looping waiting for an interrupt from the tape reader.

See below for details
[[Celebration] HITAC10 50th anniversary] (https://qiita.com/hi631/items/7956a119cf96ed01b6d4)

<BR>

ＦＰＧＡでミニコン（ＨＩＴＡＣ１０）を作る

　<テープリーダー機能>
　1.本機はHITAC10本体に付随して、テープリーダー機能を有している。
　2.本体からの要求に応じて、テープリーダー機能が動作する。
　3.テープリーダーとの接続は簡易(独自)接続。
　4.テープデーターとして、メモリ(12KB)にOML,MASSを連続して格納している。

　<実行ステップ>
　1.本機はリセット直後、IPLをコアメモリ部に転送し、PC=2番地からIPLを実行する。
　2.IPLはテープリーダーに、テープ(OML)の読み込みを要求する。
　3.テープリーダーはテープデータを読み取り、本体に送出する。
　4.OMLの読み取りが完了すると、拡張機構ソフトの読み取りを始める。
　5.読み取りが完了すると、PC=0x20番地にジャンプし、MASSテープの読み取りを開始する。
　　※この部分は本来は手動操作であり、HITAC10には無い機能。
　6,MASSテープの先頭ブロックを読み取り後、PC=0x180にジャンプ。
　7.テープリーダよりの割り込み待ちでループしている。

詳しくは下記を参照
[［祝］ＨＩＴＡＣ１０ 生誕５０周年](https://qiita.com/hi631/items/7956a119cf96ed01b6d4)
