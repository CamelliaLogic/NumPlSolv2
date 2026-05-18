unit Unit1;

interface

uses

{$IFDEF ANDROID}
   Androidapi.Helpers, Androidapi.JNI.JavaTypes,Androidapi.JNI.OS,
{$ENDIF}

  MtrixObj, MyWeightInstance, MyDLCommon, MyCNN, System.Permissions,
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,  FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls ,System.UIConsts, System.Math,
  FMX.Layouts, System.DateUtils, FMX.Media,System.Threading;

type

// Homography 用
  TPoint2D = record
    X, Y: Double;
  end;
  array2 = array of array of double;
  array1 = array of double;
  array8 = array[0..8] of double;
// Homography 用

//********
  ClrFail =
    record
      Cleard  : boolean ;
      Failded : boolean ;
    end;

//********
  TNumBt = class(TButton)
  private
    FBtNum: shortint;
  protected
    procedure Click; override;
  public
    property Num: ShortInt read FBtNum write FBtNum;
    constructor Create(AOwner: TComponent); override;
  end;

//********
  TNPCell = class(TRectangle)
  private
    Fii, Fjj : ShortInt ;
    SWT, SWB, SWL, SWR  : boolean ;
    Ferr     : boolean  ;
    ARect    : TRectF   ;
    AsRect   : array[1..9] of TRectF;
    ABrush   : TBrush   ;
  protected
    procedure Click; override;
  public
    property Err: boolean read FErr write FErr;
    property ii: ShortInt read Fii write Fii;
    property jj: ShortInt read Fjj write Fjj;
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Paint; override;
  published

  end;

//********
  TNumPlSolver2 = class(TForm)
    MainSlLayout: TScaledLayout;
    CameraSlLayout: TScaledLayout;
    CameraImage: TImage;
    CameraComponent1: TCameraComponent;
    btCameraOn: TButton;
    btCapture: TButton;
    btQuit: TButton;
    btSolve: TButton;
    btClrCheck: TButton;
    lbT1: TLabel;
    lbT2: TLabel;
    lbT3: TLabel;
    lbT4: TLabel;
    lbT5: TLabel;
    lbT6: TLabel;
    btReset: TButton;
    Label1: TLabel;
    ProgressBar1: TProgressBar;
    procedure btQuitClick(Sender: TObject);
    procedure btCameraOnClick(Sender: TObject);
    procedure btCaptureClick(Sender: TObject);
    procedure CameraComponent1SampleBufferReady(Sender: TObject;
      const ATime: TMediaTime);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure btSolveClick(Sender: TObject);
    procedure btResetClick(Sender: TObject);
    procedure btClrCheckClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    TestResult:  TMyMtrix;
    MyConvNet :  TMyConvNet;
    FInitialized: boolean  ;
//    procedure RequestCameraPermission;
    procedure SobelFilter(YorT: integer; var SrcBitMap, DstBitMap: TBitmap);
    procedure TRtoLattice;
    Procedure SortTheat;
    procedure Shaeishori2;
    procedure changeTo2DDataArray(var BMap: TBitMap);
    function  HoughLine(TorY : integer ): integer;
    function  TateHough(var BMap: TBitMap): integer;
    function  YokoHough(var BMap: TBitMap): integer;
    procedure ImageSplit2;
    function  Yomitori2(var BMap: TMyMtrix): shortint ;
    procedure Reset;
    procedure ReInput;
    procedure CreateCells;
    procedure CreateNumBts;
    procedure CreateMtrix;
  public
    { public 宣言 }
  end;

//********

  procedure RowColCheck( i,j,k :ShortInt);
  function  SomeOneTurnOut(var wFailed:boolean): boolean;
  function  SomeOneSolved (var wFailed:boolean): boolean;
  function  SomeRowSolved                      : boolean;
  function  SomeClmSolved                      : boolean;
  function  SomeAreaSolved                     : boolean;
  function  ClearCheck: ClrFail;
  function  Search( ci, cj : ShortInt ): ClrFail;
  function  ErrCheck: boolean ;
  function  ErrReCheck: boolean;
  function  DoPreCheck                         : boolean;
  procedure Reset1;



var
  NumPlSolver2: TNumPlSolver2;

implementation

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}

const
// NPCell 用
  x0 = 10+2 ;  y0 = 50 ; xw = 40 ; yw = 40 ; xd = 12 ; yd = 12 ;
// Sobel フィルター用定数
    SobelA : array[0..2, 0..2] of integer = ((-1, 0, 1),
                                             (-2, 0, 2),
                                             (-1, 0, 1));
    SobelB : array[0..2, 0..2] of integer = (( 1, 2, 1),
                                             ( 0, 0, 0),
                                             (-1,-2,-1));
    ShikiiChi = 0.75 ;

// Hough Line 用
  RMAX = 60;
  THETA_MAX = 200;
  PIK  = PI / THETA_MAX;
  XMAX = 720;
  YMAX = 720;
  RHO_MAX = round(720*1.42);
  IWIDTH = XMAX;
  IHEIGHT = YMAX;
  RBAND = 5;
  cTate = 0;   // Hough Line 縦指定
  cYoko = 1;   // Hough Line 横指定
// Hough Line 用

  wrapsize = 28;


var
// NPCell 用
  NC : array[1..9] of string = ('1','2','3','4','5','6','7','8','9');
  NPCells: array[1..9,1..9] of  TNPCell;
  NumBts : array[0..9]      of  TNumBt;
  NPCellClickEnable : boolean ;
  SomeOneFocused : boolean ;
  iFocusX        : shortint;
  iFocusY        : shortint;

  GivenNum : array[1..9,1..9] of ShortInt ;
  FSolved  : array[1..9,1..9] of boolean  ;
  FPossib  : array[1..9,1..9,1..9] of boolean ;
  FGivens  : array[1..9,1..9] of boolean  ;

  GivenNum0: array[1..9,1..9] of ShortInt ;
  FSolved0 : array[1..9,1..9] of boolean  ;
  FPossib0 : array[1..9,1..9,1..9] of boolean ;
  FGivens0 : array[1..9,1..9] of boolean  ;

  givenNumber : array[0..8,0..8] of shortint;

  SearchMode     : boolean ;
  Cleared        : boolean ;
  Failed         : boolean ;
  FPreCheck      : boolean ;

// Hough Line 用
  sn : array[0..THETA_MAX - 1] of double;
  cs : array[0..THETA_MAX - 1] of double;
  MNdata: array[0..YMAX - 1] of array[0..XMAX - 1] of byte;  // Hough変換用画像2値化データ
  counter : array[0..THETA_MAX - 1] of array[0..RHO_MAX + RHO_MAX -1] of integer;

  TheataR : array[0..1,0..9] of single;      // Hough Line 結果保持用
  RhoR    : array[0..1,0..9] of single;      // Hough Line 結果保持用
  TateC, TateD, YokoA, YokoB : array[0..9] of single;
  LatticeX: array[0..9,0..9] of single;      // 盤面格子点座標
  LatticeY: array[0..9,0..9] of single;      // 盤面格子点座標
  LatticeXH: array[0..9,0..9] of integer;    // 盤面格子点座標
  LatticeYH: array[0..9,0..9] of integer;    // 盤面格子点座標
  NumTheatT, NumTheatY : integer ;
// Hough Line 用

// Homography 用
    Src, Dst: array[0..3] of TPoint2D;
    A: array2 ;
    B, X: array1;
    H: array8;
// Homography 用

  Cells : array[1..9,1..9] of TMyMtrix;

  LapTime0 : TDateTime;
  LapTime1 : TDateTime;
  LapTime2 : TDateTime;
  LapTime3 : TDateTime;
  LapTime4 : TDateTime;
  LapTime5 : TDateTime;
  LapTime6_1 : TDateTime;
  LapTime6_2 : TDateTime;
  LapTime00  : TDateTime;
  LapTime99  : TDateTime;

procedure TNumPlSolver2.FormClose(Sender: TObject; var Action: TCloseAction);
  var i, j : shortint ;
begin
  for i := 9 downto 1 do
    for j := 9 downto 1 do
      begin
        Cells[i,j].Free;
      end;

  TestResult.Free;
  MyConvNet.Free;
  for i := 9 downto 1 do
    NumBts[i].Free;

  for i := 9 downto 1 do
    for j := 9 downto 1 do
      begin
        NPCells[i,j].Free;
      end;

end;

