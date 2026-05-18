Delphiによる数独アプリ

対象OS　windows、Android



GitHub にはアイコン用のデータはアップしていないので、必要に応じてDelphiのプロジェクト―オプション―アイコンメニューでのアートワークジェネレータなどでアイコン用のデータを作成ください。



主要ファイル

MyMtrix.pas		:  配列処理のクラス

MyCNN.pas		:  画像から数字を認識する畳み込みニューラルネットワーク（CNN）

MyDLCommon.pas		:  CNN用のprocedure,function

MyWeightConst.pas	:  CNN用の学習済み定数

MyWeightInstance.pas	: CNN用の学習済み定数

Unit1.pas		:  数独のメインプログラム群

