program NumPLSolv21;

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit1 in 'Unit1.pas' {NumPlSolver2};

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Portrait];
  Application.CreateForm(TNumPlSolver2, NumPlSolver2);
  Application.Run;
end.