procedure TNumPlSolver2.FormCreate(Sender: TObject);
  var x, y : shortint ;
  var i, j, k : shortint;
      st      : string  ;
begin
  FInitialized:=false;
  CameraSlLayout.visible:=false;
  MainSLLayout.visible:=true;

  MyConvNet := nil;

  // ConvNetは非同期で初期化
  TTask.Run(procedure
  begin
    var Net := TMyConvNet.create;
    TThread.Synchronize(nil, procedure
    begin
      MyConvNet := Net;
    end);
  end);

  TestResult:=TMyMtrix.create;
  TestResult.setsize(1,1,10);

  for  x:=0 to 8 do
    for y:=0 to 8 do
      givenNumber[x,y]:=0;

  SomeOneFocused:=false;
  iFocusX       :=1;
  iFocusY       :=1;
  SearchMode    :=false;
  Cleared       :=false;
  Failed        :=false;
  btClrCheck.Visible:=false;
  btCameraOn.visible:=true;
  FPreCheck     := true;

end;

procedure TNumPlSolver2.FormShow(Sender: TObject);
begin
  if FInitialized then Exit;  // 2回目以降は何もしない
  FInitialized := True;

  TThread.ForceQueue(nil, procedure
  begin
    CreateCells;
    CreateNumBts;
    CreateMtrix;
    NPCellClickEnable:=true;
  end);
end;


procedure TNumPlSolver2.CreateCells;
  var i,j,k : integer ;
begin
  for i := 1 to 9 do
    begin
    for j := 1 to 9 do
       begin
         NPCells[i,j]:=TNPCell.create(MainSlLayout);
         NPCells[i,j].Parent:=MainSlLayout;
         NPCells[i,j].Fii:=i;
         NPCells[i,j].Fjj:=j;
         NPCells[i,j].Position.x:=x0+(i-1)*xw;
         NPCells[i,j].Position.Y:=y0+(j-1)*yw;
         if (i mod 3) = 1 then NPCells[i,j].SWL:=true;
         if (i mod 3) = 0 then NPCells[i,j].SWR:=true;
         if (j mod 3) = 1 then NPCells[i,j].SWT:=true;
         if (j mod 3) = 0 then NPCells[i,j].SWB:=true;
         FSolved[i,j]:=false;
         FGivens[i,j]:=false;
         GivenNum[i,j]:=0;
         GivenNumber[i-1,j-1]:=0;
         for k := 1 to 9 do
           FPossib[i,j,k]:=true;
       end;
      Application.ProcessMessages;
    end;
end;

procedure TNumPlSolver2.CreateNumBts;
  var i : integer ;
      st: string  ;
begin
  for i := 0 to 9 do
    begin
      NumBts[i]:=TNumBt.Create(MainSlLayout);
      NumBts[i].Parent:=MainSlLayout;
      NumBts[i].FBtNum:=i;
      NumBts[i].Position.x:=x0+10+35*(i);
      NumBts[i].Position.y:=420;
      str(i:1,st);
      NumBts[i].Text:=st;
      if i=0 then
      begin
        NumBts[0].Text:='C';
        NumBts[0].TextSettings.FontColor:=claRed;
      end;
    end;
end;

procedure TNumPlSolver2.CreateMtrix;
  var i,j: integer ;
begin
  for i := 1 to 9 do
    for j := 1 to 9 do
       begin
         Cells[i,j]:=TMyMtrix.create;
         Cells[i,j].setsize(1,wrapsize,wrapsize);
       end;
end;

// *********************************
// ***     Sobel フィルター      ***
// *********************************
procedure TNumPlSolver2.SobelFilter(YorT: integer;var SrcBitMap, DstBitMap: TBitmap);
  var i, j, wd, hi : integer ;
      h, w         : integer ;
      wk           : single  ;
      SrcData, DstData : TBitmapData;
      cl           : TAlphaColor;
      clrec        : TAlphaColorRec;
      R            : integer    ;
begin
  wd:=SrcBitMap.width;
  hi:=SrcBitMap.height;
  DstBitMap.width:=wd-2;
  DstBitMap.height:=hi-2;
  SrcBitMap.Map(TMapAccess.read, SrcData);
  DstBitMap.Map(TMapAccess.write, DstData);
  for i:=0 to hi-2 do
    for j:=0 to wd-2 do
    begin
      wk:=0;
      for h:=0 to 2 do
        for w:=0 to 2 do
        begin
          cl:=SrcData.GetPixel(j+w,i+h);
          R := TAlphaColorRec(Cl).R;
          if YorT=0 then wk:=wk+R*SobelA[h,w] else wk:=wk+R*SobelB[h,w];
        end;
        if wk>60 then wk:=255 else wk:=0;
        clrec.A:=255; clrec.R:=trunc(wk); clrec.G:=trunc(wk); clrec.B:=trunc(wk);
        cl:=TAlphaColor(clrec);
        DstData.setPixel(j,i, cl);
    end;

  DstBitMap.Unmap(DstData);
  SrcBitMap.Unmap(SrcData);
end;
// *********************************
// ***     Sobel フィルター      ***
// *********************************

// ****************************************************************************************
//  ブランクセル判定　
// ****************************************************************************************
function IsBlankCell2(var Bitmap: TMyMtrix): Boolean;
var
  x, y, CountBlack, Total: Integer;
  C: TAlphaColor;
  Gray: Integer;
  Threshold: Integer;
  Ratio: Double;
  Result1: boolean ;
  mean: single;
  R   : single;
begin

  Threshold := 80;
  CountBlack := 0;
  Total := (WrapSize-8) * (WrapSize-8);
  mean:=0;
  for y := 1+4 to WrapSize -0-4 do
    for x := 1+4 to WrapSize -0-4 do
    begin
      Gray:=round(Bitmap.Elm2(x,y));
      mean:=mean+Gray;
      if Gray < Threshold then
        Inc(CountBlack);
    end;

  Ratio := CountBlack / Total;

  // 黒画素が 2% 未満なら空白と判定
  Result1 := Ratio < 0.02;
  IsBlankCell2:=result1;
  mean:=mean/Total;

  // 白黒反転 、正規化
  for x := 1 to WrapSize*WrapSize do
  begin
    R:=Bitmap.Mat[x-1];
    if R>(mean*0.7) then R:=255;
    Bitmap.Mat[x-1]:=(255-R)/255;
  end;
end;


// **************************************************************************
// ***    Homography 変換処理関連　                                       ***
// ***    Homography についてはChatGPT による支援                         ***
// **************************************************************************
procedure BuildHomographySystem( const Src, Dst: array of TPoint2D;
                               var A: array2 ; var  B: array1);
var
  i: Integer;
  x, y, u, v: Double;
begin
  SetLength(A, 8, 8);
  SetLength(B, 8);

  for i := 0 to 3 do
  begin
    x := Src[i].X;
    y := Src[i].Y;
    u := Dst[i].X;
    v := Dst[i].Y;

    // 第 2i 行（u に関する式）
    A[2 * i][0] := x;
    A[2 * i][1] := y;
    A[2 * i][2] := 1;
    A[2 * i][3] := 0;
    A[2 * i][4] := 0;
    A[2 * i][5] := 0;
    A[2 * i][6] := -u * x;
    A[2 * i][7] := -u * y;
    B[2 * i] := u;

    // 第 2i+1 行（v に関する式）
    A[2 * i + 1][0] := 0;
    A[2 * i + 1][1] := 0;
    A[2 * i + 1][2] := 0;
    A[2 * i + 1][3] := x;
    A[2 * i + 1][4] := y;
    A[2 * i + 1][5] := 1;
    A[2 * i + 1][6] := -v * x;
    A[2 * i + 1][7] := -v * y;
    B[2 * i + 1] := v;
  end;
end;

function SolveLinearSystem_GaussJordan( var A: array2; var B: array1;
                                       var X: array1): Boolean;
const
  N = 8;
var
  i, j, k, maxRow: Integer;
  maxVal, factor, temp: Double;
