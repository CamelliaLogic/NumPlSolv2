unit MyDLCommon;


interface

uses
  MtrixObj;


procedure sigmoid( var A, X :TMyMtrix);
//  X = sigmoid(A)
//  M : rows of X   , rows of A
//  N : columns of X, columns of A

procedure FStep( var A, X :TMyMtrix);
procedure FStep0( var X :TMyMtrix);

procedure ReLU( var A, X :TMyMtrix);
procedure ReLU0( var X :TMyMtrix);

procedure softmax( var A, X :TMyMtrix);

function  argmax( var A :TMyMtrix ): integer ;

procedure Affine( W , B : TMyMtrix;  var Ain, Xout : TMyMtrix);
// Affine レイヤー
// Ain : 入力配列データ
// W : 重みデータ配列,  B : バイアスデータ行列
// Xout : 出力配列

procedure DropOut( var A, X :TMyMtrix; ratio: single);
procedure DropOut0( var X :TMyMtrix; ratio: single);

procedure im2col(  FH, FW,  stride, pad : integer; var A, X :TMyMtrix );
//  M : 入力データ数（バッチサイズ）
//  InH, InW : 入力画像の縦、横のピクセル数
//  FH , DW  : フィルターの縦、横のピクセル数
//  OutH, OutW : フィルター適用後の縦、横のピクセル数
//  stride : フィルター移動のstride
//  pad    : パディングのピクセル数
//  A : 入力データの配列
//  X : 出力の配列

procedure Convolution( W , B : TMyMtrix; stride, pad : integer; var Ain, Xout : TMyMtrix;
                       FN, FH, FW : integer );
// Ain : 入力配列データ
// W : 重みデータ配列,  B : バイアスデータ行列
// stride パラメータ,  pad パラメータ
// Xout : 出力配列

procedure Pooling( pool_h, pool_w : integer ; stride, pad : integer; var Ain, Xout : TMyMtrix);
// Ain : 入力データ
// pool_h, pool_w : プーリングのwidth, height
// stride パラメータ,  pad パラメータ
// Xout : 出力配列


implementation


procedure sigmoid( var A, X :TMyMtrix);
  var mi, ni : integer ;
      M , N  : integer ;
begin
  M:=A.Max2; N:=A.Max3;
  X.Setsize(1,M,N);
  for mi := 1 to m do
    for ni := 1 to n do
      X.Mat[(mi-1)*n+ni-1]:=1/(1+exp(-A.Mat[(mi-1)*n+ni-1]));
end;

procedure FStep( var A, X :TMyMtrix);
  var mi, ni : integer ;
      M , N  : integer ;
begin
  M:=A.Max2; N:=A.Max3;
  X.Setsize(1,M,N);
  for mi := 1 to m do
    for ni := 1 to n do
      if A.Mat[(mi-1)*n+ni-1]>0 then X.Mat[(mi-1)*n+ni-1]:=1
                                else X.Mat[(mi-1)*n+ni-1]:=0;
end;

procedure FStep0(  var X :TMyMtrix);
  var mi, ni : integer ;
      M , N  : integer ;
begin
  M:=X.Max2; N:=X.Max3;
  for mi := 1 to m do
    for ni := 1 to n do
      if X.Mat[(mi-1)*n+ni-1]>0 then X.Mat[(mi-1)*n+ni-1]:=1
                            else X.Mat[(mi-1)*n+ni-1]:=0;
end;

procedure ReLU( var A, X :TMyMtrix);
  var ci, mi, ni : integer ;
      C , M , N  : integer ;
begin
  C:=A.Max1; M:=A.Max2; N:=A.Max3;
  X.Setsize(C,M,N);
  for ci := 1 to C do
    for mi := 1 to M do
      for ni := 1 to N do
        if A.Elm(ci,mi,ni)>0 then X.Setvalue(ci,mi,ni, A.Elm(ci,mi,ni))
                             else X.Setvalue(ci,mi,ni, 0);

end;

procedure ReLU0( var X :TMyMtrix);
  var ci, mi, ni : integer ;
      C , M , N  : integer ;
begin
  C:= X.Max1; M:=X.Max2; N:=X.Max3;
  for ci := 1 to C do
    for mi := 1 to M do
      for ni := 1 to N do
        if X.Elm(ci,mi,ni)<=0 then X.Setvalue(ci,mi,ni,0);
end;

procedure softmax( var A, X :TMyMtrix);
  var mi, ni  : integer ;
      wk, sum : single  ;
      M , N  : integer ;
begin
  M:=A.Max2; N:=A.Max3;
  X.Setsize(1,M,N);
  for mi := 1 to M do
  begin
    wk:=A.Mat[(mi-1)*N+1-1];
    for ni := 1 to N do
      if wk<A.Mat[(mi-1)*N+ni-1] then wk:=A.Mat[(mi-1)*N+ni-1];
    sum:=0;
    for ni := 1 to N do
    begin
      X.Mat[(mi-1)*N+ni-1]:=exp(A.Mat[(mi-1)*N+ni-1]-wk);
      sum:=sum+X.Mat[(mi-1)*N+ni-1];
    end;
    for ni := 1 to N do
    begin
      X.Mat[(mi-1)*N+ni-1]:=X.Mat[(mi-1)*N+ni-1]/sum;
    end;
  end;
end;

function  argmax( var A :TMyMtrix ): integer ;
  var i, imax,  n : integer ;
      wk   : single  ;
