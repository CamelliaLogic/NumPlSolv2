unit MtrixObj;

interface

uses System.SysUtils, MyWeightConst ;

type
  TMyMtrix = Class(TObject)
  private
    FMax3 : integer ;
    FMax2 : integer ;
    FMax1 : integer ;
    FSize : integer ;
    FTrans: boolean ;
    MatReady : boolean ;
  protected
    constructor Create;
    destructor Destroy; override;
  public
    Mat : singleArray ;
    property Trans: boolean read FTrans write FTrans;
    property Max1 : integer read FMax1 write FMax1;
    property Max2 : integer read FMax2 write FMax2;
    property Max3 : integer read FMax3 write FMax3;
    function SetSize( M1, M2, M3 : integer ): boolean;
    procedure SetValue( K, M , N  : integer;  x : single);
    function ReShape( M1, M2, M3 : integer ) : boolean;
    function Elm( K, M, N : integer): single;
    function Elm2(   M, N : integer): single;
    function Elm1(      N : integer): single;
    procedure SetRand( ARange : single);
    procedure MltConst( c : single);
  end;

  function MTDOt( var A :TMyMtrix; var B :TMyMtrix; var Y :TMyMtrix): boolean;
//      Y := A・B   行列A と 行列B との内積を行列Yに格納する
//                 行列Y は A・B の計算結果に合わせて reshape される
//      3次元行列は対象としない

  function MTAdd( var Y :TMyMtrix; var C:TMyMtrix): boolean;
//      Y := Y+C   行列A と 行列B との和を行列Yに格納する
//      Y と C が同じ形（行数、列数）であれば、各要素を加算
//      C が列ベクトルで、Y と C の行数が一致していれば、Y の各列の各要素に
//      C の各要素を加算する
//      C が行ベクトルで、Y と C の列数が一致していれば、Y の各行の各要素に
//      C の各要素を加算する

  function Transpose( var A :TMyMtrix; var Y : TMyMtrix): boolean;
//      Y = A の転置行列
//      A が２次元行列でない場合は　false

implementation


procedure TMyMtrix.MltConst( c : single);
  var iM, iR, iC : integer ;
begin
  for iM:=0 to FMax1-1 do
    for iR:=0 to FMax2-1 do
      for iC:=0 to FMax3-1 do
        Mat[iM*FMax2*FMax3+iR*FMax3+iC]:=Mat[iM*FMax2*FMax3+iR*FMax3+iC]*c;
end;

function TMyMtrix.SetSize( M1, M2, M3 : integer ): boolean ;
begin
  try
      SetLength(Mat, M1*M2*M3);
    except
        on E:EOutOfMemory do
        begin
          MatReady:=false;
          FMax1:=0;
          FMax2:=0;
          FMax3:=0;
          SetSize:=false;
          exit;
        end;
  end;
  FMax1:=M1;
  FMax2:=M2;
  FMax3:=M3;
  FSize:=M1*M2*M3;
  MatReady:=true;
  SetSize:=true;
end;

function TMyMtrix.ReShape( M1, M2, M3 : integer ) : boolean;
begin
  if not MatReady then
  begin
    if (M1<=0) or (M2<=0) or (M3<=0) then
    begin
      ReShape:=false;
      exit;
    end;
    ReShape:=SetSize( M1, M2, M3 );
    exit;
  end;

  if (M1>0) and (M2>0) and (M3>0) then
    begin
      if FSize = (M1*M2*M3) then
        begin
          FMax1:=M1;
          FMax2:=M2;
          FMax3:=M3;
          ReShape:=true;
        end
      else ReShape:=false;
    end
  else
    begin
      if M1>0 then
        begin
          if M2>0 then
            begin
              if (FSize mod (M1*M2))<>0 then
              begin
                ReShape:=false;
                exit;
              end;
              FMax1:=M1;
              FMax2:=M2;
              FMax3:=FSize div (M1*M2);
              ReShape:=true;
            end
          else
            begin
              if (FSize mod (M1*M3))<>0 then
              begin
                ReShape:=false;
                exit;
              end;
              FMax1:=M1;
              FMax3:=M3;
              FMax2:=FSize div (M1*M3);
              ReShape:=true;
            end;
        end
      else
        begin
          if (FSize mod (M2*M3))<>0 then
          begin
            ReShape:=false;
            exit;
          end;
          FMax2:=M2;
          FMax3:=M3;
          FMax1:=FSize div (M2*M3);
          ReShape:=true;
        end;
    end;
end;


constructor TMyMtrix.Create;
begin
  FMax3:=0;
  FMax2:=0;
  FMax1:=0;
  FSize:=0;
  FTrans:=false;
  MatReady := false;