begin
  Result := False;
  SetLength(X, N);

  for i := 0 to N - 1 do
  begin
    // ピボット選択：i列の最大絶対値を持つ行を探す
    maxRow := i;
    maxVal := Abs(A[i][i]);
    for k := i + 1 to N - 1 do
    begin
      if Abs(A[k][i]) > maxVal then
      begin
        maxVal := Abs(A[k][i]);
        maxRow := k;
      end;
    end;

    // ピボットがほぼゼロ → 解けない
    if maxVal < 1e-12 then
      Exit;

    // 行をスワップ
    if maxRow <> i then
    begin
      for j := 0 to N - 1 do
      begin
        temp := A[i][j];
        A[i][j] := A[maxRow][j];
        A[maxRow][j] := temp;
      end;
      temp := B[i];
      B[i] := B[maxRow];
      B[maxRow] := temp;
    end;

    // 対角要素を 1 に正規化
    factor := A[i][i];
    for j := 0 to N - 1 do
      A[i][j] := A[i][j] / factor;
    B[i] := B[i] / factor;

    // 他の行をゼロにする
    for k := 0 to N - 1 do
    begin
      if k = i then
        Continue;
      factor := A[k][i];
      for j := 0 to N - 1 do
        A[k][j] := A[k][j] - factor * A[i][j];
      B[k] := B[k] - factor * B[i];
    end;
  end;

  // 結果をコピー
  for i := 0 to N - 1 do
    X[i] := B[i];

  Result := True;
end;

procedure WarpAndSplit(var SrcBmp: TBitmap;  H: array8);
var
  invH: array8;
  u, v: Integer;
  ix, iy : shortint ;
  x, y, denom: Double;
  fx, fy: Integer;
  dx, dy: Double;
  c00, c01, c10, c11, cl1: TAlphaColor;
  clrec                  : TAlphaColorRec;
  r, g, b: byte;
  Srcdata : TBitmapData;
  Dstdata : TBitmapData;


  function InRange(v, max: Integer): Boolean;
  begin
    Result := (v >= 0) and (v < max);
  end;

  function GetPixelSafe(X, Y: Integer): TAlphaColor;
  begin
    if InRange(X, SrcBmp.Width) and InRange(Y, SrcBmp.Height) then
      GetPixelSafe := Srcdata.GetPixel(X, Y)
    else
      GetPixelSafe := TAlphaColors.Black;  // 範囲外は黒
  end;

  procedure InvertHomography(const HA: array8; out InvH: array8);
  var
    a, b, c, d, e, f, g, h, i: Double;
    det: Double;
  begin
    // H[0..8] を展開
    a := HA[0]; b := HA[1]; c := HA[2];
    d := HA[3]; e := HA[4]; f := HA[5];
    g := HA[6]; h := HA[7]; i := HA[8];

    // 行列式
    det := a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
    if Abs(det) < 1e-12 then Exit;

    // 逆行列の計算
    InvH[0] := (e * i - f * h) / det;
    InvH[1] := (c * h - b * i) / det;
    InvH[2] := (b * f - c * e) / det;
    InvH[3] := (f * g - d * i) / det;
    InvH[4] := (a * i - c * g) / det;
    InvH[5] := (c * d - a * f) / det;
    InvH[6] := (d * h - e * g) / det;
    InvH[7] := (b * g - a * h) / det;
    InvH[8] := (a * e - b * d) / det;
  end;

begin

  SrcBmp.Map(TMapAccess.read, Srcdata);

  InvertHomography(H, invH);

  for ix:=1 to 9 do
    for iy:= 1 to 9 do
    begin

      for v := 0 to WrapSize-1 do
        for u := 0 to WrapSize-1 do
        begin
      // 同次座標による逆変換
          denom := invH[6] * (u+round(LatticeXH[ix-1,iy-1]))
                 + invH[7] * (v+round(LatticeYH[ix-1,iy-1])) + invH[8];
          if Abs(denom) < 1e-12 then Continue;

          x := (invH[0] * (u+round(LatticeXH[ix-1,iy-1]))
             + invH[1] * (v+round(LatticeYH[ix-1,iy-1])) + invH[2]) / denom;
          y := (invH[3] * (u+round(LatticeXH[ix-1,iy-1]))
             + invH[4] * (v+round(LatticeYH[ix-1,iy-1])) + invH[5]) / denom;

      // 座標を整数＋小数部に分ける
          fx := Floor(x);
          fy := Floor(y);
          dx := x - fx;
          dy := y - fy;

      // 四隅ピクセル取得
          c00 := GetPixelSafe(fx, fy);
          c01 := GetPixelSafe(fx + 1, fy);
          c10 := GetPixelSafe(fx, fy + 1);
          c11 := GetPixelSafe(fx + 1, fy + 1);

      // 双線形補間
          r := round( (1 - dx) * (1 - dy) * TAlphaColorRec(c00).R +
               dx * (1 - dy) * TAlphaColorRec(c01).R +
               (1 - dx) * dy * TAlphaColorRec(c10).R +
               dx * dy * TAlphaColorRec(c11).R);

          Cells[ix,iy].Setvalue(1,v+1,u+1,r);
        end;
    end;
  SrcBmp.Unmap(Srcdata);

end;


procedure WarpImageWithHomography(var SrcBmp: TBitmap;  H: array8;
                                  var DestBmp: TBitmap; Size: Integer);
var
  invH: array8;
  u, v: Integer;
  x, y, denom: Double;
  fx, fy: Integer;
  dx, dy: Double;
  c00, c01, c10, c11, cl1: TAlphaColor;
  clrec                  : TAlphaColorRec;
  r, g, b: byte;
  Srcdata : TBitmapData;
  Dstdata : TBitmapData;

  function InRange(v, max: Integer): Boolean;
  begin
    Result := (v >= 0) and (v < max);
  end;

  function GetPixelSafe(X, Y: Integer): TAlphaColor;
  begin
    if InRange(X, SrcBmp.Width) and InRange(Y, SrcBmp.Height) then
      GetPixelSafe := Srcdata.GetPixel(X, Y)
    else
      GetPixelSafe := TAlphaColors.Black;  // 範囲外は黒
  end;

  procedure InvertHomography(const HA: array8; out InvH: array8);
  var
    a, b, c, d, e, f, g, h, i: Double;
    det: Double;
  begin
    // H[0..8] を展開
    a := HA[0]; b := HA[1]; c := HA[2];
    d := HA[3]; e := HA[4]; f := HA[5];
    g := HA[6]; h := HA[7]; i := HA[8];

    // 行列式
    det := a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
    if Abs(det) < 1e-12 then Exit;

    // 逆行列の計算
    InvH[0] := (e * i - f * h) / det;
    InvH[1] := (c * h - b * i) / det;
    InvH[2] := (b * f - c * e) / det;
    InvH[3] := (f * g - d * i) / det;
    InvH[4] := (a * i - c * g) / det;
    InvH[5] := (c * d - a * f) / det;
    InvH[6] := (d * h - e * g) / det;
    InvH[7] := (b * g - a * h) / det;
    InvH[8] := (a * e - b * d) / det;
  end;

begin

  SrcBmp.Map(TMapAccess.read, Srcdata);

  DestBmp.SetSize(Size, Size);
  DestBmp.Map(TMapAccess.write, Dstdata);

  InvertHomography(H, invH);

  for v := 0 to Size - 1 do
    for u := 0 to Size - 1 do
    begin
      // 同次座標による逆変換
      denom := invH[6] * u + invH[7] * v + invH[8];
      if Abs(denom) < 1e-12 then Continue;

      x := (invH[0] * u + invH[1] * v + invH[2]) / denom;
      y := (invH[3] * u + invH[4] * v + invH[5]) / denom;

      // 座標を整数＋小数部に分ける
      fx := Floor(x);
      fy := Floor(y);
      dx := x - fx;
      dy := y - fy;

      // 四隅ピクセル取得
      c00 := GetPixelSafe(fx, fy);
      c01 := GetPixelSafe(fx + 1, fy);
      c10 := GetPixelSafe(fx, fy + 1);
      c11 := GetPixelSafe(fx + 1, fy + 1);

      // 双線形補間
      r := round( (1 - dx) * (1 - dy) * TAlphaColorRec(c00).R +
           dx * (1 - dy) * TAlphaColorRec(c01).R +
           (1 - dx) * dy * TAlphaColorRec(c10).R +
           dx * dy * TAlphaColorRec(c11).R);

      g := round( (1 - dx) * (1 - dy) * TAlphaColorRec(c00).G +
           dx * (1 - dy) * TAlphaColorRec(c01).G +
           (1 - dx) * dy * TAlphaColorRec(c10).G +
           dx * dy * TAlphaColorRec(c11).G);

      b := round( (1 - dx) * (1 - dy) * TAlphaColorRec(c00).B +
           dx * (1 - dy) * TAlphaColorRec(c01).B +
           (1 - dx) * dy * TAlphaColorRec(c10).B +
           dx * dy * TAlphaColorRec(c11).B);

      clrec.A:=255; clrec.R:=r; clrec.G:=g; clrec.B:=b;
      cl1:=TAlphaColor(clrec);


      Dstdata.SetPixel(u, v, cl1)
    end;
  DestBmp.Unmap(Dstdata);
  SrcBmp.Unmap(Srcdata);