begin
  n:=A.Max3;
  wk:=A.Elm1(1);
  imax:=1;
  i:=2;
  repeat
    if A.Elm1(i)>wk then
    begin
       wk:=A.Elm1(i);
       imax:=i;
    end;
    inc(i);
  until i>n;
  argmax:=imax;
end;

procedure DropOut( var A, X :TMyMtrix; ratio: single);
  var mi, ni : integer ;
      M , N  : integer ;
begin
  M:=A.Max2; N:=A.Max3;
  X.Setsize(1,M,N);
  for mi := 1 to m do
    for ni := 1 to n do
      X.Mat[(mi-1)*n+ni-1]:=A.Mat[(mi-1)*n+ni-1]*(1-ratio);
end;

procedure DropOut0( var X :TMyMtrix; ratio: single);
begin
  X.mltconst(1-ratio);
end;

procedure im2col(  FH, FW,  stride, pad : integer; var A, X :TMyMtrix );
  var mi, OutHi, OutWi, FHi, FWi, imh, imw : integer ;
      M, InH, InW, OutH, OutW     : integer ;
      iRows  , icol               : integer ;
      ic     , ix    , iy         : integer ;
      i      , j                  : integer ;
      in_x   , in_y               : integer ;
      OutRows, FilterSize, InSize : integer ;
      wk                          : single  ;
begin
  M:= A.Max1;  InH:=A.Max2;  InW:=A.Max3;
  OutH:=(InH + 2*pad - FH) div stride + 1;
  OutW:=(InW + 2*pad - FW) div stride + 1;

  OutRows:= OutH * OutW ;
  FilterSize := FH * FW;
  InSize     := InH * InW;

  X.setsize(1,OutRows,M*Filtersize);

  for ic:=0 to M-1 do
    for iy:=0 to FH-1 do
      for ix:=0 to FW-1 do
        for i:=0 to OutH-1 do
          for j:=0 to OutW-1 do
          begin
            in_y:= iy + i*stride-pad;
            in_x:= ix + j*stride-pad;
            wk:=0;
            if (in_y >= 0) and (in_y <InH) and (in_X >=0) and (in_x <InW)
              then wk:= A.Mat[ic*Insize+in_y*InW+in_x];
            iRows:=i*outW+j;
            icol :=ic*FilterSize+iy*FW+ix;
            X.Mat[iRows*M*Filtersize+icol]:=wk;
          end;
 end;


procedure Affine( W , B : TMyMtrix;  var Ain, Xout : TMyMtrix);
// Affine レイヤー
// Ain : 入力配列データ
// W : 重みデータ配列,  B : バイアスデータ行列
// Xout : 出力配列
begin
  Ain.Reshape(1,1,-1);
  if not MTDot( Ain, W, Xout) then
  begin
    writeln;
    writeln(' MTDot ERROR at Affine');
    readln;
  end;
  if not MTAdd( Xout, B) then
  begin
    writeln;
    writeln(' MTAdd ERROR at Affine');
    readln;
  end;
end;

procedure Convolution( W , B : TMyMtrix; stride, pad : integer; var Ain, Xout : TMyMtrix;
                       FN, FH, FW : integer );
  var
      NN, HH, WW   : integer ;
      out_h, out_w : integer ;
      col          : TMyMtrix;
begin
  NN:=Ain.Max1; HH:=Ain.Max2; WW:=Ain.Max3;

  out_h := 1 + round((HH + 2*pad - FH) / stride);
  out_w := 1 + round((WW + 2*pad - FW) / stride);

  col:=TMyMtrix.Create; // Col.SetSize(?,?,?)  auto set in im2col;

  im2col( FH, FW, stride, pad, Ain, Xout);

  if not MTDOt( Xout, W, col) then
  begin
    writeln;
    writeln(' MTDot ERROR at Convolution');
    readln;
  end;

  if not MTAdd( col, B ) then
  begin
    writeln;
    writeln(' MTAdd ERROR at Convolution');
    readln;
  end;

  if not Transpose( col, Xout) then
  begin
    writeln;
    writeln(' Transpose ERROR at Convolution');
    readln;
  end;
  if not Xout.Reshape(FN, out_h, out_w) then
  begin
    writeln;
    writeln(' Reshape ERROR at Convolution');
    readln;
  end;

  col.free;
end;


procedure Pooling( pool_h, pool_w : integer ; stride, pad : integer; var Ain, Xout : TMyMtrix);
// Ain : 入力データ
// pool_h, pool_w : プーリングのwidth, height
// stride パラメータ,  pad パラメータ
// Xout : 出力配列
  var
      NN, HH, WW   : integer ;
      out_h, out_w : integer ;
      i, j, ch     : integer ;
      ix, iy       : integer ;
      wk           : single  ;

begin
  NN:=Ain.Max1; HH:=Ain.Max2; WW:=Ain.Max3;
  out_h := 1 + round((HH  - pool_h) / stride);
  out_w := 1 + round((WW  - pool_w) / stride);
  Xout.setsize(NN, out_h, out_w);

  for ch := 0 to NN-1 do
    for i := 0 to out_h-1 do
      for j := 0 to out_w-1 do
      begin
        wk:= - 3e38;
        for iy := 0 to pool_h-1 do
          for ix := 0 to pool_w-1 do
          begin
            if Ain.Elm(ch+1,i*2+iy+1,j*2+ix+1) > wk then
              wk:=Ain.Elm(ch+1,i*2+iy+1,j*2+ix+1);
          end;
        Xout.setvalue(ch+1, i+1, j+1, wk);
      end;

end;

end.