end;

destructor TMyMtrix.Destroy;
begin
  Finalize(Mat);
  inherited Destroy;
end;

function TMyMtrix.Elm( K, M, N : integer): single;
begin
  Elm:=Mat[(k-1)*FMax2*FMax3+(M-1)*FMax3+N-1];
end;

function TMyMtrix.Elm2(   M, N : integer): single;
begin
  if FTrans then Elm2:=Mat[(N-1)*FMax3+M-1]
            else Elm2:=Mat[(M-1)*FMax3+N-1];
end;

function TMyMtrix.Elm1(      N : integer): single;
begin
  Elm1:=Mat[N-1];
end;

procedure TMyMtrix.SetValue(  K, M, N : integer;  x : single);
begin
  Mat[(k-1)*FMax2*FMax3+(M-1)*FMax3+N-1]:=x;
end;

procedure TMyMtrix.SetRand( ARange : single);
  var k, m, n : integer ;
begin
   Randomize;
   for k:=1 to FMax1 do
     for m:= 1 to FMax2 do
       for n:= 1 to FMax3 do
         SetValue(k, m, n, Random*ARange);
end;


//      Y := A・B   行列A と 行列B との内積を行列Yに格納する
//                 行列Y は A・B の計算結果に合わせて reshape される
//      3次元行列は対象としない
function MTDOt( var A :TMyMtrix; var B :TMyMtrix; var Y :TMyMtrix): boolean;
  var
     irA, icA, irB, icB : integer ;
     M, N, K: Integer;
     mi, ni, ki, nn : integer ;
    wk             : single  ;
begin
  if A.Trans then begin irA:=A.Max3; icA:=A.Max2; end
             else begin irA:=A.Max2; icA:=A.Max3; end;
  if B.Trans then begin irB:=B.Max3; icB:=B.Max2; end
             else begin irB:=B.Max2; icB:=B.Max3; end;
  K:=icA; //  columns of A
  M:=irA; //   Rows of A
  N:=icB; //  columns of B
  if k<>irB then
  begin
    MTDOt:=false;
    exit;
  end;
  Y.SetSize( 1, irA, icB );

  for mi := 1 to  M do
   begin
     for ni := 1 to N do
     begin
       wk:=0;
       for ki := 1 to K do
       begin
         wk:= wk + A.Elm2(mi,ki)*B.Elm2(ki,ni);
       end;
       Y.SetValue(1, mi, ni, wk);
     end;
   end;

   MTDOt:=true;;

end;

function MTAdd( var Y :TMyMtrix; var C:TMyMtrix): boolean;
  var
     irY, icY, irC, icC : integer ;
     inY, inC           : integer ;
     M, N, K            : Integer;
begin
  irY:=Y.Max2; icY:=Y.Max3; inY:=Y.Max1;
  irC:=C.Max2; icC:=C.Max3; inC:=C.Max1;

  if (inY<>1) or (inC<>1) then
  begin
    MTAdd:=false; exit;
  end;

  if (irY = irC ) and (icY = icC) then
    begin
      for m:=1 to irY do
        for n:=1 to icY do
          Y.SetValue(1,m,n,Y.Elm(1,m,n)+C.Elm(1,m,n));
      MTAdd:=true; exit;
    end
  else
    begin
      if (irY = irC ) and (icC=1) then
      begin
        for m:=1 to irY do
          for n:=1 to icY do
            Y.SetValue(1,m,n,Y.Elm(1,m,n)+C.Elm(1,m,1));
        MTAdd:=true; exit;
      end;
      if (icY = icC ) and (irC=1) then
      begin
        for m:=1 to irY do
          for n:=1 to icY do
            Y.SetValue(1,m,n,Y.Elm(1,m,n)+C.Elm(1,1,n));
        MTAdd:=true; exit;
      end;
      MTAdd:=false; exit;
    end;
end;


//      Y = A の転置行列
//      A が２次元行列でない場合は　false
function Transpose( var A :TMyMtrix; var Y : TMyMtrix): boolean;
  var M, N   :integer;
      WTrans : boolean ;
begin
  Transpose:=false;
  if A.Max1<>1 then exit;
  if Y=nil then exit;

  Y.Setsize(1,A.Max3, A.Max2);
  Y.Trans:=false;

  WTrans:=A.Trans;
  A.Trans:=false;

  for M:=1 to A.Max2 do
    for N:= 1 to A.Max3 do
      Y.SetValue( 1, N , M ,  A.Elm2( M, N ));

  A.Trans:=WTrans;

  Transpose:=true;

end;


end.