end;


procedure TNumPlSolver2.Shaeishori2;
  var
      ix, jy : shortint ;
      WarpedBmp, SrcBmpH: TBitMap  ;
begin
  SrcBmpH:=TBitMap.Create;
  SrcBmpH.assign(CameraImage.Bitmap);

  Src[0].x:=LatticeX[ 0 , 0 ]; Src[0].y:=LatticeY[ 0 , 0 ];  // 左上
  Src[1].x:=LatticeX[ 9 , 0 ]; Src[1].y:=LatticeY[ 9 , 0 ];  // 右上
  Src[2].x:=LatticeX[ 9 , 9 ]; Src[2].y:=LatticeY[ 9 , 9 ];  // 右下
  Src[3].x:=LatticeX[ 0 , 9 ]; Src[3].y:=LatticeY[ 0 , 9 ];  // 左下

  Dst[0].x:= 0               ; Dst[0].y:=  0;
  Dst[1].x:= wrapsize*9-1    ; Dst[1].y:=  0;
  Dst[2].x:= wrapsize*9-1    ; Dst[2].y:= wrapsize*9-1;
  Dst[3].x:= 0               ; Dst[3].y:= wrapsize*9-1;

  BuildHomographySystem(Src, Dst, A, B);
  if SolveLinearSystem_GaussJordan(A, B, X) then
  begin
    // H を完成させる（h22 = 1）
    H[0] := X[0]; H[1] := X[1]; H[2] := X[2];
    H[3] := X[3]; H[4] := X[4]; H[5] := X[5];
    H[6] := X[6]; H[7] := X[7]; H[8] := 1.0;

    for ix:=0 to 9 do
      for jy:=0 to 9 do
      begin
        LatticeXH[ix,jy]:=round((LatticeX[ix,jy]*H[0]+LatticeY[ix,jy]*H[1])+H[2]);
        LatticeYH[ix,jy]:=round((LatticeX[ix,jy]*H[3]+LatticeY[ix,jy]*H[4])+H[5]);
      end;

    WarpAndSplit(SrcBmpH,  H);
  end;

end;

// **************************************************************************
// ***     Homography 変換処理関連　                                      ***
// **************************************************************************

// **************************************************************************
// ***      Hough 変換処理関連　                                          ***
// ***  石立 喬さんの「Hough変換による画像からの直線や円の検出」            ***
// ***  https://codezine.jp/article/detail/153のJavaプログラムを          ***
// ***  Delphiにコンバート                                                ***
// **************************************************************************
procedure TNumPlSolver2.TRtoLattice;    // 格子点計算
  var i, j : shortint ;
begin
  for i:=0 to 9 do
  begin
    TateC[i]:=-tan(TheataR[0,i]);
    TateD[i]:=RhoR[0,i]/cos(TheataR[0,i]);
    YokoA[i]:=-1/tan(TheataR[1,i]);
    YokoB[i]:=RhoR[1,i]/sin(TheataR[1,i]);
  end;

  for i:=0 to 9 do
    for j:=0 to 9 do
    begin
      LatticeX[i,j]:=(YokoB[j]*TateC[i]+TateD[i])/(1-YokoA[j]*TateC[i]);
      LatticeY[i,j]:=(YokoA[j]*TateD[i]+Yokob[j])/(1-YokoA[j]*TateC[i]);
    end;
end;

Procedure TNumPlSolver2.SortTheat;
  var TY, i, j : shortint ;
      wk       : single  ;
begin
  for TY:= 0 to 1 do
  begin
    for i:=0 to 8 do
    begin
      for j:=8 downto i do
      begin
        if RhoR[TY,j+1]<RhoR[TY,j] then
        begin
          wk:=RhoR[TY,j]; RhoR[TY,j]:=RhoR[TY,j+1]; RhoR[TY,j+1]:=wk;
          wk:=TheataR[TY,j]; TheataR[TY,j]:=TheataR[TY,j+1]; TheataR[TY,j+1]:=wk;
        end;
      end;
    end;
  end;
end;

// ハフ変換用二次元データー生成  2値化
// 白を１とし、白以外は０とします。
procedure TNumPlSolver2.changeTo2DDataArray(var BMap: TBitMap);
var
  width:  integer;
  height: integer;
  r, g, b : byte;
  i, j, k: integer;
  Bdata : TBitmapData;
  cl0  : TAlphaColor;
begin
  width := BMap.Width;
  Height := BMap.Height;
  BMap.Map(TMapAccess.read, Bdata);

  for i := 0 to Height - 1 do
  begin
    for j := 0 to width - 1 do
    begin
      cl0:=BData.GetPixel(j,i);
      R := TAlphaColorRec(Cl0).R;
      if R<50 then MNdata[i, j] := 0
              else MNdata[i, j] := 1;
    end;
  end;
  BMap.Unmap(Bdata);
end;

function TNumPlSolver2.HoughLine(TorY : integer ): integer ;
var
  theta, rho  : integer;
  x, y: integer;
  centerX, centerY, distX, distY, radius: integer;
  end_flag : integer;  // 繰り返しを終了するフラグ
  count    : integer;  // 検出された直線の個数カウント
  counter_max : integer;
  theta_maxs : integer;
  rho_maxm   : integer;
  thetay: Integer;
  j, i  : Integer;
  counter1_max : integer;
  centerX_max : integer;
  centerY_max : integer;
  radius_max  : integer;
  k: Integer;
begin
  if TorY=0 then NumTheatT:=0 else NumTheatY:=0;
  for y :=0 to YMAX - 1 do
    begin
      for x := 0 to XMAX - 1 do
        begin
          if MNdata[y, x] = 1 then
            begin
              for theta := 0 to THETA_MAX - 1 do
                begin
                  rho := round(x * cs[theta] + y * sn[theta]);
                  inc(counter[theta, rho + RHO_MAX]);
                end;
            end;
        end;
    end;

  theta_maxs := 0;
  rho_maxm := - RHO_MAX;
  end_flag := 0;
  count := 0;
  // 長さがxxxピクセル以下か、直線が10本になるまで検出
  while (end_flag = 0) and (count < 10) do
    begin
      inc(count);
      counter_max := 0;
      // counter が最大になるtheta_maxとrho_max を求める。
      for thetay := 0 to THETA_MAX - 1 do
      begin
        for rho := -RHO_MAX to RHO_MAX - 1 do
        begin
          if counter[thetay, rho + RHO_MAX] > counter_max then
          begin
            counter_max := counter[thetay, rho + RHO_MAX];
            // 150ピクセル以下の直線になれば検出終了
            if counter_max <= 150 then end_flag := 1
                                  else end_flag := 0;
            theta_maxs := thetay;
            rho_maxm := rho;
          end;
        end;
      end;
      if end_flag=0 then
        begin
          if count<=10 then
            begin
              if TorY=0 then TheataR[TorY,count-1]:=(theta_maxs-100)*PIK
                        else TheataR[TorY,count-1]:=(theta_maxs-100)*PIK+pi/2;
              RhoR   [TorY,count-1]:=rho_maxm;
              if TorY=0 then NumTheatT:=count-1 else NumTheatY:=count-1;
            end;
        end;
      // 検出した直線の描画
      // xを変化させてyを描く（垂直の線を除く）
      // yを変化させてxを描く(水平の線を除く)
      // 近傍の直線を消す
      for j := -10 to 10 do
        begin
          for i := -30 to 30 do
            begin
              if ((theta_maxs + i)>=0) and ((theta_maxs + i)<THETA_MAX) and
                 ((rho_maxm + J)  >=0) and ((rho_maxm + J)  <= RHO_MAX) then
                begin
                  counter[theta_maxs + i, rho_maxm + RHO_MAX + j] := 0;
                end;
            end;
      end;
    end;
  HoughLine:= count;
end;

function TNumPlSolver2.TateHough(var BMap: TBitMap): integer;
var
  i, x, y: integer;
