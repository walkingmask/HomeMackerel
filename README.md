# Home Mackerel with GPU-TensorFlow
自作 PC を組み立てて機械学習計算用自宅鯖 (サーバー) にする計画。なぜなら

- 自由に使い倒せる計算用の鯖が無性に欲しい
- PC自作は簡単ガンダム組み立てる並に余裕3時間くらいでできる
- スペック考えてパーツを調べたり選んだりに時間がかかる>数日
- それが楽しい
- 学生なら時間あるし余裕だし楽しい

から。このドキュメントは、自分の作業ログとして、また、同じようなことをしようとしている方の参考になればと思い作成しました。


## How to
主に利用するものとしては、NVIDIA グラフィックボード、Docker(nvidia-docker)、anaconda(Python3)、TensorFlow、DDNS となります。

1. パソコンを組み立ててる
1. Ubuntu インストール & 基本設定
1. ドライバ, Docker, nvidia-docker, anaconda, tensorflow をインストール
1. 外部から接続するためのセキュリティ設定
1. DDNS で外部から SSH 接続

あとは、ソースコードなどを鯖に上げて走らせるだけ。

ここからは、実際にどのように作っていくかをできるだけ細かく説明していくのですが、二度手間や必要のない情報も含まれます。Ubuntu 側の設定をつらつらっと書いたファイルを [walkingmask/HomeMackerel](https://github.com/walkingmask/HomeMackerel) に置いておきます。説明をすっ飛ばしてこのファイルを参考に自分で進めても良いと思います。


## パソコンを組み立てる
自作 PC を作っていきます。この辺は個人の好みがとても強く出ると思うので、参考になりそうなことを適当に書いておきます。

### 参考構成
今回使用した PC の構成を書いておきます。4 年くらい前の構成です。

- マザーボード : [H61M-HVS](http://www.asrock.com/mb/intel/H61M-HVS/index.jp.asp?cat=Specifications)
- 電源 : [KRPW-L4-400W](http://www.kuroutoshikou.com/product/power/atx/krpw-l4-400w/)
- CPU : [Celeron G550](http://ark.intel.com/products/53418/Intel-Celeron-Processor-G550-2M-Cache-2_60-GHz)
- メモリ : [W3U1600HQ-4G](http://www.cfd.co.jp/product/memory/desk-ddr3/w3u1600hq/)
- ストレージ : [HTS543225A7A384](http://www.tsukuba-data.com/hdd/HGST/hdd-HGST-HTS543225A7A384.php)
- ケース : [GMC B-4 Ver2](http://www.pasocomclub.co.jp/htmls/1100000146445-1.html)
- グラフィックボード : [N730K-1GD5LP/OCV1](http://www.ask-corp.jp/products/msi/graphicsboard/geforce-gt730/n730k-1gd5lpocv1.html)

最初は低価格でとりあえず組めればいいと思い、マザボCPUメモリディスプレイケースだけを買ってHDD周辺機器はあり合わせを使ったので、当時 3 万円くらいで作ったと思います。その後、この計画を思いついてグラボを追加したのですが、それを含め小規模構成です。しかし、それでも MacBookPro などのノートに比べると GPU のおかげでより早い学習が可能になると思うので作る価値はあるかなと思います。また、今回の作業中に良いパーツを手に入れることができたので、一部変更になっています。

- 電源 : [KRPW-PT500W/92+ REV2.0](http://www.kuroutoshikou.com/product/power/atx/krpw-pt500w_92_rev2_0/)
- ストレージ : [THNSNJ128GCSU](http://www.pasocomclub.co.jp/htmls/1100000217985.html)
- ドライブ : [GH24NSD1](http://kakaku.com/item/K0000848066/)

### HowTo 本を手に入れる
上記の PC パーツ構成はほんの一例で、しかも古く手に入りにくいと思うので、新たに構成を考えることになると思います。

また、組み立てることも考えると、簡単なものでいいので PC 自作関連書籍 or 雑誌を手に入れて、組み立ての概要をつかむといいでしょう。

### 規格を合わせる
パーツ選びで重要なのは規格を合わせることだと思います。例えばマザーボードのメモリスロット、CPUソケットなどの規格が合うように気をつけましょう。

その辺についても入門本や Web ページを参照するといいかと思います。

- [メモリーの規格](http://www.iodata.jp/product/memory/info/base/kikaku.htm)
- [CPUソケット](http://www.pc-master.jp/jisaku/cpu-socket.html)

また、Ubuntu を OS としてインストールする場合で、無線 LAN の利用を想定している場合は、無線LAN子機の相性を先に確認しておくといいでしょう。

- [LinuxのUSB無線LAN子機の対応状況](http://qiita.com/yukoba/items/d36930f4b8149ca36d36)

### 電源供給の計算
PC を組む時に気にしないといけないことの1つに電源容量がどれくらいあればいいかということがあります。次のようなページで計算しておくと楽かと思います。

- [Power Supply Calculator](http://powersupplycalculator.net/)

### 組み上げる
パーツを壊さないように組み上げていきます。静電気防止のためにゴム手袋などをつけるといいかもしれません。埃防止に全裸に風呂場でヤる人もいるみたいです。エアクリーナーがあると便利です。

##### 参考ページ
- [グラフィック性能を強化する](http://www.pc-master.jp/jisaku/graphicsboard-k.html)

### グラフィックボードのデュアルブート
**追記**: GPU を計算リソース専用に使うために、オンボードのグラボをディスプレイ用にするためにデュアルブート設定をしたかったのですが、dmesgにエラーが出ててどうやらうまくいってないようで、断念しました。

オンボード(CPUについている)とグラフィックボード(Nvidiaなど)のデュアルブートの BIOS 設定をやる方法を記しておきます。

通常、マザーボードの PCI スロット(グラボを刺すスロット)にグラボを刺すと、そちらが優先されてオンボードの方は使われなくてなってしまうようです。そこで設定が必要になります。

- [オンボード出力とグラフィックカード出力の同時利用（マルチディスプレイ）について](http://did2memo.net/2013/10/18/z87-pro-on-board-graphic-and-video-card-graphic/)

BIOS の設定手順が少し違いますが、ほぼ同じ感じでやります。私のマザボの場合は、

```
Advanced
-> North Bridge Configuration
-> IGPU Multi-Monitor
-> Enabled
```

これでデュアルブート設定

```
Primary Graphic Adapter -> Onboard
```

これでプライマリグラフィックボード(ディスプレイ接続用)が設定できました。


## Ubuntu と基本ソフトのインストール
Ubuntu と基本的なソフトウェアをインストールしていきたいと思います。

### Ubuntu Server
ささっと Ubuntu Server をインストールします。適当に用意したインストールメディア（.iso の入った CD か USBメモリ）を PC に接続します。

iso ファイルについては [公式サイト](https://www.ubuntu.com/) からダウンロードしてきますが、サイズが大きいので uTorrent を使うことを推奨します。ダウンロードしたら適当なメディアに書き込みます。

インストールメディアを接続して PC の電源を入れるとインストーラが起動します。あとは

1. 言語を選択して "Install Ubuntu" ボタンをクリック
2. 次の Update や third-party などは好みに応じて選択
3. Installation type は特に問題がなければ "Erase disk and install Ubuntu" を選択
4. 地域を選択
5. ユーザ情報を入力

したらインストールが開始します。

### ネットワークの基本設定
IP 固定設定などを設定します。

```lshw -short -class network```

で、ネットワークインターフェースを確認します。enpXxx のようなものが有線 LAN の ID であるはずなので、これをメモしておいて `/etc/network/interfaces` を編集します。

```
sudo vim /etc/network/interfaces
cat /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

#
auto enp3s0
iface enp3s0 inet static
address 192.168.0.100/24
gateway 192.168.0.1
dns-nameservers 8.8.8.8 192.168.0.1
```

これでネットワークに繋がるはずです。適当に `curl` などで外部との疎通を確認してみてください。無線については今回は省略します。

#### 参考ページ
- [Ubuntu 14.04 Server - WiFi WPA2 Personal](http://askubuntu.com/questions/464507/ubuntu-14-04-server-wifi-wpa2-personal)
- [ubuntu server 16.04LTS をWifiにつなげる](http://dorapon2000.hatenablog.com/entry/2016/09/17/075920)

### SSH
外部から接続して操作しやすくするように SSH の設定をします。まずはインストール。

```
sudo apt install -y openssh-server
```

この時点で SSH 接続は可能になっていると思うので、`ip a` や `ifconfig` などで IP アドレスを調べて `ssh user@hostname` で、ノート PC などから接続しておくと後の作業が楽ちんです。

### Update
OS インストール後は、とりあえずこれ。

```
sudo apt -y update
sudo apt -y upgrade
```

### 基本ソフトのインストール
好みに応じて、使うであろうソフトをインストールします。

```
sudo apt -y install zsh vim git
```

zsh をデフォルトシェルにするには

```
chsh -s /usr/local/zsh
```

を実行します。初回実行時は 2 を選択して zshrc のテンプレートを作成しておくといいでしょう。

### apt の掃除
新しいパッケージをインストールした後はとりあえずやってます。

```
sudo apt -y autoremove
sudo apt -y autoclean
```


## TensorFlow 環境の構築
nvidia-driver、Docker、nvidia-docker、pyenv、annaconda、tensorflow を入れていきます。

ここがメインになるところですが、先人方の知恵と記録のおかげであっという間に終わります。

**しかし**、nvidia-docker にたどり着くまでに driver を入れたり消したり CUDA や cuDNN を入れたり tensorflow を入れたり消したりかなり苦労しました。特別な理由がない限り nvidia-docker を利用することを強くお勧めします (現時点で Windows 対応はしていないようです)。

### グラフィックボードの設定
まずは、グラボ用ドライバをインストールしていきます。`nvidia-378` の部分は `apt search nvidia-*` の結果次第で適当に変更してください。

```
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt -y update
sudo apt -y install nvidia-378
sudo apt -y install ubuntu-drivers-common
```

インストールが完了したら、再起動 (`sudo reboot now`) して、下記のコマンドでグラフィックボードとドライバが正常に動いているか確認します。

```nvidia-smi```

こんな感じで出力されていればうまくいっていると思います。

```
Mon Jan 23 00:36:47 2017       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 367.57                 Driver Version: 367.57                    |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  GeForce GT 730      Off  | 0000:01:00.0     N/A |                  N/A |
| 33%   35C    P8    N/A /  N/A |    146MiB /   979MiB |     N/A      Default |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID  Type  Process name                               Usage      |
|=============================================================================|
|    0                  Not Supported                                         |
+-----------------------------------------------------------------------------+
```

#### Note
ubuntu-drivers-common をインストールすると、スムーズにドライバが入るのですが、果たして必要なのか...。また、これを入れた後に、GUI が有効になってしまっていました。[Tips](#Tips) に　GUI と CUI の切り替え方法が書いてあるので、GUI の必要がなければ CUI に変更しておきましょう。

#### 参考ページ

- [Ubuntu 16.04 LTSにNVIDIA製ドライバーをインストールする3つの方法](http://gihyo.jp/admin/serial/01/ubuntu-recipe/0454)
- [Installing Nvidia and Firmware Driver on Ubuntu Server 16.04.](https://ubuntuforums.org/showthread.php?t=2348421)

### Docker のインストール
次は Docker を Ubuntu に入れます。[公式ページ](https://docs.docker.com/engine/installation/linux/ubuntu/) 通りに進めます。

```
sudo apt update
sudo apt -y install curl \
  linux-image-extra-$(uname -r) \
  linux-image-extra-virtual
sudo apt -y install apt-transport-https \
  ca-certificates
curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add -
apt-key fingerprint 58118E89F3A912897C070ADBF76221572C52609D
sudo add-apt-repository \
  "deb https://apt.dockerproject.org/repo/ \
  ubuntu-$(lsb_release -cs) \
  main"
sudo apt update
sudo apt -y install docker-engine
```

Docker は、次のコマンドで動作確認ができます。

```sudo docker run hello-world```

この時、イメージやコンテナが生成されると思うので、気になる方は Docker コマンドを調べて削除するといいでしょう。

#### 参考ページ
- [Dockerコマンドメモ](http://qiita.com/curseoff/items/a9e64ad01d673abb6866)

### nvidia-docker のインストール
こちらも [公式 GitHub](https://github.com/NVIDIA/nvidia-docker) のページに沿って進めます。

```
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.0/nvidia-docker_1.0.0-1_amd64.deb
sudo dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb
```

次のコマンドで動作確認をします。

```
sudo nvidia-docker run --rm nvidia/cuda nvidia-smi
```

先ほどの Nvidia ドライバのインストールの時と同じ結果が表示されれば OK です。

### tensorflow のインストール
nvidia-docker を利用して tensorflow を インストールした Docker イメージを作ります。cuDNN が必要なので、cuDNN 入りのイメージを走らせます。

```
sudo nvidia-docker run -it --name tensorflow nvidia/cuda:cudnn /bin/bash
```

次に Docker 上で pyenv を使って annaconda を入れます。

```
# Docker上で
apt-get update
apt-get install -y --no-install-recommends wget git
apt-get clean
git clone https://github.com/yyuu/pyenv.git ~/.pyenv
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
source ~/.bashrc
pyenv install -l | grep ana
# ここで最新のものをコピペ
pyenv install anaconda3-4.2.0
pyenv rehash
pyenv global anaconda3-4.2.0
echo 'export PATH="$PYENV_ROOT/versions/anaconda3-4.2.0/bin/:$PATH"' >> ~/.bashrc
source ~/.bashrc
conda update conda
```

あとは [tensorflow 公式ページ](https://www.tensorflow.org/get_started/os_setup#using_pip) に従って tensorflow をインストールするだけです。

```
# Docker 上で
export TF_BINARY_URL=https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-0.12.1-cp35-cp35m-linux_x86_64.whl
pip install --ignore-installed --upgrade $TF_BINARY_URL
```

**注意**: TensorFlow 1.0.0 がリリースされています。

- [Announcing TensorFlow 1.0](https://developers.googleblog.com/2017/02/announcing-tensorflow-10.html)

インストールがうまくいってるか確認しましょう。

```
# Docker 上で
python
# python 上で
import tensorflow as tf
sess = tf.Session()
hello = tf.constant('hello, tensorflow!')
print(sess.run(hello))
a = tf.constant(10)
b = tf.constant(32)
print(sess.run(a + b))
```

次のような出力があれば成功しているはずです。

```
I tensorflow/stream_executor/dso_loader.cc:128] successfully opened CUDA library libcublas.so locally
I tensorflow/stream_executor/dso_loader.cc:128] successfully opened CUDA library libcudnn.so locally
I tensorflow/stream_executor/dso_loader.cc:128] successfully opened CUDA library libcufft.so locally
I tensorflow/stream_executor/dso_loader.cc:128] successfully opened CUDA library libcuda.so.1 locally
I tensorflow/stream_executor/dso_loader.cc:128] successfully opened CUDA library libcurand.so locally
I tensorflow/stream_executor/cuda/cuda_gpu_executor.cc:937] successful NUMA node read from SysFS had negative value (-1), but there must be at least one NUMA node, so returning NUMA node zero
I tensorflow/core/common_runtime/gpu/gpu_device.cc:885] Found device 0 with properties: 
name: GeForce GT 730
major: 3 minor: 5 memoryClockRate (GHz) 1.006
pciBusID 0000:01:00.0
Total memory: 979.56MiB
Free memory: 921.12MiB
I tensorflow/core/common_runtime/gpu/gpu_device.cc:906] DMA: 0 
I tensorflow/core/common_runtime/gpu/gpu_device.cc:916] 0:   Y 
I tensorflow/core/common_runtime/gpu/gpu_device.cc:975] Creating TensorFlow device (/gpu:0) -> (device: 0, name: GeForce GT 730, pci bus id: 0000:01:00.0)
b'hello, tensorflow!'
42
```

これだけで終わりです。あの苦しい CUDA や cuDNN のインストール、ドライバとの戦いはなんだったんだって感じです。

MNIST のサンプルを使って他の環境と比較してみるといいかもしれません。

- [TensorFlow チュートリアルDeep MNIST for Expertsを試してみる](http://www.trifields.jp/try-tutorial-deep-mnist-for-experts-of-tensorflow-1842)


#### 参考ページ
- [AzureのNシリーズでChainer、Tensorflow、CNTK、DIGITSのGPU環境を作る](http://qiita.com/crampon231/items/81b906c1df877ed51d04)
- [データサイエンティストを目指す人のpython環境構築 2016](http://qiita.com/y__sama/items/5b62d31cb7e6ed50f02c)
- [NVIDIA Dockerで簡単にGPU対応のTensorFlow入りコンテナを作る方法](http://www.muo.jp/2016/05/nvidia-docker-tensorflow.html)


## セキュリティ設定
外部から SSH 接続できるようにするためには、まずセキュリティ設定をしておく必要があります。設定項目として、ユーザの切り分け、ファイアーウォール、アンチウィルスなどになります。主に [こちら](http://matakite.wpblog.jp/site-construction/home-server-security-set-up-no1/) を参考にさせていただきました。その後、DDNS を使って外部からグローバルドメインを利用して SSH 接続可能にします。

### ユーザの設定
まずはユーザを設定していきたいと思います。この辺は自由にやって OK。

ユーザをどうやって切り分けて行ったらいいかよくわからないので、よくわからないなりに 作業用、ssh 用の 2 つのユーザを Ubuntu 上に作ります。

作業用はインストール時に作ったユーザとして、それとは別に ssh 用を作ります。

```
# ssh ユーザの追加 パスワード設定後基本空エンター
adduser sshuser
```

ユーザ間のディレクトリの権限を変更します。

```
# root ユーザの umask 変更
sudo sed -i -e "s/^UMASK\(\t*\)022/UMASK\1027/g" /etc/login.defs
# 作業用ユーザのディレクトリを ssh ユーザから見えなくする
chmod 750 ~
```

気分で passprompt を変更しておきます。

```
# エディタを 3 の vim に変更
sudo update-alternatives --config editor
sudo visudo
# visudo 画面で次の行を追加
Defaults passprompt = "%u@%h PaSsWoRd: "
```

#### 参考ページ
- [ubuntuでユーザを追加する](http://qiita.com/shishamo_dev/items/79b971a4288ed8eea990)
- [Ubuntuは初期状態ではrootが使えない（パスワード未設定）ようになっている](http://linux40.hateblo.jp/entry/20070903/1188797994)
- [How to set system wide umask?](http://stackoverflow.com/questions/10220531/how-to-set-system-wide-umask)

### SSH のセキュリティ強化

SSH のセキィリティを強化しておきます。これはセキィリティ上ほぼ必須です。

まずは公開鍵でログインできるようにしましょう。

- [リモートホストへ公開鍵認証でログイン](http://walkingmask.hatenablog.com/entry/2015/11/13/144454)

何度も修正するのは面倒なので、環境が完全に出来上がるまではローカルの `.ssh/config` は設定は後回しにした方がいいかもしれません。以下は設定例。

```
# ローカルで
scp ~/.ssh/ssh_rsa.pub sshuser@192.168.0.100:~
# リモートの ssh 用ユーザのホームディレクトリで
mkdir ~/.ssh
chmod 700 ~/.ssh
cd ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
cat ~/ssh_rsa.pub >>authorized_keys
rm ~/ssh_rsa.pub
```

次に /etc/ssh/sshd_config の設定例です。数値は好みで。

```
sudo sed -i -e "s/Port 22/Port 56789/g" \
-e "s/LogLevel INFO/LogLevel VERBOSE/g" \
-e "/^LoginGraceTime/i MaxAuthTries 3" \
-e "s/LoginGraceTime 120/LoginGraceTime 30/g" \
-e "s/prohibit-password/no/g" \
-e "s/#PasswordAuthentication yes/PasswordAuthentication no/g" \
/etc/ssh/sshd_config
# ssh 接続を許可するユーザの限定
sudo sed -i -e '$ a AllowUsers sshuser' /etc/ssh/sshd_config
```

#### 参考ページ
- [SSHのログイン関連エラー表示。](http://takuya-1st.hatenablog.jp/entry/20090216/1234742056)
- [SSHのセキュリティ対策について](http://www.server-memo.net/server-setting/ssh/ssh-sec.html)
- [いますぐ実践! Linux システム管理 / Vol.102](http://www.usupi.org/sysad/102.html)

### UFW の設定
UFW は Uncomplicated Firewall のことで、Linux のファイアーウォールである iptables の複雑な設定を簡単に行うためのもののようです。簡単なだけに、国外からのパケットフィルタやポートスキャンを始めとした攻撃対策のような複雑な設定はできません。以下に設定の一例を挙げておきます。

```
sudo ufw default DENY
sudo ufw limit from 216.58.0.0/16 to any port 56789 proto tcp
sudo ufw limit from 192.168.0.0/24 to any port 56789 proto tcp
sudo ufw enable
```

この設定では、特定の IP アドレスから指定のポート (22 番ポートから変更した SSH ポート) へのパケットを制限付きで許可しています。

#### 参考ページ
- [Ubuntuでufwを設定する](http://exoself.hatenablog.com/entry/2013/04/24/170540)

### iptables の設定
iptables は Linux のファイアーウォールです。複雑は設定ですが、設定項目が多くて面白くもあり、Web 上のドキュメントも多いです。しかし、しっかり設定するとなると結構な労力を要するようです。

ここでは、参考になるページを紹介するにとどめたいと思います。以下の二つは特に、そのまま利用してもいいのではないでしょうか。

- [サイト構築　〜自宅サーバ公開に向けて　セキュリティ設定　その4〜 ポートに関する設定](http://matakite.wpblog.jp/site-construction/home-server-security-set-up-no4/)
- [俺史上最強のiptablesをさらす](http://qiita.com/suin/items/5c4e21fa284497782f71)

また、Ubuntu 16.04 では iptables の設定は PC を終了させると消えてしまうようなので、iptables-president などを導入するといいです。他にも 複数の IP アドレスをまとめてホワイトリストやブラックリストに登録できる ipset といったツールもあります。ただ、こちらも設定を永続化させるには工夫が必要なようです。登録の際はシェルスクリプトを書くと楽です。

#### 参考ページ
- [Ubuntuでiptablesの設定をiptables-persistentで永続化する](http://iwashi.co/2015/01/16/ubuntu-iptables-persistent)
- [海外IPからのサーバーに向けた攻撃を遮断 ipset+iptables](https://sys-guard.com/post-5275/)
- [SSH接続で特定国(中国、ロシア)からの接続をブロックする(ipsetを使って)(その２)](http://grace.hateblo.jp/entry/2016/01/02/102739)
- [再起動時にipsetをリストアさせる方法](http://marm.cocolog-nifty.com/jokanaan/2016/12/ipset-12fc.html)

### ClamAV の設定
CalmAV はオープンソースのアンチウィルスソフトです。念のため入れます。導入は次のページに従っていけば OK です。

- [Clam AntiVirus インストール](https://www.server-world.info/query?os=Ubuntu_16.04&p=clamav)

freshclam の更新が上手くいかない場合は

- [freshclam の更新がうまくいきません。](https://forums.ubuntulinux.jp/viewtopic.php?pid=112770)

定期実行のために次のページのスクリプトを参考に、virusscan といったような名前で実行権限をつけて /etc/cron.daily に置いておきます。

#### 参考ページ
- [サイト構築　〜自宅サーバ公開に向けて　セキュリティ設定　その6〜](http://matakite.wpblog.jp/site-construction/home-server-security-set-up-no6/)

### Rootkit Hunter の設定
rkhunter は様々な悪意のあるツールやファイルの改竄を検出してくれるソフトです。一応導入しておきます。導入は次のページに従っていけば OK です。

- [RKHunter : Rootkit 検出ツール](https://www.server-world.info/query?os=Ubuntu_16.04&p=rkhunter)

#### 参考ページ
- [How To Use RKHunter to Guard Against Rootkits on an Ubuntu VPS](https://www.digitalocean.com/community/tutorials/how-to-use-rkhunter-to-guard-against-rootkits-on-an-ubuntu-vps)
- [[Rkhunter-users] Warning: "has been replaced by a script"](https://sourceforge.net/p/rkhunter/mailman/message/31460254/)
- [[Rkhunter-users] Fwd: rkhunter warning message!!!](https://sourceforge.net/p/rkhunter/mailman/message/27295287/)

### mail の設定
上記のセキュリティ用のソフトで、mail を使ってアラートを送るというコードがいくつかあるのですが、そのために一応 mail コマンドを内部でのやり取りだけに使えるように設定をします。ただ、難しくない割に色々と必要なので、[setupall.sh](https://github.com/walkingmask/HomeMackerel/blob/master/settings/setupall.sh) を参照してもらって、ここでは参考にしたページを紹介するにとどめたいと思います。

#### 参考ページ
- [Ubuntuでメールサーバー構築](http://qiita.com/mizuki_takahashi/items/1b33e1f679359827c17d)
- [Postfix インストール/設定](https://www.server-world.info/query?os=Ubuntu_16.04&p=mail)
- [Dovecot インストール/設定](https://www.server-world.info/query?os=Ubuntu_16.04&p=mail&f=2)
- [mailコマンドの使い方](http://www.uetyi.com/server-const/command/entry-166.html)


## DDNS を使って外部 SSH 接続
外部から自宅鯖に接続するには、まず自宅のグローバル IP アドレスを知っていないといけません。しかし、固定 IP アドレスは結構な料金がかかりますし (学生にとってはつらみ) 、色々と手続きをしなければなりません。そこで、DDNS (Dynamic Domain Name System) というサービスを利用します。具体的には、グローバルドメインと自宅の IP アドレスを紐付け、自宅の IP が変わった時に鯖からその変更を DDNS に登録することで、グローバルドメインを通していつでも自宅鯖に接続できるようにします。

### 注意
この方法を利用するにあたって、以下の点が要求されます。

1. 世帯にグローバル IP アドレスがあること (アパートなど建物内の各部屋にプライベート IP が振られている場合は 2 へ)
2. ネットワーク管理者である、または、ネットワーク管理者に色々お願いできる
3. 常時起動可能な PC がある

1、3 は言わずもがなですが、2 は、グローバル IP 宛に届いたパケットをポートフォワーディングで鯖に送ってもらう必要があるため、ルータの設定をしなければなりません。

### DDNS の登録
今回は、"ieServer" という日本の DDNS サービスを利用させてもらいました。

- [ieServer](http://ieserver.net/)

登録は非常に簡単で、左サイドバーの「新規ユーザー登録」から、利用規約・注意事項をよく読んで、サービス (通常接続) に申し込みます。登録には、「ユーザ名 (サブドメイン名)」「ドメイン名」「メールアドレス」「パスワード」が必要になります。この「サブドメイン名」「ドメイン名」から、`ieserver_no_subdomain.dip.jp` のようなグローバルドメインを取得することができます。

ユーザ登録が完了したら、左サイドバーの「ログイン/IPアドレス登録」から、自宅の IP アドレスを登録します。ログインして、ドメイン名 `ieserver_no_subdomain.dip.jp` のIPアドレスを xxx.xx.x.xx に更新 をクリックすると、現在利用しているグローバル IP アドレスが、そのドメインに紐づけられます。ゆえに、この作業は自宅から行う必要があります。

### ルータのポートマッピング設定
DDNS の登録が済んだら、ルータのポートマッピングの設定をします。ここでは、例として我が家のルータの設定を紹介しておきます。ルータの型は

- [Aterm BL900HW](http://www.aterm.jp/kddi/900hw/)

です。まず、マッピングするプライベート IP が固定されていないと困るので、「DHCP固定割当設定」から、鯖で利用している NIC の MAC アドレスをメモってきて、[ネットワークの基本設定](#ネットワークの基本設定) で設定した IP アドレスと共に登録します。

次に、「ポートマッピング設定」から、「LAN 側ホスト」に固定 IP アドレス、プロトコルに TCP、ポート番号を SSH で設定したポートにして設定を追加します。

これで、ルータ側の設定はできたと思うので、

```ssh sshuser@ieserver_no_subdomain.dip.jp -i ~/.ssh/ssh_rsa.pub```

といった具合で SSH して、接続できれば成功です。この時、接続できない場合もあると思いますが、頑張って解決してください！

#### ヒント
- アドレスの設定がどこか間違っている・タイポ (~/.ssh/config, /etc/ssh/sshd_config, ufw, DDNS, ルータなど)
- プライベートアドレス内からグローバルドメイン宛に SSH すると断られることがある (vpn やテザリングを利用するといいかも)
- ufw で許可していないアドレスからの接続 (自宅の IP は可変なので登録してないはず)

### DDNS の自動アップデートスクリプトの設定
これで、どこからでも接続できるようになったとは思うのですが、それは一時的です。継続的に接続できるようにするには、自宅のグローバル IP アドレスが変更された時に DDNS を更新してくれるような機構が必要になります。ここでは、例として、今作成した鯖を常時起動するものとして cron にアップデートスクリプトを登録し、自動で更新してくれるようにしたいと思います。

と言ってもスクリプトは公式で配布されているので、それを利用すれば早いです。

- [ddns-update.pl](http://ieserver.net/ddns-update.txt)

私は、慣れたシェルスクリプトに変更して実行権限を与えて cron に登録しました。詳しくは []() を見てみてください。

ここまで設定できれば、DDNS で外部から SSH 接続して、Docker の上に乗った TensorFlow を利用し、GPU を用いた学習スクリプトを回すことができるはずです！


## jupyter の利用と Docker のセキュリティ
DDNS の設定までが、鯖を作り始めてからの目標だったのですが、色々と欲が出てしまい、jupyter lab を利用してブラウザから TensorFlow および tensorboard を使う設定までしたので、それを少しだけ紹介したいと思います。

### jupyter lab とは

- [jupyterlab/jupyterlab](https://github.com/jupyterlab/jupyterlab)

ざっくり言うと、ブラウザから Python を色々できる jupyter notebook のパワーアップバージョンです。これを利用すると「いちいちターミナルを開かなくても、ブラウザから色々できちゃうじゃん！」と思い、導入してみました。

### 作業用ディレクトリを作っておく
jupyter lab をインストールする前に、実行するスクリプトなどを入れておく作業用ディレクトリを、SSH ユーザのホームディレクトリ上に作っておきます。jupyter lab は、指定されたディレクトリをルートとして実行されるので、作業用ディレクトリを指定しておくと何かと楽です。

```
mkdir /home/sshuser/Workspace
chmod 777 /home/sshuser/Workspace
```

共有するため、権限を変えてます。

### https のドメインを取っておく
jupyter lab を SSL を使って利用するために、ieServer で SSL・暗号化接続用のドメインを取得します。ieServer では、5つまでドメインを登録することができます。手順は先ほどとさほど変わらないのでサクッと取っちゃいます。

### ルータのポートマッピングに設定を追加
jupyter lab と tenosrboard で使用するポート用に 2 つ設定を追加しておきます。追加項目は、IP アドレスは先ほどと同じで、ポートを適当に設定しておきます。ここでは、例として jupyter lab 用に 56790、tensorboard 用に 56791 を設定しておきます。

### jupyter lab のインストール
インストールはとても簡単です。Docker 上にインストールするのですが、Anaconda がインストールしてあるので jupyter notebook はすでに使える状態です。これに少し加えるだけで良いです。

しかし、先ほど作成した Docker 上に、このままインストールしていっても、Docker のポートフォワードの設定をしていないので、ブラウザから jupyter lab や tensorboard にアクセスができません。また、作業用ディレクトリを共有したいので、手間ですがコンテナを作り直します。ただ、コンテナ内でもユーザの切り分けを行いたい (jupyter lab は、ブラウザ上からターミナルを操作できるため、root ユーザのまま設定してしまうと、ブラウザ上から特権ユーザとしてコンテナにアクセスできてしまう) ため、そのため Dockerfile を作りました。

- [Dockerfile](https://github.com/walkingmask/HomeMackerel/blob/master/settings/Dockerfile)

このファイルを使って... (DOCKERUSER は適当に変更してください)

(**注意**: 後で説明しますが、DDNS を設定した状態でこれを実行すると、世界中のブラウザからアクセスできてしまう可能性があります。心配な場合は、ルータのポートフォワーディングの設定を切っておくなどしておいてください。)

```
sudo nvidia-docker build -t DOCKERUSER:latest .
sudo nvidia-docker run \
-p 56790:8888 \
-p 56791:6006 \
-v /home/sshuser/Workspace:/home/DOCKERUSER/Workspace \
--name DOCKERUSER \
-u DOCKERUSER \
-d DOCKERUSER:latest /usr/local/bin/jl
```

とやると、これだけで設定できているはずです。ブラウザを開いて `https://192.168.0.100:56790` といった登録してある固定 IP アドレスにアクセスできれば成功です。この時、SSL 証明書がオレオレ証明書なため警告が出ると思いますが、自分の鯖に自分で作った証明書なので気にせず ADVANCED から Proceed しちゃってください。

また、TensorFlow が正しく動いているかも確認してみてください。特に、tensorboard を利用できるようなサンプルを動かして、jupyter lab 上からターミナルを起動し、tensorboard を動かして `http://192.168.0.100:56791` から見れれば大成功です。

### Docker のポートフォワーディング設定時のセキュリティ
Docker でポートフォワーディングの設定をすると、どうやら UFW をすり抜けてしまうようです。そうすると、すべての IP アドレスからブラウザで jupyter lab にアクセスできてしまいます。これはさすがにまずい気がします。

- [The dangers of UFW + Docker](http://blog.viktorpetersson.com/post/101707677489/the-dangers-of-ufw-docker)

そのため、上記の記事に書かれた解決法などがあるようですが、いろいろとうまくいかなかったため、最もいい感じだったルータのパケットフィルタを設定して解決を図ることにしました。パケットフィルタの設定は、in パケットを指定の IP アドレスからの特定のポートへのみ通過させ、それ以外は全て捨てるといった 2 つの設定を追加しました。

- [IPパケットフィルタの概要](https://121ware.com/aterm/regist/qa/sanko/00052-3.html)

iptables を駆使するか Docker をもっと勉強すれば、もっとスマートなソリューションを得られるかもしれませんが、現時点では力不足ゆえに力技で解決してしまいました。

ここまで設定して、`https://ieserver_no_subdomain.dip.jp:56790` にアクセスできれば成功です。

## その他
書き洩らしたことなど。

### Docker の自動起動設定
鯖を起動した時に systemctld に Docker を自動起動してもらうようにします。

```
sudo sh -c 'cat << EOF > /etc/systemd/system/docker_autostart.service
[Unit]
Description=auto start of docker containers
After=docker.service
Requires=docker.service

[Service]
ExecStart=/bin/bash -c "/usr/bin/docker start DOCKERUSER"

[Install]
WantedBy=multi-user.target
EOF'
sudo systemctl enable docker_autostart.service
```

### docker コマンドと nvidia-docker コマンドの違い
ちょっと気をつけた方が良いポイント。

- [nvidia-dockerとdockerコマンドの違い](http://walkingmask.hatenablog.com/entry/2017/01/26/205433)

### Dockerfile を作る時に参考にした記事
初 Dockerfile でした。

- [Dockerfile リファレンス](http://docs.docker.jp/engine/reference/builder.html)
- [Dockerfile の書き方「私的」なベストプラクティス](http://inokara.hateblo.jp/entry/2013/12/28/121828)
- [jprjr/Dockerfile](https://gist.github.com/jprjr/7667947)

### openssl で オレオレ証明書を作るワンライナー

- [Generate self-signed certificate and key in one line](https://major.io/2007/08/02/generate-self-signed-certificate-and-key-in-one-line/)

### VirtualBox 上でテスト
いきなり本番環境で作ってもいいのですが、失敗すると一から再インストールしないといけない上に家でしか作業できないので、VirutalBox 上に Ubuntu 16.04 LTS Server を作って Docker を入れてほぼ同じ環境でテストしていました。ただし、もちろん GPU は使えません。Anaconda がサイズ大きいので、ストレージは 16GB にしていました。

### ipv6 を無効にする
今時 ipv6 を無効にするのはどうなのだろうとは思いますが。

```
sed -i -e "$ a net.ipv6.conf.all.disable_ipv6 = 1" /etc/sysctl.conf
sed -i -e "$ a net.ipv6.conf.default.disable_ipv6 = 1" /etc/sysctl.conf
sudo sysctl -p
```

#### 参考ページ
- [IPv6を無効にする方法(Ubuntu 9.10～16.04)](http://l-w-i.net/t/ubuntu/ipv6_001.txt)

### nmap でポートの状態を確認
ufw や ルータの設定ができているのか確認するために nmap を使って調べていました。netcat でもできたかもしれません。

```nmap -Pn -p 56789 ieserver_no_subdomain.dip.jp```

#### 参考ページ
- [nmapコマンドで覚えておきたい使い方11個](https://orebibou.com/2015/06/nmapコマンドで覚えておきたい使い方11個/)

### sshuser に docker コマンドを一部許可する
`docker start tensorflow` のようなコマンドは sshuser に許可してもいいと思うので、次のように設定しておきます。

```
sudo visudo
sshuser    ALL=(ALL) NOPASSWD: /usr/bin/docker ps -a
sshuser    ALL=(ALL) NOPASSWD: /usr/bin/docker start tensorflow
sshuser    ALL=(ALL) NOPASSWD: /usr/bin/docker restart tensorflow
sshuser    ALL=(ALL) NOPASSWD: /usr/bin/docker stop tensorflow
sshuser    ALL=(ALL) NOPASSWD: /usr/bin/docker logs -ft tensorflow
```

また、このような設定は別ファイルに保存することもできます。

- [Adding NOPASSWD in /etc/sudoers doesn't work](http://askubuntu.com/questions/504652/adding-nopasswd-in-etc-sudoers-doesnt-work)

### HDD をマウントする
バックアップ用に HDD を PC に増設した場合の設定です。まずは、デバイス名を調べてフォーマットし、マウントします。

- [HDDのフォーマット](http://yang.amp.i.kyoto-u.ac.jp/~yyama/Ubuntu/strage/hdd-format.html)
- [Linux ハードディスクをマウント（mount）する](http://kazmax.zpp.jp/linux_beginner/mount_hdd.html)

バックアップするには、簡単に cron に rsync してもらうようにしてます。

```
sudo sh -c 'cat << EOF >>/etc/cron.hourly/workspace-backup 
#!/bin/bash
set -eu
/usr/bin/rsync -a --delete /home/sshuser/Workspace/ /mnt/hdd1/backup/sshuser/Workspace
exit 0
EOF'
sudo chmod +x /etc/cron.hourly/tens-backup
sudo /etc/cron.hourly/workspace-backup
```

### Wake On LAN
DDNS の自動更新が必要なため、常時起動を余儀なくされたわけですが、この構成の PC をずっと起動しておくと電気代がそこそこかかってしまうと思います。そこで、リモートから鯖の電源管理をするべく Wake On LAN (WOL) の設定をしてみます。もちろん、DDNS の自動アップデートはされなくなってしまうので、本来なら Raspberry Pi のようなずっと消費電力の少ないパソコンに DDNS の更新をやってもらいたいところです。

**注意**: ハードウェア (マザーボード、NIC) 側が WOL に対応していないと、利用できません。

簡単に紹介すると、次の設定をすることで WOL できます。

- BIOS (or UEFEI)
  - "Boot From Onboard LAN" などの設定を Enable にする
  - "Deep Sleep" などを Disabled にする
  - "PCI Devices Power on" などを Enabled にする
- 鯖上で `sed -i '$ a up ethtool -s enpXXX wol g' /etc/network/interfaces`
- ルータに WOL を許可してもらう
- クライアント PC に WOL ツールをインストールする
  - Mac であれば `brew install wakeonlan`

あとは、クライアント PC で

`wakeonlan -i ieserver_no_subdomain.dip.jp 12:23:56:78:90:ab`

のように鯖の NIC の MAC アドレス宛にマジックパケットを送り、鯖が起動したら成功です。

#### 参考ページ
- [WakeOnLan](https://help.ubuntu.com/community/WakeOnLan)
- [WOL(Wake On LAN)でハマりそうなポイント](http://qiita.com/syui/items/7047654ca0e2bda80265)
- [Wake On LAN(WOL)について](https://u-and-i.jimdo.com/2012/11/30/wake-on-lan-wol-について/)
- [Wake Other Computers from Mac OSX](http://apple.stackexchange.com/questions/95246/wake-other-computers-from-mac-osx)

### Ubuntu の自動セキュリティアップデート
- [Ubuntuでsecurity updateのみ自動的に適用する](http://qiita.com/key/items/60c43e3f97828b219436)


## Tips

関係あることもないことも。

- dpkg -i *.deb がうまくいかない場合は .deb を " " で囲むといい
- 最近はsyatemdで定期実行がデフォルトだけどcron.serviceも生きている
  - [Where Crontab? Ubuntu 16.04](http://askubuntu.com/questions/825798/where-crontab-ubuntu-16-04/825807)
  - /etc/cron.* 以下のスクリプトはファイル名に "." が入ってはいけないかつ "~" で終わってはいけない
- 作業ログ(実行時間、実行コマンド、結果など)をとるにはscriptコマンドが有効
- CUI と GUI を切り替える方法
  - [UbuntuでCUI/GUIログインの切り替え方法](http://at284km.hatenablog.com/entry/2015/02/24/230239)
  - [UbuntuでCUIオンリーに切り替える](http://packpak.hatenablog.com/entry/2016/09/15/000144)
- CUI版のインストール
  - [Ubuntu16.04 LTSのインストールと初期設定](http://eco.senritu.net/ubuntu16-04-lts-server_install_and_settings/)
- Launcher の整理 (GUI)
	- [How to remove “Amazon”?](http://askubuntu.com/questions/450398/how-to-remove-amazon)
	- [How to uninstall LibreOffice?](http://askubuntu.com/questions/180403/how-to-uninstall-libreoffice)

```
sudo apt -y remove --purge libreoffice*
sudo apt -y remove --purge unity-webapps-common
sudo apt autoclean
sudo apt -y autoremove
```

- Wi-Fiの接続安定化
  - [WN-G300UAのドライバの話。rtl8192cu](https://hellolv1.wordpress.com/2016/08/15/wn-g300ua%E3%81%AE%E3%83%89%E3%83%A9%E3%82%A4%E3%83%90%E3%81%AE%E8%A9%B1%E3%80%82rtl8192cu/amp/)


## 参考ページ

- [Ubuntu 16.04 LTSをインストールした直後に行う設定 & インストールするソフト](http://sicklylife.at-ninja.jp/memo/ubuntu1604/settings.html)
- [SSHサーバーの設定](https://www.server-world.info/query?os=Ubuntu_16.04&p=ssh)
- [Ubuntu 16.04 初期設定メモ](http://smdn.jp/softwares/ubuntu/initialconfig_xenial_desktop/)
- [サイト構築　〜自宅サーバ公開に向けて　セキュリティ設定](http://matakite.wpblog.jp/site-construction/home-server-security-set-up-no1/)
- [そこそこセキュアなlinuxサーバーを作る](http://qiita.com/cocuh/items/e7c305ccffb6841d109c#1-sshguard-fail2ban%E3%82%92%E5%B0%8E%E5%85%A5%E3%81%99%E3%82%8B)
- [Portチェックテスト【外部からのPort開放確認】](http://www.cman.jp/network/support/port.html)
- [外部・内部ネットワークからのSSH接続](http://qiita.com/rintarou/items/bef523c7c8f11097e577)
- [TimeCapsuleと古いWindowsマシンとUbuntuで自宅サーバ構築してDDNSで公開するまでの手順](http://blog.livedoor.jp/memerelics/archives/1234004.html)
- [ダイナミックDNS(FreeDNS)](http://www.rx-93dff.net/dynamic_dns.php)
- [Ubuntu 16.04にTensorFlow(GPU)をインストール](http://yyasui.hatenablog.com/entry/2016/06/05/200819)
