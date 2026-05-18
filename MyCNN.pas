unit MyCNN;

interface

uses
  MtrixObj, MyDLCommon, MyWeightInstance;

type
  TMyConvNet = class(TObject)
  private
  protected
    constructor Create;
    destructor Destroy; override;
  public
    procedure LoadParms;
    procedure Predict( var A, X : TMyMtrix);
  end;

implementation

constructor TMyConvNet.Create;
begin
end;

destructor TMyConvNet.Destroy;
begin
  inherited Destroy;
end;

procedure TMyConvNet.LoadParms;
begin
end;

procedure TMyConvNet.Predict( var A, X : TMyMtrix);
  var wk : TMyMtrix;
begin
  wk:=TMyMtrix.Create;
// layer1  Convolution
  Convolution( MyW1 , MyB1 , 1, 1,  A, wk, 16, 3, 3);

// layer2  Relu
  ReLU0( wk );

// layer3  Convolution
  Convolution( MyW2 , MyB2 , 1, 1,  wk, x, 16, 3, 3);

// layer4  Relu
  ReLU0( x );

// layer5  Pooling
  Pooling( 2, 2 , 2, 1,  X, wk );

// layer6  Convolution
  Convolution( MyW3 , MyB3 , 1, 1,  wk, x, 32, 3, 3);

// layer7  Relu
  ReLU0( x );

// layer8 Convolution
  Convolution( MyW4 , MyB4 , 1, 2,  x, wk, 32, 3, 3);

// layer9 Relu
  ReLU0( wk );

// layer10 Pooling(pool_h=2, pool_w=2, stride=2))
  Pooling( 2, 2 , 2, 1,  wk, x );

// layer11 Convolution
  Convolution( MyW5 , MyB5 , 1, 1,  x, wk, 64, 3, 3);

// layer12 Relu
  ReLU0( wk );

// layer13 Convolution
  Convolution( MyW6 , MyB6 , 1, 1,  wk, x, 64, 3, 3);

// layer14 Relu
  ReLU0( x );

// layer15 Pooling(pool_h=2, pool_w=2, stride=2))
  Pooling( 2, 2 , 2, 1,  x, wk );

// layer16 Affine
  Affine( MyW7 , MyB7, wk, X);

// layer17 Relu
  ReLU0( x );

// layer18 Dropout(0.5)
  DropOut0( X, 0.5);

// layer19 Affine
  Affine( MyW8 , MyB8, x, wk);

// layer20 Dropout(0.5)
  DropOut0( wk, 0.5);

// layer21 SoftmaxWithLoss
  softmax( wk, X);

  wk.free;
end;

end.