begin
  // 三角テーブル作成　サイン コサイン 直線用
  for i := 0 to THETA_MAX - 1 do begin
    sn[i] := sin(PIK * (i-100));
    cs[i] := cos(PIK * (i-100));
  end;
  // 直線用カウンター配列クリア
  for i := 0 to THETA_MAX - 1 do
    for x := 0 to 2 * RHO_MAX -1 do begin
      counter[i, x] := 0;
    end;
  // ハフ変換
  changeTo2DDataArray(BMap);
  TateHough:=HoughLine(0);
end;

function TNumPlSolver2.YokoHough(var BMap: TBitMap): integer;
var
  i, x, y: integer;
begin
  // 三角テーブル作成　サイン コサイン 直線用
  for i := 0 to THETA_MAX - 1 do begin
    sn[i] := sin(PIK * (i-100)+PI/2);
    cs[i] := cos(PIK * (i-100)+PI/2);
  end;
  // 直線用カウンター配列クリア
  for i := 0 to THETA_MAX - 1 do
    for x := 0 to 2 * RHO_MAX -1 do begin
      counter[i, x] := 0;
    end;
  // ハフ変換
  changeTo2DDataArray(BMap);
  YokoHough:=HoughLine(1);
end;
//
// **************************************************************************
// ***    Hough 変換処理関連　                                            ***
// **************************************************************************

// **************************************************************************
// ***    盤面からマスを切り出す処理　                                    ***
// **************************************************************************
procedure TNumPlSolver2.ImageSplit2;
  var
      ix, jy : shortint ;
      CellWidth, CellHeight : integer ;
      SrcRect: TRect;
      wk       : boolean  ;
begin
   LapTime4:=now;

   for jy:=0 to 8 do
     begin
     for ix:=0 to 8 do
        begin

          CellWidth := WrapSize;
          CellHeight:= WrapSize;

         if IsBlankCell2(Cells[ix+1,jy+1]) then
           givenNumber[ix,jy]:=0
         else
           begin
             Laptime6_1:=now;
             givenNumber[ix,jy]:=yomitori2(Cells[ix+1,jy+1]);
             LapTime6_2:=now;
           end;

         if givenNumber[ix,jy]<>0 then
           begin
             FGivens[ix+1,jy+1]:=true;
             GivenNum[ix+1,jy+1]:=givenNumber[ix,jy];
             wk:=FPossib[ix+1,jy+1,GivenNum[ix+1,jy+1]];
             RowColCheck( ix+1, jy+1, givenNumber[ix,jy]);
             FPossib[ix+1,jy+1,GivenNum[ix+1,jy+1]]:=wk;
           end;

        end;
      progressbar1.Value:=37+jy*7;
      Application.ProcessMessages;
    end;

    LapTime5:=now;

    for ix:= 1 to 9 do
      for jy:= 1 to 9 do
      begin
        if FGivens[ix,jy] then
          if not FPossib[ix,jy,GivenNum[ix,jy]] then NPCells[ix,jy].Err:=True;
      end;
  invalidate;

  lbT1.text:='白 黒 化：'+FloatTostr(SecondOf(LapTime1-LapTime0)+MilliSecondOf(LapTime1-LapTime0)/1000)+' 秒';
  lbT2.text:='格子検出：'+FloatTostr(SecondOf(LapTime2-LapTime0)+MilliSecondOf(LapTime2-LapTime0)/1000)+' 秒';
  lbT3.text:='セル切出：'+FloatTostr(SecondOf(LapTime3-LapTime0)+MilliSecondOf(LapTime3-LapTime0)/1000)+' 秒';
  lbT4.text:='一字読取：'+FloatTostr(SecondOf(LapTime6_2-LapTime6_1)+MilliSecondOf(LapTime6_2-LapTime6_1)/1000)+' 秒';
  lbT5.text:='全数読取：'+FloatTostr(SecondOf(LapTime5-LapTime4)+MilliSecondOf(LapTime5-LapTime4)/1000)+' 秒';

end;


function  TNumPlSolver2.Yomitori2(var BMap: TMyMtrix): shortint ;
begin
   MyConvNet.Predict( BMap, TestResult);
   Yomitori2:=argmax(TestResult)-1;
end;


// **********************************************
// *****  TNumBt                            *****
// **********************************************
constructor TNumBt.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  size.Width:=25; size.height:=22;
       Width:=25;      height:=22;
end;

procedure TNumBt.Click;
  var kk   : shortint ;
      i, j : shortint ;
      wk, wk2   : boolean  ;
      wkFail : boolean;
begin
  NPCellClickEnable:=false;
  if SomeoneFocused then
  begin
    if FBtNum<>0 then
      begin
        wk2:=FGivens[iFocusX,iFocusy];
        FGivens[iFocusX,iFocusy]:=true;
        GivenNum[iFocusX,iFocusy]:=FBtNum;
        wk:=FPossib[iFocusX,iFocusy,FBtNum];
        RowColCheck(iFocusX,iFocusy,FBtNum);
        FPossib[iFocusX,iFocusy,FBtNum]:=wk;
        givenNumber[iFocusX-1,iFocusy-1]:=FBtNum;
        if wk2 then ErrReCheck;
      end
    else
      begin
        FGivens[iFocusX,iFocusy]:=false;
        GivenNum[iFocusX,iFocusy]:=0;
        givenNumber[iFocusX-1,iFocusy-1]:=0;
        ErrReCheck;
      end;

    for i:= 1 to 9 do
      for j:= 1 to 9 do
      begin
        if FGivens[i,j] then
          if not FPossib[i,j,GivenNum[i,j]] then NPCells[i,j].Err:=True;
      end;

    NumPlSolver2.Invalidate;
    SomeoneFocused:=false;

  end;
  NPCellClickEnable:=true;

end;

// **********************************************
// *****  TNumBt                            *****
// **********************************************

// **********************************************
// *****   NPCell                           *****
// **********************************************
constructor TNPCell.Create(AOwner: TComponent);
  var i, j : ShortInt ;
begin
  inherited Create(AOwner);
  ABrush:=TBrush.Create(TBrushKind.Solid,claRed);
  width:=xw;
  height:=yw;
  ARect:=RectF(2,2,xw-2, yw-2);
  for i := 1 to 3 do
    for j := 1 to 3 do
       begin
         AsRect[i+(j-1)*3]:=Rect((i-1)*xd+2,(j-1)*yd+2,i*xd+1,j*yd+1);
       end;
  visible:=true;
  SWT:=false; SWB:=false; SWL:=false; SWR:=false;
  Ferr:=false;
end;

destructor  TNPCell.Destroy;
begin
  ABrush.Free;
  inherited Destroy;
end;


procedure TNPCell.Click;
begin
  if not NPCellClickEnable then exit;

  NPCellClickEnable:=false;

  SomeoneFocused:=false;
  iFocusX:=Fii;
  iFocusY:=Fjj;

  NumPlSolver2.Invalidate;
  SomeoneFocused:=true;

  NPCellClickEnable:=true;;
end;

procedure TNPCell.Paint;
  var i : ShortInt ;
begin
  inherited Paint;
  if SWT then canvas.DrawLine(PointF(1,1),PointF(xw-1,1),1);         //top
  if SWB then canvas.DrawLine(PointF(2,yw-2),PointF(xw-1,yw-2),1);   //bottom
  if SWR then canvas.DrawLine(PointF(xw-2,2),PointF(xw-2,yw-1),1);   //right
  if SWL then canvas.DrawLine(PointF(1,1),PointF(1,yw-1),1);         //left
  if  FGivens[Fii,Fjj] then
  begin
    ABrush.Color:=claLightGreen;
    Canvas.FillRect( ARect, 1, ABrush);
    canvas.font.size:=(yd-3)*3;
    canvas.fill.color:=claBlue;
    canvas.FillText(ARect,NC[GivenNum[Fii,Fjj]],false,1,[],TTextAlign.Center, TTextAlign.Center) ;
  end;

  if  FGivens[Fii,Fjj] and Ferr then
  begin
    ABrush.Color:=claRed;
    Canvas.FillRect( ARect, 1, ABrush);
    canvas.font.size:=(yd-3)*3;
    canvas.fill.color:=claBlue;
    canvas.FillText(ARect,NC[GivenNum[Fii,Fjj]],false,1,[],TTextAlign.Center, TTextAlign.Center) ;
  end;

  if (not FGivens[Fii,Fjj]) and FSolved[Fii,Fjj] and ( not FPreCheck)then
  begin
    ABrush.Color:=claLightyellow;
    Canvas.FillRect( ARect, 1, ABrush);
    canvas.font.size:=(yd-3)*3;
    canvas.fill.color:=claBlue;
    canvas.FillText(ARect,NC[GivenNum[Fii,Fjj]],false,1,[],TTextAlign.Center, TTextAlign.Center) ;
  end;

  if SomeoneFocused and (iFocusX=Fii) and (iFocusY=Fjj) then   // if I have Focus
  begin
    ABrush.Color:=claPink;
    Canvas.FillRect( ARect, 1, ABrush);
    if  FGivens[Fii,Fjj]  then
    begin
      canvas.font.size:=(yd-3)*3;
      if Err then canvas.fill.color:=claRed
             else canvas.fill.color:=claBlue;
      canvas.FillText(ARect,NC[GivenNum[Fii,Fjj]],false,1,[],TTextAlign.Center, TTextAlign.Center) ;
    end;
  end;

  canvas.font.size:=(yd-3)*3;
  canvas.fill.color:=claBlue;
  stroke.color:=claBlue;
end;
// **********************************************
// *****   NPCell                           *****
// **********************************************


// **********************************************
// ****   関数群                            *****
// **********************************************
function  ClearCheck: ClrFail;   // 正解到達　or 失敗手順　判定
  var i , j  , k    : ShortInt ;
      clr, wk2, wk3 : boolean ;
      notfail       : boolean ;
begin
  clr:=true;
  notfail:=true;
  for i := 1 to 9 do
    for j := 1 to 9 do
      begin
        wk2:=FSolved[i,j];
        clr:=clr and wk2;
        if not wk2 then
        begin
          wk3:=false;
          for k := 1 to 9 do
            wk3:=wk3 or FPossib[i,j,k];
          notfail:=notfail and wk3;
        end;
      end;
  ClearCheck.Cleard:=clr;
  ClearCheck.Failded:=not notfail;
end;

function ErrReCheck: boolean;
// ルール違反の入力値が無いか再チェックし、違反があれば true を返す
  var i, j, k : shortint ;
      wk      : boolean ;
begin
  ErrReCheck:=false;
  for i := 1 to 9 do
    for j := 1 to 9 do
      for k := 1 to 9 do
      begin
        FPossib[i,j,k]:=true;
        NPCells[i,j].Err:=false;
      end;

  for i:= 1 to 9 do
    for j:= 1 to 9 do
    begin
      if GivenNum[i,j]<>0 then
      begin
        wk:=FPossib[i,j,GivenNum[i,j]];
        if not wk then
        begin
           NPCells[i,j].Err:=True;
           ErrReCheck:=true;
        end;
        RowColCheck( i,j,GivenNum[i,j]);
        FPossib[i,j,GivenNum[i,j]]:=wk;
      end;
    end;
end;

function  ErrCheck: boolean ;
// 列、行、1/9区画に同じ数字が2つ以上入力されていると true を返す
  var i , j : ShortInt ;
      ik, jk: ShortInt ;
      count : array[1..9] of boolean ;

  procedure ClrCount;
    var i: shortint;
  begin
    for i := 1 to 9 do count[i]:=false;
  end;

begin
  ErrCheck:=true;
  for j := 1 to 9 do
    begin
      ClrCount;
      for i := 1 to 9 do
        begin
          if count[GivenNum[i,j]] then exit;
          count[GivenNum[i,j]]:=true;
        end;
    end;

  for i := 1 to 9 do
    begin
      ClrCount;
      for j := 1 to 9 do
        begin
          if count[GivenNum[i,j]] then exit;
          count[GivenNum[i,j]]:=true;
        end;
    end;

  for ik := 1 to 3 do
    for jk := 1 to 3 do
      begin
        ClrCount;
        for i := ik*3-2 to ik*3 do
          for j := jk*3-2 to jk*3 do
          begin
            if count[GivenNum[i,j]] then exit;
            count[GivenNum[i,j]]:=true;
          end;
      end;
  ErrCheck:=False;
end;

procedure RowColCheck( i,j,k :ShortInt);
// セル(i,j) に 値 k を入力したことに対応して、
// 関連セルへの値 k　入力を不可能 FPossible[?,?,k]:=false とする
  var i1, j1 : ShortInt ;
      i2, j2 : ShortInt ;
begin
  for i1 := 1 to 9 do begin FPossib[i1,j,k]:=false end;
  for j1 := 1 to 9 do begin FPossib[i,j1,k]:=false end;

  case i of
    1..3 : i1:=1;
    4..6 : i1:=4;
    7..9 : i1:=7;
  end;

  case j of
    1..3 : j1:=1;
    4..6 : j1:=4;
    7..9 : j1:=7;
  end;

  for i2 := i1 to i1+2 do
    begin
      for j2 := j1 to j1+2 do
        begin
          FPossib[i2,j2,k]:=false;
        end;
    end;
end;

//*****
function  SomeOneSolved (var wFailed:boolean): boolean;
// いずれか一つのセルで解けていないのにおける数字が無い場合
//        SomeOneSolved:=false,  wFailed:=true; を返す
// いずれか一つのセルで、まだ解けていないが、入力可能な数が1つだけなら
//       そのセルについて GivenNum[i,j]:=kk;  FSolved[i,j]:=True; とし、
//       RowColCheck(i,j,kk); をコールして関連セルの消込を行って
//        SomeOneSolved:=true,  wFailed:=false; を返す

  var i, j, k, kk  : ShortInt ;
      icount       : ShortInt ;
begin
  wFailed:=false;
  SomeOneSolved:=false;
  for j := 1 to 9 do     // 9×9セルをチェック
  begin
    for i := 1 to 9 do
      begin
        icount:=0;
        for k := 1 to 9 do
          begin
            if FPossib[i,j,k] then
            begin
              inc(icount);
              kk:=k;
            end;
          end;

        if (not FSolved[i,j]) and ( icount=0) then  // 解けていないにおける数字が無い
        begin
          SomeOneSolved:=false;
          wFailed:=true;
          exit;
        end;

        if icount=1 then
        begin
          if not FSolved[i,j] then
          begin
            SomeOneSolved:=true;
            GivenNum[i,j]:=kk;
            FSolved[i,j]:=True;
            RowColCheck(i,j,kk);
            exit;
          end;
        end;
      end;
  end;

end;

function  SomeRowSolved: boolean;
  var i, j, k  : ShortInt ;
      count    : array[1..9] of ShortInt;
begin
  SomeRowSolved:=false;
  for j := 1 to 9 do
    begin
      for k := 1 to 9 do count[k]:=0;

      for i := 1 to 9 do
      begin
        for k := 1 to 9 do if FPossib[i,j,k] then inc(count[k]);
      end;

      for k := 1 to 9 do
        begin
          if count[k]=1 then
          begin
            for i := 1 to 9 do
               begin
                 if FPossib[i,j,k] then
                 begin
                   if not FSolved[i,j] then
                   begin
                     SomeRowSolved:=true;
                     GivenNum[i,j]:=k;
                     FSolved[i,j]:=True;
                     RowColCheck(i,j,k);
                     exit;
                   end;
                 end;
               end;
          end;
        end;
    end;

end;

function  SomeClmSolved: boolean;
  var i, j, k  : ShortInt ;
      count    : array[1..9] of ShortInt;
begin
  SomeClmSolved:=false;
  for i := 1 to 9 do
    begin
      for k := 1 to 9 do count[k]:=0;

      for j := 1 to 9 do
      begin
        for k := 1 to 9 do if FPossib[i,j,k] then inc(count[k]);
      end;

      for k := 1 to 9 do
        begin
          if count[k]=1 then
          begin
            for j := 1 to 9 do
               begin
                 if FPossib[i,j,k] then
                 begin
                   if not FSolved[i,j] then
                   begin
                     SomeClmSolved:=true;
                     GivenNum[i,j]:=k;
                     FSolved[i,j]:=True;
                     RowColCheck(i,j,k);
                     exit;
                   end;
                 end;
               end;
          end;
        end;
    end;

end;

function  SomeAreaSolved : boolean;
  var i, j, k  : ShortInt ;
      ii  , jj : ShortInt ;
      count    : array[1..9] of ShortInt;
begin
  SomeAreaSolved:=false;
    for ii := 0 to 2 do
      for jj := 0 to 2 do
        begin

          for k := 1 to 9 do count[k]:=0;

          for i := ii*3+1 to ii*3+3 do
            for j := jj*3+1 to jj*3+3 do
              for k := 1 to 9 do
                if FPossib[i,j,k] then inc(count[k]);

          for k := 1 to 9 do
            begin
              if count[k]=1 then
              begin
                for i := ii*3+1 to ii*3+3 do
                  for j := jj*3+1 to jj*3+3 do
                    begin
                      if FPossib[i,j,k] then
                      begin
                        if not FSolved[i,j] then
                        begin
                          SomeAreaSolved:=true;
                          GivenNum[i,j]:=k;
                          FSolved[i,j]:=True;
                          RowColCheck(i,j,k);
                          exit;
                        end;
                      end;
                   end;
              end;
            end;
        end;

end;

function  SomeOneTurnOut(var wFailed:boolean): boolean;
                                      //   SomeOneTurnOut ← True if 正解セルが見つかった
                                      //   wFailed        ← True if セルに置ける数字が無い
  var
      wkSomeoneSolv : boolean ;
      wkError       : boolean ;
      wkClr         : boolean ;
begin
  wFailed:=false;
  SomeOneTurnOut:=false;

  repeat                              // 9×9セルをチェック
    wkSomeoneSolv:=SomeOneSolved(wkError);
    if wkError then
    begin
      SomeOneTurnOut:=false;
      wFailed:=true;
      exit;
    end;
  until not wkSomeoneSolv;

  repeat
    wkClr:=SomerowSolved;
    if wkClr then SomeOneTurnOut:=true;
  until not wkClr;

  repeat
    wkClr:=SomeClmSolved;
    if wkClr then SomeOneTurnOut:=true;
  until not wkClr;

  repeat
    wkClr:=SomeAreaSolved;
    if wkClr then SomeOneTurnOut:=true;
  until not wkClr;

end;
// **********************************************
// ****   関数群                            *****
// **********************************************


// **********************************************
// *****   カメラデータチェック             *****
// **********************************************
function InputClick(ix, jy, nn : shortint): boolean;
//  セル(ix, jy) に、値 nn を入力可能であれば true を返す
  var kk   : shortint ;
      i, j : shortint ;
      wk   : boolean  ;
      wkFail : boolean;
begin
    InputClick:=false;
    if FPossib[ix,jy,nn] then
      begin
        InputClick:=true;
        FGivens[ix,jy]:=true;
        FSolved[ix,jy]:=True;
        GivenNum[ix,jy]:=nn;
        for kk := 1 to 9 do
        begin
          FPossib[ix,jy,kk]:=false;
        end;
      end
    else
      begin
        if FSolved[ix,jy] and (GivenNum[ix,jy]=nn) then InputClick:=true;
      end;

    repeat
      for i := 1 to 9 do
      begin
        for j := 1 to 9 do
         begin
           if FSolved[i,j] then RowColCheck(i,j,GivenNum[i,j]);
//                 セル[i,j] の値が決まれば、関連セルの入力可能数字を消す
         end;
      end;
      wk:=SomeOneTurnOut(wkFail);   //  セル[ix,iy] への入力に伴い、他の解けるセルを確認
    until wk=false;

end;
// **********************************************
// *****   カメラデータチェック             *****
// **********************************************


// **********************************************
// *****   解析ルーチン                     *****
// **********************************************
function  Search( ci, cj : ShortInt ): ClrFail;
  var i, j, k, kk :shortint;
      ii,   jj    :shortint;
      wk          :ClrFail ;
      wk0         :boolean ;
      res         :ClrFail ;
      wkNotFail   :boolean ;
      wkFailed    :boolean ;
  GivenNum1: array[1..9,1..9] of ShortInt ;
  FSolved1 : array[1..9,1..9] of boolean ;
  FPossib1 : array[1..9,1..9,1..9] of boolean ;
  FGivens1 : array[1..9,1..9] of boolean  ;

    procedure DataBackUp;
      var ip, jp, kp : shortint;
    begin
      for ip := 1 to 9 do
        for jp := 1 to 9 do
        begin
          GivenNum1[ip,jp]:=GivenNum[ip,jp];
          FSolved1[ip,jp]:=FSolved[ip,jp];
          FGivens1[ip,jp]:=FGivens[ip,jp];
          for kp := 1 to 9 do
            FPossib1[ip,jp,kp]:=FPossib[ip,jp,kp];
        end;
    end;

    procedure DataReStore;
      var ip, jp, kp : shortint;
    begin
      for ip := 1 to 9 do
        for jp := 1 to 9 do
        begin
          GivenNum[ip,jp]:=GivenNum1[ip,jp];
          FSolved[ip,jp]:=FSolved1[ip,jp];
          FGivens[ip,jp]:=FGivens1[ip,jp];
          for kp := 1 to 9 do
            FPossib[ip,jp,kp]:=FPossib1[ip,jp,kp];
        end;
    end;

begin

  res.Cleard :=false;
  res.Failded:=true;
  wkNotFail  :=false;

// 盤面データをローカル配列変数にコピー（バックアップ）
  DataBackUp;

  i:=ci; j:=cj;

  while FSolved[i,j] do    // 数値が決まっていないセルまで移動
  begin
    inc(i);
    if i>9 then
    begin
      if j=9 then
      begin
        wk.Cleard:=true;      // [9,9]セルまで値が決まっているのでクリア
        wk.Failded:=false;
        Search:=wk;
        exit;
      end;
      i:=1; inc(j);
    end;
  end;

    for k := 1 to 9 do
      begin
        if FPossib[i,j,k] then
        begin
          FSolved[i,j]:=True;      //選択可能な数値を試しに設定
          GivenNum[i,j]:=k;
          for kk := 1 to 9 do
            FPossib[i,j,kk]:=false;

          RowColCheck(i,j,k);
          wk0:=SomeOneTurnOut(wkFailed);

          while wk0 and (Not wkFailed) do
          begin
            for ii := 1 to 9 do
              for jj := 1 to 9 do
                begin
                  if FSolved[ii,jj] then
                  begin
                    RowColCheck(ii,jj,GivenNum[ii,jj]);
                  end;
                end;
            wk0:=SomeOneTurnOut(wkFailed);
          end;

          wk:=ClearCheck;
          if wk.Cleard then
            begin
              Search:=wk; exit;
            end
          else
            begin
              if not wk.Failded then
              begin
                wk:=Search(i,j);
                if wk.Cleard then
                  begin
                    if not wkFailed then begin Search:=wk; exit;end
                                    else wkNotFail:=wkNotFail or ( Not wkFailed)
                  end
                else
                  begin
                    wkNotFail  :=wkNotFail or ( Not wk.Failded);
                  end;
              end else  end;

            DataReStore;
        end;

      end;

      res.Cleard:=false;
      res.Failded:=not wkNotFail;
      Search:=res;

end;

function  DoPreCheck : boolean;
// セルへ入力値が問題無ければ true を返す
  var ix, iy : shortint;
      Error  : boolean;
begin
  Error:=false;
  for ix := 1 to 9 do
  begin
    for iy := 1 to 9 do
    begin
      if GivenNum[ix,iy]<>0 then
      begin
        if not InputClick(ix, iy, GivenNum[ix,iy]) then    // セル ix,iy に GivenNum[ix,iy] を入力不可なら
          begin
            NPCells[ix,iy].Err:=true;
            Error:=true;
          end;
      end;
    end;
  end;
  DoPreCheck:= not Error;

end;


// **********************************************
// *****   解析ルーチン                     *****
// **********************************************

// カメラ起動
procedure TNumPlSolver2.btCameraOnClick(Sender: TObject);
begin
{$IFDEF ANDROID}
  CameraComponent1.Quality := TVideoCaptureQuality.HighQuality;
{$ENDIF}
//  CameraComponent1.Quality := TVideoCaptureQuality.HighQuality;


  Reset;
  CameraComponent1.Active:=true; // カメラ起動
  CameraImage.visible:=true;
  CameraSlLayout.visible:=true;
  MainSlLayout.visible:=false;
end;


// **** 以下は、CharGPT によるコード
//procedure TNumPlSolver2.RequestCameraPermission;
//var
//  Permissions: TArray<string>;
//  Callback: TPermissionRequestResult;
//begin
//{$IFDEF ANDROID}
//  Permissions := [JStringToString(TJManifest_permission.JavaClass.CAMERA)];
//
//  Callback :=
//    procedure(const APermissions: TArray<string>; const AGrantResults: TArray<TPermissionStatus>)
//    begin
//      if (Length(AGrantResults) > 0) and (AGrantResults[0] = TPermissionStatus.Granted) then
//        ShowMessage('カメラ使用許可が得られました')
//      else
//        ShowMessage('カメラの使用が拒否されました');
//    end;
//
//  PermissionsService.RequestPermissions(Permissions, Callback);
//
//{$ENDIF}
//end;


//画像取り込みに関する処理
procedure TNumPlSolver2.btCaptureClick(Sender: TObject);
  var data : TBitmapData;
      w, h : integer    ;
      cl0  : TAlphaColor;
      cl1  : TAlphaColor;
      clrec: TAlphaColorRec;
      gray : byte       ;
      BitMap0: TBitMap  ;
      BitMap1: TBitMap  ;
      icT, icY : shortint;
begin
// カメラ停止
  CameraComponent1.Active:=false;
  progressbar1.Value:=0;
  progressbar1.Visible:=true;

   LapTime0:=now;
// モノクロ化処理
   CameraImage.Bitmap.Map(TMapAccess.readwrite, data);
  for w:=0 to data.width-1 do
    for h:= 0 to data.height-1 do
    begin
      cl0:=Data.GetPixel(w,h);
      gray:=Byte(Trunc(0.299*TAlphaColorRec(Cl0).R+0.587*TAlphaColorRec(Cl0).G
           +0.114*TAlphaColorRec(Cl0).B));
      clrec.A:=255; clrec.R:=Gray; clrec.G:=Gray; clrec.B:=Gray;
      cl1:=TAlphaColor(clrec);
      data.setPixel(w,h, cl1);
    end;
    CameraImage.BitMap.Unmap(data);

    progressbar1.Value:=10;
    Application.ProcessMessages;
    LapTime1:=now;

    BitMap0:=TBitmap.create;
    BitMap0.assign(CameraImage.BitMap);
    BitMap1:=TBitmap.create;

//  縦罫線検出処理を記述すること
    SobelFilter(0,BitMap0, BitMap1);
    icT:=TateHough(BitMap1);
//  横罫線検出処理を記述すること
    SobelFilter(1,BitMap0, BitMap1);
    icY:=YokoHough(BitMap1);

    BitMap1.Free;
    BitMap0.Free;

    progressbar1.Value:=20;
    Application.ProcessMessages;

    if (icT>=10) and (icY>=10) then
    begin
//  罫線の格子点を計算
      SortTheat;
      TRtoLattice;      // 格子点計算

      LapTime2:=now;

      Shaeishori2;
      progressbar1.Value:=30;
      Application.ProcessMessages;

      LapTime3:=now;

//  盤面からマスを切り出す処理
      ImageSplit2;
    end;
  CameraSlLayout.visible:=false;
  CameraImage.visible:=false;
  progressbar1.Visible:=false;
  MainSlLayout.visible:=true;

end;

procedure TNumPlSolver2.btClrCheckClick(Sender: TObject);
begin
    if ErrCheck then ShowMessage( 'not correct')
              else ShowMessage( 'correctly solved');
end;

procedure TNumPlSolver2.CameraComponent1SampleBufferReady(Sender: TObject;
  const ATime: TMediaTime);
begin
  TThread.Synchronize(nil,
    procedure
    var
      bmp1,bmp2:TBitmap;
      srcRect,dstRect:TRect;
      xl, xr, yt, yb : integer ;
    begin
      bmp1 := TBitmap.Create;
      bmp2 := TBitmap.Create;
      try
        CameraComponent1.SampleBufferToBitmap(bmp1, True);

        if bmp1.width<=720 then
          begin
            xl:=0; xr:=bmp1.width-1;
          end
        else
          begin
            xl:=(bmp1.width div 2) - 360;
            xr:=xl + 719;
          end;

        if bmp1.height<=720 then
          begin
            yt:=0; yb:=bmp1.height-1;
          end
        else
          begin
            yt:=(bmp1.height div 2) - 360;
            yb:=yt + 719;
          end;

        bmp2.Width := xr-xl;
        bmp2.Height := yb-yt;
        srcRect := Rect( xl, yt, xr, yb);
        dstRect := srcRect;
        bmp2.CopyFromBitmap( bmp1, SrcRect, 0, 0) ;
        CameraImage.Bitmap.Assign(bmp2);  // 画面に表示
      finally
        bmp2.Free;
        bmp1.free;
      end;
    end);
end;


procedure TNumPlSolver2.btQuitClick(Sender: TObject);
begin
  close;
end;


procedure TNumPlSolver2.btResetClick(Sender: TObject);
begin
  Reset;
end;

procedure TNumPlSolver2.Reset;
  var i,j,k : ShortInt ;
begin
  FPreCheck:= true;
  NPCellClickEnable:=false;
  for i := 1 to 9 do
    for j := 1 to 9 do
       begin
         GivenNum[i,j]:=0;
         givenNumber[i-1,j-1]:=0;

         FSolved[i,j]:=false;
         FGivens[i,j]:=false;
         NPCells[i,j].Err:=false;
         for k := 1 to 9 do
           FPossib[i,j,k]:=true;
       end;

  SearchMode    :=false;
  btSolve.TextSettings.FontColor:=claBlack;
  btSolve.Text:='Solve';
  btClrCheck.Visible:=false;
  btCameraOn.visible:=true;
  SomeoneFocused:=false;
  NPCellClickEnable:=true;

  NumPlSolver2.Invalidate;
  NPCellClickEnable:=true;
end;

procedure Reset1;
  var i,j,k : ShortInt ;
begin
  for i := 1 to 9 do
    begin
    for j := 1 to 9 do
       begin
         FSolved[i,j]:=false;
         FGivens[i,j]:=false;
         NPCells[i,j].Err:=false;
         GivenNum[i,j]:=givenNumber[i-1,j-1];
         if givenNumber[i-1,j-1]<>0 then
           FGivens[i,j]:=true;
         for k := 1 to 9 do
           begin
             FPossib[i,j,k]:=true;
           end;
       end;
    end;
end;

procedure TNumPlSolver2.ReInput;
  var ix, jy : shortint ;
      nn     : shortint ;
      wk   : boolean  ;
begin
  for ix:= 1 to 9 do
    for jy:= 1 to 9 do
    begin
      nn:=GivenNum[ix,jy];
      if nn<>0 then
      begin
        FGivens[ix,jy]:=true;
        wk:=FPossib[ix,jy,nn];
        RowColCheck( ix, jy, nn);
        FPossib[ix,jy,nn]:=wk;
      end;
   end;
end;

procedure TNumPlSolver2.btSolveClick(Sender: TObject);
  var i,j,k : ShortInt;
      result: ClrFail;
begin
  LapTime00:=now;
  Reset1;
  SomeOneFocused:=false;

  if not DoPreCheck then
  begin
    ShowMessage( 'Input Error occurred');
    Reset1;
    ReInput;
    exit;
  end;

  FPreCheck     := false;
  NPCellClickEnable:=false;
   { 解析コード }
  if SearchMode then
    begin
      SearchMode    :=false;
      btSolve.TextSettings.FontColor:=claBlack;
      btSolve.Text:='Solve';
    end
  else
    begin
      SearchMode    :=true;
      btSolve.TextSettings.FontColor:=claRed;
      btSolve.Text:='Solve';
      for i := 1 to 9 do
        for j := 1 to 9 do
          begin
            GivenNum0[i,j]:=GivenNum[i,j];
            FSolved0[i,j]:=FSolved[i,j];
            FGivens0[i,j]:=FGivens[i,j];
            for k := 1 to 9 do
              FPossib0[i,j,k]:=FPossib[i,j,k];
          end;

      result:=search(1,1);     // reault.cleared = true →　正解に到達
      if result.Cleard then
        begin
          if ErrCheck then ShowMessage( 'No Solution');

          SearchMode    :=false;
          btSolve.TextSettings.FontColor:=claBlack;
          btSolve.Text:='Solved';
          btClrCheck.Visible:=true;
          btCameraOn.visible:=false;
          LapTime99:=now;
          lbT6.text:='解答時間：'
             +FloatTostr(SecondOf(LapTime99-LapTime00)+MilliSecondOf(LapTime99-LapTime00)/1000)
             +' 秒';

           invalidate;
        end
      else
        begin
          ShowMessage( 'No Solution');
          SearchMode    :=false;
        end;

    end;

  NPCellClickEnable:=false;
end;

end.
